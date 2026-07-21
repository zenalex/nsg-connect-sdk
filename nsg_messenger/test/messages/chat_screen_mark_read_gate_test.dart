import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// **Issue #37** — «прочитано» не должно врать.
///
/// Симптом заявки: отправитель видит синие ✓✓ на только что отправленном
/// сообщении, хотя получатель офлайн («был в сети» несколько часов назад).
///
/// Причина: `ChatScreen._onStateChange` гейтил auto-markRead ТОЛЬКО по
/// TASK66-флагу `active` (активная вкладка мультичатового набора). Это не
/// имеет отношения к тому, смотрит ли юзер на экран: `MessengerEventBus`
/// рвёт realtime-подписку только на `paused`/`detached`, поэтому в
/// свёрнутом (или просто расфокусированном) приложении с открытым чатом
/// сообщения продолжали приходить — и мгновенно помечались прочитанными.
///
/// Контракт после фикса: markRead уходит, только если сообщение реально
/// показано пользователю — чат активен И приложение в foreground И newest
/// сообщение в видимой области. Не выполнено — markRead ОТКЛАДЫВАЕТСЯ и
/// дожимается, когда условия сойдутся.
///
/// **Важно**: без `pumpAndSettle()` — у Loading-спиннера бесконечная
/// анимация, settle не наступит.
void main() {
  setUpAll(registerTimeagoLocales);

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: child,
  );

  /// Прогоняет lifecycle-переход прямо через observer виджета.
  /// `tester.binding.handleAppLifecycleStateChanged` навязывает строгую
  /// валидацию переходов, которая не отражает поведение реального
  /// устройства (см. chat_screen_lifecycle_test.dart).
  void fireLifecycle(WidgetTester tester, AppLifecycleState state) {
    final stateObj = tester.state(find.byType(ChatScreen));
    // ignore: avoid_dynamic_calls
    (stateObj as dynamic).didChangeAppLifecycleState(state);
  }

  /// Открывает чат с одним сообщением в истории и доводит до Ready.
  /// Возвращает (rpc, controller, eventCtrl) — teardown на вызывающем.
  Future<({_FakeRpc rpc, MessagesController controller,
      StreamController<MessengerEvent> events})> openChat(
    WidgetTester tester, {
    String seedEventId = 'first',
  }) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(_page([_msg(eventId: seedEventId)]));
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    await tester.pumpWidget(
      wrap(ChatScreen(roomId: 1, controllerOverride: controller)),
    );
    await tester.pump(); // mount + init
    await tester.pump(); // listMessages резолвится → Ready
    await tester.pump(); // микротаски markRead
    return (rpc: rpc, controller: controller, events: eventCtrl);
  }

  // ─── Фоновая доставка ────────────────────────────────────────────────

  testWidgets(
    'приложение свёрнуто (paused) → входящее realtime-сообщение НЕ '
    'помечается прочитанным',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });

      // Чат открыт в foreground — seed помечен, это корректно.
      expect(h.rpc.markReadCalls, ['first']);

      // Юзер свернул приложение. Чат остаётся смонтированным и
      // `active == true` — ровно кейс из заявки.
      fireLifecycle(tester, AppLifecycleState.paused);
      await tester.pump();

      // Пока приложение в фоне, прилетает новое сообщение (сокет ещё жив
      // / успел долететь до сворачивания подписки).
      h.events.add(_eventForRoom(1, _msg(eventId: 'bg-msg')));
      await tester.pump();

      // Ждём заведомо дольше debounce-а (500ms).
      await tester.pump(const Duration(milliseconds: 900));

      expect(
        h.rpc.markReadCalls,
        ['first'],
        reason: 'юзер не видел сообщение — «прочитано» слать нельзя '
            '(issue #37: именно здесь ✓✓ и врали)',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'inactive/hidden (расфокус, шторка) тоже блокируют markRead — '
    'bus в этих состояниях подписку НЕ рвёт',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });
      expect(h.rpc.markReadCalls, ['first']);

      fireLifecycle(tester, AppLifecycleState.inactive);
      await tester.pump();
      h.events.add(_eventForRoom(1, _msg(eventId: 'while-inactive')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(h.rpc.markReadCalls, ['first']);

      fireLifecycle(tester, AppLifecycleState.hidden);
      await tester.pump();
      h.events.add(_eventForRoom(1, _msg(eventId: 'while-hidden')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        h.rpc.markReadCalls,
        ['first'],
        reason: 'на desktop расфокусированное окно живёт в inactive/hidden '
            'сколько угодно долго — и получает realtime',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'возврат в foreground (resumed) → накопленное в фоне помечается '
    'прочитанным ровно сейчас',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });

      fireLifecycle(tester, AppLifecycleState.paused);
      await tester.pump();
      h.events.add(_eventForRoom(1, _msg(eventId: 'bg-1')));
      await tester.pump();
      h.events.add(_eventForRoom(1, _msg(eventId: 'bg-2')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(h.rpc.markReadCalls, ['first'], reason: 'в фоне — молчим');

      // Юзер вернулся в приложение и смотрит на чат.
      fireLifecycle(tester, AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      expect(
        h.rpc.markReadCalls,
        ['first', 'bg-2'],
        reason: 'отложенный markRead дожимается с newest event id '
            '(накопленный burst — одним вызовом)',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  // ─── Чат открыт на переднем плане (регрессия) ────────────────────────

  testWidgets(
    'чат открыт и приложение в foreground → входящее помечается '
    'прочитанным (debounce 500ms)',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });
      expect(h.rpc.markReadCalls, ['first']);

      h.events.add(_eventForRoom(1, _msg(eventId: 'live')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        h.rpc.markReadCalls,
        ['first'],
        reason: 'debounce ещё не истёк',
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        h.rpc.markReadCalls,
        ['first', 'live'],
        reason: 'юзер смотрит на чат — «прочитано» честное',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  // ─── Видимая область ─────────────────────────────────────────────────

  testWidgets(
    'юзер ушёл вверх в историю → новое сообщение под кромкой экрана НЕ '
    'помечается; доскролл вниз — помечается',
    (tester) async {
      final h = await openChat(tester);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });
      expect(h.rpc.markReadCalls, ['first']);

      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final scrollableEl = tester.element(
        find.descendant(of: listFinder, matching: find.byType(Scrollable)),
      );

      // reverse: true → pixels растёт ВВЕРХ, в историю. 500px от дна:
      // newest сообщение уже под нижней кромкой вьюпорта.
      // (maxScrollExtent=1000, до loadMore-порога 200 не достаём.)
      _dispatchScroll(scrollableEl, pixels: 500);
      await tester.pump();

      h.events.add(_eventForRoom(1, _msg(eventId: 'below-fold')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        h.rpc.markReadCalls,
        ['first'],
        reason: 'сообщение пришло ниже видимой области — юзер его не видел',
      );

      // Юзер доскроллил обратно вниз — сообщение показано.
      _dispatchScroll(scrollableEl, pixels: 0);
      await tester.pump();
      await tester.pump();

      expect(
        h.rpc.markReadCalls,
        ['first', 'below-fold'],
        reason: 'вернулись на дно ленты → отложенное помечается',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

void _dispatchScroll(Element scrollableEl, {required double pixels}) {
  ScrollUpdateNotification(
    metrics: FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: pixels,
      viewportDimension: 400,
      axisDirection: AxisDirection.up,
      devicePixelRatio: 1.0,
    ),
    context: scrollableEl,
    scrollDelta: 1,
  ).dispatch(scrollableEl);
}

// ─── Helpers ───

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
