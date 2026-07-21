import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// **Оптимистичный альбом**: [pickImagesAttachment] возвращает несколько
/// [PickedAttachment] через `pickMultiImage` (порядок сохраняется), пустой
/// список на cancel. Платформа замокана через [ImagePickerPlatform].
class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  _FakeImagePickerPlatform(this.multi);

  final List<XFile> multi;
  int? lastLimit;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    lastLimit = options.limit;
    return multi;
  }
}

void main() {
  // path задаём именем файла — на io-платформе XFile.name = basename(path)
  // (конструкторный `name` там игнорируется).
  XFile file(String name) => XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    path: name,
    name: name,
    mimeType: 'image/jpeg',
  );

  test('pickImagesAttachment возвращает все выбранные в порядке', () async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform([
      file('a.jpg'),
      file('b.jpg'),
      file('c.jpg'),
    ]);
    final picked = await pickImagesAttachment(ImagePicker());
    expect(picked.length, 3);
    expect(picked.map((p) => p.originalFilename), ['a.jpg', 'b.jpg', 'c.jpg']);
    expect(picked.every((p) => p.mimeType == 'image/jpeg'), isTrue);
    expect(picked.first.bytes, isNotEmpty);
  });

  test('pickImagesAttachment на cancel (пусто) → пустой список', () async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(const []);
    final picked = await pickImagesAttachment(ImagePicker());
    expect(picked, isEmpty);
  });

  test('limit пробрасывается в pickMultiImage', () async {
    final fake = _FakeImagePickerPlatform([file('a.jpg')]);
    ImagePickerPlatform.instance = fake;
    await pickImagesAttachment(ImagePicker(), limit: 7);
    expect(fake.lastLimit, 7);
  });
}
