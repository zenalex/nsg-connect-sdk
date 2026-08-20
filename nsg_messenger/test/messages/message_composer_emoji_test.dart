import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

import '../test_helpers.dart';

/// **Issue #85** — своя кнопка эмодзи в композере: вставка в позицию каретки,
/// замена выделения, корректная арифметика по суррогатным парам.
void main() {
  Widget wrap(Widget child) =>
      wrapL10n(Column(children: [const Spacer(), child]));

  Widget composer({bool enabled = true}) => wrap(
    MessageComposer(
      enabled: enabled,
      onSend: (b, {mentionedMessengerUserIds, albumId}) async {},
    ),
  );

  TextEditingController controllerOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  /// Каретка не должна вставать МЕЖДУ половинками суррогатной пары: такая
  /// позиция разрезает символ, и следующий ввод/Backspace оставит в поле
  /// мусор вместо смайлика. Проверяем именно смещение, потому что в тексте
  /// разрыв не виден — строка «выглядит нормально».
  void expectCaretOnCharBoundary(TextEditingValue v) {
    final offset = v.selection.baseOffset;
    if (offset <= 0 || offset >= v.text.length) return;
    // 0xD800..0xDBFF — старшая половина пары. Стоит прямо перед кареткой ⇒
    // младшая осталась справа, символ разорван пополам.
    expect(
      v.text.codeUnitAt(offset - 1) & 0xFC00,
      isNot(0xD800),
      reason: 'каретка встала внутрь суррогатной пары',
    );
  }

  group('insertEmojiAtCaret', () {
    test('вставляет в позицию каретки, а не в конец текста', () {
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'привет мир',
          selection: TextSelection.collapsed(offset: 6),
        ),
        '😀',
      );
      expect(result.text, 'привет😀 мир');
      // 6 + 2 кодовые единицы суррогатной пары: каретка ЗА смайликом.
      expect(result.selection.baseOffset, 8);
      expect(result.selection.isCollapsed, isTrue);
      // Вырезанный по смещениям кусок — целый смайлик, а не половинка.
      expect(result.text.substring(6, 8), '😀');
      expectCaretOnCharBoundary(result);
    });

    test('выделение ЗАМЕНЯЕТ, каретка встаёт за вставленным', () {
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'привет мир',
          selection: TextSelection(baseOffset: 0, extentOffset: 6),
        ),
        '😀',
      );
      expect(result.text, '😀 мир');
      expect(result.selection.baseOffset, 2);
      expectCaretOnCharBoundary(result);
    });

    test('выделение справа налево (base > extent) — те же границы', () {
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'привет мир',
          selection: TextSelection(baseOffset: 6, extentOffset: 0),
        ),
        '😀',
      );
      expect(result.text, '😀 мир');
      expect(result.selection.baseOffset, 2);
    });

    test('ZWJ-последовательность (5 кодовых единиц) не разрывается', () {
      // «😮‍💨» — два эмодзи, склеенные zero-width joiner-ом: посимвольная
      // арифметика оставила бы каретку внутри последовательности.
      const emoji = '😮‍💨';
      expect(emoji.length, 5, reason: 'страховка от подмены символа в файле');
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 1),
        ),
        emoji,
      );
      expect(result.text, 'a${emoji}b');
      expect(result.selection.baseOffset, 6);
      expect(result.text.substring(1, 6), emoji);
      expectCaretOnCharBoundary(result);
    });

    test('символ с variation selector («❤️») тоже целиком', () {
      const emoji = '❤️';
      expect(emoji.length, 2);
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 2),
        ),
        emoji,
      );
      expect(result.text, 'ab$emoji');
      expect(result.selection.baseOffset, 4);
    });

    test('две вставки подряд идут ОДНА ЗА ДРУГОЙ, а не наоборот', () {
      final first = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 1),
        ),
        '😀',
      );
      final second = insertEmojiAtCaret(first, '😃');
      // Порядок ввода сохранён — вторая пара встала ПОСЛЕ первой.
      expect(second.text, 'a😀😃b');
      expect(second.selection.baseOffset, 5);
      expectCaretOnCharBoundary(second);
    });

    test('каретки не было (offset -1) → дописываем в конец', () {
      final result = insertEmojiAtCaret(
        const TextEditingValue(text: 'привет'),
        '😀',
      );
      expect(result.text, 'привет😀');
      expect(result.selection.baseOffset, 8);
    });

    test('устаревшая каретка за концом текста не роняет вставку', () {
      // Снимок каретки берут ДО открытия панели; если текст успел стать
      // короче, сырое смещение дало бы RangeError вместо смайлика.
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'ab',
          selection: TextSelection(baseOffset: 40, extentOffset: 50),
        ),
        '😀',
      );
      expect(result.text, 'ab😀');
      expect(result.selection.baseOffset, 4);
    });

    test('незавершённая IME-композиция сбрасывается', () {
      final result = insertEmojiAtCaret(
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 0, end: 3),
        ),
        '😀',
      );
      expect(result.composing, TextRange.empty);
    });
  });

  // Платформу задаём вариантом теста, а не присваиванием в теле:
  // `debugDefaultTargetPlatformOverride` обязан быть сброшен к концу теста,
  // иначе фреймворк валит его как «протёкшую» отладочную переменную — а при
  // падении в середине тела ручной сброс не выполнится.
  final desktop = TargetPlatformVariant.only(TargetPlatform.windows);

  group('кнопка эмодзи в композере', () {
    testWidgets('на десктопе кнопка есть', (tester) async {
      await tester.pumpWidget(composer());
      expect(find.byKey(kComposerEmojiButtonKey), findsOneWidget);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets(
      'на Android/iOS кнопки НЕТ — эмодзи даёт системная клавиатура',
      (tester) async {
        await tester.pumpWidget(composer());
        expect(
          find.byKey(kComposerEmojiButtonKey),
          findsNothing,
          reason: 'лишний шаг к более бедному набору, чем системный',
        );
      },
      variant: TargetPlatformVariant.mobile(),
    );

    testWidgets('enabled=false → кнопка неактивна', (tester) async {
      await tester.pumpWidget(composer(enabled: false));
      final btn = tester.widget<IconButton>(
        find.byKey(kComposerEmojiButtonKey),
      );
      expect(btn.onPressed, isNull);
    }, variant: desktop);

    testWidgets('открывает панель со СВОИМ заголовком (не «реакция»)', (
      tester,
    ) async {
      await tester.pumpWidget(composer());
      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Choose an emoji'), findsOneWidget);
      expect(
        find.text('Choose a reaction'),
        findsNothing,
        reason: 'панель общая с реакциями, но заголовок должен быть свой',
      );
      // Набор — тот же курированный, что и у реакций.
      expect(find.text('Smileys & emotion'), findsOneWidget);
    }, variant: desktop);

    testWidgets('выбор эмодзи вставляет его В СЕРЕДИНУ фразы по каретке', (
      tester,
    ) async {
      await tester.pumpWidget(composer());
      await tester.enterText(find.byType(TextField), 'привет мир');
      final ctl = controllerOf(tester);
      ctl.selection = const TextSelection.collapsed(offset: 6);
      await tester.pump();

      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle();

      expect(ctl.text, 'привет😀 мир');
      expect(ctl.selection.baseOffset, 8);
      expectCaretOnCharBoundary(ctl.value);
    }, variant: desktop);

    testWidgets('выделенный текст заменяется выбранным эмодзи', (tester) async {
      await tester.pumpWidget(composer());
      await tester.enterText(find.byType(TextField), 'привет мир');
      final ctl = controllerOf(tester);
      ctl.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      await tester.pump();

      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle();

      expect(ctl.text, '😀 мир');
      expect(ctl.selection.baseOffset, 2);
    }, variant: desktop);

    testWidgets(
      'каретку снимаем ДО открытия панели — потеря её полем не сдвигает вставку',
      (tester) async {
        await tester.pumpWidget(composer());
        await tester.enterText(find.byType(TextField), 'привет мир');
        final ctl = controllerOf(tester);
        ctl.selection = const TextSelection.collapsed(offset: 6);
        await tester.pump();

        await tester.tap(find.byKey(kComposerEmojiButtonKey));
        await tester.pumpAndSettle();
        // Пока панель открыта, поле не в фокусе. Воспроизводим платформу, на
        // которой каретка при этом теряется: если брать её из контроллера
        // ПОСЛЕ закрытия панели, смайлик уедет в конец фразы — ровно мимо
        // задачи «поставить в середину».
        ctl.selection = const TextSelection.collapsed(offset: -1);
        await tester.tap(find.text('😀'));
        await tester.pumpAndSettle();

        expect(ctl.text, 'привет😀 мир');
      },
      variant: desktop,
    );

    testWidgets('закрытие панели без выбора не трогает текст', (tester) async {
      await tester.pumpWidget(composer());
      await tester.enterText(find.byType(TextField), 'привет мир');
      final ctl = controllerOf(tester);
      ctl.selection = const TextSelection.collapsed(offset: 6);
      await tester.pump();

      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();
      // Тап по барьеру закрывает модальный лист.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(ctl.text, 'привет мир');
    }, variant: desktop);

    testWidgets('вставка эмодзи в пустое поле включает «Отправить»', (
      tester,
    ) async {
      await tester.pumpWidget(composer());
      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle();

      final send = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        ),
      );
      expect(
        send.onPressed,
        isNotNull,
        reason: 'сообщение из одного смайлика — законное сообщение',
      );
    }, variant: desktop);
  });
}
