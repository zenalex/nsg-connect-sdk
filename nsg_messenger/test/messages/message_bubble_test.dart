import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// Widget-тесты для [MessageBubble] (TASK15 Chunk 2). Используем тот
/// же паттерн `MaterialApp` + `Localizations.override` что в
/// `room_summary_tile_test.dart` — SDK не depends на
/// flutter_localizations.
void main() {
  setUpAll(registerTimeagoLocales);

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
      wrapL10n(child, locale: locale);

  ChatMessage msg({
    required ChatMessageStatus status,
    String body = 'hello',
    String? clientTxnId = 'TXN-test',
    String? matrixEventId,
    Object? lastError,
  }) => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: matrixEventId,
    senderMatrixUserId: '@self:test',
    senderMessengerUserId: 1,
    body: body,
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: status,
    lastError: lastError,
  );

  testWidgets('own bubble aligns right; peer aligns left', (tester) async {
    final ownMsg = msg(status: ChatMessageStatus.sent);
    await tester.pumpWidget(
      wrap(MessageBubble(message: ownMsg, isOwn: true, onRetry: (_) {})),
    );
    expect(find.text('hello'), findsOneWidget);
    final ownRow = tester
        .widgetList<Row>(find.byType(Row))
        .firstWhere((r) => r.mainAxisAlignment != MainAxisAlignment.start);
    expect(ownRow.mainAxisAlignment, MainAxisAlignment.end);

    await tester.pumpWidget(
      wrap(MessageBubble(message: ownMsg, isOwn: false, onRetry: (_) {})),
    );
    final peerRow = tester
        .widgetList<Row>(find.byType(Row))
        .firstWhere((r) => r.mainAxisAlignment == MainAxisAlignment.start);
    expect(peerRow.mainAxisAlignment, MainAxisAlignment.start);
  });

  testWidgets('pending → spinner indicator', (tester) async {
    final m = msg(status: ChatMessageStatus.pending);
    await tester.pumpWidget(
      wrap(MessageBubble(message: m, isOwn: true, onRetry: (_) {})),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('sent → checkmark icon у own', (tester) async {
    final m = msg(status: ChatMessageStatus.sent, matrixEventId: 'e-real');
    await tester.pumpWidget(
      wrap(MessageBubble(message: m, isOwn: true, onRetry: (_) {})),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('sent peer-bubble — БЕЗ status icon (только own)', (
    tester,
  ) async {
    final m = msg(status: ChatMessageStatus.sent, matrixEventId: 'e-real');
    await tester.pumpWidget(
      wrap(MessageBubble(message: m, isOwn: false, onRetry: (_) {})),
    );
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('failed → error icon + retry callback срабатывает', (
    tester,
  ) async {
    final m = msg(
      status: ChatMessageStatus.failed,
      lastError: StateError('network down'),
    );
    ChatMessage? retried;
    await tester.pumpWidget(
      wrap(
        MessageBubble(message: m, isOwn: true, onRetry: (mm) => retried = mm),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.error_outline));
    expect(retried, isNotNull);
    expect(retried!.clientTxnId, 'TXN-test');
  });

  testWidgets('RU локаль для retry-tooltip', (tester) async {
    final m = msg(status: ChatMessageStatus.failed);
    await tester.pumpWidget(
      wrap(
        MessageBubble(message: m, isOwn: true, onRetry: (_) {}),
        locale: const Locale('ru'),
      ),
    );
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Повторить');
  });

  // ---------------------------------------------------------------
  // TASK22 Phase2 Chunk 1: interBubbleSpacing token integration.
  // ---------------------------------------------------------------
  testWidgets(
    'interBubbleSpacing override → outer Padding vertical = spacing / 2',
    (tester) async {
      const customSpacing = 24.0;
      const customTokens = NsgMessageBubbleTokens(
        radiusOwn: BorderRadius.all(Radius.circular(16)),
        radiusPeer: BorderRadius.all(Radius.circular(16)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        maxWidthFraction: 0.78,
        statusIconSize: 14,
        interBubbleSpacing: customSpacing,
        composerPadding: EdgeInsets.zero,
      );
      final m = msg(status: ChatMessageStatus.sent);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            NsgL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: NsgL10n.supportedLocales,
          theme: ThemeData(extensions: const [customTokens]),
          home: Scaffold(
            body: MessageBubble(message: m, isOwn: true, onRetry: (_) {}),
          ),
        ),
      );
      // Outermost Padding в MessageBubble — первый Padding под Scaffold.body.
      // Используем `find.byType(MessageBubble) → descendant`, чтобы взять
      // первый Padding в дерева bubble-а.
      final outerPadding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(MessageBubble),
              matching: find.byType(Padding),
            )
            .first,
      );
      final insets = outerPadding.padding as EdgeInsets;
      expect(insets.top, customSpacing / 2);
      expect(insets.bottom, customSpacing / 2);
    },
  );
}
