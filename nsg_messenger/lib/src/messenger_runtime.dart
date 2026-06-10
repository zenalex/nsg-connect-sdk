import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'auth_token_provider.dart';
import 'messenger_mode.dart';
import 'messenger_session_state.dart';
import 'push/push_token_provider.dart';
import 'rooms/nsg_messenger_rooms.dart';
import 'rooms/room_summary_tile.dart' show registerTimeagoLocales;
import 'settings/nsg_messenger_settings.dart';
import 'runtime/messenger_connection_state.dart';
import 'runtime/messenger_event_bus.dart';
import 'runtime/nsg_messenger_config.dart';
import 'session/auth_token_store.dart';
import 'session/messenger_session_manager.dart';
import 'theme/nsg_messenger_theme.dart';

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
  // **TASK22-Phase2 Chunk 2 PART C**: stream controllers owned by
  // `installDemo` (demo mode only). In production these are null; in
  // demo mode they need to be closed in `dispose()`.
  StreamController<MessengerSessionState>? _demoSessionStateCtl;
  StreamController<MessengerEvent>? _demoEventCtl;
  PushTokenProvider? _pushTokenProvider;
  StreamSubscription<String?>? _pushTokenSub;
  String? _lastRegisteredToken;
  String? _pushProductExternalKey;
  // AuthTokenProvider / ErrorReporter / AuthTokenStore передаются прямо
  // в `MessengerSessionManager` и хранятся ВНУТРИ него — runtime не
  // дублирует ссылки. Если в будущем понадобится exposed-getter
  // (например, Settings-screen хочет показать «провайдер привязан») —
  // добавим явный делегат через manager.
  NsgMessengerTheme _theme = NsgMessengerTheme.empty;
  NsgMessengerLocale _locale = const NsgMessengerLocale();
  MessengerMode _mode = MessengerMode.embeddedProduct;
  // **TASK22-Phase2 Chunk 1-B**: behavior knobs (scroll thresholds и
  // пр.). Null = host-app не передал config → возвращаем
  // [NsgMessengerConfig.fallback] из геттера.
  NsgMessengerConfig? _config;

  final StreamController<MessengerSessionState> _stateCtl =
      StreamController<MessengerSessionState>.broadcast();
  MessengerSessionState _state = MessengerSessionState.uninitialised;

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
    _theme = theme ?? NsgMessengerTheme.empty;
    _locale = locale ?? NsgMessengerLocale.resolveFromSystem();
    _mode = mode;
    _config = config;
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
    );
    if (kDebugMode) debugPrint('[MessengerRuntime.init] EventBus attached');
    _rooms = NsgMessengerRooms.attach(client: _client!, eventBus: _eventBus!);
    _notificationSettings = NsgMessengerSettings.attach(_client!);
    if (kDebugMode) {
      debugPrint(
        '[MessengerRuntime.init] Rooms+Settings attached; '
        'calling _sessionManager.init()',
      );
    }
    await _sessionManager!.init();
    if (kDebugMode) {
      debugPrint('[MessengerRuntime.init] _sessionManager.init() OK');
    }

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
    if (kDebugMode) debugPrint('[MessengerRuntime.init] all done');
  }

  /// **TASK20 followup (a)**: runtime-level lifecycle hook. Forwards
  /// state to bus (presence + suspend underlying sub) и принудительно
  /// дёргает `forceReconnect` на resumed чтобы поднять WS, если он
  /// тихо умер в background-е.
  ///
  /// **Desktop-aware** (наблюдали на Windows): на desktop каждый Alt+Tab /
  /// потеря фокуса генерирует `inactive → resumed` (без `paused` между
  /// ними, потому что desktop-окно не уходит в bg в mobile-смысле).
  /// Безусловный `forceReconnect` на каждый resumed = живой WebSocket
  /// рвётся и пересоздаётся, между событиями 500-600ms окно потерь.
  /// Mobile-кейс «iOS Background Modes silently убил WS» здесь по-прежнему
  /// важен: bus сам отменяет sub на `paused`, и `forceReconnect` на
  /// `resumed` гарантирует, что мы не зависнем на dead-sub если bus
  /// почему-то не успел отреагировать (paused не пришёл, ОС зарезала
  /// сокет в фоне). Desktop через этот сценарий не проходит.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bus = _eventBus;
    if (bus == null) return;
    bus.onAppLifecycleChanged(state);
    if (state == AppLifecycleState.resumed && _isMobilePlatform) {
      // iOS Background Modes / Android Doze может убить WS без
      // notifying client-а. Bus's pause-handler уже cancel-нет sub на
      // background; на resume сам подними её через forceReconnect
      // (он idempotent).
      bus.forceReconnect();
    }
  }

  /// True для платформ, где ОС может тихо убить WebSocket в фоне
  /// (iOS Background Modes, Android Doze). На desktop / web такого нет —
  /// `paused`/`resumed` редки, потерянный фокус окна (`inactive`/`hidden`)
  /// не приводит к разрыву соединения.
  bool get _isMobilePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

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
        // Provider сообщил что token revoked. Unregister последнюю
        // зарегистрированную row.
        if (_lastRegisteredToken != null) {
          await client.messenger.unregisterDevice(
            pushToken: _lastRegisteredToken!,
          );
          _lastRegisteredToken = null;
        }
        return;
      }
      // Новый или обновлённый token. Получаем DeviceInfo + register.
      final info = await provider.getDeviceInfo();
      if (info == null) return;
      await client.messenger.registerDevice(
        platform: info.platform,
        pushToken: token,
        pushService: info.pushService,
        locale: info.locale,
        appVersion: info.appVersion,
        deviceModel: info.deviceModel,
        productExternalKey: _pushProductExternalKey,
      );
      _lastRegisteredToken = token;
    } catch (e, st) {
      // Push registration не критичен — silent fail. SDK retry
      // на следующий tokenStream emit (token refresh) или на
      // следующий init. `debugPrint` вместо `print` — в release
      // compile-out + built-in throttling длинных строк (offline
      // customer час будет писать сотни failure-ов; throttling
      // защищает от console flood).
      if (kDebugMode) {
        debugPrint('[MessengerRuntime] registerDevice failed: $e\n$st');
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
    _pushTokenProvider = null;
    _pushProductExternalKey = null;

    // Порядок: rooms → eventBus → sessionManager → client.
    // rooms подписан на eventBus.events, eventBus на sessionStateStream.
    await _rooms?.dispose();
    _rooms = null;
    _notificationSettings = null;
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
