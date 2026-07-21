import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_action_sheet.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

/// **Issue #35 — закрепление сообщений.** Widget-тесты пункта «Закрепить/
/// Открепить» в меню сообщения:
///   * виден только при `canPin: true` и наличии matrixEventId;
///   * label = Pin / Unpin по текущему состоянию закрепления;
///   * тап зовёт controller.pin/unpinMessage + snackbar.
class _FakeRpc implements MessagesRpc {
  List<MessengerMessage> pinnedResult = const <MessengerMessage>[];
  final List<String> pinnedCalls = <String>[];
  final List<String> unpinnedCalls = <String>[];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: const []);

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

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
  }) async => pinnedResult;

  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async {
    pinnedCalls.add(matrixEventId);
    return pinnedResult.map((m) => m.matrixEventId).toList(growable: false);
  }

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async {
    unpinnedCalls.add(matrixEventId);
    return pinnedResult.map((m) => m.matrixEventId).toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRpc rpc;
  late MessagesController controller;

  setUp(() async {
    rpc = _FakeRpc();
    controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: const Stream<MessengerEvent>.empty(),
      selfMessengerUserId: 1,
      selfMatrixUserId: '@self:t',
    );
    await controller.init();
    addTearDown(controller.dispose);
  });

  ChatMessage msg() => ChatMessage(
    clientTxnId: null,
    matrixEventId: '\$ev1',
    senderMatrixUserId: '@a:t',
    senderMessengerUserId: 2,
    body: 'hello',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
  );

  MessengerMessage serverMsg(String id) => MessengerMessage(
    matrixEventId: id,
    roomId: 1,
    matrixRoomId: '!r:t',
    senderMessengerUserId: 2,
    senderMatrixUserId: '@a:t',
    msgType: 'm.text',
    body: 'hello',
    serverTimestamp: DateTime.utc(2026, 1, 1),
  );

  Widget app(ChatMessage m, {required bool canPin}) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showMessageActionSheet(
            context: ctx,
            message: m,
            isOwn: false,
            controller: controller,
            canPin: canPin,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  testWidgets('canPin=false → пункта нет', (tester) async {
    await tester.pumpWidget(app(msg(), canPin: false));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Pin'), findsNothing);
    expect(find.text('Unpin'), findsNothing);
  });

  testWidgets('canPin=true, не закреплено → «Pin»; тап закрепляет + snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(app(msg(), canPin: true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Pin'), findsOneWidget);
    expect(find.text('Unpin'), findsNothing);

    await tester.tap(find.text('Pin'));
    await tester.pump(); // pop листа + старт async
    await tester.pump(const Duration(seconds: 1));

    expect(rpc.pinnedCalls, ['\$ev1']);
    expect(find.text('Message pinned'), findsOneWidget);
  });

  testWidgets('уже закреплено → «Unpin»; тап откепляет', (tester) async {
    // Сделать сообщение закреплённым: сервер отдаёт его в listPinnedMessages.
    rpc.pinnedResult = [serverMsg('\$ev1')];
    await controller.loadPinned();
    expect(controller.isPinned('\$ev1'), isTrue);

    await tester.pumpWidget(app(msg(), canPin: true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Unpin'), findsOneWidget);
    expect(find.text('Pin'), findsNothing);

    // После unpin сервер отдаст пустой список.
    rpc.pinnedResult = const <MessengerMessage>[];
    await tester.tap(find.text('Unpin'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(rpc.unpinnedCalls, ['\$ev1']);
    expect(find.text('Message unpinned'), findsOneWidget);
  });
}
