/// **TASK49 (share-in)**: клиентская pre-upload валидация размера файла.
///
/// Пороги ЗЕРКАЛЯТ серверные лимиты `AttachmentService` (TASK19/TASK33) —
/// image/file 50 MB, video 100 MB, абсолютный hard cap 200 MB. Проверяем
/// на клиенте ДО upload (§3.5 «валидация размера/типа ДО upload, понятная
/// ошибка»), чтобы не гонять сотни мегабайт впустую и показать дружелюбный
/// текст вместо серверного `ArgumentError`.
library;

/// 50 MB — image/file (совпадает с `AttachmentService.kMaxImageFileBytes`).
const int kShareMaxImageFileBytes = 50 * 1024 * 1024;

/// 100 MB — video (совпадает с `AttachmentService.kMaxVideoBytes`).
const int kShareMaxVideoBytes = 100 * 1024 * 1024;

/// 200 MB — абсолютный hard cap (`AttachmentService.kHardCapBytes`).
const int kShareHardCapBytes = 200 * 1024 * 1024;

/// Лимит по MIME: video → [kShareMaxVideoBytes], иначе image/file cap.
/// Совпадает с логикой `AttachmentService._validateSize`.
int shareMaxBytesForMime(String? mimeType) {
  final isVideo = mimeType != null && mimeType.startsWith('video/');
  return isVideo ? kShareMaxVideoBytes : kShareMaxImageFileBytes;
}

/// Проверить размер файла против лимита для его MIME. Бросает
/// [SharedFileTooLargeException], если превышен. `sizeBytes <= 0` не
/// проверяем здесь — пустой/битый файл поймает сам upload.
void validateShareFileSize({
  required int sizeBytes,
  String? mimeType,
  String? name,
}) {
  final cap = shareMaxBytesForMime(mimeType);
  final effectiveCap = cap < kShareHardCapBytes ? cap : kShareHardCapBytes;
  if (sizeBytes > effectiveCap) {
    throw SharedFileTooLargeException(
      name: name,
      sizeBytes: sizeBytes,
      maxBytes: effectiveCap,
    );
  }
}

/// **TASK49**: файл превышает допустимый размер для share-in. Flow ловит и
/// показывает дружелюбный snackbar (см. `shareFileTooLarge` l10n).
class SharedFileTooLargeException implements Exception {
  const SharedFileTooLargeException({
    required this.sizeBytes,
    required this.maxBytes,
    this.name,
  });

  final String? name;
  final int sizeBytes;
  final int maxBytes;

  int get maxMegabytes => maxBytes ~/ (1024 * 1024);

  @override
  String toString() =>
      'SharedFileTooLargeException(name: $name, size: $sizeBytes, '
      'max: $maxBytes)';
}
