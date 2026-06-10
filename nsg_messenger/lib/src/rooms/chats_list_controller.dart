import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_session_state.dart';
import 'chats_list_state.dart';
import 'nsg_messenger_rooms.dart';

/// TASK42 Chunk 2: tab фильтр в `ChatsListScreen`. Single source of
/// truth — этот enum в [ChatsListController]. `AppBar` overflow меню
/// переключает.
///
///   * `active` (default) — server-side `includeArchived=false`. Юзер
///     видит свои нормальные чаты, archived скрыты.
///   * `archived` — server возвращает все, SDK post-filter `r.archived`.
///   * `all` — server возвращает все, без post-filter (debug / power-user).
enum ChatsListFilter { active, archived, all }

/// `ChangeNotifier` поверх [NsgMessengerRooms] + [MessengerEventBus]
/// для UI чат-листа. Состояние через sealed [ChatsListState] (Loading
/// / Ready / Error). Tests подменяют RPC через mock `NsgMessengerRooms`
/// + StreamControllers для events/sessionStates.
///
/// Контракт `lastKnown` (см. ревью 8985cce #3): на любой refresh —
/// если предыдущее состояние было `ChatsListReady`, то ВО ВРЕМЯ нового
/// запроса state остаётся `Ready(rooms=lastKnown, refreshing=true)`.
/// На success → `Ready(newRooms, refreshing=false)`. На failure →
/// `Error(lastKnown=lastKnown)` (UI показывает старый список + error
/// banner). Никаких pure-spinner-ов после первого успеха.
///
/// `loadMore()` — точка подсадки для cursor pagination в TASK42. На
/// TASK14 no-op; UI может звать безопасно. См. `NsgMessengerRooms.list`
/// — cursor уже в API, для TASK42 этого hook-а достаточно.
///
/// **Lifecycle**: вызвать `init()` после конструирования; `dispose()`
/// при удалении (стандартный `ChangeNotifier.dispose`). Двойной
/// `init()` — no-op.
class ChatsListController extends ChangeNotifier {
  final NsgMessengerRooms _rooms;
  final Stream<MessengerEvent> _events;
  final Stream<MessengerSessionState> _sessionStates;

  StreamSubscription<MessengerEvent>? _eventsSub;
  StreamSubscription<MessengerSessionState>? _stateSub;

  ChatsListState _state = const ChatsListLoading();
  bool _initialized = false;
  bool _disposed = false;
  ChatsListFilter _filter = ChatsListFilter.active;

  /// Текущий search query (TASK42 Chunk 3). `null` или пустая (после
  /// trim) — без search-параметра в RPC. Меняется через [setSearch];
  /// 300ms debounce timer внутри [setSearch] откладывает фактический
  /// refresh, чтобы typeahead не плодил RPC.
  String? _search;
  Timer? _searchDebounce;

  /// Длительность debounce между нажатиями клавиш search input-а.
  /// 300ms — баланс между responsiveness (юзер ждёт результат) и
  /// нагрузкой на server (typeahead 5 chars в 1 sec при 100ms = 5
  /// RPC; при 300ms = 1 RPC). Совпадает с TASK18 markRead pattern.
  @visibleForTesting
  static const Duration kSearchDebounce = Duration(milliseconds: 300);

  /// TASK42 Chunk 3: product filter (`null` — все products видимы;
  /// иначе — server-side `productId` фильтр). Меняется через
  /// [setProductFilter] — instant refresh без debounce (user click).
  int? _productFilter;

  /// Cached список products где у viewer есть >=1 RoomMembership;
  /// загружается ленивно через [loadAvailableProducts]. UI рендерит
  /// dropdown только когда `availableProducts != null && length > 1
  /// && mode == standalone` (см. TASK42 plan Q4).
  List<Product>? _availableProducts;
  bool _availableProductsLoading = false;

  /// Защита от concurrent refresh — если в полёте уже запрос, новый
  /// event-trigger игнорируется. После завершения текущего, если в
  /// промежутке успели invalidate-нуть, будет ещё один. Простая
  /// дебаунсинг-стратегия без timer-ов.
  bool _refreshInFlight = false;
  bool _pendingRefresh = false;

  /// Force-флаг для следующего refresh-цикла. Если `refresh(force=true)`
  /// зовётся во время in-flight refresh-а, мы НЕ инвалидируем cache
  /// сейчас (текущий уже взял snapshot до invalidate-а; в момент когда
  /// он завершится, его результат как раз наполнит cache → pending
  /// hit-ит этот свежий cache). Вместо этого ставим flag, который
  /// `_runRefresh` обработает в начале следующего цикла. Закрывает
  /// b89bfd9 #1.
  bool _pendingForceInvalidate = false;

  /// Waiters на idle-состояние (`!_refreshInFlight && !_pendingRefresh`).
  /// Используется в `refresh()` для pull-to-refresh: возвращаемый Future
  /// ждёт **всю цепочку** (текущий refresh + все pending), не только
  /// ближайший. Закрывает 8985cce/b89bfd9 #1: pull-to-refresh во время
  /// фонового refresh-а больше не возвращает Future рано — UI
  /// `RefreshIndicator` крутит spinner до фактического свежего фрейма.
  final List<Completer<void>> _idleWaiters = [];

  ChatsListController({
    required NsgMessengerRooms rooms,
    required Stream<MessengerEvent> events,
    required Stream<MessengerSessionState> sessionStates,
  }) : _rooms = rooms,
       _events = events,
       _sessionStates = sessionStates;

  ChatsListState get state => _state;

  /// Текущий tab-фильтр. Установка через [setFilter] — SDK при смене
  /// инвалидирует list cache (params changed) и триггерит refresh.
  ChatsListFilter get filter => _filter;

  /// Сменить tab. No-op если совпадает с текущим. Иначе — invalidate
  /// + refresh; UI перерисовывается через `notifyListeners`.
  void setFilter(ChatsListFilter f) {
    if (_disposed || f == _filter) return;
    _filter = f;
    _rooms.invalidate();
    _scheduleRefresh();
    notifyListeners(); // UI обновит overflow-индикатор сразу.
  }

  /// Текущий search query (TASK42 Chunk 3). `null` или пустая = без
  /// фильтра.
  String? get search => _search;

  /// Текущий product filter (`null` = все products).
  int? get productFilter => _productFilter;

  /// Cached available products. `null` пока не загружено; пустой
  /// список — viewer без any RoomMembership-ей. UI смотрит size
  /// чтобы решить рендерить dropdown или нет.
  List<Product>? get availableProducts => _availableProducts;

  /// Установить search query с 300ms debounce. Каждый вызов сбрасывает
  /// предыдущий timer. Пустая строка (после trim) → `null` (UI clear
  /// button). Same-value не триггерит refresh (idempotent typeahead-
  /// repaint).
  void setSearch(String? raw) {
    if (_disposed) return;
    final normalized = (raw == null || raw.trim().isEmpty) ? null : raw.trim();
    if (normalized == _search) return;
    _search = normalized;
    notifyListeners(); // UI input-а: обновить clear-button visibility.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(kSearchDebounce, () {
      if (_disposed) return;
      _rooms.invalidate();
      _scheduleRefresh();
    });
  }

  /// Сменить product filter. Без debounce — это click, не typeahead.
  /// `null` → все products.
  void setProductFilter(int? productId) {
    if (_disposed || productId == _productFilter) return;
    _productFilter = productId;
    _rooms.invalidate();
    _scheduleRefresh();
    notifyListeners();
  }

  /// Лениво загрузить список Product-ов в которых у viewer есть
  /// >=1 RoomMembership. Идемпотентно — повторный вызов no-op (cached).
  /// UI вызывает в `initState` для standalone mode-а; embed-mode
  /// обычно single-product, dropdown скрыт.
  Future<void> loadAvailableProducts() async {
    if (_disposed) return;
    if (_availableProducts != null || _availableProductsLoading) return;
    _availableProductsLoading = true;
    try {
      final list = await _rooms.availableProducts();
      if (_disposed) return;
      _availableProducts = list;
      notifyListeners();
    } catch (e) {
      // Silent fail — dropdown просто не появится. Server недоступен →
      // юзер увидит generic «Failed to load chats» через _runRefresh.
      if (kDebugMode) {
        debugPrint('[ChatsListController] loadAvailableProducts failed: $e');
      }
    } finally {
      _availableProductsLoading = false;
    }
  }

  /// Test-only: число фактических вызовов `_runRefresh` (для проверки
  /// debouncing — отдельно от `_listRpc.calls`, потому что cache hit
  /// маскирует количество RPC).
  @visibleForTesting
  int get debugRefreshInvocations => _refreshInvocations;
  int _refreshInvocations = 0;

  /// Подписаться на event-bus + session-state и сделать первый fetch.
  /// Идемпотентен — повторный вызов no-op.
  void init() {
    if (_initialized || _disposed) return;
    _initialized = true;
    _eventsSub = _events.listen(
      (_) => _scheduleRefresh(),
      onError: (Object e) {
        // Underlying event stream errored — list state не трогаем
        // (последний known list ещё актуален); SDK сам обработает
        // session-state переход на expired/error.
        if (kDebugMode) {
          debugPrint('[ChatsListController] event stream error: $e');
        }
      },
    );
    _stateSub = _sessionStates.listen(_onSessionState);
    unawaited(_runRefresh());
  }

  /// Manual refresh — pull-to-refresh из UI. `force=true` инвалидирует
  /// SDK-cache перед запросом (полный roundtrip к серверу).
  ///
  /// Возвращаемый Future завершается, когда **вся** refresh-цепочка
  /// (текущий in-flight + все pending) идёт в idle. Это даёт корректный
  /// UX для `RefreshIndicator.onRefresh`:
  ///   * если refresh уже шёл — pending-refresh подтянет свежее после
  ///     `invalidate()` и spinner крутится до фактического fresh-фрейма;
  ///   * без force — просто ждёт текущую цепочку (бессмысленно крутить
  ///     дольше).
  ///
  /// Внутри [_runRefresh] нет early return для `await refresh()` —
  /// он всегда ждёт `_waitForIdle`.
  Future<void> refresh({bool force = false}) async {
    if (_disposed) return;
    if (force) {
      if (_refreshInFlight) {
        // Не инвалидируем cache сейчас: текущий refresh уже взял
        // старый snapshot, его результат наполнит cache. Если бы мы
        // инвалидировали сейчас, pending refresh вызвал бы list() и
        // hit-нул только-что-наполненный cache. Откладываем
        // invalidate на начало следующего refresh-цикла.
        _pendingForceInvalidate = true;
        _pendingRefresh = true;
      } else {
        _rooms.invalidate();
        unawaited(_runRefresh());
      }
    } else {
      if (_refreshInFlight) {
        _pendingRefresh = true;
      } else {
        unawaited(_runRefresh());
      }
    }
    await _waitForIdle();
  }

  /// **TASK42**: подгрузка следующей страницы через
  /// `NsgMessengerRooms.list(cursor: _nextCursor)`. На TASK14 — no-op.
  /// UI может звать безопасно (silent return); закладывает API контракт
  /// чтобы TASK42 не менял интерфейс контроллера.
  Future<void> loadMore() async {
    return;
  }

  // ─── TASK42 Chunk 2: optimistic mutations ──────────────────────────
  //
  // UX: tap action → UI обновляется мгновенно (state copy с toggled
  // флагом / удалённой row), параллельно идёт RPC. Server-confirm
  // прилетит через event-bus → eventual `_runRefresh` → final state
  // (та же или другая, если server-side validation поменял что-то).
  // Если RPC падает — revert к pre-action snapshot + rethrow для UI
  // snackbar.

  Future<void> muteRoom(int roomId, {Duration? duration}) async {
    if (_disposed) return;
    final mutedUntil = duration == null
        ? kMuteForever
        : DateTime.now().toUtc().add(duration);
    await _withOptimistic(
      roomId: roomId,
      mutate: (r) => r.copyWith(muted: true),
      removeFromList: false,
      rpc: () => _rooms.muteRoom(roomId: roomId, mutedUntil: mutedUntil),
    );
  }

  Future<void> unmuteRoom(int roomId) => _withOptimistic(
    roomId: roomId,
    mutate: (r) => r.copyWith(muted: false),
    removeFromList: false,
    rpc: () => _rooms.unmuteRoom(roomId),
  );

  Future<void> archiveRoom(int roomId) => _withOptimistic(
    roomId: roomId,
    mutate: (r) => r.copyWith(archived: true),
    // На «active» tab archived room должен исчезнуть из visible list-а;
    // на «archived» / «all» — остаётся, mutate-нутый. UI это решает по
    // текущему filter-у.
    removeFromList: _filter == ChatsListFilter.active,
    rpc: () => _rooms.archiveRoom(roomId),
  );

  Future<void> unarchiveRoom(int roomId) => _withOptimistic(
    roomId: roomId,
    mutate: (r) => r.copyWith(archived: false),
    // На «archived» tab unarchive → исчезает из visible. На «active»
    // tab — its RoomSummary not present (since archived). На «all» —
    // остаётся mutate-нутый.
    removeFromList: _filter == ChatsListFilter.archived,
    rpc: () => _rooms.unarchiveRoom(roomId),
  );

  Future<void> leaveRoom(int roomId) => _withOptimistic(
    roomId: roomId,
    removeFromList: true,
    rpc: () => _rooms.leaveRoom(roomId),
  );

  /// Общий помощник для optimistic update + revert. Передайте либо
  /// [mutate] (transform RoomSummary), либо [removeFromList: true]
  /// (удалить row). При [removeFromList: true] [mutate] игнорируется
  /// (можно опустить). RPC error → revert к pre-action snapshot +
  /// rethrow.
  Future<void> _withOptimistic({
    required int roomId,
    RoomSummary Function(RoomSummary)? mutate,
    bool removeFromList = false,
    required Future<void> Function() rpc,
  }) async {
    assert(
      removeFromList || mutate != null,
      '_withOptimistic: либо mutate, либо removeFromList=true',
    );
    final snapshot = _state;
    if (snapshot is! ChatsListReady) {
      // No-op если state не Ready (Loading или Error без lastKnown);
      // RPC по логике не должен зваться UI-ом в этом стейте.
      return;
    }
    final List<RoomSummary> updated;
    if (removeFromList) {
      updated = snapshot.rooms
          .where((r) => r.id != roomId)
          .toList(growable: false);
    } else {
      // mutate non-null проверен assert-ом выше.
      updated = snapshot.rooms
          .map((r) => r.id == roomId ? mutate!(r) : r)
          .toList(growable: false);
    }
    _emit(ChatsListReady(rooms: updated, refreshing: snapshot.refreshing));
    try {
      await rpc();
    } catch (e) {
      if (_disposed) return;
      // Revert. Server-confirm event никогда не придёт (RPC failed);
      // никаких extra refresh-ей не надо.
      _emit(snapshot);
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _eventsSub?.cancel();
    _eventsSub = null;
    _stateSub?.cancel();
    _stateSub = null;
    _searchDebounce?.cancel();
    _searchDebounce = null;
    // Будим всех, кто await-ил `refresh()` — иначе UI висит со
    // spinner-ом, пока widget tree не размонтирован.
    _wakeIdleWaiters();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────

  void _onSessionState(MessengerSessionState s) {
    if (_disposed) return;
    // expired — сессия мертва, host-app должен показать login. List
    // не трогаем (последний known рендерится; SDK на reauthenticate
    // → active эмитнет refreshing → active, и refresh случится через
    // event-bus / session-state branch ниже).
    // active — после refresh-а или первой авторизации; если есть
    // listeners на bus, он переподписался, новые events придут. На
    // случай переходного периода также делаем явный refresh — кэш
    // мог инвалидироваться по логике backend-а.
    if (s == MessengerSessionState.active) {
      _scheduleRefresh();
    }
  }

  /// Дебаунсинг: если refresh уже в полёте, помечаем pending.
  /// После завершения текущего — выполнится pending. Никаких
  /// concurrent in-flight requests, никаких timer-ов.
  void _scheduleRefresh() {
    if (_disposed) return;
    if (_refreshInFlight) {
      _pendingRefresh = true;
      return;
    }
    unawaited(_runRefresh());
  }

  Future<void> _runRefresh() async {
    if (_disposed) return;
    if (_refreshInFlight) {
      _pendingRefresh = true;
      return;
    }
    _refreshInFlight = true;
    _refreshInvocations++;
    // Если предыдущий цикл оставил force-flag — применяем сейчас
    // (cache invalidate ровно перед list()), чтобы _rooms.list()
    // обязательно дёрнул сервер.
    if (_pendingForceInvalidate) {
      _pendingForceInvalidate = false;
      _rooms.invalidate();
    }

    // Transient state: если уже был Ready — переводим в Ready(refreshing=true).
    final current = _state;
    final lastKnown = switch (current) {
      ChatsListReady ready => ready.rooms,
      ChatsListError err => err.lastKnown,
      _ => null,
    };
    if (lastKnown != null && current is ChatsListReady && !current.refreshing) {
      _emit(ChatsListReady(rooms: lastKnown, refreshing: true));
    }

    try {
      // TASK42: server включает archived только если filter != active.
      // Для `archived` tab делаем post-filter `r.archived` локально —
      // server не имеет «archivedOnly» режима, только всё-или-нет.
      final includeArchived = _filter != ChatsListFilter.active;
      final raw = await _rooms.list(
        includeArchived: includeArchived,
        search: _search,
        productId: _productFilter,
      );
      if (_disposed) return;
      final fresh = switch (_filter) {
        ChatsListFilter.active => raw,
        ChatsListFilter.archived =>
          raw.where((r) => r.archived).toList(growable: false),
        ChatsListFilter.all => raw,
      };
      _emit(ChatsListReady(rooms: fresh, refreshing: false));
    } catch (e) {
      if (_disposed) return;
      _emit(ChatsListError(error: e, lastKnown: lastKnown));
    } finally {
      _refreshInFlight = false;
      if (_pendingRefresh && !_disposed) {
        _pendingRefresh = false;
        unawaited(_runRefresh());
      } else {
        // Цепочка пуста — будим всех, кто ждал в `refresh()`.
        _wakeIdleWaiters();
      }
    }
  }

  Future<void> _waitForIdle() {
    if (!_refreshInFlight && !_pendingRefresh) {
      return Future<void>.value();
    }
    final c = Completer<void>();
    _idleWaiters.add(c);
    return c.future;
  }

  void _wakeIdleWaiters() {
    final waiters = List<Completer<void>>.from(_idleWaiters);
    _idleWaiters.clear();
    for (final c in waiters) {
      if (!c.isCompleted) c.complete();
    }
  }

  void _emit(ChatsListState s) {
    _state = s;
    if (!_disposed) notifyListeners();
  }
}
