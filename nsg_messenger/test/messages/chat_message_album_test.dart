import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';

/// Альбом: `ChatMessage` достаёт `nsg.album_id` из сырого Matrix-content-а
/// (server-side passthrough), optimistic несёт его напрямую, copy-методы
/// сохраняют. Битый/отсутствующий content → null (без падений).
ByteData _content(Map<String, dynamic> m) =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(m))));

MessengerMessage _imageMsg({String? albumId, required String eventId}) =>
    MessengerMessage(
      matrixEventId: eventId,
      roomId: 1,
      matrixRoomId: '!r:t',
      senderMatrixUserId: '@a:t',
      msgType: 'm.image',
      body: 'img.png',
      serverTimestamp: DateTime.utc(2026, 1, 1),
      content: _content({'msgtype': 'm.image', 'nsg.album_id': ?albumId}),
    );

void main() {
  group('ChatMessage — album', () {
    test('fromServer парсит nsg.album_id из content', () {
      final m = ChatMessage.fromServer(
        _imageMsg(albumId: 'alb-1', eventId: 'e1'),
      );
      expect(m.albumId, 'alb-1');
    });

    test('fromServer без album_id → null', () {
      expect(ChatMessage.fromServer(_imageMsg(eventId: 'e2')).albumId, isNull);
    });

    test('optimistic несёт albumId, переживает failed → retrying', () {
      final o = ChatMessage.optimistic(
        clientTxnId: 't1',
        senderMatrixUserId: '@a:t',
        senderMessengerUserId: 1,
        body: 'x',
        albumId: 'alb-2',
      );
      expect(o.albumId, 'alb-2');
      expect(o.failed(StateError('x')).albumId, 'alb-2');
      expect(o.failed(StateError('x')).retrying().albumId, 'alb-2');
    });

    test('битый content → albumId null (без исключений)', () {
      final m = MessengerMessage(
        matrixEventId: 'e3',
        roomId: 1,
        matrixRoomId: '!r:t',
        senderMatrixUserId: '@a:t',
        msgType: 'm.text',
        body: 'hi',
        serverTimestamp: DateTime.utc(2026, 1, 1),
        content: ByteData.sublistView(Uint8List.fromList([0xff, 0xfe, 0x00])),
      );
      expect(ChatMessage.fromServer(m).albumId, isNull);
    });
  });

  group('ChatMessage — оптимистичный альбом (localImageBytes)', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    ChatMessage uploading() => ChatMessage.optimistic(
      clientTxnId: 't-up',
      senderMatrixUserId: '@a:t',
      senderMessengerUserId: 1,
      body: 'photo.jpg',
      msgType: 'm.image',
      attachment: null,
      localImageBytes: bytes,
      albumId: 'alb-1',
    );

    AttachmentRef ref() => AttachmentRef(
      mxcUrl: 'mxc://s/up1',
      mimeType: 'image/jpeg',
      sizeBytes: 4,
      originalFilename: 'photo.jpg',
      thumbnailMxcUrl: 'mxc://s/up1',
    );

    test('optimistic несёт localImageBytes → isUploadingImage=true', () {
      final o = uploading();
      expect(o.localImageBytes, bytes);
      expect(o.isUploadingImage, isTrue);
    });

    test('isUploadingImage=false когда attachment уже есть', () {
      final o = uploading().withUploadedAttachment(ref());
      expect(o.attachment, isNotNull);
      expect(o.localImageBytes, bytes, reason: 'байты сохраняются (расблюр)');
      expect(o.isUploadingImage, isFalse);
      expect(o.isPending, isTrue, reason: 'status остаётся pending до send');
      expect(o.msgType, 'm.image', reason: 'msgType из mime');
    });

    test('isUploadingImage=false когда нет байт (обычное pending)', () {
      final o = ChatMessage.optimistic(
        clientTxnId: 't',
        senderMatrixUserId: '@a:t',
        senderMessengerUserId: 1,
        body: 'hi',
      );
      expect(o.isUploadingImage, isFalse);
    });

    test('localImageBytes переживает failed → retrying', () {
      final o = uploading();
      expect(o.failed(StateError('x')).localImageBytes, bytes);
      expect(o.failed(StateError('x')).retrying().localImageBytes, bytes);
      // Failed-член всё ещё «грузящаяся картинка» (attachment null + bytes).
      expect(o.failed(StateError('x')).retrying().isUploadingImage, isTrue);
    });

    test('withEdit сохраняет localImageBytes', () {
      final o = uploading().withEdit(
        newBody: 'new',
        editedAt: DateTime.utc(2026, 1, 2),
      );
      expect(o.localImageBytes, bytes);
    });

    test('withDelete роняет localImageBytes (tombstone)', () {
      final o = uploading().withDelete(deletedAt: DateTime.utc(2026, 1, 2));
      expect(o.localImageBytes, isNull);
      expect(o.attachment, isNull);
      expect(o.isUploadingImage, isFalse);
    });

    test(
      'fromServer.overrideLocalImageBytes пробрасывает байты (без мигания)',
      () {
        final srv = MessengerMessage(
          matrixEventId: 'e-srv',
          roomId: 1,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@a:t',
          msgType: 'm.image',
          body: 'photo.jpg',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          content: ByteData(0),
        );
        final promoted = ChatMessage.fromServer(
          srv,
          overrideLocalImageBytes: bytes,
        );
        expect(promoted.localImageBytes, bytes);
        // sent + attachment null (thumbnail ещё нет) → isUploadingImage
        // требует pending, значит false (не показываем блюр для sent).
        expect(promoted.isUploadingImage, isFalse);
      },
    );

    test('localImageBytes НЕ участвует в ==/hashCode', () {
      final a = uploading();
      final b = ChatMessage.optimistic(
        clientTxnId: 't-up',
        senderMatrixUserId: '@a:t',
        senderMessengerUserId: 1,
        body: 'photo.jpg',
        msgType: 'm.image',
        attachment: null,
        localImageBytes: Uint8List.fromList([9, 9]), // другие байты
        albumId: 'alb-1',
        serverTimestamp: a.serverTimestamp,
      );
      expect(a, equals(b), reason: 'разные байты не ломают равенство');
      expect(a.hashCode, b.hashCode);
    });
  });
}
