/// **issue #179 — при быстром наборе буквы перемешивались между
/// соседними сообщениями.**
///
/// Владелец воспроизвёл дословно: набирал парами «фф ыы вв аа пп рр оо лл»
/// и жал Enter после каждой пары. В чат ушло:
///
/// ```
/// ффы · ыв · ва · ап · пр · ро · ол · лд · дж
/// ```
///
/// Граница каждого сообщения сдвинута ровно на символ: хвост своей пары
/// уходил вместе с головой следующей, а из следующей пропадал.
///
/// Причина — окно между нажатием и отправкой. `Enter` на десктопе
/// перехватывает `_globalKeyHandler`, а сам submit откладывается на
/// следующий кадр (иначе операции с контроллером конфликтуют с ещё летящим
/// key-dispatch). Пока submit ждал кадра, он читал поле САМ — и забирал
/// символ, напечатанный уже ПОСЛЕ Enter. Он же и стирался: поле чистилось
/// целиком.
///
/// Здесь то окно воспроизводится детерминированно: между нажатием Enter и
/// прокруткой кадра в поле дописывается следующий символ — ровно то, что
/// на живой клавиатуре успевает случиться при быстром наборе.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

void main() {
  final sent = <String>[];

  Widget app() => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        onSend: (body, {mentionedMessengerUserIds, albumId}) async {
          sent.add(body);
        },
      ),
    ),
  );

  setUp(sent.clear);

  TextEditingController controller(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  /// Дописать символ так, как это делает платформа при вводе: в конец, с
  /// кареткой следом.
  void typeMore(WidgetTester tester, String ch) {
    final c = controller(tester);
    final next = c.text + ch;
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  testWidgets('символ, напечатанный после Enter, не уезжает в чужое '
      'сообщение и не пропадает', (tester) async {
    // Enter=отправка — десктопная ветка (на мобильном Enter даёт \n).
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(app());
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'фф');

      // Enter нажат…
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      // …и ДО того, как отложенный submit доберётся до кадра, прилетает
      // следующий символ. Это и есть быстрый набор.
      typeMore(tester, 'ы');
      await tester.pumpAndSettle();

      expect(sent, ['фф'], reason: 'ушло ровно то, что было к моменту Enter');
      expect(
        controller(tester).text,
        'ы',
        reason: 'напечатанное после Enter остаётся автору, а не стирается',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  // Обычный случай — между Enter и кадром ничего не случилось: поле должно
  // остаться пустым, как и раньше.
  testWidgets('без гонки поле пустеет полностью', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(app());
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'привет');

      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(sent, ['привет']);
      expect(controller(tester).text, isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  // Кнопка «Отправить»: снимка нет, поле читается на месте — и всё равно
  // чистится ровно на отправленное.
  testWidgets('кнопка отправки чистит поле', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), 'кнопкой');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(sent, ['кнопкой']);
    expect(controller(tester).text, isEmpty);
  });
}
