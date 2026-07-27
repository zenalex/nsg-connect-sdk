/// **issue #69**: тап по файловому вложению.
///
/// Что защищаем:
///   * какие форматы показываем внутри приложения (по расширению, а НЕ по
///     mime: сервер отдаёт .md и как `text/markdown`, и как
///     `application/octet-stream`);
///   * платформенное расщепление: десктоп отдаёт файл ОС по пути, mobile/
///     web — системному sheet (на Android `file://` наружу кидать нельзя);
///   * сохранение не затирает чужой файл в «Загрузках»;
///   * `originalFilename` приходит от ОТПРАВИТЕЛЯ: «../../evil» не должен
///     превращаться в запись мимо каталога.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/attachments/file_actions.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

AttachmentRef _att({
  String name = 'report.md',
  String mime = 'text/markdown',
  int size = 1024,
}) => AttachmentRef(
  mxcUrl: 'mxc://l/abc',
  originalFilename: name,
  mimeType: mime,
  sizeBytes: size,
);

void main() {
  group('isTextPreviewable', () {
    test('текстовые расширения — показываем внутри', () {
      for (final n in ['a.md', 'b.txt', 'c.json', 'd.log', 'e.yaml', 'f.dart']) {
        expect(
          isTextPreviewable(filename: n, mimeType: '', sizeBytes: 10),
          isTrue,
          reason: n,
        );
      }
    });

    test('.md с mime application/octet-stream — всё равно текст', () {
      // Ровно случай пользователя: сервер не всегда знает markdown, и по
      // одному mime «понятный формат» стал бы «непонятным».
      expect(
        isTextPreviewable(
          filename: 'README.md',
          mimeType: 'application/octet-stream',
          sizeBytes: 10,
        ),
        isTrue,
      );
    });

    test('text/* с charset — текст', () {
      expect(
        isTextPreviewable(
          filename: 'noext',
          mimeType: 'text/plain; charset=utf-8',
          sizeBytes: 10,
        ),
        isTrue,
      );
    });

    test('бинарники — не показываем', () {
      expect(
        isTextPreviewable(
          filename: 'doc.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 10,
        ),
        isFalse,
      );
      expect(
        isTextPreviewable(
          filename: 'archive.zip',
          mimeType: 'application/zip',
          sizeBytes: 10,
        ),
        isFalse,
      );
    });

    test('огромный текст — не показываем (иначе UI встанет на рендере)', () {
      expect(
        isTextPreviewable(
          filename: 'huge.log',
          mimeType: 'text/plain',
          sizeBytes: kMaxPreviewBytes + 1,
        ),
        isFalse,
      );
    });
  });

  group('открытие', () {
    late List<String> opened;
    late List<List<XFile>> shared;

    FileActions build(TargetPlatform platform, {bool isWeb = false, bool ok = true}) {
      opened = [];
      shared = [];
      return FileActions(
        loadBytes: (_) async => Uint8List.fromList(utf8.encode('содержимое')),
        openPath: (path) async {
          opened.add(path);
          return ok;
        },
        shareFiles: (files) async => shared.add(files),
        writeTempFile: (name, bytes) async => p.join('/tmp', name),
        downloadsDir: () async => null,
        platformOverride: platform,
        isWebOverride: isWeb,
      );
    }

    test('десктоп отдаёт файл ОС по пути', () async {
      final a = build(TargetPlatform.windows);
      await a.openExternally(_att());
      expect(opened.single, endsWith('report.md'));
      expect(shared, isEmpty);
    });

    test('Android идёт через share sheet, а не file:// ', () async {
      // launchUrl(file://) на Android даёт FileUriExposedException —
      // поэтому там системный sheet, он же закрывает «открыть в…».
      final a = build(TargetPlatform.android);
      await a.openExternally(_att());
      expect(shared.single.single.name, 'report.md');
      expect(opened, isEmpty);
    });

    test('web шарит байтами (temp-файла нет)', () async {
      final a = build(TargetPlatform.android, isWeb: true);
      await a.openExternally(_att());
      expect(shared.single, hasLength(1));
      expect(opened, isEmpty);
    });

    test('ОС не нашла программу → отдельная ошибка, не «сбой загрузки»',
        () async {
      final a = build(TargetPlatform.windows, ok: false);
      await expectLater(
        a.openExternally(_att(name: 'weird.xyz', mime: 'application/x-xyz')),
        throwsA(isA<NoHandlerForFileException>()),
      );
    });
  });

  group('сохранение', () {
    test('десктоп: пишет в «Загрузки» и не затирает существующий файл',
        () async {
      final dir = await Directory.systemTemp.createTemp('nsg-dl-');
      addTearDown(() => dir.delete(recursive: true));
      File(p.join(dir.path, 'report.md')).writeAsStringSync('чужое');

      final a = FileActions(
        loadBytes: (_) async => Uint8List.fromList(utf8.encode('моё')),
        downloadsDir: () async => dir.path,
        writeTempFile: (name, bytes) async => p.join(dir.path, 'tmp-$name'),
        platformOverride: TargetPlatform.windows,
        isWebOverride: false,
      );
      final path = await a.saveToDisk(_att());

      expect(p.basename(path!), 'report (1).md');
      expect(File(p.join(dir.path, 'report.md')).readAsStringSync(), 'чужое',
          reason: 'чужой файл в «Загрузках» не наш — перезаписывать нельзя');
      expect(File(path).readAsStringSync(), 'моё');
    });

    test('mobile: отдаёт системе, пути не возвращает', () async {
      final shared = <List<XFile>>[];
      final a = FileActions(
        loadBytes: (_) async => Uint8List.fromList([1, 2, 3]),
        shareFiles: (f) async => shared.add(f),
        writeTempFile: (name, bytes) async => p.join('/tmp', name),
        downloadsDir: () async => null,
        platformOverride: TargetPlatform.iOS,
        isWebOverride: false,
      );
      expect(await a.saveToDisk(_att()), isNull);
      expect(shared, hasLength(1));
    });
  });

  group('safeName', () {
    test('путь в имени от отправителя обрезается до имени файла', () {
      expect(
        FileActions.safeName(_att(name: '../../../etc/passwd')),
        'passwd',
      );
      expect(FileActions.safeName(_att(name: r'C:\Windows\evil.exe')),
          'evil.exe');
    });

    test('пустое имя → file.bin, запрещённые символы → _', () {
      expect(FileActions.safeName(_att(name: '   ')), 'file.bin');
      expect(FileActions.safeName(_att(name: 'a:b*c?.txt')), 'a_b_c_.txt');
    });
  });

  test('битые байты не роняют просмотр', () async {
    final a = FileActions(
      loadBytes: (_) async => Uint8List.fromList([0xff, 0xfe, 0x41]),
      platformOverride: TargetPlatform.windows,
      isWebOverride: false,
    );
    // Не бросает: показать текст с «кракозяброй» в одном месте лучше, чем
    // пустой экран с ошибкой на файле, который почти весь читаем.
    expect(await a.loadTextPreview(_att()), contains('A'));
  });
}
