import 'dart:async';

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

/// **TASK83**: маршрут тапа по значку задачи в [ChatScreen] — тред задачи
/// (если у неё есть корень треда) или issue-URL (fallback). Экран, не bubble,
/// решает КУДА; здесь проверяем именно эту развилку через visible-for-testing
/// override-ы (реальную навигацию/`launchUrl` в тесте не поднимаем).
void main() {
  setUpAll(registerTimeagoLocales);

  const kSelf = 42;

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

  MessengerMessage msg({String? stage, String? root, String? url}) =>
      MessengerMessage(
        matrixEventId: 'src-event',
        roomId: 7,
        matrixRoomId: '!r:t',
        senderMessengerUserId: 99,
        senderMatrixUserId: '@peer:t',
        msgType: 'm.text',
        body: 'Кнопка не работает',
        serverTimestamp: DateTime.utc(2026, 1, 1),
        taskStage: stage,
        taskThreadRootEventId: root,
        taskUrl: url,
      );

  RoomDetails details() => RoomDetails(
    id: 7,
    matrixRoomId: '!r:t',
    name: 'Поддержка',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.support,
    participants: [
      RoomParticipant(
        messengerUserId: kSelf,
        matrixUserId: '@self:t',
        role: RoomMemberRole.member,
      ),
      RoomParticipant(
        messengerUserId: 99,
        matrixUserId: '@peer:t',
        role: RoomMemberRole.member,
        displayName: 'Пётр',
      ),
    ],
    totalParticipants: 2,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  Future<void> pumpChat(
    WidgetTester tester, {
    required MessengerMessage seeded,
    void Function(BuildContext, String)? onThread,
    void Function(String)? onUrl,
  }) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(MessengerMessageListPage(messages: [seeded]));
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 7,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: kSelf,
      selfMatrixUserId: '@self:t',
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: 7,
          controllerOverride: controller,
          roomDetailsOverride: details(),
          openTaskThreadOverride: onThread,
          openTaskUrlOverride: onUrl,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('тап по значку с тредом → openTaskThreadOverride(корень)', (
    tester,
  ) async {
    String? threadRoot;
    var urlCalls = 0;
    await pumpChat(
      tester,
      seeded: msg(stage: 'in_progress', root: r'$anchor', url: 'https://x/42'),
      onThread: (_, root) => threadRoot = root,
      onUrl: (_) => urlCalls++,
    );
    expect(find.byKey(const Key('taskBadge')), findsOneWidget);
    await tester.tap(find.byKey(const Key('taskBadge')));
    await tester.pump();
    expect(threadRoot, r'$anchor', reason: 'есть тред → идём в тред');
    expect(urlCalls, 0, reason: 'URL-fallback не дёргаем при наличии треда');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('тап по значку без треда → openTaskUrlOverride(url)', (
    tester,
  ) async {
    var threadCalls = 0;
    String? url;
    await pumpChat(
      tester,
      seeded: msg(stage: null, root: null, url: 'https://x/43'),
      onThread: (_, _) => threadCalls++,
      onUrl: (u) => url = u,
    );
    expect(find.byKey(const Key('taskBadge')), findsOneWidget);
    await tester.tap(find.byKey(const Key('taskBadge')));
    await tester.pump();
    expect(url, 'https://x/43', reason: 'нет треда → fallback в issue-URL');
    expect(threadCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('сообщение без задачи → значка нет', (tester) async {
    await pumpChat(tester, seeded: msg(), onThread: (_, _) {}, onUrl: (_) {});
    expect(find.byKey(const Key('taskBadge')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) {
    final h = listMessagesHandler;
    if (h == null) throw StateError('listMessagesHandler not set');
    return h(roomId, fromToken, limit);
  }

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_FakeRpc: only load-path RPCs mocked (${invocation.memberName})',
  );

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
