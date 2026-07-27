/// **Действия над файловым вложением** (issue #69): просмотр, открытие во
/// внешней программе, сохранение на диск.
///
/// До этого тап по файлу в бабле не делал НИЧЕГО: у `_FileRow` не было
/// обработчика вовсе — ни у .md, ни у .pdf, ни у видео. Картинки и альбомы
/// тап обрабатывали, файлы молча игнорировали, и понять это можно было
/// только потыкав.
///
/// Разделение по платформам — из-за файловых URI, а не из вкусовщины:
///   * desktop (Windows/macOS/Linux) — пишем во временный файл и отдаём ОС
///     (`file://` через url_launcher), сохраняем в «Загрузки»;
///   * mobile/web — системный share sheet: на Android `file://` наружу
///     кидать нельзя (FileUriExposedException), а sheet и «открыть в…», и
///     «сохранить» закрывает одним жестом.
///
/// Эффекты (share, launch, запись файла, каталог загрузок) инъектируются —
/// логика тестируется без реальных плагинов, как в [ImageActions], откуда
/// этот подход и взят.
library;

import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'image_actions.dart' show ImageBytesLoader, ShareFilesFn, WriteTempFileFn;

/// Инъекция «открыть путь средствами ОС» (по умолчанию — url_launcher).
typedef OpenPathFn = Future<bool> Function(String path);

/// Инъекция «каталог загрузок» (по умолчанию — path_provider). `null` —
/// каталога нет (мобильные платформы).
typedef DownloadsDirFn = Future<String?> Function();

/// Расширения, которые показываем ВНУТРИ приложения (текст как текст).
///
/// Список по расширению, а не по mime: сервер отдаёт `.md` как
/// `text/markdown`, а бывает и `application/octet-stream` — по mime
/// пользователь получил бы «непонятный файл» на понятном формате.
/// `text/*` тоже принимаем (см. [isTextPreviewable]).
const kPreviewableTextExtensions = <String>{
  '.md', '.markdown', '.txt', '.log', '.csv', '.json', '.yaml', '.yml',
  '.xml', '.ini', '.conf', '.sql', '.dart', '.py', '.js', '.ts', '.sh',
  '.ps1', '.bat', '.html', '.css', '.kt', '.java', '.cs', '.go', '.rs',
};

/// Потолок на предпросмотр: 2 МБ текста — это уже не «посмотреть», а
/// подвесить UI на рендере. Больше — предлагаем открыть внешней программой.
const kMaxPreviewBytes = 2 * 1024 * 1024;

/// Можно ли показать вложение текстом прямо в приложении.
bool isTextPreviewable({
  required String filename,
  required String mimeType,
  required int sizeBytes,
}) {
  if (sizeBytes > kMaxPreviewBytes) return false;
  final mime = mimeType.toLowerCase();
  // Картинки/аудио/видео сюда не попадают — у них свои рендеры; но
  // `text/*` с любым суффиксом (charset) показать можно.
  if (mime.startsWith('text/')) return true;
  if (mime == 'application/json' || mime == 'application/xml') return true;
  final ext = p.extension(filename).toLowerCase();
  return kPreviewableTextExtensions.contains(ext);
}

/// Сервис действий над файловым вложением.
class FileActions {
  FileActions({
    required this.loadBytes,
    ShareFilesFn? shareFiles,
    WriteTempFileFn? writeTempFile,
    OpenPathFn? openPath,
    DownloadsDirFn? downloadsDir,
    TargetPlatform? platformOverride,
    bool? isWebOverride,
  }) : _shareFiles = shareFiles ?? _defaultShareFiles,
       _writeTempFile = writeTempFile ?? _defaultWriteTempFile,
       _openPath = openPath ?? _defaultOpenPath,
       _downloadsDir = downloadsDir ?? _defaultDownloadsDir,
       _platform = platformOverride ?? defaultTargetPlatform,
       _isWeb = isWebOverride ?? kIsWeb;

  /// Конструктор из download-RPC — как у [ImageActions.fromDownloader].
  factory FileActions.fromDownloader(
    Future<AttachmentBytes> Function({required String mxcUrl}) downloadFullSize, {
    ShareFilesFn? shareFiles,
    WriteTempFileFn? writeTempFile,
    OpenPathFn? openPath,
    DownloadsDirFn? downloadsDir,
    TargetPlatform? platformOverride,
    bool? isWebOverride,
  }) {
    return FileActions(
      loadBytes: (mxcUrl) async {
        final data = await downloadFullSize(mxcUrl: mxcUrl);
        return data.bytes.buffer.asUint8List(
          data.bytes.offsetInBytes,
          data.bytes.lengthInBytes,
        );
      },
      shareFiles: shareFiles,
      writeTempFile: writeTempFile,
      openPath: openPath,
      downloadsDir: downloadsDir,
      platformOverride: platformOverride,
      isWebOverride: isWebOverride,
    );
  }

  final ImageBytesLoader loadBytes;
  final ShareFilesFn _shareFiles;
  final WriteTempFileFn _writeTempFile;
  final OpenPathFn _openPath;
  final DownloadsDirFn _downloadsDir;
  final TargetPlatform _platform;
  final bool _isWeb;

  /// Десктоп ли (файловые пути и «Загрузки» имеют смысл).
  bool get isDesktop =>
      !_isWeb &&
      (_platform == TargetPlatform.windows ||
          _platform == TargetPlatform.macOS ||
          _platform == TargetPlatform.linux);

  /// Открыть во внешней программе. На десктопе — руками ОС по временному
  /// пути; на mobile/web — системный sheet (там «открыть в…» и есть).
  Future<void> openExternally(AttachmentRef att) async {
    final bytes = await loadBytes(att.mxcUrl);
    final name = safeName(att);
    if (!isDesktop) {
      await _share(att, name, bytes);
      return;
    }
    final path = await _writeTempFile(name, bytes);
    final ok = await _openPath(path);
    if (!ok) {
      // ОС не нашла обработчик (нет ассоциации с расширением) — это не
      // сбой загрузки, и говорить о нём надо иначе. Пробрасываем типом,
      // чтобы UI показал «нет программы для этого файла», а не «ошибка».
      throw NoHandlerForFileException(name);
    }
  }

  /// Сохранить на диск. Десктоп — в «Загрузки» (возврат — полный путь,
  /// его показывает UI). Mobile/web — системный sheet: сохранение там
  /// делает сама платформа, возврат `null`.
  Future<String?> saveToDisk(AttachmentRef att) async {
    final bytes = await loadBytes(att.mxcUrl);
    final name = safeName(att);
    if (!isDesktop) {
      await _share(att, name, bytes);
      return null;
    }
    final dir = await _downloadsDir();
    if (dir == null) {
      // Каталога загрузок нет — не роняем действие, кладём во временный.
      return _writeTempFile(name, bytes);
    }
    final file = File(_uniquePath(dir, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Текст вложения для предпросмотра. Битые байты не роняют просмотр:
  /// декодируем с заменой (`allowMalformed`) — лучше показать текст с
  /// «кракозяброй» в одном месте, чем пустой экран с ошибкой.
  Future<String> loadTextPreview(AttachmentRef att) async {
    final bytes = await loadBytes(att.mxcUrl);
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _share(AttachmentRef att, String name, Uint8List bytes) async {
    if (_isWeb) {
      await _shareFiles([
        XFile.fromData(bytes, mimeType: att.mimeType, name: name),
      ]);
      return;
    }
    final path = await _writeTempFile(name, bytes);
    await _shareFiles([XFile(path, mimeType: att.mimeType, name: name)]);
  }

  /// Имя файла, безопасное для файловой системы. Пустое → `file.bin`.
  /// Разделители путей вычищаем: `originalFilename` приходит от отправителя
  /// и «../» в нём писать в чужой каталог не должен.
  static String safeName(AttachmentRef att) {
    final raw = att.originalFilename.trim();
    final base = raw.isNotEmpty ? p.basename(raw) : 'file.bin';
    final cleaned = base.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
    return cleaned.isEmpty || cleaned == '.' || cleaned == '..'
        ? 'file.bin'
        : cleaned;
  }

  /// `report.md` уже есть → `report (1).md`. Молча перезаписывать чужой
  /// файл в «Загрузках» нельзя — это не наш каталог.
  static String _uniquePath(String dir, String name) {
    final ext = p.extension(name);
    final stem = p.basenameWithoutExtension(name);
    var candidate = p.join(dir, name);
    var i = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir, '$stem ($i)$ext');
      i++;
    }
    return candidate;
  }

  static Future<void> _defaultShareFiles(List<XFile> files) =>
      SharePlus.instance.share(ShareParams(files: files));

  static Future<String> _defaultWriteTempFile(
    String name,
    Uint8List bytes,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<bool> _defaultOpenPath(String path) =>
      launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);

  static Future<String?> _defaultDownloadsDir() async {
    try {
      final dir = await getDownloadsDirectory();
      return dir?.path;
    } on UnsupportedError {
      return null;
    }
  }
}

/// Для файла нет программы по умолчанию (ОС отказалась открывать).
class NoHandlerForFileException implements Exception {
  const NoHandlerForFileException(this.filename);

  final String filename;

  @override
  String toString() => 'NoHandlerForFileException($filename)';
}
