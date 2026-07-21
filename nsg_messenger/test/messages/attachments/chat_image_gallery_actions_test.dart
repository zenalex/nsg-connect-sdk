import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/chat_image_gallery.dart';
import 'package:nsg_messenger/src/messages/attachments/image_actions.dart';

/// Widget-тесты оверлея [ChatImageGallery]: платформо-адаптивная кнопка
/// Поделиться (mobile) / Скопировать (desktop) + диспетчеризация действия.
/// ImageActions инъектируется фейком (без реальных плагинов/сети).
final Uint8List _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, //
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, //
  0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, //
  0x0D, 0x0A, 0x2D, 0xB4, //
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, //
  0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  Future<AttachmentBytes> noopThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async =>
      AttachmentBytes(bytes: ByteData.sublistView(_tinyPng), contentType: 'image/png');

  Future<AttachmentBytes> noopFull({required String mxcUrl}) async =>
      AttachmentBytes(bytes: ByteData.sublistView(_tinyPng), contentType: 'image/png');

  final images = <AttachmentRef>[
    AttachmentRef(
      mxcUrl: 'mxc://server/1',
      mimeType: 'image/png',
      sizeBytes: 10,
      originalFilename: 'a.png',
      thumbnailMxcUrl: 'mxc://server/1',
    ),
  ];

  Widget pumpGallery(ImageActions actions) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: ChatImageGallery(
      images: images,
      initialIndex: 0,
      thumbnailRpc: noopThumb,
      fullSizeRpc: noopFull,
      actions: actions,
    ),
  );

  testWidgets('desktop → кнопка «Скопировать», тап кладёт bitmap + snackbar', (
    tester,
  ) async {
    final copied = <Uint8List>[];
    final actions = ImageActions(
      loadBytes: (_) async => Uint8List.fromList([1, 2, 3]),
      copyImageBytes: (b) async => copied.add(b),
      platformOverride: TargetPlatform.windows,
      isWebOverride: false,
    );

    await tester.pumpWidget(pumpGallery(actions));
    tester.takeException(); // async image decode — не важен здесь

    expect(find.byIcon(Icons.content_copy), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsNothing);

    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pump(); // старт async
    await tester.pump(const Duration(seconds: 1)); // завершить

    expect(copied.single, [1, 2, 3]);
    expect(find.text('Image copied to clipboard'), findsOneWidget);
  });

  testWidgets('mobile → кнопка «Поделиться», тап шарит, copy-snackbar нет', (
    tester,
  ) async {
    final shared = <int>[];
    final actions = ImageActions(
      loadBytes: (_) async => Uint8List.fromList([5]),
      shareFiles: (files) async => shared.add(files.length),
      writeTempFile: (name, _) async => '/tmp/$name',
      copyImageBytes: (_) async => throw StateError('copy не должен вызваться'),
      platformOverride: TargetPlatform.iOS,
      isWebOverride: false,
    );

    await tester.pumpWidget(pumpGallery(actions));
    tester.takeException();

    expect(find.byIcon(Icons.ios_share), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsNothing);

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(shared.single, 1);
    // Share показывает системный лист — свой snackbar не рисуем.
    expect(find.text('Image copied to clipboard'), findsNothing);
  });

  testWidgets('ошибка загрузки → snackbar «не удалось»', (tester) async {
    final actions = ImageActions(
      loadBytes: (_) async => throw Exception('network down'),
      copyImageBytes: (_) async {},
      platformOverride: TargetPlatform.windows,
      isWebOverride: false,
    );

    await tester.pumpWidget(pumpGallery(actions));
    tester.takeException();

    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Couldn\'t copy the image'), findsOneWidget);
  });
}
