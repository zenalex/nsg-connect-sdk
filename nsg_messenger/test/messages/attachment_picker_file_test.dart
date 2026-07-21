import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';

/// **Issue #54 п.2** — отправка произвольных файлов.
///
/// Тестируем ЧИСТУЮ часть пикера ([buildAttachmentsFromCandidates],
/// [partitionBySizeLimit], [isAttachmentSizeAllowed]) — плагин
/// `file_picker` за скобками, он только маппит PlatformFile →
/// [AttachmentCandidate].
void main() {
  Uint8List bytes(int n) => Uint8List(n);

  group('лимит размера', () {
    test('пустой и превышающий потолок файлы не проходят', () {
      expect(isAttachmentSizeAllowed(0), isFalse);
      expect(isAttachmentSizeAllowed(1), isTrue);
      expect(isAttachmentSizeAllowed(kMaxAttachmentBytes), isTrue);
      expect(isAttachmentSizeAllowed(kMaxAttachmentBytes + 1), isFalse);
    });

    test('kMaxAttachmentMb согласован с kMaxAttachmentBytes', () {
      expect(kMaxAttachmentMb, 50);
      expect(kMaxAttachmentBytes, 50 * 1024 * 1024);
    });

    test(
      'превышение НЕ отбрасывается молча — имя попадает в rejectedOversize',
      () async {
        final outcome = await buildAttachmentsFromCandidates(
          [
            AttachmentCandidate(name: 'ok.pdf', size: 10, path: '/ok.pdf'),
            AttachmentCandidate(
              name: 'huge.mkv',
              size: kMaxAttachmentBytes + 1,
              path: '/huge.mkv',
            ),
          ],
          readBytes: (p) async => bytes(10),
        );
        expect(outcome.picked.map((p) => p.originalFilename), ['ok.pdf']);
        expect(outcome.rejectedOversize, ['huge.mkv']);
      },
    );

    test('огромный файл НЕ читается в память (reader не зовётся)', () async {
      final readPaths = <String>[];
      await buildAttachmentsFromCandidates(
        [
          AttachmentCandidate(
            name: 'huge.zip',
            size: kMaxAttachmentBytes * 10,
            path: '/huge.zip',
          ),
        ],
        readBytes: (p) async {
          readPaths.add(p);
          return bytes(1);
        },
      );
      expect(
        readPaths,
        isEmpty,
        reason: 'проверка по заявленному размеру должна быть ДО чтения',
      );
    });

    test('совравший size ловится повторной проверкой по факту', () async {
      final outcome = await buildAttachmentsFromCandidates(
        [AttachmentCandidate(name: 'liar.bin', size: 10, path: '/liar.bin')],
        readBytes: (p) async => bytes(kMaxAttachmentBytes + 1),
      );
      expect(outcome.picked, isEmpty);
      expect(outcome.rejectedOversize, ['liar.bin']);
    });

    test('partitionBySizeLimit делит уже прочитанные вложения', () {
      final outcome = partitionBySizeLimit([
        PickedAttachment(
          bytes: bytes(100),
          mimeType: 'image/png',
          originalFilename: 'small.png',
        ),
        PickedAttachment(
          bytes: bytes(kMaxAttachmentBytes + 1),
          mimeType: 'image/png',
          originalFilename: 'big.png',
        ),
      ]);
      expect(outcome.picked.single.originalFilename, 'small.png');
      expect(outcome.rejectedOversize, ['big.png']);
    });
  });

  group('сборка вложений', () {
    test('файл даёт PickedAttachment с верными mime/именем/байтами', () async {
      final outcome = await buildAttachmentsFromCandidates(
        [
          AttachmentCandidate(
            name: 'отчёт.pdf',
            size: 3,
            path: '/tmp/отчёт.pdf',
          ),
        ],
        readBytes: (p) async => Uint8List.fromList([1, 2, 3]),
      );
      final a = outcome.picked.single;
      expect(a.originalFilename, 'отчёт.pdf');
      expect(a.mimeType, 'application/pdf');
      expect(a.bytes, [1, 2, 3]);
      expect(outcome.rejectedOversize, isEmpty);
    });

    test('байты из кандидата (web-путь) используются без reader', () async {
      var readerCalled = false;
      final outcome = await buildAttachmentsFromCandidates(
        [
          AttachmentCandidate(
            name: 'a.txt',
            size: 2,
            bytes: Uint8List.fromList([7, 8]),
          ),
        ],
        readBytes: (p) async {
          readerCalled = true;
          return bytes(0);
        },
      );
      expect(readerCalled, isFalse);
      expect(outcome.picked.single.bytes, [7, 8]);
      expect(outcome.picked.single.mimeType, 'text/plain');
    });

    test('ошибка чтения файла пропускает его, не роняя выбор', () async {
      final outcome = await buildAttachmentsFromCandidates(
        [
          AttachmentCandidate(name: 'gone.txt', size: 5, path: '/gone.txt'),
          AttachmentCandidate(name: 'ok.txt', size: 5, path: '/ok.txt'),
        ],
        readBytes: (p) async {
          if (p == '/gone.txt') throw Exception('no such file');
          return bytes(5);
        },
      );
      expect(outcome.picked.map((p) => p.originalFilename), ['ok.txt']);
    });

    test('кандидат без байтов и без пути пропускается', () async {
      final outcome = await buildAttachmentsFromCandidates([
        const AttachmentCandidate(name: 'ghost.bin', size: 5),
      ]);
      expect(outcome.picked, isEmpty);
    });

    test('мультивыбор уважает limit (свободные слоты _maxPending)', () async {
      final outcome = await buildAttachmentsFromCandidates(
        List.generate(
          10,
          (i) => AttachmentCandidate(name: 'f$i.txt', size: 5, path: '/f$i'),
        ),
        limit: 3,
        readBytes: (p) async => bytes(5),
      );
      expect(outcome.picked.length, 3);
      expect(outcome.picked.map((p) => p.originalFilename), [
        'f0.txt',
        'f1.txt',
        'f2.txt',
      ]);
    });

    test('limit не мешает сообщить про oversize', () async {
      final outcome = await buildAttachmentsFromCandidates(
        [
          AttachmentCandidate(
            name: 'huge.zip',
            size: kMaxAttachmentBytes + 1,
            path: '/huge.zip',
          ),
          AttachmentCandidate(name: 'a.txt', size: 5, path: '/a'),
        ],
        limit: 1,
        readBytes: (p) async => bytes(5),
      );
      expect(outcome.picked.single.originalFilename, 'a.txt');
      expect(outcome.rejectedOversize, ['huge.zip']);
    });

    test('порядок выбора сохраняется', () async {
      final outcome = await buildAttachmentsFromCandidates(
        [
          AttachmentCandidate(name: 'z.txt', size: 1, path: '/z'),
          AttachmentCandidate(name: 'a.txt', size: 1, path: '/a'),
          AttachmentCandidate(name: 'm.txt', size: 1, path: '/m'),
        ],
        readBytes: (p) async => bytes(1),
      );
      expect(outcome.picked.map((p) => p.originalFilename), [
        'z.txt',
        'a.txt',
        'm.txt',
      ]);
    });
  });

  group('MIME-фолбэк по расширению', () {
    test('документы / архивы / медиа', () {
      expect(guessMimeFromExtension('a.pdf'), 'application/pdf');
      expect(guessMimeFromExtension('A.PDF'), 'application/pdf', reason: 'case');
      expect(guessMimeFromExtension('a.zip'), 'application/zip');
      expect(guessMimeFromExtension('a.mp3'), 'audio/mpeg');
      expect(guessMimeFromExtension('a.mov'), 'video/quicktime');
      expect(guessMimeFromExtension('a.webm'), 'video/webm');
      expect(guessMimeFromExtension('a.csv'), 'text/csv');
      expect(
        guessMimeFromExtension('a.docx'),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(
        guessMimeFromExtension('a.xlsx'),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });

    test('старое поведение для картинок не сломано', () {
      expect(guessMimeFromExtension('a.jpg'), 'image/jpeg');
      expect(guessMimeFromExtension('a.jpeg'), 'image/jpeg');
      expect(guessMimeFromExtension('a.png'), 'image/png');
      expect(guessMimeFromExtension('a.mp4'), 'video/mp4');
    });

    test('неизвестное расширение → octet-stream', () {
      expect(guessMimeFromExtension('a.qqq'), 'application/octet-stream');
      expect(guessMimeFromExtension('noextension'), 'application/octet-stream');
    });
  });
}
