import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_bubble.dart';

/// Minimal valid 1×1 transparent PNG (67 bytes). Используется в noop
/// thumbnail RPC чтобы Image.memory не fail-ил decode-ом. Hex-decoded
/// header signature + IHDR + IDAT + IEND chunks с valid CRC.
final Uint8List _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT
  0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,
  0x0D, 0x0A, 0x2D, 0xB4,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
  0xAE, 0x42, 0x60, 0x82,
]);

/// Widget tests для [AttachmentBubble] — проверяем switch по mimeType
/// без реального load-а bytes (только structural assertions). Реальный
/// rendering image через MxcImageProvider покрыт smoke step 15 live.
void main() {
  AttachmentRef ref({
    String mime = 'image/jpeg',
    String? thumbnailMxcUrl,
    int? width,
    int? height,
    int size = 102400,
    String filename = 'photo.jpg',
  }) => AttachmentRef(
    mxcUrl: 'mxc://localhost/abc',
    mimeType: mime,
    sizeBytes: size,
    originalFilename: filename,
    width: width,
    height: height,
    thumbnailMxcUrl: thumbnailMxcUrl ?? 'mxc://localhost/abc',
  );

  Future<AttachmentBytes> noopThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => AttachmentBytes(
    bytes: ByteData.sublistView(_tinyPng),
    contentType: 'image/png',
  );

  Future<AttachmentBytes> noopFull({required String mxcUrl}) async =>
      AttachmentBytes(
        bytes: ByteData.sublistView(_tinyPng),
        contentType: 'image/png',
      );

  Widget pumpBubble(AttachmentRef r) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: AttachmentBubble(
        attachment: r,
        thumbnailRpc: noopThumb,
        fullSizeRpc: noopFull,
        textColor: Colors.black,
      ),
    ),
  );

  testWidgets('image/* + thumbnailMxcUrl != null → bounded inline preview', (
    tester,
  ) async {
    await tester.pumpWidget(pumpBubble(ref(width: 1920, height: 1080)));
    // Single-frame pump БЕЗ pumpAndSettle — Image widget kicks off
    // async decode; нам важен только layout-размер, не bytes-decode.
    // Decode-exception swallow через `takeException`.
    // ignore: unused_local_variable
    final _ = tester.takeException();
    // ClipRRect оборачивает SizedBox с вычисленным inline-размером.
    final size = tester.getSize(find.byType(ClipRRect).first);
    // Aspect сохранён (1920/1080 ≈ 1.777)…
    expect(size.width / size.height, closeTo(1920 / 1080, 0.02));
    // …и картинка ограничена потолками, а не на всю ширину чата (800px).
    expect(size.width, lessThanOrEqualTo(260.5));
    expect(size.height, lessThanOrEqualTo(320.5));
  });

  testWidgets('image/* без width/height → fallback aspect 4/3', (tester) async {
    await tester.pumpWidget(pumpBubble(ref(width: null, height: null)));
    // ignore: unused_local_variable
    final _ = tester.takeException();
    final size = tester.getSize(find.byType(ClipRRect).first);
    expect(size.width / size.height, closeTo(4 / 3, 0.02));
    expect(size.width, lessThanOrEqualTo(260.5));
  });

  testWidgets(
    'image/* + thumbnailMxcUrl=null → file row fallback (broken_image icon)',
    (tester) async {
      final r = AttachmentRef(
        mxcUrl: 'mxc://localhost/x',
        mimeType: 'image/heic',
        sizeBytes: 5000,
        originalFilename: 'photo.heic',
        thumbnailMxcUrl: null, // HEIC — server-side нет thumbnail
      );
      await tester.pumpWidget(pumpBubble(r));
      // HEIC → image_outlined (не broken_image — валидное фото без
      // Dart-side preview support; sign-off review #2 fix).
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.text('photo.heic'), findsOneWidget);
      expect(find.byType(AspectRatio), findsNothing);
    },
  );

  testWidgets('video/mp4 → file row с play icon (preview Phase2)', (
    tester,
  ) async {
    final r = ref(
      mime: 'video/mp4',
      filename: 'clip.mp4',
      thumbnailMxcUrl: null,
    );
    await tester.pumpWidget(pumpBubble(r));
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    expect(find.text('clip.mp4'), findsOneWidget);
  });

  testWidgets('application/pdf → file row с insert_drive_file icon', (
    tester,
  ) async {
    final r = ref(
      mime: 'application/pdf',
      filename: 'doc.pdf',
      size: 5_242_880, // 5MB
      thumbnailMxcUrl: null,
    );
    await tester.pumpWidget(pumpBubble(r));
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    expect(find.text('doc.pdf'), findsOneWidget);
    expect(find.text('5.0 MB'), findsOneWidget);
  });

  testWidgets('size formatting: bytes / KB / MB', (tester) async {
    // 100 B
    await tester.pumpWidget(
      pumpBubble(
        ref(mime: 'application/pdf', size: 100, thumbnailMxcUrl: null),
      ),
    );
    expect(find.text('100 B'), findsOneWidget);
    // 50 KB
    await tester.pumpWidget(
      pumpBubble(
        ref(mime: 'application/pdf', size: 51200, thumbnailMxcUrl: null),
      ),
    );
    expect(find.text('50 KB'), findsOneWidget);
    // 10.5 MB
    await tester.pumpWidget(
      pumpBubble(
        ref(mime: 'application/pdf', size: 11010048, thumbnailMxcUrl: null),
      ),
    );
    expect(find.text('10.5 MB'), findsOneWidget);
  });

  testWidgets('empty filename → fallback i18n "Unnamed file" / "Без имени"', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpBubble(
        ref(mime: 'application/pdf', filename: '', thumbnailMxcUrl: null),
      ),
    );
    // Default locale en → "Unnamed file"
    expect(find.text('Unnamed file'), findsOneWidget);
  });
}
