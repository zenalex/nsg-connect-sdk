import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/widgets/nsg_avatar_image.dart';

import '../test_helpers.dart';

/// TASK16-A: tests для reply chip + mention highlighting в bubble.
void main() {
  setUpAll(registerTimeagoLocales);

  Widget wrap(Widget child) => wrapL10n(child);

  ChatMessage make({
    String body = 'hi',
    String matrixEventId = 'ev1',
    String senderMatrix = '@alice:localhost',
    int sender = 1,
    String? replyTo,
    List<int>? mentioned,
  }) => ChatMessage(
    clientTxnId: 'txn-$matrixEventId',
    matrixEventId: matrixEventId,
    senderMatrixUserId: senderMatrix,
    senderMessengerUserId: sender,
    body: body,
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    replyToMessageId: replyTo,
    mentionedMessengerUserIds: mentioned,
  );

  RoomParticipant participant({
    required int messengerId,
    required String matrix,
    String? displayName,
  }) => RoomParticipant(
    messengerUserId: messengerId,
    matrixUserId: matrix,
    displayName: displayName,
    role: RoomMemberRole.member,
  );

  testWidgets('reply chip: cache hit рендерит sender name + preview', (
    tester,
  ) async {
    final original = make(
      matrixEventId: 'ev-orig',
      body: 'original body',
      senderMatrix: '@bob:localhost',
      sender: 2,
    );
    final reply = make(matrixEventId: 'ev-reply', replyTo: 'ev-orig');
    final bob = participant(
      messengerId: 2,
      matrix: '@bob:localhost',
      displayName: 'Bob',
    );
    await tester.pumpWidget(
      wrap(
        MessageBubble(
          message: reply,
          isOwn: false,
          onRetry: (_) {},
          findReplyTarget: (id) => id == 'ev-orig' ? original : null,
          onReplyChipTap: (_) {},
          participantsByMessengerId: {2: bob},
          participantsByMatrixId: {'@bob:localhost': bob},
        ),
      ),
    );
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('original body'), findsOneWidget);
  });

  testWidgets('reply chip: cache miss → italic «unavailable» placeholder', (
    tester,
  ) async {
    final reply = make(matrixEventId: 'ev-reply', replyTo: 'ev-missing');
    await tester.pumpWidget(
      wrap(
        MessageBubble(
          message: reply,
          isOwn: false,
          onRetry: (_) {},
          findReplyTarget: (_) => null,
        ),
      ),
    );
    expect(find.text('Original message unavailable'), findsOneWidget);
  });

  testWidgets('mention highlighting: only matching token styled', (
    tester,
  ) async {
    final m = make(body: 'hey @Bob and also @nobody', mentioned: [2]);
    final bob = participant(
      messengerId: 2,
      matrix: '@bob:localhost',
      displayName: 'Bob',
    );
    await tester.pumpWidget(
      wrap(
        MessageBubble(
          message: m,
          isOwn: false,
          onRetry: (_) {},
          participantsByMessengerId: {2: bob},
        ),
      ),
    );
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final bubbleRich = richTexts.firstWhere((r) {
      final t = r.text.toPlainText();
      return t.contains('@Bob') && t.contains('@nobody');
    });
    // Collect все TextSpan-ы recursively.
    final all = <TextSpan>[];
    void collect(InlineSpan s) {
      if (s is TextSpan) {
        all.add(s);
        for (final c in s.children ?? const <InlineSpan>[]) collect(c);
      }
    }

    collect(bubbleRich.text);
    final bob1 = all.firstWhere((s) => s.text == '@Bob');
    final nobody = all.firstWhere((s) => s.text == '@nobody');
    expect(bob1.style?.fontWeight, FontWeight.w600);
    expect(nobody.style?.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('mention highlighting: cyrillic displayname (RU customer)', (
    tester,
  ) async {
    final m = make(body: 'привет @александр и @bob', mentioned: [3]);
    final alex = participant(
      messengerId: 3,
      matrix: '@aleksandr:localhost',
      displayName: 'александр',
    );
    await tester.pumpWidget(
      wrap(
        MessageBubble(
          message: m,
          isOwn: false,
          onRetry: (_) {},
          participantsByMessengerId: {3: alex},
        ),
      ),
    );
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final bubbleRich = richTexts.firstWhere((r) {
      final t = r.text.toPlainText();
      return t.contains('@александр');
    });
    final all = <TextSpan>[];
    void collect(InlineSpan s) {
      if (s is TextSpan) {
        all.add(s);
        for (final c in s.children ?? const <InlineSpan>[]) collect(c);
      }
    }

    collect(bubbleRich.text);
    // @александр должен быть match-нут regex-ом (Unicode-aware) и
    // highlighted, потому что mentioned=[3] и displayName='александр'.
    final aleks = all.firstWhere((s) => s.text == '@александр');
    expect(aleks.style?.fontWeight, FontWeight.w600);
    // @bob — НЕ в mentioned array, plain.
    final bobSpan = all.firstWhere((s) => s.text == '@bob');
    expect(bobSpan.style?.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('mention highlighting: empty mentioned → no styling', (
    tester,
  ) async {
    final m = make(body: 'hey @Bob', mentioned: null);
    final bob = participant(
      messengerId: 2,
      matrix: '@bob:localhost',
      displayName: 'Bob',
    );
    await tester.pumpWidget(
      wrap(
        MessageBubble(
          message: m,
          isOwn: false,
          onRetry: (_) {},
          participantsByMessengerId: {2: bob},
        ),
      ),
    );
    // Body просто Text, не RichText (по path-у когда `ids == null`).
    expect(find.text('hey @Bob'), findsOneWidget);
  });

  group('B16-ext (phase2): аватар отправителя слева от bubble', () {
    final bob = participant(
      messengerId: 2,
      matrix: '@bob:localhost',
      displayName: 'Bob',
    );

    testWidgets('group peer + showSenderAvatar → NsgAvatarImage отрисован', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: make(senderMatrix: '@bob:localhost', sender: 2),
            isOwn: false,
            onRetry: (_) {},
            isGroupChat: true,
            participantsByMatrixId: {'@bob:localhost': bob},
            showSenderAvatar: true,
          ),
        ),
      );
      expect(find.byType(NsgAvatarImage), findsOneWidget);
    });

    testWidgets('group peer без showSenderAvatar → spacer (нет аватара)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: make(senderMatrix: '@bob:localhost', sender: 2),
            isOwn: false,
            onRetry: (_) {},
            isGroupChat: true,
            participantsByMatrixId: {'@bob:localhost': bob},
            showSenderAvatar: false,
          ),
        ),
      );
      expect(find.byType(NsgAvatarImage), findsNothing);
    });

    testWidgets('own message в group → аватара нет (даже при showSenderAvatar)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: make(senderMatrix: '@me:localhost', sender: 1),
            isOwn: true,
            onRetry: (_) {},
            isGroupChat: true,
            showSenderAvatar: true,
          ),
        ),
      );
      expect(find.byType(NsgAvatarImage), findsNothing);
    });

    testWidgets('direct (не group) peer → аватара нет', (tester) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: make(senderMatrix: '@bob:localhost', sender: 2),
            isOwn: false,
            onRetry: (_) {},
            isGroupChat: false,
            participantsByMatrixId: {'@bob:localhost': bob},
            showSenderAvatar: true,
          ),
        ),
      );
      expect(find.byType(NsgAvatarImage), findsNothing);
    });
  });
}
