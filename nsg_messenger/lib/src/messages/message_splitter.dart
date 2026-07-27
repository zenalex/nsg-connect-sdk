/// **issue #57**: длинный текст → несколько сообщений вместо молчаливой
/// обрезки.
///
/// Инцидент постановщика: вставил длинный текст, он молча обрезался на
/// 4096 символах, и заметить потерю почти невозможно — счётчик под полем
/// не спасает, потому что текст режется уже В МОМЕНТ вставки.
///
/// Сам лимит остаётся: 4096 — контракт сервера (`kMessageBodyMaxChars`),
/// он же анти-абьюз. Меняется поведение клиента: вписаться в лимит — его
/// работа, и делать это надо разбивкой, а не отсечением хвоста.
///
/// Границы реза — по убыванию «читаемости» шва: абзац → строка → слово →
/// (только для нерушимого сверхдлинного слова) жёсткий рез. Резать посреди
/// слова там, где рядом есть пробел, значит портить текст без нужды.
///
/// Код-блоки (```) не рвём вслепую: разорванный блок теряет подсветку и
/// половина кода превращается в обычный текст. Если блок не влезает
/// целиком — закрываем его в конце части и переоткрываем тем же
/// заголовком в следующей, чтобы обе половины остались кодом.
library;

/// Лимит тела одного сообщения (совпадает с серверным).
const int kMessageBodyMaxChars = 4096;

final RegExp _fenceLine = RegExp(r'^\s*```');

/// Разбить [text] на части не длиннее [limit].
///
/// Возвращает `[text]`, если разбивать нечего. Пустые части не отдаёт.
List<String> splitMessageBody(
  String text, {
  int limit = kMessageBodyMaxChars,
}) {
  if (limit < 16) {
    throw ArgumentError.value(limit, 'limit', 'слишком мал для разбивки');
  }
  final trimmed = text.trimRight();
  if (trimmed.length <= limit) {
    return trimmed.isEmpty ? const <String>[] : <String>[trimmed];
  }

  final out = <String>[];
  final buf = StringBuffer();
  var bufLen = 0;
  // Заголовок открытого код-блока (например «```dart»), если мы внутри
  // него: им же блок переоткрывается в следующей части.
  String? openFence;

  /// Место под закрывающий «\n```», пока блок открыт.
  int reserve() => openFence != null ? 4 : 0;

  void flush() {
    var s = buf.toString();
    if (openFence != null) s = '$s\n```';
    s = s.trimRight();
    if (s.trim().isNotEmpty) out.add(s);
    buf.clear();
    bufLen = 0;
  }

  void startPart() {
    final fence = openFence;
    if (fence != null) {
      buf.write(fence);
      bufLen = fence.length;
    }
  }

  void appendLine(String line) {
    if (bufLen > 0) {
      buf.write('\n');
      bufLen += 1;
    }
    buf.write(line);
    bufLen += line.length;
  }

  for (final rawLine in trimmed.split('\n')) {
    var line = rawLine;
    // Сколько влезет в ТЕКУЩУЮ часть с учётом переноса и закрытия блока.
    int room() => limit - bufLen - reserve() - (bufLen > 0 ? 1 : 0);

    if (line.length > room()) {
      // Строка не влезает в остаток части: сначала закрываем часть (если
      // в ней что-то есть), потом при необходимости режем саму строку.
      final fenceLen = openFence?.length ?? 0;
      if (bufLen > fenceLen) {
        flush();
        startPart();
      }
      while (line.length > room()) {
        final take = _cutPoint(line, room());
        appendLine(line.substring(0, take).trimRight());
        line = line.substring(take).trimLeft();
        flush();
        startPart();
        if (line.isEmpty) break;
      }
      if (line.isEmpty) continue;
    }
    appendLine(line);

    // Открытие/закрытие код-блока считаем ПОСЛЕ добавления строки: сама
    // строка «```» принадлежит той части, в которую попала.
    if (_fenceLine.hasMatch(rawLine)) {
      openFence = openFence == null ? rawLine.trimRight() : null;
    }
  }
  flush();
  return out;
}

/// Сколько символов взять из строки, чтобы шов пришёлся на пробел.
///
/// Рвём по слову; если слово само длиннее части (ссылка, base64, минифи-
/// цированный код) — режем жёстко: иначе такой текст невозможно отправить
/// вовсе, а это ровно та потеря, от которой мы уходим.
int _cutPoint(String line, int room) {
  if (room <= 0) return 1;
  if (line.length <= room) return line.length;
  final space = line.lastIndexOf(' ', room);
  if (space > room ~/ 2) return space;
  return room;
}

/// Сколько сообщений получится из текста (для предупреждения в UI).
int messagePartCount(String text, {int limit = kMessageBodyMaxChars}) =>
    splitMessageBody(text, limit: limit).length;
