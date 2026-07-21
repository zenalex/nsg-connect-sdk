import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';

/// Пересылка пачкой (мультивыбор) через [MessagesController.forwardMessages]:
///   * N сообщений уходят в порядке ВОЗРАСТАНИЯ времени (хронология чата),
///     последовательно — мок считает вызовы и их порядок;
///   * атрибуция «Переслано от X» сохранена per-сообщение;
///   * дедуп по albumId — два члена одного альбома пересылаются один раз;
///   * одиночная обёртка [MessagesController.forwardMessage] всё ещё работает
///     (регрессия базовой пересылки).
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
    required this.fwdName,
    required this.fwdUid,
    required this.clientTxnId,
  });
  final int roomId;
  final String body;
  final String msgType;
  final AttachmentRef? attachment;
  final String? albumId;
  final String? fwdName;
  final int? fwdUid;
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
        fwdName: forwardedFromName,
        fwdUid: forwardedFromMessengerUserId,
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

MessengerMessage _text(
  String ev,
  String body,
  int minute, {
  String sender = '@alice:t',
  int uid = 2,
  String name = 'Alice',
}) => MessengerMessage(
  matrixEventId: ev,
  roomId: _srcRoom,
  matrixRoomId: '!r:t',
  senderMatrixUserId: sender,
  senderMessengerUserId: uid,
  msgType: 'm.text',
  body: body,
  serverTimestamp: DateTime.utc(2026, 1, 1, 12, minute),
  senderDisplayName: name,
);

MessengerMessage _img(String ev, String mxc, int minute, {String? albumId}) =>
    MessengerMessage(
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
      content: albumId == null
          ? null
          : _content({'msgtype': 'm.image', 'nsg.album_id': albumId}),
      senderDisplayName: 'Alice',
    );

Future<MessagesController> _build(_ForwardFakeRpc rpc) async {
  final c = MessagesController(
    roomId: _srcRoom,
    rpc: rpc,
    events: const Stream<MessengerEvent>.empty(),
    selfMessengerUserId: _selfUid,
    selfMatrixUserId: _selfMx,
  );
  await c.init();
  return c;
}

ChatMessage _byEvent(MessagesController c, String ev) =>
    (c.state as MessagesReady).messages.firstWhere(
      (m) => m.matrixEventId == ev,
    );

void main() {
  test(
    'forwardMessages шлёт N сообщений в порядке ВОЗРАСТАНИЯ времени',
    () async {
      // page — DESC (newest first): c (мин 3), b (мин 2), a (мин 1).
      final rpc = _ForwardFakeRpc()
        ..page = [
          _text('c', 'третье', 3, name: 'Carol', sender: '@carol:t', uid: 4),
          _text('b', 'второе', 2, name: 'Bob', sender: '@bob:t', uid: 3),
          _text('a', 'первое', 1),
        ];
      final c = await _build(rpc);
      // Выбор передаём в «случайном» порядке — метод сам сортирует по времени.
      final selected = [_byEvent(c, 'c'), _byEvent(c, 'a'), _byEvent(c, 'b')];

      await c.forwardMessages(targetRoomId: _dstRoom, messages: selected);

      expect(rpc.sent.length, 3);
      expect(rpc.sent.every((s) => s.roomId == _dstRoom), isTrue);
      // Порядок отправки — по возрастанию времени: a, b, c.
      expect(rpc.sent.map((s) => s.body).toList(), [
        'первое',
        'второе',
        'третье',
      ]);
      // Атрибуция сохранена per-сообщение (первый автор каждого).
      expect(rpc.sent[0].fwdName, 'Alice');
      expect(rpc.sent[1].fwdName, 'Bob');
      expect(rpc.sent[2].fwdName, 'Carol');
      // Одиночные тексты — без albumId.
      expect(rpc.sent.every((s) => s.albumId == null), isTrue);
      // Уникальные clientTxnId.
      expect(rpc.sent.map((s) => s.clientTxnId).toSet().length, 3);
      await c.dispose();
    },
  );

  test('forwardMessages: смешанный выбор (текст + альбом-anchor)', () async {
    final rpc = _ForwardFakeRpc()
      ..page = [
        _img('i2', 'mxc://s/2', 5, albumId: 'A1'),
        _img('i1', 'mxc://s/1', 4, albumId: 'A1'),
        _text('t', 'просто текст', 1),
      ];
    final c = await _build(rpc);
    // Выбираем текст (мин 1) и ОДИН anchor альбома (мин 4/5).
    final selected = [_byEvent(c, 't'), _byEvent(c, 'i1')];

    await c.forwardMessages(targetRoomId: _dstRoom, messages: selected);

    // Текст (раньше по времени) отправлен первым, затем 2 картинки альбома.
    expect(rpc.sent.length, 3);
    expect(rpc.sent[0].body, 'просто текст');
    expect(rpc.sent[0].albumId, isNull);
    // Обе картинки альбома — один НОВЫЙ albumId.
    final albumIds = {rpc.sent[1].albumId, rpc.sent[2].albumId};
    expect(albumIds.length, 1);
    expect(albumIds.single, isNotNull);
    expect(albumIds.single, isNot('A1'), reason: 'новый albumId, не исходный');
    expect(rpc.sent[1].attachment?.mxcUrl, 'mxc://s/1');
    expect(rpc.sent[2].attachment?.mxcUrl, 'mxc://s/2');
    await c.dispose();
  });

  test(
    'forwardMessages: дедуп — два члена одного альбома → 1 разворот',
    () async {
      final rpc = _ForwardFakeRpc()
        ..page = [
          _img('i2', 'mxc://s/2', 5, albumId: 'A1'),
          _img('i1', 'mxc://s/1', 4, albumId: 'A1'),
        ];
      final c = await _build(rpc);
      // Оба члена альбома в выборке (защита — в UI так не бывает, но метод
      // должен переслать альбом ОДИН раз, а не задвоить).
      final selected = [_byEvent(c, 'i1'), _byEvent(c, 'i2')];

      await c.forwardMessages(targetRoomId: _dstRoom, messages: selected);

      // Ровно 2 отправки (2 картинки альбома), НЕ 4.
      expect(rpc.sent.length, 2);
      final albumIds = rpc.sent.map((s) => s.albumId).toSet();
      expect(albumIds.length, 1, reason: 'один новый albumId на весь альбом');
      await c.dispose();
    },
  );

  test('forwardMessage (одиночная обёртка) — регрессия', () async {
    final rpc = _ForwardFakeRpc()..page = [_text('t', 'hello', 1)];
    final c = await _build(rpc);

    await c.forwardMessage(targetRoomId: _dstRoom, message: _byEvent(c, 't'));

    expect(rpc.sent.length, 1);
    expect(rpc.sent.single.roomId, _dstRoom);
    expect(rpc.sent.single.body, 'hello');
    expect(rpc.sent.single.fwdName, 'Alice');
    await c.dispose();
  });

  test(
    'F1: forwardMessagesToRooms — каждое сообщение в каждую комнату',
    () async {
      final rpc = _ForwardFakeRpc()
        ..page = [_text('b', 'второе', 2), _text('a', 'первое', 1)];
      final c = await _build(rpc);
      final selected = [_byEvent(c, 'a'), _byEvent(c, 'b')];

      // Дубликат 21 в списке — должен схлопнуться (переслать один раз).
      await c.forwardMessagesToRooms(
        targetRoomIds: [21, 22, 21],
        messages: selected,
      );

      // 2 сообщения × 2 уникальные комнаты = 4 отправки.
      expect(rpc.sent.length, 4);
      final byRoom = <int, List<String>>{};
      for (final s in rpc.sent) {
        byRoom.putIfAbsent(s.roomId, () => []).add(s.body);
      }
      expect(byRoom.keys.toSet(), {21, 22});
      // В каждую комнату — оба сообщения в порядке возрастания времени.
      expect(byRoom[21], ['первое', 'второе']);
      expect(byRoom[22], ['первое', 'второе']);
      await c.dispose();
    },
  );
}
