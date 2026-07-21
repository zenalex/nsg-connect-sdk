import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK58 (incoming webhooks / автопост статусов)**: публичный API для
/// управления входящими webhook-ами (автопостами) комнаты. Доступен через
/// `NsgMessenger.integrations`; используется `IntegrationsScreen`.
///
/// **TASK59 (self-service бот-интеграции)**: те же методы дублированы для
/// `client.botIntegration.*` (create/list/rotateSecret/setEnabled/delete) —
/// секция «Боты» на том же экране.
///
/// Тонкая обёртка над сгенерированными Serverpod-эндпоинтами
/// `client.incomingWebhook.*` / `client.botIntegration.*`. Каждый RPC
/// оборачивается в [withAuthRetry]
/// для self-heal на серверный auth-invalidation (тот же приём, что в
/// [NsgMessengerRooms]) — [MessengerSessionManager] резолвится лениво через
/// singleton runtime, closures выполняются уже после `init()`.
///
/// Кэша нет: список webhook-ов открывается редко (админ-экран интеграций),
/// каждый `list()` дёргает сервер. Мутации (`create`/`rotate`/`setEnabled`/
/// `delete`) сервер применяет атомарно; экран сам перезапрашивает список.
///
/// Сигнатуры RPC вынесены в typedef-ы для инъекции fake-ов в тестах
/// ([NsgMessengerIntegrations.withRpcs]) — так тесты не зависят от Serverpod-
/// клиента и runtime singleton-а.
typedef ListWebhooksRpc =
    Future<List<IncomingWebhook>> Function({required int roomId});
typedef CreateWebhookRpc =
    Future<IncomingWebhookCreated> Function({
      required int roomId,
      required String name,
    });
typedef RotateTokenRpc =
    Future<IncomingWebhookCreated> Function({required int id});
typedef SetWebhookEnabledRpc =
    Future<IncomingWebhook> Function({required int id, required bool enabled});
typedef DeleteWebhookRpc = Future<void> Function({required int id});
typedef TestPostWebhookRpc = Future<void> Function({required int id});

// **TASK59 (self-service бот-интеграции)**: сигнатуры RPC для
// `client.botIntegration.*`. Так же вынесены в typedef-ы для fake-инъекции
// в тестах ([NsgMessengerIntegrations.withRpcs]).
typedef ListBotIntegrationsRpc =
    Future<List<BotIntegrationView>> Function({required int roomId});
typedef CreateBotIntegrationRpc =
    Future<BotIntegrationCreated> Function({
      required int roomId,
      required String name,
      required String webhookUrl,
      required String eventTypes,
    });
typedef RotateWebhookSecretRpc =
    Future<BotIntegrationCreated> Function({required int botId});
typedef SetBotEnabledRpc =
    Future<void> Function({required int botId, required bool enabled});
typedef DeleteBotIntegrationRpc = Future<void> Function({required int botId});

class NsgMessengerIntegrations {
  NsgMessengerIntegrations._({
    required ListWebhooksRpc listWebhooksRpc,
    required CreateWebhookRpc createWebhookRpc,
    required RotateTokenRpc rotateTokenRpc,
    required SetWebhookEnabledRpc setEnabledRpc,
    required DeleteWebhookRpc deleteWebhookRpc,
    required TestPostWebhookRpc testPostRpc,
    required ListBotIntegrationsRpc listBotIntegrationsRpc,
    required CreateBotIntegrationRpc createBotIntegrationRpc,
    required RotateWebhookSecretRpc rotateWebhookSecretRpc,
    required SetBotEnabledRpc setBotEnabledRpc,
    required DeleteBotIntegrationRpc deleteBotIntegrationRpc,
  }) : _listWebhooksRpc = listWebhooksRpc,
       _createWebhookRpc = createWebhookRpc,
       _rotateTokenRpc = rotateTokenRpc,
       _setEnabledRpc = setEnabledRpc,
       _deleteWebhookRpc = deleteWebhookRpc,
       _testPostRpc = testPostRpc,
       _listBotIntegrationsRpc = listBotIntegrationsRpc,
       _createBotIntegrationRpc = createBotIntegrationRpc,
       _rotateWebhookSecretRpc = rotateWebhookSecretRpc,
       _setBotEnabledRpc = setBotEnabledRpc,
       _deleteBotIntegrationRpc = deleteBotIntegrationRpc;

  final ListWebhooksRpc _listWebhooksRpc;
  final CreateWebhookRpc _createWebhookRpc;
  final RotateTokenRpc _rotateTokenRpc;
  final SetWebhookEnabledRpc _setEnabledRpc;
  final DeleteWebhookRpc _deleteWebhookRpc;
  final TestPostWebhookRpc _testPostRpc;
  final ListBotIntegrationsRpc _listBotIntegrationsRpc;
  final CreateBotIntegrationRpc _createBotIntegrationRpc;
  final RotateWebhookSecretRpc _rotateWebhookSecretRpc;
  final SetBotEnabledRpc _setBotEnabledRpc;
  final DeleteBotIntegrationRpc _deleteBotIntegrationRpc;

  /// Дефолтный набор webhook-событий для новой бот-интеграции (совпадает с
  /// серверным `BotIntegrationEndpoint.defaultEventTypes`). Сервер повторно
  /// санитайзит/пересекает с allow-list-ом, поэтому это лишь стартовое
  /// значение — итоговый набор берём из ответа (`subscription.eventTypes`).
  static const String kDefaultBotEventTypes =
      'message.created,user.joined,user.left,user.removed';

  /// Production-фабрика. Привязывается к `client.incomingWebhook.*` методам,
  /// каждый под [withAuthRetry]. `session()` резолвит session-manager лениво
  /// из runtime (closures выполняются после `init()`).
  static NsgMessengerIntegrations attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return withRpcs(
      listWebhooksRpc: ({required int roomId}) => withAuthRetry(
        () => client.incomingWebhook.listWebhooks(roomId: roomId),
        session(),
      ),
      createWebhookRpc: ({required int roomId, required String name}) =>
          withAuthRetry(
            () => client.incomingWebhook.createWebhook(
              roomId: roomId,
              name: name,
            ),
            session(),
          ),
      rotateTokenRpc: ({required int id}) => withAuthRetry(
        () => client.incomingWebhook.rotateToken(id: id),
        session(),
      ),
      setEnabledRpc: ({required int id, required bool enabled}) => withAuthRetry(
        () => client.incomingWebhook.setEnabled(id: id, enabled: enabled),
        session(),
      ),
      deleteWebhookRpc: ({required int id}) => withAuthRetry(
        () => client.incomingWebhook.deleteWebhook(id: id),
        session(),
      ),
      testPostRpc: ({required int id}) => withAuthRetry(
        () => client.incomingWebhook.testPost(id: id),
        session(),
      ),
      listBotIntegrationsRpc: ({required int roomId}) => withAuthRetry(
        () => client.botIntegration.listBotIntegrations(roomId: roomId),
        session(),
      ),
      createBotIntegrationRpc:
          ({
            required int roomId,
            required String name,
            required String webhookUrl,
            required String eventTypes,
          }) => withAuthRetry(
            () => client.botIntegration.createBotIntegration(
              roomId: roomId,
              name: name,
              webhookUrl: webhookUrl,
              eventTypes: eventTypes,
            ),
            session(),
          ),
      rotateWebhookSecretRpc: ({required int botId}) => withAuthRetry(
        () => client.botIntegration.rotateWebhookSecret(botId: botId),
        session(),
      ),
      setBotEnabledRpc: ({required int botId, required bool enabled}) =>
          withAuthRetry(
            () =>
                client.botIntegration.setEnabled(botId: botId, enabled: enabled),
            session(),
          ),
      deleteBotIntegrationRpc: ({required int botId}) => withAuthRetry(
        () => client.botIntegration.deleteBotIntegration(botId: botId),
        session(),
      ),
    );
  }

  /// Test-фабрика: инъекция fake-RPC (без Serverpod-клиента / runtime).
  static NsgMessengerIntegrations withRpcs({
    required ListWebhooksRpc listWebhooksRpc,
    required CreateWebhookRpc createWebhookRpc,
    required RotateTokenRpc rotateTokenRpc,
    required SetWebhookEnabledRpc setEnabledRpc,
    required DeleteWebhookRpc deleteWebhookRpc,
    required TestPostWebhookRpc testPostRpc,
    required ListBotIntegrationsRpc listBotIntegrationsRpc,
    required CreateBotIntegrationRpc createBotIntegrationRpc,
    required RotateWebhookSecretRpc rotateWebhookSecretRpc,
    required SetBotEnabledRpc setBotEnabledRpc,
    required DeleteBotIntegrationRpc deleteBotIntegrationRpc,
  }) => NsgMessengerIntegrations._(
    listWebhooksRpc: listWebhooksRpc,
    createWebhookRpc: createWebhookRpc,
    rotateTokenRpc: rotateTokenRpc,
    setEnabledRpc: setEnabledRpc,
    deleteWebhookRpc: deleteWebhookRpc,
    testPostRpc: testPostRpc,
    listBotIntegrationsRpc: listBotIntegrationsRpc,
    createBotIntegrationRpc: createBotIntegrationRpc,
    rotateWebhookSecretRpc: rotateWebhookSecretRpc,
    setBotEnabledRpc: setBotEnabledRpc,
    deleteBotIntegrationRpc: deleteBotIntegrationRpc,
  );

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Список webhook-ов (автопостов) комнаты — вкладка «Интеграции».
  Future<List<IncomingWebhook>> listWebhooks({required int roomId}) =>
      _listWebhooksRpc(roomId: roomId);

  /// Создать автопост: заводит бота-подпорку, добавляет его в комнату, генерит
  /// токен. Возвращает webhook + публичный токен — **показывается один раз**
  /// (в БД хранится только его хеш).
  Future<IncomingWebhookCreated> createWebhook({
    required int roomId,
    required String name,
  }) => _createWebhookRpc(roomId: roomId, name: name);

  /// Ротация токена: новый публичный токен, тот же бот (имя/история постов
  /// сохраняются). Старый токен немедленно перестаёт резолвиться.
  Future<IncomingWebhookCreated> rotateToken({required int id}) =>
      _rotateTokenRpc(id: id);

  /// Включить/выключить webhook без удаления.
  Future<IncomingWebhook> setEnabled({
    required int id,
    required bool enabled,
  }) => _setEnabledRpc(id: id, enabled: enabled);

  /// Удалить webhook (idempotent). Гасит бота-подпорку.
  Future<void> deleteWebhook({required int id}) => _deleteWebhookRpc(id: id);

  /// Тестовый пост — платформа сама шлёт пример статус-карточки в комнату
  /// (проверка рендера без внешнего процесса).
  Future<void> testPost({required int id}) => _testPostRpc(id: id);

  // ───────────────────────────────────────────────────────────────────
  // TASK59 — self-service бот-интеграции (client.botIntegration.*)
  // ───────────────────────────────────────────────────────────────────

  /// Список бот-интеграций комнаты (безопасный вид, без токенов/секретов) —
  /// секция «Боты» на экране «Интеграции».
  Future<List<BotIntegrationView>> listBotIntegrations({
    required int roomId,
  }) => _listBotIntegrationsRpc(roomId: roomId);

  /// Создать бот-интеграцию: заводит бота (`send_messages`) в комнате +
  /// room-scoped подписку на webhook-URL разработчика. Возвращает bot-токен
  /// + webhook-секрет + apiBase — **показываются один раз** (в БД хранятся
  /// только хеши). [eventTypes] по умолчанию [kDefaultBotEventTypes]; сервер
  /// пересекает с allow-list-ом, итог — в `subscription.eventTypes`.
  Future<BotIntegrationCreated> createBotIntegration({
    required int roomId,
    required String name,
    required String webhookUrl,
    String eventTypes = kDefaultBotEventTypes,
  }) => _createBotIntegrationRpc(
    roomId: roomId,
    name: name,
    webhookUrl: webhookUrl,
    eventTypes: eventTypes,
  );

  /// Ротация webhook-секрета (тот же бот). Старая HMAC-подпись немедленно
  /// перестаёт совпадать. Возвращает новый секрет — **показывается один раз**.
  Future<BotIntegrationCreated> rotateWebhookSecret({required int botId}) =>
      _rotateWebhookSecretRpc(botId: botId);

  /// Включить/выключить бот-интеграцию (бот + подписка вместе). `enabled=true`
  /// сбрасывает circuit-breaker подписки.
  Future<void> setBotIntegrationEnabled({
    required int botId,
    required bool enabled,
  }) => _setBotEnabledRpc(botId: botId, enabled: enabled);

  /// Удалить бот-интеграцию (idempotent): удаляет подписку, гасит бота.
  Future<void> deleteBotIntegration({required int botId}) =>
      _deleteBotIntegrationRpc(botId: botId);
}
