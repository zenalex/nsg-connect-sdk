import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../../cache/messenger_cache_store.dart';
import '../../messenger_runtime.dart';

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
/// **Cache**: два уровня.
///   * **memory** — Flutter `imageCache` (LRU, default ~100MB); stable cache
///     key через `mxcUrl + width + height + fullSize`.
///   * **disk (TASK47 iter2)** — read-through в [MessengerCacheStore]
///     (`cached_attachments`): перед сетью читаем диск (оффлайн-показ +
///     экономия трафика), после сети — кладём байты + LRU-обрезка. Контент по
///     `mxcUrl` в Matrix иммутабелен, поэтому кэш-хит отдаём БЕЗ похода в сеть
///     (см. [_loadAsync]). Диск может быть `null` (web / кэш выключен) — тогда
///     только сеть, без падений.
///
/// **Fallback миниатюры → полный файл**: если thumbnail-RPC падает (Synapse
/// `/thumbnail` недоступен / не смог отдать превью), провайдер тянет
/// полноразмерный `download` — превью всё равно рисуется, а не выпадает в
/// `broken_image`. Fallback-байты НЕ кладутся в thumbnail-кэш на диск (см.
/// [_loadAsync]). Happy-path (thumbnail отдался) full-RPC не дёргает.
///
/// **TASK19 Chunk 3 sign-off review #1**: solution chosen over web-
/// route approach.
class MxcImageProvider extends ImageProvider<MxcImageKey> {
  /// Production constructor — берёт thumbnail RPC из runtime.
  /// `fullSize=true` switches к `downloadAttachment` (full bytes
  /// для tap-fullscreen). Default false — chat bubble preview.
  ///
  /// [cache] / [cacheLimitBytes] — visible-for-testing инъекция дискового
  /// кэша и его лимита. В production НЕ передаются: провайдер лениво берёт
  /// `MessengerRuntime.instance.offlineCache` и `.attachmentCacheLimitBytes`
  /// (все прод-вызовы — внутри SDK, где нужен именно runtime-кэш). Тесты
  /// инжектят фейки, чтобы не зависеть от singleton-а.
  MxcImageProvider({
    required this.mxcUrl,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    this.width,
    this.height,
    this.fullSize = false,
    MessengerCacheStore? cache,
    int? cacheLimitBytes,
  }) : _cacheOverride = cache,
       _cacheLimitOverride = cacheLimitBytes;

  final String mxcUrl;
  final int? width;
  final int? height;
  final bool fullSize;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  /// Инъекция дискового кэша (тесты). `null` → берём из runtime.
  final MessengerCacheStore? _cacheOverride;

  /// Инъекция лимита обрезки (тесты). `null` → берём из runtime.
  final int? _cacheLimitOverride;

  /// Дисковый кэш вложений: инъекция (тест) → runtime → `null`.
  MessengerCacheStore? get _cache =>
      _cacheOverride ?? MessengerRuntime.instance.offlineCache;

  /// Лимит LRU-обрезки: инъекция (тест) → runtime.
  int get _cacheLimit =>
      _cacheLimitOverride ?? MessengerRuntime.instance.attachmentCacheLimitBytes;

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
      final store = _cache;
      final kind = key.fullSize
          ? MessengerCacheStore.attachmentKindFull
          : MessengerCacheStore.attachmentKindThumbnail;

      // 1. **Read-through диск** (TASK47 iter2): контент по mxcUrl иммутабелен,
      // поэтому кэш-хит отдаём БЕЗ похода в сеть — это и есть оффлайн-показ +
      // экономия трафика. Ошибку чтения ИЛИ декода кэша глушим (best-effort) и
      // идём в сеть.
      if (store != null) {
        try {
          final cached = await store.getAttachment(key.mxcUrl, kind);
          if (cached != null && cached.isNotEmpty) {
            // **Await декод ВНУТРИ try** (не `return decode(...)`): если
            // кэш-запись битая/недекодируемая (усечённая запись, повреждение
            // диска), ошибка декода должна ловиться здесь, а не «утекать» из
            // completer-а вечным broken_image. На фейле проваливаемся в сеть —
            // network-ветка ниже перезапишет запись через putAttachment(REPLACE)
            // (self-heal, как getAttachment делает для пустого BLOB).
            final buffer = await ui.ImmutableBuffer.fromUint8List(cached);
            final codec = await decode(buffer);
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: cached.length,
                expectedTotalBytes: cached.length,
              ),
            );
            return codec;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[MxcImageProvider] disk cache miss/corrupt (${key.mxcUrl}): $e',
            );
          }
        }
      }

      // 2. **Сеть** (кэш-мисс / кэш выключен).
      //
      // **Fallback миниатюры → полный файл**: если thumbnail-RPC падает
      // (Synapse `/thumbnail` недоступен / не смог сгенерировать превью для
      // конкретного файла), тянем полноразмерный `download` — превью всё равно
      // отрисуется, а не выродится в `broken_image` (иначе «отвалившиеся
      // миниатюры» у ВСЕХ картинок при проблеме на thumbnail-endpoint-е).
      // Full-путь (`fullSize`) fallback-а не имеет — он и есть последний
      // источник байтов.
      final AttachmentBytes payload;
      var persistToDisk = true;
      if (key.fullSize) {
        payload = await fullSizeRpc(mxcUrl: key.mxcUrl);
      } else {
        AttachmentBytes? thumb;
        try {
          thumb = await thumbnailRpc(
            mxcUrl: key.mxcUrl,
            width: key.width,
            height: key.height,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[MxcImageProvider] thumbnail RPC failed for ${key.mxcUrl} — '
              'fallback на полный download: $e',
            );
          }
        }
        if (thumb != null) {
          payload = thumb;
        } else {
          // Fallback: полный файл вместо миниатюры. НЕ персистим его в
          // thumbnail-кэш на диск — иначе после восстановления Synapse
          // read-through вечно отдавал бы full-байты как превью (кэш
          // иммутабелен). В памяти (imageCache) кадр всё равно закэшируется
          // по ключу до конца сессии.
          payload = await fullSizeRpc(mxcUrl: key.mxcUrl);
          persistToDisk = false;
        }
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

      // 3. **Наполнить диск + LRU-обрезка** (best-effort, не блокируем показ).
      // Копируем байты — view над буфером payload не должен «уехать» из-под
      // асинхронной записи. Диск null → просто пропускаем. `persistToDisk`
      // false — когда миниатюра пришла fallback-ом (полный файл): такой
      // контент в thumbnail-кэш класть нельзя (см. блок сети выше).
      if (store != null && bytes.isNotEmpty && persistToDisk) {
        final copy = Uint8List.fromList(bytes);
        final limit = _cacheLimit;
        unawaited(
          store
              .putAttachment(mxcUrl: key.mxcUrl, kind: kind, bytes: copy)
              .then((_) => store.evictAttachmentsToLimit(limit))
              .catchError((Object _) => 0),
        );
      }

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
