import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **issue #46** — полный синк списка комнат.
///
/// До задачи UI звал `list()` без курсора и считал первые 50 комнат всем
/// списком: с 51-й чаты для пользователя переставали существовать, а папки
/// и бейджи, которые считаются по загруженному набору, врали вместе с ним.
/// Курсор при этом наружу не отдавался вовсе — дойти до конца было нечем.
void main() {
  RoomSummary room(int id) => RoomSummary(
    id: id,
    name: 'Room $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  /// Собирает `NsgMessengerRooms`, где постраничный RPC отдаёт заранее
  /// заданные страницы. `pages` — список страниц; курсор каждой
  /// следующей = её индекс.
  ({
    NsgMessengerRooms rooms,
    int Function() pageCalls,
    int Function() listCalls,
    List<String?> cursorsSeen,
  })
  build({
    required List<List<RoomSummary>> pages,
    bool wireFullSync = true,
    Object? failOnPage,
    List<RoomSummary> legacyListResult = const [],
    bool endlessCursor = false,
  }) {
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: const Stream<MessengerSessionState>.empty(),
    );
    var pageCalls = 0;
    var listCalls = 0;
    final cursorsSeen = <String?>[];

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
            return legacyListResult;
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

    if (wireFullSync) {
      rooms.wireRoomsFullSync(
        listPage:
            ({
              int? productId,
              RoomState? state,
              String? search,
              bool? includeArchived,
              required int limit,
              String? cursor,
            }) async {
              cursorsSeen.add(cursor);
              final i = pageCalls;
              pageCalls++;
              if (failOnPage == i) throw StateError('сеть отвалилась');
              if (endlessCursor) {
                // Патологический сервер: всегда обещает продолжение.
                return RoomListPage(rooms: [room(i)], nextCursor: 'c$i');
              }
              // За пределами заданных страниц отдаём пустую последнюю —
              // так тесты могут звать listAll повторно (проверка кэша).
              if (i >= pages.length) {
                return RoomListPage(rooms: const [], nextCursor: null);
              }
              final isLast = i == pages.length - 1;
              return RoomListPage(
                rooms: pages[i],
                nextCursor: isLast ? null : 'c$i',
              );
            },
      );
    }
    return (
      rooms: rooms,
      pageCalls: () => pageCalls,
      listCalls: () => listCalls,
      cursorsSeen: cursorsSeen,
    );
  }

  test('идёт по страницам до конца и склеивает их в один список', () async {
    final h = build(
      pages: [
        [room(1), room(2)],
        [room(3), room(4)],
        [room(5)],
      ],
    );
    final all = await h.rooms.listAll();

    expect(all.map((r) => r.id), [1, 2, 3, 4, 5]);
    expect(h.pageCalls(), 3);
    expect(
      h.cursorsSeen,
      [null, 'c0', 'c1'],
      reason: 'курсор следующей страницы берётся из ответа предыдущей',
    );
  });

  test('останавливается на nextCursor == null, а не на неполной странице', () {
    // Признак «страница короче limit» для остановки не годится: при
    // общем числе комнат, кратном limit, последняя страница полная.
    return build(pages: [
      [room(1)],
    ]).rooms.listAll().then((all) {
      expect(all.map((r) => r.id), [1]);
    });
  });

  test('ошибка на середине пути ПРОБРАСЫВАЕТСЯ, а не отдаёт огрызок', () async {
    // Неполный список, поданный как полный, — ровно тот баг, который
    // задача закрывает. Лучше показать ошибку поверх прошлых данных.
    final h = build(
      pages: [
        [room(1)],
        [room(2)],
      ],
      failOnPage: 1,
    );
    await expectLater(h.rooms.listAll(), throwsA(isA<StateError>()));
  });

  test('второй вызов берётся из TTL-кэша — сервер не дёргается заново', () async {
    final h = build(
      pages: [
        [room(1)],
        [room(2)],
      ],
    );
    await h.rooms.listAll();
    final callsAfterFirst = h.pageCalls();
    await h.rooms.listAll();

    expect(h.pageCalls(), callsAfterFirst, reason: 'ни одного лишнего RPC');
  });

  test('разные фильтры — разные ключи кэша (не выдаём чужой набор)', () async {
    final h = build(
      pages: [
        [room(1)],
      ],
    );
    await h.rooms.listAll();
    await h.rooms.listAll(includeArchived: true);

    expect(h.pageCalls(), 2);
  });

  test('старый сервер (курсора нет) → откат на одну страницу, без падения', () async {
    final h = build(
      pages: const [],
      wireFullSync: false,
      legacyListResult: [room(7)],
    );
    expect(h.rooms.fullSyncAvailable, isFalse);

    final all = await h.rooms.listAll();
    expect(all.map((r) => r.id), [7]);
    expect(h.listCalls(), 1, reason: 'ушли в обычный list()');
  });

  test('сервер бесконечно обещает продолжение → упираемся в потолок, '
      'а не крутимся вечно', () async {
    final h = build(pages: const [], endlessCursor: true);
    final all = await h.rooms.listAll();

    expect(h.pageCalls(), NsgMessengerRooms.maxFullSyncPages);
    expect(all.length, NsgMessengerRooms.maxFullSyncPages);
  });
}
