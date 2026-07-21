import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
// Typedef-ы RPC не входят в публичный barrel (как и у админки) — тест
// берёт их из src напрямую, тем же приёмом, что admin-тесты.
import 'package:nsg_messenger/src/bots/nsg_messenger_my_bots.dart';

/// **Issue #49**: обвязка «Моих ботов» — тонкий passthrough над
/// `client.myBots.*`. Тесты фиксируют, что аргументы уходят в RPC без
/// искажений (create — включая discoverable, дефолт false) и что
/// результат не переупаковывается. Скоуп «только свои» — серверная
/// ответственность (my_bots_endpoint_test), клиент про него не знает.
void main() {
  Bot bot({int id = 1, String token = ''}) => Bot(
    id: id,
    messengerUserId: 100 + id,
    tenantId: 1,
    name: 'MyBot',
    ownerEmail: 'me@test.local',
    accessToken: token,
    capabilities: 'send_messages',
    enabled: true,
    discoverable: false,
    createdAt: DateTime.utc(2026, 7, 20),
  );

  NsgMessengerMyBots make({
    MyBotsListRpc? listRpc,
    MyBotsCreateRpc? createRpc,
    MyBotsSetDiscoverableRpc? setDiscoverableRpc,
    MyBotsListRoomsRpc? listRoomsRpc,
    MyBotsRemoveFromRoomRpc? removeFromRoomRpc,
    MyBotsListAuditEventsRpc? listAuditEventsRpc,
  }) => NsgMessengerMyBots.withRpcs(
    listRpc: listRpc ?? () async => const <Bot>[],
    createRpc:
        createRpc ??
        ({
          required String name,
          required String capabilities,
          required bool discoverable,
        }) => throw UnimplementedError(),
    rotateTokenRpc: ({required int botId}) async => bot(token: 'bot_new'),
    setEnabledRpc: ({required int botId, required bool enabled}) async =>
        bot(),
    setDiscoverableRpc:
        setDiscoverableRpc ??
        ({required int botId, required bool discoverable}) async => bot(),
    listRoomsRpc: listRoomsRpc ?? ({required int botId}) async => const [],
    removeFromRoomRpc:
        removeFromRoomRpc ??
        ({required int botId, required int roomId}) async {},
    listAuditEventsRpc:
        listAuditEventsRpc ??
        ({required int botId, required int limit}) async => const [],
  );

  test('create: имя/CSV-гранты/discoverable уходят в RPC как есть; '
      'дефолт discoverable=false', () async {
    (String, String, bool)? seen;
    final myBots = make(
      createRpc:
          ({
            required String name,
            required String capabilities,
            required bool discoverable,
          }) async {
            seen = (name, capabilities, discoverable);
            return bot(token: 'bot_fresh');
          },
    );

    final created = await myBots.create(
      name: 'DeployBot',
      capabilities: 'send_messages,manage_room',
    );
    expect(created.accessToken, 'bot_fresh');
    expect(seen, ('DeployBot', 'send_messages,manage_room', false));

    await myBots.create(
      name: 'PublicBot',
      capabilities: 'send_messages',
      discoverable: true,
    );
    expect(seen!.$3, isTrue);
  });

  test('setDiscoverable / removeFromRoom: botId+флаг/roomId — насквозь',
      () async {
    (int, bool)? discSeen;
    (int, int)? removeSeen;
    final myBots = make(
      setDiscoverableRpc:
          ({required int botId, required bool discoverable}) async {
            discSeen = (botId, discoverable);
            return bot(id: botId);
          },
      removeFromRoomRpc: ({required int botId, required int roomId}) async {
        removeSeen = (botId, roomId);
      },
    );

    await myBots.setDiscoverable(botId: 7, discoverable: true);
    expect(discSeen, (7, true));

    await myBots.removeFromRoom(botId: 7, roomId: 42);
    expect(removeSeen, (7, 42));
  });

  test('listRooms / listAuditEvents: результат RPC не переупаковывается, '
      'дефолтный limit журнала — 100', () async {
    int? seenLimit;
    final myBots = make(
      listRoomsRpc: ({required int botId}) async => [
        RoomSummary(
          id: 27,
          name: 'проект NEXUS',
          unreadCount: 0,
          archived: false,
          muted: false,
          roomType: RoomType.group,
        ),
      ],
      listAuditEventsRpc: ({required int botId, required int limit}) async {
        seenLimit = limit;
        return const <BotAuditEvent>[];
      },
    );

    final rooms = await myBots.listRooms(botId: 1);
    expect(rooms.single.name, 'проект NEXUS');

    await myBots.listAuditEvents(botId: 1);
    expect(seenLimit, 100);
  });
}
