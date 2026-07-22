import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// **TASK82**: строка-кнопка «Обсуждение (N)» на якоре задачи.
///
/// Ключевое, что проверяем, — она рисуется РОВНО тогда, когда есть и
/// сводка треда, и обработчик: обещать переход, которого не будет (или
/// показывать пустой тред), хуже, чем не показывать ссылку вовсе.
void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage anchor({int? threadReplyCount}) => ChatMessage(
    clientTxnId: 'txn-anchor',
    matrixEventId: 'anchor-event',
    senderMatrixUserId: '@nsg-system:localhost',
    senderMessengerUserId: null,
    body: 'Задача создана: не грузятся фото',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    threadReplyCount: threadReplyCount,
  );

  Widget bubble({int? count, VoidCallback? onOpen}) => wrapL10n(
    MessageBubble(
      message: anchor(threadReplyCount: count),
      isOwn: false,
      onRetry: (_) {},
      threadReplyCount: count,
      onOpenThread: onOpen,
    ),
  );

  testWidgets('есть ответы + обработчик → строка «Обсуждение (N)» видна', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(bubble(count: 3, onOpen: () => opened++));

    expect(find.byKey(const Key('threadLink')), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);

    await tester.tap(find.byKey(const Key('threadLink')));
    await tester.pump();
    expect(opened, 1, reason: 'тап открывает тред');
  });

  testWidgets('нет сводки треда (обычное сообщение) → строки нет', (
    tester,
  ) async {
    await tester.pumpWidget(bubble(count: null, onOpen: () {}));
    expect(find.byKey(const Key('threadLink')), findsNothing);
  });

  testWidgets('сводка есть, но обработчика нет (например, мы уже ВНУТРИ '
      'треда) → строки нет', (tester) async {
    await tester.pumpWidget(bubble(count: 5));
    expect(find.byKey(const Key('threadLink')), findsNothing);
  });

  testWidgets('нулевой счётчик → строки нет (нечего открывать)', (
    tester,
  ) async {
    await tester.pumpWidget(bubble(count: 0, onOpen: () {}));
    expect(find.byKey(const Key('threadLink')), findsNothing);
  });
}
