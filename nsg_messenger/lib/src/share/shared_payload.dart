import 'package:flutter/foundation.dart';

/// **TASK49 (share-in)**: один файл, пришедший из системного «Поделиться».
///
/// SDK-owned тип — НЕ тип share-плагина (`share_handler` /
/// `receive_sharing_intent`). Host-app маппит payload плагина в этот тип,
/// поэтому смена плагина не ломает SDK (§4 «Разделение SDK/host»).
///
///   * [path] — локальный путь к уже материализованному файлу. Плагин
///     копирует content-URI во временный файл; host дополнительно
///     подстраховывается (см. `share_intake.dart` в chatista) — SDK
///     получает всегда читаемый путь.
///   * [mimeType] — MIME (`image/jpeg`, `application/pdf`, …). Может быть
///     `null` — тогда пайплайн выведет его из расширения имени/пути.
///   * [name] — исходное имя файла для отображения в превью и как
///     `originalFilename` при upload. `null` → берётся basename пути.
@immutable
class SharedFile {
  const SharedFile({required this.path, this.mimeType, this.name});

  final String path;
  final String? mimeType;
  final String? name;

  @override
  bool operator ==(Object other) =>
      other is SharedFile &&
      other.path == path &&
      other.mimeType == mimeType &&
      other.name == name;

  @override
  int get hashCode => Object.hash(path, mimeType, name);

  @override
  String toString() => 'SharedFile(path: $path, mime: $mimeType, name: $name)';
}

/// **TASK49 (share-in)**: нормализованный payload системного «Поделиться».
///
/// `{ text?, files }` — текст/URL (склеены в один [text]) и список
/// [SharedFile]. Смешанный share (текст + файлы) допустим: по §3.4 текст
/// уходит ОТДЕЛЬНЫМ сообщением ПОСЛЕ файлов.
@immutable
class SharedPayload {
  const SharedPayload({this.text, this.files = const <SharedFile>[]});

  /// Текст/URL для отправки. `null`/пусто — файловый share без подписи.
  final String? text;

  /// Файлы для отправки последовательно через attachment-пайплайн.
  final List<SharedFile> files;

  /// Есть непустой текст (после trim).
  bool get hasText => text != null && text!.trim().isNotEmpty;

  /// Есть хотя бы один файл.
  bool get hasFiles => files.isNotEmpty;

  /// Полностью пустой payload (ни текста, ни файлов) — flow игнорирует.
  bool get isEmpty => !hasText && !hasFiles;

  @override
  bool operator ==(Object other) =>
      other is SharedPayload &&
      other.text == text &&
      listEquals(other.files, files);

  @override
  int get hashCode => Object.hash(text, Object.hashAll(files));

  @override
  String toString() =>
      'SharedPayload(text: $text, files: ${files.length})';
}

/// **TASK49**: категория одного входящего элемента share из плагина.
/// Нейтральный SDK-enum — host маппит `SharedMediaType`/`SharedAttachmentType`
/// плагина сюда, чтобы pure-mapper [mapInboundToSharedPayload] был
/// тестируем без зависимости от конкретного плагина.
enum SharedInboundKind { text, url, image, video, file }

/// **TASK49**: один входящий элемент share (нейтральное представление
/// элемента плагина). Для [SharedInboundKind.text]/[SharedInboundKind.url]
/// в [value] лежит сам текст/URL; для файловых видов — локальный путь.
@immutable
class SharedInboundItem {
  const SharedInboundItem({
    required this.kind,
    required this.value,
    this.mimeType,
    this.name,
  });

  final SharedInboundKind kind;
  final String value;
  final String? mimeType;
  final String? name;

  bool get isTextual =>
      kind == SharedInboundKind.text || kind == SharedInboundKind.url;
}

/// **TASK49**: чистый маппер списка входящих элементов плагина в
/// [SharedPayload]. Вынесен из UI/host, чтобы покрыть юнит-тестами.
///
/// Правила (§3.4):
///   * text/url элементы склеиваются в один [SharedPayload.text] через
///     перевод строки (несколько текстовых частей — редко, но корректно);
///   * image/video/file элементы с непустым путём → [SharedPayload.files];
///   * пустые значения и файлы с пустым путём отбрасываются.
SharedPayload mapInboundToSharedPayload(List<SharedInboundItem> items) {
  final textParts = <String>[];
  final files = <SharedFile>[];
  for (final item in items) {
    if (item.isTextual) {
      final t = item.value.trim();
      if (t.isNotEmpty) textParts.add(t);
    } else {
      if (item.value.trim().isEmpty) continue;
      files.add(
        SharedFile(
          path: item.value,
          mimeType: item.mimeType,
          name: item.name,
        ),
      );
    }
  }
  return SharedPayload(
    text: textParts.isEmpty ? null : textParts.join('\n'),
    files: files,
  );
}
