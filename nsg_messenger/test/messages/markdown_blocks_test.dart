/// **issue #56, вторая половина: списки, цитаты, копирование кода.**
///
/// Разметка блочная — значит смысл знака зависит от позиции: `-` в начале
/// строки это пункт списка, а в середине дефис. Здесь проверяются обе
/// стороны: что маркеры распознаются в начале строки и что НЕ
/// распознаются там, где человек их не имел в виду.
library;

import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/markdown_spans.dart';

void main() {
  const base = TextStyle(color: Color(0xFF000000));
  const accent = Color(0xFF2196F3);

  /// Плоский текст всех span-ов — что человек в итоге увидит.
  String rendered(String source, {void Function(String)? onCodeTap}) {
    final spans = parseMarkdownToSpans(
      source,
      baseStyle: base,
      accentColor: accent,
      onCodeBlockTap: onCodeTap,
    );
    final sb = StringBuffer();
    void walk(List<InlineSpan> list) {
      for (final s in list) {
        if (s is TextSpan) {
          if (s.text != null) sb.write(s.text);
          if (s.children != null) walk(s.children!);
        }
      }
    }

    walk(spans);
    return sb.toString();
  }

  group('списки', () {
    test('дефис в начале строки → пункт', () {
      expect(rendered('- один\n- два'), '•  один\n•  два');
    });

    test('звёздочка и плюс — тоже маркеры пункта', () {
      expect(rendered('* один\n+ два'), '•  один\n•  два');
    });

    test('нумерованный список сохраняет номера автора', () {
      // Перенумеровывать — значит спорить с автором: он мог продолжать
      // список из предыдущего сообщения.
      expect(rendered('3. три\n4) четыре'), '3.  три\n4.  четыре');
    });

    test('вложенность сохраняет отступ', () {
      expect(rendered('- верх\n  - вложенный'), '•  верх\n  •  вложенный');
    });

    test('дефис В СЕРЕДИНЕ строки остаётся дефисом', () {
      expect(rendered('температура -5 градусов'), 'температура -5 градусов');
    });

    test('дефис без пробела не список', () {
      expect(rendered('-5 градусов'), '-5 градусов');
    });

    test('«*жирный*» в начале строки не превращается в список', () {
      // Иначе выделение первым словом строки пропадало бы.
      expect(rendered('*важно* и точка'), 'важно и точка');
    });

    test('внутри пункта работает инлайн-разметка', () {
      expect(rendered('- **жирный** пункт'), '•  жирный пункт');
    });
  });

  group('цитаты', () {
    test('строка с > становится цитатой с полоской', () {
      expect(rendered('> цитата'), '▎ цитата');
    });

    test('несколько строк цитаты — полоска у каждой', () {
      expect(rendered('> раз\n> два'), '▎ раз\n▎ два');
    });

    test('внутри цитаты работает инлайн-разметка', () {
      expect(rendered('> `код` в цитате'), '▎ код в цитате');
    });

    test('«>» в середине строки — обычный символ', () {
      expect(rendered('если a > b тогда'), 'если a > b тогда');
    });

    test('полоска цитаты покрашена акцентом', () {
      final spans = parseMarkdownToSpans(
        '> цитата',
        baseStyle: base,
        accentColor: accent,
      );
      final bar = spans.first as TextSpan;
      expect(bar.text, '▎ ');
      expect(bar.style?.color, accent);
    });
  });

  group('блочный код', () {
    test('внутри блока маркеры списка не разбираются', () {
      // Строка кода часто начинается с дефиса (флаг команды) — превращать
      // её в пункт списка значит испортить код.
      final out = rendered('```\n- ls -la\n```');
      expect(out, contains('- ls -la'));
      expect(out, isNot(contains('•')));
    });

    test('внутри блока цитата не разбирается', () {
      final out = rendered('```\n> stdin\n```');
      expect(out, contains('> stdin'));
      expect(out, isNot(contains('▎')));
    });

    test('тап по блоку отдаёт его содержимое', () {
      String? copied;
      final spans = parseMarkdownToSpans(
        'смотри:\n```dart\nvoid main() {}\n```',
        baseStyle: base,
        accentColor: accent,
        onCodeBlockTap: (code) => copied = code,
      );
      final codeSpan =
          spans.firstWhere(
                (s) => s is TextSpan && s.style?.fontFamily == 'monospace',
              )
              as TextSpan;
      expect(codeSpan.recognizer, isNotNull);
      (codeSpan.recognizer! as TapGestureRecognizer).onTap!();
      expect(copied, 'void main() {}');
    });

    test('без обработчика распознавателя нет', () {
      // Пузырь мерит текст TextPainter-ом и в probe-проходе обработчик
      // не нужен — лишний распознаватель там ничего не даёт.
      final spans = parseMarkdownToSpans(
        '```\nкод\n```',
        baseStyle: base,
        accentColor: accent,
      );
      final codeSpan =
          spans.firstWhere(
                (s) => s is TextSpan && s.style?.fontFamily == 'monospace',
              )
              as TextSpan;
      expect(codeSpan.recognizer, isNull);
    });
  });

  test('обычный текст не трогается', () {
    expect(rendered('просто сообщение'), 'просто сообщение');
  });
}
