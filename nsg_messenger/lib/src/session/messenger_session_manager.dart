import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../auth_token_provider.dart';
import '../messenger_session_state.dart';
import 'auth_context_fingerprint.dart';
import 'auth_token_store.dart';
import 'messenger_auth_key_provider.dart';

/// Сигнатура для `session()` и `refresh()` RPC. Манагер дёргает их
/// через колбэки (а не напрямую `client.messenger.X`), чтобы тесты
/// могли подменить их на in-memory fake-и без реального Serverpod-а.
typedef MessengerSessionRpc =
    Future<MessengerSession> Function(MessengerAuthContext ctx);

/// Время ДО `expiresAt`, за которое SDK запускает proactive refresh.
/// 5 минут даёт запас на сетевую задержку и retry, не приближая частоту
/// refresh к границе rate-лимитов backend-а.
const Duration _refreshLeadTime = Duration(minutes: 5);

/// Минимальная задержка перед proactive refresh-ом — защита от
/// «session.expiresAt в прошлом» (clock skew, кэш с истёкшим токеном).
/// Если до `expiresAt - 5min` 0 или меньше — refresh сразу же.
const Duration _minRefreshDelay = Duration(milliseconds: 100);

/// Управляет жизненным циклом серверной сессии в SDK:
///   * **init**: пытается восстановить из [AuthTokenStore] (если
///     fingerprint совпадает с тем, что вернул provider) или создаёт
///     новую через `client.messenger.session(ctx)`;
///   * **proactive refresh**: за [_refreshLeadTime] до `expiresAt`
///     дёргает `client.messenger.refresh(ctx)`;
///   * **reactive refresh**: на 401 от любого RPC Serverpod через
///     [MessengerAuthKeyProvider.refreshAuthKey(force: true)] зовёт
///     этот же `refresh()`. См.
///     [MutexRefresherClientAuthKeyProvider] для гарантии «один refresh
///     в момент времени».
///
/// **Streams и refresh** (см. ревью 51c1094):
/// При proactive refresh уже-открытые WebSocket-стримы продолжают
/// работать на старом auth-handshake до тех пор, пока сервер их не
/// закроет (Serverpod 3.4.7 не разрывает существующие подключения при
/// смене auth-key). При reactive refresh — то же самое, плюс конкретный
/// RPC, упавший с 401, retries-ится с новым токеном автоматически.
/// Auto-reconnect стримов на refresh — TASK17 (когда SDK будет давать
/// stream-обёртки вместо raw client.messenger.roomStream).
class MessengerSessionManager {
  final MessengerSessionRpc _sessionRpc;
  final MessengerSessionRpc _refreshRpc;
  final AuthTokenProvider _authTokenProvider;
  final AuthTokenStore _store;
  final ErrorReporter? _errorReporter;
  final void Function(MessengerSessionState) _emitState;

  /// `MessengerAuthKeyProvider`, который мы установили на `_client`.
  /// Хранится здесь, чтобы push-ить в него новый токен после refresh.
  final MessengerAuthKeyProvider _authKeyProvider;

  MessengerSession? _session;
  Timer? _refreshTimer;
  bool _disposed = false;

  /// Последний fingerprint провайдер-ского ctx-а. Используется для
  /// детекта смены юзера (logout/login на лету) при refresh-е.
  /// Самого ctx (с accessToken) не храним — это PII.
  String? _activeFingerprint;

  /// In-flight init operation. Покрывает ВЕСЬ `init()` (включая
  /// cache.read, store.clear, _createNewSession) — на любом из его
  /// internal-await mutex-decorator может попасть на mutex.authHeaderValue
  /// (триггер от concurrent authenticated RPC) и параллельно запустить
  /// refresh(), который revoke-нёт session(), выданный нашим init.
  /// Поэтому `_refreshAuthKey` ждёт завершения init и возвращает
  /// `skipped`. См. ревью 2026-05-23.
  Completer<void>? _initInProgress;

  /// **TASK20 followup (b)**: in-flight self-heal Completer. Гарантирует
  /// single-flight на [selfHealStaleToken] — N RPC-ов одновременно
  /// поймали типизированный auth-error → только ОДИН реальный refresh,
  /// остальные ждут его future. На отдельный Completer (не reused
  /// `_initInProgress`), потому что init и self-heal — разные семантические
  /// операции: init может вообще не быть в self-heal сценарии, а
  /// self-heal не имеет смысла до завершения init.
  Completer<String?>? _selfHealInProgress;

  MessengerSessionManager._({
    required MessengerSessionRpc sessionRpc,
    required MessengerSessionRpc refreshRpc,
    required AuthTokenProvider authTokenProvider,
    required AuthTokenStore store,
    required ErrorReporter? errorReporter,
    required void Function(MessengerSessionState) emitState,
    required MessengerAuthKeyProvider authKeyProvider,
  }) : _sessionRpc = sessionRpc,
       _refreshRpc = refreshRpc,
       _authTokenProvider = authTokenProvider,
       _store = store,
       _errorReporter = errorReporter,
       _emitState = emitState,
       _authKeyProvider = authKeyProvider;

  /// Production-фабрика: оборачивает `client.messenger.session/refresh`
  /// и устанавливает auth-key provider на client.
  static MessengerSessionManager attach({
    required Client client,
    required AuthTokenProvider authTokenProvider,
    required AuthTokenStore store,
    required ErrorReporter? errorReporter,
    required void Function(MessengerSessionState) emitState,
  }) => attachWithRpcs(
    sessionRpc: client.messenger.session,
    refreshRpc: client.messenger.refresh,
    installAuthKeyProvider: (kp) {
      // Mutex-decorator из serverpod_client — гарантирует, что
      // concurrent RPC ждут одного refresh-а, а не вызывают
      // параллельные. **Важно**: оба auth-эндпоинта (`messenger.session`,
      // `messenger.refresh`) на сервере помечены `@unauthenticatedClientCall`
      // — иначе mutex-getter `authHeaderValue` рекурсивно дёргает
      // `refreshAuthKey` → deadlock на первом запросе.
      client.authKeyProvider = MutexRefresherClientAuthKeyProvider(kp);
    },
    authTokenProvider: authTokenProvider,
    store: store,
    errorReporter: errorReporter,
    emitState: emitState,
  );

  /// Test-фабрика. Принимает RPC-функции напрямую и опциональный
  /// `installAuthKeyProvider` (по умолчанию no-op — тестам не нужен
  /// настоящий Client). Вызывается из `attach()` под капотом.
  @visibleForTesting
  static MessengerSessionManager attachWithRpcs({
    required MessengerSessionRpc sessionRpc,
    required MessengerSessionRpc refreshRpc,
    required AuthTokenProvider authTokenProvider,
    required AuthTokenStore store,
    required ErrorReporter? errorReporter,
    required void Function(MessengerSessionState) emitState,
    void Function(MessengerAuthKeyProvider)? installAuthKeyProvider,
  }) {
    late final MessengerSessionManager manager;
    final keyProvider = MessengerAuthKeyProvider(
      onForceRefresh: ({bool force = false}) =>
          manager._refreshAuthKey(force: force),
    );
    installAuthKeyProvider?.call(keyProvider);

    manager = MessengerSessionManager._(
      sessionRpc: sessionRpc,
      refreshRpc: refreshRpc,
      authTokenProvider: authTokenProvider,
      store: store,
      errorReporter: errorReporter,
      emitState: emitState,
      authKeyProvider: keyProvider,
    );
    return manager;
  }

  /// Test-only: токен в auth-провайдере. Помогает интеграционному
  /// тесту проверить, что после refresh provider содержит новый токен.
  @visibleForTesting
  Future<String?> get currentAuthHeaderValueForTest =>
      _authKeyProvider.authHeaderValue;

  /// Test-only: симулирует тот же путь, что 401-retry от Serverpod-а
  /// или срабатывание proactive timer-а. Возвращает [RefreshAuthKeyResult]
  /// для проверки тестом.
  @visibleForTesting
  Future<RefreshAuthKeyResult> refreshForTest({bool force = true}) =>
      _refreshAuthKey(force: force);

  /// Текущая активная сессия. Null до завершения `init()` или после
  /// `dispose()`.
  MessengerSession? get session => _session;

  /// Запросить контекст у provider-а, попробовать восстановить сессию
  /// из кэша (если fingerprint совпадает и `expiresAt` ещё не истёк),
  /// иначе создать новую через `client.messenger.session(ctx)`.
  /// Запускает proactive refresh-таймер на новый `expiresAt`.
  Future<void> init() async {
    if (kDebugMode) debugPrint('[SessionManager.init] enter');
    final initCompleter = Completer<void>();
    _initInProgress = initCompleter;
    _emitState(MessengerSessionState.refreshing);
    try {
      if (kDebugMode) debugPrint('[SessionManager.init] getAuthContext...');
      final ctx = await _authTokenProvider.getAuthContext();
      final fp = authContextFingerprint(ctx);
      _activeFingerprint = fp;
      if (kDebugMode) debugPrint('[SessionManager.init] auth fp=$fp');

      if (kDebugMode) debugPrint('[SessionManager.init] store.read...');
      final cached = await _store.read();
      if (kDebugMode) {
        debugPrint(
          '[SessionManager.init] store.read OK (cached=${cached != null})',
        );
      }
      if (cached != null &&
          cached.fingerprint == fp &&
          cached.session.expiresAt.isAfter(
            DateTime.now().toUtc().add(_refreshLeadTime),
          )) {
        if (kDebugMode) debugPrint('[SessionManager.init] cache HIT');
        _session = cached.session;
        _authKeyProvider.setToken(cached.session.sessionToken);
        _scheduleRefresh(cached.session.expiresAt);
        _emitState(MessengerSessionState.active);
        return;
      }
      if (kDebugMode) debugPrint('[SessionManager.init] cache MISS');

      if (cached != null && cached.fingerprint != fp) {
        await _store.clear();
      }
      if (kDebugMode) debugPrint('[SessionManager.init] _createNewSession (RPC)...');
      await _createNewSession(ctx, fp);
      if (kDebugMode) debugPrint('[SessionManager.init] _createNewSession OK');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[SessionManager.init] FAILED: $e');
      _errorReporter?.reportError(e, st, tags: {'phase': 'session.init'});
      _emitState(MessengerSessionState.error);
      if (!initCompleter.isCompleted) initCompleter.completeError(e, st);
      rethrow;
    } finally {
      if (!initCompleter.isCompleted) initCompleter.complete();
      // Clear ref ТОЛЬКО если это всё ещё наш Completer — re-entrant init
      // (логин нового юзера во время старого init-а) может перезаписать.
      if (identical(_initInProgress, initCompleter)) {
        _initInProgress = null;
      }
    }
  }

  /// Принудительно сбросить кэш и заново создать сессию. Используется
  /// host-app-ом после logout/login (host-app сам отдаст новый
  /// `MessengerAuthContext` через provider).
  ///
  /// **Не recoverable**: `_store.clear()` делается ДО `init()`, и если
  /// `init()` упадёт (сеть, провайдер не может получить токен), кэш
  /// уже потерян. При следующем cold start cache miss → опять `init()`
  /// с зовом провайдера. Это намеренный контракт: re-auth = явный отказ
  /// от старой сессии. Host-app, для которого это важно (плохая сеть),
  /// должен поймать ошибку из `reauthenticate()` и показать UI типа
  /// «попробуйте позже» вместо тихого переключения в `expired`.
  Future<void> reauthenticate() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _session = null;
    _authKeyProvider.setToken(null);
    await _store.clear();
    await init();
  }

  /// Закрыть менеджер. Сессия в БД не отзывается — это сделает
  /// host-app явным `client.messenger.revoke(...)` если нужно (logout).
  ///
  /// **`_store.clear()` НЕ вызывается намеренно.** dispose = «процесс
  /// закрылся / SDK отключили», но юзер логически остался залогиненным.
  /// Cold start подхватит сессию из storage и переиспользует без
  /// похода к провайдеру (если fingerprint совпадает и `expiresAt`
  /// валиден). Стирание кэша — только в `reauthenticate()` (явный
  /// logout от host-app-а).
  Future<void> dispose() async {
    _disposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _session = null;
    _authKeyProvider.setToken(null);
  }

  // ───────────────────────────────────────────────────────────────────
  // Private
  // ───────────────────────────────────────────────────────────────────

  Future<void> _createNewSession(MessengerAuthContext ctx, String fp) async {
    if (kDebugMode) debugPrint('[SessionManager._createNewSession] calling _sessionRpc...');
    final session = await _sessionRpc(ctx).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (kDebugMode) {
          debugPrint(
            '[SessionManager._createNewSession] _sessionRpc TIMEOUT after 15s — '
            'server unreachable или RPC висит. Проверь network/firewall.',
          );
        }
        throw TimeoutException('messenger.session RPC timeout (15s)');
      },
    );
    if (kDebugMode) {
      debugPrint(
        '[SessionManager._createNewSession] _sessionRpc returned '
        'token=${session.sessionToken.length >= 8 ? session.sessionToken.substring(0, 8) : session.sessionToken}...',
      );
    }
    if (_disposed) return;
    _session = session;
    _authKeyProvider.setToken(session.sessionToken);
    await _store.write(
      StoredMessengerSession(
        fingerprint: fp,
        session: session,
        storedAt: DateTime.now().toUtc(),
      ),
    );
    if (_disposed) return;
    _scheduleRefresh(session.expiresAt);
    _emitState(MessengerSessionState.active);
  }

  /// Тело refresh-а. Зовётся из:
  ///   1. таймера (proactive);
  ///   2. [MessengerAuthKeyProvider.refreshAuthKey] на 401 от RPC
  ///      (reactive, force=true).
  ///
  /// Возвращает [RefreshAuthKeyResult] для совместимости с
  /// `RefresherClientAuthKeyProvider`. На force=false и невышедшем
  /// сроке — `skipped` (proactive вызывается строго по таймеру; для
  /// 401 retry mutex-decorator всё равно поставит force=true либо
  /// прозевает result). На сети/сервере — `failedOther`. На отказе
  /// provider-а / типизированном auth-исключении — `failedUnauthorized`
  /// и переход в `expired`.
  Future<RefreshAuthKeyResult> _refreshAuthKey({bool force = false}) async {
    if (_disposed) return RefreshAuthKeyResult.failedOther;

    // Race-guard: init() работает над cache.read / store.clear / session()
    // RPC прямо сейчас. Mutex-decorator на любом await-yield может попасть
    // на parallel-RPC и параллельно дёрнуть refresh() — он revoke-нёт
    // только что выданный session() токен. Ждём завершения init и
    // возвращаем skipped — token к тому моменту будет в _delegate.authHeaderValue.
    final inProgressInit = _initInProgress;
    if (inProgressInit != null && !inProgressInit.isCompleted) {
      try {
        await inProgressInit.future;
      } catch (_) {
        return RefreshAuthKeyResult.failedOther;
      }
      return RefreshAuthKeyResult.skipped;
    }

    final session = _session;
    if (!force && session != null) {
      // Skip-условие: до expiresAt больше lead-time — refresh-ить пока
      // нечего. Это бывает, когда mutex-decorator проверяет «нужен ли
      // refresh» перед каждым RPC. Полезное короткое замыкание.
      final remaining = session.expiresAt.difference(DateTime.now().toUtc());
      if (kDebugMode) {
        debugPrint(
          '[SessionManager._refreshAuthKey] force=$force '
          'session=set remaining=${remaining.inSeconds}s '
          'leadTime=${_refreshLeadTime.inSeconds}s',
        );
      }
      if (remaining > _refreshLeadTime) {
        return RefreshAuthKeyResult.skipped;
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '[SessionManager._refreshAuthKey] force=$force '
          'session=${session == null ? "null" : "set"} → proceeding to refresh',
        );
      }
    }

    _emitState(MessengerSessionState.refreshing);
    try {
      // Каждый await — async-окно, в котором мог сработать `dispose()`
      // (host-app закрыл SDK; в смежном Future — `dispose` стоит в очереди).
      // Без guard-ов мы дописали бы токен в storage и emit-нули `active`
      // на уже закрытом manager-е. См. ревью 3e7e61b #2.
      final ctx = await _authTokenProvider.getAuthContext();
      if (_disposed) return RefreshAuthKeyResult.failedOther;
      final fp = authContextFingerprint(ctx);
      // Если provider вернул другой fingerprint (host-app переключил
      // юзера прямо на лету) — refresh идёт через свежий ctx, но это
      // де-факто новая сессия, не «refresh старой». Стираем кэш и
      // создаём заново.
      if (_activeFingerprint != null && _activeFingerprint != fp) {
        await _store.clear();
        if (_disposed) return RefreshAuthKeyResult.failedOther;
        _activeFingerprint = fp;
        await _createNewSession(ctx, fp);
        return _disposed
            ? RefreshAuthKeyResult.failedOther
            : RefreshAuthKeyResult.success;
      }
      _activeFingerprint = fp;

      final refreshed = await _refreshRpc(ctx);
      if (_disposed) return RefreshAuthKeyResult.failedOther;
      _session = refreshed;
      _authKeyProvider.setToken(refreshed.sessionToken);
      await _store.write(
        StoredMessengerSession(
          fingerprint: fp,
          session: refreshed,
          storedAt: DateTime.now().toUtc(),
        ),
      );
      if (_disposed) return RefreshAuthKeyResult.failedOther;
      _scheduleRefresh(refreshed.expiresAt);
      _emitState(MessengerSessionState.active);
      return RefreshAuthKeyResult.success;
    } on InvalidTokenException catch (e, st) {
      // Provider не смог дать рабочий токен (его accessToken протух
      // и refresh у себя тоже не помог). Сессия мертва, host-app должен
      // показать login.
      //
      // **TASK20 followup (b)**: до этого изменения мы оставляли запись
      // в store-е — следующий cold start подтянул бы мёртвый sessionToken
      // и попал бы в тот же 401-loop. Чистим явно, потому что попали
      // в типизированный auth-error (НЕ network / 5xx).
      await _clearSessionOnUnauthorized();
      _errorReporter?.reportError(
        e,
        st,
        tags: {'phase': 'session.refresh', 'class': 'InvalidTokenException'},
      );
      _emitState(MessengerSessionState.expired);
      return RefreshAuthKeyResult.failedUnauthorized;
    } on MessengerNotAuthenticatedException catch (e, st) {
      // Текущий sessionToken тоже отвергнут на этапе refresh — это
      // означает, что и старый, и попытка нового не удались. Тоже
      // expired. **TASK20 followup (b)**: clear store, см. комментарий
      // в InvalidTokenException-ветке выше.
      await _clearSessionOnUnauthorized();
      _errorReporter?.reportError(
        e,
        st,
        tags: {'phase': 'session.refresh', 'class': 'MessengerNotAuth'},
      );
      _emitState(MessengerSessionState.expired);
      return RefreshAuthKeyResult.failedUnauthorized;
    } catch (e, st) {
      // Сеть, 5xx, etc. Не expired — состояние «ошибка», host-app может
      // повторить через `reauthenticate()`. Текущий session-токен
      // оставляем (вдруг ещё работает); proactive timer не
      // переустанавливаем (был сброшен в начале _scheduleRefresh).
      _errorReporter?.reportError(
        e,
        st,
        tags: {'phase': 'session.refresh', 'class': e.runtimeType.toString()},
      );
      _emitState(MessengerSessionState.error);
      return RefreshAuthKeyResult.failedOther;
    }
  }

  /// **TASK20 followup (b)**: на типизированном auth-исключении
  /// (`InvalidTokenException` / `MessengerNotAuthenticatedException`)
  /// мы обязаны полностью обнулить локальное состояние сессии:
  ///
  ///   1. `_authKeyProvider.setToken(null)` — следующие RPC уйдут БЕЗ
  ///      `Authorization` header-а (Serverpod вернёт чистый 401, host-app
  ///      увидит `MessengerSessionState.expired` через emitState).
  ///   2. `_store.clear()` — следующий cold start не подтянет мёртвый
  ///      `sessionToken` из secure storage. Без этого reboot приложения
  ///      продолжил бы 401-loop, пока host-app явно не позовёт
  ///      `reauthenticate()`.
  ///   3. `_refreshTimer?.cancel()` — проактивный таймер на мёртвой
  ///      сессии бессмысленен; нечего рефрешить.
  ///
  /// **CRITICAL**: метод приватный и зовётся ТОЛЬКО из веток, поймавших
  /// **типизированное** auth-исключение. Никогда из generic catch-а
  /// `_refreshAuthKey()` (там сеть/5xx — токен жив, чистить НЕЛЬЗЯ).
  ///
  /// Best-effort на errors внутри `_store.clear()` — пишем в errorReporter,
  /// но не пробрасываем (исходное auth-исключение важнее, чем секондари
  /// ошибка хранилища).
  Future<void> _clearSessionOnUnauthorized() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _session = null;
    _authKeyProvider.setToken(null);
    try {
      await _store.clear();
    } catch (e, st) {
      _errorReporter?.reportError(
        e,
        st,
        tags: {
          'phase': 'session.clearOnUnauthorized',
          'class': e.runtimeType.toString(),
        },
      );
    }
  }

  /// **TASK20 followup (b)**: silently refresh the session token after
  /// server-side invalidation (server revoke, password change, manual
  /// session expire). Returns the new `sessionToken` on success.
  ///
  /// **Trigger contract** — caller MUST verify the failure is a TRUE
  /// auth invalidation BEFORE calling this. Specifically:
  ///   * HTTP 401 surfaced as `ServerpodClientUnauthorized` (already
  ///     handled by Serverpod's `MutexRefresherClientAuthKeyProvider` via
  ///     [refreshAuthKey] — this path doesn't need [selfHealStaleToken]);
  ///   * Typed `MessengerNotAuthenticatedException` from any endpoint
  ///     (delivered as a serialized exception, NOT 401 — Serverpod does
  ///     NOT auto-retry → [withAuthRetry] catches it and calls us).
  ///
  /// MUST NOT be called on: `TimeoutException`, `SocketException`,
  /// `HandshakeException`, HTTP 5xx, HTTP 403, generic `Exception`. See
  /// `isAuthInvalidation()` in `auth_retry.dart`.
  ///
  /// **Behavior**:
  ///   1. If a self-heal is already in flight (`_selfHealInProgress`
  ///      non-null) — await that one (single-flight). N concurrent
  ///      failing RPCs → 1 refresh.
  ///   2. If init() is still in progress — await it; на тот момент
  ///      session, скорее всего, уже валидна и retry успешен.
  ///   3. Otherwise: forward to [_refreshAuthKey] with `force: true`.
  ///      Manager re-fetches `MessengerAuthContext` via provider, дёргает
  ///      `refresh(ctx)` RPC, обновляет токен в auth-key provider-е и
  ///      store-е, эмитит `active`.
  ///   4. On `_refreshAuthKey` failure with `failedUnauthorized` —
  ///      session уже почищена в `_clearSessionOnUnauthorized()`,
  ///      state == `expired`, мы throw-аем → caller в `withAuthRetry`
  ///      пробрасывает auth-исключение → host-app's login UI.
  ///   5. On `_refreshAuthKey` failure с `failedOther` (network/5xx) —
  ///      throw, host-app получит исходное auth-исключение от первого
  ///      RPC-вызова. Token cache не трогаем (см. red-line constraint).
  ///
  /// Возвращает текущий sessionToken после refresh-а (для тестов и
  /// metrics). На failure throw-ит исходное исключение из refresh-а.
  Future<String?> selfHealStaleToken() async {
    if (_disposed) {
      throw StateError(
        'selfHealStaleToken() called on disposed MessengerSessionManager.',
      );
    }

    // Single-flight: N concurrent failing RPCs → 1 refresh.
    final inFlight = _selfHealInProgress;
    if (inFlight != null) {
      return inFlight.future;
    }

    // If init is still running, that's effectively a fresh session —
    // wait for it, the resulting token will likely satisfy the caller's
    // retry. (init owns its own _initInProgress Completer.)
    final initInProgress = _initInProgress;
    if (initInProgress != null && !initInProgress.isCompleted) {
      try {
        await initInProgress.future;
      } catch (_) {
        // init failed → no point self-healing; propagate the auth-error
        // upward via rethrow on the caller.
        throw StateError(
          'selfHealStaleToken: init() failed, cannot refresh stale token.',
        );
      }
      return _session?.sessionToken;
    }

    // Single-flight: первый caller создаёт Completer, остальные
    // дождутся его future в early-return сверху. Внутренняя логика
    // — в [_doSelfHeal]; результаты / ошибки маршалятся в Completer
    // и тем же временем return-ятся / throw-ятся текущему caller-у.
    final completer = Completer<String?>();
    _selfHealInProgress = completer;
    // **Важно**: подписываемся на `.catchError(noop)` ЗАРАНЕЕ, чтобы
    // ошибка в Completer-е не была "unhandled" в случае, если
    // concurrent listener-ов НЕТ (только один caller, который сам
    // обрабатывает rethrow через try/catch в withAuthRetry).
    completer.future.catchError((Object _) => null);
    try {
      final token = await _doSelfHeal();
      completer.complete(token);
      return token;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      if (identical(_selfHealInProgress, completer)) {
        _selfHealInProgress = null;
      }
    }
  }

  /// Реальная логика self-heal: вызывает [_refreshAuthKey] и
  /// маппит результат на token / throw. Single-flight-обёртка —
  /// в [selfHealStaleToken].
  Future<String?> _doSelfHeal() async {
    final result = await _refreshAuthKey(force: true);
    switch (result) {
      case RefreshAuthKeyResult.success:
      case RefreshAuthKeyResult.skipped:
        // skipped возможен, если concurrent proactive refresh уже
        // обновил токен — текущий _session.sessionToken свежий.
        return _session?.sessionToken;
      case RefreshAuthKeyResult.failedUnauthorized:
        // session уже почищена в `_clearSessionOnUnauthorized()` из
        // `_refreshAuthKey()`. Throw, чтобы caller в `withAuthRetry`
        // не делал retry (мёртвый токен, retry бессмыслен).
        throw StateError(
          'selfHealStaleToken: refresh failed unauthorized — '
          'session cleared, host-app should show login.',
        );
      case RefreshAuthKeyResult.failedOther:
        // Сеть / 5xx во время refresh. Токен НЕ чистим (см.
        // red-line). Caller пробрасывает исходное auth-исключение
        // выше; на следующем юзер-action retry попробует ещё раз.
        throw StateError(
          'selfHealStaleToken: refresh failed (network/5xx) — '
          'token cache preserved.',
        );
    }
  }

  /// Test-only: симулирует in-flight self-heal на момент check-а в
  /// concurrent тесте.
  @visibleForTesting
  bool get hasSelfHealInFlightForTest => _selfHealInProgress != null;

  void _scheduleRefresh(DateTime expiresAt) {
    _refreshTimer?.cancel();
    if (_disposed) return;
    final now = DateTime.now().toUtc();
    final fireAt = expiresAt.subtract(_refreshLeadTime);
    final delay = fireAt.isAfter(now)
        ? fireAt.difference(now)
        : _minRefreshDelay;
    _refreshTimer = Timer(delay, () async {
      // proactive — force=false; mutex-decorator отдаст skipped, если
      // ещё рано (на случай коротких expiresAt + clock skew).
      await _refreshAuthKey(force: true);
    });
  }
}
