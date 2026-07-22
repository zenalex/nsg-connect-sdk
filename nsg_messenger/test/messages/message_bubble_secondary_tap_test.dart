import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// Issue #6: правый клик мыши (desktop/web) по пузырю вызывает тот же
/// [MessageBubble.onLongPress], что и long-press, — и подчиняется ТЕМ ЖЕ
/// гардам: не-tombstone, вне selectionMode и либо sent (полный набор
/// действий), либо своё ещё-не-ушедшее с `clientTxnId` (**OUTBOX**:
/// повторить / отменить отправку). Long-press на мобиле не меняется —
/// right-click добавлен параллельно.
void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg({
    ChatMessageStatus status = ChatMessageStatus.sent,
    String? matrixEventId = 'e1',
    DateTime? deletedAt,
  }) => ChatMessage(
    clientTxnId: 'txn',
    matrixEventId: matrixEventId,
    senderMatrixUserId: '@peer:test',
    senderMessengerUserId: 2,
    body: 'hello',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: status,
    deletedAt: deletedAt,
  );

  testWidgets('правый клик по sent-пузырю → onLongPress вызван', (
    tester,
  ) async {
    ChatMessage? opened;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(),
          isOwn: false,
          onRetry: (_) {},
          onLongPress: (m) => opened = m,
        ),
      ),
    );
    await tester.tap(find.text('hello'), buttons: kSecondaryButton);
    await tester.pump();
    expect(opened, isNotNull);
    expect(opened!.matrixEventId, 'e1');
  });

  testWidgets('long-press остаётся рабочим параллельно с правым кликом', (
    tester,
  ) async {
    ChatMessage? opened;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(),
          isOwn: false,
          onRetry: (_) {},
          onLongPress: (m) => opened = m,
        ),
      ),
    );
    await tester.longPress(find.text('hello'));
    await tester.pump();
    expect(opened, isNotNull);
  });

  testWidgets('tombstone → правый клик НЕ открывает меню', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(deletedAt: DateTime.utc(2026, 1, 2)),
          isOwn: false,
          onRetry: (_) {},
          onLongPress: (_) => calls++,
        ),
      ),
    );
    // Tombstone рендерит placeholder вместо body.
    await tester.tap(
      find.text('Message deleted'),
      buttons: kSecondaryButton,
      warnIfMissed: false,
    );
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('своё pending (строка очереди) → правый клик ОТКРЫВАЕТ меню', (
    tester,
  ) async {
    // **OUTBOX**: у не-отправленного своего сообщения есть свои действия
    // («повторить» / «отменить отправку»), и на десктопе они должны быть
    // доступны тем же правым кликом. Раньше гейт требовал `isSent` — и
    // зависшую в очереди строку нельзя было ни повторить, ни убрать.
    var calls = 0;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(status: ChatMessageStatus.pending, matrixEventId: null),
          isOwn: true,
          onRetry: (_) {},
          onLongPress: (_) => calls++,
        ),
      ),
    );
    await tester.tap(
      find.text('hello'),
      buttons: kSecondaryButton,
      warnIfMissed: false,
    );
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('чужое без matrixEventId → правый клик игнорируется', (
    tester,
  ) async {
    // Не своё и не отправлено — действий нет вообще: ни очереди за ним
    // (очередь только своя), ни stable event id для reply/forward/pin.
    var calls = 0;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(status: ChatMessageStatus.pending, matrixEventId: null),
          isOwn: false,
          onRetry: (_) {},
          onLongPress: (_) => calls++,
        ),
      ),
    );
    await tester.tap(
      find.text('hello'),
      buttons: kSecondaryButton,
      warnIfMissed: false,
    );
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('selectionMode → правый клик НЕ открывает меню и НЕ тогглит', (
    tester,
  ) async {
    var calls = 0;
    var toggles = 0;
    await tester.pumpWidget(
      wrapL10n(
        MessageBubble(
          message: msg(),
          isOwn: false,
          onRetry: (_) {},
          onLongPress: (_) => calls++,
          selectionMode: true,
          selected: false,
          onToggleSelect: () => toggles++,
        ),
      ),
    );
    await tester.tap(
      find.text('hello'),
      buttons: kSecondaryButton,
      warnIfMissed: false,
    );
    await tester.pump();
    expect(calls, 0);
    expect(toggles, 0);
  });
}
