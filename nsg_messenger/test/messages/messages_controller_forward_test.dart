import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/message_share.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';

/// Пересылка (forward) через [MessagesController.forwardMessage]:
///   * одиночный текст / картинка → одна отправка в целевую комнату;
///   * альбом → все члены под НОВЫМ albumId, картинки перед подписью,
///     mxc переиспользован, reply/mentions сброшены;
///   * атрибуция «Переслано от X» сохраняет ПЕРВОГО автора при re-forward.
///   * [MessageSharer.buildImageFiles] тянет байты через downloadFullSize.

const _selfUid = 1;
const _selfMx = '@self:t';
const _srcRoom = 10;
const _dstRoom = 20;

ByteData _content(Map<String, dynamic> m) =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(m))));

class _Sent {
  _Sent({
    required this.roomId,
    required this.body,
    required this.msgType,
    required this.attachment,
    required this.albumId,
    required this.replyTo,
    required this.mentions,
    required this.fwdName,
    required this.fwdUid,
    required this.fwdRoomId,
    required this.fwdEventId,
    required this.clientTxnId,
  });
  final int roomId;
  final String body;
  final String msgType;
  final AttachmentRef? attachment;
  final String? albumId;
  final String? replyTo;
  final List<int>? mentions;
  final String? fwdName;
  final int? fwdUid;
  final int? fwdRoomId;
  final String? fwdEventId;
  final String clientTxnId;
}

class _ForwardFakeRpc implements MessagesRpc {
  final List<_Sent> sent = [];
  List<MessengerMessage> page = [];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: page);

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
  }) async {
    sent.add(
      _Sent(
        roomId: roomId,
        body: body,
        msgType: msgType,
        attachment: attachment,
        albumId: albumId,
        replyTo: replyToMatrixEventId,
        mentions: mentionedMessengerUserIds,
        fwdName: forwardedFromName,
        fwdUid: forwardedFromMessengerUserId,
        fwdRoomId: forwardedFromRoomId,
        fwdEventId: forwardedFromEventId,
        clientTxnId: clientTxnId,
      ),
    );
    return MessengerMessage(
      matrixEventId: 'ev${sent.length}',
      roomId: roomId,
      matrixRoomId: '!r:t',
      senderMatrixUserId: _selfMx,
      senderMessengerUserId: _selfUid,
      msgType: msgType,
      body: body,
      serverTimestamp: DateTime.utc(2026, 2, 2),
      clientTxnId: clientTxnId,
    );
  }

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) async =>
      AttachmentBytes(
        bytes: ByteData.sublistView(Uint8List.fromList([1, 2, 3, 4])),
        contentType: 'image/jpeg',
      );

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const [];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // #35 pin — заглушки (эти тесты pin не покрывают).
  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({required int roomId}) async =>
      const <MessengerMessage>[];
}

MessengerMessage _img(String ev, String mxc, int minute) => MessengerMessage(
  matrixEventId: ev,
  roomId: _srcRoom,
  matrixRoomId: '!r:t',
  senderMatrixUserId: '@alice:t',
  senderMessengerUserId: 2,
  msgType: 'm.image',
  body: 'photo.jpg',
  serverTimestamp: DateTime.utc(2026, 1, 1, 12, minute),
  attachment: AttachmentRef(
    mxcUrl: mxc,
    mimeType: 'image/jpeg',
    sizeBytes: 10,
    originalFilename: 'photo.jpg',
  ),
  content: _content({'msgtype': 'm.image', 'nsg.album_id': 'SRC'}),
  senderDisplayName: 'Alice',
);

MessengerMessage _caption(String ev, int minute) => MessengerMessage(
  matrixEventId: ev,
  roomId: _srcRoom,
  matrixRoomId: '!r:t',
  senderMatrixUserId: '@alice:t',
  senderMessengerUserId: 2,
  msgType: 'm.text',
  body: 'caption text',
  serverTimestamp: DateTime.utc(2026, 1, 1, 12, minute),
  content: _content({'msgtype': 'm.text', 'nsg.album_id': 'SRC'}),
  senderDisplayName: 'Alice',
);

Future<MessagesController> _build(_ForwardFakeRpc rpc) async {
  final c = MessagesController(
    roomId: _srcRoom,
    rpc: rpc,
    events: Stream<MessengerEvent>.empty(),
    selfMessengerUserId: _selfUid,
    selfMatrixUserId: _selfMx,
  );
  await c.init();
  return c;
}

void main() {
  test('forward одиночного текста → одна отправка в целевую комнату', () async {
    final rpc = _ForwardFakeRpc()
      ..page = [
        MessengerMessage(
          matrixEventId: 't1',
          roomId: _srcRoom,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@alice:t',
          senderMessengerUserId: 2,
          msgType: 'm.text',
          body: 'hello world',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          senderDisplayName: 'Alice',
        ),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.single;

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    expect(rpc.sent.length, 1);
    final s = rpc.sent.single;
    expect(s.roomId, _dstRoom);
    expect(s.body, 'hello world');
    expect(s.albumId, isNull);
    expect(s.attachment, isNull);
    expect(s.fwdName, 'Alice');
    expect(s.fwdUid, 2);
    expect(s.replyTo, isNull);
    expect(s.mentions, isNull);
    await c.dispose();
  });

  test('forward одиночной картинки (не альбом) → mxc переиспользован', () async {
    final rpc = _ForwardFakeRpc()
      ..page = [
        MessengerMessage(
          matrixEventId: 'p1',
          roomId: _srcRoom,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@alice:t',
          senderMessengerUserId: 2,
          msgType: 'm.image',
          body: 'pic.jpg',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          attachment: AttachmentRef(
            mxcUrl: 'mxc://server/solo',
            mimeType: 'image/jpeg',
            sizeBytes: 5,
            originalFilename: 'pic.jpg',
          ),
          senderDisplayName: 'Alice',
        ),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.single;

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    expect(rpc.sent.length, 1);
    final s = rpc.sent.single;
    expect(s.roomId, _dstRoom);
    expect(s.albumId, isNull);
    expect(s.msgType, 'm.image');
    expect(s.attachment?.mxcUrl, 'mxc://server/solo');
    expect(s.fwdName, 'Alice');
    await c.dispose();
  });

  test(
    'forward альбома → новый albumId, картинки перед подписью, mxc reuse',
    () async {
      // page — DESC (newest first): подпись новее, затем i2, i1.
      final rpc = _ForwardFakeRpc()
        ..page = [
          _caption('c1', 3),
          _img('i2', 'mxc://server/2', 2),
          _img('i1', 'mxc://server/1', 1),
        ];
      final c = await _build(rpc);
      // anchor — любой член альбома (берём картинку).
      final anchor = (c.state as MessagesReady).messages.firstWhere(
        (m) => m.attachment != null,
      );

      await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

      expect(rpc.sent.length, 3);
      expect(rpc.sent.every((s) => s.roomId == _dstRoom), isTrue);

      final albumIds = rpc.sent.map((s) => s.albumId).toSet();
      expect(albumIds.length, 1, reason: 'все части — один новый albumId');
      final newAlbum = albumIds.single;
      expect(newAlbum, isNotNull);
      expect(newAlbum, isNot('SRC'), reason: 'НОВЫЙ albumId, не исходный');

      // Картинки первыми (по возрастанию времени: i1, затем i2), подпись — последней.
      expect(rpc.sent[0].attachment?.mxcUrl, 'mxc://server/1');
      expect(rpc.sent[1].attachment?.mxcUrl, 'mxc://server/2');
      expect(rpc.sent[2].attachment, isNull);
      expect(rpc.sent[2].msgType, 'm.text');
      expect(rpc.sent[2].body, 'caption text');

      // Атрибуция на всех частях.
      expect(rpc.sent.every((s) => s.fwdName == 'Alice'), isTrue);
      expect(rpc.sent.every((s) => s.fwdUid == 2), isTrue);
      // Уникальные clientTxnId.
      expect(rpc.sent.map((s) => s.clientTxnId).toSet().length, 3);
      await c.dispose();
    },
  );

  test('re-forward сохраняет ПЕРВОГО автора', () async {
    final rpc = _ForwardFakeRpc()
      ..page = [
        MessengerMessage(
          matrixEventId: 'f1',
          roomId: _srcRoom,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@carol:t',
          senderMessengerUserId: 3, // промежуточный пересыльщик
          msgType: 'm.text',
          body: 'orig text',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          content: _content({
            'msgtype': 'm.text',
            'nsg.forwarded_from': 'Bob',
            'nsg.forwarded_from_uid': 9,
          }),
          senderDisplayName: 'Carol',
        ),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.single;

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    final s = rpc.sent.single;
    expect(s.fwdName, 'Bob', reason: 'первый автор, не Carol');
    expect(s.fwdUid, 9);
    await c.dispose();
  });

  // ─── Issue #41: координаты первоисточника ──────────────────────────

  test('forward сохраняет координаты источника (комната + событие)', () async {
    final rpc = _ForwardFakeRpc()
      ..page = [
        MessengerMessage(
          matrixEventId: r'$orig',
          roomId: _srcRoom,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@alice:t',
          senderMessengerUserId: 2,
          msgType: 'm.text',
          body: 'hello world',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          senderDisplayName: 'Alice',
        ),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.single;

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    final s = rpc.sent.single;
    expect(s.fwdRoomId, _srcRoom, reason: 'комната, ИЗ которой пересылаем');
    expect(s.fwdEventId, r'$orig');
    await c.dispose();
  });

  test('re-forward → координаты ПЕРВОИСТОЧНИКА, не звена', () async {
    // В нашей комнате лежит уже пересланное сообщение: автор — Bob из
    // комнаты 77, переслал его Carol. Пересылаем дальше — координаты
    // должны остаться Bob-овыми, иначе тап по «Переслано от Bob» открыл бы
    // чат Carol.
    final rpc = _ForwardFakeRpc()
      ..page = [
        MessengerMessage(
          matrixEventId: r'$relay',
          roomId: _srcRoom,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@carol:t',
          senderMessengerUserId: 3,
          msgType: 'm.text',
          body: 'orig text',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          content: _content({
            'msgtype': 'm.text',
            'nsg.forwarded_from': 'Bob',
            'nsg.forwarded_from_uid': 9,
            'nsg.forwarded_room_id': 77,
            'nsg.forwarded_event_id': r'$bobs-original',
          }),
          senderDisplayName: 'Carol',
        ),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.single;

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    final s = rpc.sent.single;
    expect(s.fwdName, 'Bob');
    expect(s.fwdRoomId, 77, reason: 'комната Bob-а, не _srcRoom Carol');
    expect(s.fwdEventId, r'$bobs-original');
    await c.dispose();
  });

  test('re-forward старого (координат нет) → координат нет', () async {
    // Сообщение переслали до issue #41: имя первого автора есть, координат
    // нет. Подставлять сюда промежуточное звено нельзя — шапка обещала бы
    // переход к Bob-у, а вёл бы он в чат Carol. Лучше некликабельная шапка.
    final rpc = _ForwardFakeRpc()
      ..page = [
        MessengerMessage(
          matrixEventId: r'$relay',
          roomId: _srcRoom,
          matrixRoomId: '!r:t',
          senderMatrixUserId: '@carol:t',
          senderMessengerUserId: 3,
          msgType: 'm.text',
          body: 'orig text',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          content: _content({
            'msgtype': 'm.text',
            'nsg.forwarded_from': 'Bob',
            'nsg.forwarded_from_uid': 9,
          }),
          senderDisplayName: 'Carol',
        ),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.single;

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    final s = rpc.sent.single;
    expect(s.fwdName, 'Bob', reason: 'атрибуция по имени как была');
    expect(s.fwdRoomId, isNull);
    expect(s.fwdEventId, isNull);
    await c.dispose();
  });

  test('альбом: у каждой части свои координаты источника', () async {
    final rpc = _ForwardFakeRpc()
      ..page = [
        _caption('c1', 3),
        _img('i2', 'mxc://server/2', 2),
        _img('i1', 'mxc://server/1', 1),
      ];
    final c = await _build(rpc);
    final anchor = (c.state as MessagesReady).messages.firstWhere(
      (m) => m.attachment != null,
    );

    await c.forwardMessage(targetRoomId: _dstRoom, message: anchor);

    // Порядок отправки: i1, i2, подпись — см. тест выше.
    expect(rpc.sent.map((s) => s.fwdEventId).toList(), ['i1', 'i2', 'c1']);
    expect(rpc.sent.every((s) => s.fwdRoomId == _srcRoom), isTrue);
    await c.dispose();
  });

  test(
    'MessageSharer.buildImageFiles тянет байты через downloadFullSize',
    () async {
      final rpc = _ForwardFakeRpc()..page = [_img('i1', 'mxc://server/1', 1)];
      final c = await _build(rpc);
      final imageMsg = (c.state as MessagesReady).messages.firstWhere(
        (m) => m.attachment != null,
      );

      final files = await MessageSharer(c).buildImageFiles([imageMsg]);
      expect(files.length, 1);
      final bytes = await files.single.readAsBytes();
      expect(bytes, [1, 2, 3, 4]);
      expect(files.single.mimeType, 'image/jpeg');
      await c.dispose();
    },
  );
}
