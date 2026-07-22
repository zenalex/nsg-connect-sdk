import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';
import 'package:nsg_messenger/src/screens/thread_screen.dart';

/// **TASK82**: вход в тред задачи с якоря в чате + сам экран треда.
///
/// Навигация в [ChatScreen] подменяется `openThreadOverride`: настоящий
/// [ThreadScreen] строит СВОЙ контроллер через `MessengerRuntime`, которого
/// в widget-тесте нет. Экран треда проверяем отдельно, с инжектированным
/// контроллером.
const _room = 7;
const _root = 'anchor-event';

MessengerMessage _msg({
  required String eventId,
  String body = 'msg',
  String? threadId,
  int? threadReplyCount,
  int? senderMessengerUserId = 2,
}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: _room,
  matrixRoomId: '!r:t',
  senderMessengerUserId: senderMessengerUserId,
  senderMatrixUserId: '@peer:t',
  msgType: 'm.text',
  body: body,
  serverTimestamp: DateTime.utc(2026, 1, 1, 12),
  threadId: threadId,
  threadReplyCount: threadReplyCount,
);

class _FakeRpc implements MessagesRpc {
  List<MessengerMessage> roomPage = [];
  List<MessengerMessage> threadPage = [];

  /// Аргументы последнего `sendMessage` — по ним проверяем, что отправка
  /// из треда уходит с корнем.
  String? lastSentThreadId;
  String? lastSentBody;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: roomPage);

  @override
  Future<MessengerMessageListPage> listThreadMessages({
    required int roomId,
    required String threadRootEventId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: threadPage);

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
    String? threadId,
  }) async {
    lastSentThreadId = threadId;
    lastSentBody = body;
    return MessengerMessage(
      matrixEventId: 'sent-$clientTxnId',
      roomId: roomId,
      matrixRoomId: '!r:t',
      senderMessengerUserId: 42,
      senderMatrixUserId: '@self:t',
      msgType: msgType,
      body: body,
      serverTimestamp: DateTime.utc(2026, 1, 1, 13),
      clientTxnId: clientTxnId,
      threadId: threadId,
    );
  }

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const [];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(registerTimeagoLocales);

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: child,
  );

  MessagesController make(_FakeRpc rpc, {String? threadRootEventId}) {
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: _room,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
      threadRootEventId: threadRootEventId,
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    return controller;
  }

  testWidgets('ChatScreen: тап по «Обсуждение (N)» на якоре открывает тред', (
    tester,
  ) async {
    final rpc = _FakeRpc()
      ..roomPage = [
        _msg(
          eventId: _root,
          body: 'Задача создана: не грузятся фото',
          threadReplyCount: 2,
        ),
      ];
    final controller = make(rpc);
    ChatMessage? opened;

    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: _room,
          controllerOverride: controller,
          openThreadOverride: (_, anchor) => opened = anchor,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('threadLink')), findsOneWidget);
    await tester.tap(find.byKey(const Key('threadLink')));
    await tester.pump();

    expect(opened?.matrixEventId, _root);
  });

  testWidgets('ChatScreen: у сообщения без треда строки-кнопки нет', (
    tester,
  ) async {
    final rpc = _FakeRpc()..roomPage = [_msg(eventId: 'plain')];
    final controller = make(rpc);

    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: _room,
          controllerOverride: controller,
          openThreadOverride: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('threadLink')), findsNothing);
  });

  testWidgets('ThreadScreen: лента треда рендерится, шапка = тема задачи', (
    tester,
  ) async {
    final rpc = _FakeRpc()
      ..threadPage = [
        _msg(eventId: 'r1', body: 'починилось?', threadId: _root),
        _msg(eventId: _root, body: 'Задача создана: не грузятся фото'),
      ];
    final controller = make(rpc, threadRootEventId: _root);

    await tester.pumpWidget(
      wrap(
        ThreadScreen(
          roomId: _room,
          threadRootEventId: _root,
          title: 'Не грузятся фото',
          statusLabel: 'В работе',
          controllerOverride: controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Не грузятся фото'), findsOneWidget);
    expect(find.text('В работе'), findsOneWidget);
    expect(find.text('починилось?'), findsOneWidget);
    // Внутри треда ссылка «Обсуждение» на якоре не рисуется — она бы
    // открывала сама себя.
    expect(find.byKey(const Key('threadLink')), findsNothing);
  });

  testWidgets('ThreadScreen: отправка из композера уходит с threadId', (
    tester,
  ) async {
    final rpc = _FakeRpc()..threadPage = [_msg(eventId: _root, body: 'Задача')];
    final controller = make(rpc, threadRootEventId: _root);

    await tester.pumpWidget(
      wrap(
        ThreadScreen(
          roomId: _room,
          threadRootEventId: _root,
          controllerOverride: controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'проверил, ок');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(rpc.lastSentBody, 'проверил, ок');
    expect(rpc.lastSentThreadId, _root);
  });
}
