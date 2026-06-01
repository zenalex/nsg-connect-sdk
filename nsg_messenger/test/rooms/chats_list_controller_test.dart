import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/rooms/chats_list_controller.dart';
import 'package:nsg_messenger/src/rooms/chats_list_state.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// Тесты `ChatsListController` (TASK14 Chunk 1):
///   * initial loading → ready на success;
///   * realtime event → refresh, lastKnown сохранён в Ready(refreshing=true);
///   * первый refresh падает → Error с lastKnown=null;
///   * recurring refresh падает → Error с lastKnown=previous (UX «онлайн
///     потеряли, показываем кэш»);
///   * concurrent refresh debouncing — не плодим RPC;
///   * MessengerSessionState.active → triggers refresh;
///   * loadMore() — no-op (точка подсадки TASK42);
///   * dispose() — нет notifyListeners после.
void main() {
  // ───────── fixtures ─────────

  RoomSummary summary({required int id, String? name}) => RoomSummary(
    id: id,
    name: name ?? 'Room $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  MessengerEvent eventFor({int roomId = 1}) => MessengerEvent(
    eventType: MessengerEventType.messageCreated,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: roomId,
    matrixRoomId: '!fake:localhost',
  );

  /// Helper — собирает `NsgMessengerRooms` (через `attachWithRpcs`)
  /// + `ChatsListController` с одним и тем же EventBus и
  /// session-state-stream. Возвращает controller + способ толкать
  /// events / state-transitions / поменять list-результат.
  ({
    ChatsListController controller,
    NsgMessengerRooms rooms,
    StreamController<MessengerEvent> upstream,
    StreamController<MessengerSessionState> stateCtl,
    int Function() listCalls,
    void Function(List<RoomSummary> r) setListResult,
    void Function(Object e) setListError,
  })
  buildController({List<RoomSummary> initialList = const []}) {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );

    var listCalls = 0;
    var listResult = initialList;
    Object? listError;

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
            if (listError != null) throw listError!;
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

    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );

    return (
      controller: controller,
      rooms: rooms,
      upstream: upstream,
      stateCtl: stateCtl,
      listCalls: () => listCalls,
      setListResult: (r) {
        listResult = r;
        listError = null;
      },
      setListError: (e) {
        listError = e;
      },
    );
  }

  /// Variant — позволяет inject custom muteRpc для проверки optimistic
  /// + revert в TASK42 Chunk 2.
  ({
    ChatsListController controller,
    NsgMessengerRooms rooms,
    StreamController<MessengerEvent> upstream,
    StreamController<MessengerSessionState> stateCtl,
  })
  buildControllerWithMuteRpc({
    required List<RoomSummary> initialList,
    required Future<void> Function({
      required int roomId,
      DateTime? mutedUntil,
      int? muteForSeconds,
    })
    muteRpc,
  }) {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
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
          }) async => initialList,
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
      muteRoomRpc: muteRpc,
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
    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    return (
      controller: controller,
      rooms: rooms,
      upstream: upstream,
      stateCtl: stateCtl,
    );
  }

  /// Variant — для leaveRoom error-revert теста.
  ({
    ChatsListController controller,
    NsgMessengerRooms rooms,
    StreamController<MessengerEvent> upstream,
    StreamController<MessengerSessionState> stateCtl,
  })
  buildControllerWithLeaveRpc({
    required List<RoomSummary> initialList,
    required Future<void> Function({required int roomId}) leaveRpc,
  }) {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
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
          }) async => initialList,
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
      leaveRoomRpc: leaveRpc,
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
    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    return (
      controller: controller,
      rooms: rooms,
      upstream: upstream,
      stateCtl: stateCtl,
    );
  }

  Future<void> teardown(
    ({
      ChatsListController controller,
      NsgMessengerRooms rooms,
      StreamController<MessengerEvent> upstream,
      StreamController<MessengerSessionState> stateCtl,
      int Function() listCalls,
      void Function(List<RoomSummary> r) setListResult,
      void Function(Object e) setListError,
    })
    ctx,
  ) async {
    ctx.controller.dispose();
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  }

  // Удобная поездка через несколько микротасков, чтобы async chain
  // (init → list → emit) успел разрешиться.
  Future<void> tick() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  // ───────── tests ─────────

  test('init → Loading → Ready(rooms=initial)', () async {
    final ctx = buildController(initialList: [summary(id: 1), summary(id: 2)]);
    expect(ctx.controller.state, isA<ChatsListLoading>());

    ctx.controller.init();
    await tick();

    expect(ctx.controller.state, isA<ChatsListReady>());
    final s = ctx.controller.state as ChatsListReady;
    expect(s.rooms.length, 2);
    expect(s.refreshing, isFalse);
    expect(ctx.listCalls(), 1);
    await teardown(ctx);
  });

  test('event-bus event → Ready(refreshing=true) → Ready(new)', () async {
    final ctx = buildController(initialList: [summary(id: 1)]);
    ctx.controller.init();
    await tick();
    expect(ctx.listCalls(), 1);

    // Меняем server-side список + толкаем event.
    ctx.setListResult([summary(id: 1), summary(id: 2)]);
    final transitions = <ChatsListState>[];
    ctx.controller.addListener(() => transitions.add(ctx.controller.state));

    ctx.upstream.add(eventFor(roomId: 1));
    await tick();

    expect(ctx.listCalls(), 2);
    // Должны были увидеть Ready(refreshing=true) → Ready(refreshing=false).
    expect(
      transitions.whereType<ChatsListReady>().any((r) => r.refreshing),
      isTrue,
      reason: 'промежуточное Ready(refreshing=true) для no-flicker UX',
    );
    final last = ctx.controller.state as ChatsListReady;
    expect(last.refreshing, isFalse);
    expect(last.rooms.length, 2);
    await teardown(ctx);
  });

  test('первый fetch падает → Error(lastKnown=null)', () async {
    final ctx = buildController(initialList: const []);
    ctx.setListError(StateError('network'));
    ctx.controller.init();
    await tick();

    expect(ctx.controller.state, isA<ChatsListError>());
    final s = ctx.controller.state as ChatsListError;
    expect(s.error, isA<StateError>());
    expect(s.lastKnown, isNull);
    await teardown(ctx);
  });

  test(
    'recurring fetch падает → Error(lastKnown=previous list) — кэш UI',
    () async {
      final ctx = buildController(initialList: [summary(id: 1)]);
      ctx.controller.init();
      await tick();
      expect(ctx.controller.state, isA<ChatsListReady>());

      ctx.setListError(StateError('network drop'));
      ctx.upstream.add(eventFor());
      await tick();

      expect(ctx.controller.state, isA<ChatsListError>());
      final s = ctx.controller.state as ChatsListError;
      expect(s.error, isA<StateError>());
      expect(s.lastKnown, isNotNull, reason: 'lastKnown сохранён');
      expect(s.lastKnown!.length, 1);
      expect(s.lastKnown!.first.id, 1);
      await teardown(ctx);
    },
  );

  test('concurrent events дебаунсятся — не плодим RPC', () async {
    // Замедленный listRpc через Completer — чтобы события могли стопиться.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final completers = <Completer<List<RoomSummary>>>[];
    var listCalls = 0;

    final rooms = NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            int? productId,
            RoomState? state,
            String? search,
            bool? includeArchived,
            required int limit,
            String? cursor,
          }) {
            listCalls++;
            final c = Completer<List<RoomSummary>>();
            completers.add(c);
            return c.future;
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

    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    controller.init();
    await Future<void>.delayed(Duration.zero);
    expect(listCalls, 1, reason: 'init triggered first fetch');

    // Толкаем 5 events пока первый запрос ещё в полёте.
    for (var i = 0; i < 5; i++) {
      upstream.add(eventFor());
    }
    await Future<void>.delayed(Duration.zero);
    // Refresh debouncing: должен был добавиться один pending, не пять.
    expect(listCalls, 1, reason: 'события debounced');

    // Завершаем первый запрос.
    completers[0].complete([summary(id: 1)]);
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    // После первого fini → pending refresh fires. Проверяем через
    // debugRefreshInvocations (а не listCalls, потому что cache hit
    // от только-что-populated _listEntry мог бы скрыть RPC count).
    expect(
      controller.debugRefreshInvocations,
      2,
      reason: '5 events дебаунсятся в один pending refresh после init-fetch',
    );

    // Второй completer ещё может ждать (если pending действительно
    // создал второй Future). На наших условиях кэш только что был
    // заполнен → второй вызов rooms.list() — cache hit, _listRpc НЕ
    // зовётся. Это подтверждает дебаунсинг + cache layer работают
    // вместе как ожидается.
    expect(
      listCalls,
      1,
      reason: 'cache hit на второй list() — RPC не делается',
    );

    controller.dispose();
    await rooms.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('MessengerSessionState.active triggers refresh', () async {
    final ctx = buildController(initialList: [summary(id: 1)]);
    ctx.controller.init();
    await tick();
    expect(ctx.listCalls(), 1);

    // Симулируем эффект reauth: SDK invalidates cache (произошёл network
    // drop / token rotated). Проверяем, что active-transition заставляет
    // controller сделать новый fetch (не cache hit).
    ctx.rooms.invalidate();
    ctx.stateCtl.add(MessengerSessionState.refreshing);
    ctx.stateCtl.add(MessengerSessionState.active);
    await tick();

    expect(
      ctx.listCalls(),
      2,
      reason: 'active + invalidated cache → controller делает RPC',
    );
    await teardown(ctx);
  });

  test('loadMore() — no-op (TASK42 hook)', () async {
    final ctx = buildController(initialList: [summary(id: 1)]);
    ctx.controller.init();
    await tick();
    final callsBefore = ctx.listCalls();

    await ctx.controller.loadMore();
    await tick();
    expect(ctx.listCalls(), callsBefore, reason: 'loadMore() no-op на TASK14');
    await teardown(ctx);
  });

  test('refresh(force: true) → invalidate cache + RPC', () async {
    final ctx = buildController(initialList: [summary(id: 1)]);
    ctx.controller.init();
    await tick();
    expect(ctx.listCalls(), 1);

    // Без force — TTL ещё не истёк, второй list() — cache hit.
    await ctx.controller.refresh();
    await tick();
    expect(ctx.listCalls(), 1, reason: 'cache hit без force');

    await ctx.controller.refresh(force: true);
    await tick();
    expect(ctx.listCalls(), 2, reason: 'force invalidates cache → RPC');
    await teardown(ctx);
  });

  test(
    'refresh(force=true) во время in-flight ждёт ВСЮ цепочку до idle',
    () async {
      // Закрытие ревью b89bfd9 #1: pull-to-refresh во время фонового
      // refresh должен возвращать Future, который завершается ПОСЛЕ
      // pending refresh-а с force-invalidated cache, а не сразу.
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final upstream = StreamController<MessengerEvent>.broadcast();
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        sessionStateStream: stateCtl.stream,
      );
      final completers = <Completer<List<RoomSummary>>>[];
      var listCalls = 0;

      final rooms = NsgMessengerRooms.attachWithRpcs(
        listRpc:
            ({
              int? productId,
              RoomState? state,
              String? search,
              bool? includeArchived,
              required int limit,
              String? cursor,
            }) {
              listCalls++;
              final c = Completer<List<RoomSummary>>();
              completers.add(c);
              return c.future;
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
            ({
              required int roomId,
              required int targetMessengerUserId,
            }) async {},
        setRoomMemberRoleRpc:
            ({
              required int roomId,
              required int targetMessengerUserId,
              required RoomMemberRole newRole,
            }) async {},
        listBannedUsersRpc: ({required int roomId}) async => const [],
        eventBus: bus,
      );

      final controller = ChatsListController(
        rooms: rooms,
        events: bus.events,
        sessionStates: stateCtl.stream,
      );
      controller.init();
      await Future<void>.delayed(Duration.zero);
      // init triggered first list — completer[0] in-flight.
      expect(listCalls, 1);

      var refreshDone = false;
      final refreshFuture = controller
          .refresh(force: true)
          .then((_) => refreshDone = true);
      // Сразу после refresh(force=true) Future НЕ завершен — current
      // ещё в полёте + force поставил pending-маркер.
      await Future<void>.delayed(Duration.zero);
      expect(refreshDone, isFalse);

      // Завершаем первый list — это запустит pending refresh
      // (с force-invalidated cache → новый _listRpc вызов).
      completers[0].complete([summary(id: 1)]);
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      // Pending refresh запущен (listCalls=2), но completer[1] ещё
      // не resolved → refresh-Future всё ещё ждёт.
      expect(listCalls, 2);
      expect(
        refreshDone,
        isFalse,
        reason: 'force-pending refresh ещё не завершён',
      );

      // Завершаем pending refresh.
      completers[1].complete([summary(id: 1), summary(id: 2)]);
      await refreshFuture;
      expect(
        refreshDone,
        isTrue,
        reason: 'Future завершился после fresh fetch',
      );
      expect(listCalls, 2);

      controller.dispose();
      await rooms.dispose();
      await upstream.close();
      await stateCtl.close();
    },
  );

  // ─── TASK42 Chunk 2 ─────────────────────────────────────────────────

  test('muteRoom: optimistic update — UI меняется до RPC complete', () async {
    final ctx = buildController(initialList: [summary(id: 1, name: 'A')]);
    ctx.controller.init();
    await tick();
    final before = ctx.controller.state as ChatsListReady;
    expect(before.rooms.first.muted, isFalse);

    // На время RPC «hang» через completer: проверяем что UI уже видит
    // muted=true ДО завершения RPC.
    final hangCompleter = Completer<void>();
    final ctx2 = buildControllerWithMuteRpc(
      initialList: [summary(id: 1, name: 'A')],
      muteRpc:
          ({required int roomId, DateTime? mutedUntil, int? muteForSeconds}) =>
              hangCompleter.future,
    );
    ctx2.controller.init();
    await tick();

    final fut = ctx2.controller.muteRoom(1);
    await Future<void>.delayed(Duration.zero); // micro-tick для emit-а.
    final mid = ctx2.controller.state as ChatsListReady;
    expect(
      mid.rooms.first.muted,
      isTrue,
      reason: 'optimistic — muted=true до RPC complete',
    );

    hangCompleter.complete();
    await fut;
    await teardown(ctx);
    ctx2.controller.dispose();
    await ctx2.rooms.dispose();
    await ctx2.upstream.close();
    await ctx2.stateCtl.close();
  });

  test('muteRoom: RPC fail → revert state', () async {
    final ctx = buildControllerWithMuteRpc(
      initialList: [summary(id: 1, name: 'A')],
      muteRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) async => throw StateError('network'),
    );
    ctx.controller.init();
    await tick();
    final before = ctx.controller.state as ChatsListReady;
    expect(before.rooms.first.muted, isFalse);

    await expectLater(ctx.controller.muteRoom(1), throwsA(isA<StateError>()));

    final after = ctx.controller.state as ChatsListReady;
    expect(
      after.rooms.first.muted,
      isFalse,
      reason: 'после RPC fail — revert к pre-action snapshot',
    );

    ctx.controller.dispose();
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test(
    'archiveRoom: на active filter — room удаляется из visible list',
    () async {
      final ctx = buildController(
        initialList: [
          summary(id: 1, name: 'A'),
          summary(id: 2, name: 'B'),
        ],
      );
      ctx.controller.init();
      await tick();
      // filter == active по default.
      expect(ctx.controller.filter, ChatsListFilter.active);

      await ctx.controller.archiveRoom(1);
      await tick();
      final after = ctx.controller.state as ChatsListReady;
      // Optimistic: room.id=1 удалён из active list.
      expect(after.rooms.map((r) => r.id), [2]);

      await teardown(ctx);
    },
  );

  test('leaveRoom: removes room from list, revert on fail', () async {
    final ctx = buildControllerWithLeaveRpc(
      initialList: [summary(id: 1), summary(id: 2)],
      leaveRpc: ({required int roomId}) async => throw StateError('boom'),
    );
    ctx.controller.init();
    await tick();
    expect((ctx.controller.state as ChatsListReady).rooms.length, 2);

    await expectLater(ctx.controller.leaveRoom(1), throwsA(isA<StateError>()));

    final after = ctx.controller.state as ChatsListReady;
    expect(after.rooms.map((r) => r.id), [
      1,
      2,
    ], reason: 'revert восстанавливает обе комнаты');

    ctx.controller.dispose();
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });

  test('setFilter: разные tab → invalidate + post-filter', () async {
    final activeRoom = summary(id: 1);
    final archivedRoom = RoomSummary(
      id: 2,
      name: 'archived',
      unreadCount: 0,
      archived: true,
      muted: false,
      roomType: RoomType.group,
    );
    final ctx = buildController(initialList: [activeRoom, archivedRoom]);
    ctx.controller.init();
    await tick();

    // Default: active filter; server возвращает оба, но фактически
    // server-side `includeArchived=false` отрежет archived. В нашем
    // stub server возвращает initialList целиком, так что post-filter
    // на стороне controller не fires (filter==active = no-op для нас).
    // Здесь тест проверяет filter API, не server-side filter.
    expect(ctx.controller.filter, ChatsListFilter.active);

    ctx.controller.setFilter(ChatsListFilter.archived);
    await tick();
    final afterArchived = ctx.controller.state as ChatsListReady;
    expect(
      afterArchived.rooms.map((r) => r.id),
      [2],
      reason: 'post-filter оставляет только archived',
    );

    ctx.controller.setFilter(ChatsListFilter.all);
    await tick();
    final afterAll = ctx.controller.state as ChatsListReady;
    expect(afterAll.rooms.map((r) => r.id), [1, 2]);

    await teardown(ctx);
  });

  test('setFilter: same filter → no-op (no extra RPC)', () async {
    final ctx = buildController(initialList: [summary(id: 1)]);
    ctx.controller.init();
    await tick();
    final before = ctx.listCalls();

    ctx.controller.setFilter(ChatsListFilter.active); // same as default
    await tick();
    expect(
      ctx.listCalls(),
      before,
      reason: 'смена на тот же filter — no extra RPC',
    );

    await teardown(ctx);
  });

  // ─── TASK42 Chunk 3 ─────────────────────────────────────────────────

  test('setSearch: 300ms debounce — rapid keystroke даёт 1 RPC', () async {
    // Замедленный listRpc через completers — позволяет считать
    // call-ы по факту, без race на cache TTL.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final searchValues = <String?>[];
    var listCalls = 0;
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
            searchValues.add(search);
            return const <RoomSummary>[];
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
    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    controller.init();
    await tick();
    // Init triggered first list; reset counter для debounce-теста.
    expect(listCalls, 1);
    final baseline = listCalls;

    // Имитация typeahead: 4 keystroke в течение 100ms-debounce.
    controller.setSearch('h');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    controller.setSearch('he');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    controller.setSearch('hel');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    controller.setSearch('hello');

    // Меньше чем kSearchDebounce — RPC ещё не должен был вылететь.
    expect(listCalls, baseline, reason: 'до окончания debounce no RPC');

    // Ждём debounce + microtask chain.
    await Future<void>.delayed(
      ChatsListController.kSearchDebounce + const Duration(milliseconds: 50),
    );
    await tick();

    // Ровно ОДИН lookup с финальным query.
    expect(listCalls, baseline + 1);
    expect(searchValues.last, 'hello');

    controller.dispose();
    await rooms.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('setSearch(null) clears query и refresh без search-param', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final searchValues = <String?>[];
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
            searchValues.add(search);
            return const <RoomSummary>[];
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
    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    controller.init();
    await tick();

    // Set query → wait debounce → RPC с search='foo'.
    controller.setSearch('foo');
    await Future<void>.delayed(
      ChatsListController.kSearchDebounce + const Duration(milliseconds: 50),
    );
    await tick();
    expect(searchValues.last, 'foo');

    // Clear → next RPC без search.
    controller.setSearch(null);
    await Future<void>.delayed(
      ChatsListController.kSearchDebounce + const Duration(milliseconds: 50),
    );
    await tick();
    expect(searchValues.last, isNull, reason: 'clear → null search');
    expect(controller.search, isNull);

    controller.dispose();
    await rooms.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('setSearch: empty/whitespace string → null', () async {
    final ctx = buildController(initialList: const []);
    ctx.controller.init();
    await tick();
    ctx.controller.setSearch('   ');
    expect(ctx.controller.search, isNull, reason: 'whitespace trim → null');
    ctx.controller.setSearch('');
    expect(ctx.controller.search, isNull);
    await teardown(ctx);
  });

  test(
    'setProductFilter: instant refresh (без debounce) + same-value no-op',
    () async {
      final ctx = buildController(initialList: [summary(id: 1)]);
      ctx.controller.init();
      await tick();
      final baseline = ctx.listCalls();

      ctx.controller.setProductFilter(42);
      await tick();
      expect(
        ctx.listCalls(),
        baseline + 1,
        reason: 'product filter — instant RPC',
      );

      // Same value → no-op.
      ctx.controller.setProductFilter(42);
      await tick();
      expect(ctx.listCalls(), baseline + 1, reason: 'same value — no-op');

      await teardown(ctx);
    },
  );

  test('loadAvailableProducts: idempotent — однократный RPC', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    var availableProductsCalls = 0;
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
      getAvailableProductsRpc: () async {
        availableProductsCalls++;
        final now = DateTime.utc(2026, 1, 1);
        return [
          Product(
            id: 1,
            tenantId: 1,
            externalKey: 'team',
            displayName: 'Team',
            createdAt: now,
            updatedAt: now,
          ),
          Product(
            id: 2,
            tenantId: 1,
            externalKey: 'support',
            displayName: 'Support',
            createdAt: now,
            updatedAt: now,
          ),
        ];
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
    final controller = ChatsListController(
      rooms: rooms,
      events: bus.events,
      sessionStates: stateCtl.stream,
    );
    controller.init();
    await tick();
    expect(controller.availableProducts, isNull);

    await controller.loadAvailableProducts();
    expect(availableProductsCalls, 1);
    expect(controller.availableProducts?.length, 2);

    // Повторный вызов — идемпотентен (cached).
    await controller.loadAvailableProducts();
    expect(availableProductsCalls, 1);

    controller.dispose();
    await rooms.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('dispose: после него notifyListeners не происходит', () async {
    final ctx = buildController(initialList: [summary(id: 1)]);
    ctx.controller.init();
    await tick();

    var notified = 0;
    ctx.controller.addListener(() => notified++);
    final notifiedBefore = notified;

    ctx.controller.dispose();
    // Толкаем event ПОСЛЕ dispose — подписка должна быть cancel-нута.
    ctx.upstream.add(eventFor());
    await tick();
    expect(
      notified,
      notifiedBefore,
      reason: 'после dispose нет notifyListeners',
    );

    // Не вызываем teardown(ctx) — controller уже disposed.
    await ctx.rooms.dispose();
    await ctx.upstream.close();
    await ctx.stateCtl.close();
  });
}
