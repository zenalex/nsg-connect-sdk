import 'package:flutter/foundation.dart' show immutable;

/// **TASK58 (incoming webhooks / автопост статусов)**: структурированная
/// статус-карточка, приезжающая внутри сырого Matrix-content-а сообщения
/// под ключом `nsg.status_card`. Сообщение при этом имеет
/// `msgType == 'nsg.status_card'`, а человекочитаемый fallback — в `body`.
///
/// Формат карточки (server DTO / raw content):
/// ```json
/// {
///   "level": "info|success|warn|error",
///   "title": "…",            // optional
///   "text": "…",             // optional
///   "fields": [ {"name": "…", "value": "…"}, … ],   // optional
///   "link": {"url": "…", "label": "…"}              // optional
/// }
/// ```
///
/// Мы читаем её ТЕМ ЖЕ механизмом, что и `nsg.album_id` /
/// `nsg.forwarded_from` — `ChatMessage.fromServer` декодирует сырой
/// content в Map один раз и передаёт сюда (см. [StatusCardData.tryParse]).
@immutable
class StatusCardData {
  const StatusCardData({
    required this.level,
    this.title,
    this.text,
    this.fields = const <StatusCardField>[],
    this.link,
  });

  /// Уровень (управляет цветом левой рамки / заголовка в bubble).
  /// Неизвестное/отсутствующее значение → [StatusCardLevel.info].
  final StatusCardLevel level;

  /// Заголовок карточки (bold, в цвет level). Может быть null.
  final String? title;

  /// Основной текст карточки. Может быть null.
  final String? text;

  /// Пары «label / value». Пустой список → строки не рендерятся.
  final List<StatusCardField> fields;

  /// Опциональная ссылка «Открыть». Может быть null.
  final StatusCardLink? link;

  /// Распарсить статус-карточку из сырого Matrix-content-а (Map, уже
  /// декодированный из [ByteData] в [ChatMessage.fromServer]). Возвращает
  /// null, если ключа `nsg.status_card` нет или он не object.
  ///
  /// Толерантен к битым данным: невалидные `fields` / `link` тихо
  /// отбрасываются, чтобы никакое сообщение не роняло рендер.
  static StatusCardData? tryParse(Map<String, dynamic>? content) {
    final raw = content?['nsg.status_card'];
    if (raw is! Map) return null;
    final map = raw;

    final fields = <StatusCardField>[];
    final rawFields = map['fields'];
    if (rawFields is List) {
      for (final f in rawFields) {
        if (f is Map) {
          final name = f['name'];
          final value = f['value'];
          if (name is String && value is String) {
            fields.add(StatusCardField(name: name, value: value));
          }
        }
      }
    }

    StatusCardLink? link;
    final rawLink = map['link'];
    if (rawLink is Map) {
      final url = rawLink['url'];
      if (url is String && url.isNotEmpty) {
        final label = rawLink['label'];
        link = StatusCardLink(
          url: url,
          label: (label is String && label.isNotEmpty) ? label : null,
        );
      }
    }

    return StatusCardData(
      level: StatusCardLevel.fromWire(map['level']),
      title: _nonEmpty(map['title']),
      text: _nonEmpty(map['text']),
      fields: List<StatusCardField>.unmodifiable(fields),
      link: link,
    );
  }

  static String? _nonEmpty(Object? v) =>
      (v is String && v.isNotEmpty) ? v : null;

  @override
  bool operator ==(Object other) =>
      other is StatusCardData &&
      other.level == level &&
      other.title == title &&
      other.text == text &&
      other.link == link &&
      _listEquals(other.fields, fields);

  @override
  int get hashCode =>
      Object.hash(level, title, text, link, Object.hashAll(fields));

  @override
  String toString() =>
      'StatusCardData(${level.name} title=$title fields=${fields.length}'
      '${link != null ? " link" : ""})';
}

/// Пара «label / value» в статус-карточке.
@immutable
class StatusCardField {
  const StatusCardField({required this.name, required this.value});

  final String name;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is StatusCardField && other.name == name && other.value == value;

  @override
  int get hashCode => Object.hash(name, value);

  @override
  String toString() => 'StatusCardField($name: $value)';
}

/// Ссылка «Открыть» в статус-карточке.
@immutable
class StatusCardLink {
  const StatusCardLink({required this.url, this.label});

  final String url;

  /// Подпись кнопки; null → UI покажет дефолтную локализованную «Открыть».
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is StatusCardLink && other.url == url && other.label == label;

  @override
  int get hashCode => Object.hash(url, label);

  @override
  String toString() => 'StatusCardLink($url${label != null ? " '$label'" : ""})';
}

/// Уровень статус-карточки — определяет акцентный цвет (рамка/заголовок).
enum StatusCardLevel {
  info,
  success,
  warn,
  error;

  /// Смапить строку из wire-формата (`"info"|"success"|"warn"|"error"`) в
  /// enum. Любое неизвестное/не-строковое значение → [StatusCardLevel.info]
  /// (безопасный дефолт — карточка всегда отрендерится).
  static StatusCardLevel fromWire(Object? v) {
    if (v is String) {
      switch (v) {
        case 'success':
          return StatusCardLevel.success;
        case 'warn':
          return StatusCardLevel.warn;
        case 'error':
          return StatusCardLevel.error;
        case 'info':
          return StatusCardLevel.info;
      }
    }
    return StatusCardLevel.info;
  }
}

bool _listEquals(List<StatusCardField> a, List<StatusCardField> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
