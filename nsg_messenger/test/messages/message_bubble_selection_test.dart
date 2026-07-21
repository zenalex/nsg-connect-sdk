import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// Пересылка (мультивыбор): визуал выбранного пузыря + тоггл по тапу.
void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg() => ChatMessage(
    clientTxnId: 'txn',
    matrixEventId: 'e1',
    senderMatrixUserId: '@peer:test',
    senderMessengerUserId: 2,
    body: 'hello',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
  );

  testWidgets('вне режима — нет чекбокса', (tester) async {
    await tester.pumpWidget(
      wrapL10n(MessageBubble(message: msg(), isOwn: false, onRetry: (_) {})),
    );
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('режим + не выбран → пустой кружок', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(),
          isOwn: false,
          onRetry: (_) {},
          selectionMode: true,
          selected: false,
          onToggleSelect: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('режим + выбран → галочка', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(),
          isOwn: false,
          onRetry: (_) {},
          selectionMode: true,
          selected: true,
          onToggleSelect: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('тап по пузырю в режиме → onToggleSelect', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(),
          isOwn: false,
          onRetry: (_) {},
          selectionMode: true,
          selected: false,
          onToggleSelect: () => toggles++,
        ),
      ),
    );
    // Тап по тексту сообщения — в режиме это выбор, а не действие.
    await tester.tap(find.text('hello'));
    await tester.pump();
    expect(toggles, 1);
  });
}
