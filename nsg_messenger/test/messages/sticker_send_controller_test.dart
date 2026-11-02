/// **issue #151 — отправка стикера из контроллера.**
///
/// Две вещи, которые легко потерять:
///
///   * **пузырь виден сразу и целиком.** `mxc` стикера пикеру уже известен —
///     ждать серверного echo, чтобы показать картинку, незачем;
///   * **на сервер уходит только идентификатор.** Содержимое собирает сервер
///     по своей строке набора; если бы его слал клиент, стикером можно было
///     бы назвать что угодно и подписать чужим набором.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';
import 'package:nsg_messenger/src/messages/sticker_data.dart';

void main() {
  const roomId = 7;

  Sticker sticker({int id = 11, String alias = 'cat'}) => Sticker(
    id: id,
    packId: 3,
    mxcUrl: 'mxc://localhost/$alias',
    mimeType: 'image/webp',
    sizeBytes: 2048,
    width: 128,
    height: 128,
    alias: alias,
    position: 0,
    createdAt: DateTime.utc(2026, 8, 29),
  );

  Future<MessagesController> ready(_StickerFakeRpc rpc) async {
    final ctrl = MessagesController(
      roomId: roomId,
      rpc: rpc,
      events: const Stream.empty(),
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:test',
    );
    await ctrl.init();
    return ctrl;
  }

  List<ChatMessage> messagesOf(MessagesController c) =>
      (c.state as MessagesReady).messages;

  test('пузырь появляется сразу — с картинкой и разметкой', () async {
    // Сеть держим не отвеченной: проверяем именно ОПТИМИСТИЧНЫЙ пузырь, до
    // серверного echo.
    final rpc = _StickerFakeRpc()..hold = true;
    final ctrl = await ready(rpc);

    unawaited(ctrl.sendSticker(sticker()));
    await pumpEventQueue();

    final m = messagesOf(ctrl).single;
    expect(m.msgType, kStickerMsgType);
    expect(m.sticker?.alias, 'cat');
    expect(m.sticker?.id, 11, reason: 'без id не повторить упавшую отправку');
    expect(
      m.attachment?.mxcUrl,
      'mxc://localhost/cat',
      reason:
          'mxc известен пикеру — ждать echo, чтобы показать картинку, '
          'значит показывать пустое место на всё время сети',
    );
    expect(
      m.body,
      ':cat:',
      reason:
          'тот же запасной текст, что соберёт сервер: иначе на промоуте '
          'пузырь дёрнулся бы с одного текста на другой',
    );
    await ctrl.dispose();
  });

  test('после ответа сервера пузырь остаётся стикером', () async {
    // Промоут pending → sent строит пузырь ЗАНОВО, из серверного echo. Если
    // разметка там теряется, стикер на глазах превращается в картинку — а
    // заметить это можно только на живом сервере.
    final rpc = _StickerFakeRpc();
    final ctrl = await ready(rpc);

    await ctrl.sendSticker(sticker(alias: 'shrug'));
    await pumpEventQueue();

    final m = messagesOf(ctrl).single;
    expect(m.matrixEventId, isNotNull, reason: 'echo принят');
    expect(m.sticker?.alias, 'shrug');
    expect(m.sticker?.id, 11);
  });

  test('на сервер уходит идентификатор, а не сочинённое содержимое', () async {
    final rpc = _StickerFakeRpc();
    final ctrl = await ready(rpc);

    await ctrl.sendSticker(sticker(id: 77, alias: 'shrug'));

    expect(rpc.sent.single.stickerId, 77);
    expect(
      rpc.sent.single.msgType,
      kStickerMsgType,
      reason: 'сервер по нему ничего не решает, но пусть не расходится',
    );
    await ctrl.dispose();
  });

  test('повтор упавшего стикера остаётся стикером', () async {
    // Без id повтор ушёл бы обычной картинкой — и пузырь сменил бы вид
    // прямо на глазах у человека, который всего лишь нажал «повторить».
    final rpc = _StickerFakeRpc()..failNext = true;
    final ctrl = await ready(rpc);

    final txn = await ctrl.sendSticker(sticker(id: 5));
    expect(messagesOf(ctrl).single.isFailed, isTrue);

    await ctrl.retry(txn);

    expect(rpc.sent.map((s) => s.stickerId), [5, 5]);
    expect(rpc.sent.last.clientTxnId, txn, reason: 'тот же txn — иначе дубль');
    await ctrl.dispose();
  });
}

typedef _Sent = ({String clientTxnId, String msgType, int? stickerId});

class _StickerFakeRpc implements MessagesRpc {
  final List<_Sent> sent = <_Sent>[];

  /// Первый вызов упадёт permanent-ошибкой (не сетевой — ретраить нечего,
  /// пузырь сразу станет failed).
  bool failNext = false;

  /// Не отвечать вовсе — тогда виден оптимистичный пузырь.
  bool hold = false;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(
    messages: const <MessengerMessage>[],
    nextToken: null,
    prevToken: null,
  );

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

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
    String? threadId,
    int? stickerId,
  }) async {
    sent.add((
      clientTxnId: clientTxnId,
      msgType: msgType,
      stickerId: stickerId,
    ));
    if (failNext) {
      failNext = false;
      throw ArgumentError('стикер не принят');
    }
    if (hold) return Completer<MessengerMessage>().future;
    // Сервер отдаёт echo с ПОЛНЫМ content-ом события (см.
    // `MatrixMessageService.sendMessage`) — включая разметку стикера.
    final content = <String, dynamic>{
      'msgtype': msgType,
      'body': body,
      if (stickerId != null)
        'nsg.sticker': {
          'id': stickerId,
          'alias': body.replaceAll(':', ''),
          'packId': 3,
        },
    };
    return MessengerMessage(
      matrixEventId: '\$evt-$clientTxnId',
      roomId: roomId,
      matrixRoomId: '!r:test',
      senderMessengerUserId: 42,
      senderMatrixUserId: '@self:test',
      msgType: msgType,
      body: body,
      serverTimestamp: DateTime.utc(2026, 8, 29),
      clientTxnId: clientTxnId,
      attachment: attachment,
      content: ByteData.sublistView(
        Uint8List.fromList(utf8.encode(jsonEncode(content))),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
