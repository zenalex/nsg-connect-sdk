import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/admin/nsg_messenger_bots_admin.dart';

/// **issue #50**: обвязка админского листинга комнат.
///
/// Фолбэк «RPC нет/упал → собственные комнаты» здесь не гоняется: он
/// упирается в singleton `MessengerRuntime.instance.rooms`, у которого
/// нет test-override; путь старого сервера покрыт самим дизайном
/// (`listAllRoomsRpc` — nullable, как поздние RPC в NsgMessengerRooms).
void main() {
  RoomSummary room(int id, String name) => RoomSummary(
    id: id,
    name: name,
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  NsgMessengerBotsAdmin makeAdmin({
    ListAdminRoomsRpc? listAllRoomsRpc,
    ListBotRoomIdsRpc? listBotRoomIdsRpc,
  }) =>
      NsgMessengerBotsAdmin.withRpcs(
        isBotAdminRpc: () async => true,
        listBotsRpc: ({required String tenantExternalKey}) async =>
            const <Bot>[],
        createBotRpc:
            ({
              required String tenantExternalKey,
              String? productExternalKey,
              required String name,
              required String ownerEmail,
              required String capabilities,
              required bool discoverable,
            }) => throw UnimplementedError(),
        rotateBotTokenRpc: ({required int botId}) =>
            throw UnimplementedError(),
        setBotEnabledRpc: ({required int botId, required bool enabled}) =>
            throw UnimplementedError(),
        addBotToRoomRpc: ({required int botId, required int roomId}) async {},
        listAuditEventsRpc: ({required int botId, required int limit}) async =>
            const <BotAuditEvent>[],
        listAllRoomsRpc: listAllRoomsRpc,
        listBotRoomIdsRpc: listBotRoomIdsRpc,
      );

  test('listAllRooms зовёт админский RPC и отдаёт его результат', () async {
    int? seenLimit;
    final admin = makeAdmin(
      listAllRoomsRpc: ({required int limit}) async {
        seenLimit = limit;
        // Комната, в которой «админ не состоит», — обычный rooms.list()
        // такую не вернул бы; тут она проходит насквозь.
        return [room(27, 'проект NEXUS')];
      },
    );

    final rooms = await admin.listAllRooms();
    expect(rooms.map((r) => r.name), ['проект NEXUS']);
    expect(seenLimit, 200, reason: 'дефолтный limit доходит до RPC');
  });

  test('listBotRoomIds: отдаёт множество занятых комнат', () async {
    final admin = makeAdmin(
      listBotRoomIdsRpc: ({required int botId}) async => [27, 3, 27],
    );
    expect(await admin.listBotRoomIds(botId: 6), {27, 3});
  });

  test('listBotRoomIds: без RPC (старый сервер) — пусто, не исключение; '
      'пикер тогда просто никого не помечает', () async {
    final admin = makeAdmin();
    expect(await admin.listBotRoomIds(botId: 6), isEmpty);
  });

  test('listBotRoomIds: сбой RPC — пусто, деградация без поломки', () async {
    final admin = makeAdmin(
      listBotRoomIdsRpc: ({required int botId}) =>
          throw StateError('сеть упала'),
    );
    expect(await admin.listBotRoomIds(botId: 6), isEmpty);
  });

  test('limit пробрасывается', () async {
    int? seenLimit;
    final admin = makeAdmin(
      listAllRoomsRpc: ({required int limit}) async {
        seenLimit = limit;
        return const <RoomSummary>[];
      },
    );
    await admin.listAllRooms(limit: 50);
    expect(seenLimit, 50);
  });
}
