import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messages/attachments/mxc_image_provider.dart';

/// **TASK47 iter2**: read-through дискового кэша ВЛОЖЕНИЙ в [MxcImageProvider].
///
/// Покрывает:
///   * онлайн — сеть отдаёт байты, провайдер декодирует И наполняет диск;
///   * оффлайн — сетевой RPC бросает/висит, провайдер отдаёт кэш-хит с диска
///     БЕЗ похода в сеть (контент по mxcUrl иммутабелен);
///   * кэш `null` (выключен) — только сеть, без падений.
void main() {
  // Нужен для imageCache / ImageProvider.resolve / decode.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Валидный 1×1 PNG (RGB) — чтобы `ui.ImmutableBuffer`+decode отработали.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
  );

  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mxc_cache_test');
    // Сбрасываем memory-imageCache между тестами: иначе одинаковый key
    // отдаст закэшированный кадр в обход _loadAsync (и диск/сеть не тронутся).
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> openCache() async {
    final s = await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: 'test',
      userId: 1,
    );
    expect(s, isNotNull, reason: 'ffi-фабрика открывает кэш на desktop');
    return s!;
  }

  AttachmentBytes payload(Uint8List bytes) => AttachmentBytes(
    bytes: ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
    contentType: 'image/png',
  );

  // Резолвит ImageProvider до первого кадра или ошибки.
  Future<ui.Image> resolveImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (Object e, StackTrace? st) {
        if (!completer.isCompleted) completer.completeError(e);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  Future<Uint8List?> waitDiskAttachment(
    MessengerCacheStore cache,
    String mxcUrl,
    String kind,
  ) async {
    Uint8List? got;
    for (var i = 0; i < 100 && got == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      got = await cache.getAttachment(mxcUrl, kind);
    }
    return got;
  }

  Future<AttachmentBytes> throwingThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => throw Exception('offline');

  Future<AttachmentBytes> throwingFull({required String mxcUrl}) async =>
      throw Exception('offline');

  test('онлайн: сеть отдаёт байты + наполняет дисковый кэш', () async {
    final cache = await openCache();
    addTearDown(cache.close);

    final provider = MxcImageProvider(
      mxcUrl: 'mxc://online/thumb',
      thumbnailRpc: ({required String mxcUrl, int? width, int? height}) async =>
          payload(png),
      fullSizeRpc: ({required String mxcUrl}) async => payload(png),
      cache: cache,
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    final img = await resolveImage(provider);
    expect(img.width, 1);
    expect(img.height, 1);

    // putAttachment — unawaited; поллим до появления на диске.
    final disk = await waitDiskAttachment(
      cache,
      'mxc://online/thumb',
      MessengerCacheStore.attachmentKindThumbnail,
    );
    expect(disk, isNotNull);
    expect(disk, equals(png));
  });

  test('оффлайн: RPC бросает → кэш-хит с диска (сеть не нужна)', () async {
    final cache = await openCache();
    addTearDown(cache.close);
    // Заранее кладём байты на диск (как будто скачали раньше, будучи онлайн).
    await cache.putAttachment(
      mxcUrl: 'mxc://offline/thumb',
      kind: MessengerCacheStore.attachmentKindThumbnail,
      bytes: png,
    );

    final provider = MxcImageProvider(
      mxcUrl: 'mxc://offline/thumb',
      thumbnailRpc: throwingThumb, // сеть недоступна
      fullSizeRpc: throwingFull,
      cache: cache,
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    // Должно отдать картинку из кэша, а НЕ упасть с 'offline'.
    final img = await resolveImage(provider);
    expect(img.width, 1);
  });

  test('оффлайн: зависший RPC → кэш-хит с диска БЕЗ ожидания сети', () async {
    final cache = await openCache();
    addTearDown(cache.close);
    await cache.putAttachment(
      mxcUrl: 'mxc://hang/thumb',
      kind: MessengerCacheStore.attachmentKindThumbnail,
      bytes: png,
    );

    // thumbnailRpc никогда не завершается — если бы провайдер ходил в сеть
    // до кэша, resolve завис бы. Кэш-хит-first спасает.
    final provider = MxcImageProvider(
      mxcUrl: 'mxc://hang/thumb',
      thumbnailRpc:
          ({required String mxcUrl, int? width, int? height}) =>
              Completer<AttachmentBytes>().future,
      fullSizeRpc: ({required String mxcUrl}) =>
          Completer<AttachmentBytes>().future,
      cache: cache,
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    final img = await resolveImage(provider).timeout(const Duration(seconds: 5));
    expect(img.width, 1);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('кэш null (выключен) → только сеть, без падений', () async {
    // Без cache-инъекции: _cacheOverride == null → провайдер спросит runtime,
    // а в SDK-тесте runtime не инициализирован → offlineCache == null.
    final provider = MxcImageProvider(
      mxcUrl: 'mxc://nodisk/thumb',
      thumbnailRpc: ({required String mxcUrl, int? width, int? height}) async =>
          payload(png),
      fullSizeRpc: ({required String mxcUrl}) async => payload(png),
      // cacheLimitBytes не важен: кэша нет, evict не зовётся.
      cacheLimitBytes: 10 * 1024 * 1024,
    );
    final img = await resolveImage(provider);
    expect(img.width, 1);
  });

  // ─────────────── fallback миниатюры → полный download (issue #24) ───────────
  //
  // Регресс: при недоступном Synapse `/thumbnail` миниатюры «отваливались»
  // (broken_image) у всех картинок сразу. Провайдер обязан упасть на полный
  // `download`, чтобы превью всё равно отрисовалось.

  test('thumbnail RPC падает → fallback на полный download (превью рисуется)', () async {
    final cache = await openCache();
    addTearDown(cache.close);

    final provider = MxcImageProvider(
      mxcUrl: 'mxc://broken-thumb/img',
      // Synapse thumbnail-endpoint недоступен.
      thumbnailRpc: throwingThumb,
      // Полный файл доступен — из него и рисуем превью.
      fullSizeRpc: ({required String mxcUrl}) async => payload(png),
      cache: cache,
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    final img = await resolveImage(provider);
    expect(img.width, 1, reason: 'превью отрисовано из full-download fallback');
  });

  test('fallback (полный файл) НЕ персистится в thumbnail-кэш на диск', () async {
    final cache = await openCache();
    addTearDown(cache.close);

    final provider = MxcImageProvider(
      mxcUrl: 'mxc://broken-thumb/nopersist',
      thumbnailRpc: throwingThumb,
      fullSizeRpc: ({required String mxcUrl}) async => payload(png),
      cache: cache,
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    await resolveImage(provider);
    // Ждём, что put НЕ произойдёт: поллер вернёт null по таймауту.
    final disk = await waitDiskAttachment(
      cache,
      'mxc://broken-thumb/nopersist',
      MessengerCacheStore.attachmentKindThumbnail,
    );
    expect(
      disk,
      isNull,
      reason: 'full-байты нельзя класть в thumbnail-кэш (иммутабелен) — '
          'иначе после восстановления Synapse превью навсегда осталось бы full',
    );
  });

  test('битая кэш-запись (не декодируется) → refetch из сети + self-heal', () async {
    final cache = await openCache();
    addTearDown(cache.close);

    // Кладём на диск НЕ-декодируемые байты (не PNG/JPEG) под thumbnail-ключ —
    // имитация усечённой записи / повреждения. getAttachment их вернёт
    // (не пустые), но decode упадёт.
    final garbage = Uint8List.fromList(List<int>.filled(64, 0x7f));
    await cache.putAttachment(
      mxcUrl: 'mxc://corrupt/thumb',
      kind: MessengerCacheStore.attachmentKindThumbnail,
      bytes: garbage,
    );

    final provider = MxcImageProvider(
      mxcUrl: 'mxc://corrupt/thumb',
      // Сеть здорова — отдаёт валидный PNG.
      thumbnailRpc: ({required String mxcUrl, int? width, int? height}) async =>
          payload(png),
      fullSizeRpc: ({required String mxcUrl}) async => payload(png),
      cache: cache,
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    // Должно отрисоваться (из сети), а не выпасть в error по битому кэш-хиту.
    final img = await resolveImage(provider);
    expect(img.width, 1, reason: 'битый кэш-хит НЕ должен ронять показ');

    // Self-heal: битая запись перезаписана валидными байтами из сети. Запись
    // уже НЕ пустая (там мусор), поэтому поллим именно до равенства png, а не
    // до «появления» (иначе прочитали бы мусор до того, как put(REPLACE) отработал).
    Uint8List? healed;
    for (var i = 0; i < 100; i++) {
      healed = await cache.getAttachment(
        'mxc://corrupt/thumb',
        MessengerCacheStore.attachmentKindThumbnail,
      );
      if (healed != null && healed.length == png.length) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(healed, equals(png), reason: 'putAttachment(REPLACE) перезаписал битьё');
  });

  test('happy-path: thumbnail отдался → full-RPC НЕ дёргается', () async {
    var fullCalled = false;
    final provider = MxcImageProvider(
      mxcUrl: 'mxc://ok/thumb',
      thumbnailRpc: ({required String mxcUrl, int? width, int? height}) async =>
          payload(png),
      fullSizeRpc: ({required String mxcUrl}) async {
        fullCalled = true;
        throw Exception('full не должен вызываться на happy-path');
      },
      cacheLimitBytes: 10 * 1024 * 1024,
    );

    final img = await resolveImage(provider);
    expect(img.width, 1);
    expect(fullCalled, isFalse, reason: 'миниатюра отдалась — fallback не нужен');
  });
}
