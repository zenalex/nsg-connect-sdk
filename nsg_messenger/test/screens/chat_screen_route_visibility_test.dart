import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart' show NsgMessenger;
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// **Issue #55** — перекрытие чата другим маршрутом ВНУТРИ приложения.
///
/// Симптом заявки: при открытом поверх чата профиле пришло сообщение — без
/// оповещения, и после выхода из профиля оно оказалось «прочитанным», хотя
/// пользователь его не видел.
///
/// Причина: живой (не dispose-нутый) `ChatScreen` под чужим маршрутом
/// считал себя видимым — держал серверный presence `currentRoomId`
/// (push-routing глушил уведомление «пользователю в комнате») и метил
/// входящие прочитанными: ни одна из осей гейта issue #37
/// (active/appResumed/newestVisible) перекрытие не ловит.
///
/// Контракт после фикса (через `NsgMessenger.routeObserver`, который host
/// обязан включить в `MaterialApp.navigatorObservers`):
///   * push маршрута поверх → presence отпускается (`currentRoomId: null`,
///     как в dispose), auto-markRead откладывается;
///   * pop обратно → presence комнаты возвращается, отложенное «прочитано»
///     дожимается (механика догона issue #37);
///   * host не подключил observer → прежнее поведение, без исключений;
///   * bottom-sheet-ы/диалоги перекрытием НЕ считаются (чат под ними виден).
///
/// **Важно**: без `pumpAndSettle()` — у Loading-спиннера бесконечная
/// анимация; переходы маршрутов прокачиваем фиксированными pump-ами.
void main() {
  setUpAll(registerTimeagoLocales);

  /// Открывает чат с одним сообщением в истории и доводит до Ready.
  /// [withObserver] — регистрировать ли `NsgMessenger.routeObserver` у
  /// навигатора (кейс деградации проверяется без него).
  Future<
    ({
      _FakeRpc rpc,
      MessagesController controller,
      StreamController<MessengerEvent> events,
      List<({int? currentRoomId, bool foreground})> presenceCalls,
      GlobalKey<NavigatorState> navKey,
    })
  >
  openChat(
    WidgetTester tester, {
    bool withObserver = true,
    bool active = true,
  }) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(_page([_msg(eventId: 'first')]));
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    final presenceCalls = <({int? currentRoomId, bool foreground})>[];
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        navigatorObservers: [if (withObserver) NsgMessenger.routeObserver],
        locale: const Locale('en'),
        localizationsDelegates: const [
          NsgL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: NsgL10n.supportedLocales,
        home: ChatScreen(
          roomId: 1,
          active: active,
          controllerOverride: controller,
          setPresenceOverride:
              ({int? currentRoomId, required bool foreground}) async {
                presenceCalls.add((
                  currentRoomId: currentRoomId,
                  foreground: foreground,
                ));
              },
        ),
      ),
    );
    await tester.pump(); // mount + init
    await tester.pump(); // listMessages резолвится → Ready
    await tester.pump(); // микротаски markRead
    return (
      rpc: rpc,
      controller: controller,
      events: eventCtrl,
      presenceCalls: presenceCalls,
      navKey: navKey,
    );
  }

  /// Пуш экрана-«профиля» поверх чата + прокачка transition-анимации.
  Future<void> pushCover(
    WidgetTester tester,
    GlobalKey<NavigatorState> navKey,
  ) async {
    navKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('profile'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> popCover(
    WidgetTester tester,
    GlobalKey<NavigatorState> navKey,
  ) async {
    navKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
    'пуш маршрута поверх чата → presence отпущен (null), входящее при '
    'перекрытии НЕ помечается прочитанным',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });

      // Открытый чат: заявил комнату и пометил seed — это корректно.
      expect(h.presenceCalls, hasLength(1));
      expect(h.presenceCalls.first.currentRoomId, 1);
      expect(h.rpc.markReadCalls, ['first']);

      await pushCover(tester, h.navKey);

      // Перекрытие = уход с экрана: presence как в dispose. Без этого
      // push-routing (фильтр «foreground в той же комнате → skip») глушит
      // уведомление — первая половина issue #55.
      expect(h.presenceCalls, hasLength(2));
      expect(h.presenceCalls.last.currentRoomId, isNull);
      expect(h.presenceCalls.last.foreground, isTrue);

      // Пока юзер смотрит на «профиль», прилетает сообщение.
      h.events.add(_eventForRoom(1, _msg(eventId: 'while-covered')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900)); // > debounce

      expect(
        h.rpc.markReadCalls,
        ['first'],
        reason: 'юзер не видел сообщение — «прочитано» слать нельзя '
            '(вторая половина issue #55: молчаливое прочтение под профилем)',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'pop обратно в чат → presence комнаты возвращается, отложенный '
    'markRead дожимается',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });
      expect(h.rpc.markReadCalls, ['first']);

      await pushCover(tester, h.navKey);
      h.events.add(_eventForRoom(1, _msg(eventId: 'covered-1')));
      await tester.pump();
      h.events.add(_eventForRoom(1, _msg(eventId: 'covered-2')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(h.rpc.markReadCalls, ['first'], reason: 'под профилем — молчим');

      await popCover(tester, h.navKey);
      await tester.pump();

      // Возврат presence: сервер снова знает «юзер в комнате 1».
      expect(h.presenceCalls.last.currentRoomId, 1);
      expect(h.presenceCalls.last.foreground, isTrue);
      // Догон: накопившееся помечено одним вызовом с newest event id.
      expect(
        h.rpc.markReadCalls,
        ['first', 'covered-2'],
        reason: 'юзер вернулся и смотрит на ленту — теперь «прочитано» '
            'честное',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'host НЕ зарегистрировал observer → прежнее поведение (без исключений, '
    'markRead работает как раньше)',
    (tester) async {
      final h = await openChat(tester, withObserver: false);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });
      expect(h.rpc.markReadCalls, ['first']);

      await pushCover(tester, h.navKey);

      // Деградация: перекрытие не замечено, presence не отпущен.
      expect(h.presenceCalls, hasLength(1));

      h.events.add(_eventForRoom(1, _msg(eventId: 'legacy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        h.rpc.markReadCalls,
        ['first', 'legacy'],
        reason: 'без observer-а SDK не видит перекрытие — сохраняем '
            'прежнее (пусть и небезупречное) поведение, а не ломаемся',
      );

      await popCover(tester, h.navKey);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'неактивная вкладка (active=false): на didPopNext presence с roomId '
    'НЕ шлётся — иначе фоновая панель стёрла бы заявку активной',
    (tester) async {
      final h = await openChat(tester, active: false);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });

      // Неактивная вкладка комнату не заявляет вовсе (TASK66).
      expect(h.presenceCalls, isEmpty);

      await pushCover(tester, h.navKey);
      expect(
        h.presenceCalls,
        isEmpty,
        reason: 'мы presence не держали — и отпускать (null) нечего: null '
            'стёр бы заявку чата, активного в другой панели',
      );

      await popCover(tester, h.navKey);
      await tester.pump();
      expect(
        h.presenceCalls,
        isEmpty,
        reason: 'didPopNext в неактивной вкладке НЕ заявляет комнату — '
            'это сделает didUpdateWidget, когда вкладка станет активной',
      );
      expect(h.rpc.markReadCalls, isEmpty, reason: 'гейт active — как был');

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'bottom sheet поверх чата — НЕ перекрытие: presence не отпускается, '
    'markRead продолжает работать',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });
      expect(h.rpc.markReadCalls, ['first']);

      // Action-sheet/пикер — постоянные спутники переписки; чат под ними
      // виден сквозь полупрозрачный barrier, юзер продолжает читать.
      final chatCtx = tester.element(find.byType(ChatScreen));
      showModalBottomSheet<void>(
        context: chatCtx,
        builder: (_) => const SizedBox(height: 120),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        h.presenceCalls,
        hasLength(1),
        reason: 'шит — не уход с экрана, presence комнаты остаётся',
      );

      h.events.add(_eventForRoom(1, _msg(eventId: 'under-sheet')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        h.rpc.markReadCalls,
        ['first', 'under-sheet'],
        reason: 'лента видна за шитом — «прочитано» честное',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

// ─── Helpers (по образцу chat_screen_mark_read_gate_test) ───

MessengerEvent _eventForRoom(int roomId, MessengerMessage msg) =>
    MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: msg.serverTimestamp,
      roomId: roomId,
      matrixRoomId: msg.matrixRoomId,
      message: msg,
    );

MessengerMessage _msg({required String eventId, String body = 'msg'}) =>
    MessengerMessage(
      matrixEventId: eventId,
      roomId: 1,
      matrixRoomId: '!r:t',
      senderMessengerUserId: 99,
      senderMatrixUserId: '@peer:t',
      msgType: 'm.text',
      body: body,
      content: ByteData(0),
      serverTimestamp: DateTime.utc(2026, 1, 1),
    );

MessengerMessageListPage _page(List<MessengerMessage> ms) =>
    MessengerMessageListPage(messages: ms);

class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;

  final markReadCalls = <String>[];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) =>
      listMessagesHandler?.call(roomId, fromToken, limit) ??
      Future.value(_page(const []));

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async {
    markReadCalls.add(matrixEventId);
    return true;
  }

  @override
  Future<TaskLink> createTaskFromMessage({
    required int roomId,
    required String matrixEventId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) =>
      throw UnimplementedError();

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => throw UnimplementedError();

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) async => 'reaction-event';

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) async {}

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) async => const <MessengerMessage>[];

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];
}
