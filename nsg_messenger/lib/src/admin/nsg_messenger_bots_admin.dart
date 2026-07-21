import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK36 (admin panel для ботов)**: публичный API админки ботов —
/// tenant-wide, в отличие от room-scoped `NsgMessengerIntegrations`
/// (TASK58/59). Доступен через `NsgMessenger.botsAdmin`; используется
/// `BotsAdminScreen`.
///
/// Гейт — серверный: каждый метод `client.botAdmin.*` требует, чтобы email
/// caller-а был в env `BOT_ADMIN_EMAILS`. [isBotAdmin] нужен только чтобы
/// НЕ показывать пункт меню тому, кому все методы всё равно откажут —
/// это UX, а не авторизация (её решает сервер).
///
/// Тонкая обёртка над сгенерированными Serverpod-эндпоинтами; каждый RPC
/// под [withAuthRetry] (self-heal на серверный auth-invalidation), тот же
/// приём, что в [NsgMessengerIntegrations]. Кэша нет — админ-экран
/// открывается редко, каждый `list` идёт на сервер.
///
/// Сигнатуры вынесены в typedef-ы для инъекции fake-ов в тестах
/// ([NsgMessengerBotsAdmin.withRpcs]).
typedef IsBotAdminRpc = Future<bool> Function();
typedef ListBotsRpc =
    Future<List<Bot>> Function({required String tenantExternalKey});
typedef CreateBotRpc =
    Future<Bot> Function({
      required String tenantExternalKey,
      String? productExternalKey,
      required String name,
      required String ownerEmail,
      required String capabilities,
      // **Issue #49**: видимость в поиске. Тот же флаг, что и у
      // self-service `myBots.create`; сервер зовёт общий BotService.createBot.
      required bool discoverable,
    });
typedef RotateBotTokenRpc = Future<Bot> Function({required int botId});
typedef SetBotAdminEnabledRpc =
    Future<Bot> Function({required int botId, required bool enabled});
typedef AddBotToRoomRpc =
    Future<void> Function({required int botId, required int roomId});
typedef ListBotAuditEventsRpc =
    Future<List<BotAuditEvent>> Function({required int botId, required int limit});

/// **issue #50**: все активные комнаты tenant-а (для пикера «добавить
/// бота в комнату»); обычный rooms.list() отдаёт лишь комнаты самого
/// админа.
typedef ListAdminRoomsRpc = Future<List<RoomSummary>> Function({
  required int limit,
});

/// **issue #50 follow-up**: id комнат, где бот уже состоит, — пикер
/// помечает их «уже добавлен».
typedef ListBotRoomIdsRpc = Future<List<int>> Function({required int botId});

class NsgMessengerBotsAdmin {
  NsgMessengerBotsAdmin._({
    required IsBotAdminRpc isBotAdminRpc,
    required ListBotsRpc listBotsRpc,
    required CreateBotRpc createBotRpc,
    required RotateBotTokenRpc rotateBotTokenRpc,
    required SetBotAdminEnabledRpc setBotEnabledRpc,
    required AddBotToRoomRpc addBotToRoomRpc,
    required ListBotAuditEventsRpc listAuditEventsRpc,
    ListAdminRoomsRpc? listAllRoomsRpc,
    ListBotRoomIdsRpc? listBotRoomIdsRpc,
  }) : _isBotAdminRpc = isBotAdminRpc,
       _listBotsRpc = listBotsRpc,
       _createBotRpc = createBotRpc,
       _rotateBotTokenRpc = rotateBotTokenRpc,
       _setBotEnabledRpc = setBotEnabledRpc,
       _addBotToRoomRpc = addBotToRoomRpc,
       _listAuditEventsRpc = listAuditEventsRpc,
       _listAllRoomsRpc = listAllRoomsRpc,
       _listBotRoomIdsRpc = listBotRoomIdsRpc;

  final IsBotAdminRpc _isBotAdminRpc;
  final ListBotsRpc _listBotsRpc;
  final CreateBotRpc _createBotRpc;
  final RotateBotTokenRpc _rotateBotTokenRpc;
  final SetBotAdminEnabledRpc _setBotEnabledRpc;
  final AddBotToRoomRpc _addBotToRoomRpc;
  final ListBotAuditEventsRpc _listAuditEventsRpc;

  /// Nullable по той же причине, что поздние RPC в NsgMessengerRooms:
  /// не ломать существующие call-site-ы [withRpcs] новым required-полем.
  final ListAdminRoomsRpc? _listAllRoomsRpc;
  final ListBotRoomIdsRpc? _listBotRoomIdsRpc;

  /// Tenant по умолчанию — тот же дефолт, что у серверных сигнатур
  /// `botAdmin.*` (`'nsg'`).
  static const String kDefaultTenant = 'nsg';

  /// Capability-гранты (значения совпадают с серверными
  /// `BotService.cap*` — сервер санитайзит CSV повторно).
  static const String capReadOnly = 'read_only';
  static const String capSendMessages = 'send_messages';
  static const String capManageRoom = 'manage_room';
  static const String capWebhookTarget = 'webhook_target';

  /// Все гранты в порядке отображения в UI (чекбоксы диалога создания).
  static const List<String> kAllCapabilities = [
    capReadOnly,
    capSendMessages,
    capManageRoom,
    capWebhookTarget,
  ];

  /// Production-фабрика: привязка к `client.botAdmin.*`, каждый под
  /// [withAuthRetry]. `session()` резолвит session-manager лениво из
  /// runtime (closures выполняются после `init()`).
  static NsgMessengerBotsAdmin attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return withRpcs(
      isBotAdminRpc: () =>
          withAuthRetry(() => client.botAdmin.isBotAdmin(), session()),
      listBotsRpc: ({required String tenantExternalKey}) => withAuthRetry(
        () => client.botAdmin.listBots(tenantExternalKey: tenantExternalKey),
        session(),
      ),
      createBotRpc:
          ({
            required String tenantExternalKey,
            String? productExternalKey,
            required String name,
            required String ownerEmail,
            required String capabilities,
            required bool discoverable,
          }) => withAuthRetry(
            () => client.botAdmin.createBot(
              tenantExternalKey: tenantExternalKey,
              productExternalKey: productExternalKey,
              name: name,
              ownerEmail: ownerEmail,
              capabilities: capabilities,
              discoverable: discoverable,
            ),
            session(),
          ),
      rotateBotTokenRpc: ({required int botId}) => withAuthRetry(
        () => client.botAdmin.rotateBotToken(botId: botId),
        session(),
      ),
      setBotEnabledRpc: ({required int botId, required bool enabled}) =>
          withAuthRetry(
            () => client.botAdmin.setBotEnabled(botId: botId, enabled: enabled),
            session(),
          ),
      addBotToRoomRpc: ({required int botId, required int roomId}) =>
          withAuthRetry(
            () => client.botAdmin.addBotToRoom(botId: botId, roomId: roomId),
            session(),
          ),
      listAuditEventsRpc: ({required int botId, required int limit}) =>
          withAuthRetry(
            () => client.botAdmin.listAuditEvents(botId: botId, limit: limit),
            session(),
          ),
      listAllRoomsRpc: ({required int limit}) => withAuthRetry(
        () => client.botAdmin.listAllRooms(limit: limit),
        session(),
      ),
      listBotRoomIdsRpc: ({required int botId}) => withAuthRetry(
        () => client.botAdmin.listBotRoomIds(botId: botId),
        session(),
      ),
    );
  }

  /// Test-фабрика: инъекция fake-RPC (без Serverpod-клиента / runtime).
  static NsgMessengerBotsAdmin withRpcs({
    required IsBotAdminRpc isBotAdminRpc,
    required ListBotsRpc listBotsRpc,
    required CreateBotRpc createBotRpc,
    required RotateBotTokenRpc rotateBotTokenRpc,
    required SetBotAdminEnabledRpc setBotEnabledRpc,
    required AddBotToRoomRpc addBotToRoomRpc,
    required ListBotAuditEventsRpc listAuditEventsRpc,
    ListAdminRoomsRpc? listAllRoomsRpc,
    ListBotRoomIdsRpc? listBotRoomIdsRpc,
  }) => NsgMessengerBotsAdmin._(
    isBotAdminRpc: isBotAdminRpc,
    listBotsRpc: listBotsRpc,
    createBotRpc: createBotRpc,
    rotateBotTokenRpc: rotateBotTokenRpc,
    setBotEnabledRpc: setBotEnabledRpc,
    addBotToRoomRpc: addBotToRoomRpc,
    listAuditEventsRpc: listAuditEventsRpc,
    listAllRoomsRpc: listAllRoomsRpc,
    listBotRoomIdsRpc: listBotRoomIdsRpc,
  );

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Доступна ли caller-у админка ботов (email в `BOT_ADMIN_EMAILS`).
  /// Только для скрытия пункта меню — авторизацию решает сервер на каждом
  /// методе. Ошибку не бросает: недоступность админки — не ошибка экрана,
  /// а норма для 99% пользователей.
  Future<bool> isBotAdmin() async {
    try {
      return await _isBotAdminRpc();
    } catch (_) {
      return false;
    }
  }

  /// Список ботов tenant-а. `accessToken` в моделях списка ПУСТ — сервер
  /// зануляет его; актуальный credential виден только в момент выдачи
  /// ([createBot] / [rotateToken]).
  Future<List<Bot>> listBots({String tenantExternalKey = kDefaultTenant}) =>
      _listBotsRpc(tenantExternalKey: tenantExternalKey);

  /// Завести бота. Возвращённый [Bot] несёт `accessToken` — **показать
  /// админу один раз**. [capabilities] — CSV грантов ([kAllCapabilities]).
  /// [discoverable] — виден ли бот в поиске (дефолт false: публичность —
  /// осознанный выбор владельца, issue #49).
  Future<Bot> createBot({
    String tenantExternalKey = kDefaultTenant,
    String? productExternalKey,
    required String name,
    required String ownerEmail,
    required String capabilities,
    bool discoverable = false,
  }) => _createBotRpc(
    tenantExternalKey: tenantExternalKey,
    productExternalKey: productExternalKey,
    name: name,
    ownerEmail: ownerEmail,
    capabilities: capabilities,
    discoverable: discoverable,
  );

  /// Ротация credential-а бота: новый `accessToken`, все прежние отозваны
  /// немедленно. Бот, его комнаты и история постов сохраняются. Ответ несёт
  /// новый токен — **показать один раз**; программе бота нужно подставить
  /// его, иначе её вызовы перестанут проходить.
  Future<Bot> rotateToken({required int botId}) =>
      _rotateBotTokenRpc(botId: botId);

  /// Kill-switch: `enabled=false` → любое gated-действие бота отклоняется.
  Future<Bot> setEnabled({required int botId, required bool enabled}) =>
      _setBotEnabledRpc(botId: botId, enabled: enabled);

  /// Добавить бота в комнату (идемпотентно).
  Future<void> addToRoom({required int botId, required int roomId}) =>
      _addBotToRoomRpc(botId: botId, roomId: roomId);

  /// **issue #50 follow-up**: id комнат, где бот уже состоит. Пустое
  /// множество при старом сервере или сбое — тогда пикер просто никого
  /// не помечает, как раньше (деградация без поломки).
  Future<Set<int>> listBotRoomIds({required int botId}) async {
    final rpc = _listBotRoomIdsRpc;
    if (rpc == null) return const <int>{};
    try {
      return (await rpc(botId: botId)).toSet();
    } on Object {
      return const <int>{};
    }
  }

  /// **issue #50**: комнаты для пикера «добавить бота в комнату» — ВСЕ
  /// активные комнаты tenant-а, а не только те, где состоит сам админ.
  ///
  /// На старом сервере (метода ещё нет) или без wiring-а честно
  /// откатываемся на прежнее поведение — список собственных комнат:
  /// урезанный пикер лучше сломанного.
  Future<List<RoomSummary>> listAllRooms({int limit = 200}) async {
    final rpc = _listAllRoomsRpc;
    if (rpc == null) {
      return MessengerRuntime.instance.rooms.list(limit: limit);
    }
    try {
      return await rpc(limit: limit);
    } on Object {
      return MessengerRuntime.instance.rooms.list(limit: limit);
    }
  }

  /// Журнал событий бота, свежие сверху: кто завёл/ротировал/выключал и во
  /// что бот ломился без grant-а (`capability_denied`).
  Future<List<BotAuditEvent>> listAuditEvents({
    required int botId,
    int limit = 100,
  }) => _listAuditEventsRpc(botId: botId, limit: limit);
}
