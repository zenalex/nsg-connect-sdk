import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/outbox/outbox_item.dart';
import 'package:nsg_messenger/src/outbox/outbox_sender.dart';

/// **OUTBOX**: юнит-тесты [OutboxSender] — классификация ошибок
/// (транзиент→бэкофф vs перманент→failed), успешная доставка текста и
/// вложения (upload→send + удаление файла), ручной retry.
void main() {
  late Directory tmp;
  late Directory outboxDir;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('outbox_sender_test');
    outboxDir = Directory('${tmp.path}/outbox')..createSync(recursive: true);
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> openStore() async {
    final store = await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: 'sender',
      userId: 7,
    );
    return store!;
  }

  OutboxSender makeSender(
    MessengerCacheStore store,
    _FakeRpc rpc, {
    int? maxAttempts,
  }) =>
      OutboxSender(
        store: store,
        rpc: rpc,
        // Быстрый бэкофф для теста (не влияет на классификацию).
        backoffSchedule: const [Duration(milliseconds: 1)],
        maxAttempts: maxAttempts,
        directoryResolver: () async => outboxDir,
      );

  test('текст: успех → sendMessage(clientTxnId) + строка удалена', () async {
    final store = await openStore();
    final rpc = _FakeRpc();
    final sender = makeSender(store, rpc);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'txt1',
        userId: 7,
        roomId: 1,
        kind: OutboxKind.text,
        body: 'hello',
        createdAt: 1,
      ),
    );
    await sender.flush();

    expect(rpc.sentBodies, ['hello']);
    expect(rpc.sentTxnIds, ['txt1']);
    expect(await store.outboxForRoom(1), isEmpty);
    await sender.dispose();
    await store.close();
  });

  test('транзиентная ошибка → pending + attempts++ + бэкофф (строка живёт)',
      () async {
    final store = await openStore();
    final rpc = _FakeRpc()..sendError = TimeoutException('net down');
    final sender = makeSender(store, rpc);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'txt1',
        userId: 7,
        roomId: 1,
        kind: OutboxKind.text,
        body: 'hi',
        createdAt: 1,
      ),
    );
    await sender.flush();

    final rows = await store.outboxForRoom(1);
    expect(rows, hasLength(1), reason: 'транзиент не удаляет строку');
    expect(rows.single.status, OutboxStatus.pending);
    expect(rows.single.attempts, 1);
    expect(rows.single.nextAttemptAt, greaterThan(0));
    expect(rows.single.lastError, contains('net down'));
    await sender.dispose();
    await store.close();
  });

  test('транзиент сверх лимита попыток → failed (не ретраим вечно)', () async {
    final store = await openStore();
    // Транзиентная (по классификатору) ошибка, которая НИКОГДА не пройдёт —
    // ровно случай несериализуемого 500 из серверной валидации.
    final rpc = _FakeRpc()..sendError = TimeoutException('net down');
    final sender = makeSender(store, rpc, maxAttempts: 2);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'txt1',
        userId: 7,
        roomId: 1,
        kind: OutboxKind.text,
        body: 'hi',
        createdAt: 1,
      ),
    );

    // Попытка 1 — ещё в пределах лимита, строка ждёт следующей.
    await sender.flush();
    var rows = await store.outboxForRoom(1);
    expect(rows.single.status, OutboxStatus.pending);
    expect(rows.single.attempts, 1);

    // Попытка 2 упирается в лимит → сдаёмся, строка становится failed
    // (в UI появляются «повторить»/«удалить» вместо вечного «отправляется»).
    await sender.flush();
    rows = await store.outboxForRoom(1);
    expect(rows, hasLength(1), reason: 'строку не теряем — юзер решит сам');
    expect(rows.single.status, OutboxStatus.failed);
    expect(rows.single.attempts, 2);
    expect(rows.single.lastError, contains('исчерпан лимит попыток'));

    await sender.dispose();
    await store.close();
  });

  test('перманентная ошибка → failed (без ретрая)', () async {
    final store = await openStore();
    final rpc = _FakeRpc()..sendError = Exception('room not found (domain)');
    final sender = makeSender(store, rpc);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'txt1',
        userId: 7,
        roomId: 1,
        kind: OutboxKind.text,
        body: 'hi',
        createdAt: 1,
      ),
    );
    await sender.flush();

    final rows = await store.outboxForRoom(1);
    expect(rows.single.status, OutboxStatus.failed);
    expect(rows.single.lastError, contains('domain'));
    await sender.dispose();
    await store.close();
  });

  test('вложение: файл → upload → send(attachment, albumId) + файл удалён',
      () async {
    final store = await openStore();
    final rpc = _FakeRpc();
    final sender = makeSender(store, rpc);

    // Персистентная копия файла (как после enqueueFile).
    final f = File('${outboxDir.path}/img1.jpg');
    await f.writeAsBytes([1, 2, 3, 4]);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'img1',
        userId: 7,
        roomId: 1,
        kind: OutboxKind.attachment,
        body: 'img.jpg',
        msgType: 'm.image',
        attachmentPath: f.path,
        mimeType: 'image/jpeg',
        originalFilename: 'img.jpg',
        albumId: 'album-9',
        createdAt: 1,
      ),
    );
    await sender.flush();

    expect(rpc.uploadCount, 1);
    expect(rpc.sentTxnIds, ['img1']);
    expect(rpc.sentAlbumIds, ['album-9']);
    expect(rpc.lastAttachment, isNotNull);
    expect(await store.outboxForRoom(1), isEmpty);
    expect(await f.exists(), isFalse, reason: 'файл удаляется на успехе');
    await sender.dispose();
    await store.close();
  });

  test('enqueueFile копирует источник в персистентный каталог', () async {
    final store = await openStore();
    final rpc = _FakeRpc()..sendError = TimeoutException('offline');
    final sender = makeSender(store, rpc);

    final src = File('${tmp.path}/source.png');
    await src.writeAsBytes([9, 9, 9]);

    await sender.enqueueFile(
      roomId: 1,
      clientTxnId: 'file1',
      sourcePath: src.path,
      msgType: 'm.image',
      mimeType: 'image/png',
      originalFilename: 'source.png',
    );
    await sender.flush(); // упадёт транзиентно, строка + файл остаются

    final rows = await store.outboxForRoom(1);
    expect(rows.single.attachmentPath, isNotNull);
    final copied = File(rows.single.attachmentPath!);
    expect(await copied.exists(), isTrue);
    expect(copied.path, isNot(src.path));
    await sender.dispose();
    await store.close();
  });

  test('retry сбрасывает failed → pending и добивает доставку', () async {
    final store = await openStore();
    final rpc = _FakeRpc()..sendError = Exception('permanent');
    final sender = makeSender(store, rpc);

    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'txt1',
        userId: 7,
        roomId: 1,
        kind: OutboxKind.text,
        body: 'hi',
        createdAt: 1,
      ),
    );
    await sender.flush();
    expect((await store.outboxForRoom(1)).single.status, OutboxStatus.failed);

    // Сеть восстановилась — ручной retry.
    rpc.sendError = null;
    await sender.retry('txt1');
    await sender.flush();
    expect(await store.outboxForRoom(1), isEmpty);
    expect(rpc.sentTxnIds, ['txt1']);
    await sender.dispose();
    await store.close();
  });
}

/// Минимальный fake [MessagesRpc] через noSuchMethod — реализуем только
/// `sendMessage` / `uploadAttachment`, остальное не вызывается дренажом.
class _FakeRpc implements MessagesRpc {
  Object? sendError;
  int uploadCount = 0;
  final List<String> sentBodies = [];
  final List<String> sentTxnIds = [];
  final List<String?> sentAlbumIds = [];
  AttachmentRef? lastAttachment;

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) async {
    uploadCount++;
    return AttachmentRef(
      mxcUrl: 'mxc://s/$originalFilename',
      mimeType: mimeType,
      sizeBytes: bytes.lengthInBytes,
      originalFilename: originalFilename,
    );
  }

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
    // TASK82: тред задачи — фейку достаточно принять параметр.
    String? threadId,
  }) async {
    if (sendError != null) throw sendError!;
    sentBodies.add(body);
    sentTxnIds.add(clientTxnId);
    sentAlbumIds.add(albumId);
    lastAttachment = attachment;
    return MessengerMessage(
      matrixEventId: 'evt-$clientTxnId',
      roomId: roomId,
      matrixRoomId: '!r:s',
      senderMatrixUserId: '@me:s',
      senderMessengerUserId: 7,
      msgType: msgType,
      body: body,
      content: ByteData(0),
      serverTimestamp: DateTime.utc(2026, 1, 1),
      clientTxnId: clientTxnId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} не нужен дренажу');

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
