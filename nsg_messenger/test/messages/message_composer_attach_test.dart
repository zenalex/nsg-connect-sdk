import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake image_picker: возвращает заданный набор картинок для
/// `pickMultiImage` (мультивыбор из галереи).
class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  _FakeImagePickerPlatform(this.multi);
  final List<XFile> multi;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => multi;
}

/// TASK19 Chunk 3: composer attach button widget tests.
/// Picker integration через image_picker (платформенный) — за scope
/// unit-тестов; cover только UI surface (button visibility, spinner
/// state, callback wiring).
void main() {
  Widget pumpComposer({
    required Future<void> Function(String) onSend,
    Future<void> Function(PickedAttachment)? onSendAttachment,
    void Function(
      List<PickedAttachment>, {
      String caption,
      List<int>? mentions,
    })?
    onSendAlbum,
    bool enabled = true,
  }) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        onSend: (b, {mentionedMessengerUserIds, albumId}) => onSend(b),
        enabled: enabled,
        onSendAttachment: onSendAttachment == null
            ? null
            : (p, {albumId}) => onSendAttachment(p),
        onSendAlbum: onSendAlbum,
      ),
    ),
  );

  testWidgets('attach button скрыт когда onSendAttachment == null', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(onSend: (_) async {}));
    expect(find.byIcon(Icons.attach_file), findsNothing);
  });

  testWidgets('attach button виден когда onSendAttachment != null', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpComposer(onSend: (_) async {}, onSendAttachment: (_) async {}),
    );
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });

  testWidgets('attach button disabled когда enabled=false', (tester) async {
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_) async {},
        onSendAttachment: (_) async {},
        enabled: false,
      ),
    );
    final btn = find.ancestor(
      of: find.byIcon(Icons.attach_file),
      matching: find.byType(IconButton),
    );
    expect(btn, findsOneWidget);
    final iconBtn = tester.widget<IconButton>(btn);
    expect(iconBtn.onPressed, isNull, reason: 'disabled when not enabled');
  });

  // ─────────── Оптимистичный альбом: мультипик + не-заморозка ───────────
  group('оптимистичный альбом', () {
    XFile file(String name) => XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      path: name,
      name: name,
      mimeType: 'image/jpeg',
    );

    testWidgets('мультипик добавляет несколько миниатюр в черновик', (
      tester,
    ) async {
      // Desktop → bottom-sheet без камеры: «Изображение» + «Файл»
      // (issue #54 п.2). Сбрасываем override в конце тела теста.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      ImagePickerPlatform.instance = _FakeImagePickerPlatform([
        file('a.jpg'),
        file('b.jpg'),
        file('c.jpg'),
      ]);
      await tester.pumpWidget(
        pumpComposer(
          onSend: (_) async {},
          onSendAttachment: (_) async {},
          onSendAlbum: (_, {caption = '', mentions}) {},
        ),
      );
      await tester.tap(find.byIcon(Icons.attach_file));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library_outlined));
      await tester.pumpAndSettle();
      // 3 миниатюры → 3 Image.memory в ленте черновика.
      final memImages = tester
          .widgetList<Image>(find.byType(Image))
          .where((i) => i.image is MemoryImage)
          .toList();
      expect(memImages.length, 3);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      '_submit зовёт onSendAlbum и НЕ морозит TextField (поле активно)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        List<PickedAttachment>? sentImages;
        String? sentCaption;
        ImagePickerPlatform.instance = _FakeImagePickerPlatform([
          file('a.jpg'),
          file('b.jpg'),
        ]);
        await tester.pumpWidget(
          pumpComposer(
            onSend: (_) async {},
            onSendAttachment: (_) async {},
            onSendAlbum: (imgs, {caption = '', mentions}) {
              sentImages = imgs;
              sentCaption = caption;
            },
          ),
        );
        // Набираем подпись + прикрепляем 2 картинки.
        await tester.enterText(find.byType(TextField), 'подпись');
        await tester.tap(find.byIcon(Icons.attach_file));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.photo_library_outlined));
        await tester.pumpAndSettle();

        // Отправка (кнопка send).
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // onSendAlbum получил обе картинки + подпись.
        expect(sentImages, isNotNull);
        expect(sentImages!.length, 2);
        expect(sentCaption, 'подпись');

        // Поле НЕ заморожено (нет _uploading=true): TextField enabled.
        final tf = tester.widget<TextField>(find.byType(TextField));
        expect(tf.enabled, isTrue, reason: 'альбомный путь не морозит поле');
        // Черновик очищен (миниатюр больше нет).
        final memImages = tester
            .widgetList<Image>(find.byType(Image))
            .where((i) => i.image is MemoryImage)
            .toList();
        expect(memImages, isEmpty);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });
}
