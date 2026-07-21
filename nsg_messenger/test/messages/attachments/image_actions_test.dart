import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/attachments/image_actions.dart';
import 'package:share_plus/share_plus.dart';

/// Unit-тесты «скопировать/поделиться картинкой» (запрос постановщика):
///   * [imagePrimaryActionFor] — платформенный выбор share-vs-copy;
///   * [ImageActions.shareImage] — temp-файл (native) / fromData (web);
///   * [ImageActions.copyImage] — bitmap-в-буфер / файловая ссылка (Linux);
///   * [ImageActions.runPrimary] — диспетчеризация по платформе;
///   * [ImageActions.fromDownloader] — конверсия `AttachmentBytes` → байты.
///
/// Все платформенные эффекты инъектируются → без реальных плагинов.
void main() {
  AttachmentRef ref({
    String mime = 'image/jpeg',
    String filename = 'photo.jpg',
  }) => AttachmentRef(
    mxcUrl: 'mxc://server/abc',
    mimeType: mime,
    sizeBytes: 10,
    originalFilename: filename,
  );

  group('imagePrimaryActionFor', () {
    test('web → share (для любой ОС браузера)', () {
      for (final pf in TargetPlatform.values) {
        expect(
          imagePrimaryActionFor(pf, isWeb: true),
          ImagePrimaryAction.share,
          reason: '$pf web',
        );
      }
    });

    test('mobile → share', () {
      expect(
        imagePrimaryActionFor(TargetPlatform.iOS, isWeb: false),
        ImagePrimaryAction.share,
      );
      expect(
        imagePrimaryActionFor(TargetPlatform.android, isWeb: false),
        ImagePrimaryAction.share,
      );
      expect(
        imagePrimaryActionFor(TargetPlatform.fuchsia, isWeb: false),
        ImagePrimaryAction.share,
      );
    });

    test('desktop → copy', () {
      expect(
        imagePrimaryActionFor(TargetPlatform.windows, isWeb: false),
        ImagePrimaryAction.copy,
      );
      expect(
        imagePrimaryActionFor(TargetPlatform.macOS, isWeb: false),
        ImagePrimaryAction.copy,
      );
      expect(
        imagePrimaryActionFor(TargetPlatform.linux, isWeb: false),
        ImagePrimaryAction.copy,
      );
    });
  });

  group('shareImage', () {
    test('native — пишет temp-файл и шарит XFile(path)', () async {
      final shared = <List<XFile>>[];
      final tempWrites = <MapEntry<String, Uint8List>>[];
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([1, 2, 3]),
        shareFiles: (files) async => shared.add(files),
        writeTempFile: (name, bytes) async {
          tempWrites.add(MapEntry(name, bytes));
          return '/tmp/$name';
        },
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );

      await actions.shareImage(ref(filename: 'cat.jpg'));

      expect(tempWrites.single.key, 'cat.jpg');
      expect(tempWrites.single.value, [1, 2, 3]);
      expect(shared.single.single.path, '/tmp/cat.jpg');
    });

    test('web — XFile.fromData, temp-файл НЕ пишется', () async {
      final shared = <List<XFile>>[];
      var tempCalled = false;
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([7, 8, 9]),
        shareFiles: (files) async => shared.add(files),
        writeTempFile: (name, bytes) async {
          tempCalled = true;
          return '/tmp/$name';
        },
        platformOverride: TargetPlatform.android,
        isWebOverride: true,
      );

      await actions.shareImage(ref());

      expect(tempCalled, isFalse, reason: 'на web temp-файл недоступен');
      final bytes = await shared.single.single.readAsBytes();
      expect(bytes, [7, 8, 9]);
    });

    test('пустое имя → fallback image.<ext> по mime', () async {
      final tempWrites = <String>[];
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([0]),
        shareFiles: (_) async {},
        writeTempFile: (name, _) async {
          tempWrites.add(name);
          return '/tmp/$name';
        },
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );

      await actions.shareImage(ref(mime: 'image/png', filename: ''));
      expect(tempWrites.single, 'image.png');
    });
  });

  group('copyImage', () {
    test('desktop (не Linux) — bitmap в буфер', () async {
      final copiedBitmaps = <Uint8List>[];
      final copiedFiles = <List<String>>[];
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([4, 5, 6]),
        copyImageBytes: (b) async => copiedBitmaps.add(b),
        copyFiles: (paths) async => copiedFiles.add(paths),
        platformOverride: TargetPlatform.windows,
        isWebOverride: false,
      );

      await actions.copyImage(ref());

      expect(copiedBitmaps.single, [4, 5, 6]);
      expect(copiedFiles, isEmpty);
    });

    test('Linux — файловая ссылка (writeImage там no-op)', () async {
      final copiedBitmaps = <Uint8List>[];
      final copiedFiles = <List<String>>[];
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([1, 1]),
        copyImageBytes: (b) async => copiedBitmaps.add(b),
        copyFiles: (paths) async => copiedFiles.add(paths),
        writeTempFile: (name, _) async => '/tmp/$name',
        platformOverride: TargetPlatform.linux,
        isWebOverride: false,
      );

      await actions.copyImage(ref(filename: 'x.png'));

      expect(copiedFiles.single, ['/tmp/x.png']);
      expect(copiedBitmaps, isEmpty);
    });

    test('mobile — bitmap в буфер (writeImage поддержан)', () async {
      final copiedBitmaps = <Uint8List>[];
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([2, 2]),
        copyImageBytes: (b) async => copiedBitmaps.add(b),
        platformOverride: TargetPlatform.iOS,
        isWebOverride: false,
      );

      await actions.copyImage(ref());
      expect(copiedBitmaps.single, [2, 2]);
    });
  });

  group('runPrimary', () {
    test('mobile → share', () async {
      var shareCalled = false;
      var copyCalled = false;
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([0]),
        shareFiles: (_) async => shareCalled = true,
        copyImageBytes: (_) async => copyCalled = true,
        writeTempFile: (name, _) async => '/tmp/$name',
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );

      await actions.runPrimary(ref());
      expect(shareCalled, isTrue);
      expect(copyCalled, isFalse);
    });

    test('desktop → copy', () async {
      var shareCalled = false;
      var copyCalled = false;
      final actions = ImageActions(
        loadBytes: (_) async => Uint8List.fromList([0]),
        shareFiles: (_) async => shareCalled = true,
        copyImageBytes: (_) async => copyCalled = true,
        platformOverride: TargetPlatform.macOS,
        isWebOverride: false,
      );

      await actions.runPrimary(ref());
      expect(copyCalled, isTrue);
      expect(shareCalled, isFalse);
    });
  });

  group('fromDownloader', () {
    test('конвертит AttachmentBytes → байты с учётом offset', () async {
      // ByteData с ненулевым offset — проверяем, что asUint8List уважает
      // offsetInBytes/lengthInBytes (не отдаёт весь буфер).
      final full = Uint8List.fromList([9, 9, 3, 4, 5]);
      final view = ByteData.sublistView(full, 2); // [3,4,5]
      Future<AttachmentBytes> download({required String mxcUrl}) async =>
          AttachmentBytes(bytes: view, contentType: 'image/png');

      final copied = <Uint8List>[];
      final actions = ImageActions.fromDownloader(
        download,
        copyImageBytes: (b) async => copied.add(b),
        platformOverride: TargetPlatform.windows,
        isWebOverride: false,
      );

      await actions.copyImage(ref());
      expect(copied.single, [3, 4, 5]);
    });
  });
}
