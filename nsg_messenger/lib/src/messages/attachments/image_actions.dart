/// **Копирование / расшаривание картинки из сообщения** (запрос
/// постановщика: «картинку нельзя скопировать/расшарить»).
///
/// Одна платформо-адаптивная точка входа [ImageActions.runPrimary]:
///   * mobile (iOS/Android) и web → **Поделиться** системным share sheet
///     (`share_plus`);
///   * desktop (Windows/macOS/Linux) → **Скопировать** картинку в буфер
///     обмена (`pasteboard`).
///
/// Плюс явные [ImageActions.shareImage] / [ImageActions.copyImage] для меню
/// сообщения (лонг-тап / правый клик), где пункт «Скопировать изображение»
/// нужен независимо от платформенного дефолта.
///
/// **Тестируемость**: платформенные эффекты (share sheet, запись в буфер,
/// запись temp-файла) и сама платформа инъектируются через конструктор —
/// юнит-тесты гоняют логику без реальных плагинов. Загрузка байтов идёт
/// через [ImageActions.loadBytes] (в проде — `downloadAttachment` full-size).
library;

import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

/// Загрузчик полноразмерных байт вложения по `mxcUrl` (в проде —
/// `MessagesController.downloadFullSize`).
typedef ImageBytesLoader = Future<Uint8List> Function(String mxcUrl);

/// Инъекция системного share (по умолчанию — `SharePlus`).
typedef ShareFilesFn = Future<void> Function(List<XFile> files);

/// Инъекция «положить bitmap в буфер обмена» (по умолчанию —
/// `Pasteboard.writeImage`).
typedef CopyImageBytesFn = Future<void> Function(Uint8List bytes);

/// Инъекция «положить файловую ссылку в буфер» (по умолчанию —
/// `Pasteboard.writeFiles`). Нужен на Linux, где `writeImage` — no-op.
typedef CopyFilesFn = Future<void> Function(List<String> paths);

/// Инъекция записи временного файла (по умолчанию — path_provider tmp).
typedef WriteTempFileFn = Future<String> Function(String name, Uint8List bytes);

/// Действие по картинке в зависимости от платформы.
enum ImagePrimaryAction { share, copy }

/// Выбор share-vs-copy по платформе — **чистая функция** (тестируется без
/// реальных плагинов): mobile/web → share; desktop → copy.
ImagePrimaryAction imagePrimaryActionFor(
  TargetPlatform platform, {
  required bool isWeb,
}) {
  // Web — только share (Web Share API); копирование файла в буфер на web
  // ограничено (см. постановку), а bitmap-clipboard браузеров нестабилен.
  if (isWeb) return ImagePrimaryAction.share;
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
      return ImagePrimaryAction.share;
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return ImagePrimaryAction.copy;
  }
}

/// Сервис действий над картинкой сообщения (share / copy). Собирается из
/// загрузчика байтов ([ImageActions.fromDownloader] — из download-RPC),
/// эффекты дефолтятся на реальные плагины, но перекрываются в тестах.
class ImageActions {
  ImageActions({
    required this.loadBytes,
    ShareFilesFn? shareFiles,
    CopyImageBytesFn? copyImageBytes,
    CopyFilesFn? copyFiles,
    WriteTempFileFn? writeTempFile,
    TargetPlatform? platformOverride,
    bool? isWebOverride,
  }) : _shareFiles = shareFiles ?? _defaultShareFiles,
       _copyImageBytes = copyImageBytes ?? _defaultCopyImageBytes,
       _copyFiles = copyFiles ?? _defaultCopyFiles,
       _writeTempFile = writeTempFile ?? _defaultWriteTempFile,
       _platform = platformOverride ?? defaultTargetPlatform,
       _isWeb = isWebOverride ?? kIsWeb;

  /// Удобный конструктор из download-RPC (`downloadAttachment` full-size).
  /// Signature совпадает с `MessagesController.downloadFullSize` и
  /// `DownloadAttachmentRpc`.
  factory ImageActions.fromDownloader(
    Future<AttachmentBytes> Function({required String mxcUrl}) downloadFullSize, {
    ShareFilesFn? shareFiles,
    CopyImageBytesFn? copyImageBytes,
    CopyFilesFn? copyFiles,
    WriteTempFileFn? writeTempFile,
    TargetPlatform? platformOverride,
    bool? isWebOverride,
  }) {
    return ImageActions(
      loadBytes: (mxcUrl) async {
        final data = await downloadFullSize(mxcUrl: mxcUrl);
        // ByteData → Uint8List без копии (view над тем же буфером).
        return data.bytes.buffer.asUint8List(
          data.bytes.offsetInBytes,
          data.bytes.lengthInBytes,
        );
      },
      shareFiles: shareFiles,
      copyImageBytes: copyImageBytes,
      copyFiles: copyFiles,
      writeTempFile: writeTempFile,
      platformOverride: platformOverride,
      isWebOverride: isWebOverride,
    );
  }

  final ImageBytesLoader loadBytes;
  final ShareFilesFn _shareFiles;
  final CopyImageBytesFn _copyImageBytes;
  final CopyFilesFn _copyFiles;
  final WriteTempFileFn _writeTempFile;
  final TargetPlatform _platform;
  final bool _isWeb;

  /// Платформенный дефолт для одной кнопки в fullscreen-оверлее.
  ImagePrimaryAction primaryAction() =>
      imagePrimaryActionFor(_platform, isWeb: _isWeb);

  /// Нужны ли просмотрщику ВИДИМЫЕ кнопки листания (‹ ›).
  ///
  /// На тач-платформах листание свайпом естественно и кнопки были бы
  /// мусором. На десктопе/web свайпнуть мышью нечем: горизонтальный drag
  /// над [PhotoView] — это панорама зума, а не переход к соседней
  /// картинке. Без кнопок механизм листания на десктопе физически
  /// недостижим (issue #54 — «нет листания картинок» с Windows).
  ///
  /// Отдельный предикат, а НЕ переиспользование [primaryAction]: там web
  /// приравнен к mobile (share), а здесь web — десктопный по способу
  /// ввода (мышь). Живёт здесь, потому что [ImageActions] уже
  /// инъектируется в просмотрщик и уже держит платформу с override-ами
  /// для тестов — заводить рядом четвёртый способ определять платформу
  /// не хочется.
  bool get needsPagingButtons =>
      _isWeb ||
      _platform == TargetPlatform.windows ||
      _platform == TargetPlatform.macOS ||
      _platform == TargetPlatform.linux;

  /// Выполнить платформенное действие по умолчанию (share на mobile/web,
  /// copy на desktop). Бросает при ошибке — вызывающий UI покажет snackbar.
  Future<void> runPrimary(AttachmentRef att) =>
      primaryAction() == ImagePrimaryAction.share
      ? shareImage(att)
      : copyImage(att);

  /// Поделиться картинкой наружу (системный share sheet).
  ///
  /// Non-web — пишем temp-файл (path_provider) и отдаём `XFile(path)`
  /// (надёжнее для нативных share-провайдеров, как просил постановщик).
  /// Web — `XFile.fromData` (Web Share API, temp-файл недоступен).
  Future<void> shareImage(AttachmentRef att) async {
    final bytes = await loadBytes(att.mxcUrl);
    final name = _safeName(att);
    if (_isWeb) {
      await _shareFiles([
        XFile.fromData(bytes, mimeType: att.mimeType, name: name),
      ]);
      return;
    }
    final path = await _writeTempFile(name, bytes);
    await _shareFiles([XFile(path, mimeType: att.mimeType, name: name)]);
  }

  /// Скопировать картинку в буфер обмена.
  ///
  /// Linux — `pasteboard.writeImage` не реализован (no-op), поэтому кладём
  /// файловую ссылку (`writeFiles`). Остальные платформы (Win/mac/iOS/
  /// Android/web) поддерживают bitmap в буфер напрямую.
  Future<void> copyImage(AttachmentRef att) async {
    final bytes = await loadBytes(att.mxcUrl);
    if (!_isWeb && _platform == TargetPlatform.linux) {
      final path = await _writeTempFile(_safeName(att), bytes);
      await _copyFiles([path]);
      return;
    }
    await _copyImageBytes(bytes);
  }

  /// Плоское безопасное имя файла для temp-каталога/share. Из
  /// `originalFilename`; пусто → `image.<ext>` по mime. Разделители путей
  /// и запрещённые символы заменяем на `_`.
  static String _safeName(AttachmentRef att) {
    final raw = att.originalFilename.trim();
    final base = raw.isNotEmpty ? raw : 'image${_extForMime(att.mimeType)}';
    return base.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
  }

  static String _extForMime(String mime) {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/heic':
        return '.heic';
      default:
        return '.bin';
    }
  }

  static Future<void> _defaultShareFiles(List<XFile> files) =>
      SharePlus.instance.share(ShareParams(files: files));

  static Future<void> _defaultCopyImageBytes(Uint8List bytes) =>
      Pasteboard.writeImage(bytes);

  static Future<void> _defaultCopyFiles(List<String> paths) =>
      Pasteboard.writeFiles(paths);

  static Future<String> _defaultWriteTempFile(
    String name,
    Uint8List bytes,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
