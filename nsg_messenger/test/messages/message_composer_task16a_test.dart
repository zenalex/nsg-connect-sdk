import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

/// TASK16-A: tests для @-typeahead + reply quote chip + mention выбор
/// прокидывается в onSend.
void main() {
  Widget pumpComposer({
    required Future<void> Function(
      String body, {
      List<int>? mentionedMessengerUserIds,
    })
    onSend,
    List<RoomParticipant>? participants,
    int? totalParticipants,
    ChatMessage? replyTarget,
    String? replyTargetSenderName,
    VoidCallback? onCancelReply,
  }) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        onSend: onSend,
        participants: participants,
        totalParticipants: totalParticipants,
        replyTarget: replyTarget,
        replyTargetSenderName: replyTargetSenderName,
        onCancelReply: onCancelReply,
      ),
    ),
  );

  RoomParticipant p({required int id, required String matrix, String? name}) =>
      RoomParticipant(
        messengerUserId: id,
        matrixUserId: matrix,
        displayName: name,
        role: RoomMemberRole.member,
      );

  testWidgets('@-typeahead: ввод "@Bo" фильтрует participant', (tester) async {
    final participants = [
      p(id: 1, matrix: '@alice:localhost', name: 'Alice'),
      p(id: 2, matrix: '@bob:localhost', name: 'Bob'),
    ];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds}) async {},
        participants: participants,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@Bo');
    await tester.pumpAndSettle();
    // Typeahead показывает Bob (matched), Alice — отфильтрован.
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('@-typeahead: cyrillic query фильтрует RU displayname', (
    tester,
  ) async {
    final participants = [
      p(id: 1, matrix: '@aleksandr:localhost', name: 'александр'),
      p(id: 2, matrix: '@bob:localhost', name: 'Bob'),
    ];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds}) async {},
        participants: participants,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@алек');
    await tester.pumpAndSettle();
    expect(find.text('александр'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('@-typeahead: empty-state когда нет матчей', (tester) async {
    final participants = [p(id: 1, matrix: '@alice:localhost', name: 'Alice')];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds}) async {},
        participants: participants,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@xyz');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('send без picked mention → onSend получает null mentions', (
    tester,
  ) async {
    final captured = <List<int>?>[];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (body, {mentionedMessengerUserIds}) async {
          captured.add(mentionedMessengerUserIds);
        },
      ),
    );
    await tester.enterText(find.byType(TextField), 'plain text');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(captured, [null]);
  });

  testWidgets('@-typeahead: header «Showing 30 of 50» при cap', (tester) async {
    final participants = List.generate(
      30,
      (i) => p(id: i, matrix: '@u$i:localhost', name: 'User$i'),
    );
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds}) async {},
        participants: participants,
        totalParticipants: 50,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@');
    await tester.pumpAndSettle();
    expect(find.text('Showing 30 of 50'), findsOneWidget);
  });

  testWidgets('reply quote chip: показывает sender + cancel callback', (
    tester,
  ) async {
    var cancelled = 0;
    final target = ChatMessage(
      clientTxnId: 't1',
      matrixEventId: 'ev1',
      senderMatrixUserId: '@bob:localhost',
      senderMessengerUserId: 2,
      body: 'orig',
      msgType: 'm.text',
      serverTimestamp: DateTime.utc(2026, 1, 1),
      status: ChatMessageStatus.sent,
    );
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds}) async {},
        replyTarget: target,
        replyTargetSenderName: 'Bob',
        onCancelReply: () => cancelled++,
      ),
    );
    expect(find.text('Replying to Bob'), findsOneWidget);
    expect(find.text('orig'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(cancelled, 1);
  });
}
