import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'auth_token_provider.dart';
import 'calls/call_controller.dart';
import 'demo/demo_fixtures.dart';
import 'demo/demo_runtime.dart';
import 'i18n/generated/nsg_l10n.dart';
import 'contact_card/nsg_messenger_contact_cards.dart';
import 'contacts/nsg_messenger_contacts.dart';
import 'admin/nsg_messenger_bots_admin.dart';
import 'admin/nsg_messenger_platform_admin.dart';
import 'bots/nsg_messenger_my_bots.dart';
import 'integrations/nsg_messenger_integrations.dart';
import 'messages/messages_controller.dart';
import 'messages/messages_rpc.dart';
import 'messenger_mode.dart';
import 'messenger_runtime.dart';
import 'messenger_session_state.dart';
import 'push/push_token_provider.dart';
import 'rooms/nsg_messenger_rooms.dart';
import 'runtime/messenger_connection_state.dart';
import 'runtime/nsg_messenger_config.dart';
import 'screens/chat_screen.dart';
import 'screens/chats_list_screen.dart';
import 'screens/contact_profile_screen.dart';
import 'screens/contact_requests_screen.dart';
import 'screens/people_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/object_rooms_catalog_screen.dart';
import 'screens/support_chat_screen.dart';
import 'screens/support_team_screen.dart';
import 'session/auth_retry.dart';
import 'session/auth_token_store.dart';
import 'share/share_intake.dart';
import 'share/shared_payload.dart';
import 'theme/messenger_theme_scope.dart';
import 'theme/nsg_messenger_theme.dart';

/// Главный entry-point Flutter SDK NSG Connect.
///
/// Все методы статические — host-app не управляет lifecycle вручную,
/// SDK сам держит singleton (`MessengerRuntime`).
///
/// **На TASK11**: skeleton + публичный API. Реализация экранов —
/// TASK14 / TASK15 / TASK22.
class NsgMessenger {
  NsgMessenger._();

  /// Главный entry-point.
  ///
  /// `authTokenProvider` — обязательный callback, через который SDK
  /// получает свежий `MessengerAuthContext` (см. TASK12 для полной
  /// спецификации). SDK НЕ хранит customer accessToken; он каждый раз
  /// запрашивается у provider-а при init и при каждом refresh.
  /// `tokenStoreOverride` — visible-for-testing: позволяет подменить
  /// `flutter_secure_storage` на `InMemoryAuthTokenStore` в виджет- и
  /// integration-тестах host-app-а без MethodChannel-моков. В production
  /// host-app не передаёт — SDK использует `SecureAuthTokenStore`.
  /// Подключить трекер ошибок ДО [init] — вызывать на boot приложения
  /// (сразу после инициализации самого трекера). Без этого ошибки экрана
  /// ВХОДА уходили в никуда: [init] зовётся только после логина, а до
  /// него `MessengerRuntime.reportError` был no-op. Идемпотентно; [init]
  /// не перезатрёт репортер, подключённый здесь.
  static void configureErrorReporter(ErrorReporter reporter) =>
      MessengerRuntime.instance.configureErrorReporter(reporter);

  static Future<void> init({
    required String apiBaseUrl,
    required AuthTokenProvider authTokenProvider,
    NsgMessengerTheme? theme,
    NsgMessengerLocale? locale,
    MessengerMode mode = MessengerMode.embeddedProduct,
    ErrorReporter? errorReporter,
    @visibleForTesting AuthTokenStore? tokenStoreOverride,
    PushTokenProvider? pushTokenProvider,
    String? productExternalKey,
    NsgMessengerConfig? config,
    bool enableOfflineCache = true,
    String? cacheDirectoryOverride,
    String? hooksBaseUrl,
  }) {
    return MessengerRuntime.instance.init(
      apiBaseUrl: apiBaseUrl,
      authTokenProvider: authTokenProvider,
      theme: theme,
      locale: locale,
      mode: mode,
      errorReporter: errorReporter,
      tokenStoreOverride: tokenStoreOverride,
      pushTokenProvider: pushTokenProvider,
      productExternalKey: productExternalKey,
      config: config,
      enableOfflineCache: enableOfflineCache,
      cacheDirectoryOverride: cacheDirectoryOverride,
      hooksBaseUrl: hooksBaseUrl,
    );
  }

  /// **TASK47**: очистить дисковый оффлайн-кэш чатов текущего пользователя.
  /// Host-app вызывает при ЛОГАУТЕ (§3 п.3) перед сменой аккаунта. Кэш
  /// скоуплен по userId — чистит только вышедшего. No-op если кэш выключен
  /// (web / не инициализирован).
  static Future<void> clearOfflineCache() =>
      MessengerRuntime.instance.clearOfflineCache();

  // ─── TASK47 iter2: дисковый кэш вложений (превью картинок) ──────────

  /// Сентинел «без лимита» кэша вложений (см. [setAttachmentCacheLimitBytes]).
  static const int unlimitedAttachmentCacheLimit =
      kUnlimitedAttachmentCacheLimit;

  /// Дефолтный лимит кэша вложений (200 МБ).
  static const int defaultAttachmentCacheLimitBytes =
      kDefaultAttachmentCacheLimitBytes;

  /// **TASK47 iter2**: доступен ли дисковый кэш вложений (mobile/desktop с
  /// открытым store). `false` на web / до init — host прячет секцию
  /// «Хранилище» в настройках.
  static bool get isAttachmentCacheAvailable =>
      MessengerRuntime.instance.isAttachmentCacheAvailable;

  /// **TASK47 iter2**: текущий мягкий лимит кэша вложений (байт). `< 0` —
  /// «без лимита».
  static int get attachmentCacheLimitBytes =>
      MessengerRuntime.instance.attachmentCacheLimitBytes;

  /// **TASK47 iter2**: сменить лимит кэша вложений. Host хранит выбор в своих
  /// настройках (Chatista — flutter_secure_storage) и прокидывает сюда при
  /// старте и на изменение. Отрицательное значение / [unlimitedAttachmentCacheLimit]
  /// — «без лимита». Применяет обрезку под новый лимит немедленно (best-effort).
  static void setAttachmentCacheLimitBytes(int bytes) =>
      MessengerRuntime.instance.setAttachmentCacheLimitBytes(bytes);

  /// **TASK47 iter2**: суммарный размер кэша вложений (байт) для UI. `0`, если
  /// кэш выключен.
  static Future<int> attachmentCacheSizeBytes() =>
      MessengerRuntime.instance.attachmentCacheSizeBytes();

  /// **TASK47 iter2**: очистить кэш вложений текущего пользователя (кнопка
  /// «Очистить кэш»). No-op, если кэш выключен.
  static Future<void> clearAttachmentCache() =>
      MessengerRuntime.instance.clearAttachmentCache();

  /// **TASK22-Phase2 Chunk 2 PART C**: headless demo mode for design
  /// exploration. Bypasses real Client / WebSocket / RPC — backs SDK
  /// widgets with in-memory [DemoRoomFixture] / [DemoMessageFixture]
  /// lists so a designer can iterate on theming without a running
  /// backend.
  ///
  /// **NOT for production use.** Throws [StateError] if called twice
  /// or after [init].
  ///
  /// Limitations vs production [init]:
  ///   * `NsgMessenger.rooms.get(roomId)` returns the fixture details,
  ///     `list(...)` returns the fixture summaries; mutating RPCs
  ///     (mute/archive/leave/...) are no-ops.
  ///   * `NsgMessenger.userEventStream` never emits — demo runtime
  ///     has no realtime backend.
  ///   * Send/edit/delete/upload from ChatScreen throw
  ///     `UnimplementedError` (read-only). Wrap ChatScreen in
  ///     `readOnly: true` to hide MessageComposer entirely.
  ///   * `sessionStateStream()` immediately emits `active`.
  ///
  /// Customer integration walkthrough — use [init] instead.
  static Future<void> initDemo({
    required List<DemoRoomFixture> rooms,
    List<DemoMessageFixture> messages = const [],
    NsgMessengerTheme? theme,
    NsgMessengerLocale? locale,
    NsgMessengerConfig? config,
  }) async {
    final data = DemoRuntimeData.fromFixtures(
      rooms: rooms,
      messages: messages,
      selfMessengerUserId: -1,
      selfMatrixUserId: '@demo-self:demo',
    );
    await installDemoRuntime(
      data: data,
      theme: theme ?? NsgMessengerTheme.empty,
      locale: locale ?? const NsgMessengerLocale(),
      config: config,
    );
    // Stash the demo data on the runtime so `demoChatScreen` can
    // build a MessagesController without a real Client.
    _demoData = data;
  }

  /// **TASK22-Phase2 Chunk 2 PART C**: build a [ChatScreen] backed by
  /// the demo fixtures registered via [initDemo]. Wires up a
  /// `MessagesController` whose `MessagesRpc` reads from the in-memory
  /// fixture map and passes it via `controllerOverride` so the
  /// production code path (which needs `MessengerRuntime.client`) is
  /// bypassed.
  ///
  /// `readOnly: true` hides the `MessageComposer` — recommended for
  /// demo use since send is disabled at the RPC layer.
  static Widget demoChatScreen({required int roomId, bool readOnly = true}) {
    final data = _demoData;
    if (data == null) {
      throw StateError(
        'NsgMessenger.demoChatScreen() called before initDemo(). '
        'Call NsgMessenger.initDemo(rooms: ...) first.',
      );
    }
    final runtime = MessengerRuntime.instance;
    final controller = MessagesController(
      roomId: roomId,
      rpc: buildDemoMessagesRpc(data),
      events: runtime.eventBus.events,
      selfMessengerUserId: data.selfMessengerUserId,
      selfMatrixUserId: data.selfMatrixUserId,
    );
    return MessengerThemeScope(
      theme: runtime.theme,
      child: ChatScreen(
        roomId: roomId,
        // ignore: invalid_use_of_visible_for_testing_member
        controllerOverride: controller,
        readOnly: readOnly,
      ),
    );
  }

  /// **TASK22-Phase2 Chunk 2 PART C**: cached demo fixture bundle for
  /// [demoChatScreen]. Reset by [dispose] and overwritten by any
  /// subsequent [initDemo] (which the runtime guard already rejects).
  static DemoRuntimeData? _demoData;

  /// Принудительно сбросить кэш и заново получить контекст у provider-а.
  /// Нужно после logout/login в host-app.
  static Future<void> reauthenticate() =>
      MessengerRuntime.instance.reauthenticate();

  static Future<void> dispose() async {
    _demoData = null;
    await MessengerRuntime.instance.dispose();
  }

  /// Stream `MessengerSessionState`-ов: `uninitialised → refreshing →
  /// active`. Host-app может показывать на основе этого баннер
  /// "соединение восстанавливается" / "session истекла".
  static Stream<MessengerSessionState> sessionStateStream() =>
      MessengerRuntime.instance.stateStream;

  /// **TASK20 followup (a)**: stream `MessengerConnectionState`-ов
  /// (`healthy → reconnecting → disconnected`). Separate axis from
  /// `sessionStateStream` — transport (WS) health, не auth/login.
  ///
  /// Token cache **НЕ trogается** при transport failures — auth
  /// invalidation отдельный axis. Host-app может embed
  /// [ConnectionStateIndicator] widget в AppBar чтобы рисовать
  /// traffic-light circle.
  static Stream<MessengerConnectionState> connectionStateStream() =>
      MessengerRuntime.instance.connectionStateStream;

  /// Current value of [connectionStateStream]. Default — `healthy`.
  static MessengerConnectionState get connectionState =>
      MessengerRuntime.instance.connectionState;

  /// **TASK20 followup (a)**: запросить immediate reconnect bus's WS.
  /// No-op если bus уже healthy. Идемпотентно. Полезно для host-app
  /// если он сам хочет принудительно проверить здоровье (например при
  /// tap по [ConnectionStateIndicator]).
  static void forceReconnect() =>
      MessengerRuntime.instance.eventBus.forceReconnect();

  /// API для работы с комнатами: list/get/createDirect/createGroup/
  /// getOrCreateProductRoom/openSupportChat. См. [NsgMessengerRooms].
  /// Включает in-memory cache 30s + invalidation на realtime events.
  static NsgMessengerRooms get rooms => MessengerRuntime.instance.rooms;

  /// **TASK63**: организация контактов — per-viewer «своё имя» (alias),
  /// приватная заметка и метки. См. [NsgMessengerContacts] и
  /// [ContactProfileScreen].
  static NsgMessengerContacts get contacts =>
      MessengerRuntime.instance.contacts;

  /// **TASK52 итер.1**: личные визитки (Contact Card) — чужие с TTL-кэшем
  /// и prefetch-ем для экрана звонка, своя — для редактора. См.
  /// [NsgMessengerContactCards], [ContactCardEditorScreen].
  static NsgMessengerContactCards get contactCards =>
      MessengerRuntime.instance.contactCards;

  /// **TASK58 (incoming webhooks / автопост статусов)**: API управления
  /// входящими webhook-ами (автопостами) комнаты — list/create/rotate/
  /// enable/delete/testPost. См. [NsgMessengerIntegrations]. Экран
  /// «Интеграции» открывается из настроек группы (owner/admin).
  static NsgMessengerIntegrations get integrations =>
      MessengerRuntime.instance.integrations;

  /// **TASK36 (боты)**: API админки ботов — tenant-wide, в отличие от
  /// room-scoped [integrations]: list/create/rotateToken/setEnabled/
  /// addToRoom/listAuditEvents. См. [NsgMessengerBotsAdmin]. Экран
  /// [BotsAdminScreen] открывается из настроек и виден только тем, чей
  /// email в серверном `BOT_ADMIN_EMAILS` (`isBotAdmin()`).
  static NsgMessengerBotsAdmin get botsAdmin =>
      MessengerRuntime.instance.botsAdmin;

  /// **TASK78 п.3 (админка секретов тенантов)**: API платформенной
  /// админки issued-token-режима — listTenants/enableAndGenerate/
  /// rotateSecret/disable/status/listAuditEvents. См.
  /// [NsgMessengerPlatformAdmin]. Экран [PlatformAdminScreen]
  /// открывается из настроек и виден только тем, чей email в серверном
  /// `PLATFORM_ADMIN_EMAILS` (`isPlatformAdmin()`).
  static NsgMessengerPlatformAdmin get platformAdmin =>
      MessengerRuntime.instance.platformAdmin;

  /// **Issue #49 (открытая платформа ботов)**: API «Моих ботов» —
  /// self-service ОБЫЧНОГО пользователя, без админ-гейта: list/create/
  /// rotateToken/setEnabled/setDiscoverable/listRooms/removeFromRoom.
  /// Скоуп (только свои боты, по ownerEmail) решает сервер. См.
  /// [NsgMessengerMyBots]; экран [MyBotsScreen] открывается из настроек
  /// и виден всем.
  static NsgMessengerMyBots get myBots => MessengerRuntime.instance.myBots;

  /// **TASK58**: базовый URL для отображаемого webhook-URL
  /// (`<hooksBaseUrl>/<token>`). Дефолт выводится из `apiBaseUrl` (dev →
  /// `localhost:5570/hooks`, прод `api.X` → `https://hooks.X`); override —
  /// через `init(hooksBaseUrl: 'https://hooks.chatista.me')`.
  static String get hooksBaseUrl => MessengerRuntime.instance.hooksBaseUrl;

  /// **TASK46 (SDK)**: контроллер голосовых звонков 1:1 (WebRTC поверх
  /// Matrix-сигналинга). `ChangeNotifier` — единый источник состояния
  /// звонка (`CallState`: idle/outgoingRinging/incomingRinging/
  /// connecting/connected/ended). Подписан на realtime с момента
  /// [init] — входящий звонок ловится на любом экране.
  ///
  /// UI (overlay входящего/исходящего/in-call) биндится к нему как к
  /// `ChangeNotifier`; команды: `startCall` / `accept` / `decline` /
  /// `hangup` / `toggleMute`.
  static CallController get callController => MessengerRuntime.instance.calls;

  /// **TASK46 (SDK)**: инициировать исходящий звонок в комнату
  /// [roomId] собеседнику [peerMessengerUserId] (для показа имени в UI).
  /// Тонкая обёртка над [callController].startCall. No-op если звонок
  /// уже активен. Подписаться на состояние — через [callController].
  static Future<void> startCall({
    required int roomId,
    int? peerMessengerUserId,
    String? peerDisplayName,
  }) => MessengerRuntime.instance.calls.startCall(
    roomId: roomId,
    peerMessengerUserId: peerMessengerUserId,
    peerDisplayName: peerDisplayName,
  );

  /// **TASK46 (звонки в фоне)**: дотянуть pending `callInvite` по [callId]
  /// с сервера и впрыснуть в [callController] (звонок зазвонит).
  ///
  /// Нужно, когда приложение разбудили push-ом на входящий из УБИТОГО
  /// состояния: live `m.call.invite` сервер уже consumed (чтобы послать
  /// push), realtime-стрим его не переиграет. Возвращает `true`, если
  /// invite найден и впрыснут; `false`, если звонок уже завершён/истёк
  /// (сервер отдал `null`). Идемпотентно с live-доставкой (см.
  /// `CallController.ingestFetchedInvite`).
  static Future<bool> fetchAndInjectCallInvite(String callId) async {
    final rt = MessengerRuntime.instance;
    final event = await withAuthRetry(
      () => rt.client.messenger.fetchCallInvite(callId: callId),
      rt.sessionManager,
    );
    if (event == null) return false;
    rt.calls.ingestFetchedInvite(event);
    return true;
  }

  /// **TASK46 (звонки в фоне, iOS)**: зарегистрировать PushKit VoIP-токен
  /// устройства как отдельную push-регистрацию (`pushService=voip`) — по
  /// ней сервер шлёт прямой APNs VoIP-push на входящий звонок, когда
  /// приложение свёрнуто/убито. Токен приходит из натива (PushKit
  /// `didUpdatePushCredentials`) через host-app (см. `CallKitBridge` +
  /// `AppDelegate.swift`). Идемпотентно; безопасно звать до `init()` —
  /// токен зарегистрируется, как только поднимется сессия. `null` снимает
  /// последнюю VoIP-регистрацию (PushKit отозвал токен).
  ///
  /// На устройстве могут сосуществовать FCM-регистрация (сообщения) и
  /// VoIP-регистрация (звонки) — это разные `DeviceRegistration`.
  static Future<void> registerVoipToken(String? token) =>
      MessengerRuntime.instance.registerVoipToken(token);

  /// **TASK46 (история звонков)**: список звонков текущего пользователя
  /// (входящие и исходящие), новейшие первыми — для вкладки «Звонки».
  /// Каждый [CallHistoryEntry] несёт `roomId` + `caller/calleeMessengerUserId`
  /// + `status`/`startedAt`/`durationSeconds`; host-app выводит направление
  /// per-viewer (сравнить с [session].messengerUserId) и резолвит имя
  /// собеседника по `roomId` из своего списка комнат. Обёрнуто в
  /// [withAuthRetry] (self-heal на token-rotation).
  static Future<List<CallHistoryEntry>> listCallHistory({int limit = 100}) {
    final rt = MessengerRuntime.instance;
    return withAuthRetry(
      () => rt.client.messenger.listCallHistory(limit: limit),
      rt.sessionManager,
    );
  }

  /// **TASK61 «Проверить пуш»**: ставит серверу тестовый пуш ТЕКУЩЕМУ
  /// пользователю на все его устройства с задержкой ([PushTestResult
  /// .delaySeconds], обычно 10с — чтобы успеть свернуть/закрыть приложение
  /// и проверить доставку в обоих состояниях). Возвращает сразу, ДО прихода
  /// пуша: сколько устройств и через каких провайдеров (`fcm`/`rustore`)
  /// придёт — host-app это показывает пользователю. Обёрнуто в
  /// [withAuthRetry] (self-heal на token-rotation).
  /// **TASK55 итер.1**: batch last-seen собеседников (≤50 id). Сервер
  /// отдаёт только по пользователям с общей комнатой; боты отброшены.
  /// **TASK55 итер.2b**: подписка на presence (идемпотентна, TTL ~5 мин
  /// на сервере — повторять при открытом чате). Возвращает снапшот;
  /// изменения придут событиями `presenceUpdated` в [userEventStream].
  static Future<List<PresenceInfo>> subscribePresence(List<int> userIds) {
    final rt = MessengerRuntime.instance;
    return withAuthRetry(
      () => rt.client.messenger.subscribePresence(userIds: userIds),
      rt.sessionManager,
    );
  }

  static Future<List<PresenceInfo>> getLastSeen(List<int> userIds) {
    final rt = MessengerRuntime.instance;
    return withAuthRetry(
      () => rt.client.messenger.getLastSeen(userIds: userIds),
      rt.sessionManager,
    );
  }

  static Future<PushTestResult> testPush() {
    final rt = MessengerRuntime.instance;
    return withAuthRetry(
      () => rt.client.messenger.testPush(),
      rt.sessionManager,
    );
  }

  /// **B20**: сменить SDK-тему в рантайме (light↔dark toggle, смена
  /// brand-акцента). SDK widget-фабрики (`chatsListView`, `openRoom`,
  /// `demoChatScreen`) читают тему на каждый build — после вызова
  /// host-app должен перестроить subtree (`setState`), и фабрики
  /// переинъектят новую тему. Решает «SDK-экран не следует за
  /// переключением темы» (intern QA B20).
  static void updateTheme(NsgMessengerTheme theme) =>
      MessengerRuntime.instance.updateTheme(theme);

  /// Текущая активная сессия — `messengerUserId`, `matrixUserId`,
  /// `displayName`, `avatarUrl`, и `sessionToken`. Host-app использует
  /// для отображения профиля и для self-vs-peer вычислений.
  ///
  /// Throws `StateError` если session ещё не установлена (init не
  /// завершён, либо token expired без re-auth). Host-app может
  /// подписаться на [sessionStateStream] чтобы знать состояние.
  static MessengerSession get session => MessengerRuntime.instance.session;

  /// **Avatar upload (B16-extension)**: загрузить аватар текущего юзера.
  ///
  /// Server:
  ///   1. Validate MIME (image/*).
  ///   2. Upload bytes в Matrix media → mxc:// URL.
  ///   3. Save в `MessengerUser.avatarUrl` (DB).
  ///   4. Best-effort `setAvatar` на Matrix profile (через Synapse Admin
  ///      API) — чтобы другие matrix-клиенты тоже увидели.
  ///
  /// Возвращает `mxcUrl`. Host-app после этого может:
  ///   * показать новый аватар у себя в profile screen-е;
  ///   * `rooms.invalidate()` чтобы при следующем listRooms RoomSummary
  ///     подтянул свежий avatarUrl (server computes для direct chats).
  ///
  /// Throws `MatrixUnconfiguredException` если matrix-bridge не настроен
  /// (например, в demo-режиме / тестах). `ArgumentError` если MIME не
  /// image/*. На прочие ошибки upload — re-throw от Serverpod / Matrix.
  static Future<String> uploadUserAvatar({
    required Uint8List bytes,
    required String mimeType,
  }) {
    return MessengerRuntime.instance.client.messenger.uploadUserAvatar(
      bytes: ByteData.sublistView(bytes),
      mimeType: mimeType,
    );
  }

  /// **Settings (Профиль и Настройки)**: сменить отображаемое имя
  /// текущего пользователя. Имя показывается в чатах (RoomSummary /
  /// участники / шапка direct-чата) и в профиле.
  ///
  /// Server: validate `1..50` непустых символов → save в
  /// `MessengerUser.displayName` + best-effort `setDisplayName` на
  /// Matrix-профиле (чтобы другие matrix-клиенты тоже увидели).
  ///
  /// Throws `ArgumentError`, если `displayName` вне диапазона `1..50`
  /// (host-app должен валидировать и на client-е перед вызовом). Прочие
  /// ошибки save — re-throw от Serverpod / Matrix.
  ///
  /// Host-app после успеха может обновить локальный профиль и сбросить
  /// `rooms.invalidate()` (server-computed display-имена для direct-чатов
  /// подтянутся свежими на следующем list/get). Текущий
  /// [NsgMessenger.session] не мутируется — отражает старое имя до
  /// re-init / reauthenticate.
  static Future<void> setDisplayName(String displayName) {
    return MessengerRuntime.instance.client.messenger.setDisplayName(
      displayName: displayName,
    );
  }

  // ─── TASK64: мультиязычный профиль ─────────────────────────────────

  /// **TASK64**: языковые версии своего профиля (для редактора).
  static Future<List<ProfileTranslation>> listMyProfileTranslations() =>
      MessengerRuntime.instance.client.messenger.listMyProfileTranslations();

  /// **TASK64**: записать языковую версию (null = не менять, '' =
  /// очистить; полностью пустая — удаляется, возврат null).
  static Future<ProfileTranslation?> setProfileTranslation({
    required String locale,
    String? displayName,
    String? about,
    String? jobTitle,
    String? company,
  }) => MessengerRuntime.instance.client.messenger.setProfileTranslation(
    locale: locale,
    displayName: displayName,
    about: about,
    jobTitle: jobTitle,
    company: company,
  );

  /// **TASK64**: пометить язык профилем по умолчанию (перевод ↔ база
  /// меняются местами, см. TASK64.md §3).
  static Future<void> setDefaultProfileLocale(String locale) =>
      MessengerRuntime.instance.client.messenger.setDefaultProfileLocale(
        locale: locale,
      );

  /// **B17 phase 2**: кросс-room keyword-поиск по сообщениям ВСЕХ комнат
  /// пользователя (Matrix `/search` без room-фильтра). Каждый
  /// [MessengerMessage] несёт свой `roomId`/`matrixRoomId` — host-app
  /// группирует результаты по комнате (имя резолвит из своего списка).
  /// Query < 2 символов → пустой list. Только Matrix FTS на сервере
  /// (без pagination-fallback — дорого по всем комнатам).
  ///
  /// Обёрнуто в [withAuthRetry] (self-heal на token-rotation), как
  /// in-room search.
  static Future<List<MessengerMessage>> searchAllMessages(
    String query, {
    int limit = 50,
  }) {
    final rt = MessengerRuntime.instance;
    return withAuthRetry(
      () => rt.client.messenger.searchAllMessages(query: query, limit: limit),
      rt.sessionManager,
    );
  }

  /// Realtime-стрим **всех** событий текущего юзера. На MVP TASK17 это
  /// `messageCreated` + (TASK17 Chunk 2 расширит membership/state). UI
  /// обычно использует `roomStream(roomId)` для конкретной комнаты;
  /// `userEventStream` нужен для cross-room-логики (badges,
  /// foreground suppression, и пр.).
  ///
  /// Auto-reconnect on token rotation встроен через
  /// [MessengerEventBus] — host-app не делает ничего, события
  /// продолжают приходить под новым токеном.
  ///
  /// Геттер (а не метод-без-args) для consistency с [rooms]
  /// (см. ревью 8336e2e #2).
  static Stream<MessengerEvent> get userEventStream =>
      MessengerRuntime.instance.eventBus.events;

  /// Realtime-стрим событий конкретной комнаты. Локальный фильтр над
  /// общим `userEventStream` — один long-poll к серверу независимо от
  /// количества открытых чатов (см. ревью TASK17 Q2).
  static Stream<MessengerEvent> roomStream(int roomId) =>
      MessengerRuntime.instance.eventBus.roomStream(roomId);

  /// Создать [MessagesController] для одной комнаты (TASK15 Chunk 1).
  ///
  /// Lifecycle: per-ChatScreen — `init()` в `initState`, `dispose()` в
  /// `dispose`. Глобального cache контроллеров нет: повторное открытие
  /// комнаты создаёт свежий controller с full-reload первой страницы.
  /// (Persistent pre-fetch для push notifications — TASK20.)
  ///
  /// Тесты host-app-а могут передать [rpcOverride] для подмены RPC
  /// слоя без поднятия Serverpod-клиента.
  static MessagesController messagesControllerFor(
    int roomId, {
    @visibleForTesting MessagesRpc? rpcOverride,
  }) {
    final runtime = MessengerRuntime.instance;
    return MessagesController(
      roomId: roomId,
      rpc: rpcOverride ?? ClientMessagesRpc(runtime.client),
      events: runtime.eventBus.events,
      selfMessengerUserId: runtime.session.messengerUserId,
      selfMatrixUserId: runtime.session.matrixUserId,
    );
  }

  // ----- Share-in (TASK49) -----

  /// **TASK49 (share-in)**: обработать входящий системный share (текст/URL/
  /// файлы) — открыть flow «Куда отправить?»: пикер чата (переиспользует
  /// forward-picker core) → превью → подтверждение → отправка → переход в
  /// чат. Host-app зовёт это на каждый входящий payload (и на холодном
  /// старте, и на тёплом), всегда прокидывая payload — SDK сам решает,
  /// показать сейчас или отложить.
  ///
  /// [navigatorKey] — ключ корневого навигатора host-app (нужен, чтобы
  /// показать пикер/диалоги/перейти в чат вне конкретного `BuildContext`,
  /// в т.ч. из cold-start обработчика intent-а).
  ///
  /// Поведение (§3.5):
  ///   * не залогинен / рантайм не готов / навигатор ещё не смонтирован →
  ///     payload кладётся в pending-слот, не теряется; host дёрнет
  ///     [flushPendingSharedPayload] после успешного входа;
  ///   * уже идёт другой share-flow → блокировка со снекбаром «отправка
  ///     ещё идёт» (очередь — не в MVP);
  ///   * пустой payload → no-op.
  static Future<void> handleSharedPayload(
    SharedPayload payload, {
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    final runtime = MessengerRuntime.instance;
    if (payload.isEmpty) return;

    final context = navigatorKey.currentContext;
    // Не готовы показать UI (не залогинен / shell ещё не смонтирован / нет
    // навигатора) → откладываем в pending. НЕ теряем. `shareUiReady` критичен
    // для холодного старта: пока shell не готов, ВСЕ доставки (в т.ч. дубль
    // getInitialMedia+getMediaStream) копятся в одном слоте и запускаются
    // РОВНО ОДИН раз через flushPendingSharedPayload — без гонки и без пикера
    // на переходном навигаторе.
    if (!runtime.isSignedIn ||
        !runtime.shareUiReady ||
        context == null ||
        !context.mounted) {
      runtime.sharePendingSlot.store(payload);
      return;
    }
    await _runShareOrBlock(payload, navigatorKey);
  }

  /// **TASK49 (share-in)**: доотправить отложенный share-payload (§3.5).
  /// Host-app зовёт после успешного входа/инициализации SDK. No-op, если
  /// слот пуст или пользователь всё ещё не залогинен.
  static Future<void> flushPendingSharedPayload({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    final runtime = MessengerRuntime.instance;
    if (!runtime.isSignedIn) return;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    // Shell смонтирован — теперь тёплые share-и (пришедшие при открытом
    // приложении) обрабатываются сразу, а не копятся. Ставим ДО take, чтобы
    // флаг взвёлся даже когда pending пуст (обычный запуск без share).
    runtime.shareUiReady = true;
    if (!runtime.sharePendingSlot.hasPending) return;
    final payload = runtime.sharePendingSlot.take();
    if (payload == null || payload.isEmpty) return;
    await _runShareOrBlock(payload, navigatorKey);
  }

  /// **TASK49 (share-in)**: есть ли отложенный share-payload. Host крутит
  /// [flushPendingSharedPayload] в ретрай-цикле, пока это `true` — чтобы
  /// холодный старт (payload/навигатор не готовы в момент первого flush) не
  /// оставлял share «застрявшим».
  static bool get hasPendingSharedPayload =>
      MessengerRuntime.instance.sharePendingSlot.hasPending;

  /// Общий guard + запуск flow: одноразовость (`shareFlowActive`) — второй
  /// share при активном flow отбивается снекбаром «отправка ещё идёт».
  static Future<void> _runShareOrBlock(
    SharedPayload payload,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final runtime = MessengerRuntime.instance;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      runtime.sharePendingSlot.store(payload);
      return;
    }
    if (runtime.shareFlowActive) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(NsgL10n.of(context).shareBusy),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    runtime.shareFlowActive = true;
    try {
      await runShareInFlow(context, payload);
    } finally {
      runtime.shareFlowActive = false;
    }
  }

  /// Hook для host-app `WidgetsBindingObserver.didChangeAppLifecycleState`.
  /// **TASK20** реализует: при `paused`/`detached` SDK закрывает
  /// underlying long-poll (foreground suppression), при `resumed` —
  /// переоткрывает. На TASK17 — no-op stub, чтобы host-app мог
  /// подключить observer прямо сейчас без последующего breaking change.
  static void onAppLifecycleChanged(AppLifecycleState state) =>
      MessengerRuntime.instance.eventBus.onAppLifecycleChanged(state);

  // ----- Виджеты -----

  /// Виджет списка чатов. Mode задаётся в `init()`, но можно
  /// переопределить точечно (для compactWidget).
  ///
  /// Если в `init(theme: ...)` host-app передал не-empty
  /// `NsgMessengerTheme`, widget автоматически оборачивается в
  /// [MessengerThemeScope] для injection theme overrides
  /// (ColorScheme + bubble/tile tokens). См. TASK22 Chunk 2.
  static Widget chatsListView({MessengerMode? mode}) {
    final runtime = MessengerRuntime.instance;
    return MessengerThemeScope(
      theme: runtime.theme,
      child: ChatsListScreen(mode: mode ?? runtime.mode),
    );
  }

  // ----- Навигация (host-app сам решает, как push-ить) -----

  /// Открыть конкретную комнату. ChatScreen route оборачивается в
  /// [MessengerThemeScope] для consistency с `chatsListView`.
  static Future<void> openRoom(BuildContext context, int roomId) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: ChatScreen(roomId: roomId),
        ),
      ),
    );
  }

  /// Открыть support-chat для заданного контекста (id заказа,
  /// тикета и т.д.).
  static Future<void> openSupportChat(
    BuildContext context, {
    required String contextId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportChatScreen(contextId: contextId),
      ),
    );
  }

  /// **TASK43**: открыть экран «Команда поддержки» продукта. Доступен и
  /// виден только участникам команды — если caller не в команде, экран
  /// сам покажет «недоступно» (гейт по серверному `getSupportTeam`,
  /// который бросает `NotSupportTeamMemberException`). Владелец команды
  /// может добавлять операторов по email и удалять участников.
  ///
  /// `productExternalKey` — ключ продукта (напр. `titan_control`),
  /// команда резолвится в tenant-е текущего пользователя.
  static Future<void> openSupportTeam(
    BuildContext context, {
    required String productExternalKey,
  }) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: SupportTeamScreen(productExternalKey: productExternalKey),
        ),
      ),
    );
  }

  /// **TASK45 фаза 1 п.5**: открыть каталог объектовых комнат продукта для
  /// члена команды поддержки. Доступен и виден только участникам команды —
  /// если caller не в команде, экран сам покажет «недоступно» (гейт по
  /// серверному `listProductObjectRooms`, который бросает
  /// `NotSupportTeamMemberException`).
  ///
  /// Член команды видит ВСЕ объектовые чаты продукта, входит по тапу
  /// (join → открыть чат), выходит когда вопрос решён. `productDisplayName`
  /// — для заголовка (иначе используется ключ).
  static Future<void> openObjectRoomsCatalog(
    BuildContext context, {
    required String productExternalKey,
    String? productDisplayName,
  }) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: ObjectRoomsCatalogScreen(
            productExternalKey: productExternalKey,
            productDisplayName: productDisplayName,
          ),
        ),
      ),
    );
  }

  /// **TASK63 итер.2**: открыть экран «Люди» — директория контактов с
  /// фильтром по меткам.
  static Future<void> openPeople(BuildContext context) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MessengerThemeScope(theme: theme, child: const PeopleScreen()),
      ),
    );
  }

  /// **TASK63**: открыть профиль контакта (своё имя / заметка / метки).
  static Future<void> openContactProfile(
    BuildContext context, {
    required int contactMessengerUserId,
  }) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: ContactProfileScreen(
            contactMessengerUserId: contactMessengerUserId,
          ),
        ),
      ),
    );
  }

  /// **TASK52 итер.2**: открыть экран входящих карточек-заявок
  /// (message-requests).
  static Future<void> openContactRequests(BuildContext context) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: const ContactRequestsScreen(),
        ),
      ),
    );
  }

  /// **TASK57 фаза 1**: открыть экран «Мои обращения» — список тикетов
  /// пользователя со статусами. Тап по тикету открывает его support-чат.
  static Future<void> openMyTickets(BuildContext context) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MessengerThemeScope(theme: theme, child: const MyTicketsScreen()),
      ),
    );
  }

  /// Открыть чат, привязанный к сущности продукта (см. ТЗ §13).
  /// На TASK11 — заглушка; getOrCreateProductRoom приходит в TASK13.
  static Future<void> openProductRoom(
    BuildContext context, {
    required String productKey,
    required String entityType,
    required String entityId,
  }) async {
    throw UnimplementedError(
      'openProductRoom приходит в TASK13 (RoomService).',
    );
  }
}
