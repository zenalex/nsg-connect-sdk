import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../i18n/generated/nsg_l10n.dart';

/// Web + desktop: `image_picker` не поддерживает камеру (плагин её не
/// реализует), поэтому пункт «Камера» на этих платформах не показываем.
/// Мобильные (iOS/Android) — показываем.
bool get _hasCameraSource {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// **Клиентский потолок размера одного вложения** (issue #54 п.2).
///
/// ПОЧЕМУ он вообще нужен: и пикер, и upload работают с `bytes` —
/// файл целиком лежит в RAM (а на web ещё и копируется в blob при
/// выборе). Без потолка выбор 4-гигабайтного видео валит приложение
/// по OOM ещё до того, как что-то уйдёт на сервер. Серверного лимита
/// на момент issue #54 тоже нет, так что это единственная защита.
///
/// ПОЧЕМУ именно 50 МиБ: это верх «обычного» вложения в мессенджерах
/// (Telegram-бот 50 МБ, вложение в почте 25 МБ) и при этом влезает
/// в память самого скромного целевого устройства даже с учётом
/// временной копии при кодировании. Черновик копит до `_maxPending`
/// вложений, поэтому потолок на ОДИН файл держим заведомо ниже, чем
/// «сколько влезет всего».
const int kMaxAttachmentBytes = 50 * 1024 * 1024;

/// Тот же лимит в мегабайтах — для текста сообщения пользователю.
const int kMaxAttachmentMb = kMaxAttachmentBytes ~/ (1024 * 1024);

/// Чистая проверка потолка: пустые файлы тоже отбрасываем (отправлять
/// нечего, а сервер такой upload всё равно отвергнет).
bool isAttachmentSizeAllowed(int sizeBytes) =>
    sizeBytes > 0 && sizeBytes <= kMaxAttachmentBytes;

/// Результат выбора: что реально прикрепили и что отвергли по размеру.
///
/// Отдельный список [rejectedOversize] нужен, чтобы UI мог СКАЗАТЬ
/// пользователю про пропущенные файлы, а не отбросить их молча —
/// молчаливый отброс читается как «файл потерялся» (см. issue #54).
@immutable
class AttachmentPickOutcome {
  const AttachmentPickOutcome({
    required this.picked,
    this.rejectedOversize = const <String>[],
  });

  final List<PickedAttachment> picked;

  /// Имена файлов, не прошедших [kMaxAttachmentBytes].
  final List<String> rejectedOversize;

  static const AttachmentPickOutcome empty = AttachmentPickOutcome(
    picked: <PickedAttachment>[],
  );
}

/// Описание выбранного файла, независимое от `file_picker`.
///
/// Прослойка нужна ради тестируемости: логика «проверить размер →
/// прочитать байты → определить MIME» живёт в
/// [buildAttachmentsFromCandidates] и тестируется без мока плагина.
@immutable
class AttachmentCandidate {
  const AttachmentCandidate({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
  });

  final String name;
  final int size;

  /// Байты, если платформа отдала их сразу (web).
  final Uint8List? bytes;

  /// Путь на диске (native) — читаем ЛЕНИВО, уже после проверки размера.
  final String? path;
}

/// Как прочитать байты по пути. Подменяется в тестах.
typedef AttachmentBytesReader = Future<Uint8List> Function(String path);

Future<Uint8List> _readFileBytes(String path) => XFile(path).readAsBytes();

/// Собрать вложения из кандидатов: отсечь по [kMaxAttachmentBytes],
/// прочитать байты только у прошедших, определить MIME.
///
/// [limit] — сколько ещё влезет в черновик (`_maxPending` минус уже
/// набранное). Лишние сверх лимита просто не берём: это мягкий потолок
/// количества, он же действует и для галереи.
Future<AttachmentPickOutcome> buildAttachmentsFromCandidates(
  List<AttachmentCandidate> candidates, {
  int? limit,
  AttachmentBytesReader? readBytes,
}) async {
  final reader = readBytes ?? _readFileBytes;
  final picked = <PickedAttachment>[];
  final rejected = <String>[];
  for (final c in candidates) {
    // Отвергаем ДО чтения байтов — в этом весь смысл проверки по
    // заявленному размеру: огромный файл не попадает в память вовсе.
    if (!isAttachmentSizeAllowed(c.size)) {
      rejected.add(c.name);
      continue;
    }
    if (limit != null && picked.length >= limit) break;
    Uint8List bytes;
    if (c.bytes != null) {
      bytes = c.bytes!;
    } else if (c.path != null) {
      try {
        bytes = await reader(c.path!);
      } catch (_) {
        continue; // файл исчез / нет прав — пропускаем молча
      }
    } else {
      continue; // ни байтов, ни пути — брать нечего
    }
    // Повторная проверка по факту: заявленный `size` мог соврать
    // (симлинк, подмена файла между выбором и чтением).
    if (!isAttachmentSizeAllowed(bytes.length)) {
      rejected.add(c.name);
      continue;
    }
    picked.add(
      PickedAttachment(
        bytes: bytes,
        // `file_picker` не отдаёт MIME ни на одной платформе, поэтому
        // всегда идём через общий fallback по расширению — тот же,
        // что используют image_picker-путь и share-intake.
        mimeType: guessMimeFromExtension(c.name),
        originalFilename: c.name,
      ),
    );
  }
  return AttachmentPickOutcome(picked: picked, rejectedOversize: rejected);
}

/// Отсечь по размеру уже прочитанные вложения (путь image_picker —
/// там байты приходят раньше, чем узнаём размер, поэтому проверка
/// пост-фактум; память уже занята, но отправка не уйдёт).
AttachmentPickOutcome partitionBySizeLimit(List<PickedAttachment> items) {
  final picked = <PickedAttachment>[];
  final rejected = <String>[];
  for (final item in items) {
    if (isAttachmentSizeAllowed(item.bytes.length)) {
      picked.add(item);
    } else {
      rejected.add(item.originalFilename);
    }
  }
  return AttachmentPickOutcome(picked: picked, rejectedOversize: rejected);
}

/// Результат выбора attachment-а юзером — bytes + MIME + filename
/// для последующего `uploadAttachment` server-side. SDK абстрагирует
/// `image_picker` API; downstream UI оперирует только `PickedAttachment`.
@immutable
class PickedAttachment {
  const PickedAttachment({
    required this.bytes,
    required this.mimeType,
    required this.originalFilename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String originalFilename;
}

/// Bottom-sheet с действиями attach в `MessageComposer`.
///
/// Источники: «Камера» (только мобильные), «Изображение» (галерея,
/// мультивыбор) и «Файл» — произвольный файл через `file_picker`
/// (issue #54 п.2). На desktop/web раньше сразу открывалась галерея,
/// но с появлением пункта «Файл» выбор нужен уже везде.
///
/// Возвращает список [PickedAttachment] (пустой, если юзер cancel-нул).
/// Файлы, не прошедшие [kMaxAttachmentBytes], сюда не попадают — про
/// них показывается snackbar (не молчаливый отброс).
Future<List<PickedAttachment>> showAttachmentPicker({
  required BuildContext context,
  ImagePicker? pickerOverride,
  int? galleryLimit,
}) async {
  final picker = pickerOverride ?? ImagePicker();
  final outcome = await showModalBottomSheet<AttachmentPickOutcome>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) =>
        _AttachmentPickerSheet(picker: picker, galleryLimit: galleryLimit),
  );
  if (outcome == null) return const <PickedAttachment>[];
  if (outcome.rejectedOversize.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          NsgL10n.of(
            context,
          ).attachFileTooLarge(outcome.rejectedOversize.join(', ')),
        ),
      ),
    );
  }
  return outcome.picked;
}

/// Выбор произвольного файла (issue #54 п.2). Мультивыбор — как
/// у галереи; [limit] ограничивает сверху числом свободных слотов
/// черновика.
Future<AttachmentPickOutcome> pickFilesAttachment({int? limit}) async {
  final FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      // `withData` только на web: там у файла нет пути и байты — это
      // единственный способ их получить (цена — огромный файл всё же
      // попадёт в память до проверки; на web иначе никак). На native
      // читаем лениво в buildAttachmentsFromCandidates, уже после
      // проверки размера.
      withData: kIsWeb,
    );
  } catch (_) {
    return AttachmentPickOutcome.empty; // плагин недоступен / отказ ОС
  }
  if (result == null || result.files.isEmpty) {
    return AttachmentPickOutcome.empty; // cancel
  }
  return buildAttachmentsFromCandidates(
    result.files
        .map(
          (f) => AttachmentCandidate(
            name: f.name,
            size: f.size,
            bytes: f.bytes,
            path: f.path,
          ),
        )
        .toList(),
    limit: limit,
  );
}

/// Pick → read bytes → derive MIME. `image_picker` возвращает `XFile`
/// с опциональным `.mimeType`; fallback по extension. Возвращает null на
/// cancel / permission-denied / camera-unavailable (UI покажет snackbar).
Future<PickedAttachment?> pickImageAttachment(
  ImagePicker picker,
  ImageSource source,
) async {
  final XFile? file;
  try {
    file = await picker.pickImage(source: source);
  } catch (_) {
    return null;
  }
  if (file == null) return null; // user cancelled
  final bytes = await file.readAsBytes();
  final mime = file.mimeType ?? guessMimeFromExtension(file.name);
  return PickedAttachment(
    bytes: bytes,
    mimeType: mime,
    originalFilename: file.name,
  );
}

/// **Мультивыбор из галереи** (`pickMultiImage`, image_picker 1.2.x) —
/// несколько картинок одним действием для оптимистичного альбома. Читает
/// байты + derive MIME для каждой (порядок выбора сохраняется). Пустой
/// список на cancel / permission-denied. [limit] — потолок числа картинок
/// (null → без ограничения плагином; композер докапливает до `_maxPending`).
Future<List<PickedAttachment>> pickImagesAttachment(
  ImagePicker picker, {
  int? limit,
}) async {
  final List<XFile> files;
  try {
    files = await picker.pickMultiImage(limit: limit);
  } catch (_) {
    return const <PickedAttachment>[];
  }
  if (files.isEmpty) return const <PickedAttachment>[];
  final result = <PickedAttachment>[];
  for (final file in files) {
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? guessMimeFromExtension(file.name);
    result.add(
      PickedAttachment(
        bytes: bytes,
        mimeType: mime,
        originalFilename: file.name,
      ),
    );
  }
  return result;
}

/// Heuristic MIME guess по расширению — fallback когда `XFile.mimeType`
/// null. Server-side валидирует MIME whitelist.
String guessMimeFromExtension(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  if (lower.endsWith('.avif')) return 'image/avif';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  // Issue #54 п.2: с приходом произвольных файлов таблица расширена —
  // от MIME зависит, каким рядом вложение отрисуется у получателя
  // (`attachment_bubble.dart` свитчится по mimeType), поэтому честный
  // MIME важнее, чем «всё есть octet-stream».
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.mkv')) return 'video/x-matroska';
  if (lower.endsWith('.avi')) return 'video/x-msvideo';
  if (lower.endsWith('.mp3')) return 'audio/mpeg';
  if (lower.endsWith('.m4a')) return 'audio/mp4';
  if (lower.endsWith('.aac')) return 'audio/aac';
  if (lower.endsWith('.ogg') || lower.endsWith('.oga')) return 'audio/ogg';
  if (lower.endsWith('.opus')) return 'audio/opus';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.flac')) return 'audio/flac';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.txt') || lower.endsWith('.log')) return 'text/plain';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.md')) return 'text/markdown';
  if (lower.endsWith('.html') || lower.endsWith('.htm')) return 'text/html';
  if (lower.endsWith('.json')) return 'application/json';
  if (lower.endsWith('.xml')) return 'application/xml';
  if (lower.endsWith('.zip')) return 'application/zip';
  if (lower.endsWith('.rar')) return 'application/vnd.rar';
  if (lower.endsWith('.7z')) return 'application/x-7z-compressed';
  if (lower.endsWith('.gz')) return 'application/gzip';
  if (lower.endsWith('.tar')) return 'application/x-tar';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
  if (lower.endsWith('.pptx')) {
    return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  }
  if (lower.endsWith('.rtf')) return 'application/rtf';
  if (lower.endsWith('.svg')) return 'image/svg+xml';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.tif') || lower.endsWith('.tiff')) return 'image/tiff';
  return 'application/octet-stream';
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet({required this.picker, this.galleryLimit});

  final ImagePicker picker;
  final int? galleryLimit;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              l.attachActionSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Камера — только там, где image_picker её реализует.
          if (_hasCameraSource)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.attachActionCamera),
              onTap: () async {
                // Камера — одна картинка; оборачиваем в список для единого
                // контракта showAttachmentPicker → List.
                final result = await pickImageAttachment(
                  picker,
                  ImageSource.camera,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop(
                  result == null
                      ? AttachmentPickOutcome.empty
                      : partitionBySizeLimit([result]),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            // На desktop/web «галереи» как таковой нет — там это обычный
            // диалог выбора файла, отфильтрованный по картинкам, поэтому
            // называем пункт «Изображение».
            title: Text(
              _hasCameraSource ? l.attachActionGallery : l.attachActionImage,
            ),
            onTap: () async {
              // Галерея — мультивыбор (Telegram-style альбом).
              final result = await pickImagesAttachment(
                picker,
                limit: galleryLimit,
              );
              if (!context.mounted) return;
              Navigator.of(context).pop(partitionBySizeLimit(result));
            },
          ),
          // Issue #54 п.2: произвольный файл (документ, архив, видео…).
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(l.attachActionFile),
            onTap: () async {
              final outcome = await pickFilesAttachment(limit: galleryLimit);
              if (!context.mounted) return;
              Navigator.of(context).pop(outcome);
            },
          ),
        ],
      ),
    );
  }
}
