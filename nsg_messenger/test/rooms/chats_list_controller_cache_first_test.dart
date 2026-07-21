import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messenger_session_state.dart';
import 'package:nsg_messenger/src/rooms/chats_list_controller.dart';
import 'package:nsg_messenger/src/rooms/chats_list_state.dart';
import 'package:nsg_messenger/src/rooms/nsg_messenger_rooms.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **TASK47 cache-first**: `ChatsListController` эмитит `ChatsListReady`
/// из дискового кэша ДО (или без) успешного сетевого `list()`, когда
/// приложение оффлайн. Раньше оффлайн-`list()` мог висеть, контроллер
/// оставался в `ChatsListLoading` → экран чатов крутил «connecting».
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('chats_cache_first_test');
  });
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  RoomSummary room(int id, {DateTime? at}) => RoomSummary(
    id: id,
    name: 'R$id',
    lastMessagePreview: 'p$id',
    lastMessageAt: at,
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  /// Строит controller + rooms с подключённым кэшем и listRpc, который
  /// либо бросает, либо (по флагу `hang`) НИКОГДА не завершается — для
  /// теста «сеть зависла, показываем кэш».
  Future<
    ({
      ChatsListController controller,
      NsgMessengerRooms rooms,
      MessengerCacheStore cache,
    })
  >
  build({required Future<List<RoomSummary>> Function() listRpc}) async {
    final upstream = StreamController<MessengerEvent>.broadcast();
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
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
          }) => listRpc(),
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

    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    addTearDown(() async {
      controller.dispose();
      await rooms.dispose();
      await cache.close();
      await upstream.close();
      await stateCtl.close();
    });
    return (controller: controller, rooms: rooms, cache: cache);
  }

  final t0 = DateTime.utc(2026, 1, 1, 12);

  test(
    'оффлайн (сеть зависла): Ready из кэша ДО ответа сети',
    () async {
      // listRpc никогда не завершается — эмулирует зависший транспорт.
      final never = Completer<List<RoomSummary>>();
      final h = await build(listRpc: () => never.future);
      // Наполняем диск ДО init().
      await h.cache.putRooms([room(1, at: t0), room(2, at: t0)]);

      h.controller.init();
      // Дать микротаскам/await-ам кэша прокрутиться (сеть всё ещё висит).
      await pumpEventQueue();

      // Контроллер НЕ застрял в Loading — показал кэш.
      final state = h.controller.state;
      expect(state, isA<ChatsListReady>());
      final ready = state as ChatsListReady;
      expect(ready.rooms.map((r) => r.id).toSet(), {1, 2});
      // refreshing=true — сеть ещё в полёте поверх кэша.
      expect(ready.refreshing, isTrue);

      if (!never.isCompleted) never.complete(const []);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('оффлайн (сеть бросает): остаёмся на кэше, не Loading', () async {
    final h = await build(listRpc: () async => throw Exception('offline'));
    await h.cache.putRooms([room(3, at: t0)]);

    h.controller.init();
    await pumpEventQueue();

    // Сеть упала, но кэш уже показан → Ready (не Loading, не голый Error).
    final state = h.controller.state;
    expect(state, isA<ChatsListReady>());
    expect((state as ChatsListReady).rooms.single.id, 3);
  });

  test('онлайн: кэш показывается мгновенно, затем свежее заменяет', () async {
    // Диск: room(4); сеть вернёт room(5) — свежий список.
    final h = await build(listRpc: () async => [room(5, at: t0)]);
    await h.cache.putRooms([room(4, at: t0)]);

    h.controller.init();
    // Ждём завершения всей refresh-цепочки (сеть ответила).
    await h.controller.refresh();
    await pumpEventQueue();

    final state = h.controller.state;
    expect(state, isA<ChatsListReady>());
    final ready = state as ChatsListReady;
    // Свежий сетевой результат заменил кэш.
    expect(ready.rooms.single.id, 5);
    expect(ready.refreshing, isFalse);
  });

  test(
    'пустой кэш оффлайн: остаёмся в Loading пока сеть висит',
    () async {
      final never = Completer<List<RoomSummary>>();
      final h = await build(listRpc: () => never.future);
      // Диск пуст — кэшу нечего показать.

      h.controller.init();
      await pumpEventQueue();

      // Без кэша cache-first не эмитит Ready; контроллер ждёт сеть.
      expect(h.controller.state, isA<ChatsListLoading>());

      if (!never.isCompleted) never.complete(const []);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
