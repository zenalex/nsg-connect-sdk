import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:photo_view/photo_view.dart';

import '../../i18n/generated/nsg_l10n.dart';
import 'audio_player_row.dart';
import 'mxc_image_provider.dart';
import '../../theme/glass_blur.dart';

/// **Оптимистичный альбом**: одна плитка мозаики — либо уже загруженная
/// (`mxc` доступен, рендер через [MxcImageProvider]), либо ещё грузящаяся
/// (локальные байты, рендер блюром + прогресс). Sealed — [AlbumMosaic]
/// исчерпывающе switch-ает оба случая.
sealed class AlbumTile {
  const AlbumTile();
}

/// Загруженная плитка — привязан `mxc` (thumbnail/full).
class UploadedTile extends AlbumTile {
  const UploadedTile(this.ref);
  final AttachmentRef ref;
}

/// Грузящаяся плитка — локальные байты, аплоад в фоне. Рендерится блюром
/// + `CircularProgressIndicator`; тап отключён.
class UploadingTile extends AlbumTile {
  const UploadingTile(this.bytes);
  final Uint8List bytes;
}

/// Render `MessengerMessage.attachment` внутри `MessageBubble` (TASK19
/// Chunk 3). Switch по mimeType:
///
///   * `image/*` + `thumbnailMxcUrl != null` → [MxcImageProvider]
///     thumbnail preview, tap → fullscreen [PhotoView] с pinch-zoom
///     через full-size download.
///   * `image/*` + `thumbnailMxcUrl == null` (HEIC без probe / corrupt
///     server-side decode) → fallback на icon-row (`broken_image`).
///   * `video/*` → file-style row + play icon (preview Phase2 — нужен
///     FFmpeg server-side для thumbnail).
///   * `application/*` (PDF / zip / etc) → file row с mime-iconom + size.
///
/// **Не блокирует bubble** — renders в any state (sent / pending /
/// failed). Pending bubble показывает `attachment` от optimistic — UI
/// выглядит сразу как media-сообщение, без spinner-замены на bytes.
class AttachmentBubble extends StatelessWidget {
  const AttachmentBubble({
    super.key,
    required this.attachment,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.textColor,
    this.onOpenImage,
  });

  final AttachmentRef attachment;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  /// Цвет fallback-иконок и текста — bubble сам передаёт в зависимости
  /// от own/peer (theme primary vs surface).
  final Color textColor;

  /// Tap по картинке-превью. Host (ChatScreen) открывает галерею всех
  /// картинок чата с листанием, стартуя с этой. Если null — fallback на
  /// одиночный полноэкранный просмотр.
  final void Function(AttachmentRef tapped)? onOpenImage;

  bool get _isImage => attachment.mimeType.startsWith('image/');
  bool get _isVideo => attachment.mimeType.startsWith('video/');
  bool get _isAudio => attachment.mimeType.startsWith('audio/');

  @override
  Widget build(BuildContext context) {
    if (_isImage && attachment.thumbnailMxcUrl != null) {
      return _ImagePreview(
        attachment: attachment,
        thumbnailRpc: thumbnailRpc,
        fullSizeRpc: fullSizeRpc,
        textColor: textColor,
        onOpenImage: onOpenImage,
      );
    }
    if (_isAudio) {
      // **B-voice**: render m.audio как inline-player (play/pause +
      // progress + duration). Bytes lazy-loaded на первый play через
      // fullSizeRpc.
      return AudioPlayerRow(
        attachment: attachment,
        fullSizeRpc: fullSizeRpc,
        textColor: textColor,
      );
    }
    if (_isVideo) {
      return _FileRow(
        attachment: attachment,
        leading: Icons.play_circle_outline,
        textColor: textColor,
      );
    }
    // Image без thumbnail (HEIC/HEIF без Dart-side decoder) → file_row
    // с photo icon. Раньше использовали broken_image_outlined, но HEIC
    // — валидное iOS-фото без preview из-за weak Dart decoder, не
    // битый файл. UX-сигнал «picture without preview», не «corrupt».
    // Sign-off review #2.
    return _FileRow(
      attachment: attachment,
      leading: _isImage
          ? Icons.image_outlined
          : Icons.insert_drive_file_outlined,
      textColor: textColor,
    );
  }
}

/// **Альбом**: мозаика из нескольких картинок одного сообщения (общий
/// `albumId`). 2-колоночная сетка квадратных превью (cover), тап по
/// плитке → [onOpenImage] (галерея всех картинок чата с листанием).
/// Рендерится [MessageBubble]-ом вместо одиночного [AttachmentBubble],
/// подпись альбома идёт отдельным `_BodyText` под мозаикой.
class AlbumMosaic extends StatelessWidget {
  const AlbumMosaic({
    super.key,
    required this.tiles,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.textColor,
    this.onOpenImage,
  });

  /// Плитки альбома — смешанные загруженные ([UploadedTile]) и грузящиеся
  /// ([UploadingTile]).
  final List<AlbumTile> tiles;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;
  final Color textColor;

  /// Тап по загруженной плитке → галерея. Грузящиеся плитки тап игнорируют.
  final void Function(AttachmentRef tapped)? onOpenImage;

  static const double _maxW = 264;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final cols = tiles.length == 1 ? 1 : 2;
    final tile = (_maxW - _gap * (cols - 1)) / cols;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _maxW,
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final t in tiles)
                _MosaicTile(
                  tile: t,
                  size: tile,
                  thumbnailRpc: thumbnailRpc,
                  fullSizeRpc: fullSizeRpc,
                  textColor: textColor,
                  onTap: t is UploadedTile
                      ? () => onOpenImage?.call(t.ref)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MosaicTile extends StatelessWidget {
  const _MosaicTile({
    required this.tile,
    required this.size,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.textColor,
    required this.onTap,
  });

  final AlbumTile tile;
  final double size;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;
  final Color textColor;

  /// null → тап отключён (грузящаяся плитка).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = tile;
    if (t is UploadingTile) {
      // Грузящаяся плитка: локальные байты под блюром + прогресс. Тап
      // отключён (mxc ещё нет, галерею открывать нечем).
      final dpr = MediaQuery.of(context).devicePixelRatio;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: glassBlur(8),
              child: Image.memory(
                t.bytes,
                fit: BoxFit.cover,
                cacheWidth: (size * dpr).round(),
                errorBuilder: (ctx, _, _) =>
                    Container(color: textColor.withValues(alpha: 0.06)),
              ),
            ),
            Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final ref = (t as UploadedTile).ref;
    final image = MxcImageProvider(
      mxcUrl: ref.thumbnailMxcUrl ?? ref.mxcUrl,
      thumbnailRpc: thumbnailRpc,
      fullSizeRpc: fullSizeRpc,
    );
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: textColor.withValues(alpha: 0.06),
              alignment: Alignment.center,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            );
          },
          errorBuilder: (ctx, _, _) => Container(
            color: textColor.withValues(alpha: 0.06),
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: textColor.withValues(alpha: 0.7),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// **Оптимистичный альбом**: одиночное грузящееся фото (не альбом,
/// `attachment` ещё null) — локальные байты под блюром + прогресс. Тап
/// отключён (mxc ещё нет). Расблюр — когда controller подменит на реальное
/// вложение (bubble пере-соберётся с `AttachmentBubble`).
class UploadingImagePreview extends StatelessWidget {
  const UploadingImagePreview({
    super.key,
    required this.bytes,
    required this.textColor,
  });

  final Uint8List bytes;
  final Color textColor;

  static const double _maxW = 260;
  static const double _maxH = 320;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxW, maxHeight: _maxH),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: glassBlur(8),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    cacheWidth: (_maxW * dpr).round(),
                    errorBuilder: (ctx, _, _) =>
                        Container(color: textColor.withValues(alpha: 0.06)),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.attachment,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.textColor,
    this.onOpenImage,
  });

  final AttachmentRef attachment;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;
  final Color textColor;
  final void Function(AttachmentRef tapped)? onOpenImage;

  /// Дефолтный inline-размер превью — картинка не должна занимать всю
  /// ширину чата (особенно на web/desktop, где колонка широкая). Реальный
  /// размер вычисляется из aspect с этими потолками, но не шире доступной
  /// ширины bubble (LayoutBuilder). Full-size — по тапу в галерее.
  static const double _maxW = 260;
  static const double _maxH = 320;

  @override
  Widget build(BuildContext context) {
    // Aspect ratio из server-probed dimensions (PNG/JPEG/WebP — есть;
    // HEIC/HEIF/corrupt — null → 4:3 fallback).
    final aspect =
        (attachment.width != null &&
            attachment.height != null &&
            attachment.height! > 0)
        ? attachment.width! / attachment.height!
        : 4 / 3;

    final image = MxcImageProvider(
      mxcUrl: attachment.thumbnailMxcUrl!,
      thumbnailRpc: thumbnailRpc,
      fullSizeRpc: fullSizeRpc,
    );

    // Потолок 260×320, но НЕ шире bubble: ConstrainedBox уважает входящий
    // maxWidth (тесный из двух побеждает), AspectRatio вписывает картинку.
    // БЕЗ LayoutBuilder намеренно — LayoutBuilder внутри ListView.builder
    // кэширует размер на первом (порой вырожденном) layout-е нового item-а,
    // и картинка не прорисовывается до принудительного релейаута (resize
    // окна). Статический ConstrainedBox+AspectRatio детерминирован.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _open(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _maxW,
              maxHeight: _maxH,
            ),
            child: AspectRatio(
              aspectRatio: aspect,
              child: Image(
                image: image,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: textColor.withValues(alpha: 0.06),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
                errorBuilder: (ctx, _, _) => Container(
                  color: textColor.withValues(alpha: 0.06),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: textColor.withValues(alpha: 0.7),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    // Есть host-колбэк → открываем галерею всех картинок чата с листанием.
    final cb = onOpenImage;
    if (cb != null) {
      cb(attachment);
      return;
    }
    // Fallback: одиночный полноэкранный просмотр (host не подключил галерею).
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenViewer(
          attachment: attachment,
          thumbnailRpc: thumbnailRpc,
          fullSizeRpc: fullSizeRpc,
        ),
      ),
    );
  }
}

class _FullscreenViewer extends StatelessWidget {
  const _FullscreenViewer({
    required this.attachment,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
  });

  final AttachmentRef attachment;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  @override
  Widget build(BuildContext context) {
    // Escape закрывает и одиночный просмотр тоже. Focus/onKeyEvent хватает:
    // текстовых полей на экране нет, конкурировать за клавишу некому
    // (в отличие от композера с его EditableText). Листания здесь нет —
    // вложение ровно одно, соседей host не передал.
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).maybePop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          // Имя файла у картинок не показываем (решение пользователя) — оно
          // остаётся только в Matrix-событии. AppBar без заголовка.
        ),
        body: PhotoView(
          imageProvider: MxcImageProvider(
            mxcUrl: attachment.mxcUrl,
            thumbnailRpc: thumbnailRpc,
            fullSizeRpc: fullSizeRpc,
            fullSize: true, // tap-fullscreen → /download (full bytes).
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (_, _) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.attachment,
    required this.leading,
    required this.textColor,
  });

  final AttachmentRef attachment;
  final IconData leading;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(leading, size: 28, color: textColor.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.originalFilename.isNotEmpty
                      ? attachment.originalFilename
                      : l.attachUnnamedFallback,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
                Text(
                  _formatSize(attachment.sizeBytes),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Human-readable size: 102400 → "100 KB"; 5242880 → "5.0 MB".
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
