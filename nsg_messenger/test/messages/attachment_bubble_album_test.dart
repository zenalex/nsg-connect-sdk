import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_bubble.dart';
import 'package:nsg_messenger/src/messages/attachments/mxc_image_provider.dart';

import '../test_helpers.dart';

/// **Оптимистичный альбом**: [AlbumMosaic] со смешанными [AlbumTile] —
/// грузящаяся плитка ([UploadingTile]) рендерится `Image.memory` + блюр +
/// прогресс; загруженная ([UploadedTile]) — через [MxcImageProvider].
void main() {
  // Минимальное валидное PNG (1×1, прозрачный) — чтобы Image.memory не
  // падал на decode в widget-тесте.
  final pngBytes = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, //
    0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00, //
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
    0x42, 0x60, 0x82, //
  ]);

  Future<AttachmentBytes> thumbRpc({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => AttachmentBytes(
    bytes: ByteData.sublistView(pngBytes),
    contentType: 'image/png',
  );

  Future<AttachmentBytes> fullRpc({required String mxcUrl}) async =>
      AttachmentBytes(
        bytes: ByteData.sublistView(pngBytes),
        contentType: 'image/png',
      );

  AttachmentRef ref() => AttachmentRef(
    mxcUrl: 'mxc://s/loaded',
    mimeType: 'image/png',
    sizeBytes: pngBytes.length,
    originalFilename: 'loaded.png',
    thumbnailMxcUrl: 'mxc://s/loaded',
  );

  Widget wrap(Widget child) => wrapL10n(child);

  testWidgets('мозаика со смешанными плитками: Image.memory+прогресс для '
      'UploadingTile, MxcImageProvider для UploadedTile', (tester) async {
    await tester.pumpWidget(
      wrap(
        AlbumMosaic(
          tiles: [UploadedTile(ref()), UploadingTile(pngBytes)],
          thumbnailRpc: thumbRpc,
          fullSizeRpc: fullRpc,
          textColor: Colors.black,
        ),
      ),
    );
    await tester.pump();

    // Грузящаяся плитка: есть прогресс-индикатор (у загруженной плитки
    // тоже может крутиться loadingBuilder-спиннер, пока mxc резолвится —
    // поэтому >=1).
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Есть Image.memory для грузящейся плитки. `cacheWidth` оборачивает
    // MemoryImage в ResizeImage — считаем оба варианта.
    bool isMemoryBacked(ImageProvider p) =>
        p is MemoryImage ||
        (p is ResizeImage && p.imageProvider is MemoryImage);
    final memoryImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((img) => isMemoryBacked(img.image))
        .toList();
    expect(memoryImages.length, 1, reason: 'один UploadingTile → MemoryImage');

    // Есть блюр (ImageFiltered) на грузящейся плитке.
    expect(find.byType(ImageFiltered), findsOneWidget);

    // Загруженная плитка использует MxcImageProvider.
    final mxcImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((img) => img.image is MxcImageProvider)
        .toList();
    expect(mxcImages.length, 1, reason: 'один UploadedTile → MxcImageProvider');
  });

  testWidgets('тап по UploadingTile не открывает галерею (onTap отключён)', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      wrap(
        AlbumMosaic(
          tiles: [UploadingTile(pngBytes), UploadingTile(pngBytes)],
          thumbnailRpc: thumbRpc,
          fullSizeRpc: fullRpc,
          textColor: Colors.black,
          onOpenImage: (_) => opened = true,
        ),
      ),
    );
    await tester.pump();
    // Тап по первой плитке — грузящаяся, тап не проходит (нет GestureDetector,
    // hit-test промахивается — warnIfMissed:false подавляет предупреждение).
    await tester.tap(find.byType(ImageFiltered).first, warnIfMissed: false);
    await tester.pump();
    expect(opened, isFalse);
  });

  testWidgets('тап по UploadedTile открывает галерею', (tester) async {
    AttachmentRef? tapped;
    await tester.pumpWidget(
      wrap(
        AlbumMosaic(
          tiles: [UploadedTile(ref()), UploadedTile(ref())],
          thumbnailRpc: thumbRpc,
          fullSizeRpc: fullRpc,
          textColor: Colors.black,
          onOpenImage: (a) => tapped = a,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(tapped, isNotNull);
  });
}
