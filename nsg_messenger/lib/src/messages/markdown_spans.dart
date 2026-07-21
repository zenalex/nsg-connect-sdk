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
  try {
    return _parsePass(text, baseStyle, accentColor);
  } on FormatException {
    // Web: Dart RegExp компилируется в JS RegExp БРАУЗЕРА. На старых
    // движках экзотика (unicode property escapes и т.п.) кидает
    // SyntaxError → FormatException при ПОСТРОЕНИИ регэкспа, и без
    // fallback падал весь рендер сообщений («не отображается
    // переписка», GT-2976). Markdown — украшение; текст — обязателен.
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }
}

// ─── parsing pipeline ───────────────────────────────────────────────

/// Single-pass через все markdown-правила. Order matters:
///   code → link → bare-url → bold → strike → italic.
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
      // нужно substring/реалоцировать строки. Пропускаем кандидатов,
      // которым предшествует word-char (замена lookbehind, см. _rules).
      Match? m;
      for (final candidate in rule.regex.allMatches(text, cursor)) {
        if (_notPrecededBy(rule, text, candidate.start)) {
          m = candidate;
          break;
        }
      }
      if (m == null) continue;
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
  const _Rule({required this.regex, this.notBefore, required this.build});

  final RegExp regex;

  /// Word-boundary guard СЛЕВА от матча (anti-false-positive: `2*3=6`).
  /// Раньше был lookbehind `(?<![\p{L}\p{N}_*])` прямо в регэкспе, но на
  /// web Dart-регэксп компилируется в JS RegExp БРАУЗЕРА, а lookbehind не
  /// поддерживается старыми движками (Safari < 16.4 → «invalid group
  /// specifier name», чат падал целиком — GT-2976). Поэтому guard
  /// проверяем кодом по символу перед матчем (см. [_notPrecededBy]).
  final RegExp? notBefore;

  final InlineSpan Function(Match m, TextStyle baseStyle, Color accentColor)
  build;
}

/// `true`, если перед [start] нет символа, запрещённого правилом
/// ([_Rule.notBefore]). Начало строки — всегда ок.
bool _notPrecededBy(_Rule rule, String text, int start) {
  final guard = rule.notBefore;
  if (guard == null || start == 0) return true;
  return !guard.hasMatch(text[start - 1]);
}

class _Match {
  _Match(this.match, this.rule);
  final Match match;
  final _Rule rule;
}

// Anti-false-positive: italic/bold не matchится если delim касается
// word-char с обеих сторон. Word-char определяем как `\w` (lat + digits +
// underscore). Cyrillic — `\p{L}` (unicode letters). Справа — lookahead
// `(?![\p{L}\p{N}_])` (поддержан везде); слева — БЕЗ lookbehind (падал на
// старых JS-движках, GT-2976): guard задан отдельным `notBefore`-классом
// в правиле и проверяется кодом сканера.
//
// **`code` НЕ имеет word-boundary guard** — `foo`bar`baz` matchится
// как `bar` inside code, что обычно intent юзера.
final _codeRe = RegExp(r'`([^`\n]+)`', unicode: true);
final _linkRe = RegExp(r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)', unicode: true);

// **issue #34**: голый URL в тексте (не markdown-форма) — тоже кликабельный.
// Тело: любые непробельные, кроме `<>()` (скобки — чтобы `(см. url)` не
// заглатывал `)`). ПОСЛЕДНИЙ символ обязан быть URL-safe, а не пунктуацией —
// так `текст https://x.com.` не тащит концевую точку в ссылку. Guard-класс
// вместо lookbehind: lookbehind падает на web-движках (см. GT-2976 выше).
// Markdown-ссылка `[t](url)` матчится раньше по `start` и имеет приоритет в
// сканере — этот регэксп внутрь неё не влезет.
final _bareUrlRe = RegExp(
  r'https?://[^\s<>()]*[\w/#=&%~+-]',
  unicode: true,
);
final _boldRe = RegExp(
  r'\*\*(\S(?:[^*\n]*\S)?)\*\*(?![\p{L}\p{N}_*])',
  unicode: true,
);
final _strikeRe = RegExp(
  r'~~(\S(?:[^~\n]*\S)?)~~(?![\p{L}\p{N}_~])',
  unicode: true,
);
final _italicStarRe = RegExp(
  r'\*(\S(?:[^*\n]*\S)?)\*(?![\p{L}\p{N}_*])',
  unicode: true,
);
final _italicUnderRe = RegExp(
  r'_(\S(?:[^_\n]*\S)?)_(?![\p{L}\p{N}_])',
  unicode: true,
);

final _notWordOrStar = RegExp(r'[\p{L}\p{N}_*]', unicode: true);
final _notWordOrTilde = RegExp(r'[\p{L}\p{N}_~]', unicode: true);
final _notWord = RegExp(r'[\p{L}\p{N}_]', unicode: true);

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
  // **issue #34**: голый URL. Идёт ПОСЛЕ markdown-link — при вложении
  // `[t](url)` у link меньше `start`, сканер отдаёт приоритет ему. Здесь
  // label = url (весь матч), tap открывает его же.
  _Rule(
    regex: _bareUrlRe,
    build: (m, base, accent) {
      final url = m.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openUrl(url);
      return TextSpan(
        text: url,
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
    notBefore: _notWordOrStar,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontWeight: FontWeight.w700);
      return TextSpan(children: _parsePass(inner, innerStyle, accent));
    },
  ),
  _Rule(
    regex: _strikeRe,
    notBefore: _notWordOrTilde,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: base.color?.withValues(alpha: 0.7),
      );
      return TextSpan(children: _parsePass(inner, innerStyle, accent));
    },
  ),
  _Rule(
    regex: _italicStarRe,
    notBefore: _notWordOrStar,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(children: _parsePass(inner, innerStyle, accent));
    },
  ),
  _Rule(
    regex: _italicUnderRe,
    notBefore: _notWord,
    build: (m, base, accent) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(children: _parsePass(inner, innerStyle, accent));
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
