import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show RoomParticipant, RoomMemberRole;
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

import '../test_helpers.dart';

/// Widget-тесты для [MessageComposer] (TASK15 Chunk 2; TASK22 Chunk 1
/// migrated to ARB-generated `NsgL10n`).
void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
      wrapL10n(Column(children: [const Spacer(), child]), locale: locale);

  testWidgets('пустой text → send-button disabled', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
        ),
      ),
    );
    final btn = tester.widget<IconButton>(find.byType(IconButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('text → send-button enabled; tap отправляет + clears field', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'привет');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, ['привет']);
    expect(find.text('привет'), findsNothing, reason: 'field cleared');
  });

  testWidgets(
    'body > 4096 chars → отправляется обрезанным до лимита (никогда не '
    'улетает server-side MessageBodyTooLargeException)',
    (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        wrap(
          MessageComposer(
            onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
          ),
        ),
      );
      // 5000 символов — выше лимита 4096. maxLength=enforced обрезает на
      // вводе; defensive clamp в _submit — второй пояс.
      await tester.enterText(find.byType(TextField), 'a' * 5000);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(sent.length, 1);
      expect(
        sent.single.length,
        4096,
        reason: 'body обрезан до kMessageBodyMaxChars перед отправкой',
      );
    },
  );

  testWidgets('hardware Enter submits (desktop) without Shift', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    // Hardware Enter без модификаторов → submit через
    // HardwareKeyboard.addHandler (см. doc у `_globalKeyHandler`).
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    // _submit() в hardware handler-е вызывается через
    // addPostFrameCallback — нужен extra pump чтобы microtask
    // отработала.
    await tester.pump();
    await tester.pump();
    expect(sent, ['hello']);
  });

  testWidgets('hardware Shift+Enter does NOT submit (newline allowed)', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    // Shift+Enter — hardware handler пропускает через guard `!isShift`,
    // submit НЕ должен происходить.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.pump();
    expect(sent, isEmpty);
  });

  testWidgets('whitespace-only → send-button disabled', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    final btn = tester.widget<IconButton>(find.byType(IconButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('enabled=false → TextField + send-button disabled', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
          enabled: false,
        ),
      ),
    );
    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.enabled, isFalse);
    final btn = tester.widget<IconButton>(find.byType(IconButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('EN placeholder + send tooltip', (tester) async {
    // Заметка: RU-аналог не тестируем здесь — TextField требует
    // MaterialLocalizations для не-EN локалей, что в SDK без
    // flutter_localizations dep не доступно. RU-pattern проверен в
    // message_bubble_test (там TextField нет).
    await tester.pumpWidget(
      wrap(MessageComposer(onSend: (_, {mentionedMessengerUserIds}) async {})),
    );
    expect(find.text('Message…'), findsOneWidget);
    final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
    expect(tooltips.any((t) => t.message == 'Send'), isTrue);
  });

  // ─── B12: edit-mode ──────────────────────────────────────────────────

  ChatMessage ownSent(String body) => ChatMessage(
    clientTxnId: 'tx',
    matrixEventId: r'$evt-1',
    senderMatrixUserId: '@me:localhost',
    senderMessengerUserId: 7,
    body: body,
    msgType: 'm.text',
    serverTimestamp: DateTime.now().toUtc(),
    status: ChatMessageStatus.sent,
  );

  testWidgets('↑-arrow в пустом composer → onRequestEditLast', (tester) async {
    var requested = 0;
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (_, {mentionedMessengerUserIds}) async {},
          onRequestEditLast: () => requested++,
        ),
      ),
    );
    // Focus поле сначала, иначе global handler не сработает.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(requested, 1);
  });

  testWidgets('↑-arrow в non-empty composer — no-op (курсор-навигация)', (
    tester,
  ) async {
    var requested = 0;
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (_, {mentionedMessengerUserIds}) async {},
          onRequestEditLast: () => requested++,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(requested, 0);
  });

  testWidgets(
    'editTarget non-null → pre-populate body + Enter routes to onEdit',
    (tester) async {
      final sent = <String>[];
      final edits = <List<dynamic>>[];
      Widget build(ChatMessage? target) => wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds}) async => sent.add(b),
          editTarget: target,
          onEdit: (id, body, {mentionedMessengerUserIds}) async {
            edits.add([id, body]);
          },
          onCancelEdit: () {},
        ),
      );
      await tester.pumpWidget(build(null));
      await tester.pump();
      // Transition в edit-mode.
      await tester.pumpWidget(build(ownSent('first version')));
      await tester.pump();
      // body должен быть pre-populated в TextField (+ preview в
      // edit-chip — matches >= 1).
      expect(find.text('first version'), findsAtLeast(1));
      // Edit body + Enter → onEdit fires, onSend не fires.
      await tester.enterText(find.byType(TextField), 'edited version');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(edits.length, 1);
      expect(edits.first, [r'$evt-1', 'edited version']);
      expect(sent, isEmpty);
    },
  );

  testWidgets('Esc в edit-mode → onCancelEdit (приоритет над reply)', (
    tester,
  ) async {
    var cancelEdit = 0;
    var cancelReply = 0;
    final reply = ownSent('reply target');
    final edit = ownSent('edit target');
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (_, {mentionedMessengerUserIds}) async {},
          editTarget: edit,
          replyTarget: reply,
          onEdit: (_, _, {mentionedMessengerUserIds}) async {},
          onCancelEdit: () => cancelEdit++,
          onCancelReply: () => cancelReply++,
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(cancelEdit, 1);
    expect(cancelReply, 0);
  });

  testWidgets('editTarget transition null → ChatMessage focuses TextField', (
    tester,
  ) async {
    Widget build(ChatMessage? target) => wrap(
      MessageComposer(
        onSend: (_, {mentionedMessengerUserIds}) async {},
        editTarget: target,
        onEdit: (_, _, {mentionedMessengerUserIds}) async {},
        onCancelEdit: () {},
      ),
    );
    await tester.pumpWidget(build(null));
    await tester.pump();
    await tester.pumpWidget(build(ownSent('hello')));
    await tester.pumpAndSettle();
    // TextField должно иметь фокус.
    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.focusNode?.hasFocus, isTrue);
  });

  // ===================== B12: Tab-autocomplete + markdown =====================

  RoomParticipant participant({
    required int id,
    required String matrix,
    String? name,
  }) => RoomParticipant(
    messengerUserId: id,
    matrixUserId: matrix,
    displayName: name,
    role: RoomMemberRole.member,
  );

  TextEditingController ctlOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  testWidgets('B12: Tab при открытом @-typeahead вставляет первый вариант', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (_, {mentionedMessengerUserIds}) async {},
          participants: [
            participant(id: 1, matrix: '@bob:localhost', name: 'Bob'),
            participant(id: 2, matrix: '@bill:localhost', name: 'Bill'),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@Bo');
    await tester.pumpAndSettle();
    // Typeahead открыт; Tab выбирает первый отфильтрованный (Bob).
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ctlOf(tester).text, '@Bob ');
  });

  testWidgets('B12: Tab без открытого typeahead — НЕ вставляет (no-op)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (_, {mentionedMessengerUserIds}) async {},
          participants: [
            participant(id: 1, matrix: '@bob:localhost', name: 'Bob'),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // Текст не изменился — typeahead закрыт, Tab не перехвачен composer-ом.
    expect(ctlOf(tester).text, 'hello');
  });

  testWidgets('B12: Ctrl+B оборачивает выделение в **bold**', (tester) async {
    await tester.pumpWidget(
      wrap(MessageComposer(onSend: (_, {mentionedMessengerUserIds}) async {})),
    );
    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.pump();
    ctlOf(tester).selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    ); // "hello"
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(ctlOf(tester).text, '**hello** world');
  });

  testWidgets('B12: Ctrl+I оборачивает выделение в _italic_', (tester) async {
    await tester.pumpWidget(
      wrap(MessageComposer(onSend: (_, {mentionedMessengerUserIds}) async {})),
    );
    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.pump();
    ctlOf(tester).selection = const TextSelection(
      baseOffset: 6,
      extentOffset: 11,
    ); // "world"
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(ctlOf(tester).text, 'hello _world_');
  });

  testWidgets('B12: Ctrl+B при пустом выделении вставляет пару маркеров', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(MessageComposer(onSend: (_, {mentionedMessengerUserIds}) async {})),
    );
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    ctlOf(tester).selection = const TextSelection.collapsed(offset: 2);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(ctlOf(tester).text, 'hi****');
    // Каретка между маркерами (offset = 2 + len('**') = 4).
    expect(ctlOf(tester).selection.baseOffset, 4);
  });
}
