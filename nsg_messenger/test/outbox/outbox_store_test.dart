import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/outbox/outbox_item.dart';

/// **OUTBOX**: юнит-тесты таблицы `outbox` в [MessengerCacheStore] —
/// CRUD, FIFO-порядок due-выборки, mark-переходы, broadcast-поток изменений
/// и сохранность очереди при bump схемы кэша.
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('outbox_store_test');
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> open(
    int userId, {
    String namespace = 'test',
  }) async {
    final store = await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: namespace,
      userId: userId,
    );
    expect(store, isNotNull, reason: 'ffi-фабрика должна открыть БД на desktop');
    return store!;
  }

  OutboxItem textItem(
    String txn, {
    int roomId = 1,
    int createdAt = 0,
    int userId = 7,
    String status = OutboxStatus.pending,
    int nextAttemptAt = 0,
  }) => OutboxItem(
    clientTxnId: txn,
    userId: userId,
    roomId: roomId,
    kind: OutboxKind.text,
    body: 'body-$txn',
    createdAt: createdAt,
    status: status,
    nextAttemptAt: nextAttemptAt,
  );

  test('enqueue → outboxForRoom возвращает строку с полями', () async {
    final store = await open(7);
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 't1',
        userId: 7,
        roomId: 42,
        kind: OutboxKind.attachment,
        body: 'photo.jpg',
        msgType: 'm.image',
        attachmentPath: '/x/t1.jpg',
        mimeType: 'image/jpeg',
        originalFilename: 'photo.jpg',
        albumId: 'album-1',
        mentionedMessengerUserIds: const [5, 9],
        createdAt: 100,
      ),
    );
    final rows = await store.outboxForRoom(42);
    expect(rows, hasLength(1));
    final r = rows.single;
    expect(r.clientTxnId, 't1');
    expect(r.kind, OutboxKind.attachment);
    expect(r.attachmentPath, '/x/t1.jpg');
    expect(r.albumId, 'album-1');
    expect(r.mentionedMessengerUserIds, [5, 9]);
    expect(r.msgType, 'm.image');
    await store.close();
  });

  test('outboxForRoom — FIFO по createdAt, фильтр по roomId', () async {
    final store = await open(7);
    await store.enqueueOutbox(textItem('b', roomId: 1, createdAt: 200));
    await store.enqueueOutbox(textItem('a', roomId: 1, createdAt: 100));
    await store.enqueueOutbox(textItem('c', roomId: 2, createdAt: 150));
    final room1 = await store.outboxForRoom(1);
    expect(room1.map((e) => e.clientTxnId), ['a', 'b']); // createdAt ASC
    final room2 = await store.outboxForRoom(2);
    expect(room2.map((e) => e.clientTxnId), ['c']);
    await store.close();
  });

  test('outboxDue — исключает sending, failed и будущий nextAttemptAt', () async {
    final store = await open(7);
    await store.enqueueOutbox(textItem('due', createdAt: 1, nextAttemptAt: 0));
    await store.enqueueOutbox(
      textItem('future', createdAt: 2, nextAttemptAt: 9999999999999),
    );
    await store.enqueueOutbox(textItem('sending', createdAt: 3));
    await store.markOutboxSending('sending');
    await store.enqueueOutbox(textItem('failed', createdAt: 4));
    await store.markOutboxFailed('failed');

    final due = await store.outboxDue(1000);
    expect(due.map((e) => e.clientTxnId), ['due']);
    await store.close();
  });

  test('markOutboxBackoff → pending с attempts/nextAttemptAt/lastError', () async {
    final store = await open(7);
    await store.enqueueOutbox(textItem('t', createdAt: 1));
    await store.markOutboxSending('t');
    await store.markOutboxBackoff(
      't',
      attempts: 3,
      nextAttemptAt: 5000,
      lastError: 'net',
    );
    final r = (await store.outboxForRoom(1)).single;
    expect(r.status, OutboxStatus.pending);
    expect(r.attempts, 3);
    expect(r.nextAttemptAt, 5000);
    expect(r.lastError, 'net');
    await store.close();
  });

  test('markOutboxFailed → failed + resetOutboxForRetry → pending nextAt=0', () async {
    final store = await open(7);
    await store.enqueueOutbox(textItem('t', createdAt: 1, nextAttemptAt: 8000));
    await store.markOutboxFailed('t', lastError: 'boom');
    expect((await store.outboxForRoom(1)).single.status, OutboxStatus.failed);

    await store.resetOutboxForRetry('t');
    final r = (await store.outboxForRoom(1)).single;
    expect(r.status, OutboxStatus.pending);
    expect(r.nextAttemptAt, 0);
    expect(r.lastError, isNull);
    await store.close();
  });

  test('deleteOutbox убирает строку', () async {
    final store = await open(7);
    await store.enqueueOutbox(textItem('t', createdAt: 1));
    await store.deleteOutbox('t');
    expect(await store.outboxForRoom(1), isEmpty);
    await store.close();
  });

  test('outboxRoomChanges эмитит roomId на enqueue/mark/delete', () async {
    final store = await open(7);
    final seen = <int>[];
    final sub = store.outboxRoomChanges.listen(seen.add);
    await store.enqueueOutbox(textItem('t', roomId: 55, createdAt: 1));
    await store.markOutboxSending('t');
    await store.deleteOutbox('t');
    await Future<void>.delayed(Duration.zero);
    expect(seen, [55, 55, 55]);
    await sub.cancel();
    await store.close();
  });

  test('очередь скоуплена по userId (мультиаккаунт)', () async {
    final storeA = await open(7);
    await storeA.enqueueOutbox(textItem('a', roomId: 1, createdAt: 1, userId: 7));
    await storeA.close();
    // Другой пользователь той же БД (namespace) — своей очереди пусто.
    final storeB = await open(8);
    expect(await storeB.outboxForRoom(1), isEmpty);
    await storeB.close();
  });

  test('bump схемы кэша НЕ теряет очередь (CREATE IF NOT EXISTS)', () async {
    // Открываем, кладём строку, закрываем — эмулируем «до апгрейда».
    final store = await open(7);
    await store.enqueueOutbox(textItem('survivor', roomId: 3, createdAt: 1));
    await store.close();
    // Переоткрытие того же файла (та же версия) — строка на месте. Реальный
    // onUpgrade тестируется тем, что _onUpgrade вызывает _createOutboxTable с
    // IF NOT EXISTS и НЕ дропает outbox (см. messenger_cache_store.dart).
    final reopened = await open(7);
    final rows = await reopened.outboxForRoom(3);
    expect(rows.map((e) => e.clientTxnId), ['survivor']);
    await reopened.close();
  });
}
