import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_mime_types.dart';

/// Общий MIME-модуль SDK: таблица расширений + деривация Matrix msgType.
///
/// Деривация была продублирована трижды (`ChatMessage`, `OutboxSender`,
/// `MessagesController`), и копия в контроллере не знала про `audio/` —
/// голосовое в оптимистичном бабле показывалось как файл, пока не
/// приедет authoritative msgType из RPC-ответа. Тесты ниже фиксируют
/// единое поведение, чтобы копии не отросли заново.
void main() {
  group('matrixMsgTypeForMime', () {
    test('image/* → m.image', () {
      expect(matrixMsgTypeForMime('image/jpeg'), 'm.image');
      expect(matrixMsgTypeForMime('image/heic'), 'm.image');
    });

    test('video/* → m.video', () {
      expect(matrixMsgTypeForMime('video/mp4'), 'm.video');
      expect(matrixMsgTypeForMime('video/quicktime'), 'm.video');
    });

    test('audio/* → m.audio (регрессия: контроллер отдавал m.file)', () {
      expect(matrixMsgTypeForMime('audio/mp4'), 'm.audio');
      expect(matrixMsgTypeForMime('audio/mpeg'), 'm.audio');
      expect(matrixMsgTypeForMime('audio/opus'), 'm.audio');
    });

    test('всё остальное → m.file', () {
      expect(matrixMsgTypeForMime('application/pdf'), 'm.file');
      expect(matrixMsgTypeForMime('text/plain'), 'm.file');
      expect(matrixMsgTypeForMime(kFallbackMime), 'm.file');
    });
  });

  group('mimeForMatrixMsgType', () {
    test('обратный дериват покрывает все четыре категории', () {
      expect(mimeForMatrixMsgType('m.image'), 'image/jpeg');
      expect(mimeForMatrixMsgType('m.video'), 'video/mp4');
      expect(mimeForMatrixMsgType('m.audio'), 'audio/mp4');
      expect(mimeForMatrixMsgType('m.file'), kFallbackMime);
    });

    test('неизвестный msgType → image/jpeg (альбом = картинки)', () {
      expect(mimeForMatrixMsgType('m.text'), 'image/jpeg');
    });

    test('round-trip: категория MIME сохраняется', () {
      for (final mime in kExtensionToMime.values.toSet()) {
        final msgType = matrixMsgTypeForMime(mime);
        expect(
          matrixMsgTypeForMime(mimeForMatrixMsgType(msgType)),
          msgType,
          reason: '$mime → $msgType → должен вернуться в ту же категорию',
        );
      }
    });
  });

  group('kExtensionToMime', () {
    test('ключи — нижний регистр с точкой (иначе lookup промахнётся)', () {
      for (final ext in kExtensionToMime.keys) {
        expect(ext, startsWith('.'));
        expect(ext, equals(ext.toLowerCase()));
      }
    });

    test('каждая запись достижима через guessMimeFromExtension', () {
      kExtensionToMime.forEach((ext, mime) {
        expect(guessMimeFromExtension('file$ext'), mime);
        expect(guessMimeFromExtension('FILE${ext.toUpperCase()}'), mime);
      });
    });

    test('составное расширение берётся по последней точке', () {
      expect(guessMimeFromExtension('archive.tar.gz'), 'application/gzip');
    });

    test('dot-file без второго расширения не считается расширением', () {
      expect(guessMimeFromExtension('.jpg'), 'image/jpeg');
    });
  });
}
