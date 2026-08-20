/// **issue #90**: какие ссылки из сообщения заслуживают превью.
///
/// Отдельный файл и чистая функция — потому что решение «за какой ссылкой
/// пойти» стоит денег и приватности: каждый найденный здесь URL превратится
/// в поход сервера на чужой сайт. Ошибиться тут дороже, чем нарисовать
/// карточку криво, поэтому правило проверяется тестами отдельно от вёрстки.
library;

import 'markdown_spans.dart' show BodyTextChunk, splitBodyIntoChunks;

/// Markdown-ссылка `[подпись](url)` — берём именно URL, а не подпись.
final _mdLinkRe = RegExp(r'\[[^\]\n]+\]\((https?://[^\s)]+)\)', unicode: true);

/// Голый URL в тексте. Тело и хвостовой guard — те же, что в
/// `markdown_spans`: если ссылка там кликабельна, превью должно быть ровно
/// у неё, иначе карточка покажет не тот адрес, который откроется по тапу.
final _bareUrlRe = RegExp(r'https?://[^\s<>()]*[\w/#=&%~+-]', unicode: true);

/// Inline-код: `` `текст` ``.
final _inlineCodeRe = RegExp(r'`[^`\n]+`');

/// Ссылки из [body], за которыми имеет смысл идти, — не больше [max].
///
/// **Только ПЕРВАЯ ссылка (по умолчанию).** У сообщения со списком из пяти
/// ссылок пять карточек — это стена, за которой не видно самого сообщения;
/// в мессенджерах превью показывают у первой, и это не экономия, а вёрстка.
///
/// Код исключён: URL внутри `` ` `` или ограждённого блока — это пример, а
/// не ссылка, которой поделились. Он и кликабельным-то не рисуется (в
/// `markdown_spans` правило кода перехватывает участок раньше), так что
/// карточка под ним обещала бы переход, которого нет.
///
/// Дубли убираются: одна и та же ссылка дважды в сообщении — одна карточка.
List<String> extractPreviewUrls(String body, {int max = 1}) {
  if (body.isEmpty || max <= 0) return const <String>[];
  final out = <String>[];
  for (final chunk in splitBodyIntoChunks(body)) {
    if (chunk is! BodyTextChunk) continue;
    // Inline-код вырезаем ПРОБЕЛОМ, а не пустотой: иначе куски по краям
    // склеились бы в один токен и дали несуществующий адрес.
    final clean = chunk.text.replaceAll(_inlineCodeRe, ' ');
    for (final url in _urlsIn(clean)) {
      if (out.contains(url)) continue;
      out.add(url);
      if (out.length >= max) return out;
    }
  }
  return out;
}

/// URL-ы куска в порядке появления.
///
/// Markdown-форма имеет приоритет над голой: у `[t](url)` матчатся обе, но
/// у markdown-формы меньше `start`. Без приоритета из `[t](https://e.com)`
/// вылезла бы «ссылка» с хвостовой скобкой.
Iterable<String> _urlsIn(String text) sync* {
  var cursor = 0;
  while (cursor < text.length) {
    final md = _firstFrom(_mdLinkRe, text, cursor);
    final bare = _firstFrom(_bareUrlRe, text, cursor);
    if (md == null && bare == null) return;
    final useMd = md != null && (bare == null || md.start <= bare.start);
    final m = useMd ? md : bare!;
    yield useMd ? m.group(1)! : m.group(0)!;
    cursor = m.end;
  }
}

Match? _firstFrom(RegExp re, String text, int start) {
  final it = re.allMatches(text, start).iterator;
  return it.moveNext() ? it.current : null;
}
