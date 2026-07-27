import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK77 итер.3**: каталог ботов и self-service-подключение бота в свою
/// комнату — публичный API поверх `client.botCatalog.*`.
///
/// Отличие от соседей: [NsgMessengerBotsAdmin] — платформенный админ (все
/// боты тенанта), [NsgMessengerMyBots] — владелец бота (свои боты), а здесь
/// **владелец комнаты**: он не владеет ботом и не админ платформы, но вправе
/// решать, кто читает его группу. Скоуп решает сервер: каталог — только
/// публичные боты своего тенанта, подключение — только в комнаты, где caller
/// админ.
///
/// Сигнатуры вынесены в typedef-ы для инъекции fake-ов в тестах
/// ([NsgMessengerBotCatalog.withRpcs]) — тот же приём, что у соседних
/// bot-фасадов.
typedef ListAvailableBotsRpc =
    Future<List<AvailableBot>> Function({int? roomId});
typedef GetBotCardRpc =
    Future<AvailableBot?> Function({
      required int botMessengerUserId,
      int? roomId,
    });
typedef ListMyAdminRoomsRpc =
    Future<List<RoomSummary>> Function({required int limit});
typedef AddBotToMyRoomRpc =
    Future<void> Function({required int botId, required int roomId});
typedef RemoveBotFromMyRoomRpc =
    Future<void> Function({required int botId, required int roomId});

class NsgMessengerBotCatalog {
  NsgMessengerBotCatalog._({
    required ListAvailableBotsRpc listAvailableBotsRpc,
    required GetBotCardRpc getBotCardRpc,
    required ListMyAdminRoomsRpc listMyAdminRoomsRpc,
    required AddBotToMyRoomRpc addBotToMyRoomRpc,
    required RemoveBotFromMyRoomRpc removeBotFromMyRoomRpc,
  }) : _listAvailableBotsRpc = listAvailableBotsRpc,
       _getBotCardRpc = getBotCardRpc,
       _listMyAdminRoomsRpc = listMyAdminRoomsRpc,
       _addBotToMyRoomRpc = addBotToMyRoomRpc,
       _removeBotFromMyRoomRpc = removeBotFromMyRoomRpc;

  final ListAvailableBotsRpc _listAvailableBotsRpc;
  final GetBotCardRpc _getBotCardRpc;
  final ListMyAdminRoomsRpc _listMyAdminRoomsRpc;
  final AddBotToMyRoomRpc _addBotToMyRoomRpc;
  final RemoveBotFromMyRoomRpc _removeBotFromMyRoomRpc;

  /// Режим чтения «читает ВСЕ сообщения» (значение `AvailableBot.readMode`).
  /// Дублируется здесь, чтобы каталог/карточка не тянули админский фасад
  /// ради одной константы.
  static const String readModeAll = 'read_all';

  /// Режим чтения «только обращения к боту».
  static const String readModeAddressed = 'read_addressed';

  /// `true` — бот читает всю переписку своих комнат. Сервер отдаёт в
  /// [AvailableBot.readMode] уже РАЗРЕШЁННЫЙ режим (grandfathered `NULL`
  /// превращён в `read_all` там же), поэтому здесь простое сравнение —
  /// правило «NULL = read_all» на клиенте не повторяется.
  static bool readsAllMessages(AvailableBot bot) =>
      bot.readMode == readModeAll;

  /// Production-фабрика: привязка к `client.botCatalog.*` под
  /// [withAuthRetry].
  static NsgMessengerBotCatalog attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return withRpcs(
      listAvailableBotsRpc: ({int? roomId}) => withAuthRetry(
        () => client.botCatalog.listAvailableBots(roomId: roomId),
        session(),
      ),
      getBotCardRpc: ({required int botMessengerUserId, int? roomId}) =>
          withAuthRetry(
            () => client.botCatalog.getBotCard(
              botMessengerUserId: botMessengerUserId,
              roomId: roomId,
            ),
            session(),
          ),
      listMyAdminRoomsRpc: ({required int limit}) => withAuthRetry(
        () => client.botCatalog.listMyAdminRooms(limit: limit),
        session(),
      ),
      addBotToMyRoomRpc: ({required int botId, required int roomId}) =>
          withAuthRetry(
            () => client.botCatalog.addBotToMyRoom(
              botId: botId,
              roomId: roomId,
            ),
            session(),
          ),
      removeBotFromMyRoomRpc: ({required int botId, required int roomId}) =>
          withAuthRetry(
            () => client.botCatalog.removeBotFromMyRoom(
              botId: botId,
              roomId: roomId,
            ),
            session(),
          ),
    );
  }

  /// Test-фабрика: инъекция fake-RPC (без Serverpod-клиента / runtime).
  static NsgMessengerBotCatalog withRpcs({
    required ListAvailableBotsRpc listAvailableBotsRpc,
    required GetBotCardRpc getBotCardRpc,
    required ListMyAdminRoomsRpc listMyAdminRoomsRpc,
    required AddBotToMyRoomRpc addBotToMyRoomRpc,
    required RemoveBotFromMyRoomRpc removeBotFromMyRoomRpc,
  }) => NsgMessengerBotCatalog._(
    listAvailableBotsRpc: listAvailableBotsRpc,
    getBotCardRpc: getBotCardRpc,
    listMyAdminRoomsRpc: listMyAdminRoomsRpc,
    addBotToMyRoomRpc: addBotToMyRoomRpc,
    removeBotFromMyRoomRpc: removeBotFromMyRoomRpc,
  );

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Публичные (`discoverable`) включённые боты своего тенанта.
  ///
  /// [roomId] — контекст «куда собираемся подключать»: боты, уже
  /// состоящие в этой комнате, приходят с `inRoom = true`.
  Future<List<AvailableBot>> listAvailableBots({int? roomId}) =>
      _listAvailableBotsRpc(roomId: roomId);

  /// Карточка бота по его `messengerUserId` (так клиент знает участника
  /// комнаты и автора сообщения). `null` — этот бот caller-у не виден
  /// (не публичный и не в его комнатах, либо чужой тенант).
  Future<AvailableBot?> getBotCard({
    required int botMessengerUserId,
    int? roomId,
  }) => _getBotCardRpc(botMessengerUserId: botMessengerUserId, roomId: roomId);

  /// Комнаты, куда caller ВПРАВЕ подключить бота (он там владелец/админ) —
  /// источник для «добавить в комнату…» в карточке.
  Future<List<RoomSummary>> listMyAdminRooms({int limit = 200}) =>
      _listMyAdminRoomsRpc(limit: limit);

  /// Подключить публичного бота в свою комнату. Идемпотентно.
  Future<void> addBotToMyRoom({required int botId, required int roomId}) =>
      _addBotToMyRoomRpc(botId: botId, roomId: roomId);

  /// Отключить бота от своей комнаты. Идемпотентно.
  Future<void> removeBotFromMyRoom({
    required int botId,
    required int roomId,
  }) => _removeBotFromMyRoomRpc(botId: botId, roomId: roomId);
}
