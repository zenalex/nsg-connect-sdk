import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// Пересылка (forward): шапка «Переслано от X» в bubble пересланного
/// сообщения; для непересланного её нет.
void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg({String? forwardedFromName}) => ChatMessage(
    clientTxnId: 'txn',
    matrixEventId: 'e1',
    senderMatrixUserId: '@self:test',
    senderMessengerUserId: 1,
    body: 'hello',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    forwardedFromName: forwardedFromName,
  );

  testWidgets('forwarded → шапка «Forwarded from Alice»', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(forwardedFromName: 'Alice'),
          isOwn: false,
          onRetry: (_) {},
        ),
      ),
    );
    expect(find.text('Forwarded from Alice'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('RU локаль → «Переслано от Alice»', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(forwardedFromName: 'Alice'),
          isOwn: false,
          onRetry: (_) {},
        ),
        locale: const Locale('ru'),
      ),
    );
    expect(find.text('Переслано от Alice'), findsOneWidget);
  });

  testWidgets('не пересланное → нет шапки', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(message: msg(), isOwn: false, onRetry: (_) {}),
      ),
    );
    expect(find.textContaining('Forwarded from'), findsNothing);
  });
}
