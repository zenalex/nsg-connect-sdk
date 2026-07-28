/// **Кто попадает в фотомозаику альбома.**
///
/// Отчёт с отладки `titan_lk` на iPhone: «композер выдаёт общий albumId
/// любой пачке вложений, поэтому в мозаике из картинок может оказаться
/// PDF». Последствия шли каскадом: плитка документа грузилась как
/// изображение и падала в иконку битого файла; тап по ней открывал
/// ПЕРВОЕ фото чата (починено отдельно, `0ac66ce`); клиент запрашивал у
/// Synapse превью документа и получал отказ, который на сервере
/// превращался в 500.
///
/// Правило простое: в альбом идут только картинки, файл — своё
/// сообщение.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

PickedAttachment _a(String mime, [String name = 'f']) => PickedAttachment(
  bytes: Uint8List(0),
  mimeType: mime,
  originalFilename: name,
);

void main() {
  group('belongsInAlbum', () {
    test('картинки — в мозаику', () {
      expect(belongsInAlbum(_a('image/jpeg')), isTrue);
      expect(belongsInAlbum(_a('image/png')), isTrue);
      expect(belongsInAlbum(_a('image/heic')), isTrue);
    });

    test('документы, видео и аудио — отдельными сообщениями', () {
      // Видео в мозаике рисовалось бы как картинка — галерея его тоже не
      // листает (`collectChatImages` требует image/*).
      expect(belongsInAlbum(_a('application/pdf')), isFalse);
      expect(belongsInAlbum(_a('video/mp4')), isFalse);
      expect(belongsInAlbum(_a('audio/ogg')), isFalse);
      expect(belongsInAlbum(_a('text/plain')), isFalse);
    });
  });

  group('albumNeeded', () {
    test('две картинки — альбом', () {
      expect(
        albumNeeded([_a('image/jpeg'), _a('image/png')], hasText: false),
        isTrue,
      );
    });

    test('одна картинка с подписью — альбом (иначе подпись отвяжется)', () {
      expect(albumNeeded([_a('image/jpeg')], hasText: true), isTrue);
    });

    test('одна картинка без подписи — обычное сообщение', () {
      expect(albumNeeded([_a('image/jpeg')], hasText: false), isFalse);
    });

    test('ЖИВОЙ СЛУЧАЙ: фото + PDF — альбом не из-за PDF', () {
      // Раньше «в пачке больше одного» давало albumId обоим, и документ
      // становился плиткой фотомозаики.
      final pack = [_a('image/jpeg'), _a('application/pdf', 'Инструкция.pdf')];
      expect(
        albumNeeded(pack, hasText: false),
        isFalse,
        reason: 'картинка тут одна — альбому неоткуда взяться',
      );
      expect(belongsInAlbum(pack[1]), isFalse, reason: 'PDF в мозаику не идёт');
    });

    test('два PDF альбома не образуют', () {
      expect(
        albumNeeded([
          _a('application/pdf'),
          _a('application/pdf'),
        ], hasText: true),
        isFalse,
      );
    });

    test('два фото + PDF: альбом собирают фото', () {
      final pack = [_a('image/jpeg'), _a('image/png'), _a('application/pdf')];
      expect(albumNeeded(pack, hasText: false), isTrue);
      expect(pack.where(belongsInAlbum), hasLength(2));
    });

    test('пустая пачка (только текст) — не альбом', () {
      expect(albumNeeded(const [], hasText: true), isFalse);
    });
  });
}
