import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/rooms/nsg_messenger_rooms.dart';
import 'package:nsg_messenger/src/messenger_session_state.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **TASK47 iter1**: read-through дискового кэша в `NsgMessengerRooms.list`
/// + мёрж realtime-событий. Проверяет: онлайн — наполняет диск; оффлайн
/// (RPC бросает) — отдаёт диск; messageCreated-событие обновляет диск.
void main() {
  late Directory tmp;
  late StreamController<MessengerEvent> upstream;
  late StreamController<MessengerSessionState> stateCtl;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('rooms_cache_test');
  });
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  RoomSummary room(int id, {DateTime? at, String name = 'R'}) => RoomSummary(
    id: id,
    name: '$name$id',
    lastMessagePreview: 'p$id',
    lastMessageAt: at,
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  // Строит NsgMessengerRooms с управляемым listRpc (может бросать) и
  // подключённым дисковым кэшем.
  Future<
    ({
      NsgMessengerRooms rooms,
      void Function(List<RoomSummary>) setList,
      void Function(bool) setThrow,
      MessengerCacheStore cache,
    })
  >
  build() async {
    upstream = StreamController<MessengerEvent>.broadcast();
    stateCtl = StreamController<MessengerSessionState>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    var listResult = <RoomSummary>[];
    var shouldThrow = false;

    final rooms = NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) async {
            if (shouldThrow) throw Exception('offline');
            return listResult;
          },
      getRpc: ({required int roomId}) async => throw UnimplementedError(),
      createDirectRpc: ({required int peerMessengerUserId}) async =>
          throw UnimplementedError(),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => throw UnimplementedError(),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => throw UnimplementedError(),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => throw UnimplementedError(),
      muteRoomRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) async {},
      unmuteRoomRpc: ({required int roomId}) async {},
      archiveRoomRpc: ({required int roomId}) async {},
      unarchiveRoomRpc: ({required int roomId}) async {},
      leaveRoomRpc: ({required int roomId}) async {},
      getAvailableProductsRpc: () async => const [],
      kickUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      banUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      unbanUserRpc:
          ({required int roomId, required int targetMessengerUserId}) async {},
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) async {},
      listBannedUsersRpc: ({required int roomId}) async => const [],
      eventBus: bus,
    );

    final cache = (await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: 'test',
      userId: 1,
    ))!;
    rooms.attachCache(cache);
    addTearDown(() async {
      await rooms.dispose();
      await cache.close();
      await upstream.close();
      await stateCtl.close();
    });

    return (
      rooms: rooms,
      setList: (v) => listResult = v,
      setThrow: (v) => shouldThrow = v,
      cache: cache,
    );
  }

  // Как build(), но listRpc НИКОГДА не завершается (Completer без
  // complete) — эмулирует зависший оффлайн-транспорт. Проверяет, что
  // .timeout() в list() спасает fallback на диск.
  Future<({NsgMessengerRooms rooms, MessengerCacheStore cache})>
  buildHanging() async {
    upstream = StreamController<MessengerEvent>.broadcast();
    stateCtl = StreamController<MessengerSessionState>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final never = Completer<List<RoomSummary>>();
    final rooms = NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) => never.future,
      getRpc: ({required int roomId}) async => throw UnimplementedError(),
      createDirectRpc: ({required int peerMessengerUserId}) async =>
          throw UnimplementedError(),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => throw UnimplementedError(),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => throw UnimplementedError(),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => throw UnimplementedError(),
      muteRoomRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) async {},
      unmuteRoomRpc: ({required int roomId}) async {},
      archiveRoomRpc: ({required int roomId}) async {},
      unarchiveRoomRpc: ({required int roomId}) async {},
      leaveRoomRpc: ({required int roomId}) async {},
      getAvailableProductsRpc: () async => const [],
      kickUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      banUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      unbanUserRpc:
          ({required int roomId, required int targetMessengerUserId}) async {},
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) async {},
      listBannedUsersRpc: ({required int roomId}) async => const [],
      eventBus: bus,
    );
    final cache = (await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: 'test',
      userId: 1,
    ))!;
    rooms.attachCache(cache);
    addTearDown(() async {
      await rooms.dispose();
      await cache.close();
      await upstream.close();
      await stateCtl.close();
      if (!never.isCompleted) never.complete(const []);
    });
    return (rooms: rooms, cache: cache);
  }

  final t0 = DateTime.utc(2026, 1, 1, 12);

  test('онлайн list() наполняет диск', () async {
    final h = await build();
    h.setList([room(1, at: t0), room(2, at: t0)]);
    final fresh = await h.rooms.list();
    expect(fresh.map((r) => r.id).toSet(), {1, 2});
    // putRooms — unawaited; поллим до завершения (детерминированно, без
    // фикс-делея — тот флейкал под нагрузкой полного сюита).
    await _waitFor(() async => (await h.cache.getRooms()).length == 2);
    expect((await h.cache.getRooms()).map((r) => r.id).toSet(), {1, 2});
  });

  test('оффлайн (RPC бросает) → list() отдаёт диск', () async {
    final h = await build();
    // Сначала наполняем диск напрямую.
    await h.cache.putRooms([room(3, at: t0), room(4, at: t0)]);
    h.setThrow(true);
    // in-memory TTL пуст → идёт в RPC → бросает → fallback на диск.
    final offline = await h.rooms.list();
    expect(offline.map((r) => r.id).toSet(), {3, 4});
  });

  test('оффлайн без диска → пробрасывает ошибку', () async {
    final h = await build();
    h.setThrow(true);
    await expectLater(h.rooms.list(), throwsA(isA<Exception>()));
  });

  test('cachedRoomsOrEmpty читает диск без сети', () async {
    final h = await build();
    await h.cache.putRooms([room(7, at: t0), room(8, at: t0)]);
    // Даже если сеть «висла бы» — этот метод её не трогает.
    h.setThrow(true);
    final cached = await h.rooms.cachedRoomsOrEmpty();
    expect(cached.map((r) => r.id).toSet(), {7, 8});
  });

  test('cachedRoomsOrEmpty без кэша → пустой список', () async {
    // rooms без attachCache — свежий экземпляр.
    final upstream2 = StreamController<MessengerEvent>.broadcast();
    final stateCtl2 = StreamController<MessengerSessionState>.broadcast();
    final bus2 = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream2.stream,
      sessionStateStream: stateCtl2.stream,
    );
    final rooms = NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) async => const <RoomSummary>[],
      getRpc: ({required int roomId}) async => throw UnimplementedError(),
      createDirectRpc: ({required int peerMessengerUserId}) async =>
          throw UnimplementedError(),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => throw UnimplementedError(),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => throw UnimplementedError(),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => throw UnimplementedError(),
      muteRoomRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) async {},
      unmuteRoomRpc: ({required int roomId}) async {},
      archiveRoomRpc: ({required int roomId}) async {},
      unarchiveRoomRpc: ({required int roomId}) async {},
      leaveRoomRpc: ({required int roomId}) async {},
      getAvailableProductsRpc: () async => const [],
      kickUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      banUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      unbanUserRpc:
          ({required int roomId, required int targetMessengerUserId}) async {},
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) async {},
      listBannedUsersRpc: ({required int roomId}) async => const [],
      eventBus: bus2,
    );
    addTearDown(() async {
      await rooms.dispose();
      await upstream2.close();
      await stateCtl2.close();
    });
    expect(await rooms.cachedRoomsOrEmpty(), isEmpty);
  });

  test(
    'list() с зависшей сетью → таймаут → fallback на диск',
    () async {
      final h = await buildHanging();
      await h.cache.putRooms([room(9, at: t0)]);
      // listRpc никогда не завершится; .timeout(6s) в list() бросит
      // TimeoutException → catch отдаст диск. Ждём реальный таймаут.
      final offline = await h.rooms.list();
      expect(offline.single.id, 9);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('messageCreated-событие обновляет диск', () async {
    final h = await build();
    await h.cache.putRooms([room(5, at: t0)]);
    final later = t0.add(const Duration(hours: 1));
    upstream.add(
      MessengerEvent(
        eventType: MessengerEventType.messageCreated,
        serverTimestamp: later,
        roomId: 5,
        message: MessengerMessage(
          matrixEventId: 'evt1',
          roomId: 5,
          matrixRoomId: '!5:l',
          senderMessengerUserId: 2,
          senderMatrixUserId: '@u:l',
          msgType: 'm.text',
          body: 'новое',
          serverTimestamp: later,
        ),
      ),
    );
    await _waitFor(
      () async =>
          (await h.cache.getRooms()).single.lastMessagePreview == 'новое',
    );
    final cachedRoom = (await h.cache.getRooms()).single;
    expect(cachedRoom.lastMessagePreview, 'новое');
    expect(cachedRoom.unreadCount, 1);
    expect((await h.cache.getMessages(5)).single.matrixEventId, 'evt1');
  });
}

/// Поллит [cond] до true (или таймаут ~3с) — детерминированная замена
/// фикс-делею для unawaited disk-merge (тот флейкал под нагрузкой).
Future<void> _waitFor(Future<bool> Function() cond) async {
  for (var i = 0; i < 150; i++) {
    if (await cond()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition not met within timeout');
}
