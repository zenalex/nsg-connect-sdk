import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// **Issue #41**: кликабельность шапки «Переслано от X».
///
/// Главное свойство — шапка НЕ выглядит кликабельной, когда переход
/// невозможен. Координат нет у всех сообщений, пересланных до issue #41, и
/// это самый частый случай, а не редкий сбой.
void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg({ForwardSource? source}) => ChatMessage(
    clientTxnId: 'txn',
    matrixEventId: 'e1',
    senderMatrixUserId: '@self:test',
    senderMessengerUserId: 1,
    body: 'hello',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    forwardedFromName: 'Alice',
    forwardedSource: source,
  );

  /// InkWell именно вокруг шапки (в пузыре есть и другие).
  Finder headerInk() => find.ancestor(
    of: find.text('Forwarded from Alice'),
    matching: find.byType(InkWell),
  );

  testWidgets(
    'координаты + обработчик → шапка кликабельна, тап отдаёт источник',
    (tester) async {
      ForwardSource? tapped;
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: msg(
              source: const ForwardSource(roomId: 77, eventId: r'$o'),
            ),
            isOwn: false,
            onRetry: (_) {},
            onForwardedHeaderTap: (s) => tapped = s,
          ),
        ),
      );

      expect(headerInk(), findsOneWidget);
      await tester.tap(find.text('Forwarded from Alice'));
      await tester.pump();
      expect(tapped, const ForwardSource(roomId: 77, eventId: r'$o'));
    },
  );

  testWidgets('старое пересланное (координат нет) → шапка НЕ кликабельна', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(), // forwardedSource == null
          isOwn: false,
          onRetry: (_) {},
          onForwardedHeaderTap: (_) => taps++,
        ),
      ),
    );

    expect(find.text('Forwarded from Alice'), findsOneWidget);
    expect(headerInk(), findsNothing, reason: 'без координат — не кнопка');
    await tester.tap(find.text('Forwarded from Alice'), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('координаты есть, но хост не дал обработчик → не кликабельна', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(source: const ForwardSource(roomId: 77, eventId: r'$o')),
          isOwn: false,
          onRetry: (_) {},
        ),
      ),
    );
    expect(find.text('Forwarded from Alice'), findsOneWidget);
    expect(headerInk(), findsNothing);
  });
}
