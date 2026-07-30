/// **issue #76**: «при нажатии правой кнопкой в групповом чате на
/// сообщении пользователя добавить пункт Личное сообщение, для перехода в
/// отдельный чат».
///
/// Пункт живёт по тем же правилам, что «Ответить с упоминанием»: только в
/// группе, только на чужом сообщении и только когда автор известен —
/// у системных сообщений и бот-эха id автора нет, и создавать 1:1 не с кем.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_action_sheet.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

void main() {
  late MessagesController controller;

  setUp(() async {
    controller = MessagesController(
      roomId: 1,
      rpc: _FakeRpc(),
      events: const Stream<MessengerEvent>.empty(),
      selfMessengerUserId: 1,
      selfMatrixUserId: '@self:t',
    );
    await controller.init();
    addTearDown(controller.dispose);
  });

  ChatMessage msg({int? senderId = 2}) => ChatMessage(
    clientTxnId: null,
    matrixEventId: '\$ev1',
    senderMatrixUserId: '@a:t',
    senderMessengerUserId: senderId,
    body: 'привет всем',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
  );

  Future<List<ChatMessage>> openSheet(
    WidgetTester tester, {
    required bool isOwn,
    required bool offerDirect,
    ChatMessage? message,
  }) async {
    final opened = <ChatMessage>[];
    final m = message ?? msg();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showMessageActionSheet(
                context: ctx,
                message: m,
                isOwn: isOwn,
                controller: controller,
                onOpenDirectChat: offerDirect ? opened.add : null,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('в группе на чужом сообщении пункт есть и зовёт переход', (
    tester,
  ) async {
    final opened = await openSheet(tester, isOwn: false, offerDirect: true);
    expect(find.text('Direct message'), findsOneWidget);
    await tester.tap(find.text('Direct message'));
    await tester.pumpAndSettle();
    expect(opened.single.senderMessengerUserId, 2);
    expect(find.text('Direct message'), findsNothing, reason: 'шит закрылся');
  });

  testWidgets('без колбэка (1:1, своё сообщение, нет автора) пункта нет', (
    tester,
  ) async {
    // Решение «показывать ли» принимает ChatScreen — здесь проверяем, что
    // шит уважает его отказ и не рисует пункт «на всякий случай».
    await openSheet(tester, isOwn: false, offerDirect: false);
    expect(find.text('Direct message'), findsNothing);
  });

  testWidgets('удалённое сообщение пункта не даёт', (tester) async {
    // Автор известен, но писать «по мотивам» надгробия незачем.
    final deleted = ChatMessage(
      clientTxnId: null,
      matrixEventId: '\$ev1',
      senderMatrixUserId: '@a:t',
      senderMessengerUserId: 2,
      body: '',
      msgType: 'm.text',
      serverTimestamp: DateTime.utc(2026, 1, 1),
      status: ChatMessageStatus.sent,
      deletedAt: DateTime.utc(2026, 1, 2),
    );
    await openSheet(tester, isOwn: false, offerDirect: true, message: deleted);
    expect(find.text('Direct message'), findsNothing);
  });
}

class _FakeRpc implements MessagesRpc {
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
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
