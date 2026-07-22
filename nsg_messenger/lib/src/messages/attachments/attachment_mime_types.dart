/// Клиентская таблица «расширение → MIME» и деривация Matrix msgType.
///
/// **Файл намеренно pure-Dart, без единого import-а.** Причины две:
///   1. Таблица — часть контракта с сервером, а не деталь виджета-пикера;
///      её место не в файле, который тащит `flutter/material`.
///   2. Серверный контракт-тест
///      (`nsg_connect_server/test/unit/attachment_mime_contract_test.dart`)
///      ЧИТАЕТ ЭТОТ ФАЙЛ КАК ТЕКСТ и парсит [kExtensionToMime] регуляркой:
///      импортировать его он не может (Flutter-пакет + неверное
///      направление зависимости server → sdk).
///
/// ПОЭТОМУ: формат литерала [kExtensionToMime] менять нельзя — только
/// строки вида `'.ext': 'type/subtype',`, по одной паре на строку.
/// Тест падает с внятным текстом, если распарсил подозрительно мало
/// записей, так что «тихо позеленеть» при поломке формата он не может.
///
/// Issue #54: рассинхрон этой таблицы с серверным whitelist-ом ронял
/// отправку `.txt` без объяснения причины. Контракт-тест закрывает
/// именно этот класс багов: любой новый `.psd` здесь обязан быть
/// принят `AttachmentService.validateUpload` на сервере.
library;

/// MIME для расширений, которых нет в [kExtensionToMime]. Сервер обязан
/// принимать и его — иначе произвольный файл с незнакомым расширением
/// нельзя отправить в принципе (ровно баг #54).
const String kFallbackMime = 'application/octet-stream';

/// Расширение (в нижнем регистре, с точкой) → MIME.
///
/// От MIME зависит, каким рядом вложение отрисуется у получателя
/// (`attachment_bubble.dart` свитчится по `mimeType.startsWith`),
/// поэтому честный MIME важнее, чем «всё есть octet-stream».
const Map<String, String> kExtensionToMime = {
  // ─── image ───
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.heic': 'image/heic',
  '.heif': 'image/heif',
  '.avif': 'image/avif',
  '.bmp': 'image/bmp',
  '.tif': 'image/tiff',
  '.tiff': 'image/tiff',
  '.svg': 'image/svg+xml',
  // ─── video ───
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.webm': 'video/webm',
  '.mkv': 'video/x-matroska',
  '.avi': 'video/x-msvideo',
  // ─── audio ───
  '.mp3': 'audio/mpeg',
  '.m4a': 'audio/mp4',
  '.aac': 'audio/aac',
  '.ogg': 'audio/ogg',
  '.oga': 'audio/ogg',
  '.opus': 'audio/opus',
  '.wav': 'audio/wav',
  '.flac': 'audio/flac',
  // ─── text ───
  '.txt': 'text/plain',
  '.log': 'text/plain',
  '.csv': 'text/csv',
  '.md': 'text/markdown',
  '.html': 'text/html',
  '.htm': 'text/html',
  // ─── documents ───
  '.pdf': 'application/pdf',
  '.json': 'application/json',
  '.xml': 'application/xml',
  '.rtf': 'application/rtf',
  '.doc': 'application/msword',
  '.docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.xls': 'application/vnd.ms-excel',
  '.xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  '.ppt': 'application/vnd.ms-powerpoint',
  '.pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  // ─── archives ───
  '.zip': 'application/zip',
  '.rar': 'application/vnd.rar',
  '.7z': 'application/x-7z-compressed',
  '.gz': 'application/gzip',
  '.tar': 'application/x-tar',
};

/// Heuristic MIME guess по расширению — fallback когда `XFile.mimeType`
/// null. Server-side валидирует MIME whitelist.
String guessMimeFromExtension(String filename) {
  final lower = filename.toLowerCase();
  final dot = lower.lastIndexOf('.');
  if (dot < 0) return kFallbackMime;
  return kExtensionToMime[lower.substring(dot)] ?? kFallbackMime;
}

/// Matrix msgType из MIME — ЕДИНСТВЕННАЯ деривация на весь SDK.
///
/// Раньше копий было три (`ChatMessage`, `OutboxSender`,
/// `MessagesController`), и та, что в контроллере, не знала про
/// `audio/` — оптимистичный бабл голосового показывался как файл,
/// пока не приедет authoritative msgType из RPC-ответа.
///
/// Должна совпадать с серверной `AttachmentService
/// .buildContentForAttachment`: она authoritative, эта — для
/// оптимистичного бабла до ответа сервера.
String matrixMsgTypeForMime(String mime) {
  if (mime.startsWith('image/')) return 'm.image';
  if (mime.startsWith('video/')) return 'm.video';
  if (mime.startsWith('audio/')) return 'm.audio';
  return 'm.file';
}

/// Обратный дериват: MIME из Matrix msgType. Нужен для реконструкции
/// `PickedAttachment` при re-upload упавшего члена альбома — точный
/// исходный MIME не сохранён, но серверу достаточно категории, он
/// валидирует байты сам. Fallback — `image/jpeg` (альбом = картинки).
String mimeForMatrixMsgType(String msgType) {
  switch (msgType) {
    case 'm.video':
      return 'video/mp4';
    case 'm.audio':
      return 'audio/mp4';
    case 'm.file':
      return kFallbackMime;
    default:
      return 'image/jpeg';
  }
}
