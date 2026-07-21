import 'dart:async';

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
      String? albumId,
    })
    onSend,
    List<RoomParticipant>? participants,
    int? totalParticipants,
    ChatMessage? replyTarget,
    String? replyTargetSenderName,
    VoidCallback? onCancelReply,
    Stream<RoomParticipant>? mentionInsertRequests,
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
        mentionInsertRequests: mentionInsertRequests,
      ),
    ),
  );

  RoomParticipant p({
    required int id,
    required String matrix,
    String? name,
    String? username,
    String? avatarUrl,
  }) => RoomParticipant(
    messengerUserId: id,
    matrixUserId: matrix,
    displayName: name,
    username: username,
    avatarUrl: avatarUrl,
    role: RoomMemberRole.member,
  );

  testWidgets('@-typeahead: ввод "@Bo" фильтрует participant', (tester) async {
    final participants = [
      p(id: 1, matrix: '@alice:localhost', name: 'Alice'),
      p(id: 2, matrix: '@bob:localhost', name: 'Bob'),
    ];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
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
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
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
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
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
        onSend: (body, {mentionedMessengerUserIds, albumId}) async {
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
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
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

  testWidgets('TASK69 2A: typeahead-строка рендерит аватар + @username', (
    tester,
  ) async {
    final participants = [
      p(id: 1, matrix: '@alice:localhost', name: 'Alice', username: 'alice_h'),
      p(id: 2, matrix: '@bob:localhost', name: 'Bob'),
    ];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
        participants: participants,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@');
    await tester.pumpAndSettle();
    // Аватар на каждую строку (визуальный якорь вместо обезличенной иконки).
    expect(find.byType(NsgAvatarImage), findsNWidgets(2));
    // Публичный @username для того, у кого он есть.
    expect(find.text('@alice_h'), findsOneWidget);
    // Fallback на matrix-localpart с `@`, если username пуст.
    expect(find.text('@bob'), findsOneWidget);
  });

  testWidgets('TASK69 2A: фильтр по @username находит участника', (
    tester,
  ) async {
    final participants = [
      p(id: 1, matrix: '@u1:localhost', name: 'Иван', username: 'vanya'),
      p(id: 2, matrix: '@u2:localhost', name: 'Пётр', username: 'petya'),
    ];
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
        participants: participants,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    // Набираем по username, а не по displayName.
    await tester.enterText(find.byType(TextField), '@vany');
    await tester.pumpAndSettle();
    expect(find.text('Иван'), findsOneWidget);
    expect(find.text('Пётр'), findsNothing);
  });

  testWidgets(
    'TASK69 2C: mentionInsertRequests вставляет @имя + уходит в mentions',
    (tester) async {
      final inserts = StreamController<RoomParticipant>.broadcast();
      addTearDown(inserts.close);
      final captured = <List<int>?>[];
      await tester.pumpWidget(
        pumpComposer(
          onSend: (body, {mentionedMessengerUserIds, albumId}) async {
            captured.add(mentionedMessengerUserIds);
          },
          mentionInsertRequests: inserts.stream,
        ),
      );
      // Уже есть текст — проверяем ведущий пробел перед вставкой.
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();
      inserts.add(p(id: 7, matrix: '@bob:localhost', name: 'Bob'));
      await tester.pumpAndSettle();
      expect(find.text('hi @Bob '), findsOneWidget);
      // На send автор уходит в mention-flow.
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(captured, [
        [7],
      ]);
    },
  );

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
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
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

  // Issue #21: вход в reply-режим должен сразу дать фокус полю ввода —
  // пользователь печатает ответ без дополнительного тапа.
  testWidgets('reply: вход в reply-режим фокусирует поле ввода', (
    tester,
  ) async {
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

    // Изначально reply-режим не активен — поле НЕ сфокусировано.
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isFalse,
    );

    // Переход null → replyTarget (эквивалент tap «Ответить»): didUpdateWidget
    // запрашивает фокус.
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
        replyTarget: target,
        replyTargetSenderName: 'Bob',
        onCancelReply: () {},
      ),
    );
    await tester.pump();

    expect(find.text('Replying to Bob'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
      reason: 'после входа в reply-режим поле ввода должно быть сфокусировано',
    );
  });

  // issue #43: попап всплывает НАД лентой сообщений. В Glass-темах
  // `colorScheme.surface` прозрачный, поэтому Material без явного `color`
  // рисовался без подложки — сквозь список подсказок читался чат.
  group('issue #43: подложка попапа @-подсказок', () {
    testWidgets('фон задан явно и непрозрачен', (tester) async {
      await tester.pumpWidget(
        pumpComposer(
          onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
          participants: [
            p(id: 1, matrix: '@alice:localhost', name: 'Alice'),
            p(id: 2, matrix: '@bob:localhost', name: 'Bob'),
          ],
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '@Bo');
      await tester.pumpAndSettle();

      // Попап действительно открыт — иначе тест «проходил» бы вхолостую.
      expect(find.text('Bob'), findsOneWidget);

      final popup = tester.widget<Material>(
        find.byKey(kMentionTypeaheadPopupKey),
      );
      expect(
        popup.color,
        isNotNull,
        reason: 'без явного color Material возьмёт прозрачный surface',
      );
      expect(
        popup.color!.a,
        greaterThan(0.9),
        reason: 'сквозь подложку не должна читаться лента сообщений',
      );
      expect(popup.color, kOverlaySurface);
    });

    testWidgets('фон непрозрачен и на Glass-теме, где surface прозрачный', (
      tester,
    ) async {
      // Регрессия ловится именно здесь: на Glass-палитре surface = 0x00000000,
      // и любой возврат к дефолтному фону снова сделает попап сквозным.
      final glass = ChatistaTheme.glassSunset();
      expect(
        glass.colorScheme!.surface.a,
        0.0,
        reason: 'предпосылка теста: в Glass-теме surface прозрачный',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: NsgL10n.localizationsDelegates,
          supportedLocales: NsgL10n.supportedLocales,
          theme: ThemeData.from(colorScheme: glass.colorScheme!),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: MessageComposer(
              onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
              participants: [p(id: 2, matrix: '@bob:localhost', name: 'Bob')],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '@Bo');
      await tester.pumpAndSettle();

      final popup = tester.widget<Material>(
        find.byKey(kMentionTypeaheadPopupKey),
      );
      expect(popup.color?.a, greaterThan(0.9));
      expect(
        popup.color,
        isNot(glass.colorScheme!.surface),
        reason: 'попап не должен наследовать прозрачный surface темы',
      );
    });
  });
}
