/// **Текст сообщения без разметки (issue #56).**
///
/// Разметка рендерится там, где есть место её нарисовать, — в пузыре. Но
/// то же сообщение показывается ещё и одной строкой: в списке чатов и в
/// уведомлении. Там оформления нет, и человек видел сырые звёздочки с
/// backtick-ами — особенно от ботов, которые отвечают markdown-ом.
///
/// Здесь знаки разметки снимаются, а СОДЕРЖИМОЕ остаётся: превью должно
/// говорить, о чём сообщение. Блок кода — исключение: строки кода в одну
/// строку превью не складываются осмысленно, поэтому от него остаётся
/// первая строка (обычно она и есть суть — сигнатура, команда, имя).
library;

/// Ограждённый блок кода: оставляем первую непустую строку.
final _fencedBlock = RegExp(
  r'```[ \t]*[A-Za-z0-9_+\-#]*[ \t]*\r?\n?([\s\S]*?)(?:```|$)',
);
final _inlineCode = RegExp(r'`([^`\n]+)`');
final _mdLink = RegExp(r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)');
final _bold = RegExp(r'\*\*(\S(?:[^*\n]*\S)?)\*\*');
final _strike = RegExp(r'~~(\S(?:[^~\n]*\S)?)~~');
final _italicStar = RegExp(r'\*(\S(?:[^*\n]*\S)?)\*');
final _italicUnder = RegExp(r'(?:^|\s)_(\S(?:[^_\n]*\S)?)_');
final _blockPrefix = RegExp(
  r'^[ \t]{0,3}(?:>[ \t]?|[-*+][ \t]+|\d{1,3}[.)][ \t]+)',
);
final _spaces = RegExp(r'[ \t]+');

/// Снять разметку и сжать в одну строку.
String stripMarkdown(String text) {
  if (text.isEmpty) return text;
  var out = text.replaceAllMapped(_fencedBlock, (m) {
    final code = m.group(1) ?? '';
    for (final line in code.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  });
  // Ссылку сводим к подписи: URL в превью занимает всю строку и ничего
  // не сообщает. Голые URL не трогаем — они и есть весь текст.
  out = out.replaceAllMapped(_mdLink, (m) => m.group(1)!);
  out = out.replaceAllMapped(_inlineCode, (m) => m.group(1)!);
  out = out.replaceAllMapped(_bold, (m) => m.group(1)!);
  out = out.replaceAllMapped(_strike, (m) => m.group(1)!);
  out = out.replaceAllMapped(_italicStar, (m) => m.group(1)!);
  out = out.replaceAllMapped(
    _italicUnder,
    (m) => m.group(0)!.startsWith('_') ? m.group(1)! : ' ${m.group(1)!}',
  );
  // Блочные маркеры — построчно: они значат что-то только в начале строки.
  final lines = out
      .split('\n')
      .map((l) => l.replaceFirst(_blockPrefix, ''))
      .where((l) => l.trim().isNotEmpty);
  return lines.join(' ').replaceAll(_spaces, ' ').trim();
}
