/// **issue #57**: длинный текст в композере уходит частями, а не режется.
///
/// Инцидент постановщика: вставил длинный текст — он молча обрезался на
/// 4096, и потерю легко не заметить. Здесь защищаем именно наблюдаемое
/// поведение композера: сколько сообщений ушло, в каком порядке, что
/// осталось в поле.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

import '../test_helpers.dart';

void main() {
  _codeFormattingTests();
  Widget wrap(Widget child, {Locale locale = const Locale('ru')}) =>
      wrapL10n(Column(children: [const Spacer(), child]), locale: locale);

  Future<List<String>> typeAndSend(WidgetTester tester, String text) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (body, {mentionedMessengerUserIds, albumId}) async {
            sent.add(body);
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    return sent;
  }

  testWidgets('текст в лимите — одно сообщение (поведение не изменилось)', (
    tester,
  ) async {
    final sent = await typeAndSend(tester, 'привет');
    expect(sent, ['привет']);
  });

  testWidgets('длинный текст уходит частями, а не обрезается', (tester) async {
    // Две части: 3 части и меньше отправляются без вопросов.
    final text = List.generate(700, (i) => 'слово$i').join(' ');
    expect(text.length, greaterThan(kMessageBodyMaxChars));

    final sent = await typeAndSend(tester, text);

    expect(sent.length, greaterThan(1), reason: 'разбили, а не обрезали');
    for (final part in sent) {
      expect(part.length, lessThanOrEqualTo(kMessageBodyMaxChars));
    }
    // Ничего не потеряно и порядок сохранён.
    expect(sent.join(' ').split(RegExp(r'\s+')), text.split(' '));
  });

  testWidgets('поле очищается только после отправки всех частей', (
    tester,
  ) async {
    final text = List.generate(700, (i) => 'сл$i').join(' ');
    await typeAndSend(tester, text);
    expect(find.text(text), findsNothing);
  });

  testWidgets('много частей — спрашиваем; отказ ничего не шлёт и текст цел', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (body, {mentionedMessengerUserIds, albumId}) async {
            sent.add(body);
          },
        ),
      ),
    );
    // Заведомо больше kSplitConfirmThreshold частей.
    final text = 'x' * (kMessageBodyMaxChars * 5);
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Длинный текст'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(sent, isEmpty, reason: 'отказ — не отправляем');
    expect(
      find.byType(TextField),
      findsOneWidget,
      reason: 'текст остаётся у автора, а не пропадает',
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, text);
  });

  testWidgets('много частей — подтверждение отправляет всё по порядку', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (body, {mentionedMessengerUserIds, albumId}) async {
            sent.add(body);
          },
        ),
      ),
    );
    final text = List.generate(4000, (i) => 'w$i').join(' ');
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отправить'));
    await tester.pumpAndSettle();

    expect(sent.length, greaterThan(3));
    expect(sent.join(' ').split(RegExp(r'\s+')), text.split(' '));
  });
}

// ── issue #70: оформление выделения как кода ─────────────────────────────
void _codeFormattingTests() {
  Widget wrap(Widget child) =>
      wrapL10n(Column(children: [const Spacer(), child]), locale: const Locale('ru'));

  Future<TextEditingController> pumpWith(WidgetTester tester, String text,
      {required int start, required int end}) async {
    late TextEditingController ctl;
    await tester.pumpWidget(
      wrap(
        MessageComposer(
          onSend: (b, {mentionedMessengerUserIds, albumId}) async {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    ctl = tester.widget<TextField>(find.byType(TextField)).controller!;
    ctl.selection = TextSelection(baseOffset: start, extentOffset: end);
    await tester.pump();
    return ctl;
  }

  Future<void> pressCodeShortcut(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('однострочное выделение → inline-код (не рвём абзац)', (
    tester,
  ) async {
    final ctl = await pumpWith(tester, 'смотри foo тут', start: 7, end: 10);
    await pressCodeShortcut(tester);
    expect(ctl.text, 'смотри `foo` тут');
  });

  testWidgets('многострочное выделение → блок ``` со своих строк', (
    tester,
  ) async {
    final ctl = await pumpWith(tester, 'a\nb', start: 0, end: 3);
    await pressCodeShortcut(tester);
    expect(ctl.text, '```\na\nb\n```');
  });

  testWidgets('блок отделяется от соседнего текста переводами строк', (
    tester,
  ) async {
    final ctl = await pumpWith(tester, 'до x\ny после', start: 3, end: 6);
    await pressCodeShortcut(tester);
    // Ограждение не должно прилипнуть к «до» — иначе это уже не блок.
    expect(ctl.text.contains('до \n```'), isTrue, reason: ctl.text);
  });
}
