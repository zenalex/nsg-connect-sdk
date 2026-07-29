/// **issue #72 — Windows: Enter не отправляет, Backspace стирает строку.**
///
/// Воспроизведено на живом Windows (стенд с одним композером, клавиши
/// подавались через WinAPI). Достаточно уйти из окна с зажатым
/// модификатором — Alt+Tab, Ctrl+C в другое приложение, Win+L: key-up
/// достаётся уже другому окну, и `HardwareKeyboard` остаётся уверен, что
/// клавиша нажата. Журнал стенда в тот момент:
///
/// ```
/// --- вернулись, физически CTRL отпущен: True ---
/// DOWN Backspace  mods=CTRL+ALT      ← Flutter: «удалить слово»
/// DOWN Enter      mods=ALT           ← гард !isAlt не проходит, submit нет
/// ```
///
/// Отсюда ровно два симптома из жалобы. Синтетический key-up фреймворк
/// присылает, но следом — клавиша к тому моменту уже отработала, и
/// починка опаздывает ровно на одно нажатие.
///
/// Здесь то же состояние строится детерминированно: модификатор нажимаем,
/// пока поле НЕ в фокусе, — композер этого нажатия не видит, а
/// `HardwareKeyboard` его помнит. Это и есть «протухшее» состояние.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

void main() {
  final sent = <String>[];

  Widget app({String initial = 'привет'}) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        initialText: initial,
        onSend: (body, {mentionedMessengerUserIds, albumId}) async {
          sent.add(body);
        },
      ),
    ),
  );

  setUp(sent.clear);

  /// Сфокусировать поле ввода.
  Future<void> focusField(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pump();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('протухший Ctrl не мешает Enter отправить', (tester) async {
    await tester.pumpWidget(app());
    // Модификатор нажат ДО фокуса — композер его не видел, фреймворк помнит.
    await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await focusField(tester);
    expect(
      HardwareKeyboard.instance.isControlPressed,
      isTrue,
      reason: 'состояние фреймворка должно быть именно «грязным»',
    );

    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(sent, ['привет'], reason: 'ровно этого не происходило у оператора');
    await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
  });

  testWidgets('протухший Ctrl не превращает Backspace в «удалить слово»', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await focusField(tester);

    await simulateKeyDownEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(
      fieldText(tester),
      'приве',
      reason: 'один символ, а не слово целиком',
    );
    await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
  });

  testWidgets('НАСТОЯЩИЙ Shift+Enter по-прежнему даёт перенос строки', (
    tester,
  ) async {
    // Обратная сторона: правка не должна сделать модификаторы «невидимыми».
    await tester.pumpWidget(app());
    await focusField(tester);
    await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(sent, isEmpty, reason: 'Shift+Enter — это перенос, а не отправка');
    await simulateKeyUpEvent(LogicalKeyboardKey.enter);
    await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  });

  testWidgets('чистый Enter отправляет (базовое поведение не сломано)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await focusField(tester);
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(sent, ['привет']);
  });

  testWidgets('чистый Backspace обрабатывает поле само (мы не вмешиваемся)', (
    tester,
  ) async {
    // Без протухшего состояния перехватывать Backspace нельзя: иначе
    // сломается штатный Ctrl+Backspace («удалить слово») на десктопе.
    await tester.pumpWidget(app());
    await focusField(tester);
    await simulateKeyDownEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(fieldText(tester), 'приве');
  });

  testWidgets('отпущенный после возврата фокуса модификатор забывается', (
    tester,
  ) async {
    // Смена фокуса — единственный момент, когда состояние могло уехать;
    // после неё композер набирает его заново.
    await tester.pumpWidget(app());
    await focusField(tester);
    await simulateKeyDownEvent(LogicalKeyboardKey.altLeft);

    // Уходим и возвращаемся — «отпустили» Alt в чужом окне.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await focusField(tester);

    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(sent, ['привет']);
    await simulateKeyUpEvent(LogicalKeyboardKey.altLeft);
  });
}
