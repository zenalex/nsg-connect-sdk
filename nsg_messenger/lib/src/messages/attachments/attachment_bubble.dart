import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:photo_view/photo_view.dart';

import '../../i18n/generated/nsg_l10n.dart';
import 'audio_player_row.dart';
import 'mxc_image_provider.dart';

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
  });

  final AttachmentRef attachment;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  /// Цвет fallback-иконок и текста — bubble сам передаёт в зависимости
  /// от own/peer (theme primary vs surface).
  final Color textColor;

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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.attachment,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.textColor,
  });

  final AttachmentRef attachment;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    // Aspect ratio из server-probed dimensions (PNG/JPEG/WebP — есть;
    // HEIC/HEIF/corrupt — null → 4:3 fallback). UI использует для
    // pre-allocate placeholder без layout shift.
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _openFullscreen(context),
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
    );
  }

  void _openFullscreen(BuildContext context) {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          attachment.originalFilename,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: PhotoView(
        imageProvider: MxcImageProvider(
          mxcUrl: attachment.mxcUrl,
          thumbnailRpc: thumbnailRpc,
          fullSizeRpc: fullSizeRpc,
          fullSize: true, // tap-fullscreen → /download (full bytes).
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, _) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 64),
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
