/// **Разбор списка целей, вставленного текстом** (TASK94 §2, issue #108).
///
/// Запрос интегратора 11.08.2026: разрешить 13 пар `host:port` «через
/// штатный API с audit». Раньше пилотную строку завели SQL-ом напрямую —
/// и записи в журнале за неё нет; повторять это тринадцать раз нельзя, а
/// вбивать руками по четыре поля тринадцать раз — способ ошибиться.
///
/// Каждый следующий клиент приходит с таким же списком на полтора десятка
/// endpoint-ов, поэтому разбор вынесен в чистую функцию: правила проверяются
/// без экрана, а экран остаётся тонким.
///
/// Что принимаем построчно:
///
/// ```text
/// 78.37.191.63:8896          — адрес и порт
/// 92.255.105.45/32:443       — сеть с маской
/// [2001:db8::1]:443          — IPv6 ТОЛЬКО в скобках
/// # комментарий и пустые строки пропускаем
/// ```
///
/// **Скобки у IPv6 обязательны не из вредности:** в самом адресе двоеточий
/// сколько угодно, и без скобок «последнее двоеточие — это порт» ломается
/// на первом же `2001:db8::1`. Молча угадывать тут нельзя — ошибка даст
/// разрешение не на тот адрес.
library;

/// Разобранная строка: адрес, необязательная маска, порт.
class ParsedProbeTarget {
  const ParsedProbeTarget({
    required this.address,
    required this.port,
    this.prefixLength,
  });

  final String address;
  final int port;
  final int? prefixLength;

  /// Ключ дедупа внутри одной вставки. Маска в него НЕ входит: две строки
  /// на один адрес и порт — это одна цель, как бы ни была записана сеть.
  String get key => '$address:$port';

  @override
  String toString() =>
      prefixLength == null ? '$address:$port' : '$address/$prefixLength:$port';
}

/// Результат разбора: что удалось, что нет и что повторилось.
class ProbeAllowlistPaste {
  const ProbeAllowlistPaste({
    required this.targets,
    required this.rejected,
    required this.duplicates,
  });

  /// Годные цели в порядке ввода, без повторов.
  final List<ParsedProbeTarget> targets;

  /// Строки, которые разобрать не удалось — В ИСХОДНОМ ВИДЕ. Человеку
  /// нужно увидеть свою строку, а не наш пересказ её.
  final List<String> rejected;

  /// Сколько строк повторяли уже встреченную цель. Не ошибка: в списках от
  /// заказчиков дубли обычны, и падать на них значило бы заставлять
  /// вычищать текст руками.
  final int duplicates;

  bool get isEmpty => targets.isEmpty;
}

final _bracketed = RegExp(r'^\[([0-9A-Fa-f:.]+)\](?:/(\d{1,3}))?:(\d{1,5})$');
final _plain = RegExp(r'^([0-9A-Za-z.\-]+)(?:/(\d{1,3}))?:(\d{1,5})$');

/// Разобрать вставленный текст. Порядок строк сохраняется — человек
/// сверяет результат со своим списком глазами.
ProbeAllowlistPaste parseProbeAllowlistPaste(String text) {
  final targets = <ParsedProbeTarget>[];
  final rejected = <String>[];
  final seen = <String>{};
  var duplicates = 0;

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parsed = _parseLine(line);
    if (parsed == null) {
      rejected.add(line);
      continue;
    }
    if (!seen.add(parsed.key)) {
      duplicates++;
      continue;
    }
    targets.add(parsed);
  }
  return ProbeAllowlistPaste(
    targets: targets,
    rejected: rejected,
    duplicates: duplicates,
  );
}

ParsedProbeTarget? _parseLine(String line) {
  final m = _bracketed.firstMatch(line) ?? _plain.firstMatch(line);
  if (m == null) return null;
  final address = m.group(1)!;
  final port = int.tryParse(m.group(3)!);
  if (port == null || port < 1 || port > 65535) return null;
  final prefixRaw = m.group(2);
  int? prefix;
  if (prefixRaw != null) {
    prefix = int.tryParse(prefixRaw);
    // Верхняя граница зависит от семейства адресов: 32 для IPv4, 128 для
    // IPv6. Пропустить сюда `/64` у IPv4 значит разрешить пробам ходить
    // не туда, куда думал человек.
    final max = address.contains(':') ? 128 : 32;
    if (prefix == null || prefix < 0 || prefix > max) return null;
  }
  return ParsedProbeTarget(
    address: address,
    port: port,
    prefixLength: prefix,
  );
}
