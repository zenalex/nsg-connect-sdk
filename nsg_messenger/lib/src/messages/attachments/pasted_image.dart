/// **Картинка из буфера обмена — не обязательно PNG.**
///
/// Живой случай (прод, 28.07): из 67 присланных `image/png` у 42 Synapse
/// не смог сделать превью и на каждый запрос миниатюры отвечал 400
/// («Failed to find any generated thumbnails»). Все 42 — вставки из
/// буфера (`clipboard-*.png`), и все они на самом деле BMP: первые байты
/// `42 4D` («BM»). У 25 настоящих PNG и у всех 63 JPEG превью на месте.
///
/// Причина: `Pasteboard.image` отдаёт то, что лежит в системном буфере,
/// а Windows кладёт туда DIB (BMP). Композер подписывал эти байты
/// `image/png`, не глядя. Synapse верит объявленному типу, разобрать
/// файл как PNG не выходит — миниатюра не рождается. И уже не родится:
/// media в Matrix иммутабельна, так что каждая такая картинка навсегда
/// осталась без превью, а клиент на каждый показ тянул полный файл.
///
/// Чиним в момент вставки: определяем формат по байтам и пережимаем в
/// настоящий PNG. Побочная выгода крупная — скриншот в BMP весит 6–8 МБ
/// (в проде именно такие и лежат), тот же кадр в PNG — сотни килобайт.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'attachment_picker.dart' show PickedAttachment;

/// MIME по «магическим» байтам. `null` — формат не опознан.
///
/// Смотрим на содержимое, а не на то, чем его назвали: объявленный тип
/// здесь и был источником всей проблемы.
String? sniffImageMime(Uint8List bytes) {
  bool starts(List<int> magic, {int at = 0}) {
    if (bytes.length < at + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[at + i] != magic[i]) return false;
    }
    return true;
  }

  if (starts(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (starts(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (starts(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  // RIFF....WEBP — размер между сигнатурами не проверяем, он произвольный.
  if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
      starts(const [0x57, 0x45, 0x42, 0x50], at: 8)) {
    return 'image/webp';
  }
  if (starts(const [0x42, 0x4D])) return 'image/bmp';
  if (starts(const [0x49, 0x49, 0x2A, 0x00]) ||
      starts(const [0x4D, 0x4D, 0x00, 0x2A])) {
    return 'image/tiff';
  }
  return null;
}

/// Форматы, которые дальше по конвейеру умеют все: Synapse делает
/// превью, браузер и мобильный клиент рисуют. Остальное пережимаем.
const Map<String, String> _passThroughExtensions = {
  'image/png': '.png',
  'image/jpeg': '.jpg',
  'image/gif': '.gif',
  'image/webp': '.webp',
};

/// Перекодировщик в PNG. Отдельным типом — чтобы тесты не зависели от
/// платформенных кодеков.
typedef PngEncoder = Future<Uint8List?> Function(Uint8List source);

/// Вложение из байтов буфера обмена: с честным типом и, если надо,
/// пережатое в PNG.
///
/// [stampMs] — метка времени для имени файла (передаётся снаружи, чтобы
/// имя было предсказуемым в тестах).
Future<PickedAttachment> pastedImageAttachment(
  Uint8List bytes, {
  required int stampMs,
  PngEncoder encodeToPng = encodePngViaEngine,
}) async {
  final sniffed = sniffImageMime(bytes);
  final passThrough = _passThroughExtensions[sniffed];
  if (passThrough != null) {
    return PickedAttachment(
      bytes: bytes,
      mimeType: sniffed!,
      originalFilename: 'clipboard-$stampMs$passThrough',
    );
  }

  final png = await encodeToPng(bytes);
  if (png != null && png.isNotEmpty) {
    return PickedAttachment(
      bytes: png,
      mimeType: 'image/png',
      originalFilename: 'clipboard-$stampMs.png',
    );
  }

  // Пережать не вышло. Отправляем как есть, но НЕ врём про тип: BMP и
  // TIFF сервер принимает (см. `_imageMimes`), и честная подпись хотя бы
  // даёт ему шанс сделать превью самому. Формат не опознан вовсе —
  // остаёмся на прежнем `image/png`: так работало до этой правки на
  // macOS и Linux, где буфер и правда отдаёт PNG.
  final fallbackMime = sniffed ?? 'image/png';
  final ext = switch (fallbackMime) {
    'image/bmp' => '.bmp',
    'image/tiff' => '.tiff',
    _ => '.png',
  };
  return PickedAttachment(
    bytes: bytes,
    mimeType: fallbackMime,
    originalFilename: 'clipboard-$stampMs$ext',
  );
}

/// Перекодирование средствами движка — без новой зависимости.
///
/// `dart:ui` уже умеет и разобрать BMP, и собрать PNG; тянуть ради этого
/// пакет `image` (свой декодер на Dart) смысла нет — он и медленнее, и
/// это лишние килобайты в каждом хосте, который встраивает SDK.
Future<Uint8List?> encodePngViaEngine(Uint8List source) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(source);
    final frame = await codec.getNextFrame();
    image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (_) {
    // Кодек не осилил — вызывающий останется на исходных байтах.
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}
