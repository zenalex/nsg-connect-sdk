/// **issue #70**: распознать код во вставляемом тексте.
///
/// Пользователь копирует фрагмент из VS Code или markdown из Claude Code и
/// ждёт, что он «сам красиво отформатируется», как в Telegram.
///
/// Цена ошибки здесь несимметрична. Не распознали код — человек выделит и
/// нажмёт «Код» (issue #70, первая часть), потеря невелика. Распознали код
/// в обычном тексте — сообщение уехало моноширинным в рамке, и это уже
/// испорченное сообщение. Поэтому эвристика СТРОГАЯ: одиночных признаков
/// не хватает, нужно совпадение нескольких, и только на многострочном
/// тексте.
///
/// Одна строка никогда не считается кодом: `foo()` в предложении — обычное
/// дело, а inline-код пользователь ставит сам.
library;

/// Минимум строк, начиная с которого вообще смотрим на текст как на код.
const int _kMinCodeLines = 2;

/// Сколько признаков должно совпасть.
const int _kMinSignals = 2;

/// Похож ли вставляемый текст на код настолько, чтобы обернуть его в блок.
bool looksLikeCode(String text) {
  final t = text.trimRight();
  if (t.isEmpty) return false;
  // Уже размечено — не трогаем: пользователь скопировал готовый markdown.
  if (t.contains('```')) return false;

  final lines = t.split('\n');
  if (lines.length < _kMinCodeLines) return false;

  final meaningful = lines.where((l) => l.trim().isNotEmpty).toList();
  if (meaningful.length < _kMinCodeLines) return false;

  int count(RegExp re) => meaningful.where((l) => re.hasMatch(l)).length;

  /// Признак весит вдвое, когда встречается МАССОВО (три строки и больше).
  ///
  /// Иначе не распознавались очевидные случаи, у которых силён ровно один
  /// признак: SQL-запрос (три строки подряд с ключевых слов, но без
  /// отступов и точек с запятой) и разметка html (сплошные теги).
  int weigh(int matches) => matches >= 3 ? 2 : (matches >= 2 ? 1 : 0);

  var signals = 0;

  // Отступы у нескольких строк. НИКОГДА не массовый признак: стихи,
  // цитаты и оформленные списки тоже выровнены отступами.
  if (count(RegExp(r'^[ \t]{2,}')) >= 2) signals++;

  // Строки заканчиваются на `;`, `{`, `}` — синтаксис, а не пунктуация
  // естественного языка.
  signals += weigh(count(RegExp(r'[;{}]\s*$')));

  // Ключевые слова В НАЧАЛЕ строки: слово «class» посреди фразы — слово,
  // а не объявление. SQL пишут капсом, поэтому он перечислен отдельно —
  // делать всю регулярку регистронезависимой нельзя, иначе английская
  // фраза с «If…»/«For…» в начале строки начнёт считаться кодом.
  signals += weigh(
    count(
      RegExp(
        r'^\s*(import|export|from|class|def|func|function|const|let|var|'
        r'final|public|private|static|return|if|for|while|foreach|package|'
        r'using|#include|SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|'
        r'GROUP|ORDER|CREATE|ALTER)\b',
      ),
    ),
  );

  // Присваивания и стрелки: `x = 1`, `=>`, `:=`, `->`.
  if (count(RegExp(r'(=>|:=|->|[A-Za-z_)\]]\s*=\s*[^=])')) >= 2) signals++;

  // Теги разметки (html/xml).
  signals += weigh(count(RegExp(r'</?[a-zA-Z][\w-]*[^>]*>')));

  return signals >= _kMinSignals;
}

/// Обернуть текст в блок кода.
String wrapAsCodeBlock(String text) => '```\n${text.trim()}\n```';
