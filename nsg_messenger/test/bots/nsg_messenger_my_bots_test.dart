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
    MyBotsSetReadModeRpc? setReadModeRpc,
    MyBotsSetDescriptionRpc? setDescriptionRpc,
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
          required String readMode,
        }) => throw UnimplementedError(),
    rotateTokenRpc: ({required int botId}) async => bot(token: 'bot_new'),
    setEnabledRpc: ({required int botId, required bool enabled}) async =>
        bot(),
    setDiscoverableRpc:
        setDiscoverableRpc ??
        ({required int botId, required bool discoverable}) async => bot(),
    setReadModeRpc:
        setReadModeRpc ??
        ({required int botId, required String readMode}) async =>
            BotReadModeResult(bot: bot(), unboundSubscriptionCount: 0),
    setDescriptionRpc:
        setDescriptionRpc ??
        ({required int botId, required String description}) async => bot(),
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
            required String readMode,
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

  // **TASK77 итер.2**: privacy by default — если дефолт когда-нибудь
  // «поедет» на read_all, бот начнёт читать чужие чаты молча.
  test('create: дефолтный режим чтения — read_addressed; явный read_all '
      'доходит до RPC', () async {
    String? seenMode;
    final myBots = make(
      createRpc:
          ({
            required String name,
            required String capabilities,
            required bool discoverable,
            required String readMode,
          }) async {
            seenMode = readMode;
            return bot();
          },
    );

    await myBots.create(name: 'B', capabilities: 'send_messages');
    expect(seenMode, NsgMessengerBotsAdmin.readModeAddressed);

    await myBots.create(
      name: 'B2',
      capabilities: 'send_messages',
      readMode: NsgMessengerBotsAdmin.readModeAll,
    );
    expect(seenMode, NsgMessengerBotsAdmin.readModeAll);
  });

  test('setReadMode: botId+режим уходят в RPC насквозь', () async {
    (int, String)? seen;
    final myBots = make(
      setReadModeRpc: ({required int botId, required String readMode}) async {
        seen = (botId, readMode);
        return BotReadModeResult(
          bot: bot(id: botId),
          // **TASK77 итер.3**: сервер сообщает, сколько подписок обходит
          // privacy mode — фасад обязан донести это до UI без потерь.
          unboundSubscriptionCount: 2,
        );
      },
    );
    final result = await myBots.setReadMode(
      botId: 7,
      readMode: NsgMessengerBotsAdmin.readModeAll,
    );
    expect(seen, (7, 'read_all'));
    expect(result.unboundSubscriptionCount, 2);
  });

  test('setDescription: botId+текст уходят в RPC насквозь', () async {
    (int, String)? seen;
    final myBots = make(
      setDescriptionRpc:
          ({required int botId, required String description}) async {
            seen = (botId, description);
            return bot(id: botId);
          },
    );
    await myBots.setDescription(botId: 9, description: 'Следит за CI');
    expect(seen, (9, 'Следит за CI'));
  });

  group('readModeOf — трактовка совпадает с серверной', () {
    test('пусто/null → read_all (бот заведён до итер.2, grandfathered)', () {
      expect(
        NsgMessengerBotsAdmin.readModeOf(bot()),
        NsgMessengerBotsAdmin.readModeAll,
      );
      expect(NsgMessengerBotsAdmin.readsAllMessages(bot()), isTrue);
    });

    test('read_addressed — как есть', () {
      final b = bot()..readMode = 'read_addressed';
      expect(NsgMessengerBotsAdmin.readsAllMessages(b), isFalse);
    });

    test('мусор → read_addressed (сервер fail-closed, экран не должен '
        'обещать больше, чем даёт сервер)', () {
      final b = bot()..readMode = 'read_everything';
      expect(
        NsgMessengerBotsAdmin.readModeOf(b),
        NsgMessengerBotsAdmin.readModeAddressed,
      );
    });
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
