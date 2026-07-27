import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_bots_admin.dart';
import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **Issue #49 (открытая платформа ботов)**: публичный API self-service
/// «Мои боты» — для ОБЫЧНОГО пользователя, в отличие от админской
/// [NsgMessengerBotsAdmin] (BOT_ADMIN_EMAILS, все боты tenant-а). Скоуп
/// решает сервер: `client.myBots.*` отдаёт только ботов, чей `ownerEmail`
/// совпадает с email caller-а; чужой botId неотличим от несуществующего
/// ([BotNotFoundException], anti-enumeration).
///
/// Доступен через `NsgMessenger.myBots`; используется `MyBotsScreen`.
///
/// Тонкая обёртка над сгенерированными Serverpod-эндпоинтами; каждый RPC
/// под [withAuthRetry] — тот же приём, что в [NsgMessengerBotsAdmin].
/// Кэша нет — экран открывается редко.
///
/// Сигнатуры вынесены в typedef-ы для инъекции fake-ов в тестах
/// ([NsgMessengerMyBots.withRpcs]).
typedef MyBotsListRpc = Future<List<Bot>> Function();
typedef MyBotsCreateRpc =
    Future<Bot> Function({
      required String name,
      required String capabilities,
      required bool discoverable,
      // **TASK77 итер.2**: режим чтения (`read_addressed` / `read_all`).
      required String readMode,
    });
typedef MyBotsRotateTokenRpc = Future<Bot> Function({required int botId});
typedef MyBotsSetEnabledRpc =
    Future<Bot> Function({required int botId, required bool enabled});
/// **TASK77 итер.3**: ответ несёт не только бота, но и число webhook-
/// подписок БЕЗ `botId`, покрывающих его комнаты — каналы, где privacy mode
/// не сработает.
typedef MyBotsSetReadModeRpc =
    Future<BotReadModeResult> Function({
      required int botId,
      required String readMode,
    });
typedef MyBotsSetDiscoverableRpc =
    Future<Bot> Function({required int botId, required bool discoverable});
/// **TASK77 итер.3**: описание бота для каталога/карточки.
typedef MyBotsSetDescriptionRpc =
    Future<Bot> Function({required int botId, required String description});
typedef MyBotsListRoomsRpc =
    Future<List<RoomSummary>> Function({required int botId});
typedef MyBotsRemoveFromRoomRpc =
    Future<void> Function({required int botId, required int roomId});
typedef MyBotsListAuditEventsRpc =
    Future<List<BotAuditEvent>> Function({
      required int botId,
      required int limit,
    });

class NsgMessengerMyBots {
  NsgMessengerMyBots._({
    required MyBotsListRpc listRpc,
    required MyBotsCreateRpc createRpc,
    required MyBotsRotateTokenRpc rotateTokenRpc,
    required MyBotsSetEnabledRpc setEnabledRpc,
    required MyBotsSetDiscoverableRpc setDiscoverableRpc,
    required MyBotsSetReadModeRpc setReadModeRpc,
    required MyBotsSetDescriptionRpc setDescriptionRpc,
    required MyBotsListRoomsRpc listRoomsRpc,
    required MyBotsRemoveFromRoomRpc removeFromRoomRpc,
    required MyBotsListAuditEventsRpc listAuditEventsRpc,
  }) : _listRpc = listRpc,
       _createRpc = createRpc,
       _rotateTokenRpc = rotateTokenRpc,
       _setEnabledRpc = setEnabledRpc,
       _setDiscoverableRpc = setDiscoverableRpc,
       _setReadModeRpc = setReadModeRpc,
       _setDescriptionRpc = setDescriptionRpc,
       _listRoomsRpc = listRoomsRpc,
       _removeFromRoomRpc = removeFromRoomRpc,
       _listAuditEventsRpc = listAuditEventsRpc;

  final MyBotsListRpc _listRpc;
  final MyBotsCreateRpc _createRpc;
  final MyBotsRotateTokenRpc _rotateTokenRpc;
  final MyBotsSetEnabledRpc _setEnabledRpc;
  final MyBotsSetDiscoverableRpc _setDiscoverableRpc;
  final MyBotsSetReadModeRpc _setReadModeRpc;
  final MyBotsSetDescriptionRpc _setDescriptionRpc;
  final MyBotsListRoomsRpc _listRoomsRpc;
  final MyBotsRemoveFromRoomRpc _removeFromRoomRpc;
  final MyBotsListAuditEventsRpc _listAuditEventsRpc;

  /// Production-фабрика: привязка к `client.myBots.*`, каждый под
  /// [withAuthRetry]. `session()` резолвит session-manager лениво из
  /// runtime (closures выполняются после `init()`).
  static NsgMessengerMyBots attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return withRpcs(
      listRpc: () => withAuthRetry(() => client.myBots.list(), session()),
      createRpc:
          ({
            required String name,
            required String capabilities,
            required bool discoverable,
            required String readMode,
          }) => withAuthRetry(
            () => client.myBots.create(
              name: name,
              capabilities: capabilities,
              discoverable: discoverable,
              readMode: readMode,
            ),
            session(),
          ),
      rotateTokenRpc: ({required int botId}) => withAuthRetry(
        () => client.myBots.rotateToken(botId: botId),
        session(),
      ),
      setEnabledRpc: ({required int botId, required bool enabled}) =>
          withAuthRetry(
            () => client.myBots.setEnabled(botId: botId, enabled: enabled),
            session(),
          ),
      setDiscoverableRpc: ({required int botId, required bool discoverable}) =>
          withAuthRetry(
            () => client.myBots.setDiscoverable(
              botId: botId,
              discoverable: discoverable,
            ),
            session(),
          ),
      setReadModeRpc: ({required int botId, required String readMode}) =>
          withAuthRetry(
            () =>
                client.myBots.setReadMode(botId: botId, readMode: readMode),
            session(),
          ),
      setDescriptionRpc: ({required int botId, required String description}) =>
          withAuthRetry(
            () => client.myBots.setDescription(
              botId: botId,
              description: description,
            ),
            session(),
          ),
      listRoomsRpc: ({required int botId}) => withAuthRetry(
        () => client.myBots.listRooms(botId: botId),
        session(),
      ),
      removeFromRoomRpc: ({required int botId, required int roomId}) =>
          withAuthRetry(
            () => client.myBots.removeFromRoom(botId: botId, roomId: roomId),
            session(),
          ),
      listAuditEventsRpc: ({required int botId, required int limit}) =>
          withAuthRetry(
            () => client.myBots.listAuditEvents(botId: botId, limit: limit),
            session(),
          ),
    );
  }

  /// Test-фабрика: инъекция fake-RPC (без Serverpod-клиента / runtime).
  static NsgMessengerMyBots withRpcs({
    required MyBotsListRpc listRpc,
    required MyBotsCreateRpc createRpc,
    required MyBotsRotateTokenRpc rotateTokenRpc,
    required MyBotsSetEnabledRpc setEnabledRpc,
    required MyBotsSetDiscoverableRpc setDiscoverableRpc,
    required MyBotsSetReadModeRpc setReadModeRpc,
    required MyBotsSetDescriptionRpc setDescriptionRpc,
    required MyBotsListRoomsRpc listRoomsRpc,
    required MyBotsRemoveFromRoomRpc removeFromRoomRpc,
    required MyBotsListAuditEventsRpc listAuditEventsRpc,
  }) => NsgMessengerMyBots._(
    listRpc: listRpc,
    createRpc: createRpc,
    rotateTokenRpc: rotateTokenRpc,
    setEnabledRpc: setEnabledRpc,
    setDiscoverableRpc: setDiscoverableRpc,
    setReadModeRpc: setReadModeRpc,
    setDescriptionRpc: setDescriptionRpc,
    listRoomsRpc: listRoomsRpc,
    removeFromRoomRpc: removeFromRoomRpc,
    listAuditEventsRpc: listAuditEventsRpc,
  );

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Свои боты. `accessToken` в моделях ПУСТ — сервер зануляет его;
  /// credential виден только в момент выдачи ([create] / [rotateToken]).
  Future<List<Bot>> list() => _listRpc();

  /// Завести своего бота. Владелец — caller (email на сервере, не
  /// параметр). Возвращённый [Bot] несёт `accessToken` — **показать один
  /// раз**. Превышение лимита — [BotLimitExceededException] с числом.
  ///
  /// [readMode] — режим чтения (TASK77 итер.2): дефолт
  /// `read_addressed` (бот видит только обращения к себе), `read_all` —
  /// осознанный выбор «читает всё».
  Future<Bot> create({
    required String name,
    required String capabilities,
    bool discoverable = false,
    String readMode = NsgMessengerBotsAdmin.readModeAddressed,
  }) => _createRpc(
    name: name,
    capabilities: capabilities,
    discoverable: discoverable,
    readMode: readMode,
  );

  /// Ротация credential-а: новый `accessToken`, прежние отозваны
  /// немедленно; бот, комнаты и история сохраняются. Ответ несёт новый
  /// токен — **показать один раз**.
  Future<Bot> rotateToken({required int botId}) =>
      _rotateTokenRpc(botId: botId);

  /// Kill-switch: `enabled=false` → gated-действия бота отклоняются.
  Future<Bot> setEnabled({required int botId, required bool enabled}) =>
      _setEnabledRpc(botId: botId, enabled: enabled);

  /// Видимость бота в поиске. Выключено — бота нельзя найти и позвать в
  /// чужую комнату; существующие членства не трогаются ([removeFromRoom]).
  Future<Bot> setDiscoverable({
    required int botId,
    required bool discoverable,
  }) => _setDiscoverableRpc(botId: botId, discoverable: discoverable);

  /// **TASK77 итер.2**: режим чтения бота — `read_addressed` (только
  /// обращения) либо `read_all` (вся переписка его комнат). Смена пишется в
  /// аудит на сервере.
  ///
  /// **TASK77 итер.3**: в ответе — [BotReadModeResult.unboundSubscriptionCount]:
  /// сколько webhook-подписок БЕЗ привязки к боту покрывают его комнаты. При
  /// `read_addressed` это ровно те каналы, где приватность не подействует
  /// (фильтровать нечем — у подписки нет владельца-бота); UI обязан сказать
  /// это вслух, а не промолчать.
  Future<BotReadModeResult> setReadMode({
    required int botId,
    required String readMode,
  }) => _setReadModeRpc(botId: botId, readMode: readMode);

  /// **TASK77 итер.3**: описание бота — то, что читают в каталоге и в
  /// карточке, решая, пускать ли программу в свою группу. Пустая строка
  /// стирает описание.
  Future<Bot> setDescription({
    required int botId,
    required String description,
  }) => _setDescriptionRpc(botId: botId, description: description);

  /// Комнаты бота — владелец видит, куда его бота позвали (добавление
  /// discoverable-бота свободно, контроль постфактум: список + отзыв).
  Future<List<RoomSummary>> listRooms({required int botId}) =>
      _listRoomsRpc(botId: botId);

  /// Отозвать бота из комнаты (Matrix-leave + удаление членства).
  Future<void> removeFromRoom({required int botId, required int roomId}) =>
      _removeFromRoomRpc(botId: botId, roomId: roomId);

  /// Журнал бота, свежие сверху — тот же формат, что в админке.
  Future<List<BotAuditEvent>> listAuditEvents({
    required int botId,
    int limit = 100,
  }) => _listAuditEventsRpc(botId: botId, limit: limit);
}
