import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/rooms/nsg_messenger_rooms.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// Тесты `NsgMessengerRooms`: cache hit/miss, TTL expire, LRU eviction,
/// invalidation на messageCreated event, populate-on-create, manual
/// invalidate(), expired-state очистка.
void main() {
  // ───────── fixtures ─────────

  RoomSummary summary({required int id, String? name, DateTime? lastAt}) =>
      RoomSummary(
        id: id,
        name: name ?? 'Room $id',
        unreadCount: 0,
        archived: false,
        muted: false,
        lastMessageAt: lastAt,
        roomType: RoomType.group,
      );

  RoomDetails details({required int id, String? name}) => RoomDetails(
    id: id,
    matrixRoomId: '!r$id:localhost',
    name: name ?? 'Room $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
    participants: const [],
    totalParticipants: 0,
    viewerRole: RoomMemberRole.member,
  );

  MessengerEvent messageEvent({int? roomId, String body = 'hi'}) =>
      MessengerEvent(
        eventType: MessengerEventType.messageCreated,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: roomId,
        matrixRoomId: '!fake:localhost',
        message: MessengerMessage(
          matrixEventId: '\$ev-${DateTime.now().microsecondsSinceEpoch}',
          roomId: roomId ?? 0,
          matrixRoomId: '!fake:localhost',
          senderMatrixUserId: '@bob:localhost',
          msgType: 'm.text',
          body: body,
          serverTimestamp: DateTime.now().toUtc(),
        ),
      );

  // Helper для построения rooms+bus с mock RPC + event-stream.
  ({
    NsgMessengerRooms rooms,
    StreamController<MessengerSessionState> stateCtl,
    StreamController<MessengerEvent> upstream,
    int Function() listCalls,
    int Function() getCalls,
    int Function() createDirectCalls,
    int Function() muteCalls,
    int Function() unmuteCalls,
    int Function() archiveCalls,
    int Function() unarchiveCalls,
    int Function() leaveCalls,
    int Function() availableProductsCalls,
    void Function(int v) setListReturn,
    void Function(RoomDetails d) setGetReturn,
    void Function(Object e) setMuteError,
  })
  buildRooms({
    required List<RoomSummary> initialList,
    required RoomDetails Function(int roomId) detailsFor,
  }) {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );

    var listCalls = 0;
    var getCalls = 0;
    var createDirectCalls = 0;
    var muteCalls = 0;
    var unmuteCalls = 0;
    var archiveCalls = 0;
    var unarchiveCalls = 0;
    var leaveCalls = 0;
    var availableProductsCalls = 0;
    var listResult = initialList;
    Object? muteError;

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
            listCalls++;
            return listResult;
          },
      getRpc: ({required int roomId}) async {
        getCalls++;
        return detailsFor(roomId);
      },
      createDirectRpc: ({required int peerMessengerUserId}) async {
        createDirectCalls++;
        return detailsFor(1000 + peerMessengerUserId);
      },
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => detailsFor(2000),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => detailsFor(3000),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => detailsFor(4000),
      muteRoomRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) async {
            muteCalls++;
            if (muteError != null) throw muteError!;
          },
      unmuteRoomRpc: ({required int roomId}) async {
        unmuteCalls++;
      },
      archiveRoomRpc: ({required int roomId}) async {
        archiveCalls++;
      },
      unarchiveRoomRpc: ({required int roomId}) async {
        unarchiveCalls++;
      },
      leaveRoomRpc: ({required int roomId}) async {
        leaveCalls++;
      },
      getAvailableProductsRpc: () async {
        availableProductsCalls++;
        return const [];
      },
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

    return (
      rooms: rooms,
      stateCtl: stateCtl,
      upstream: upstream,
      listCalls: () => listCalls,
      getCalls: () => getCalls,
      createDirectCalls: () => createDirectCalls,
      muteCalls: () => muteCalls,
      unmuteCalls: () => unmuteCalls,
      archiveCalls: () => archiveCalls,
      unarchiveCalls: () => unarchiveCalls,
      leaveCalls: () => leaveCalls,
      availableProductsCalls: () => availableProductsCalls,
      setListReturn: (_) {}, // unused; kept for API symmetry
      setGetReturn: (_) {},
      setMuteError: (e) {
        muteError = e;
      },
    );
  }

  // ───────── tests ─────────

  test('list: cache miss → RPC; повторный — cache hit', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 1), summary(id: 2)],
      detailsFor: (id) => details(id: id),
    );

    final r1 = await ctx.rooms.list();
    expect(r1.length, 2);
    expect(ctx.listCalls(), 1);

    final r2 = await ctx.rooms.list();
    expect(r2.length, 2);
    expect(ctx.listCalls(), 1, reason: 'cache hit');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('list: разные параметры → разные cache entry', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 1)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.list(productId: 5); // другой ключ — RPC снова.
    expect(ctx.listCalls(), 2);
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('get: cache miss → RPC; повторный — hit', () async {
    final ctx = buildRooms(
      initialList: const [],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.get(7);
    await ctx.rooms.get(7);
    expect(ctx.getCalls(), 1);
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'messageCreated event инвалидирует list + details конкретной комнаты',
    () async {
      final ctx = buildRooms(
        initialList: [summary(id: 5)],
        detailsFor: (id) => details(id: id),
      );

      await ctx.rooms.list();
      await ctx.rooms.get(5);
      await ctx.rooms.get(99); // другая комната — НЕ должна инвалидироваться.
      expect(ctx.listCalls(), 1);
      expect(ctx.getCalls(), 2);

      // Нужно подтянуть подписку EventBus на upstream.
      // В нашем setup attachWithRpcs сразу listen-ит на bus.events.
      ctx.upstream.add(messageEvent(roomId: 5));
      await Future<void>.delayed(Duration.zero);

      // list — invalidated.
      await ctx.rooms.list();
      expect(ctx.listCalls(), 2);
      // details(5) — invalidated.
      await ctx.rooms.get(5);
      expect(ctx.getCalls(), 3);
      // details(99) — НЕ invalidated.
      await ctx.rooms.get(99);
      expect(ctx.getCalls(), 3);

      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test('messageCreated event без roomId — skip, list НЕ invalidates', () async {
    final ctx = buildRooms(
      initialList: const [],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    expect(ctx.listCalls(), 1);

    ctx.upstream.add(messageEvent(roomId: null));
    await Future<void>.delayed(Duration.zero);

    await ctx.rooms.list();
    expect(
      ctx.listCalls(),
      1,
      reason: 'event без roomId — skip без invalidate',
    );

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('roomCreated event → list invalidate, details НЕ трогаем', () async {
    // TASK17 Chunk 2: caller получил доступ к новой комнате (через
    // invite-then-join или admin-add). list нужно перерисовать;
    // details не было в кэше, ничего не трогаем.
    final ctx = buildRooms(
      initialList: [summary(id: 1)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.get(1);
    expect(ctx.listCalls(), 1);
    expect(ctx.getCalls(), 1);

    ctx.upstream.add(
      MessengerEvent(
        eventType: MessengerEventType.roomCreated,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: 99,
        matrixRoomId: '!new:localhost',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await ctx.rooms.list();
    expect(ctx.listCalls(), 2, reason: 'list invalidated');
    await ctx.rooms.get(1);
    expect(ctx.getCalls(), 1, reason: 'details(1) НЕ invalidated');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'membershipJoined/Left/Removed events → details invalidate, list НЕ трогаем',
    () async {
      // TASK17 Chunk 2: participants изменились → details[X] инвалид;
      // имя/аватар/order/lastMessage в Summary не меняются.
      for (final t in [
        MessengerEventType.membershipJoined,
        MessengerEventType.membershipLeft,
        MessengerEventType.membershipRemoved,
      ]) {
        final ctx = buildRooms(
          initialList: [summary(id: 5)],
          detailsFor: (id) => details(id: id),
        );
        await ctx.rooms.list();
        await ctx.rooms.get(5);
        expect(ctx.listCalls(), 1);
        expect(ctx.getCalls(), 1);

        ctx.upstream.add(
          MessengerEvent(
            eventType: t,
            serverTimestamp: DateTime.now().toUtc(),
            roomId: 5,
            matrixRoomId: '!fake:localhost',
            membershipMatrixUserId: '@x:server',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        await ctx.rooms.list();
        expect(ctx.listCalls(), 1, reason: '$t: list НЕ invalidated');
        await ctx.rooms.get(5);
        expect(ctx.getCalls(), 2, reason: '$t: details(5) invalidated');

        await ctx.rooms.dispose();
        await ctx.upstream.close();
        await ctx.stateCtl.close();
      }
    },
  );

  test('roomUnreadChanged event → list + details invalidate', () async {
    // TASK18: counter сбрасывается через markRead (cross-device)
    // или растёт через dispatcher на новое сообщение. UI badge
    // в ChatsListScreen должен перерисоваться при следующем `list()`
    // вызове → list-cache invalidate. RoomDetails тоже содержит
    // unreadCount → details[roomId] invalidate.
    final ctx = buildRooms(
      initialList: [summary(id: 9, name: 'with-unread')],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.get(9);
    expect(ctx.listCalls(), 1);
    expect(ctx.getCalls(), 1);

    ctx.upstream.add(
      MessengerEvent(
        eventType: MessengerEventType.roomUnreadChanged,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: 9,
        matrixRoomId: '!fake:localhost',
        unreadCount: 3,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await ctx.rooms.list();
    expect(ctx.listCalls(), 2, reason: 'list invalidated (badge изменился)');
    await ctx.rooms.get(9);
    expect(
      ctx.getCalls(),
      2,
      reason: 'details(9) invalidated (unreadCount в RoomDetails)',
    );

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('messageDeleted event → list + details invalidate (B23)', () async {
    // **B23**: redaction может изменить превью списка чатов (если удалено
    // последнее сообщение комнаты). Сервер пересчитывает
    // Room.lastMessageBody и эмитит messageDeleted; SDK инвалидирует
    // list/details cache, чтобы следующий list() подтянул свежее превью.
    final ctx = buildRooms(
      initialList: [summary(id: 7, name: 'with-redaction')],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.get(7);
    expect(ctx.listCalls(), 1);
    expect(ctx.getCalls(), 1);

    ctx.upstream.add(
      MessengerEvent(
        eventType: MessengerEventType.messageDeleted,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: 7,
        matrixRoomId: '!fake:localhost',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await ctx.rooms.list();
    expect(
      ctx.listCalls(),
      2,
      reason: 'list invalidated (превью могло измениться)',
    );
    await ctx.rooms.get(7);
    expect(ctx.getCalls(), 2, reason: 'details(7) invalidated');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('messageDeleted без roomId → skip, no invalidate (B23)', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 1)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    expect(ctx.listCalls(), 1);

    ctx.upstream.add(
      MessengerEvent(
        eventType: MessengerEventType.messageDeleted,
        serverTimestamp: DateTime.now().toUtc(),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await ctx.rooms.list();
    expect(ctx.listCalls(), 1, reason: 'no invalidate без roomId');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'roomUnreadChanged без roomId → debugPrint warning, no invalidate',
    () async {
      final ctx = buildRooms(
        initialList: [summary(id: 1)],
        detailsFor: (id) => details(id: id),
      );
      await ctx.rooms.list();
      expect(ctx.listCalls(), 1);

      // Server bug — нет roomId. Reactor должен skip-нуть, без crash.
      ctx.upstream.add(
        MessengerEvent(
          eventType: MessengerEventType.roomUnreadChanged,
          serverTimestamp: DateTime.now().toUtc(),
          unreadCount: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await ctx.rooms.list();
      expect(ctx.listCalls(), 1, reason: 'no invalidate без roomId');
      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test('roomStateChanged event → list + details invalidate', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 5)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.get(5);
    expect(ctx.listCalls(), 1);
    expect(ctx.getCalls(), 1);

    ctx.upstream.add(
      MessengerEvent(
        eventType: MessengerEventType.roomStateChanged,
        serverTimestamp: DateTime.now().toUtc(),
        roomId: 5,
        matrixRoomId: '!fake:localhost',
        roomStateField: 'name',
        roomStateNewValue: 'Renamed Room',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await ctx.rooms.list();
    expect(ctx.listCalls(), 2, reason: 'list invalidated (name в Summary)');
    await ctx.rooms.get(5);
    expect(
      ctx.getCalls(),
      2,
      reason: 'details(5) invalidated (name в Details)',
    );

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('createDirect: invalidates list, populates details cache', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 1)],
      detailsFor: (id) => details(id: id, name: 'D-$id'),
    );
    await ctx.rooms.list();
    expect(ctx.listCalls(), 1);

    final result = await ctx.rooms.createDirect(42);
    // createDirectRpc returns details(1000+42) → id = 1042.
    expect(result.id, 1042);
    expect(ctx.createDirectCalls(), 1);

    // get(1042) сразу после create — должен быть из cache, без RPC.
    await ctx.rooms.get(1042);
    expect(ctx.getCalls(), 0, reason: 'populate-on-create');

    // list — invalidated.
    await ctx.rooms.list();
    expect(ctx.listCalls(), 2);

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  // Regression «новый чат невидим до reload»: createDirect должен
  // инжектить локальный roomCreated в EventBus, чтобы chat-list (и любой
  // другой подписчик) реактивно обновился у создателя без перезагрузки.
  test('createDirect: эмитит локальный roomCreated на EventBus', () async {
    final ctx = buildRooms(
      initialList: const [],
      detailsFor: (id) => details(id: id),
    );
    final seen = <MessengerEvent>[];
    final sub = ctx.rooms.eventBus.events.listen(seen.add);
    await Future<void>.delayed(Duration.zero);

    final result = await ctx.rooms.createDirect(42);
    await Future<void>.delayed(Duration.zero);

    final created = seen
        .where((e) => e.eventType == MessengerEventType.roomCreated)
        .toList();
    expect(created, hasLength(1), reason: 'ровно один локальный roomCreated');
    expect(created.single.roomId, result.id);

    await sub.cancel();
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'invalidate(roomId): точечная инвалидация details, list не трогаем',
    () async {
      final ctx = buildRooms(
        initialList: [summary(id: 1)],
        detailsFor: (id) => details(id: id),
      );
      await ctx.rooms.list();
      await ctx.rooms.get(1);
      expect(ctx.listCalls(), 1);
      expect(ctx.getCalls(), 1);

      ctx.rooms.invalidate(roomId: 1);

      await ctx.rooms.list();
      expect(ctx.listCalls(), 1, reason: 'list не invalidated');
      await ctx.rooms.get(1);
      expect(ctx.getCalls(), 2, reason: 'details invalidated');

      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test('invalidate() без аргумента: clear all', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 1)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.get(1);
    ctx.rooms.invalidate();
    await ctx.rooms.list();
    await ctx.rooms.get(1);
    expect(ctx.listCalls(), 2);
    expect(ctx.getCalls(), 2);

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  // ─── TASK42 ─────────────────────────────────────────────────────────

  test(
    'muteRoom: invalidates list + details + RPC called с durations',
    () async {
      final ctx = buildRooms(
        initialList: [summary(id: 5)],
        detailsFor: (id) => details(id: id),
      );
      await ctx.rooms.list();
      await ctx.rooms.get(5);
      expect(ctx.listCalls(), 1);
      expect(ctx.getCalls(), 1);

      final until = DateTime.utc(2030, 1, 1);
      await ctx.rooms.muteRoom(roomId: 5, mutedUntil: until);
      expect(ctx.muteCalls(), 1);

      // Cache invalidated — следующий list/get идут в RPC.
      await ctx.rooms.list();
      expect(ctx.listCalls(), 2);
      await ctx.rooms.get(5);
      expect(ctx.getCalls(), 2);

      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test('unmuteRoom / archiveRoom / unarchiveRoom: invalidate cache', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 5)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    expect(ctx.listCalls(), 1);

    await ctx.rooms.unmuteRoom(5);
    expect(ctx.unmuteCalls(), 1);
    await ctx.rooms.list();
    expect(ctx.listCalls(), 2, reason: 'unmute invalidated');

    await ctx.rooms.archiveRoom(5);
    expect(ctx.archiveCalls(), 1);
    await ctx.rooms.list();
    expect(ctx.listCalls(), 3, reason: 'archive invalidated');

    await ctx.rooms.unarchiveRoom(5);
    expect(ctx.unarchiveCalls(), 1);
    await ctx.rooms.list();
    expect(ctx.listCalls(), 4, reason: 'unarchive invalidated');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('leaveRoom: invalidates list + removes details', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 5)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    await ctx.rooms.get(5);
    expect(ctx.listCalls(), 1);
    expect(ctx.getCalls(), 1);

    await ctx.rooms.leaveRoom(5);
    expect(ctx.leaveCalls(), 1);

    await ctx.rooms.list();
    expect(ctx.listCalls(), 2);
    await ctx.rooms.get(5);
    expect(ctx.getCalls(), 2);

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('availableProducts: вызывается RPC, без cache', () async {
    final ctx = buildRooms(
      initialList: const [],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.availableProducts();
    await ctx.rooms.availableProducts();
    expect(
      ctx.availableProductsCalls(),
      2,
      reason: 'NsgMessengerRooms не кэширует availableProducts на TASK42',
    );
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'list: includeArchived в cache key — разные tab-ы → разные RPC',
    () async {
      // `_listEntry` — single-entry cache (хранит последний результат).
      // Любая смена ключа → cache miss → новый RPC. Тест проверяет
      // что includeArchived включается в ключ (без этого `archived` tab
      // показывал бы closet `active`-результат).
      final ctx = buildRooms(
        initialList: [summary(id: 1)],
        detailsFor: (id) => details(id: id),
      );
      await ctx.rooms.list();
      expect(ctx.listCalls(), 1);
      // Повторный с тем же null — cache hit.
      await ctx.rooms.list();
      expect(ctx.listCalls(), 1);
      // Сменили на true — cache miss.
      await ctx.rooms.list(includeArchived: true);
      expect(ctx.listCalls(), 2);
      // false vs null — разные keys (defensive — чтобы explicit false не
      // считался эквивалентом null).
      await ctx.rooms.list(includeArchived: false);
      expect(ctx.listCalls(), 3);

      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test('list: search в cache key — разные query → разные RPC', () async {
    final ctx = buildRooms(
      initialList: [summary(id: 1)],
      detailsFor: (id) => details(id: id),
    );
    await ctx.rooms.list();
    expect(ctx.listCalls(), 1);
    await ctx.rooms.list(); // same null-search → cache hit.
    expect(ctx.listCalls(), 1);
    await ctx.rooms.list(search: 'foo');
    expect(ctx.listCalls(), 2);
    await ctx.rooms.list(search: 'bar');
    expect(ctx.listCalls(), 3, reason: 'разный search → разные cache keys');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'roomMembershipUpdated event → list + details invalidate (privacy boundary)',
    () async {
      // TASK42: server эмитит ТОЛЬКО в channel viewer-а; для нас это
      // значит — cross-device update от alice device A прилетает
      // alice device B и обновляет UI без user-action.
      final ctx = buildRooms(
        initialList: [summary(id: 7)],
        detailsFor: (id) => details(id: id),
      );
      await ctx.rooms.list();
      await ctx.rooms.get(7);
      expect(ctx.listCalls(), 1);
      expect(ctx.getCalls(), 1);

      ctx.upstream.add(
        MessengerEvent(
          eventType: MessengerEventType.roomMembershipUpdated,
          serverTimestamp: DateTime.now().toUtc(),
          roomId: 7,
          matrixRoomId: '!fake:localhost',
          membershipChangedField: 'mutedUntil',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await ctx.rooms.list();
      expect(ctx.listCalls(), 2, reason: 'list invalidated (muted в Summary)');
      await ctx.rooms.get(7);
      expect(ctx.getCalls(), 2, reason: 'details invalidated');

      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test(
    'roomMembershipUpdated без roomId → debugPrint warning, no invalidate',
    () async {
      final ctx = buildRooms(
        initialList: [summary(id: 1)],
        detailsFor: (id) => details(id: id),
      );
      await ctx.rooms.list();
      expect(ctx.listCalls(), 1);

      ctx.upstream.add(
        MessengerEvent(
          eventType: MessengerEventType.roomMembershipUpdated,
          serverTimestamp: DateTime.now().toUtc(),
          membershipChangedField: 'archived',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await ctx.rooms.list();
      expect(ctx.listCalls(), 1, reason: 'no invalidate без roomId');

      await ctx.rooms.dispose();
      await ctx.upstream.close();
      await ctx.stateCtl.close();
    },
  );

  test('LRU: больше kRoomDetailsLruCapacity → старые evictятся', () async {
    final ctx = buildRooms(
      initialList: const [],
      detailsFor: (id) => details(id: id),
    );
    // Запросим capacity+5 разных details → первые 5 должны evict-нуться.
    for (var i = 1; i <= kRoomDetailsLruCapacity + 5; i++) {
      await ctx.rooms.get(i);
    }
    expect(ctx.getCalls(), kRoomDetailsLruCapacity + 5);
    // Перечитываем первые 5 → они evicted, должны быть RPC.
    for (var i = 1; i <= 5; i++) {
      await ctx.rooms.get(i);
    }
    expect(ctx.getCalls(), kRoomDetailsLruCapacity + 5 + 5);
    // Перечитываем последние kRoomDetailsLruCapacity — все cache hit.
    final getsBefore = ctx.getCalls();
    for (var i = 11; i <= kRoomDetailsLruCapacity + 5; i++) {
      await ctx.rooms.get(i);
    }
    // Повторное чтение последних — без новых RPC.
    expect(ctx.getCalls(), getsBefore, reason: 'recently-used cache hit');

    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });
}
