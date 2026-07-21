import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/share/share_intake.dart';
import 'package:nsg_messenger/src/share/shared_payload.dart';

/// **TASK49 (share-in)**: юнит-тесты чистых частей — маппинг входящих
/// элементов плагина в [SharedPayload], порядок отправки «текст после
/// файлов» (§3.4) и поведение отложенного слота (hold → release).
void main() {
  group('mapInboundToSharedPayload', () {
    test('только текст → payload с текстом, без файлов', () {
      final p = mapInboundToSharedPayload(const [
        SharedInboundItem(kind: SharedInboundKind.text, value: 'hello'),
      ]);
      expect(p.text, 'hello');
      expect(p.files, isEmpty);
      expect(p.hasText, isTrue);
      expect(p.hasFiles, isFalse);
    });

    test('url трактуется как текст', () {
      final p = mapInboundToSharedPayload(const [
        SharedInboundItem(
          kind: SharedInboundKind.url,
          value: 'https://example.com',
        ),
      ]);
      expect(p.text, 'https://example.com');
      expect(p.files, isEmpty);
    });

    test('картинки/видео/файлы → files с путём и MIME', () {
      final p = mapInboundToSharedPayload(const [
        SharedInboundItem(
          kind: SharedInboundKind.image,
          value: '/tmp/a.jpg',
          mimeType: 'image/jpeg',
          name: 'a.jpg',
        ),
        SharedInboundItem(
          kind: SharedInboundKind.video,
          value: '/tmp/b.mp4',
          mimeType: 'video/mp4',
        ),
        SharedInboundItem(
          kind: SharedInboundKind.file,
          value: '/tmp/c.pdf',
        ),
      ]);
      expect(p.text, isNull);
      expect(p.files.length, 3);
      expect(p.files.first.path, '/tmp/a.jpg');
      expect(p.files.first.mimeType, 'image/jpeg');
      expect(p.files.first.name, 'a.jpg');
    });

    test('смешанный share: текст + файл', () {
      final p = mapInboundToSharedPayload(const [
        SharedInboundItem(kind: SharedInboundKind.text, value: 'caption'),
        SharedInboundItem(kind: SharedInboundKind.image, value: '/tmp/a.jpg'),
      ]);
      expect(p.text, 'caption');
      expect(p.files.single.path, '/tmp/a.jpg');
    });

    test('несколько текстовых частей склеиваются переводом строки', () {
      final p = mapInboundToSharedPayload(const [
        SharedInboundItem(kind: SharedInboundKind.text, value: 'line1'),
        SharedInboundItem(kind: SharedInboundKind.url, value: 'line2'),
      ]);
      expect(p.text, 'line1\nline2');
    });

    test('пустые значения и файлы с пустым путём отбрасываются', () {
      final p = mapInboundToSharedPayload(const [
        SharedInboundItem(kind: SharedInboundKind.text, value: '   '),
        SharedInboundItem(kind: SharedInboundKind.file, value: ''),
      ]);
      expect(p.isEmpty, isTrue);
    });
  });

  group('planShareSend (порядок «текст после файлов», §3.4)', () {
    test('только текст → один текстовый шаг', () {
      final steps = planShareSend(const SharedPayload(text: 'hi'));
      expect(steps, hasLength(1));
      expect(steps.single, isA<ShareTextStep>());
      expect((steps.single as ShareTextStep).text, 'hi');
    });

    test('только файлы → файловые шаги в порядке', () {
      final steps = planShareSend(
        const SharedPayload(
          files: [
            SharedFile(path: '/a'),
            SharedFile(path: '/b'),
          ],
        ),
      );
      expect(steps, hasLength(2));
      expect(steps.every((s) => s is ShareFileStep), isTrue);
      expect((steps[0] as ShareFileStep).file.path, '/a');
      expect((steps[1] as ShareFileStep).file.path, '/b');
    });

    test('текст + файлы → текст ПОСЛЕДНИМ шагом (после всех файлов)', () {
      final steps = planShareSend(
        const SharedPayload(
          text: 'caption',
          files: [
            SharedFile(path: '/a'),
            SharedFile(path: '/b'),
          ],
        ),
      );
      expect(steps, hasLength(3));
      expect(steps[0], isA<ShareFileStep>());
      expect(steps[1], isA<ShareFileStep>());
      expect(steps.last, isA<ShareTextStep>());
      expect((steps.last as ShareTextStep).text, 'caption');
    });

    test('текст тримится в шаге', () {
      final steps = planShareSend(const SharedPayload(text: '  hi  '));
      expect((steps.single as ShareTextStep).text, 'hi');
    });
  });

  group('OUTBOX album-планирование (мульти-фото → один albumId, §4)', () {
    var seq = 0;
    String genId() => 'album-${seq++}';

    setUp(() => seq = 0);

    test('≥2 изображения → общий albumId', () {
      final id = shareAlbumIdForPayload(
        const SharedPayload(
          files: [
            SharedFile(path: '/a.jpg', mimeType: 'image/jpeg'),
            SharedFile(path: '/b.png', mimeType: 'image/png'),
          ],
        ),
        genId: genId,
      );
      expect(id, isNotNull);
    });

    test('одна картинка → без albumId (null)', () {
      final id = shareAlbumIdForPayload(
        const SharedPayload(
          files: [SharedFile(path: '/a.jpg', mimeType: 'image/jpeg')],
        ),
        genId: genId,
      );
      expect(id, isNull);
    });

    test('картинка + не-картинка → без общего albumId (одна картинка)', () {
      final id = shareAlbumIdForPayload(
        const SharedPayload(
          files: [
            SharedFile(path: '/a.jpg', mimeType: 'image/jpeg'),
            SharedFile(path: '/b.pdf', mimeType: 'application/pdf'),
          ],
        ),
        genId: genId,
      );
      expect(id, isNull);
    });

    test('MIME выводится из расширения, если не задан', () {
      expect(
        shareFileIsImage(const SharedFile(path: '/photo.jpg')),
        isTrue,
      );
      expect(
        shareFileIsImage(const SharedFile(path: '/doc.pdf')),
        isFalse,
      );
    });

    test('два image-файла без MIME (по расширению) → общий albumId', () {
      final id = shareAlbumIdForPayload(
        const SharedPayload(
          files: [SharedFile(path: '/a.jpg'), SharedFile(path: '/b.png')],
        ),
        genId: genId,
      );
      expect(id, isNotNull);
    });
  });

  group('SharePendingSlot (hold → release, §3.5)', () {
    test('изначально пусто', () {
      final slot = SharePendingSlot();
      expect(slot.hasPending, isFalse);
      expect(slot.take(), isNull);
    });

    test('store → hasPending, take отдаёт один раз и очищает', () {
      final slot = SharePendingSlot();
      const payload = SharedPayload(text: 'later');
      slot.store(payload);
      expect(slot.hasPending, isTrue);
      expect(slot.take(), payload);
      expect(slot.hasPending, isFalse);
      expect(slot.take(), isNull);
    });

    test('второй store перезаписывает (последний важнее, очередь не в MVP)', () {
      final slot = SharePendingSlot();
      slot.store(const SharedPayload(text: 'first'));
      slot.store(const SharedPayload(text: 'second'));
      expect(slot.take()?.text, 'second');
    });

    test('clear сбрасывает слот без выдачи', () {
      final slot = SharePendingSlot();
      slot.store(const SharedPayload(text: 'x'));
      slot.clear();
      expect(slot.hasPending, isFalse);
    });
  });
}
