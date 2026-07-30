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
///   * Inline-пары должны быть на одной строке.
///   * **Блочный код** (issue #56/#70) разбирается предпроходом, ДО
///     инлайновых правил: внутри блока не парсится ничего, поэтому
///     звёздочки и подчёркивания в коде остаются собой.
///
/// `accentColor` используется для link-цвета. `bodyColor` — основной
/// цвет текста (берётся из bubble textColor).
List<InlineSpan> parseMarkdownToSpans(
  String text, {
  required TextStyle baseStyle,
  required Color accentColor,

  /// Подложка код-плашек. Приходит СНАРУЖИ, потому что считается от фона
  /// пузыря, который парсер не знает: раньше подложка бралась от цвета
  /// текста и в тёмной теме сливалась с ним (issue про читаемость).
  Color? codeBackground,

  /// **issue #56**: тап по блоку кода — «скопировать» (как в Telegram).
  /// Кнопкой сделать нельзя: пузырь мерит текст через `TextPainter`, а
  /// `WidgetSpan` без заданных размеров этот замер ломает (см.
  /// [_codeBlockSpan]). Обработчик приходит снаружи: парсер — чистая
  /// функция, буфера обмена и снекбара он не знает.
  void Function(String code)? onCodeBlockTap,
}) {
  if (text.isEmpty) return const <InlineSpan>[];
  try {
    return _parseWithCodeBlocks(
      text,
      baseStyle,
      accentColor,
      codeBackground,
      onCodeBlockTap,
    );
  } on FormatException {
    // Web: Dart RegExp компилируется в JS RegExp БРАУЗЕРА. На старых
    // движках экзотика (unicode property escapes и т.п.) кидает
    // SyntaxError → FormatException при ПОСТРОЕНИИ регэкспа, и без
    // fallback падал весь рендер сообщений («не отображается
    // переписка», GT-2976). Markdown — украшение; текст — обязателен.
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }
}

/// Ограждённый блок кода с закрывающими backtick-ами.
///
/// Язык после открывающих backtick-ов допускаем, но как текст не рисуем:
/// подсветки синтаксиса нет, а строка «dart» посреди сообщения выглядела
/// бы мусором.
final _fencedBlockRe = RegExp(
  r'```[ \t]*([A-Za-z0-9_+\-#]*)[ \t]*\r?\n([\s\S]*?)```',
  multiLine: true,
);

/// Незакрытый блок — код до конца текста.
///
/// Сообщение могут ещё дописывать (и разбивка длинного текста, issue #57,
/// сама переоткрывает блоки на границе частей). Мигание «то код, то не
/// код» на каждом введённом символе хуже, чем предположение о намерении.
final _openFenceRe = RegExp(
  r'```[ \t]*([A-Za-z0-9_+\-#]*)[ \t]*\r?\n([\s\S]*)$',
  multiLine: true,
);

/// **issue #56/#70**: предпроход по блокам кода ДО инлайновых правил.
///
/// Порядок принципиален: внутри блока ничего не парсится, поэтому
/// звёздочки и подчёркивания в коде остаются собой, а не превращаются в
/// жирный текст и курсив.
List<InlineSpan> _parseWithCodeBlocks(
  String text,
  TextStyle baseStyle,
  Color accentColor,
  Color? codeBackground,
  void Function(String code)? onCodeBlockTap,
) {
  if (!text.contains('```')) {
    return _parseBlocks(text, baseStyle, accentColor, codeBackground);
  }
  final spans = <InlineSpan>[];
  var cursor = 0;
  while (cursor < text.length) {
    final closed = _firstMatch(_fencedBlockRe, text, cursor);
    final open = _firstMatch(_openFenceRe, text, cursor);
    // Закрытый блок предпочтительнее, если начинается не позже открытого.
    final m = (closed != null && (open == null || closed.start <= open.start))
        ? closed
        : open;
    if (m == null) {
      spans.addAll(
        _parseBlocks(
          text.substring(cursor),
          baseStyle,
          accentColor,
          codeBackground,
        ),
      );
      break;
    }
    if (m.start > cursor) {
      spans.addAll(
        _parseBlocks(
          text.substring(cursor, m.start),
          baseStyle,
          accentColor,
          codeBackground,
        ),
      );
    }
    spans.add(
      _codeBlockSpan(
        m.group(2) ?? '',
        baseStyle,
        codeBackground,
        onCodeBlockTap,
      ),
    );
    cursor = m.end;
  }
  return spans;
}

/// **Блочная разметка (issue #56): цитаты и списки.**
///
/// Разбирается ПОСТРОЧНО и до инлайновых правил, потому что смысл этих
/// знаков зависит от позиции: `-` в начале строки — пункт списка, а в
/// середине — дефис. Инлайновые правила позиции не знают вовсе, поэтому
/// решать это внутри них нельзя.
///
/// Маркер заменяем на готовый символ (`•`, `▎`), а не рисуем виджетом:
/// пузырь мерит текст `TextPainter`-ом, и placeholder ломает замер (см.
/// [_codeBlockSpan]). Цена — вторая строка длинного пункта не
/// выравнивается по тексту первой, как в настоящем списке; за это платим
/// сознательно, потому что альтернатива — сломанное сворачивание длинных
/// сообщений.
List<InlineSpan> _parseBlocks(
  String text,
  TextStyle baseStyle,
  Color accentColor,
  Color? codeBackground,
) {
  if (text.isEmpty) return const <InlineSpan>[];
  // Дешёвая проверка: ни одной строки с блочным маркером — сразу инлайн.
  if (!_hasBlockMarker(text)) {
    return _parsePass(text, baseStyle, accentColor, codeBackground);
  }
  final spans = <InlineSpan>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final quote = _quoteLineRe.firstMatch(line);
    final bullet = quote == null ? _bulletLineRe.firstMatch(line) : null;
    final ordered = (quote == null && bullet == null)
        ? _orderedLineRe.firstMatch(line)
        : null;

    if (quote != null) {
      // Полоска слева — цветом акцента, сам текст полной насыщенности:
      // приглушать его значило бы ухудшать читаемость там, где человек
      // как раз и цитирует что-то важное.
      spans.add(
        TextSpan(
          text: '▎ ',
          style: baseStyle.copyWith(color: accentColor),
        ),
      );
      spans.addAll(
        _parsePass(quote.group(1)!, baseStyle, accentColor, codeBackground),
      );
    } else if (bullet != null) {
      spans.add(TextSpan(text: '${bullet.group(1)}•  ', style: baseStyle));
      spans.addAll(
        _parsePass(bullet.group(2)!, baseStyle, accentColor, codeBackground),
      );
    } else if (ordered != null) {
      // Номер оставляем ТОТ, что написал человек: перенумеровывать —
      // значит спорить с автором (он мог начать с 3 или продолжить
      // список из предыдущего сообщения).
      spans.add(
        TextSpan(
          text: '${ordered.group(1)}${ordered.group(2)}.  ',
          style: baseStyle,
        ),
      );
      spans.addAll(
        _parsePass(ordered.group(3)!, baseStyle, accentColor, codeBackground),
      );
    } else {
      spans.addAll(_parsePass(line, baseStyle, accentColor, codeBackground));
    }
    if (i != lines.length - 1) {
      spans.add(TextSpan(text: '\n', style: baseStyle));
    }
  }
  return spans;
}

bool _hasBlockMarker(String text) {
  for (final line in text.split('\n')) {
    if (_quoteLineRe.hasMatch(line) ||
        _bulletLineRe.hasMatch(line) ||
        _orderedLineRe.hasMatch(line)) {
      return true;
    }
  }
  return false;
}

/// Цитата: `> текст`. До трёх пробелов отступа — как в CommonMark.
final _quoteLineRe = RegExp(r'^[ \t]{0,3}>[ \t]?(.*)$');

/// Пункт списка: `- текст`, `* текст`, `+ текст`.
///
/// Пробел после маркера обязателен, иначе `*жирный*` в начале строки и
/// минус в `-5 градусов` превращались бы в списки.
final _bulletLineRe = RegExp(r'^([ \t]*)[-*+][ \t]+(\S.*)$');

/// Нумерованный пункт: `1. текст` / `1) текст`.
final _orderedLineRe = RegExp(r'^([ \t]*)(\d{1,3})[.)][ \t]+(\S.*)$');

Match? _firstMatch(RegExp re, String text, int start) {
  for (final m in re.allMatches(text, start)) {
    return m;
  }
  return null;
}

/// Блок кода — одним моноширинным span-ом с подложкой.
///
/// Не `WidgetSpan`: бабл прогоняет текст через `TextPainter`, чтобы
/// решить, сворачивать ли длинное сообщение, а placeholder без заданных
/// размеров этот замер ломает. Подложка средствами `TextStyle` даёт
/// нужный вид без отдельного layout-а.
InlineSpan _codeBlockSpan(
  String code,
  TextStyle base,
  Color? background,
  void Function(String code)? onTap,
) {
  final body = code.trimRight();
  return TextSpan(
    text: body,
    // Тап — «скопировать» (issue #56). Кнопки у блока нет по той же
    // причине, по которой он не виджет: замер текста в пузыре.
    recognizer: onTap == null
        ? null
        : (TapGestureRecognizer()..onTap = () => onTap(body)),
    style: base.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'DejaVu Sans Mono', 'Menlo'],
      backgroundColor: background ?? base.color?.withValues(alpha: 0.12),
      letterSpacing: 0,
      height: 1.35,
    ),
  );
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
  Color? codeBackground,
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
    spans.add(
      earliest.rule.build(
        earliest.match,
        baseStyle,
        accentColor,
        codeBackground,
      ),
    );
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

  /// `codeBackground` прокидывается сквозь вложенные правила: подложка
  /// код-плашки считается от фона пузыря снаружи (см.
  /// [parseMarkdownToSpans]), а `` `код` `` может встретиться и внутри
  /// жирного или курсива.
  final InlineSpan Function(
    Match m,
    TextStyle baseStyle,
    Color accentColor,
    Color? codeBackground,
  )
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
final _bareUrlRe = RegExp(r'https?://[^\s<>()]*[\w/#=&%~+-]', unicode: true);
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
    build: (m, base, _, codeBg) {
      return TextSpan(
        text: m.group(1)!,
        style: base.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const [
            'Courier New',
            'DejaVu Sans Mono',
            'Menlo',
          ],
          backgroundColor: codeBg ?? base.color?.withValues(alpha: 0.12),
          letterSpacing: 0,
        ),
      );
    },
  ),
  _Rule(
    regex: _linkRe,
    build: (m, base, accent, codeBg) {
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
    build: (m, base, accent, codeBg) {
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
    build: (m, base, accent, codeBg) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontWeight: FontWeight.w700);
      return TextSpan(children: _parsePass(inner, innerStyle, accent, codeBg));
    },
  ),
  _Rule(
    regex: _strikeRe,
    notBefore: _notWordOrTilde,
    build: (m, base, accent, codeBg) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: base.color?.withValues(alpha: 0.7),
      );
      return TextSpan(children: _parsePass(inner, innerStyle, accent, codeBg));
    },
  ),
  _Rule(
    regex: _italicStarRe,
    notBefore: _notWordOrStar,
    build: (m, base, accent, codeBg) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(children: _parsePass(inner, innerStyle, accent, codeBg));
    },
  ),
  _Rule(
    regex: _italicUnderRe,
    notBefore: _notWord,
    build: (m, base, accent, codeBg) {
      final inner = m.group(1)!;
      final innerStyle = base.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(children: _parsePass(inner, innerStyle, accent, codeBg));
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
