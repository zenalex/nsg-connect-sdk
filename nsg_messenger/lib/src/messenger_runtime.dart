import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'package:path_provider/path_provider.dart';

import 'auth_token_provider.dart';
import 'cache/messenger_cache_store.dart';
import 'calls/call_controller.dart';
import 'calls/call_rpc.dart';
import 'calls/conference_call_controller.dart';
import 'calls/conference_rpc.dart';
import 'calls/webrtc_adapter.dart';
import 'calls/webrtc_adapter_real.dart';
import 'contact_card/nsg_messenger_contact_cards.dart';
import 'contacts/nsg_messenger_contacts.dart';
import 'admin/nsg_messenger_bots_admin.dart';
import 'admin/nsg_messenger_platform_admin.dart';
import 'bots/nsg_messenger_my_bots.dart';
import 'integrations/nsg_messenger_integrations.dart';
import 'messages/messages_rpc.dart';
import 'outbox/outbox_sender.dart';
import 'pulse/nsg_messenger_pulse.dart';
import 'messenger_mode.dart';
import 'messenger_session_state.dart';
import 'push/push_token_provider.dart';
import 'rooms/nsg_messenger_rooms.dart';
import 'rooms/room_summary_tile.dart' show registerTimeagoLocales;
import 'settings/nsg_messenger_settings.dart';
import 'runtime/messenger_connection_state.dart';
import 'runtime/messenger_event_bus.dart';
import 'runtime/nsg_messenger_config.dart';
import 'session/auth_retry.dart' show withAuthRetry;
import 'session/auth_token_store.dart';
import 'session/messenger_session_manager.dart';
import 'share/share_intake.dart' show SharePendingSlot;
import 'theme/nsg_messenger_theme.dart';

/// **TASK47 iter2**: дефолтный мягкий лимит дискового кэша вложений — 200 МБ.
const int kDefaultAttachmentCacheLimitBytes = 200 * 1024 * 1024;

/// **TASK47 iter2**: сентинел «без лимита» для лимита кэша вложений. Любое
/// значение `< 0` трактуется [MessengerCacheStore.evictAttachmentsToLimit] как
/// no-op (кэш растёт неограниченно, пока host не сменит настройку / не очистит).
const int kUnlimitedAttachmentCacheLimit = -1;

/// Internal SDK state. Singleton, доступен только из SDK; host-app
/// взаимодействует через `NsgMessenger` (`lib/src/nsg_messenger.dart`).
///
/// Хранит:
///   * сгенерированный Serverpod-клиент (с прикреплённым
///     `MessengerAuthKeyProvider` через [MessengerSessionManager]);
///   * `MessengerSessionManager` — proactive refresh + reactive 401
///     retry (TASK12 Chunk 3);
///   * AuthTokenProvider, ErrorReporter, тема, локаль, режим;
///   * stream `MessengerSessionState`-ов для UI host-app-а.
///
/// Не использует Riverpod / Bloc — намеренно простой singleton, чтобы
/// не навязывать SM host-app-у.
class MessengerRuntime with WidgetsBindingObserver {
  MessengerRuntime._();
  static final MessengerRuntime instance = MessengerRuntime._();

  /// **TASK20 followup (a)**: true once [WidgetsBinding.addObserver] has
  /// been called for `this`. Guard against double-registration on
  /// re-init.
  bool _lifecycleObserverRegistered = false;

  Client? _client;
  MessengerSessionManager? _sessionManager;
  MessengerEventBus? _eventBus;
  NsgMessengerRooms? _rooms;
  NsgMessengerSettings? _notificationSettings;
  // **TASK58**: контроллер входящих webhook-ов (автопостов) комнаты.
  NsgMessengerIntegrations? _integrations;
  // **TASK36**: контроллер админки ботов (tenant-wide, BOT_ADMIN_EMAILS).
  NsgMessengerBotsAdmin? _botsAdmin;
  // **TASK78 п.3**: контроллер платформенной админки секретов тенантов
  // (PLATFORM_ADMIN_EMAILS).
  NsgMessengerPlatformAdmin? _platformAdmin;
  // **Issue #49**: self-service «Мои боты» (owner-scoped, без админ-гейта).
  NsgMessengerMyBots? _myBots;
  // **TASK60**: контроллер дашборда мониторинга Connect Pulse.
  NsgMessengerPulse? _pulse;
  NsgMessengerContacts? _contacts;
  NsgMessengerContactCards? _contactCards;
  // **TASK58**: базовый URL для показа webhook-URL в UI интеграций.
  // Дефолт выводится из apiBaseUrl (см. _deriveHooksBaseUrl); host-app
  // может override-нуть на прод (`https://hooks.chatista.me`).
  String _hooksBaseUrl = '';
  // **TASK47**: дисковый оффлайн-кэш чатов (null → выключен: web / host
  // отключил / ошибка открытия). Открывается ПОСЛЕ сессии (нужен userId).
  MessengerCacheStore? _cache;
  // **TASK47 iter2**: мягкий лимит дискового кэша ВЛОЖЕНИЙ (байт). После
  // каждого read-through-наполнения [MxcImageProvider] зовёт evict до этого
  // значения. Значение по умолчанию — [kDefaultAttachmentCacheLimitBytes];
  // host (Chatista) может переопределить из своих настроек через
  // [setAttachmentCacheLimitBytes]. Сентинел [kUnlimitedAttachmentCacheLimit]
  // (< 0) — «без лимита» (evict — no-op).
  int _attachmentCacheLimitBytes = kDefaultAttachmentCacheLimitBytes;
  // **OUTBOX**: фоновый отправитель персистентной очереди исходящих.
  // Создаётся вместе с дисковым кэшем (нужен store); null если кэш выключен
  // (web / host отключил / ошибка) — тогда share падает обратно в прямой
  // RPC-путь (см. share_intake.dart).
  OutboxSender? _outbox;
  // **TASK55 итер.1**: периодический presence-heartbeat (только в
  // foreground; троттл серверной записи — в PresenceService).
  Timer? _presenceTimer;
  bool _lifecycleResumed = true;
  // **Realtime-синк (TASK63)**: сброс кэша меток на contactMetaChanged.
  StreamSubscription<MessengerEvent>? _contactSyncSub;
  // **TASK46 (SDK)**: контроллер голосовых звонков 1:1. Подписан на
  // event bus всегда (входящий invite ловится на любом экране).
  CallController? _calls;

  /// **TASK51 итерация 1**: контроллер групповых (mesh) звонков. Живёт
  /// параллельно [_calls]; трафик разведён префиксом callId `conf:`.
  ConferenceCallController? _conferenceCalls;
  // Позволяет тестам runtime подменить WebRtcAdapter на fake без
  // нативного плагина. В production — RealWebRtcAdapter.
  WebRtcAdapter? _webRtcAdapterOverride;
  // **TASK22-Phase2 Chunk 2 PART C**: stream controllers owned by
  // `installDemo` (demo mode only). In production these are null; in
  // demo mode they need to be closed in `dispose()`.
  StreamController<MessengerSessionState>? _demoSessionStateCtl;
  StreamController<MessengerEvent>? _demoEventCtl;
  PushTokenProvider? _pushTokenProvider;
  StreamSubscription<String?>? _pushTokenSub;
  String? _lastRegisteredToken;

  /// Токен, регистрация которого сейчас в процессе (для ретрая — см.
  /// [_onPushTokenChanged]). Если во время backoff-а провайдер отдал
  /// новый токен, `_currentPushToken` меняется и устаревшая retry-петля
  /// прекращается.
  String? _currentPushToken;
  String? _pushProductExternalKey;

  /// **TASK46 (звонки в фоне)**: PushKit VoIP-токен iOS. Отдельный
  /// `DeviceRegistration` с `pushService=voip` (рядом с FCM-регистрацией) —
  /// сервер по нему шлёт прямой APNs VoIP-push на входящий звонок в фоне.
  /// Токен приходит из натива (PushKit) через host-app асинхронно и может
  /// прийти ДО завершения `init()` — тогда держим его в [_pendingVoipToken]
  /// и регистрируем, как только появится `client` (см. [_flushVoipToken]).
  String? _pendingVoipToken;
  String? _lastRegisteredVoipToken;
  // AuthTokenProvider / ErrorReporter / AuthTokenStore передаются прямо
  // в `MessengerSessionManager` и хранятся ВНУТРИ него — runtime не
  // дублирует ссылки. Если в будущем понадобится exposed-getter
  // (например, Settings-screen хочет показать «провайдер привязан») —
  // добавим явный делегат через manager.
  NsgMessengerTheme _theme = NsgMessengerTheme.empty;

  /// Хук host-app-а для отправки ошибок в трекер (chatista → GlitchTip).
  /// Держим полем, а не только параметром `init()`: до него должны
  /// дотягиваться экраны и сервисы SDK — см. [reportError].
  ErrorReporter? _errorReporter;
  NsgMessengerLocale _locale = const NsgMessengerLocale();
  MessengerMode _mode = MessengerMode.embeddedProduct;
  // **TASK22-Phase2 Chunk 1-B**: behavior knobs (scroll thresholds и
  // пр.). Null = host-app не передал config → возвращаем
  // [NsgMessengerConfig.fallback] из геттера.
  NsgMessengerConfig? _config;

  final StreamController<MessengerSessionState> _stateCtl =
      StreamController<MessengerSessionState>.broadcast();
  MessengerSessionState _state = MessengerSessionState.uninitialised;

  /// **TASK49 (share-in)**: одноместный слот отложенного share-payload.
  /// Если payload пришёл, когда юзер не залогинен / рантайм не готов (§3.5),
  /// держим его тут и доотправляем после входа (см. `NsgMessenger
  /// .flushPendingSharedPayload`). Не теряем молча.
  final SharePendingSlot sharePendingSlot = SharePendingSlot();

  /// **TASK49 (share-in)**: flow «Куда отправить?» сейчас активен (пикер /
  /// подтверждение / отправка). Второй share при активном flow блокируется
  /// со снекбаром «отправка ещё идёт» (§3.5, очередь — не в MVP).
  bool shareFlowActive = false;

  /// **TASK49 fix (cold-start)**: UI готов показывать share-flow (основной
  /// shell смонтирован). До этого — ЛЮБАЯ доставка идёт в pending, даже если
  /// пользователь уже залогинен: иначе на холодном старте flow пытается
  /// открыть пикер на переходном bootstrap-навигаторе (теряется при
  /// перестройке в shell), а гонка `getInitialMedia`+`getMediaStream` ловит
  /// «отправка ещё идёт». Host выставляет флаг через `flushPendingSharedPayload`
  /// (зовётся после ready). Сбрасывается на dispose/logout.
  bool shareUiReady = false;

  // ---------- Публичные геттеры (для NsgMessenger / SDK screens) ----------

  Client get client {
    final c = _client;
    if (c == null) {
      throw StateError(
        'NsgMessenger.init() не вызывался. См. docs/tasks/TASK11.md.',
      );
    }
    return c;
  }

  MessengerSession get session {
    final s = _sessionManager?.session;
    if (s == null) {
      throw StateError(
        'MessengerSession отсутствует. Вероятно, init() ещё не завершился, '
        'token истёк, или session manager в expired-стейте. '
        'Подпишись на sessionStateStream() для UI.',
      );
    }
    return s;
  }

  /// `messengerUserId` для проброса в Serverpod RPC. На TASK12 Chunk 2
  /// серверные методы больше не принимают этот параметр (derives из
  /// session.authenticated), так что геттер используется только если
  /// host-app или внутренний SDK-код хочет узнать «кто я» для UI.
  int get currentMessengerUserId => session.messengerUserId;

  /// **TASK47**: дисковый оффлайн-кэш (null → выключен). ChatScreen передаёт
  /// его в [MessagesController] для read-through истории сообщений.
  MessengerCacheStore? get offlineCache => _cache;

  /// **TASK47 iter2**: доступен ли дисковый кэш вложений (mobile/desktop с
  /// открытым store). `false` на web / до init / при ошибке открытия — host
  /// (Chatista) прячет секцию «Хранилище».
  bool get isAttachmentCacheAvailable => _cache != null;

  /// **TASK47 iter2**: текущий мягкий лимит кэша вложений (байт). `< 0` —
  /// «без лимита» ([kUnlimitedAttachmentCacheLimit]).
  int get attachmentCacheLimitBytes => _attachmentCacheLimitBytes;

  /// **TASK47 iter2**: сменить лимит кэша вложений (host читает из своих
  /// настроек и прокидывает сюда; [MxcImageProvider] берёт значение при
  /// следующей обрезке). Отрицательное — «без лимита». Сразу применяем
  /// обрезку под новый лимит (best-effort, не блокируем).
  void setAttachmentCacheLimitBytes(int bytes) {
    _attachmentCacheLimitBytes = bytes;
    final cache = _cache;
    if (cache != null && bytes >= 0) {
      unawaited(cache.evictAttachmentsToLimit(bytes).catchError((Object _) => 0));
    }
  }

  /// **TASK47 iter2**: суммарный размер кэша вложений, байт (для UI
  /// «Хранилище»). `0`, если кэш выключен.
  Future<int> attachmentCacheSizeBytes() async {
    final cache = _cache;
    if (cache == null) return 0;
    try {
      return await cache.attachmentsCacheSize();
    } catch (_) {
      return 0;
    }
  }

  /// **TASK47 iter2**: очистить кэш вложений текущего пользователя (кнопка
  /// «Очистить кэш»). No-op, если кэш выключен.
  Future<void> clearAttachmentCache() async {
    try {
      await _cache?.clearAttachments();
    } catch (_) {}
  }

  /// **OUTBOX**: фоновый отправитель персистентной очереди исходящих (null →
  /// выключен вместе с дисковым кэшем). Share-flow ставит сообщения сюда;
  /// [MessagesController] рендерит их pending-бабблами и подписан на
  /// изменения очереди.
  OutboxSender? get outbox => _outbox;

  /// **TASK20 followup (α)**: доступ к [MessengerSessionManager] для
  /// SDK-internal `withAuthRetry` wrapping. Hot-path RPC closures (в
  /// [NsgMessengerRooms.attach], [NsgMessengerSettings.attach],
  /// [ClientMessagesRpc]) lazy-resolve manager через этот getter, чтобы
  /// не таскать manager через конструкторы.
  ///
  /// Throws [StateError], если runtime ещё не инициализирован — это
  /// safety net: если closure дёрнули после `dispose()`, мы хотим явный
  /// failure, а не silent NPE.
  ///
  /// **NOT visible** в публичном `nsg_messenger.dart` барьере —
  /// `MessengerRuntime` сам internal, getter доступен только из SDK
  /// internals.
  MessengerSessionManager get sessionManager {
    final m = _sessionManager;
    if (m == null) {
      throw StateError(
        'MessengerSessionManager отсутствует. NsgMessenger.init() ещё '
        'не вызван или dispose() уже отработал.',
      );
    }
    return m;
  }

  NsgMessengerTheme get theme => _theme;

  /// **Отправить ошибку в трекер host-app-а.** Безопасно звать откуда угодно:
  /// до `init()` и без репортера — no-op; сам репорт обёрнут в try/catch,
  /// потому что диагностика не имеет права ронять то, что диагностирует.
  ///
  /// **Зачем это есть.** В SDK и app-е ~157 мест `catch (_)`, и в 79 из них
  /// пользователю показывается ошибка, а в трекер не уходит НИЧЕГО. Так
  /// прятались реальные баги: «ошибка сохранения» визитки на самом деле была
  /// `MessengerNotAuthenticatedException`, и найти это удалось только по
  /// серверным логам. Если ошибку видит пользователь — её обязан видеть и
  /// трекер: зови этот метод в таком `catch`.
  void reportError(
    Object error,
    StackTrace? stack, {
    Map<String, String>? tags,
  }) {
    try {
      _errorReporter?.reportError(error, stack, tags: tags);
    } catch (_) {
      // Трекер недоступен — молчим, иначе диагностика уронит вызывающего.
    }
  }

  /// Подключить трекер ДО [init] — с загрузки приложения.
  ///
  /// [init] раньше был единственной точкой, где выставлялся репортер, но
  /// он зовётся уже после логина (нужен токен). Из-за этого экран ВХОДА —
  /// самый чувствительный момент — слал ошибки в никуда ([reportError]
  /// был no-op до init). Репортер же по природе не зависит от сессии
  /// (например, обёртка над глобальным Sentry), поэтому хост зовёт это
  /// сразу после boot, и [reportError] работает всё время жизни
  /// приложения, включая pre-auth.
  void configureErrorReporter(ErrorReporter reporter) {
    _errorReporter = reporter;
  }
  NsgMessengerLocale get locale => _locale;
  MessengerMode get mode => _mode;

  /// **B20**: сменить активную SDK-тему в рантайме. Нужно когда host-app
  /// переключает light/dark (или brand-акцент) после `init` — SDK
  /// widget-фабрики (`chatsListView` / `openRoom` / `demoChatScreen`)
  /// читают `runtime.theme` на каждый build, поэтому host достаточно:
  ///   1. вызвать `NsgMessenger.updateTheme(newTheme)`;
  ///   2. сделать `setState` (или иначе перестроить subtree), чтобы
  ///      фабрики переинъектили свежую тему.
  ///
  /// Без этого `runtime.theme` оставался зафиксированным на init-time
  /// значении, и SDK-экраны не следовали за brightness-переключением
  /// (intern QA B20).
  void updateTheme(NsgMessengerTheme theme) {
    _theme = theme;
  }

  /// **TASK22-Phase2 Chunk 1-B**: behavior config (scroll thresholds и
  /// пр.). Если host-app не передал config в `init(config: ...)` —
  /// возвращается [NsgMessengerConfig.fallback] с дефолтами (200 px
  /// thresholds), так что SDK-widgets всегда могут читать конфиг без
  /// null-check-а.
  NsgMessengerConfig get config => _config ?? NsgMessengerConfig.fallback;

  /// **TASK22-Phase2 Chunk 2 PART C**: `true` если runtime уже был
  /// проинициализирован — через [init] (production) либо [installDemo]
  /// (designer sandbox). Используется `NsgMessenger.initDemo` для
  /// guard-а против двойного init.
  bool get isInitialized =>
      _client != null || _rooms != null || _eventBus != null;

  /// **TASK49 (share-in)**: залогинен ли пользователь (активная сессия
  /// доступна). Share-flow гейтится по нему — payload без сессии уходит в
  /// [sharePendingSlot] (§3.5).
  bool get isSignedIn {
    try {
      return _sessionManager?.session != null;
    } catch (_) {
      return false;
    }
  }
  Stream<MessengerSessionState> get stateStream => _stateCtl.stream;
  MessengerSessionState get state => _state;

  /// **TASK20 followup (a)**: transport health (separate axis from
  /// [stateStream] which is auth/login). Delegates to event bus.
  /// Embed [ConnectionStateIndicator] widget in host-app AppBar to
  /// render a traffic-light circle.
  ///
  /// Returns empty stream when runtime not initialised; switches to
  /// the live bus stream after `init()`.
  Stream<MessengerConnectionState> get connectionStateStream =>
      _eventBus?.connectionStateStream ??
      const Stream<MessengerConnectionState>.empty();

  /// Текущее значение [connectionStateStream]. Default — `healthy`.
  MessengerConnectionState get connectionState =>
      _eventBus?.connectionState ?? MessengerConnectionState.healthy;

  /// Внутренний SDK-API. Public expose в TASK17 (когда появятся
  /// stream-wrappers поверх). На TASK13 Chunk 2 используется только
  /// `NsgMessengerRooms` для cache invalidation.
  MessengerEventBus get eventBus {
    final b = _eventBus;
    if (b == null) {
      throw StateError(
        'MessengerEventBus отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return b;
  }

  /// Public API для работы с комнатами. Доступен через `NsgMessenger.rooms`.
  NsgMessengerRooms get rooms {
    final r = _rooms;
    if (r == null) {
      throw StateError(
        'NsgMessengerRooms отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return r;
  }

  /// **TASK46 (SDK)**: контроллер голосовых звонков 1:1. Доступен
  /// глобально (`NsgMessenger.callController`), подписан на event bus
  /// с момента [init] — входящий звонок ловится на любом экране. UI
  /// (overlay) биндится к нему как к `ChangeNotifier`.
  CallController get calls {
    final c = _calls;
    if (c == null) {
      throw StateError(
        'CallController отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return c;
  }

  /// **TASK51 итерация 1**: контроллер групповых (mesh) аудиозвонков.
  /// Доступен глобально (`NsgMessenger.conferenceCalls`), подписан на
  /// event bus с момента [init] — входящая конференция ловится на любом
  /// экране. UI биндится как к `ChangeNotifier`
  /// (`ConferenceCallState`: idle/incomingRinging/joining/active/ended).
  ConferenceCallController get conferenceCalls {
    final c = _conferenceCalls;
    if (c == null) {
      throw StateError(
        'ConferenceCallController отсутствует. NsgMessenger.init() не '
        'вызван или dispose() уже отработал.',
      );
    }
    return c;
  }

  /// Nullable-вариант [conferenceCalls] — для UI, живущего дольше
  /// рантайма (та же мотивация, что [callsOrNull], issue #47).
  ConferenceCallController? get conferenceCallsOrNull => _conferenceCalls;

  /// **issue #47**: nullable-вариант [calls] для UI, живущего ДОЛЬШЕ
  /// рантайма (например `CallOverlayHost` в корне навигации host-app-а).
  ///
  /// Почему нельзя гейтиться по [isInitialized] + [calls]: в окне
  /// teardown/reinit смены аккаунта они рассинхронизированы —
  /// в [init] `_client` создаётся ЗАДОЛГО до [_calls], а в [dispose]
  /// `_calls` зануляется ЗАДОЛГО до `_client` (между ними await-ы
  /// снятия push-регистраций). Виджет, перестроившийся в этом окне,
  /// видел `isInitialized == true`, дёргал [calls] и падал StateError-ом
  /// (красный экран в debug). Здесь — просто null: «контроллера сейчас
  /// нет, отрисуй пустой оверлей и пере-резолвь на следующем событии».
  /// Бросающий [calls] намеренно не трогаем — другим вызывателям ошибка
  /// «init() не вызван» нужна громкой.
  CallController? get callsOrNull => _calls;

  /// **issue #47, visible-for-testing**: подставить/сбросить
  /// [CallController] напрямую. Widget-тестам `CallOverlayHost` нужен
  /// рантайм в состояниях «окно teardown/reinit» (calls == null при
  /// isInitialized == true) и «init завершился» (calls != null) — без
  /// подъёма реального [init] (клиент/сессия/webrtc).
  @visibleForTesting
  void debugSetCallController(CallController? controller) =>
      _calls = controller;

  /// **issue #47, visible-for-testing**: эмитнуть session-state в
  /// [stateStream]. Тесты так воспроизводят «init нового аккаунта
  /// завершился» (production эмитит `active` из
  /// MessengerSessionManager) — событие, по которому `CallOverlayHost`
  /// пере-резолвит контроллер.
  @visibleForTesting
  void debugEmitSessionState(MessengerSessionState state) => _emit(state);

  /// **TASK46 (SDK)**: visible-for-testing — подменить [WebRtcAdapter]
  /// (fake без нативного плагина) ДО [init]. Production не вызывает —
  /// используется [RealWebRtcAdapter].
  @visibleForTesting
  set webRtcAdapterOverride(WebRtcAdapter adapter) =>
      _webRtcAdapterOverride = adapter;

  /// **TASK20-Phase2 Chunk 4**: notification settings API
  /// (showMessagePreview toggle). См. [NotificationSettingsScreen]
  /// в host-app's settings UI.
  NsgMessengerSettings get notificationSettings {
    final s = _notificationSettings;
    if (s == null) {
      throw StateError(
        'NsgMessengerSettings отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return s;
  }

  /// **TASK58**: публичный API управления входящими webhook-ами (автопостами)
  /// комнаты. Доступен через `NsgMessenger.integrations`; используется
  /// `IntegrationsScreen` (вкладка «Интеграции» в настройках группы).
  NsgMessengerIntegrations get integrations {
    final i = _integrations;
    if (i == null) {
      throw StateError(
        'NsgMessengerIntegrations отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return i;
  }

  /// **TASK36**: публичный API админки ботов (tenant-wide). Доступен через
  /// `NsgMessenger.botsAdmin`; используется `BotsAdminScreen`. Серверный
  /// гейт — `BOT_ADMIN_EMAILS`; `isBotAdmin()` только прячет вход в UI.
  NsgMessengerBotsAdmin get botsAdmin {
    final b = _botsAdmin;
    if (b == null) {
      throw StateError(
        'NsgMessengerBotsAdmin отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return b;
  }

  /// **TASK78 п.3**: публичный API платформенной админки секретов
  /// тенантов. Доступен через `NsgMessenger.platformAdmin`; используется
  /// `PlatformAdminScreen`. Серверный гейт — `PLATFORM_ADMIN_EMAILS`;
  /// `isPlatformAdmin()` только прячет вход в UI.
  NsgMessengerPlatformAdmin get platformAdmin {
    final p = _platformAdmin;
    if (p == null) {
      throw StateError(
        'NsgMessengerPlatformAdmin отсутствует. NsgMessenger.init() не '
        'вызван или dispose() уже отработал.',
      );
    }
    return p;
  }

  /// **Issue #49**: публичный API «Моих ботов» (self-service обычного
  /// пользователя; скоуп по ownerEmail решает сервер). Доступен через
  /// `NsgMessenger.myBots`; используется `MyBotsScreen`.
  NsgMessengerMyBots get myBots {
    final b = _myBots;
    if (b == null) {
      throw StateError(
        'NsgMessengerMyBots отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return b;
  }

  /// **TASK60**: публичный API дашборда мониторинга Connect Pulse. Доступен
  /// через `NsgMessenger.pulse`; используется `PulseScreen`. Все эндпоинты
  /// gate-ятся server-side (PULSE_ADMIN_EMAILS) — non-admin получает
  /// `MessengerNotAuthenticatedException`, UI показывает «нет доступа».
  NsgMessengerPulse get pulse {
    final p = _pulse;
    if (p == null) {
      throw StateError(
        'NsgMessengerPulse отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return p;
  }

  /// **TASK63**: организация контактов — per-viewer alias/заметка/метки.
  /// Доступен через `NsgMessenger.contacts`.
  NsgMessengerContacts get contacts {
    final c = _contacts;
    if (c == null) {
      throw StateError(
        'NsgMessengerContacts отсутствует. NsgMessenger.init() не вызван '
        'или dispose() уже отработал.',
      );
    }
    return c;
  }

  /// **TASK52 итер.1**: личные визитки (Contact Card) — чужие с TTL-кэшем
  /// и prefetch-ем для экрана звонка, своя — для редактора.
  NsgMessengerContactCards get contactCards {
    final c = _contactCards;
    if (c == null) {
      throw StateError(
        'NsgMessengerContactCards отсутствует. NsgMessenger.init() не '
        'вызван или dispose() уже отработал.',
      );
    }
    return c;
  }

  /// **TASK58**: базовый URL для формирования отображаемого webhook-URL
  /// (`<hooksBaseUrl>/<token>`). По умолчанию выводится из `apiBaseUrl`
  /// (см. [_deriveHooksBaseUrl]); host-app может override-ить через
  /// `NsgMessenger.init(hooksBaseUrl: ...)`.
  String get hooksBaseUrl => _hooksBaseUrl;

  /// Дефолтный hooks-base из [apiBaseUrl]. Публичный роут `/hooks/:token`
  /// живёт на Serverpod **webServer** (:5570), НЕ на apiServer — поэтому
  /// простое `apiBaseUrl + /hooks` неверно. Правила:
  ///   * dev (`localhost`/`127.0.0.1`) → `http://localhost:5570/hooks`
  ///     (прямой доступ к webServer; URL = `<base>/<token>`);
  ///   * прод `api.<домен>` → `https://hooks.<домен>` (reverse-proxy
  ///     `hooks.chatista.me` переписывает `/` → внутр. `/hooks/`).
  /// Нестандартный хостинг → задать `hooksBaseUrl` явно в `init`.
  static String _deriveHooksBaseUrl(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.host.isEmpty) return apiBaseUrl;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      // apiServer :5568 → webServer :5570 (см. infra/PORTS.md).
      return uri.replace(port: 5570, path: '/hooks').toString();
    }
    final hooksHost = uri.host.startsWith('api.')
        ? 'hooks.${uri.host.substring(4)}'
        : 'hooks.${uri.host}';
    return uri
        .replace(host: hooksHost, path: '')
        .toString()
        .replaceAll(RegExp(r'/+$'), '');
  }

  // ---------- Lifecycle ----------

  /// Полная инициализация SDK. Шаги:
  ///   1. Создать [Client] на `apiBaseUrl`.
  ///   2. Создать [AuthTokenStore] (secure_storage по умолчанию,
  ///      `tokenStoreOverride` в тестах).
  ///   3. Сконструировать [MessengerSessionManager] — он установит
  ///      `MessengerAuthKeyProvider` на client и подпишется на 401-retry.
  ///   4. Вызвать `manager.init()` — провайдер дёрнут за context-ом,
  ///      кэш проверен / новая сессия выдана, refresh-таймер запущен.
  Future<void> init({
    required String apiBaseUrl,
    required AuthTokenProvider authTokenProvider,
    NsgMessengerTheme? theme,
    NsgMessengerLocale? locale,
    MessengerMode mode = MessengerMode.embeddedProduct,
    ErrorReporter? errorReporter,
    AuthTokenStore? tokenStoreOverride,
    PushTokenProvider? pushTokenProvider,
    String? productExternalKey,
    NsgMessengerConfig? config,
    bool enableOfflineCache = true,
    String? cacheDirectoryOverride,
    String? hooksBaseUrl,
  }) async {
    if (kDebugMode) {
      debugPrint('[MessengerRuntime.init] enter (apiBaseUrl=$apiBaseUrl)');
    }
    if (_client != null) {
      // Повторный init — допускаем как смену AuthTokenProvider /
      // theme. Закрываем старый manager и client, создаём новые.
      await dispose();
    }
    // Регистрируем RU-локаль в timeago (идемпотентно). EN — default.
    registerTimeagoLocales();
    _client = Client(apiBaseUrl);
    // **Workaround**: FlutterConnectivityMonitor (connectivity_plus) на
    // Windows-desktop и в некоторых iOS-конфигурациях возвращает "no
    // internet" → Serverpod-client стопорит все RPC в ожидании сети,
    // и SDK виснет на первом session() вызове. Отключаем монитор —
    // streams сами авто-reconnect через event_bus. Если позже понадобится
    // back-off на потере сети → ставить platform-conditional (включать
    // только на android, где плагин стабилен).
    // `??` — не затирать репортер, уже подключённый через
    // [configureErrorReporter] на boot, если init вызван без него.
    _errorReporter = errorReporter ?? _errorReporter;
    _theme = theme ?? NsgMessengerTheme.empty;
    _locale = locale ?? NsgMessengerLocale.resolveFromSystem();
    _mode = mode;
    _config = config;
    // **TASK58**: дефолт webhook-URL выводим из apiBaseUrl (роут живёт на
    // webServer :5570, не apiServer — см. [_deriveHooksBaseUrl]); host-app
    // может override-ить прод-значением.
    _hooksBaseUrl = hooksBaseUrl ?? _deriveHooksBaseUrl(apiBaseUrl);
    if (kDebugMode) debugPrint('[MessengerRuntime.init] Client created');

    _sessionManager = MessengerSessionManager.attach(
      client: _client!,
      authTokenProvider: authTokenProvider,
      store: tokenStoreOverride ?? SecureAuthTokenStore(),
      errorReporter: errorReporter,
      emitState: _emit,
    );
    if (kDebugMode) {
      debugPrint('[MessengerRuntime.init] SessionManager attached');
    }
    // EventBus создаём ДО session.init() — важно, чтобы listener-ы
    // на _stateCtl были подключены до первого emit-а; иначе bus
    // пропустит начальный `refreshing → active` переход. Underlying
    // sub triggers только когда NsgMessengerRooms (или другой
    // consumer) реально начнёт listen.
    _eventBus = MessengerEventBus.attach(
      client: _client!,
      sessionStateStream: _stateCtl.stream,
      onError: errorReporter == null
          ? null
          : (e, st) => errorReporter.reportError(
              e,
              st,
              tags: const {'source': 'event_bus'},
            ),
      // **Session-recovery fix (a2)**: типизированный auth-invalidation на
      // `userEventStream` маршрутится сюда (вместо бесконечного transport-
      // reconnect на протухшем токене). Дёргаем self-heal — он либо обновит
      // токен, либо переведёт сессию в `expired` (host уводит в login).
      onStreamAuthError: _onStreamAuthError,
    );
    if (kDebugMode) debugPrint('[MessengerRuntime.init] EventBus attached');
    _rooms = NsgMessengerRooms.attach(client: _client!, eventBus: _eventBus!);
    _notificationSettings = NsgMessengerSettings.attach(_client!);
    // **TASK58**: контроллер входящих webhook-ов (автопостов). Stateless-
    // прокси над `client.incomingWebhook.*` — attach сразу, до session.init().
    _integrations = NsgMessengerIntegrations.attach(client: _client!);
    // **TASK36**: контроллер админки ботов. Тоже stateless-прокси (над
    // `client.botAdmin.*`) — attach сразу, до session.init().
    _botsAdmin = NsgMessengerBotsAdmin.attach(client: _client!);
    // **TASK78 п.3**: платформенная админка секретов — такой же stateless-
    // прокси (над `client.connectTenantAdmin.*`) — attach сразу.
    _platformAdmin = NsgMessengerPlatformAdmin.attach(client: _client!);
    // **Issue #49**: «Мои боты» — такой же stateless-прокси (над
    // `client.myBots.*`) — attach сразу, до session.init().
    _myBots = NsgMessengerMyBots.attach(client: _client!);
    // **TASK60**: контроллер дашборда мониторинга Pulse. Stateless-прокси над
    // `client.pulse.*` — attach сразу, до session.init().
    _pulse = NsgMessengerPulse.attach(client: _client!);
    // **TASK63**: организация контактов (alias / заметка / метки).
    // Stateless-прокси над `client.messenger.*` — attach сразу.
    _contacts = NsgMessengerContacts.attach(_client!);
    // **TASK52**: личные визитки — attach сразу (кэш per-user внутри).
    _contactCards = NsgMessengerContactCards.attach(_client!);
    // Realtime-синк: другое устройство изменило метки/alias — сброс кэша.
    _contactSyncSub = _eventBus!.events.listen((event) {
      if (event.eventType == MessengerEventType.contactMetaChanged) {
        _contacts?.invalidateLabels();
      } else if (event.eventType ==
          MessengerEventType.contactRequestChanged) {
        // **TASK52 итер.2**: новая/принятая/отклонённая заявка на другом
        // устройстве — пересчёт бейджа входящих.
        _contacts?.refreshIncomingRequests();
      }
    }, onError: (_) {});
    // **TASK46 (SDK)**: CallController подписывается на event bus сразу
    // (входящий invite ловится на любом экране). Подписка на
    // `_eventBus.events` держит underlying sync-worker живым — что и так
    // уже происходит из-за NsgMessengerRooms (см. MessengerEventBus doc).
    // **TASK51**: адаптер WebRTC один на оба контроллера (1:1 и
    // конференции) — это фабрика pc/media без own-state, второй инстанс
    // лишь дублировал бы native-обвязку.
    final webrtcAdapter =
        _webRtcAdapterOverride ?? RealWebRtcAdapter(reporter: errorReporter);
    _calls = CallController(
      rpc: ClientCallRpc(_client!),
      // errorReporter пробрасываем в адаптер: на состоявшийся звонок уходит
      // один отчёт диагностики медиа («звука нет») в трекер host-app-а
      // (chatista → GlitchTip). Отключить: --dart-define=CALL_DIAG=false.
      webrtc: webrtcAdapter,
      events: _eventBus!.events,
      // ...и в сам контроллер: он репортит потерю TURN-кредов (звонок без
      // relay). Раньше это молчало и стоило нам несоединяющихся звонков.
      reporter: errorReporter,
    );
    // **TASK51 итерация 1**: контроллер mesh-конференций — рядом с 1:1,
    // тот же lifecycle (attach на init, dispose на dispose). Трафик двух
    // контроллеров разведён префиксом callId `conf:` (см.
    // ConferenceCallController doc).
    _conferenceCalls = ConferenceCallController(
      conferenceRpc: ClientConferenceRpc(_client!),
      callRpc: ClientCallRpc(_client!),
      webrtc: webrtcAdapter,
      events: _eventBus!.events,
      // Лениво: на момент init сессии ещё нет; к моменту join/событий —
      // есть (иначе бросит, контроллер трактует как «сессии нет»).
      selfMessengerUserId: () => session.messengerUserId,
      reporter: errorReporter,
    );
    if (kDebugMode) {
      debugPrint(
        '[MessengerRuntime.init] Rooms+Settings+Calls attached; '
        'calling _sessionManager.init()',
      );
    }
    await _sessionManager!.init();
    if (kDebugMode) {
      debugPrint('[MessengerRuntime.init] _sessionManager.init() OK');
    }

    // **TASK47**: открываем дисковый оффлайн-кэш ПОСЛЕ сессии (нужен userId).
    // Web / ошибка → store == null → SDK работает без диска (best-effort).
    if (enableOfflineCache && !kIsWeb) {
      await _openOfflineCache(apiBaseUrl, cacheDirectoryOverride);
    }
    // **TASK64**: сообщить серверу локаль интерфейса — по ней он выбирает
    // языковые версии ЧУЖИХ профилей для этого пользователя. Fire-and-
    // forget: не блокирует init, ошибка не критична (останется база).
    unawaited(
      _client!.messenger
          .setUiLocale(locale: _locale.locale.languageCode)
          .catchError((_) {}),
    );
    // **TASK55 итер.1**: presence-heartbeat — сразу и далее каждые 90с
    // (только в foreground; серверный троттл записи — 60с).
    unawaited(_sendPresenceHeartbeat());
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (_lifecycleResumed) unawaited(_sendPresenceHeartbeat());
    });

    // TASK20 Chunk 3: push token registration. Если host-app передал
    // provider — subscribe на token stream + регистрируем initial
    // token. Без provider-а push routing не работает (embed-mode без
    // push, или customer обрабатывает push через свою инфру).
    if (pushTokenProvider != null) {
      _pushTokenProvider = pushTokenProvider;
      _pushProductExternalKey = productExternalKey;
      _pushTokenSub = pushTokenProvider.tokenStream().listen(
        _onPushTokenChanged,
        onError: (Object e, StackTrace st) {
          errorReporter?.reportError(
            e,
            st,
            tags: const {'source': 'push_token_stream'},
          );
        },
      );
      // Initial register если token уже доступен (provider может уже
      // получить от FCM до listener подписки).
      if (kDebugMode) {
        debugPrint('[MessengerRuntime.init] getCurrentToken (initial)...');
      }
      final initial = await pushTokenProvider.getCurrentToken();
      if (kDebugMode) {
        debugPrint(
          '[MessengerRuntime.init] getCurrentToken returned '
          '${initial == null ? "null" : "<token>"}',
        );
      }
      if (initial != null) {
        if (kDebugMode) {
          debugPrint(
            '[MessengerRuntime.init] _onPushTokenChanged (initial)...',
          );
        }
        await _onPushTokenChanged(initial);
        if (kDebugMode) {
          debugPrint('[MessengerRuntime.init] _onPushTokenChanged OK');
        }
      }
    }
    // **TASK20 followup (a)**: lifecycle observer на уровне runtime —
    // bus's `onAppLifecycleChanged` теперь дёрнется автоматически
    // на каждый pause/resume, plus runtime triggers `forceReconnect`
    // на `resumed` (iOS/Android могут silently убить WS в background,
    // bus об этом узнает только при попытке записи). До этого host-app
    // должен был руками звать `bus.onAppLifecycleChanged` (TASK20
    // Chunk 2) — теперь автоматически.
    if (!_lifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
      if (kDebugMode) {
        debugPrint('[MessengerRuntime.init] lifecycle observer registered');
      }
    }
    // **TASK46 (звонки в фоне)**: VoIP-токен мог прийти из натива (PushKit)
    // ещё до готовности `client` — регистрируем отложенный токен сейчас.
    await _flushVoipToken();
    if (kDebugMode) debugPrint('[MessengerRuntime.init] all done');
  }

  /// **TASK47**: открывает дисковый кэш и подключает его к rooms. Namespace
  /// файла = sha256(apiBaseUrl)[:16] — изолирует окружения (dev/тест/prod);
  /// per-user — колонка userId внутри (messengerUserId server-global). Каталог
  /// по умолчанию — getApplicationSupportDirectory(); host может переопределить.
  /// Best-effort: любая ошибка → кэш просто выключен.
  Future<void> _openOfflineCache(
    String apiBaseUrl,
    String? cacheDirectoryOverride,
  ) async {
    try {
      final dir =
          cacheDirectoryOverride ??
          (await getApplicationSupportDirectory()).path;
      final namespace = sha256
          .convert(utf8.encode(apiBaseUrl))
          .toString()
          .substring(0, 16);
      final store = await MessengerCacheStore.openForUser(
        directory: dir,
        namespace: namespace,
        userId: currentMessengerUserId,
      );
      if (store != null) {
        _cache = store;
        _rooms?.attachCache(store);
        // **OUTBOX**: поднимаем фоновый отправитель на том же store. start()
        // будит дренаж — persisted-строки (пережившие рестарт) уходят, как
        // только сессия готова / появится сеть.
        final sender = OutboxSender(
          store: store,
          rpc: ClientMessagesRpc(client),
        );
        _outbox = sender;
        sender.start();
        if (kDebugMode) {
          debugPrint('[MessengerRuntime] offline cache ready (ns=$namespace)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MessengerRuntime] offline cache disabled: $e');
      }
    }
  }

  /// **TASK47**: явно очистить дисковый кэш ТЕКУЩЕГО пользователя — host-app
  /// зовёт при ЛОГАУТЕ (§3 п.3). Кэш скоуплен по userId, поэтому чистит
  /// только вышедшего. No-op если кэш выключен.
  Future<void> clearOfflineCache() async {
    try {
      await _cache?.clear();
    } catch (_) {}
  }

  /// **TASK20 followup (a)**: runtime-level lifecycle hook. Forwards
  /// state to bus (presence + suspend underlying sub) и принудительно
  /// дёргает `forceReconnect` на resumed чтобы поднять WS, если он
  /// тихо умер в background-е.
  ///
  /// **Все платформы** (было mobile-only): `forceReconnect` на `resumed`
  /// теперь безусловен. На desktop каждый Alt+Tab генерирует
  /// `inactive → resumed`; раньше боялись, что это рвёт живой WebSocket,
  /// поэтому гейтили по mobile. Но [MessengerEventBus.forceReconnect] имеет
  /// healthy-fast-path (живой + healthy + без retry/stop → ранний return),
  /// так что resumed при здоровом сокете — no-op, а при зависшем transport-е
  /// (desktop: sub закрыт auth-веткой без retry, retry-loop не крутится) —
  /// поднимает соединение без ожидания рестарта приложения.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bus = _eventBus;
    if (bus == null) return;
    bus.onAppLifecycleChanged(state);
    // **OUTBOX**: на возврате в foreground будим дренаж очереди — ОС могла
    // убить процесс/сеть в фоне; при resume добиваем отложенные отправки.
    if (state == AppLifecycleState.resumed) {
      _outbox?.kick();
    }
    // **TASK55**: presence-heartbeat живёт только в foreground.
    _lifecycleResumed = state == AppLifecycleState.resumed;
    if (_lifecycleResumed) unawaited(_sendPresenceHeartbeat());
    if (state == AppLifecycleState.resumed) {
      // iOS/Android: ОС могла убить WS в фоне (Background Modes / Doze) —
      // поднимаем на resume. Desktop (Windows): lifecycle-события реже, но
      // `resumed` при возврате фокуса окну — дешёвый backstop, если
      // retry-loop завис (напр. sub закрыт auth-веткой без retry, см.
      // [_onStreamAuthError]). Безопасно на ВСЕХ платформах благодаря
      // healthy-fast-path в [MessengerEventBus.forceReconnect]: живой
      // healthy-сокет НЕ рвётся (ранний return) — пересоздание только
      // когда transport реально не healthy.
      bus.forceReconnect();
    }
  }

  /// **TASK55**: best-effort heartbeat активности (last seen). Ошибки
  /// глушим — offline не должен шуметь.
  Future<void> _sendPresenceHeartbeat() async {
    final client = _client;
    final sm = _sessionManager;
    if (client == null || sm == null || sm.session == null) return;
    try {
      await withAuthRetry(
        () => client.messenger.presenceHeartbeat(),
        sm,
      );
    } catch (_) {
      // молча — следующий тик попробует снова
    }
  }


  /// **Session-recovery fix (a2)**: колбэк для [MessengerEventBus] на
  /// типизированный auth-invalidation в `userEventStream`. Дёргаем
  /// `selfHealStaleToken()` — single-flight refresh протухшего токена.
  ///
  ///   * успех → менеджер эмитит `active` → bus's `_listenToSessionState`
  ///     переподпишет underlying с новым токеном;
  ///   * мёртвый токен (typed auth-fail на refresh) → менеджер чистит
  ///     сессию и эмитит `expired` → host уводит в login;
  ///   * network/5xx → `error` (токен-кэш СОХРАНЁН, red line) → sub остаётся
  ///     закрыт (без spin), восстановление позже через proactive-refresh /
  ///     app-resume `forceReconnect`.
  ///
  /// `selfHealStaleToken` throw-ит на expired/network — но всю нужную
  /// state-машину он уже прогнал через `emitState`; здесь просто глотаем
  /// исключение (исход несёт session-state stream, не этот await).
  Future<void> _onStreamAuthError() async {
    try {
      await _sessionManager?.selfHealStaleToken();
    } catch (_) {
      // selfHeal бросает на expired (host → login через state) или
      // network (токен сохранён). Итог — в sessionStateStream, не тут.
      //
      // **Desktop-фикс зависания**: на network-fail токен цел, но underlying
      // sub закрыт auth-веткой БЕЗ запланированного retry (см.
      // [MessengerEventBus._handleStreamAuthError]) — на desktop, где нет
      // надёжного resume-kick, клиент завис бы до рестарта. Различаем по
      // сессии: `session != null` = network-fail (токен сохранён) → добиваем
      // transport-reconnect с задержкой (дальше обычный retry-loop с backoff);
      // `session == null` = expired → сессия почищена, host уводит в login,
      // reconnect не нужен.
      if (_sessionManager?.session != null) {
        Future<void>.delayed(_authNetworkReconnectDelay, () {
          _eventBus?.forceReconnect();
        });
      }
    }
  }

  /// Задержка перед transport-reconnect после network-fail self-heal
  /// (см. [_onStreamAuthError]). Даём сети шанс подняться, не долбим сразу.
  static const Duration _authNetworkReconnectDelay = Duration(seconds: 3);

  /// Обработка нового token-а от [PushTokenProvider]. Зовётся:
  ///   * на initial init (initial token из getCurrentToken);
  ///   * на каждый emit `tokenStream` (rotation от FCM/APNs);
  ///   * с `null` — token revoked / OS reset → unregister последнюю
  ///     регистрацию.
  Future<void> _onPushTokenChanged(String? token) async {
    final client = _client;
    final provider = _pushTokenProvider;
    if (client == null || provider == null) return;
    try {
      if (token == null) {
        // Provider сообщил что token revoked. Прерываем любую in-flight
        // retry-петлю + unregister последнюю зарегистрированную row.
        _currentPushToken = null;
        if (_lastRegisteredToken != null) {
          // **Session-recovery fix (a2)**: unregister тоже может упасть
          // NotAuthenticated на протухшем токене — self-heal один раз
          // вместо тихого провала. Guard `_sessionManager != null`.
          final sm = _sessionManager;
          final lastToken = _lastRegisteredToken!;
          if (sm != null) {
            await withAuthRetry(
              () => client.messenger.unregisterDevice(pushToken: lastToken),
              sm,
            );
          } else {
            await client.messenger.unregisterDevice(pushToken: lastToken);
          }
          _lastRegisteredToken = null;
        }
        return;
      }
      // Новый или обновлённый token. Получаем DeviceInfo + register
      // с ОГРАНИЧЕННЫМ РЕТРАЕМ. Раньше при сбое (сеть / сервер на
      // редеплое) регистрация «залечивалась» только на следующий
      // tokenStream emit ИЛИ перезапуск app-а. Но стабильный FCM-токен
      // НЕ refresh-ится → одноразовый провал оставлял устройство
      // незарегистрированным навсегда (прод-кейс: у iOS-юзера нет ни
      // одной device_registration, хотя push поддержан). Ретрай с
      // backoff-ом само-залечивает транзиентный сбой в рамках сессии.
      _currentPushToken = token;
      // Токен, зарегистрированный ДО этой ротации — снимем его после
      // успешной регистрации нового (см. ниже), чтобы не копить мёртвые
      // device_registrations на сервере.
      final previousToken = _lastRegisteredToken;
      final info = await provider.getDeviceInfo();
      if (info == null) return;
      const backoff = [
        Duration(seconds: 2),
        Duration(seconds: 6),
        Duration(seconds: 20),
        Duration(seconds: 60),
      ];
      for (var attempt = 0; ; attempt++) {
        // Провайдер отдал новый токен / SDK закрыт / relogin заменил client →
        // бросаем устаревшую петлю (свежий emit зарегистрирует актуальный
        // токен на новом client). `!identical` ловит relogin в окне backoff:
        // client не null и токен тот же, но инстанс уже другой (старый закрыт).
        if (_client == null ||
            !identical(_client, client) ||
            _currentPushToken != token) {
          return;
        }
        try {
          // **Session-recovery fix (a2)**: оборачиваем registerDevice в
          // withAuthRetry — если session-токен протух, `NotAuthenticated`
          // теперь self-heal-ится ОДИН раз (refresh → retry) вместо того,
          // чтобы крутить bounded-loop с одним и тем же мёртвым токеном
          // каждые ~30s (прод-симптом). Non-auth ошибки (сеть/5xx) пролетают
          // мимо withAuthRetry и попадают в существующий bounded-retry ниже.
          // Guard `_sessionManager != null` — без менеджера (не должно
          // случаться после init) зовём напрямую.
          final sm = _sessionManager;
          Future<void> doRegister() => client.messenger.registerDevice(
            platform: info.platform,
            pushToken: token,
            pushService: info.pushService,
            locale: info.locale,
            appVersion: info.appVersion,
            deviceModel: info.deviceModel,
            productExternalKey: _pushProductExternalKey,
          );
          if (sm != null) {
            await withAuthRetry(doRegister, sm);
          } else {
            await doRegister();
          }
          _lastRegisteredToken = token;
          // Ротация токена (A→B): снимаем СТАРУЮ регистрацию. Иначе сервер
          // копит мёртвые токены и шлёт push в пустоту (прод-кейс: у юзера
          // 2 fcm-токена, доставка на устаревший не доходит). Best-effort:
          // сбой снятия не критичен — server-side TTL-sweep подчистит.
          if (previousToken != null && previousToken != token) {
            try {
              await client.messenger.unregisterDevice(pushToken: previousToken);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[MessengerRuntime] unregister stale token: $e');
              }
            }
          }
          return;
        } catch (e, st) {
          if (attempt >= backoff.length) {
            if (kDebugMode) {
              debugPrint(
                '[MessengerRuntime] registerDevice exhausted retries: $e\n$st',
              );
            }
            return;
          }
          if (kDebugMode) {
            debugPrint(
              '[MessengerRuntime] registerDevice attempt ${attempt + 1} '
              'failed: $e (retry in ${backoff[attempt].inSeconds}s)',
            );
          }
          await Future<void>.delayed(backoff[attempt]);
        }
      }
    } catch (e, st) {
      // Внешний catch — сбой getDeviceInfo / unregister-ветки. Push
      // registration не критичен; следующий emit / init повторит.
      if (kDebugMode) {
        debugPrint('[MessengerRuntime] push token handling failed: $e\n$st');
      }
    }
  }

  /// **TASK46 (звонки в фоне)**: регистрация PushKit VoIP-токена iOS как
  /// отдельного устройства (`pushService=voip`). Зовётся host-app-ом, когда
  /// натив (PushKit `didUpdatePushCredentials`) выдал/обновил токен —
  /// возможно ещё до готовности `client`. Токен кэшируем и регистрируем при
  /// первой возможности (см. [_flushVoipToken] + вызов в конце `init`).
  ///
  /// `null` → PushKit отозвал токен: снимаем последнюю VoIP-регистрацию.
  Future<void> registerVoipToken(String? token) async {
    if (token == null) {
      final last = _lastRegisteredVoipToken;
      _pendingVoipToken = null;
      if (last != null && _client != null) {
        try {
          await _client!.messenger.unregisterDevice(pushToken: last);
        } catch (_) {
          // best-effort — server-side stale row очистится по TTL.
        }
        _lastRegisteredVoipToken = null;
      }
      return;
    }
    // Идемпотентность: тот же токен уже зарегистрирован — не дёргаем сеть.
    if (token == _lastRegisteredVoipToken) return;
    _pendingVoipToken = token;
    await _flushVoipToken();
  }

  /// Зарегистрировать отложенный VoIP-токен, если `client` готов. Тихий
  /// best-effort: при ошибке токен остаётся pending и повторится на
  /// следующем `init` / вызове [registerVoipToken].
  Future<void> _flushVoipToken() async {
    final client = _client;
    final token = _pendingVoipToken;
    if (client == null || token == null) return;
    try {
      // Метаданные берём у FCM-provider-а (locale/appVersion/model), но
      // platform=ios и pushService=voip — это отдельная регистрация.
      final info = await _pushTokenProvider?.getDeviceInfo();
      await client.messenger.registerDevice(
        platform: DevicePlatform.ios,
        pushToken: token,
        pushService: PushService.voip,
        locale: info?.locale ?? 'en',
        appVersion: info?.appVersion ?? '',
        deviceModel: info?.deviceModel,
        productExternalKey: _pushProductExternalKey,
      );
      _lastRegisteredVoipToken = token;
      _pendingVoipToken = null;
      if (kDebugMode) {
        debugPrint('[MessengerRuntime] VoIP-токен зарегистрирован (voip)');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[MessengerRuntime] registerVoipToken failed: $e\n$st');
      }
    }
  }

  /// **TASK22-Phase2 Chunk 2 PART C**: install pre-built collaborators
  /// for the headless demo mode (no real Client, no WebSocket, no
  /// session manager). Called only from `NsgMessenger.initDemo` —
  /// **NOT for production use**. Throws [StateError] if the runtime
  /// has already been initialised.
  ///
  /// Demo-mode lifetime semantics:
  ///   * `client` / `session` getters throw (no real backend exists);
  ///   * `rooms`, `notificationSettings`, `eventBus`, `theme`, `locale`,
  ///     `config` all behave normally — they're backed by the in-
  ///     memory fakes the caller passed in.
  ///   * `dispose()` closes the demo stream controllers and resets
  ///     everything just like in production mode.
  void installDemo({
    required NsgMessengerRooms rooms,
    required NsgMessengerSettings settings,
    required MessengerEventBus eventBus,
    required StreamController<MessengerSessionState> sessionStateController,
    required StreamController<MessengerEvent> demoEventController,
    required NsgMessengerTheme theme,
    required NsgMessengerLocale locale,
    NsgMessengerConfig? config,
  }) {
    if (isInitialized) {
      throw StateError(
        'MessengerRuntime.installDemo() called on already-initialised '
        'runtime. Call dispose() first or use a fresh process.',
      );
    }
    _rooms = rooms;
    _notificationSettings = settings;
    _eventBus = eventBus;
    _demoSessionStateCtl = sessionStateController;
    _demoEventCtl = demoEventController;
    _theme = theme;
    _locale = locale;
    _config = config;
    // Emit `active` so anything listening on stateStream (e.g. the
    // `ChatsListController.refresh` trigger) doesn't sit waiting for a
    // session to come up.
    _emit(MessengerSessionState.active);
  }

  /// Принудительно пересоздать сессию через AuthTokenProvider.
  /// Используется host-app-ом после logout/login. Кэш стирается,
  /// fingerprint-сравнение выявит «новый юзер» и создаст fresh сессию.
  Future<void> reauthenticate() async {
    final m = _sessionManager;
    if (m == null) {
      throw StateError(
        'reauthenticate() до init() — сначала NsgMessenger.init(...).',
      );
    }
    await m.reauthenticate();
  }

  Future<void> dispose() async {
    _emit(MessengerSessionState.uninitialised);
    // **TASK49 (share-in)**: отложенный share скоуплен на текущую сессию —
    // на logout/switch аккаунта он не должен «выстрелить» для другого юзера.
    sharePendingSlot.clear();
    shareFlowActive = false;
    shareUiReady = false;
    // **TASK20 followup (a)**: unregister lifecycle observer ДО bus
    // teardown — иначе between `addObserver(this)` и teardown-ом
    // системный resume может triggers `didChangeAppLifecycleState` на
    // bus который уже disposed.
    if (_lifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleObserverRegistered = false;
    }
    // TASK20 Chunk 3: unregister push token ДО session/client teardown
    // — нужен живой client.messenger.unregisterDevice. Best-effort:
    // если упадёт (network, или session уже expired) — просто
    // продолжаем dispose, server-side будет stale row, cleanup TTL
    // 90+ дней (TASK20-Phase2).
    await _pushTokenSub?.cancel();
    _pushTokenSub = null;
    if (_lastRegisteredToken != null && _client != null) {
      try {
        await _client!.messenger.unregisterDevice(
          pushToken: _lastRegisteredToken!,
        );
      } catch (_) {
        // Best-effort.
      }
      _lastRegisteredToken = null;
    }
    // **TASK46 (звонки в фоне)**: снять VoIP-регистрацию текущего аккаунта
    // (на logout/switch этот device не должен получать звонки старого
    // пользователя). Host-app (CallKitBridge) заново зарегистрирует токен
    // после re-init — registerVoipToken идемпотентен.
    if (_lastRegisteredVoipToken != null && _client != null) {
      try {
        await _client!.messenger.unregisterDevice(
          pushToken: _lastRegisteredVoipToken!,
        );
      } catch (_) {
        // Best-effort.
      }
    }
    _lastRegisteredVoipToken = null;
    _pendingVoipToken = null;
    _pushTokenProvider = null;
    _pushProductExternalKey = null;

    // Порядок: calls → rooms → eventBus → sessionManager → client.
    // calls/rooms подписаны на eventBus.events, eventBus на
    // sessionStateStream.
    // **TASK51**: конференция первой — её dispose ещё шлёт best-effort
    // leaveConference/hangup-ы через живой client (спека: dispose рантайма
    // = наш выход из конференции).
    _conferenceCalls?.dispose();
    _conferenceCalls = null;
    // **TASK46 (SDK)**: CallController — ChangeNotifier + подписка на
    // event bus + возможный активный pc; dispose закрывает всё.
    _calls?.dispose();
    _calls = null;
    // **OUTBOX**: останавливаем фоновый отправитель (таймер) ДО закрытия
    // store — очередь на диске сохраняется, доставится после re-init.
    await _outbox?.dispose();
    _outbox = null;
    // **TASK47**: закрываем дисковый кэш (НЕ чистим — переживает рестарт
    // для оффлайна; явная чистка при логауте — clearOfflineCache).
    await _cache?.close();
    _cache = null;
    await _rooms?.dispose();
    _rooms = null;
    _notificationSettings = null;
    // **TASK58**: контроллер интеграций — stateless-прокси, отдельного
    // teardown не требует (нет подписок/ресурсов); просто сбрасываем ссылку.
    _integrations = null;
    // **TASK36**: админка ботов — stateless-прокси, teardown-а не требует.
    _botsAdmin = null;
    // **TASK78 п.3**: платформенная админка — stateless-прокси, teardown-а
    // не требует.
    _platformAdmin = null;
    // **Issue #49**: «Мои боты» — тоже stateless-прокси.
    _myBots = null;
    // **TASK60**: контроллер Pulse — тоже stateless-прокси (стрим-подписку
    // держит UI, не runtime); сбрасываем ссылку.
    _pulse = null;
    _contacts = null;
    _contactCards = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    unawaited(_contactSyncSub?.cancel());
    _contactSyncSub = null;
    await _eventBus?.dispose();
    _eventBus = null;
    await _sessionManager?.dispose();
    _sessionManager = null;
    _client?.close();
    _client = null;
    _config = null;
    // **TASK22-Phase2 Chunk 2 PART C**: clean up demo stream
    // controllers (no-op in production where they're null).
    await _demoSessionStateCtl?.close();
    _demoSessionStateCtl = null;
    await _demoEventCtl?.close();
    _demoEventCtl = null;
  }

  // ---------- Internal ----------

  void _emit(MessengerSessionState state) {
    _state = state;
    _stateCtl.add(state);
  }
}
