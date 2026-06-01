import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// **B19 inline markdown** — конвертирует markdown-подобный subset в
/// `List<InlineSpan>` для рендеринга через `Text.rich`.
///
/// Поддерживаемый subset (приоритет ↓ — высший раньше):
///   1. Inline code: `` `code` `` — внутри ничего не парсится.
///   2. Link: `[text](https://…)` — tappable, открывается через
///      `url_launcher`.
///   3. Bold: `**text**` — `FontWeight.w700`.
///   4. Strikethrough: `~~text~~`.
///   5. Italic: `*text*` / `_text_`.
///   6. Mentions: `@name` — apply отдельным проходом сверху
///      (см. `applyMentions` в `_BodyText` — мы НЕ парсим mentions
///      здесь, чтобы не дублировать логику participants lookup).
///
/// **Conservative rules** (anti-false-positive):
///   * `*italic*` НЕ matchится если `*` касается word-char с одной
///     стороны (`2*3=6` остаётся plain).
///   * Внутри code-span markdown НЕ парсится.
///   * Pairs должны быть на одной line — multi-line code блоки
///     ( ``` ``` ) пока не support-ятся.
///
/// `accentColor` используется для link-цвета. `bodyColor` — основной
/// цвет текста (берётся из bubble textColor).
List<InlineSpan> parseMarkdownToSpans(
  String text, {
  required TextStyle baseStyle,
  required Color accentColor,
}) {
  if (text.isEmpty) return const <InlineSpan>[];
  return _parsePass(text, baseStyle, accentColor);
}

// ─── parsing pipeline ───────────────────────────────────────────────

/// Single-pass через все markdown-правила. Order matters:
///   code → link → bold → strike → italic.
///
/// На каждом шаге выбираем ПЕРВЫЙ (по `start`) match среди всех
/// активных regex-ов, эмитим его, рекурсивно парсим оставшийся
/// suffix. Это даёт правильную приоритезацию вложений без явного
/// nested-parser-а.
List<InlineSpan> _parsePass(
  String text,
  TextStyle baseStyle,
  Color accentColor,
) {
  if (text.isEmpty) return const <InlineSpan>[];
  final spans = <InlineSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    _Match? earliest;
    for (final rule in _rules) {
      // `allMatches(text, start)` нативно поддерживает offset — не
      // нужно substring/реалоцировать строки.
      final iter = rule.regex.allMatches(text, cursor).iterator;
      if (!iter.moveNext()) continue;
      final m = iter.current;
      if (earliest == null || m.start < earliest.match.start) {
        earliest = _Match(m, rule);
      }
    }
    if (earliest == null) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
      break;
    }
    if (earliest.match.start > cursor) {
      spans.add(
        TextSpan(
          text: text.substring(cursor, earliest.match.start),
          style: baseStyle,
        ),
      );
    }
    spans.add(earliest.rule.build(earliest.match, baseStyle, accentColor));
    cursor = earliest.match.end;
  }
  return spans;
}

/// Pure-function rule descriptor: regex + builder для матчей.
class _Rule {
  const _Rule({required this.regex, required this.build});

  final RegExp regex;
  final InlineSpan Function(
    Match m,
    TextStyle baseStyle,
    Color accentColor,
  ) build;
}

class _Match {
  _Match(this.match, this.rule);
  final Match match;
  final _Rule rule;
}

// Anti-false-positive: italic/bold не matchится если delim касается
// word-char с обеих сторон. Word-char определяем как `\w` (lat + digits +
// underscore). Cyrillic — `\p{L}` (unicode letters). Объединяем:
// `(?<![\p{L}\p{N}_])` / `(?![\p{L}\p{N}_])`.
//
// **`code` НЕ имеет word-boundary guard** — `foo`bar`baz` matchится
// как `bar` inside code, что обычно intent юзера.
final _codeRe = RegExp(r'`([^`\n]+)`', unicode: true);
final _linkRe = RegExp(
  r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)',
  unicode: true,
);
final _boldRe = RegExp(
  r'(?<![\p{L}\p{N}_*])\*\*(\S(?:[^*\n]*\S)?)\*\*(?![\p{L}\p{N}_*])',
  unicode: true,
);
final _strikeRe = RegExp(
  r'(?<![\p{L}\p{N}_~])~~(\S(?:[^~\n]*\S)?)~~(?![\p{L}\p{N}_~])',
  unicode: true,
);
final _italicStarRe = RegExp(
  r'(?<![\p{L}\p{N}_*])\*(\S(?:[^*\n]*\S)?)\*(?![\p{L}\p{N}_*])',
  unicode: true,
);
final _italicUnderRe = RegExp(
  r'(?<![\p{L}\p{N}_])_(\S(?:[^_\n]*\S)?)_(?![\p{L}\p{N}_])',
  unicode: true,
);

final List<_Rule> _rules = [
  _Rule(
    regex: _codeRe,
    build: (m, base, _) {
      return TextSpan(
        text: m.group(1)!,
        style: base.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const [
            'Courier New',
            'DejaVu Sans Mono',
            'Menlo',
          ],
          backgroundColor: base.color?.withValues(alpha: 0.12),
          letterSpacing: 0,
        ),
      );
    },
  ),
  _Rule(
    regex: _linkRe,
    build: (m, base, accent) {
      final label = m.group(1)!;
      final url = m.group(2)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openUrl(url);
      return TextSpan(
        text: label,
        recognizer: recognizer,
        style: base.copyWith(
          color: accent,
          decoration: TextDecoration.underline,
          decorationColor: accent,
        ),
      );
    },
  ),
  _Rule(
    regex: _boldRe,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontWeight: FontWeight.w700);
      return TextSpan(
        children: _parsePass(inner, innerStyle, accent),
      );
    },
  ),
  _Rule(
    regex: _strikeRe,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: base.color?.withValues(alpha: 0.7),
      );
      return TextSpan(
        children: _parsePass(inner, innerStyle, accent),
      );
    },
  ),
  _Rule(
    regex: _italicStarRe,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(
        children: _parsePass(inner, innerStyle, accent),
      );
    },
  ),
  _Rule(
    regex: _italicUnderRe,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(
        children: _parsePass(inner, innerStyle, accent),
      );
    },
  ),
];

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // best-effort; bubble не знает про ScaffoldMessenger для snackbar.
  }
}
