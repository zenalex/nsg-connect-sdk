import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';
import 'package:nsg_messenger/src/outbox/outbox_item.dart';

const _kRoomId = 101;
const _kSelfUid = 42;
const _kSelfMxid = '@self:test';

/// **OUTBOX**: реконсиляция очереди с оптимистичным UI в [MessagesController]:
/// строки очереди рендерятся pending-бабблами; реальное событие с тем же
/// `clientTxnId` промоутит их (без дубля); удаление строки на успехе не
/// сносит уже-промоутнутый sent-баббл.
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('outbox_recon_test');
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> openStore() async {
    final store = await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: 'recon',
      userId: _kSelfUid,
    );
    return store!;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  MessagesController makeController(
    MessengerCacheStore store,
    Stream<MessengerEvent> events,
  ) => MessagesController(
    roomId: _kRoomId,
    rpc: _FakeRpc(),
    events: events,
    selfMessengerUserId: _kSelfUid,
    selfMatrixUserId: _kSelfMxid,
    cache: store,
  );

  test('строка очереди рендерится pending-бабблом при init', () async {
    final store = await openStore();
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.text,
        body: 'queued msg',
        createdAt: 1,
      ),
    );
    final events = StreamController<MessengerEvent>.broadcast();
    final c = makeController(store, events.stream);
    await c.init();
    await settle();

    final state = c.state as MessagesReady;
    final bubble = state.messages.firstWhere((m) => m.clientTxnId == 'q1');
    expect(bubble.isPending, isTrue);
    expect(bubble.body, 'queued msg');
    await c.dispose();
    await events.close();
    await store.close();
  });

  test('реальное событие с тем же clientTxnId промоутит баббл (без дубля)',
      () async {
    final store = await openStore();
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.text,
        body: 'queued',
        createdAt: 1,
      ),
    );
    final events = StreamController<MessengerEvent>.broadcast();
    final c = makeController(store, events.stream);
    await c.init();
    await settle();
    expect(
      (c.state as MessagesReady).messages.where((m) => m.clientTxnId == 'q1'),
      hasLength(1),
    );

    // Реальное сообщение приезжает через sync (echo clientTxnId).
    events.add(
      _event(_msg(eventId: 'evt-q1', clientTxnId: 'q1', body: 'queued')),
    );
    await settle();

    final withTxn = (c.state as MessagesReady).messages
        .where((m) => m.clientTxnId == 'q1')
        .toList();
    expect(withTxn, hasLength(1), reason: 'нет дубля');
    expect(withTxn.single.isSent, isTrue, reason: 'промоутнут в sent');
    expect(withTxn.single.matrixEventId, 'evt-q1');

    // Sender удаляет строку на успехе → sent-баббл остаётся (не снимается).
    await store.deleteOutbox('q1');
    await settle();
    final after = (c.state as MessagesReady).messages
        .where((m) => m.clientTxnId == 'q1')
        .toList();
    expect(after, hasLength(1));
    expect(after.single.isSent, isTrue);
    await c.dispose();
    await events.close();
    await store.close();
  });

  test('failed-строка рендерится failed-бабблом; discard снимает его',
      () async {
    final store = await openStore();
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.text,
        body: 'boom',
        status: OutboxStatus.failed,
        lastError: 'permanent',
        createdAt: 1,
      ),
    );
    final events = StreamController<MessengerEvent>.broadcast();
    final c = makeController(store, events.stream);
    await c.init();
    await settle();
    final b = (c.state as MessagesReady).messages
        .firstWhere((m) => m.clientTxnId == 'q1');
    expect(b.isFailed, isTrue);

    // Discard → строка ушла → баббл снимается через outboxRoomChanges.
    await store.deleteOutbox('q1');
    await settle();
    expect(
      (c.state as MessagesReady).messages.where((m) => m.clientTxnId == 'q1'),
      isEmpty,
    );
    await c.dispose();
    await events.close();
    await store.close();
  });

  test('новый enqueue появляется бабблом вживую (подписка на изменения)',
      () async {
    final store = await openStore();
    final events = StreamController<MessengerEvent>.broadcast();
    final c = makeController(store, events.stream);
    await c.init();
    await settle();
    expect((c.state as MessagesReady).messages, isEmpty);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q2',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.text,
        body: 'live',
        createdAt: 2,
      ),
    );
    await settle();
    expect(
      (c.state as MessagesReady).messages.where((m) => m.clientTxnId == 'q2'),
      hasLength(1),
    );
    await c.dispose();
    await events.close();
    await store.close();
  });
}

MessengerMessage _msg({
  required String eventId,
  String? clientTxnId,
  String body = 'm',
}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: _kRoomId,
  matrixRoomId: '!r:test',
  senderMessengerUserId: _kSelfUid,
  senderMatrixUserId: _kSelfMxid,
  msgType: 'm.text',
  body: body,
  content: ByteData(0),
  serverTimestamp: DateTime.utc(2026, 1, 1),
  clientTxnId: clientTxnId,
);

MessengerEvent _event(MessengerMessage m) => MessengerEvent(
  eventType: MessengerEventType.messageCreated,
  serverTimestamp: m.serverTimestamp,
  roomId: _kRoomId,
  matrixRoomId: m.matrixRoomId,
  message: m,
);

/// listMessages → пустая страница; seed-RPC → пусто; остальное не вызывается.
class _FakeRpc implements MessagesRpc {
  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(
    messages: const [],
    nextToken: null,
    prevToken: null,
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
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');

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
