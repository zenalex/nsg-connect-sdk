import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/markdown_spans.dart';

/// Unit-тесты parser-а inline-markdown subset (B19).
///
/// Сосредоточены на pure-parsing-логике: каких токенов какой стиль,
/// edge cases на false-positive (math `2*3`, contraction `it_s`),
/// порядок приоритетов (code > link > bold > strike > italic).
void main() {
  const baseStyle = TextStyle(color: Color(0xFF000000));
  const accent = Color(0xFF6750A4);

  List<InlineSpan> parse(String input) =>
      parseMarkdownToSpans(input, baseStyle: baseStyle, accentColor: accent);

  /// Вытащить flat-список текстов всех leaf TextSpan-ов (для проверки
  /// что parser структурно правильно разбил body).
  List<String> leaves(List<InlineSpan> spans) {
    final out = <String>[];
    void visit(InlineSpan s) {
      if (s is! TextSpan) return;
      if (s.children != null && s.children!.isNotEmpty) {
        for (final c in s.children!) {
          visit(c);
        }
        return;
      }
      if (s.text != null) out.add(s.text!);
    }
    for (final s in spans) {
      visit(s);
    }
    return out;
  }

  TextStyle? styleOfLeaf(List<InlineSpan> spans, String text) {
    TextStyle? found;
    void visit(InlineSpan s, TextStyle? inherited) {
      if (s is! TextSpan) return;
      final merged = inherited?.merge(s.style) ?? s.style;
      if (s.children != null && s.children!.isNotEmpty) {
        for (final c in s.children!) {
          visit(c, merged);
        }
        return;
      }
      if (s.text == text) found = merged;
    }
    for (final s in spans) {
      visit(s, null);
    }
    return found;
  }

  group('parseMarkdownToSpans', () {
    test('empty input → empty list', () {
      expect(parse(''), isEmpty);
    });

    test('plain text without markup → single span', () {
      final spans = parse('hello world');
      expect(leaves(spans), ['hello world']);
    });

    test('bold **word**', () {
      final spans = parse('hello **world** end');
      expect(leaves(spans), ['hello ', 'world', ' end']);
      final style = styleOfLeaf(spans, 'world');
      expect(style?.fontWeight, FontWeight.w700);
    });

    test('italic *word*', () {
      final spans = parse('plain *em* tail');
      expect(leaves(spans), ['plain ', 'em', ' tail']);
      expect(styleOfLeaf(spans, 'em')?.fontStyle, FontStyle.italic);
    });

    test('italic _word_', () {
      final spans = parse('a _b_ c');
      expect(leaves(spans), ['a ', 'b', ' c']);
      expect(styleOfLeaf(spans, 'b')?.fontStyle, FontStyle.italic);
    });

    test('strikethrough ~~text~~', () {
      final spans = parse('a ~~b~~ c');
      expect(leaves(spans), ['a ', 'b', ' c']);
      expect(styleOfLeaf(spans, 'b')?.decoration, TextDecoration.lineThrough);
    });

    test('inline code `text` — monospace + bg', () {
      final spans = parse('run `flutter test` now');
      expect(leaves(spans), ['run ', 'flutter test', ' now']);
      expect(styleOfLeaf(spans, 'flutter test')?.fontFamily, 'monospace');
    });

    test('inline code не парсит markdown внутри', () {
      final spans = parse('show `**bold**` here');
      expect(leaves(spans), ['show ', '**bold**', ' here']);
      expect(styleOfLeaf(spans, '**bold**')?.fontFamily, 'monospace');
    });

    test('link [label](url) — tappable, accent color', () {
      final spans = parse('see [docs](https://example.com) for help');
      expect(leaves(spans), ['see ', 'docs', ' for help']);
      final style = styleOfLeaf(spans, 'docs');
      expect(style?.color, accent);
      expect(style?.decoration, TextDecoration.underline);
    });

    test('math 2*3=6 НЕ парсится как italic (word-boundary)', () {
      final spans = parse('result is 2*3=6');
      // Должен остаться plain: либо весь текст одним leaf, либо несколько
      // без italic-стиля.
      final allLeaves = leaves(spans);
      expect(allLeaves.join(), 'result is 2*3=6');
      // Гарантируем что нет italic-spans.
      for (final s in spans) {
        if (s is TextSpan && s.text != null) {
          expect(s.style?.fontStyle, isNot(FontStyle.italic));
        }
      }
    });

    test('snake_case_id НЕ парсится как italic', () {
      final spans = parse('var snake_case_id = 1');
      expect(leaves(spans).join(), 'var snake_case_id = 1');
    });

    test('bold внутри text + cyrillic', () {
      final spans = parse('это **важно** проверить');
      expect(leaves(spans), ['это ', 'важно', ' проверить']);
      expect(styleOfLeaf(spans, 'важно')?.fontWeight, FontWeight.w700);
    });

    test('nested bold+italic: ***boldItalic*** → bold first', () {
      // **xx** имеет приоритет над *xx*; ***x*** matches bold first как
      // **\*x\***, внутри — italic *x*. Простой случай — даём гарантию
      // что результат содержит и bold, и italic style.
      final spans = parse('a ***x*** b');
      final s = styleOfLeaf(spans, 'x');
      expect(s?.fontWeight, FontWeight.w700);
      expect(s?.fontStyle, FontStyle.italic);
    });

    test('multiple bolds в одном body', () {
      final spans = parse('**a** plain **b**');
      expect(leaves(spans), ['a', ' plain ', 'b']);
      expect(styleOfLeaf(spans, 'a')?.fontWeight, FontWeight.w700);
      expect(styleOfLeaf(spans, 'b')?.fontWeight, FontWeight.w700);
    });

    test('unclosed delimiter НЕ ломает парсер', () {
      final spans = parse('unclosed *italic without end');
      expect(leaves(spans).join(), 'unclosed *italic without end');
    });

    test('priorities: code > link inside code', () {
      final spans = parse('try `[link](url)` here');
      expect(leaves(spans), ['try ', '[link](url)', ' here']);
      expect(styleOfLeaf(spans, '[link](url)')?.fontFamily, 'monospace');
    });
  });
}
