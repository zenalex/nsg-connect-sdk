import 'dart:async';
import 'dart:io' show SocketException, HandshakeException, HttpException;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'chat_message.dart';
import 'messages_rpc.dart';
import 'messages_state.dart';

/// **B10 (см. docs/BACKLOG.md)**: default-расписание retry-ов для
/// transient send-ошибок (network/timeout/5xx). 5 попыток с экспонентой
/// 1s/3s/10s/15s/30s — суммарно ~59 секунд под «pending» статусом,
/// после чего message переходит в `failed` (UI показывает retry-button).
///
/// Сравнение с industry:
///   * Telegram — бесконечная очередь (часики до отправки);
///   * WhatsApp — ~5 минут;
///   * Signal — ~3 минуты;
///   * CHATista — 1 минута (баланс между «не сломается на короткой
///     потере связи» и «пользователь увидит провал до того как уйдёт
///     с экрана»).
///
/// Permanent-ошибки (4xx, типизированные доменные exception-ы) НЕ
/// ретраятся — `_markFailed` сразу.
@visibleForTesting
const List<Duration> kDefaultSendRetrySchedule = [
  Duration(seconds: 1),
  Duration(seconds: 3),
  Duration(seconds: 10),
  Duration(seconds: 15),
  Duration(seconds: 30),
];

/// Default pending-buffer cap. См. doc у [MessagesController.pendingBufferCap].
@visibleForTesting
const int kDefaultPendingBufferCap = 100;

/// Default initial-page size. На MVP 50 совпадает с серверным
/// fallback-ом (TASK09).
@visibleForTesting
const int kDefaultInitialPageSize = 50;

/// Controller-обёртка над одной комнатой для ChatScreen (TASK15).
///
/// Ответственности:
///   * **History pagination** через [MessagesRpc.listMessages]
///     (backward-only, Matrix `dir=b`).
///   * **Realtime merge** — подписка на стрим [MessengerEvent]-ов;
///     события для своей `roomId` мержатся в state с двухслойной
///     дедупликацией:
///       1. **layer-1 (pending → real)** — match по `clientTxnId`
///          replace pending bubble на server-confirmed entry;
///       2. **layer-2 (real → real)** — match по `matrixEventId`,
///          skip если уже видели (защита от двойной доставки stream
///          + RPC-return).
///   * **Optimistic send** — pending bubble в state сразу при
///     `sendMessage()`, реальный RPC в фоне; promote pending → sent
///     при success или fail при exception.
///   * **Subscribe-before-fetch** — стрим подписан ДО первого
///     `listMessages`. Между ms-T1 (fetch fire) и ms-T2 (response
///     arrives) приходящие realtime-events буферятся в
///     `_initBuffer` и сливаются в финальный state с deduplicate-ами
///     по `matrixEventId`. Без этого паттерна events, прилетевшие в
///     этом окне, теряются (Matrix не пере-доставит — они уже
///     прошли nextBatch).
///
/// **Lifecycle:** один controller per ChatScreen. `init()` в
/// `initState`, `dispose()` в `dispose`. Глобального cache нет
/// (см. TASK15 план — closing chat = clear messages; persistent
/// pre-fetch появится в TASK20 push routing).
class MessagesController {
  MessagesController({
    required int roomId,
    required MessagesRpc rpc,
    required Stream<MessengerEvent> events,
    required int selfMessengerUserId,
    required String selfMatrixUserId,
    String Function()? clientTxnIdGenerator,
    int pendingBufferCap = kDefaultPendingBufferCap,
    int initialPageSize = kDefaultInitialPageSize,
    int loadMorePageSize = kDefaultInitialPageSize,
    void Function(Object error, StackTrace stack)? onSendError,
    List<Duration>? sendRetrySchedule,
  }) : _sendRetrySchedule = sendRetrySchedule ?? kDefaultSendRetrySchedule,
       assert(
         pendingBufferCap > 0,
         'pendingBufferCap must be > 0; cap=0 даёт бесконечный '
         'restart-storm в overflow path',
       ),
       assert(initialPageSize > 0, 'initialPageSize must be > 0'),
       assert(loadMorePageSize > 0, 'loadMorePageSize must be > 0'),
       _roomId = roomId,
       _rpc = rpc,
       _events = events,
       _selfMessengerUserId = selfMessengerUserId,
       _selfMatrixUserId = selfMatrixUserId,
       _txnIdGenerator = clientTxnIdGenerator ?? _defaultTxnIdGenerator,
       _pendingBufferCap = pendingBufferCap,
       _initialPageSize = initialPageSize,
       _loadMorePageSize = loadMorePageSize,
       _onSendError = onSendError;

  final int _roomId;
  final MessagesRpc _rpc;
  final Stream<MessengerEvent> _events;
  final int _selfMessengerUserId;
  final String _selfMatrixUserId;
  final String Function() _txnIdGenerator;
  final int _pendingBufferCap;
  final int _initialPageSize;
  final int _loadMorePageSize;
  final void Function(Object error, StackTrace stack)? _onSendError;
  final List<Duration> _sendRetrySchedule;

  final ValueNotifier<MessagesState> _state = ValueNotifier(
    const MessagesLoading(),
  );

  /// **B9 typing indicator**: set текущих печатающих peer-ов (matrix
  /// id-ы). Server-side фильтрует self, поэтому только peers.
  /// Pусто = никто не печатает → ChatScreen footer hidden.
  final ValueNotifier<Set<String>> _typingPeers = ValueNotifier(
    const <String>{},
  );
  ValueListenable<Set<String>> get typingPeersListenable => _typingPeers;
  Set<String> get typingPeers => _typingPeers.value;

  /// **B11 read receipts**: per-peer last-read marker —
  /// `matrixUserId → DateTime serverTimestamp`. Когда reader X прочитал
  /// событие со ts=T, любой message с serverTimestamp ≤ T считается
  /// прочитанным им. Используется в [readByPeerMatrixIds] для bubble
  /// UI.
  ///
  /// Matrix m.read семантика — «read UP TO this event», поэтому мы
  /// храним timestamp последнего прочитанного event-а (не set всех
  /// id-ов).
  final Map<String, DateTime> _peerLastReadAt = <String, DateTime>{};

  /// Версия `_peerLastReadAt`, инкрементируется при каждом обновлении.
  /// Используется для notify-а UI (ChangeNotifier-like через
  /// `_readReceiptsNotifier`).
  final ValueNotifier<int> _readReceiptsVersion = ValueNotifier(0);
  ValueListenable<int> get readReceiptsVersionListenable =>
      _readReceiptsVersion;

  /// **Emoji reactions**: агрегат реакций по сообщениям.
  /// `targetEventId → key → (set реакторов matrix-id)`. Count = размер
  /// set-а; `mine` = self среди реакторов. Set дедуплицирует двойную
  /// доставку (stream + RPC echo) и double-react того же юзера.
  final Map<String, Map<String, Set<String>>> _reactionsByTarget =
      <String, Map<String, Set<String>>>{};

  /// **Emoji reactions**: reverse-индекс `reactionEventId →
  /// (targetEventId, key, reactorMatrixId)`. Нужен для redaction
  /// (toggle-off): redaction event знает только reactionEventId, по
  /// нему находим что декрементить. Также хранит my reaction-event-id
  /// для каждого (target,key) — через поиск по reactor==self.
  final Map<String, _ReactionRef> _reactionRefById = <String, _ReactionRef>{};

  /// **Emoji reactions**: версия агрегата — bump на каждое изменение,
  /// триггерит UI rebuild (паттерн `_readReceiptsVersion`).
  final ValueNotifier<int> _reactionsVersion = ValueNotifier(0);
  ValueListenable<int> get reactionsVersionListenable => _reactionsVersion;

  /// **Emoji reactions**: агрегированные группы реакций для сообщения
  /// `matrixEventId` (для рендеринга чипов под bubble). Пустой list —
  /// нет реакций. Стабильный порядок: по первому появлению ключа
  /// (insertion order Map-а).
  List<ReactionGroup> reactionsFor(String matrixEventId) {
    final byKey = _reactionsByTarget[matrixEventId];
    if (byKey == null || byKey.isEmpty) return const <ReactionGroup>[];
    final result = <ReactionGroup>[];
    for (final entry in byKey.entries) {
      if (entry.value.isEmpty) continue;
      result.add(
        ReactionGroup(
          key: entry.key,
          count: entry.value.length,
          mine: entry.value.contains(_selfMatrixUserId),
        ),
      );
    }
    return result;
  }

  /// **TASK16-A**: target message текущего reply-draft-а в composer.
  /// `null` = composer без reply chip-а; non-null = composer показывает
  /// quote chip над TextField, send отправляет с
  /// `replyToMatrixEventId = replyTarget.matrixEventId`.
  ///
  /// Управляется через [setReplyTarget] / [clearReplyTarget]; после
  /// успешного send composer вызывает [clearReplyTarget].
  final ValueNotifier<ChatMessage?> _replyTarget = ValueNotifier(null);
  ValueListenable<ChatMessage?> get replyTargetListenable => _replyTarget;
  ChatMessage? get replyTarget => _replyTarget.value;

  /// Текущее значение state. Используется ChatScreen через
  /// `ValueListenableBuilder`.
  ValueListenable<MessagesState> get stateListenable => _state;
  MessagesState get state => _state.value;

  /// **TASK16-A**: lookup по `matrixEventId` для reply chip rendering.
  /// MessageBubble зовёт это, чтобы найти original message при
  /// рендеринге reply-quote. Cache miss (`null`) → bubble показывает
  /// placeholder text «Original message unavailable». Per Q1 — БЕЗ
  /// fetch+scroll-to-original в MVP.
  ChatMessage? findByEventId(String matrixEventId) {
    final current = _state.value;
    if (current is! MessagesReady) return null;
    for (final m in current.messages) {
      if (m.matrixEventId == matrixEventId) return m;
    }
    return null;
  }

  /// **TASK16-A**: установить reply-target для composer-а.
  /// Идемпотентно — переустанавливает на новое сообщение даже если
  /// уже set. Caller (action sheet → ChatScreen → controller).
  void setReplyTarget(ChatMessage target) {
    if (_disposed) return;
    _replyTarget.value = target;
  }

  /// **TASK16-A**: очистить reply-target. Зовётся из close-X в quote
  /// chip composer-а ИЛИ автоматически после успешного send.
  void clearReplyTarget() {
    if (_disposed) return;
    if (_replyTarget.value == null) return;
    _replyTarget.value = null;
  }

  /// `messengerUserId` владельца сессии, для которого создан controller.
  /// ChatScreen использует для own/peer discriminator-а в bubble layout.
  int get selfMessengerUserId => _selfMessengerUserId;

  /// **B12 (BACKLOG)**: последнее собственное **отправленное** сообщение
  /// в текущем chat-history. Используется composer-ом для Telegram-
  /// style ↑-arrow edit-shortcut (если поле пустое и юзер жмёт ↑ —
  /// переключаемся в edit-mode на это сообщение).
  ///
  /// Фильтрует:
  ///   * Pending / Failed (нет stable matrixEventId, edit недоступен);
  ///   * Tombstone (deletedAt != null) — нечего edit-ить;
  ///   * Чужие сообщения (`senderMessengerUserId != self`).
  ///
  /// Возвращает `null` если ничего своего sent в текущей загруженной
  /// истории (могут быть сообщения старше пагинации — Phase2 можно
  /// делать loadMore + retry).
  ChatMessage? get lastOwnSentMessage {
    final current = _state.value;
    if (current is! MessagesReady) return null;
    for (final m in current.messages) {
      if (m.senderMessengerUserId != _selfMessengerUserId) continue;
      if (!m.isSent) continue;
      if (m.isDeleted) continue;
      if (m.matrixEventId == null) continue;
      return m;
    }
    return null;
  }

  /// Matrix `@user:server` self — для отладки и для test-доступа.
  String get selfMatrixUserId => _selfMatrixUserId;

  /// **B17 search**: keyword-поиск в этой комнате через Matrix /search.
  /// Возвращает `List&lt;ChatMessage&gt;` (server возвращает
  /// MessengerMessage, конвертируем в ChatMessage для UI).
  ///
  /// Empty/short query → пустой list. Errors — propagate (host UI
  /// показывает snackbar).
  Future<List<ChatMessage>> searchMessages(String query) async {
    if (query.trim().length < 2) return const <ChatMessage>[];
    final results = await _rpc.searchMessages(
      roomId: _roomId,
      query: query,
      limit: 50,
    );
    return results.map(ChatMessage.fromServer).toList();
  }

  /// **B9 typing indicator**: уведомить peer-ов что юзер печатает /
  /// перестал. Best-effort — errors не propagate (typing — не
  /// критичная операция). Composer вызывает этот метод с debounce
  /// (см. `MessageComposer.onTyping`).
  Future<void> sendTyping(bool typing) async {
    if (kDebugMode) {
      debugPrint(
        '[MessagesController.room=$_roomId] sendTyping($typing) → RPC',
      );
    }
    try {
      await _rpc.sendTyping(roomId: _roomId, typing: typing);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MessagesController.room=$_roomId] sendTyping($typing) '
          'failed: $e (best-effort, ignored)',
        );
      }
    }
  }

  /// **Emoji reactions**: toggle своей реакции `key` на сообщение
  /// `targetEventId`. Если у меня уже есть эта реакция — снимаем
  /// (`removeReaction` по сохранённому reactionEventId), иначе ставим
  /// (`sendReaction`). Optimistic-free: realtime sync быстрый, и
  /// агрегат обновится при приходе `reactionChanged` event-а. Errors
  /// глотаются (best-effort, как typing) — если send упал, реакция
  /// просто не появится.
  Future<void> toggleReaction(String targetEventId, String key) async {
    if (_disposed) return;
    // Ищем свой reaction-event-id для этого (target,key).
    final myEventId = _myReactionEventId(targetEventId, key);
    try {
      if (myEventId != null) {
        await _rpc.removeReaction(roomId: _roomId, reactionEventId: myEventId);
      } else {
        await _rpc.sendReaction(
          roomId: _roomId,
          targetEventId: targetEventId,
          key: key,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MessagesController.room=$_roomId] toggleReaction($targetEventId, '
          '$key) failed: $e (best-effort, ignored)',
        );
      }
    }
  }

  /// Возвращает matrixEventId моего `m.reaction` event-а для
  /// (target,key), если я реагировал — иначе null.
  String? _myReactionEventId(String targetEventId, String key) {
    for (final entry in _reactionRefById.entries) {
      final ref = entry.value;
      if (ref.targetEventId == targetEventId &&
          ref.key == key &&
          ref.reactorMatrixId == _selfMatrixUserId) {
        return entry.key;
      }
    }
    return null;
  }

  /// **B11 read receipts**: список matrix id-ов peer-ов, которые
  /// прочитали (или прочитали что-то позже) данное сообщение.
  ///
  /// Bubble UI использует `.isNotEmpty` для переключения иконки на
  /// «прочитано» (две синие галочки). Размер списка — для group chat
  /// label вроде «прочитано 3».
  ///
  /// Self НЕ включается (сервер фильтрует ephemeral.m.receipt от self;
  /// если попадёт — `selfMatrixUserId` excluded ниже).
  Set<String> readByPeerMatrixIds(ChatMessage message) {
    if (_peerLastReadAt.isEmpty) return const <String>{};
    final ts = message.serverTimestamp;
    final result = <String>{};
    for (final entry in _peerLastReadAt.entries) {
      if (entry.key == _selfMatrixUserId) continue;
      // peer прочитал до timestamp ≥ ts → marked read.
      if (!entry.value.isBefore(ts)) {
        result.add(entry.key);
      }
    }
    return result;
  }

  /// **TASK19 Chunk 3**: thumbnail RPC pass-through для `MessageBubble`
  /// → `MxcImageProvider`. Bubble не знает про `MessagesRpc`, получает
  /// closure напрямую из controller-а — clean separation.
  Future<AttachmentBytes> downloadThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => _rpc.downloadAttachmentThumbnail(
    mxcUrl: mxcUrl,
    width: width,
    height: height,
  );

  /// **TASK19 Chunk 3**: full-size download для tap-fullscreen viewer.
  Future<AttachmentBytes> downloadFullSize({required String mxcUrl}) =>
      _rpc.downloadAttachment(mxcUrl: mxcUrl);

  /// Эпоха текущего init() — увеличивается при каждом restart.
  /// Async-операция проверяет epoch ПОСЛЕ await: если изменилось —
  /// её результат игнорируется. Нужен для overflow-restart-init
  /// (когда _initBuffer переполняется).
  int _initEpoch = 0;

  /// Опциональный буфер для events, прилетевших ДО завершения init().
  /// Создаётся в init() в самом начале, очищается при переходе в
  /// Ready. Если `null` — мы уже Ready и события идут в state напрямую.
  List<MessengerMessage>? _initBuffer;

  /// Token для следующего `loadMore`. `null` если history closed
  /// или ещё не были в Ready.
  String? _nextToken;

  /// Subscription на event stream. Создаётся ОДНОКРАТНО в первом
  /// init() (subscribe-before-fetch), переживает rest-init-ы.
  StreamSubscription<MessengerEvent>? _eventsSub;

  /// `true` после `dispose()`. Все async-handlers проверяют это
  /// после `await` чтобы не emit-ить state.
  bool _disposed = false;

  /// Гард против concurrent `loadMore()`-вызовов: второй concurrent
  /// вызов silent return-ится. То же самое поведение что в
  /// `MessengerSessionManager` для refresh.
  bool _loadingMore = false;

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Запустить controller: subscribe на events + загрузить первую
  /// страницу истории. Идемпотентен относительно повторных вызовов
  /// (используется во внутреннем restart-on-overflow); host-app обычно
  /// зовёт один раз в `initState`.
  Future<void> init() async {
    if (_disposed) return;
    final epoch = ++_initEpoch;
    _state.value = const MessagesLoading();
    _initBuffer = <MessengerMessage>[];

    // Subscribe-first (только при первом init — sub переживает restart).
    //
    // **Важно**: фильтр только по `roomId`, БЕЗ `e.message != null`.
    // Ephemeral events (B9 typingChanged + B11 readReceiptUpdated)
    // приходят с `message=null` — старый фильтр их резал. `_onEvent`
    // сам разруливает type-switch и no-op-ит для нерелевантных
    // events (membership / unread / state changes — те обрабатываются
    // в NsgMessengerRooms).
    _eventsSub ??= _events.where((e) => e.roomId == _roomId).listen(_onEvent);

    final MessengerMessageListPage page;
    try {
      page = await _rpc.listMessages(roomId: _roomId, limit: _initialPageSize);
    } catch (e) {
      if (_disposed || epoch != _initEpoch) return;
      _initBuffer = null;
      _state.value = MessagesError(error: e, lastKnown: null);
      return;
    }

    if (_disposed || epoch != _initEpoch) return;

    // Build initial messages list, applying buffered events (subscribe-
    // before-fetch race).
    final messages = page.messages.map(ChatMessage.fromServer).toList();
    final buffered = _initBuffer ?? const <MessengerMessage>[];
    for (final m in buffered) {
      _acceptIncomingInto(messages, m);
    }
    _initBuffer = null;
    _nextToken = page.nextToken;

    _state.value = MessagesReady(
      messages: messages,
      hasMore: page.nextToken != null,
      paginating: false,
    );

    // **Reactions history (phase 2)**: подтянуть существующие реакции
    // для загруженной страницы, чтобы чипы были видны сразу при
    // открытии чата (а не только по realtime). Best-effort, unawaited —
    // не блокирует первый рендер.
    unawaited(_seedReactions(messages));

    // **Persistent read-receipts seed (B22)**: подтянуть persisted
    // read-pointer-ы peer-ов, чтобы ✓✓ были видны сразу при re-open чата
    // (раньше `_peerLastReadAt` volatile терялся при пересоздании
    // контроллера). Best-effort, unawaited — не блокирует первый рендер.
    unawaited(_seedReadReceipts());
  }

  /// Подгрузить страницу OLDER messages. No-op если:
  ///   * state ≠ Ready (нечего расширять);
  ///   * `hasMore == false`;
  ///   * другой `loadMore` уже идёт.
  Future<void> loadMore() async {
    if (_disposed) return;
    final current = _state.value;
    if (current is! MessagesReady) return;
    if (!current.hasMore) return;
    if (_loadingMore) return;
    _loadingMore = true;
    _state.value = current.copyWith(paginating: true);

    final MessengerMessageListPage page;
    try {
      page = await _rpc.listMessages(
        roomId: _roomId,
        fromToken: _nextToken,
        limit: _loadMorePageSize,
      );
    } catch (e) {
      _loadingMore = false;
      if (_disposed) return;
      // Возвращаемся в pre-paginate Ready + Error overlay.
      final after = _state.value;
      if (after is MessagesReady) {
        _state.value = MessagesError(
          error: e,
          lastKnown: after.copyWith(paginating: false),
        );
      } else {
        _state.value = MessagesError(error: e, lastKnown: null);
      }
      return;
    }

    _loadingMore = false;
    if (_disposed) return;
    final after = _state.value;
    if (after is! MessagesReady) return;

    // Append OLDER messages в конец списка (DESC: index 0 = newest;
    // page.messages — тоже DESC внутри страницы; поэтому просто
    // concat). Dedup на случай overlap (server вернул сообщение,
    // которое уже было в первой странице — не должно случаться, но
    // защищаемся).
    final merged = List<ChatMessage>.of(after.messages);
    final existingEventIds = {
      for (final m in merged)
        if (m.matrixEventId != null) m.matrixEventId!,
    };
    final newlyAdded = <ChatMessage>[];
    for (final raw in page.messages) {
      if (existingEventIds.contains(raw.matrixEventId)) continue;
      final cm = ChatMessage.fromServer(raw);
      merged.add(cm);
      newlyAdded.add(cm);
      existingEventIds.add(raw.matrixEventId);
    }
    _nextToken = page.nextToken;
    _state.value = after.copyWith(
      messages: merged,
      hasMore: page.nextToken != null,
      paginating: false,
    );

    // Reactions history (phase 2): seed реакции для свежеподгруженной
    // OLDER-страницы (best-effort, unawaited).
    unawaited(_seedReactions(newlyAdded));
  }

  /// **Reactions history (phase 2)**: тянет существующие реакции для
  /// `messages` (по их matrixEventId) и применяет их через тот же
  /// `_handleReactionChanged`, что и realtime. Best-effort — ошибки
  /// silent (реакции не критичны для chat-UX). Pending/failed bubble-ы
  /// (без matrixEventId) пропускаются.
  Future<void> _seedReactions(List<ChatMessage> messages) async {
    final ids = <String>[
      for (final m in messages)
        if (m.matrixEventId != null) m.matrixEventId!,
    ];
    if (ids.isEmpty) return;
    final List<MessengerEvent> events;
    try {
      events = await _rpc.listReactions(roomId: _roomId, eventIds: ids);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MessagesController.room=$_roomId] seedReactions failed: $e '
          '(best-effort, ignored)',
        );
      }
      return;
    }
    if (_disposed || events.isEmpty) return;
    for (final e in events) {
      _handleReactionChanged(e);
    }
  }

  /// **Persistent read-receipts seed (B22)**: тянет persisted
  /// read-pointer-ы участников комнаты (`listReadReceipts`) и применяет
  /// каждый через тот же [_applyReadReceipt], что и realtime. Best-effort
  /// — ошибки silent (✓✓ не критичны). Monotonic-guard в
  /// [_applyReadReceipt] гарантирует, что seed (потенциально старее) НЕ
  /// перетрёт более свежий realtime receipt, пришедший до завершения
  /// этого RPC.
  Future<void> _seedReadReceipts() async {
    final List<MessengerEvent> events;
    try {
      events = await _rpc.listReadReceipts(roomId: _roomId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MessagesController.room=$_roomId] seedReadReceipts failed: $e '
          '(best-effort, ignored)',
        );
      }
      return;
    }
    if (_disposed || events.isEmpty) return;
    for (final e in events) {
      _applyReadReceipt(e);
    }
  }

  /// **B11/B22 read receipts**: применить один `readReceiptUpdated`-event
  /// к per-peer last-read marker. Общий путь для realtime ([_onEvent]) и
  /// seed ([_seedReadReceipts]).
  ///
  /// Monotonic-guard: receipt не «откатывает» marker назад (out-of-order
  /// delivery ИЛИ seed старее уже-применённого realtime). Резолвит ts
  /// прочитанного event-а через loaded history, иначе fallback на
  /// `event.serverTimestamp`.
  void _applyReadReceipt(MessengerEvent event) {
    if (_disposed) return;
    if (kDebugMode) {
      debugPrint(
        '[MessagesController.room=$_roomId] readReceiptUpdated '
        'event.roomId=${event.roomId} reader=${event.readReceiptMatrixUserId} '
        'eventId=${event.readReceiptEventId}',
      );
    }
    if (event.roomId != _roomId) return;
    final readerMxid = event.readReceiptMatrixUserId;
    final readEventId = event.readReceiptEventId;
    if (readerMxid == null || readEventId == null) return;
    // Резолвим timestamp прочитанного event-а через state.messages
    // (если у нас есть этот message в loaded history). Иначе fallback на
    // event.serverTimestamp (для seed = lastReadAt, для realtime = когда
    // receipt пришёл).
    DateTime readUpTo = event.serverTimestamp;
    final state = _state.value;
    if (state is MessagesReady) {
      for (final m in state.messages) {
        if (m.matrixEventId == readEventId) {
          readUpTo = m.serverTimestamp;
          break;
        }
      }
    }
    final prev = _peerLastReadAt[readerMxid];
    // Monotonic: новый receipt не должен «откатывать» backward
    // (out-of-order delivery / seed старее realtime).
    if (prev != null && prev.isAtSameMomentAs(readUpTo)) return;
    if (prev != null && prev.isAfter(readUpTo)) return;
    _peerLastReadAt[readerMxid] = readUpTo;
    _readReceiptsVersion.value = _readReceiptsVersion.value + 1;
  }

  /// Optimistic send. UX:
  ///   1. Создаём pending bubble с свежим UUID `clientTxnId`,
  ///      append на index 0 (top of DESC list) → UI видит сразу.
  ///   2. `_rpc.sendMessage` в фоне.
  ///   3a. На success → server вернул `MessengerMessage` (с тем же
  ///       `clientTxnId`); layer-1 dedup промоутит pending → sent.
  ///   3b. На failure → pending помечается failed; UI показывает
  ///       retry-button. Retry зовёт [retry] с тем же `clientTxnId`.
  ///
  /// Возвращает `clientTxnId`, чтобы host-app мог сослаться на
  /// созданный bubble (например, для ручного `retry`). Метод не
  /// throws — все ошибки уходят в state failed-bubble через
  /// `_onSendError` callback.
  ///
  /// **Контракт порядка**: ожидается, что `init()` вызван **до**
  /// `sendMessage`. Если sendMessage пришёл во время Loading (init
  /// ещё в полёте), pending bubble будет создан в "промежуточный"
  /// `Ready` (с одним только pending), а финальный `init()`
  /// перезапишет state свежим Ready из server-history — pending
  /// **временно исчезнет**, потом снова появится через layer-1 dedup
  /// когда RPC вернёт echo. Видимый flicker, но не data loss.
  /// Host-app pattern: создавай controller + сразу `init()` (можно
  /// без await в `initState`, controller сам отдаст Loading→Ready),
  /// и не отправляй сообщение из UI до перехода state в Ready.
  /// ChatScreen в TASK15 Chunk 2 enforce-ит это через disabled
  /// composer пока state ≠ Ready.
  Future<String> sendMessage({
    required String body,
    String msgType = 'm.text',
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  }) async {
    final txnId = _txnIdGenerator();
    if (_disposed) return txnId;

    // TASK19 Chunk 3: для media-сообщений msgType derives из MIME
    // (server sets m.image/m.video/m.file). Optimistic bubble
    // отображает attachment мгновенно — UI выглядит как media-message
    // без spinner-фазы.
    final effectiveMsgType = attachment != null
        ? _msgTypeForMime(attachment.mimeType)
        : msgType;
    final effectiveBody = body.isEmpty && attachment != null
        ? attachment.originalFilename
        : body;

    final optimistic = ChatMessage.optimistic(
      clientTxnId: txnId,
      senderMatrixUserId: _selfMatrixUserId,
      senderMessengerUserId: _selfMessengerUserId,
      body: effectiveBody,
      msgType: effectiveMsgType,
      attachment: attachment,
      replyToMessageId: replyToMatrixEventId,
      mentionedMessengerUserIds: mentionedMessengerUserIds,
    );
    _insertLocalPending(optimistic);

    // TASK16-A: после fire send — сразу clear reply-target, чтобы UI
    // composer не «застревал» с quote chip-ом для уже отправленного
    // reply. На revert (failed send) chip не возвращается — user может
    // retry без quote (acceptable MVP UX).
    if (replyToMatrixEventId != null) {
      clearReplyTarget();
    }

    await _shootSendRpc(
      clientTxnId: txnId,
      body: effectiveBody,
      msgType: effectiveMsgType,
      attachment: attachment,
      replyToMatrixEventId: replyToMatrixEventId,
      mentionedMessengerUserIds: mentionedMessengerUserIds,
    );
    return txnId;
  }

  /// **TASK19 Chunk 3**: upload media bytes + send как attachment в
  /// одном flow. Используется `MessageComposer.onSendAttachment`
  /// callback. Returns clientTxnId; UI ничего с ним не делает,
  /// optimistic bubble уже виден.
  Future<String> sendAttachment({
    required Uint8List bytes,
    required String mimeType,
    required String originalFilename,
    String body = '',
  }) async {
    if (_disposed) return '';
    final ref = await _rpc.uploadAttachment(
      bytes: ByteData.sublistView(bytes),
      mimeType: mimeType,
      originalFilename: originalFilename,
    );
    if (_disposed) return '';
    return sendMessage(body: body, attachment: ref);
  }

  /// Matrix msgType derived из MIME для optimistic bubble msgType.
  /// Server валидирует и sets окончательный — в RPC return приходит
  /// authoritative значение, мы переписываем локальный bubble.
  static String _msgTypeForMime(String mime) {
    if (mime.startsWith('image/')) return 'm.image';
    if (mime.startsWith('video/')) return 'm.video';
    return 'm.file';
  }

  /// Помечает комнату прочитанной до `matrixEventId` включительно
  /// (TASK18). Server-side: atomic SQL update + Matrix `m.read`
  /// receipt + emit `roomUnreadChanged` (counter=0) для cross-device.
  ///
  /// **Контракт failure-free**: метод не throws. Network-error /
  /// monotonic-regression обрабатываются silently — следующий
  /// auto-markRead (через ChatScreen debounced timer на новое
  /// сообщение) всё равно перекроет horizon. Self-healing без явной
  /// retry-логики (см. ревью TASK18 plan #Q8).
  Future<void> markRead(String matrixEventId) async {
    if (_disposed) return;
    try {
      await _rpc.markRead(roomId: _roomId, matrixEventId: matrixEventId);
    } catch (e) {
      // Тихо: failure не блокирует chat-UX. Auto-debounce следующим
      // event-ом перекроет horizon. `onSendError` намеренно НЕ
      // используется (его контракт — только about send-failures).
      //
      // Stacktrace опущен (ревью plan TASK18 7b8716f #1): на постоянном
      // offline auto-trigger каждые 500ms даст лог-spam; для transient
      // network errors stack малоинформативен. Если нужно глубже
      // дебажить — использовать proper error reporter (TASK20 push
      // routing вынесет ErrorReporter на этот путь).
      if (kDebugMode) {
        debugPrint('[MessagesController.room=$_roomId] markRead failed: $e');
      }
    }
  }

  /// Повторить send для bubble в `failed`-status. Reuse того же
  /// `clientTxnId` — server-side idempotency защитит от дубля
  /// (если первый запрос успел дойти, server вернёт existing event
  /// с тем же matrix event id).
  Future<void> retry(String clientTxnId) async {
    if (_disposed) return;
    final current = _state.value;
    if (current is! MessagesReady) return;

    final idx = current.messages.indexWhere(
      (m) => m.clientTxnId == clientTxnId && m.isFailed,
    );
    if (idx < 0) return;
    final failedMsg = current.messages[idx];

    final newMessages = List<ChatMessage>.of(current.messages);
    newMessages[idx] = failedMsg.retrying();
    _state.value = current.copyWith(messages: newMessages);

    await _shootSendRpc(
      clientTxnId: clientTxnId,
      body: failedMsg.body,
      msgType: failedMsg.msgType,
      attachment: failedMsg.attachment,
      replyToMatrixEventId: failedMsg.replyToMessageId,
      mentionedMessengerUserIds: failedMsg.mentionedMessengerUserIds,
    );
  }

  /// **B10 (BACKLOG)**: повторить ВСЕ сообщения в `failed`-статусе. Зовётся
  /// ChatScreen-ом при возврате сети (transport `connectionState` →
  /// `healthy` после reconnecting/disconnected) — сообщения, которые
  /// исчерпали in-send retry-расписание (~60с) пока сеть лежала, авто-
  /// переотправляются. Idempotent: каждый [retry] переиспользует тот же
  /// `clientTxnId`, server-side dedup защищает от дубля. Permanent-failure
  /// (4xx) переотправится и снова быстро упадёт в failed — без вреда.
  Future<void> retryAllFailed() async {
    if (_disposed) return;
    final current = _state.value;
    if (current is! MessagesReady) return;
    // Snapshot txnId-ов ДО retry (он мутирует state на каждой итерации).
    final failedTxnIds = <String>[
      for (final m in current.messages)
        if (m.isFailed && m.clientTxnId != null) m.clientTxnId!,
    ];
    for (final txnId in failedTxnIds) {
      if (_disposed) return;
      await retry(txnId);
    }
  }

  // ─── TASK37 Chunk 2: edit / delete ─────────────────────────────────

  /// **TASK37**: edit own message. Optimistic — bubble показывает
  /// `newBody` мгновенно с `editedAt = now`; revert на RPC fail.
  /// Race-safe: если local bubble уже tombstone (`isDeleted`) либо
  /// `pending`/`failed` (RPC server-side fallback дёрнется, но local
  /// state не имеет stable matrixEventId-а до RPC return) — silent
  /// no-op.
  Future<void> editMessage({
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) async {
    if (_disposed) return;
    final current = _state.value;
    if (current is! MessagesReady) return;
    final idx = current.messages.indexWhere(
      (c) => c.matrixEventId == matrixEventId && !c.isDeleted,
    );
    if (idx < 0) return;
    final original = current.messages[idx];
    final snapshot = current.messages;

    // Optimistic update.
    final optimistic = original.withEdit(
      newBody: newBody,
      editedAt: DateTime.now().toUtc(),
      newMentionedMessengerUserIds: mentionedMessengerUserIds,
    );
    final updated = List<ChatMessage>.of(snapshot)..[idx] = optimistic;
    _state.value = current.copyWith(messages: updated);

    try {
      final real = await _rpc.editMessage(
        roomId: _roomId,
        matrixEventId: matrixEventId,
        newBody: newBody,
        mentionedMessengerUserIds: mentionedMessengerUserIds,
      );
      if (_disposed) return;
      // Apply server-authoritative state (editedAt may differ from
      // optimistic local value).
      final after = _state.value;
      if (after is! MessagesReady) return;
      final newIdx = after.messages.indexWhere(
        (c) => c.matrixEventId == matrixEventId,
      );
      if (newIdx < 0) return;
      final svrMessages = List<ChatMessage>.of(after.messages);
      svrMessages[newIdx] = after.messages[newIdx].withEdit(
        newBody: real.body,
        editedAt: real.editedAt ?? DateTime.now().toUtc(),
        newMentionedMessengerUserIds: real.mentionedMessengerUserIds,
      );
      _state.value = after.copyWith(messages: svrMessages);
    } catch (e, st) {
      if (_disposed) return;
      // Revert.
      _state.value = current.copyWith(messages: snapshot);
      _onSendError?.call(e, st);
      rethrow;
    }
  }

  /// **TASK37**: delete own message. Optimistic — bubble превращается
  /// в tombstone мгновенно; revert на RPC fail.
  Future<void> deleteMessage({required String matrixEventId}) async {
    if (_disposed) return;
    final current = _state.value;
    if (current is! MessagesReady) return;
    final idx = current.messages.indexWhere(
      (c) => c.matrixEventId == matrixEventId && !c.isDeleted,
    );
    if (idx < 0) return;
    final snapshot = current.messages;
    final original = current.messages[idx];

    // Optimistic tombstone.
    final tombstone = original.withDelete(deletedAt: DateTime.now().toUtc());
    final updated = List<ChatMessage>.of(snapshot)..[idx] = tombstone;
    _state.value = current.copyWith(messages: updated);

    try {
      await _rpc.deleteMessage(roomId: _roomId, matrixEventId: matrixEventId);
    } catch (e, st) {
      if (_disposed) return;
      // Revert.
      _state.value = current.copyWith(messages: snapshot);
      _onSendError?.call(e, st);
      rethrow;
    }
  }

  /// **TASK37**: handle realtime `messageUpdated` event.
  /// **Race mitigation** (TASK37 Chunk 1 review #1): если local bubble
  /// уже tombstone (`isDeleted`), skip update — late edit event для
  /// уже-удалённого message не должен resurrect-ить bubble.
  void _handleMessageUpdated(MessengerMessage m) {
    final current = _state.value;
    if (current is! MessagesReady) return;
    final idx = current.messages.indexWhere(
      (c) => c.matrixEventId == m.matrixEventId,
    );
    if (idx < 0) return;
    final existing = current.messages[idx];
    if (existing.isDeleted) {
      // Race: edit arrived AFTER redaction. Tombstone wins; ignore
      // late edit.
      return;
    }
    final updated = List<ChatMessage>.of(current.messages);
    updated[idx] = existing.withEdit(
      newBody: m.body,
      editedAt: m.editedAt ?? m.serverTimestamp,
    );
    _state.value = current.copyWith(messages: updated);
  }

  /// **TASK37**: handle realtime `messageDeleted` event.
  void _handleMessageDeleted(MessengerMessage m) {
    final current = _state.value;
    if (current is! MessagesReady) return;
    final idx = current.messages.indexWhere(
      (c) => c.matrixEventId == m.matrixEventId,
    );
    if (idx < 0) return;
    final existing = current.messages[idx];
    if (existing.isDeleted) return; // already tombstone (idempotent).
    final updated = List<ChatMessage>.of(current.messages);
    updated[idx] = existing.withDelete(
      deletedAt: m.deletedAt ?? m.serverTimestamp,
    );
    _state.value = current.copyWith(messages: updated);
  }

  /// **Emoji reactions**: применить realtime `reactionChanged` event к
  /// агрегату. Два случая:
  ///   * add (`reactionRedacted != true`): по
  ///     (target, key, reactor, reactionEventId) добавляем reactor в
  ///     set + индексируем reactionEventId.
  ///   * redact (`reactionRedacted == true`): redaction знает только
  ///     `reactionEventId` (= target redaction-а). Находим по нему ref
  ///     в reverse-индексе, убираем reactor из set, чистим индекс. Если
  ///     ref не найден (redaction был не реакцией, либо мы не видели
  ///     add-event) — no-op.
  void _handleReactionChanged(MessengerEvent e) {
    final reactionEventId = e.reactionEventId;
    if (reactionEventId == null) return;
    final reactor = e.reactionReactorMatrixUserId;

    if (e.reactionRedacted == true) {
      final ref = _reactionRefById.remove(reactionEventId);
      if (ref == null) return; // не реакция, или add не виден — no-op.
      final byKey = _reactionsByTarget[ref.targetEventId];
      final set = byKey?[ref.key];
      if (set == null) return;
      set.remove(ref.reactorMatrixId);
      if (set.isEmpty) {
        byKey!.remove(ref.key);
        if (byKey.isEmpty) _reactionsByTarget.remove(ref.targetEventId);
      }
      _reactionsVersion.value = _reactionsVersion.value + 1;
      return;
    }

    // Add path.
    final target = e.reactionTargetEventId;
    final key = e.reactionKey;
    if (target == null || key == null || reactor == null) return;
    // Idempotent: повторная доставка того же reaction-event — skip.
    if (_reactionRefById.containsKey(reactionEventId)) return;
    _reactionRefById[reactionEventId] = _ReactionRef(
      targetEventId: target,
      key: key,
      reactorMatrixId: reactor,
    );
    final byKey = _reactionsByTarget.putIfAbsent(
      target,
      () => <String, Set<String>>{},
    );
    final set = byKey.putIfAbsent(key, () => <String>{});
    set.add(reactor);
    _reactionsVersion.value = _reactionsVersion.value + 1;
  }

  /// Отписаться от стрима + не emit state из in-flight async-операций.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _eventsSub?.cancel();
    _eventsSub = null;
    _initBuffer = null;
    _state.dispose();
    _replyTarget.dispose();
    _typingPeers.dispose();
    _readReceiptsVersion.dispose();
    _reactionsVersion.dispose();
    _peerLastReadAt.clear();
    _reactionsByTarget.clear();
    _reactionRefById.clear();
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────

  void _onEvent(MessengerEvent event) {
    if (_disposed) return;

    // **B9 typing**: ephemeral event, message=null. Handle ДО
    // `message` null-check ниже.
    if (event.eventType == MessengerEventType.typingChanged) {
      if (kDebugMode) {
        debugPrint(
          '[MessagesController.room=$_roomId] typingChanged '
          'event.roomId=${event.roomId} ids=${event.typingMatrixUserIds}',
        );
      }
      if (event.roomId != _roomId) return; // другая room
      final list = event.typingMatrixUserIds ?? const <String>[];
      _typingPeers.value = Set<String>.unmodifiable(list);
      return;
    }

    // **B11 read receipts**: ephemeral event, message=null. Обновляем
    // per-peer last-read marker. UI bubble через `readByPeerMatrixIds`
    // считает количество прочитавших. Общая обработка вынесена в
    // [_applyReadReceipt] — её же использует B22 seed (listReadReceipts).
    if (event.eventType == MessengerEventType.readReceiptUpdated) {
      _applyReadReceipt(event);
      return;
    }

    // **Emoji reactions**: reactionChanged ephemeral-like event,
    // message=null. Аккумулируем агрегат, bump version → UI rebuild.
    if (event.eventType == MessengerEventType.reactionChanged) {
      if (event.roomId != _roomId) return;
      _handleReactionChanged(event);
      return;
    }

    final m = event.message;
    if (m == null) return;

    // **TASK37**: type-switch на messageUpdated / messageDeleted ПЕРЕД
    // `_acceptIncomingInto`. Эти events содержат `MessengerMessage` с
    // `matrixEventId = TARGET` (server-side dispatcher convention) +
    // editedAt / deletedAt populated.
    if (event.eventType == MessengerEventType.messageUpdated) {
      _handleMessageUpdated(m);
      return;
    }
    if (event.eventType == MessengerEventType.messageDeleted) {
      _handleMessageDeleted(m);
      return;
    }

    // Если ещё в init() — буферим до Ready.
    final buffer = _initBuffer;
    if (buffer != null) {
      if (buffer.length >= _pendingBufferCap) {
        // Overflow: накопилось слишком много events за время первой
        // listMessages-страницы. Скорее всего сеть медленная, или
        // в комнате media-burst. Restart init — _initEpoch++ заставит
        // in-flight `listMessages` future игнорировать свой результат;
        // новый init создаст свежий buffer и заново дёрнет history.
        if (kDebugMode) {
          debugPrint(
            '[MessagesController.room=$_roomId] pending overflow '
            '(${buffer.length} >= $_pendingBufferCap) — refetching history',
          );
        }
        // Текущий event намеренно НЕ кладём в новый buffer — старый
        // buffer выбрасывается вместе с in-flight epoch, новый init
        // создаст свежий пустой buffer. Этот event в Matrix sync-е
        // в любом случае был в окне «последние 50 сообщений», поэтому
        // re-fetched listMessages (без fromToken — newest 50) его
        // вернёт. Если же overflow триггернуло какое-то совсем свежее
        // событие, не успевшее попасть в backend на момент рестарта —
        // оно всё равно прилетит через stream после Ready (sub живёт
        // через restart).
        unawaited(init());
        return;
      }
      buffer.add(m);
      return;
    }

    final current = _state.value;
    if (current is! MessagesReady) return;
    final newMessages = List<ChatMessage>.of(current.messages);
    final changed = _acceptIncomingInto(newMessages, m);
    if (!changed) return;
    _state.value = current.copyWith(messages: newMessages);
  }

  /// Применить серверное сообщение к `target`-листу in-place.
  /// Возвращает `true`, если список действительно изменился.
  ///
  /// **Layer-1 (pending → real):** если у нас есть pending entry с
  /// тем же `clientTxnId` — replace in-place (сохраняем позицию,
  /// никаких UI-jump-ов).
  ///
  /// **Layer-2 (real → real dedup):** если уже есть entry с тем же
  /// `matrixEventId` — silent skip (защита от двойной доставки RPC
  /// return + stream).
  bool _acceptIncomingInto(List<ChatMessage> target, MessengerMessage m) {
    // Layer-1.
    final txnId = m.clientTxnId;
    if (txnId != null) {
      final pendingIdx = target.indexWhere(
        (c) => c.clientTxnId == txnId && (c.isPending || c.isFailed),
      );
      if (pendingIdx >= 0) {
        target[pendingIdx] = ChatMessage.fromServer(m);
        return true;
      }
    }
    // Layer-2.
    if (target.any((c) => c.matrixEventId == m.matrixEventId)) {
      return false;
    }
    // New incoming — insert at top (DESC).
    target.insert(0, ChatMessage.fromServer(m));
    return true;
  }

  void _insertLocalPending(ChatMessage pending) {
    final current = _state.value;
    if (current is MessagesReady) {
      final newMessages = List<ChatMessage>.of(current.messages)
        ..insert(0, pending);
      _state.value = current.copyWith(messages: newMessages);
    } else {
      // Send до init() — крайний edge case. Создаём минимальный Ready
      // с одним pending; init() потом подмержит history через
      // _acceptIncomingInto.
      _state.value = MessagesReady(
        messages: [pending],
        hasMore: false,
        paginating: false,
      );
    }
  }

  Future<void> _shootSendRpc({
    required String clientTxnId,
    required String body,
    required String msgType,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  }) async {
    // **B10**: retry-loop с backoff для transient ошибок (network,
    // timeout, 5xx). Идемпотентность гарантирует server-side dedup по
    // `clientTxnId` (TASK09 §retry-policy) — каждая попытка с тем же
    // txnId, при success сервер вернёт первый committed event, при
    // дубликате — тот же event повторно.
    //
    // Permanent ошибки (4xx, типизированные доменные exception-ы)
    // ретрай не делают — сразу `_markFailed`.
    Object? lastError;
    StackTrace? lastStack;
    final attempts = _sendRetrySchedule.length + 1; // initial + retries
    for (var i = 0; i < attempts; i++) {
      if (_disposed) return;
      try {
        final real = await _rpc.sendMessage(
          roomId: _roomId,
          body: body,
          msgType: msgType,
          clientTxnId: clientTxnId,
          attachment: attachment,
          replyToMatrixEventId: replyToMatrixEventId,
          mentionedMessengerUserIds: mentionedMessengerUserIds,
        );
        if (_disposed) return;
        // Layer-1 promote pending → sent. Use _acceptIncomingInto на
        // current state, чтобы единая dedup-логика работала.
        final current = _state.value;
        if (current is! MessagesReady) return;
        final newMessages = List<ChatMessage>.of(current.messages);
        final changed = _acceptIncomingInto(newMessages, real);
        if (changed) {
          _state.value = current.copyWith(messages: newMessages);
        }
        return; // success
      } catch (e, st) {
        if (_disposed) return;
        lastError = e;
        lastStack = st;
        if (!_isTransientSendError(e)) {
          // Permanent (4xx, auth, domain exception) — НЕ ретраим.
          break;
        }
        if (i < _sendRetrySchedule.length) {
          // Поспать до следующей попытки. Bubble остаётся в pending.
          final delay = _sendRetrySchedule[i];
          if (kDebugMode) {
            debugPrint(
              '[MessagesController.room=$_roomId] send transient '
              'attempt=${i + 1}/$attempts error=$e — retry in '
              '${delay.inSeconds}s',
            );
          }
          try {
            await Future<void>.delayed(delay);
          } catch (_) {
            return; // disposed during sleep
          }
          if (_disposed) return;
        }
      }
    }
    // Все попытки исчерпаны (или permanent error) → mark failed.
    _markFailed(clientTxnId: clientTxnId, error: lastError ?? 'send failed');
    if (lastError != null) {
      _onSendError?.call(lastError, lastStack ?? StackTrace.current);
    }
  }

  /// **B10**: классификатор «transient vs permanent» для send-retry.
  ///
  /// **Transient** (ретраим): сетевые/IO ошибки, таймаут, generic
  /// `ServerpodClientException` (5xx, parse error в ответе, dropped
  /// connection). Эти обычно временные — сервер мог рестартануть,
  /// connection упал, retry с тем же txnId безопасен (dedup).
  ///
  /// **Permanent** (НЕ ретраим): типизированные доменные exception-ы
  /// (`MessengerNotAuthenticated`, `RoomNotFound`, `PeerUnavailable` и
  /// т.д.), 401, 403 — ретрай тех же ошибок не поможет. Лучше сразу
  /// показать пользователю failed-bubble с retry-button (он либо
  /// поправит ситуацию, либо вручную retry-нет позже).
  bool _isTransientSendError(Object error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is HandshakeException) return true;
    if (error is HttpException) return true;
    // Generic Serverpod-client exception (5xx, parse fail, network).
    // Типизированные доменные exception-ы наследуются от
    // SerializableException, а НЕ от ServerpodClientException, поэтому
    // этот match их не зацепит.
    if (error is ServerpodClientException) return true;
    return false;
  }

  void _markFailed({required String clientTxnId, required Object error}) {
    final current = _state.value;
    if (current is! MessagesReady) return;
    final idx = current.messages.indexWhere(
      (m) => m.clientTxnId == clientTxnId && m.isPending,
    );
    if (idx < 0) return;
    final newMessages = List<ChatMessage>.of(current.messages);
    newMessages[idx] = current.messages[idx].failed(error);
    _state.value = current.copyWith(messages: newMessages);
  }
}

/// **Emoji reactions**: reverse-индексная запись `reactionEventId →
/// (target, key, reactor)`. Нужна чтобы redaction (знающий только
/// reactionEventId) мог декрементить правильный (target,key) и чтобы
/// `toggleReaction` нашёл свой reaction-event-id для toggle-off.
class _ReactionRef {
  const _ReactionRef({
    required this.targetEventId,
    required this.key,
    required this.reactorMatrixId,
  });
  final String targetEventId;
  final String key;
  final String reactorMatrixId;
}

/// Default — non-cryptographic UUIDv4-like 16 bytes hex. Crypto-strong
/// рандом не нужен (txnId не secret), но достаточно entropy чтобы
/// collision на client side был невозможен в practical limits.
String _defaultTxnIdGenerator() {
  final rand = math.Random();
  String hex(int n) {
    final buf = StringBuffer();
    for (var i = 0; i < n; i++) {
      buf.write(rand.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  // 8-4-4-4-12 (UUIDv4-shape, без version-bit setup — нам идентичность
  // не nominal-UUID, а просто уникальная строка).
  return '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}';
}
