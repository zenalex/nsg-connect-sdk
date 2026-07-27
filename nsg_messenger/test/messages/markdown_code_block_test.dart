/// **issue #56/#70**: блочный код в сообщениях.
///
/// Пользователь копирует markdown из Claude Code или код из VS Code и
/// ждёт, что он «красиво отформатируется», как в Telegram. Инлайновая
/// разметка была, блоков ``` не было вовсе.
///
/// Что защищаем:
///   * блок рисуется моноширинным и с подложкой, ограждения не видны;
///   * ВНУТРИ блока разметка не работает: `**` и `_` в коде — это код;
///   * незакрытый блок (сообщение ещё дописывают) не мигает туда-сюда;
///   * текст вокруг блока остаётся обычным текстом с обычной разметкой.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/markdown_spans.dart';

/// Собрать плоский текст из спанов — что реально увидит пользователь.
String _plain(List<InlineSpan> spans) {
  final sb = StringBuffer();
  for (final s in spans) {
    s.visitChildren((span) {
      if (span is TextSpan && span.text != null) sb.write(span.text);
      return true;
    });
  }
  return sb.toString();
}

List<TextSpan> _leaves(List<InlineSpan> spans) {
  final out = <TextSpan>[];
  for (final s in spans) {
    s.visitChildren((span) {
      if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
        out.add(span);
      }
      return true;
    });
  }
  return out;
}

void main() {
  const base = TextStyle(color: Color(0xFF000000));
  List<InlineSpan> parse(String text) => parseMarkdownToSpans(
    text,
    baseStyle: base,
    accentColor: const Color(0xFF2196F3),
  );

  test('ограждения не показываем, код показываем', () {
    final spans = parse('до\n```\nvar x = 1;\n```\nпосле');
    final text = _plain(spans);
    expect(text.contains('```'), isFalse, reason: 'ограждения — разметка');
    expect(text, contains('var x = 1;'));
    expect(text, contains('до'));
    expect(text, contains('после'));
  });

  test('блок — моноширинный и с подложкой', () {
    final code = _leaves(
      parse('```\nprint(1)\n```'),
    ).firstWhere((s) => s.text!.contains('print'));
    expect(code.style?.fontFamily, 'monospace');
    expect(code.style?.backgroundColor, isNotNull);
  });

  test('внутри блока разметка НЕ работает — код остаётся кодом', () {
    // Ровно то, обо что спотыкается наивная реализация: звёздочки в коде.
    final spans = parse('```\na ** b и _c_ = 5\n```');
    final leaves = _leaves(spans);
    expect(leaves, hasLength(1), reason: 'один цельный span кода');
    expect(leaves.single.text, contains('**'));
    expect(leaves.single.text, contains('_c_'));
    expect(leaves.single.style?.fontWeight, isNot(FontWeight.w700));
  });

  test('язык после ограждения не рисуется как текст', () {
    final text = _plain(parse('```dart\nvoid main() {}\n```'));
    expect(text.trim(), 'void main() {}');
  });

  test('незакрытый блок — код до конца текста (сообщение дописывают)', () {
    final leaves = _leaves(parse('вот код:\n```\nline1\nline2'));
    final code = leaves.firstWhere((s) => s.text!.contains('line1'));
    expect(code.style?.fontFamily, 'monospace');
    expect(code.text, contains('line2'));
  });

  test('текст вокруг блока сохраняет обычную разметку', () {
    final leaves = _leaves(parse('**жирно**\n```\ncode\n```\n_курсив_'));
    final bold = leaves.firstWhere((s) => s.text == 'жирно');
    expect(bold.style?.fontWeight, FontWeight.w700);
    final italic = leaves.firstWhere((s) => s.text == 'курсив');
    expect(italic.style?.fontStyle, FontStyle.italic);
  });

  test('несколько блоков в одном сообщении', () {
    final text = _plain(parse('```\nA\n```\nмежду\n```\nB\n```'));
    expect(text, contains('A'));
    expect(text, contains('между'));
    expect(text, contains('B'));
    expect(text.contains('```'), isFalse);
  });

  test('текст без ограждений идёт прежним путём', () {
    final leaves = _leaves(parse('обычный **текст**'));
    expect(leaves.any((s) => s.text == 'текст'), isTrue);
  });
}
