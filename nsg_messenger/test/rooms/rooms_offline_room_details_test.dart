import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messenger_session_state.dart';
import 'package:nsg_messenger/src/rooms/nsg_messenger_rooms.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **TASK47 iter2**: read-through дискового кэша ДЕТАЛЕЙ комнаты в
/// `NsgMessengerRooms.get` — чат открывается ОФФЛАЙН (детали из кэша), а не
/// висит на сетевом `get`. Покрывает: онлайн наполняет диск; оффлайн (RPC
/// бросает) отдаёт диск; оффлайн без диска пробрасывает; зависшая сеть →
/// `.timeout` → диск.
void main() {
  late Directory tmp;
  late StreamController<MessengerEvent> upstream;
  late StreamController<MessengerSessionState> stateCtl;

  setUp(() => tmp = Directory.systemTemp.createTempSync('room_details_test'));
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  RoomDetails details(int id, {String name = 'Room'}) => RoomDetails(
    id: id,
    matrixRoomId: '!r$id:localhost',
    name: '$name $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
    participants: const [],
    totalParticipants: 0,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  // Ждём, пока best-effort (unawaited) запись деталей на диск завершится.
  Future<RoomDetails?> waitDisk(MessengerCacheStore cache, int roomId) async {
    RoomDetails? d;
    for (var i = 0; i < 50 && d == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      d = await cache.getRoomDetails(roomId);
    }
    return d;
  }

  // Harness: NsgMessengerRooms с управляемым getRpc (return / throw / hang)
  // + подключённый дисковый кэш.
  Future<
    ({
      NsgMessengerRooms rooms,
      MessengerCacheStore cache,
      void Function(RoomDetails) setGet,
      void Function(bool) setThrow,
      void Function(bool) setHang,
    })
  >
  build() async {
    upstream = StreamController<MessengerEvent>.broadcast();
    stateCtl = StreamController<MessengerSessionState>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    var getResult = details(1);
    var shouldThrow = false;
    var shouldHang = false;

    final rooms = NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) async => const [],
      getRpc: ({required int roomId}) async {
        if (shouldHang) return Completer<RoomDetails>().future; // никогда
        if (shouldThrow) throw Exception('offline');
        return getResult;
      },
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
      cache: cache,
      setGet: (RoomDetails d) => getResult = d,
      setThrow: (bool v) => shouldThrow = v,
      setHang: (bool v) => shouldHang = v,
    );
  }

  test('онлайн get() наполняет дисковый кэш деталей', () async {
    final h = await build();
    h.setGet(details(1, name: 'Online'));
    final fresh = await h.rooms.get(1);
    expect(fresh.name, 'Online 1');
    final disk = await waitDisk(h.cache, 1);
    expect(disk, isNotNull);
    expect(disk!.name, 'Online 1');
  });

  test('оффлайн (RPC бросает) → get() отдаёт детали с диска', () async {
    final h = await build();
    h.setGet(details(1, name: 'Cached'));
    await h.rooms.get(1); // наполнили диск
    expect(await waitDisk(h.cache, 1), isNotNull);

    h.rooms.invalidate(roomId: 1); // сбрасываем in-memory → следующий get на сеть
    h.setThrow(true); // сеть офлайн
    final offline = await h.rooms.get(1);
    expect(offline.name, 'Cached 1'); // из дискового кэша, не исключение
  });

  test('оффлайн без диска → get() пробрасывает ошибку', () async {
    final h = await build();
    h.setThrow(true);
    await expectLater(h.rooms.get(999), throwsA(isA<Exception>()));
  });

  test(
    'get() с зависшей сетью → таймаут → детали с диска',
    () async {
      final h = await build();
      h.setGet(details(1, name: 'Hangy'));
      await h.rooms.get(1); // наполнили диск
      expect(await waitDisk(h.cache, 1), isNotNull);

      h.rooms.invalidate(roomId: 1);
      h.setHang(true); // getRpc никогда не завершится; .timeout(6s) в get()
      final offline = await h.rooms.get(1);
      expect(offline.name, 'Hangy 1');
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('removeRoom чистит и детали комнаты', () async {
    final h = await build();
    h.setGet(details(1));
    await h.rooms.get(1);
    expect(await waitDisk(h.cache, 1), isNotNull);
    await h.cache.removeRoom(1);
    expect(await h.cache.getRoomDetails(1), isNull);
  });
}
