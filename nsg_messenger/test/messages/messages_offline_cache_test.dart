import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';

/// **TASK47 iter1**: read-through дискового кэша в [MessagesController.init]
/// — оффлайн-история, наполнение кэша, gap-стратегия.
void main() {
  const roomId = 55;
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('msgs_cache_test');
  });
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> openCache() async =>
      (await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 1,
      ))!;

  MessengerMessage msg(String evt, {required DateTime at, String body = 'm'}) =>
      MessengerMessage(
        matrixEventId: evt,
        roomId: roomId,
        matrixRoomId: '!$roomId:l',
        senderMessengerUserId: 99,
        senderMatrixUserId: '@peer:l',
        msgType: 'm.text',
        body: body,
        serverTimestamp: at,
      );

  MessagesController make(_FakeRpc rpc, MessengerCacheStore cache) =>
      MessagesController(
        roomId: roomId,
        rpc: rpc,
        events: const Stream<MessengerEvent>.empty(),
        selfMessengerUserId: 1,
        selfMatrixUserId: '@self:l',
        cache: cache,
      );

  final t0 = DateTime.utc(2026, 1, 1, 12);

  test('оффлайн: кэш показан, ошибка listMessages не роняет в Error', () async {
    final cache = await openCache();
    addTearDown(cache.close);
    await cache.putMessages(roomId, [
      msg('a', at: t0),
      msg('b', at: t0.add(const Duration(minutes: 1))),
    ]);
    final rpc = _FakeRpc()..listThrows = true;
    final c = make(rpc, cache);
    await c.init();

    expect(c.state, isA<MessagesReady>());
    final st = c.state as MessagesReady;
    expect(st.messages.map((m) => m.matrixEventId).toList(), ['a', 'b']);
    await c.dispose();
  });

  test('онлайн: сервер наполняет кэш', () async {
    final cache = await openCache();
    addTearDown(cache.close);
    final rpc = _FakeRpc()
      ..page = MessengerMessageListPage(
        messages: [
          msg('x', at: t0),
          msg('y', at: t0.add(const Duration(minutes: 1))),
        ],
      );
    final c = make(rpc, cache);
    await c.init();
    await _waitFor(() async => (await cache.getMessages(roomId)).length == 2);

    expect(
      (await cache.getMessages(roomId)).map((m) => m.matrixEventId).toList(),
      ['x', 'y'],
    );
    await c.dispose();
  });

  test('gap: серверная страница не смыкается с кэшем → кэш сброшен', () async {
    final cache = await openCache();
    addTearDown(cache.close);
    // Старое кэшированное сообщение.
    await cache.putMessages(roomId, [msg('old', at: t0)]);
    // Сервер отдаёт НАМНОГО более свежую страницу (за оффлайн пришло много).
    final rpc = _FakeRpc()
      ..page = MessengerMessageListPage(
        messages: [msg('new', at: t0.add(const Duration(days: 10)))],
      );
    final c = make(rpc, cache);
    await c.init();
    await _waitFor(() async {
      final m = await cache.getMessages(roomId);
      return m.length == 1 && m.single.matrixEventId == 'new';
    });

    // 'old' сброшен (разрыв), в кэше только свежая страница.
    expect(
      (await cache.getMessages(roomId)).map((m) => m.matrixEventId).toList(),
      ['new'],
    );
    await c.dispose();
  });

  test('overlap: пересечение страниц → merge без сброса', () async {
    final cache = await openCache();
    addTearDown(cache.close);
    await cache.putMessages(roomId, [
      msg('a', at: t0),
      msg('b', at: t0.add(const Duration(minutes: 1))),
    ]);
    // Сервер отдаёт b (пересечение) + c (новее) → без gap.
    final rpc = _FakeRpc()
      ..page = MessengerMessageListPage(
        messages: [
          msg('b', at: t0.add(const Duration(minutes: 1))),
          msg('c', at: t0.add(const Duration(minutes: 2))),
        ],
      );
    final c = make(rpc, cache);
    await c.init();
    await _waitFor(() async => (await cache.getMessages(roomId)).length == 3);

    // a сохранён (нет сброса), b/c домержены.
    expect(
      (await cache.getMessages(roomId)).map((m) => m.matrixEventId).toList(),
      ['a', 'b', 'c'],
    );
    await c.dispose();
  });
}

/// Поллит [cond] до true (или таймаут ~3с) — детерминированная замена
/// фикс-делею для unawaited reconcile-записи в кэш.
Future<void> _waitFor(Future<bool> Function() cond) async {
  for (var i = 0; i < 150; i++) {
    if (await cond()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition not met within timeout');
}

class _FakeRpc implements MessagesRpc {
  bool listThrows = false;
  MessengerMessageListPage page = MessengerMessageListPage(messages: const []);

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async {
    if (listThrows) throw Exception('offline');
    return page;
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
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeRpc: ${invocation.memberName}');

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
