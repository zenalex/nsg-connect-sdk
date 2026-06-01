import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

/// RPC-функция для thumbnail download (signature совпадает с
/// `client.messenger.downloadAttachmentThumbnail`). Inject-уется
/// в [MxcImageProvider] вместо прямой зависимости от `Client` —
/// тестируется без spinning up Serverpod.
typedef DownloadAttachmentThumbnailRpc =
    Future<AttachmentBytes> Function({
      required String mxcUrl,
      int? width,
      int? height,
    });

/// Аналог для full-size download (`m.image` tap → fullscreen).
typedef DownloadAttachmentRpc =
    Future<AttachmentBytes> Function({required String mxcUrl});

/// Custom [ImageProvider] для Matrix `mxc://` URLs через server-proxy
/// (`client.messenger.downloadAttachment` / `downloadAttachmentThumbnail`).
///
/// **Why custom, не CachedNetworkImage**:
/// - server-proxy via Serverpod RPC использует POST body (auth token
///   в headers); standard NetworkImage / CachedNetworkImage ожидают
///   GET URL — для них нужен был бы дополнительный HTTP route.
/// - cleaner separation: SDK уже имеет auth flow через Serverpod
///   client, дополнительный web route был бы duplicate surface.
///
/// **Cache**: integrated в Flutter `imageCache` (LRU, default ~100MB).
/// Stable cache key через `mxcUrl + width + height + fullSize` — same
/// url при разных preview sizes — разные cache entries.
///
/// **TASK19 Chunk 3 sign-off review #1**: solution chosen over web-
/// route approach.
class MxcImageProvider extends ImageProvider<MxcImageKey> {
  /// Production constructor — берёт thumbnail RPC из runtime.
  /// `fullSize=true` switches к `downloadAttachment` (full bytes
  /// для tap-fullscreen). Default false — chat bubble preview.
  MxcImageProvider({
    required this.mxcUrl,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    this.width,
    this.height,
    this.fullSize = false,
  });

  final String mxcUrl;
  final int? width;
  final int? height;
  final bool fullSize;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  @override
  Future<MxcImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MxcImageKey>(
      MxcImageKey(
        mxcUrl: mxcUrl,
        width: width,
        height: height,
        fullSize: fullSize,
      ),
    );
  }

  @override
  ImageStreamCompleter loadImage(MxcImageKey key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, chunkEvents),
      scale: 1.0,
      chunkEvents: chunkEvents.stream,
      debugLabel:
          'MxcImage(${key.mxcUrl}'
          '${key.fullSize ? "" : ", thumb"}'
          '${key.width != null ? ", ${key.width}×${key.height}" : ""})',
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('mxcUrl', key.mxcUrl),
        DiagnosticsProperty<bool>('fullSize', key.fullSize),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    MxcImageKey key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      final AttachmentBytes payload;
      if (key.fullSize) {
        payload = await fullSizeRpc(mxcUrl: key.mxcUrl);
      } else {
        payload = await thumbnailRpc(
          mxcUrl: key.mxcUrl,
          width: key.width,
          height: key.height,
        );
      }
      final bytes = Uint8List.view(
        payload.bytes.buffer,
        payload.bytes.offsetInBytes,
        payload.bytes.lengthInBytes,
      );
      // Дать subscribers знать total — nice-to-have для progress UI
      // (в нашем кейсе imageCache не использует, но Flutter-protocol
      // require-ит закрыть chunkEvents).
      chunkEvents.add(
        ImageChunkEvent(
          cumulativeBytesLoaded: bytes.length,
          expectedTotalBytes: bytes.length,
        ),
      );
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MxcImageProvider &&
        other.mxcUrl == mxcUrl &&
        other.width == width &&
        other.height == height &&
        other.fullSize == fullSize;
  }

  @override
  int get hashCode => Object.hash(mxcUrl, width, height, fullSize);
}

/// Cache key — stable identity для одинаковых mxc + size + mode.
@immutable
class MxcImageKey {
  const MxcImageKey({
    required this.mxcUrl,
    required this.width,
    required this.height,
    required this.fullSize,
  });

  final String mxcUrl;
  final int? width;
  final int? height;
  final bool fullSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MxcImageKey &&
        other.mxcUrl == mxcUrl &&
        other.width == width &&
        other.height == height &&
        other.fullSize == fullSize;
  }

  @override
  int get hashCode => Object.hash(mxcUrl, width, height, fullSize);
}
