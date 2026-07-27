import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/bots/nsg_messenger_bot_catalog.dart';

/// **TASK77 итер.3**: фасад каталога ботов — параметры уходят в RPC насквозь,
/// а трактовка режима чтения НЕ дублирует серверное правило grandfathering-а
/// (сервер отдаёт уже разрешённый режим; повтор правила на клиенте — второй
/// источник истины для trust-сигнала).
void main() {
  AvailableBot bot({String readMode = 'read_addressed'}) => AvailableBot(
    botId: 1,
    messengerUserId: 101,
    name: 'b',
    ownerEmail: 'o@x.io',
    commands: const <BotCommand>[],
    readMode: readMode,
    discoverable: true,
    inRoom: false,
  );

  NsgMessengerBotCatalog make({
    ListAvailableBotsRpc? listAvailableBotsRpc,
    GetBotCardRpc? getBotCardRpc,
    ListMyAdminRoomsRpc? listMyAdminRoomsRpc,
    AddBotToMyRoomRpc? addBotToMyRoomRpc,
    RemoveBotFromMyRoomRpc? removeBotFromMyRoomRpc,
  }) => NsgMessengerBotCatalog.withRpcs(
    listAvailableBotsRpc:
        listAvailableBotsRpc ??
        ({int? roomId}) async => const <AvailableBot>[],
    getBotCardRpc:
        getBotCardRpc ??
        ({required int botMessengerUserId, int? roomId}) async => null,
    listMyAdminRoomsRpc:
        listMyAdminRoomsRpc ??
        ({required int limit}) async => const <RoomSummary>[],
    addBotToMyRoomRpc:
        addBotToMyRoomRpc ?? ({required int botId, required int roomId}) async {},
    removeBotFromMyRoomRpc:
        removeBotFromMyRoomRpc ??
        ({required int botId, required int roomId}) async {},
  );

  test('listAvailableBots: roomId-контекст уходит в RPC (нужен для inRoom)',
      () async {
    int? seen = -1;
    final catalog = make(
      listAvailableBotsRpc: ({int? roomId}) async {
        seen = roomId;
        return const <AvailableBot>[];
      },
    );
    await catalog.listAvailableBots(roomId: 42);
    expect(seen, 42);
    await catalog.listAvailableBots();
    expect(seen, isNull, reason: 'без контекста комнаты — null, не 0');
  });

  test('getBotCard: botMessengerUserId + roomId насквозь', () async {
    (int, int?)? seen;
    final catalog = make(
      getBotCardRpc: ({required int botMessengerUserId, int? roomId}) async {
        seen = (botMessengerUserId, roomId);
        return bot();
      },
    );
    await catalog.getBotCard(botMessengerUserId: 101, roomId: 7);
    expect(seen, (101, 7));
  });

  test('listMyAdminRooms: дефолтный лимит уходит в RPC', () async {
    int? seen;
    final catalog = make(
      listMyAdminRoomsRpc: ({required int limit}) async {
        seen = limit;
        return const <RoomSummary>[];
      },
    );
    await catalog.listMyAdminRooms();
    expect(seen, 200);
  });

  test('add/removeBotFromMyRoom: (botId, roomId) насквозь', () async {
    (int, int)? added;
    (int, int)? removed;
    final catalog = make(
      addBotToMyRoomRpc: ({required int botId, required int roomId}) async =>
          added = (botId, roomId),
      removeBotFromMyRoomRpc:
          ({required int botId, required int roomId}) async =>
              removed = (botId, roomId),
    );
    await catalog.addBotToMyRoom(botId: 3, roomId: 9);
    await catalog.removeBotFromMyRoom(botId: 3, roomId: 9);
    expect(added, (3, 9));
    expect(removed, (3, 9));
  });

  group('readsAllMessages — доверяем режиму, разрешённому сервером', () {
    test('read_all → true, read_addressed → false', () {
      expect(
        NsgMessengerBotCatalog.readsAllMessages(bot(readMode: 'read_all')),
        isTrue,
      );
      expect(
        NsgMessengerBotCatalog.readsAllMessages(
          bot(readMode: 'read_addressed'),
        ),
        isFalse,
      );
    });

    test('пустой режим НЕ превращается в read_all: в AvailableBot сервер '
        'уже применил grandfathering, и пустая строка тут — аномалия, '
        'которую нельзя трактовать как «читает всё»', () {
      expect(NsgMessengerBotCatalog.readsAllMessages(bot(readMode: '')), isFalse);
    });
  });
}
