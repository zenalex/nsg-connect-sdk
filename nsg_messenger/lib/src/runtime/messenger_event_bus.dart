import 'dart:async';
import 'dart:collection';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_session_state.dart';
import 'messenger_connection_state.dart';

/// Сигнатура для `client.messenger.userEventStream` — позволяет тестам
/// подменить настоящий Serverpod-стрим на in-memory fake.
typedef UserEventStreamFactory = Stream<MessengerEvent> Function();

/// Сигнатура для `client.messenger.setPresence` — host-app-у не нужно
/// знать про этот RPC (вызывается только из bus при lifecycle change),
/// но тестам нужно подменять без поднятия Serverpod.
typedef SetPresenceFn =
    Future<void> Function({int? currentRoomId, required bool foreground});

/// Аггрегированный broadcast-стрим [MessengerEvent]-ов от backend-а.
/// Один singleton-подписчик на `client.messenger.userEventStream()`,
/// fan-out через `StreamController.broadcast`. Используется:
///   * `NsgMessengerRooms` (TASK13 Chunk 2b) — invalidation cache при
///     `messageCreated`.
///   * `ChatsListScreen`/`ChatScreen` UI обёртки (TASK14/15) —
///     reactive rebuild.
///   * Stream wrappers с auto-reconnect on token rotation (TASK17).
///   * `PushRoutingService` foreground-suppression (TASK20).
///
/// Lifecycle:
///   * подписка на underlying stream создаётся **лениво** при первом
///     `attach()`/наличии listener-ов — иначе SDK не дёргает sync
///     worker на сервере без необходимости (sync-loop недёшев);
///   * при `MessengerSessionState.refreshing` или `expired` underlying
///     subscription cancel-ится; при следующем `active` — re-subscribe
///     с новым токеном (через `MessengerSessionManager.attach()` уже
///     обновлён `client.authKeyProvider`).
///
/// **Реальный lifecycle в SDK** (см. ревью 8985cce #1): `NsgMessengerRooms`
/// (TASK13 Chunk 2b) подписывается на bus сразу в `attach()` для cache
/// invalidation. Это означает, что **lazy-семантика bus-а в production
/// фактически отключена** — с момента `NsgMessenger.init()` underlying
/// sub держится открытым до `dispose()`, и серверный sync worker
/// горит постоянно. На long-poll mobile это OK (battery acceptable),
/// но **background suppression** (cancel underlying когда app в
/// background) — TASK20 push routing. Lazy-режим bus-а актуален только
/// в тестах или если Rooms не attached.
///
/// **Не public API SDK** на TASK13. Public expose будет в TASK17,
/// когда появятся stream-wrappers поверх. На TASK13 доступен только
/// внутренним SDK-классам через `MessengerRuntime`.
class MessengerEventBus {
  /// **TASK20 followup (a)**: default fast-then-slow backoff curve. After
  /// the last entry the cap (30s) is reused for every subsequent
  /// attempt. Each delay is jittered ±20% to avoid thundering-herd.
  static const List<Duration> defaultReconnectBackoff = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
  ];

  /// **TASK20 followup (a)**: default number of consecutive failed
  /// reconnect attempts before transitioning into
  /// [MessengerConnectionState.disconnected].
  static const int defaultDisconnectedAfterFailures = 3;

  final UserEventStreamFactory _streamFactory;
  final Stream<MessengerSessionState> _sessionStateStream;
  final SetPresenceFn? _setPresence;
  final void Function(Object error, StackTrace stack)? _onError;
  final List<Duration> _reconnectBackoff;
  final int _disconnectedAfterFailures;
  final Random _jitterRng;

  StreamController<MessengerEvent>? _controller;
  StreamSubscription<MessengerEvent>? _underlyingSub;
  StreamSubscription<MessengerSessionState>? _stateSub;
  bool _disposed = false;

  // ── reconnect state machine ────────────────────────────────────────
  /// Number of consecutive failed reconnect attempts since the last
  /// successful underlying-stream connection. Reset to 0 on first
  /// successful event (or successful `listen` without error within
  /// the first scheduling pass).
  int _consecutiveFailures = 0;

  /// Active retry timer (null while bus is healthy or while underlying
  /// sub is currently active). Cancelled on dispose / on explicit
  /// `forceReconnect` / on session-state-driven stop.
  Timer? _retryTimer;

  MessengerConnectionState _connectionState = MessengerConnectionState.healthy;
  final StreamController<MessengerConnectionState> _connectionStateCtl =
      StreamController<MessengerConnectionState>.broadcast();

  /// True пока приложение в background (`paused`/`detached`); используется
  /// в `onAppLifecycleChanged` для решения — re-attach или нет на
  /// `active` session-state. Без этого лога `paused → session.refreshing
  /// → session.active` восстановил бы underlying sub, хотя app в bg.
  bool _backgrounded = false;

  /// FIFO-with-capacity dedup для `matrixEventId`. После reconnect-а на
  /// rotated token underlying server-stream может пере-доставить
  /// уже виденные события (особенно при отлове граничного timestamp-а
  /// в Matrix `/sync`). Дубли отбрасываем.
  ///
  /// **Только для events с `message.matrixEventId != null`.** Membership
  /// / state-events на TASK17 ещё не имеют надёжного eventId-маркера;
  /// доверяем Matrix sync структуре (per-room state events не
  /// дублируются внутри одного `/sync` cycle). Если позже окажется,
  /// что дубли есть — расширим composite key (см. ревью TASK17 plan
  /// Q3).
  ///
  /// `LinkedHashMap` сохраняет порядок вставки; первый удаляется когда
  /// размер превышает [_dedupCapacity]. LRU не нужен: мы никогда не
  /// «re-access»-им event, только `containsKey + put`.
  static const int _dedupCapacity = 1000;
  final LinkedHashMap<String, void> _seenEventIds = LinkedHashMap();

  /// True пока есть хотя бы один подписчик. Lazy lifecycle — без
  /// listener-ов SDK не открывает long-poll к серверу.
  bool get hasListeners => _controller?.hasListener ?? false;

  MessengerEventBus._({
    required UserEventStreamFactory streamFactory,
    required Stream<MessengerSessionState> sessionStateStream,
    SetPresenceFn? setPresence,
    void Function(Object error, StackTrace stack)? onError,
    List<Duration>? reconnectBackoff,
    int? disconnectedAfterFailures,
    Random? jitterRng,
  }) : _streamFactory = streamFactory,
       _sessionStateStream = sessionStateStream,
       _setPresence = setPresence,
       _onError = onError,
       _reconnectBackoff = reconnectBackoff ?? defaultReconnectBackoff,
       _disconnectedAfterFailures =
           disconnectedAfterFailures ?? defaultDisconnectedAfterFailures,
       _jitterRng = jitterRng ?? Random();

  /// Production-фабрика. Привязывается к `client.messenger.userEventStream`
  /// и сессионному state-stream-у из `MessengerSessionManager`.
  static MessengerEventBus attach({
    required Client client,
    required Stream<MessengerSessionState> sessionStateStream,
    void Function(Object error, StackTrace stack)? onError,
  }) => attachWithFactory(
    streamFactory: client.messenger.userEventStream,
    setPresence: client.messenger.setPresence,
    sessionStateStream: sessionStateStream,
    onError: onError,
  );

  /// Test-фабрика. Принимает [UserEventStreamFactory] напрямую,
  /// чтобы тесты могли подсунуть `StreamController.stream` без
  /// настоящего Serverpod Client-а.
  ///
  /// **TASK20 followup (a)**: `reconnectBackoff` / `disconnectedAfterFailures`
  /// / `jitterRng` — visible-for-testing knobs для unit-тестов реконнекта
  /// (короткие задержки + детерминистичный RNG).
  @visibleForTesting
  static MessengerEventBus attachWithFactory({
    required UserEventStreamFactory streamFactory,
    required Stream<MessengerSessionState> sessionStateStream,
    SetPresenceFn? setPresence,
    void Function(Object error, StackTrace stack)? onError,
    List<Duration>? reconnectBackoff,
    int? disconnectedAfterFailures,
    Random? jitterRng,
  }) {
    final bus = MessengerEventBus._(
      streamFactory: streamFactory,
      sessionStateStream: sessionStateStream,
      setPresence: setPresence,
      onError: onError,
      reconnectBackoff: reconnectBackoff,
      disconnectedAfterFailures: disconnectedAfterFailures,
      jitterRng: jitterRng,
    );
    bus._listenToSessionState();
    return bus;
  }

  /// Broadcast-стрим **всех** событий пользователя. Подписка на него
  /// triggers underlying subscription если её ещё нет. Отписка
  /// последнего listener-а закрывает underlying subscription
  /// (lazy lifecycle).
  Stream<MessengerEvent> get events {
    _ensureController();
    return _controller!.stream;
  }

  /// Узкий стрим конкретной комнаты — фильтр над [events]. Один
  /// underlying sync worker per user независимо от количества открытых
  /// чатов; SDK / spike фильтруют локально (см. ревью TASK17 plan Q2).
  ///
  /// **Dedup унаследован от [events]** — `.where()` это pure filter без
  /// повторной проверки `_seenEventIds` (см. ревью 8336e2e #5). Если
  /// host-app подписывается одновременно на `events` и
  /// `roomStream(X)` — оба стрима получают **уже** дедуплицированные
  /// сообщения; никаких двойных проверок.
  Stream<MessengerEvent> roomStream(int roomId) =>
      events.where((e) => e.roomId == roomId);

  /// **TASK20 followup (a)**: stream-of-transport-health (см.
  /// [MessengerConnectionState]). Separate from [stateStream] на
  /// runtime-level (тот — auth/login axis).
  ///
  /// Broadcast: подписка не triggers underlying subscription (нет
  /// onListen-стартового effect-а). Initial value через [connectionState]
  /// getter — stream сам emit-ит только при transitions.
  Stream<MessengerConnectionState> get connectionStateStream =>
      _connectionStateCtl.stream;

  /// Текущее значение [connectionStateStream]. Default — [healthy].
  MessengerConnectionState get connectionState => _connectionState;

  /// **TASK20 followup (a)**: явно перепроверить здоровье WS-соединения.
  /// Cancel-ит активный retry-timer и пытается переподписаться немедленно.
  ///
  /// Вызывается:
  ///   * [MessengerRuntime] при `AppLifecycleState.resumed` (iOS/Android
  ///     background может silently убить WS, а bus об этом не узнает
  ///     пока не попробует написать);
  ///   * host-app-ом manually (UI tap по `ConnectionStateIndicator`).
  ///
  /// Idempotent: если bus уже в [healthy] state-е с живой sub —
  /// no-op. Иначе пересоздаёт underlying subscription, reset-ит
  /// failure counter перед попыткой (чтобы UI не зависал в `disconnected`
  /// пока проверяем).
  ///
  /// **Healthy-fast-path** (наблюдали на Windows-клиенте): на каждый
  /// `inactive↔resumed` цикл (Alt+Tab, потеря фокуса окном) `MessengerRuntime`
  /// зовёт `forceReconnect`. Если сокет жив и connectionState == healthy —
  /// рвать его и пересоздавать = `WebSocketClosedException` + 500-600ms
  /// окно «во время которого события теряются». Поэтому если всё хорошо,
  /// просто выходим. Mobile-кейс «iOS Background Modes silently убил WS»
  /// перехватывается через [didChangeAppLifecycleState] → `paused` →
  /// underlying sub отменяется, и на `resumed` sub поднимается заново
  /// через стандартный path, без участия forceReconnect.
  void forceReconnect() {
    if (kDebugMode) debugPrint('[MessengerEventBus] forceReconnect()');
    if (_disposed) return;
    if (!hasListeners) return;
    if (_backgrounded) return;
    // Healthy-fast-path: сокет жив, transport здоров, ни retry, ни stop
    // не идут — никакой работы нет.
    if (_underlyingSub != null &&
        !_stopping &&
        _retryTimer == null &&
        _connectionState == MessengerConnectionState.healthy) {
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] forceReconnect SKIP (healthy + sub alive)',
        );
      }
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_underlyingSub != null) {
      // Уже живой — но мы не уверены что transport здоров (бэкграунд
      // мог убить WS, sub думает что жив). Cancel + re-subscribe.
      unawaited(_stopUnderlyingSubscription());
    }
    _consecutiveFailures = 0;
    _startUnderlyingSubscription();
  }

  /// Вызывается host-app-ом при `WidgetsBindingObserver` app lifecycle
  /// change (TASK20 Chunk 2 implementation).
  ///
  /// **`paused` / `detached`** (app в background, минимизирован, или
  /// detached от engine): cancel underlying `/sync` long-poll subscription
  /// — экономим battery (нет open WebSocket) + server-side sync worker
  /// идёт в idle (`MatrixSyncDispatcher` через 5 мин idleTimeout
  /// останавливается автоматически). Listener-ы на `events` остаются
  /// живыми (broadcast stream); просто никто не feed-ит их пока bg.
  /// Также fire-and-forget `setPresence(foreground: false)` для
  /// server-side `PushRoutingService` (TASK20 Chunk 4) — он будет
  /// слать push notifications для bg user-ов.
  ///
  /// **`resumed`** (app снова в foreground): fire-and-forget
  /// `setPresence(foreground: true)`; если есть active listeners на
  /// `events` — re-attach underlying subscription. Lazy-режим bus-а
  /// сохранён: если listener-ы отвалились пока в bg (host-app dispose-нул
  /// контроллеры) — sub НЕ открываем заранее, дождёмся следующей
  /// подписки.
  ///
  /// **`inactive`** (короткое interruption — notification banner,
  /// control center swipe-down, ~200-500ms): **no-op**. Cancel + reattach
  /// каждый раз создаёт reconnect storm + missed events. Только
  /// `paused`/`detached` cancel-worthy. (Принято в ревью plan #Q2.)
  ///
  /// **Контракт fire-and-forget для `setPresence`:** запросы летят без
  /// `await` — если приложение swiped и app suspended до response,
  /// network-stack drop-нет request, server-side TTL (60s) сам выкинет
  /// stale presence. Errors silent (debugPrint только).
  void onAppLifecycleChanged(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint(
        '[MessengerEventBus] onAppLifecycleChanged: $state (current _backgrounded=$_backgrounded hasListeners=$hasListeners)',
      );
    }
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_backgrounded) return; // Идемпотентно — повторный paused.
        _backgrounded = true;
        // setPresence до cancel: пусть server успеет узнать пока WS
        // ещё открыт; всё равно fire-and-forget.
        _firePresence(foreground: false);
        unawaited(_stopUnderlyingSubscription());

      case AppLifecycleState.resumed:
        if (!_backgrounded) return; // Идемпотентно.
        _backgrounded = false;
        _firePresence(foreground: true);
        if (hasListeners) {
          if (kDebugMode) {
            debugPrint('[MessengerEventBus] resumed → re-attach underlying');
          }
          _startUnderlyingSubscription();
        }

      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // No-op:
        //
        // **`inactive`** — 200-500ms transient (notification banner,
        // control center на mobile; lost focus на desktop). Cancel +
        // reattach каждый раз = reconnect storm + missed events.
        //
        // **`hidden`** — на mobile транзитный шаг между `inactive` и
        // `paused` (если приложение реально уходит в background, придёт
        // `paused` следом, и мы среагируем там). На **macOS desktop**
        // `hidden` приходит при потере фокуса окна / частичном перекрытии
        // — приложение продолжает работать, должно получать сообщения.
        // Раньше мы лечили `hidden` как `paused`, что закрывало stream
        // когда юзер переключился в терминал/браузер; видели в логах
        // mac-клиента, что после `hidden` поток никогда не возобновлялся
        // (resumed не приходит пока окно не снова в фокусе).
        return;
    }
  }

  /// Fire-and-forget `setPresence` без блокировки lifecycle handler.
  /// Если callback не передан (тесты) — silent skip.
  void _firePresence({required bool foreground}) {
    final fn = _setPresence;
    if (fn == null) return;
    // currentRoomId == null: bus не знает про active ChatScreen;
    // ChatScreen сам зовёт setPresence(currentRoomId: X) на open
    // (TASK20 Chunk 4). Lifecycle handler — только foreground toggle.
    final future = fn(currentRoomId: null, foreground: foreground);
    future.catchError((Object e, StackTrace st) {
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] setPresence(foreground=$foreground) failed: $e',
        );
      }
      _onError?.call(e, st);
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _stateSub?.cancel();
    _stateSub = null;
    await _stopUnderlyingSubscription();
    await _controller?.close();
    _controller = null;
    await _connectionStateCtl.close();
    _seenEventIds.clear();
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────

  void _ensureController() {
    if (_controller != null) return;
    if (kDebugMode) {
      debugPrint(
        '[MessengerEventBus] _ensureController — creating broadcast controller',
      );
    }
    _controller = StreamController<MessengerEvent>.broadcast(
      onListen: () {
        if (kDebugMode) {
          debugPrint(
            '[MessengerEventBus] onListen fired → _startUnderlyingSubscription',
          );
        }
        _startUnderlyingSubscription();
      },
      onCancel: () {
        // Все listener-ы отписались — экономим сервер-side sync worker.
        // Если кто-то снова listen-ёт — onListen триггернёт re-subscribe.
        if (kDebugMode) {
          debugPrint(
            '[MessengerEventBus] onCancel fired → _stopUnderlyingSubscription',
          );
        }
        _stopUnderlyingSubscription();
      },
    );
  }

  void _startUnderlyingSubscription() {
    if (_disposed) {
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _startUnderlyingSubscription SKIPPED (disposed)',
        );
      }
      return;
    }
    // **Важен порядок**: сначала чекаем `_stopping`, потом
    // `_underlyingSub != null`. Иначе во время stop-а (когда
    // `_underlyingSub` ещё non-null до завершения cancel) мы
    // попадаем в guard «already running» и `_pendingStartAfterStop`
    // не выставляется → после завершения cancel deferred-start не
    // триггерится → stream остаётся закрытым навсегда (наблюдали
    // в production-логе mac-клиента: forceReconnect → SKIPPED →
    // сообщения перестают приходить).
    if (_stopping) {
      // Race-fix: предыдущий sub ещё cancel-ится. Запомним намерение,
      // авто-перезапустим в finally блока stop-а. Без этого guard-а
      // open-ы накапливались бы парами (см. doc у `_stopping`).
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _startUnderlyingSubscription DEFERRED '
          '(stopping in progress)',
        );
      }
      _pendingStartAfterStop = true;
      return;
    }
    if (_underlyingSub != null) {
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _startUnderlyingSubscription SKIPPED (already running)',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[MessengerEventBus] _startUnderlyingSubscription → calling _streamFactory()',
      );
    }
    try {
      _underlyingSub = _streamFactory().listen(
        (event) {
          if (kDebugMode) {
            debugPrint(
              '[MessengerEventBus] event received type=${event.eventType.name} roomId=${event.roomId} matrixEventId=${event.message?.matrixEventId} typingIds=${event.typingMatrixUserIds} readReceipt=(${event.readReceiptMatrixUserId}, ${event.readReceiptEventId})',
            );
          }
          // **TASK20 followup (a)**: первый успешный event после
          // reconnect-а = transport здоров. Reset failure counter и
          // emit healthy state (idempotent — _setConnectionState
          // фильтрует одинаковые transitions).
          if (_consecutiveFailures != 0 ||
              _connectionState != MessengerConnectionState.healthy) {
            _consecutiveFailures = 0;
            _setConnectionState(MessengerConnectionState.healthy);
          }
          // Dedup только при наличии matrixEventId. См. поле
          // `_seenEventIds` для обоснования; state-events без eventId
          // пробрасываются без проверки.
          //
          // **Важно**: ключ дедупа = `${eventType}:${eventId}`, а НЕ
          // просто eventId. Потому что для `messageUpdated` /
          // `messageDeleted` сервер шлёт event с TARGET eventId (тем
          // же, что был у оригинального `messageCreated`) — это
          // convention SDK reactor-а (matchить существующий bubble по
          // matrixEventId). Если дедупить только по eventId, edit/delete
          // event-ы фильтруются как «уже видели» и reactor никогда не
          // получает их → отредактированное сообщение не обновляется
          // в UI до перерисовки экрана. Composite key решает это —
          // тот же eventId с другим eventType прорывается мимо дедупа.
          final eventId = event.message?.matrixEventId;
          if (eventId != null) {
            final dedupKey = '${event.eventType.name}:$eventId';
            if (_seenEventIds.containsKey(dedupKey)) return;
            _seenEventIds[dedupKey] = null;
            // FIFO-eviction.
            while (_seenEventIds.length > _dedupCapacity) {
              _seenEventIds.remove(_seenEventIds.keys.first);
            }
          }
          _controller?.add(event);
        },
        onError: (Object e, StackTrace st) {
          // **TASK20 followup (a)**: НЕ пробрасываем error consumer-ам.
          // Транспортный layer обрабатывает blip-ы сам: cancel sub,
          // эмит reconnecting/disconnected, schedule retry. Listener-ы
          // (rooms, controllers) не должны видеть transient errors —
          // они появляются в TASK20-followup-c onError handlers, но
          // те — strictly defensive (логирование + preserve UI).
          //
          // **CRITICAL**: token / auth cache НЕ trogаем. Auth invalidation
          // — отдельный axis (`MessengerSessionManager` ловит 401
          // отдельно через retry-interceptor).
          if (kDebugMode) {
            debugPrint(
              '[MessengerEventBus] underlying stream onError: ${e.runtimeType}: $e',
            );
          }
          _onError?.call(e, st);
          _scheduleReconnect(reason: 'onError');
        },
        onDone: () {
          // Серверный стрим закрылся — schedule reconnect. До TASK20
          // followup (a) bus просто nulled sub и ждал onListen, что
          // оставляло клиент silent навсегда (server restart кейс).
          if (kDebugMode) {
            debugPrint(
              '[MessengerEventBus] underlying stream onDone — server closed connection',
            );
          }
          _scheduleReconnect(reason: 'onDone');
        },
      );
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _startUnderlyingSubscription DONE (sub installed)',
        );
      }
    } catch (e, st) {
      // Subscription factory сама бросила (auth не готов / network) —
      // считаем как failed-attempt и schedule retry.
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _streamFactory() THREW synchronously: ${e.runtimeType}: $e',
        );
      }
      _onError?.call(e, st);
      _scheduleReconnect(reason: 'factory threw');
    }
  }

  /// **TASK20 followup (a)**: запланировать reconnect после transport
  /// failure. Increment failure counter, emit reconnecting/disconnected,
  /// schedule retry с jittered backoff.
  void _scheduleReconnect({required String reason}) {
    if (_disposed) return;
    // Sub уже мёртв (onError может прилететь, потом onDone), но
    // защищённо cancel-ним предыдущую — иначе stale sub держит ref на
    // старый Stream и в broadcast-сценариях получает duplicate events.
    final prevSub = _underlyingSub;
    _underlyingSub = null;
    if (prevSub != null) {
      // fire-and-forget cancel: ждать не надо, sub уже эффективно
      // закрыт со стороны Stream-а (error/done доставлены).
      unawaited(prevSub.cancel());
    }
    // Уже есть pending retry timer — игнорируем повторный signal.
    // (Например onError + onDone могут прилететь подряд.)
    if (_retryTimer != null) {
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _scheduleReconnect SKIP (timer already pending) reason=$reason',
        );
      }
      return;
    }
    // Если в background или нет listeners — reconnect не нужен; на
    // resume / новый listen уже сработает _startUnderlyingSubscription.
    if (_backgrounded || !hasListeners) {
      if (kDebugMode) {
        debugPrint(
          '[MessengerEventBus] _scheduleReconnect SKIP (backgrounded=$_backgrounded hasListeners=$hasListeners) reason=$reason',
        );
      }
      return;
    }
    _consecutiveFailures += 1;
    final attempt = _consecutiveFailures;
    final delay = _nextBackoff(attempt);
    final nextState = attempt >= _disconnectedAfterFailures
        ? MessengerConnectionState.disconnected
        : MessengerConnectionState.reconnecting;
    _setConnectionState(nextState);
    if (kDebugMode) {
      debugPrint(
        '[MessengerEventBus] _scheduleReconnect attempt=$attempt '
        'delay=${delay.inMilliseconds}ms state=$nextState reason=$reason',
      );
    }
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (_disposed) return;
      if (!hasListeners || _backgrounded) {
        // Условия изменились пока ждали — reset state; следующий
        // listen/resume вызовет _startUnderlyingSubscription заново.
        return;
      }
      _startUnderlyingSubscription();
    });
  }

  /// Возвращает следующую задержку из [_reconnectBackoff] с ±20% jitter.
  /// Если `attempt` превышает длину массива — используется последний
  /// элемент (cap).
  Duration _nextBackoff(int attempt) {
    final index = (attempt - 1).clamp(0, _reconnectBackoff.length - 1);
    final base = _reconnectBackoff[index].inMilliseconds;
    // jitter ±20%: 0.8 + rand[0..1) * 0.4 → [0.8 .. 1.2)
    final factor = 0.8 + _jitterRng.nextDouble() * 0.4;
    final jittered = (base * factor).round();
    return Duration(milliseconds: jittered);
  }

  void _setConnectionState(MessengerConnectionState next) {
    if (_disposed) return;
    if (_connectionState == next) return;
    _connectionState = next;
    if (!_connectionStateCtl.isClosed) {
      _connectionStateCtl.add(next);
    }
  }

  /// True пока идёт async-cancel предыдущего underlying sub. Защищает
  /// от race-условия: если кто-то зовёт [_startUnderlyingSubscription]
  /// пока предыдущая cancel ещё в полёте, новый sub откроется на
  /// сервере ДО того как старый успеет закрыться → server-side
  /// накапливает «pair of streams» (мы наблюдали такой паттерн в логе
  /// сервера). Guard в [_startUnderlyingSubscription] чекает этот
  /// флаг и no-op-ит; после завершения cancel мы сами re-trigger
  /// start если условия (hasListeners && !_backgrounded) сохранились.
  bool _stopping = false;
  bool _pendingStartAfterStop = false;

  Future<void> _stopUnderlyingSubscription() async {
    // **TASK20 followup (a)**: also cancel pending retry timer — иначе
    // session-state `refreshing` (token rotation) или lifecycle
    // `paused` оставят hot timer, который через 0.5-30s reconnect-нёт
    // в неподходящий момент.
    _retryTimer?.cancel();
    _retryTimer = null;
    final sub = _underlyingSub;
    if (sub == null) return;
    // НЕ нулим _underlyingSub до завершения cancel — иначе concurrent
    // `_startUnderlyingSubscription` пройдёт guard и откроет второй sub.
    _stopping = true;
    if (kDebugMode) {
      debugPrint(
        '[MessengerEventBus] _stopUnderlyingSubscription — cancelling '
        'existing sub (await)',
      );
    }
    try {
      await sub.cancel();
    } finally {
      _underlyingSub = null;
      _stopping = false;
      // Если кто-то пытался start во время cancel (session active /
      // lifecycle resumed / new listener), мы заблокировали его guard-ом;
      // теперь cancel завершён — повторно попробуем start если условия
      // живы.
      if (_pendingStartAfterStop) {
        _pendingStartAfterStop = false;
        if (!_disposed && hasListeners && !_backgrounded) {
          if (kDebugMode) {
            debugPrint(
              '[MessengerEventBus] _stopUnderlyingSubscription — '
              'deferred start triggers now',
            );
          }
          _startUnderlyingSubscription();
        }
      }
    }
  }

  /// При смене session-state:
  ///   * `refreshing` или `expired` — текущий sub становится протухшим
  ///     (использует старый auth-token); cancel-им сейчас, при
  ///     следующем `active` — переподписка с новым токеном.
  ///   * `active` — если есть listeners, переподписываемся.
  void _listenToSessionState() {
    _stateSub = _sessionStateStream.listen(
      (state) async {
        if (kDebugMode) {
          debugPrint(
            '[MessengerEventBus] sessionState=$state hasListeners=$hasListeners backgrounded=$_backgrounded',
          );
        }
        if (_disposed) return;
        if (state == MessengerSessionState.refreshing ||
            state == MessengerSessionState.expired ||
            state == MessengerSessionState.error) {
          await _stopUnderlyingSubscription();
        } else if (state == MessengerSessionState.active) {
          // Не re-attach пока app в background — иначе session refresh
          // во время свернутого app-а откроет underlying sub впустую
          // и сломает battery suppression.
          if (hasListeners && !_backgrounded) {
            if (kDebugMode) {
              debugPrint(
                '[MessengerEventBus] sessionState=active → re-attach underlying',
              );
            }
            _startUnderlyingSubscription();
          } else {
            if (kDebugMode) {
              debugPrint(
                '[MessengerEventBus] sessionState=active but SKIP re-attach (hasListeners=$hasListeners backgrounded=$_backgrounded)',
              );
            }
          }
        }
      },
      onError: (Object e, StackTrace st) {
        // Session-state stream сам никогда не должен ошибиться, но если
        // вдруг — log + продолжаем работать с последним известным
        // состоянием.
        if (kDebugMode) {
          debugPrint('[MessengerEventBus] session-state stream error: $e\n$st');
        }
        _onError?.call(e, st);
      },
    );
  }
}
