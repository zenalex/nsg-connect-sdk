import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:path/path.dart' as p;

import '../cache/messenger_cache_store.dart';
import '../outbox/outbox_item.dart';
import '../outbox/outbox_sender.dart';
import '../share/share_limits.dart';
import 'attachments/attachment_mime_types.dart';
import 'attachments/attachment_picker.dart';
import 'chat_message.dart';
import 'composer_album_edit.dart';
import 'forward_source.dart';
import 'messages_rpc.dart';
import 'messages_state.dart';
import 'send_error_classifier.dart';

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
    this.onSendError,
    List<Duration>? sendRetrySchedule,
    MessengerCacheStore? cache,
    OutboxSender? outbox,
  }) : _sendRetrySchedule = sendRetrySchedule ?? kDefaultSendRetrySchedule,
       _cache = cache,
       _outbox = outbox,
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
       _loadMorePageSize = loadMorePageSize;

  final int _roomId;
  final MessagesRpc _rpc;
  final Stream<MessengerEvent> _events;
  final int _selfMessengerUserId;
  final String _selfMatrixUserId;
  final String Function() _txnIdGenerator;
  final int _pendingBufferCap;
  final int _initialPageSize;
  final int _loadMorePageSize;

  /// Сбой отправки, который пользователь должен увидеть: исчерпанный
  /// send-RPC либо упавший фоновый аплоад вложения.
  ///
  /// **Issue #54**: поле mutable (не `final`), потому что задать его через
  /// конструктор может только тот, кто контроллер СОЗДАЁТ. ChatScreen же
  /// часто получает готовый инстанс (`controllerOverride`) — и тогда
  /// ошибка снова умирала бы внутри контроллера. Теперь экран подключается
  /// после конструктора, не завися от того, кто владеет контроллером.
  void Function(Object error, StackTrace stack)? onSendError;

  final List<Duration> _sendRetrySchedule;

  /// **TASK47**: дисковый кэш (null → оффлайн-история выключена). init()
  /// показывает кэш сразу, наполняет его свежей страницей и сбрасывает при
  /// разрыве (gap §3 п.7). Realtime-мёрж в кэш делает NsgMessengerRooms.
  final MessengerCacheStore? _cache;

  /// **OUTBOX**: фоновый отправитель персистентной очереди. Null → outbox
  /// выключен (кэш недоступен): контроллер работает как раньше, без
  /// pending-бабблов из очереди. Используется для retry/discard из UI.
  final OutboxSender? _outbox;

  /// **OUTBOX**: подписка на изменения очереди для ЭТОЙ комнаты — новые
  /// enqueue появляются pending-бабблами вживую, delete-на-успехе убирает их.
  StreamSubscription<int>? _outboxSub;

  /// **OUTBOX**: clientTxnId-ы, которые сейчас показаны как бабблы из очереди
  /// (инъекция). На refresh снимаем исчезнувшие (discard / доставлено).
  final Set<String> _outboxTxnIds = <String>{};

  final ValueNotifier<MessagesState> _state = ValueNotifier(
    const MessagesLoading(),
  );

  /// **TASK38**: доступна ли task-интеграция в этой комнате — gating для
  /// пункта «Создать задачу» в long-press меню. Грузится best-effort в
  /// [init] (не блокирует загрузку сообщений); до ответа / при ошибке /
  /// если интеграция не настроена — `false` (пункт скрыт). Action-sheet
  /// читает значение при открытии (init к тому моменту уже отработал), так
  /// что reactive-notify не нужен.
  bool _taskIntegrationEnabled = false;
  bool get taskIntegrationEnabled => _taskIntegrationEnabled;

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

  /// **Issue #35 — закрепление сообщений**: закреплённые сообщения комнаты
  /// (oldest-first, как в Matrix `m.room.pinned_events`). Плашка над чатом
  /// слушает [pinnedListenable]. Наполняется [loadPinned] при открытии и на
  /// realtime `pinnedMessagesChanged`. Источник правды — сервер; тут только
  /// кэш для отрисовки.
  final ValueNotifier<List<ChatMessage>> _pinned =
      ValueNotifier<List<ChatMessage>>(const <ChatMessage>[]);
  ValueListenable<List<ChatMessage>> get pinnedListenable => _pinned;
  List<ChatMessage> get pinnedMessages => _pinned.value;

  /// Быстрый lookup «закреплено ли сообщение» — derived из `_pinned` (для
  /// пункта Pin/Unpin в action-sheet). Пустой до первого [loadPinned].
  Set<String> _pinnedIds = const <String>{};
  bool isPinned(String matrixEventId) => _pinnedIds.contains(matrixEventId);

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

    // **OUTBOX**: подписка на изменения очереди этой комнаты (однократно) —
    // enqueue/delete/mark отражаются в pending-бабблах вживую.
    final outboxCache = _cache;
    if (outboxCache != null) {
      _outboxSub ??= outboxCache.outboxRoomChanges
          .where((rid) => rid == _roomId)
          .listen((_) => unawaited(_refreshOutbox()));
    }

    // **TASK38**: best-effort gating-чек (показывать ли «Создать задачу»).
    // Параллельно с загрузкой сообщений; ошибка / нет интеграции → false.
    unawaited(
      _rpc
          .isTaskIntegrationAvailable(roomId: _roomId)
          .then((v) {
            if (!_disposed && epoch == _initEpoch) _taskIntegrationEnabled = v;
          })
          .catchError((Object _) {}),
    );

    // **TASK47**: показать кэшированную историю СРАЗУ (до сети). Буфер
    // применяем неразрушающе — серверный путь ниже применит его снова
    // (dedup в _acceptIncomingInto идемпотентен, буфер обнуляется там).
    final cache = _cache;
    if (cache != null) {
      try {
        final cached = await cache.getMessages(
          _roomId,
          limit: _initialPageSize,
        );
        if (!_disposed && epoch == _initEpoch && cached.isNotEmpty) {
          final cachedList = cached.map(ChatMessage.fromServer).toList();
          for (final m in _initBuffer ?? const <MessengerMessage>[]) {
            _acceptIncomingInto(cachedList, m);
          }
          _state.value = MessagesReady(
            messages: cachedList,
            hasMore: true,
            paginating: false,
          );
        }
      } catch (_) {
        // best-effort — кэш не должен ломать открытие чата.
      }
    }

    final MessengerMessageListPage page;
    try {
      page = await _rpc.listMessages(roomId: _roomId, limit: _initialPageSize);
    } catch (e) {
      if (_disposed || epoch != _initEpoch) return;
      _initBuffer = null;
      // **TASK47**: оффлайн — если кэш уже показан, оставляем историю из
      // кэша; иначе (кэша нет / пуст) — ошибка.
      if (_state.value is! MessagesReady) {
        _state.value = MessagesError(error: e, lastKnown: null);
      }
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

    // **TASK47**: наполняем кэш свежей страницей; при разрыве между кэш-
    // хвостом и новой «головой» — сбрасываем кэш комнаты (§3 п.7). Best-
    // effort, unawaited — не блокирует рендер.
    if (cache != null) {
      unawaited(_reconcileCache(cache, page.messages));
    }

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

    // **Issue #35 — закрепление сообщений**: подтянуть закреплённые для
    // плашки над чатом при открытии (а не только по realtime). Best-effort,
    // unawaited — не блокирует первый рендер.
    unawaited(loadPinned());

    // **OUTBOX**: отрисовать pending-бабблы из персистентной очереди (share и
    // прочие фоновые отправки), пережившие рестарт. Best-effort, unawaited.
    unawaited(_refreshOutbox());
  }

  /// **TASK47**: gap-детект + наполнение кэша свежей страницей. Если
  /// новейшее КЭШированное сообщение старше самого старого в серверной
  /// странице (за оффлайн пришло больше, чем помещается в страницу) —
  /// сбрасываем кэш комнаты (наивный merge несмежных диапазонов запрещён,
  /// §3 п.7), затем кладём свежую страницу.
  Future<void> _reconcileCache(
    MessengerCacheStore cache,
    List<MessengerMessage> serverPage,
  ) async {
    try {
      if (serverPage.isEmpty) return;
      var serverOldest = serverPage.first.serverTimestamp;
      for (final m in serverPage) {
        if (m.serverTimestamp.isBefore(serverOldest)) {
          serverOldest = m.serverTimestamp;
        }
      }
      final cachedTail = await cache.getMessages(_roomId, limit: 1);
      // getMessages возвращает по возрастанию → последний = новейший.
      if (cachedTail.isNotEmpty &&
          serverOldest.isAfter(cachedTail.last.serverTimestamp)) {
        // Разрыв: серверная страница не смыкается с кэшем → сброс.
        await cache.resetRoomMessages(_roomId);
      }
      await cache.putMessages(_roomId, serverPage);
    } catch (_) {
      // best-effort — кэш не должен ломать загрузку.
    }
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

  /// **Issue #35 — закрепление сообщений**: (пере)загрузить закреплённые
  /// сообщения комнаты с сервера в плашку. Best-effort — ошибка (например,
  /// нет сети) не мешает чату; плашка просто не обновится.
  Future<void> loadPinned() async {
    final List<MessengerMessage> msgs;
    try {
      msgs = await _rpc.listPinnedMessages(roomId: _roomId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MessagesController.room=$_roomId] loadPinned failed: $e '
          '(best-effort, ignored)',
        );
      }
      return;
    }
    if (_disposed) return;
    final list = msgs.map(ChatMessage.fromServer).toList(growable: false);
    _pinnedIds = <String>{
      for (final m in list)
        if (m.matrixEventId != null) m.matrixEventId!,
    };
    _pinned.value = list;
  }

  /// **Issue #35**: закрепить сообщение [matrixEventId]. После успешного RPC
  /// перечитывает плашку через [loadPinned] (закреплённое сообщение может
  /// быть вне загруженного окна — нужен серверный резолв полного DTO).
  /// Бросает наверх — UI (`showMessageActionSheet`) ловит и показывает
  /// snackbar (напр. [InsufficientPowerException] в группе для member-а).
  Future<void> pinMessage(String matrixEventId) async {
    await _rpc.pinMessage(roomId: _roomId, matrixEventId: matrixEventId);
    if (_disposed) return;
    await loadPinned();
  }

  /// **Issue #35**: снять закрепление [matrixEventId]. Idempotent.
  Future<void> unpinMessage(String matrixEventId) async {
    await _rpc.unpinMessage(roomId: _roomId, matrixEventId: matrixEventId);
    if (_disposed) return;
    await loadPinned();
  }

  /// **Issue #35**: применить realtime `pinnedMessagesChanged`. Если набор
  /// id совпадает с текущим (эхо собственного pin/unpin, который уже сделал
  /// [loadPinned]) — no-op, лишний RPC не шлём. Иначе перечитываем плашку.
  void _handlePinnedChanged(MessengerEvent event) {
    final incoming = (event.pinnedEventIds ?? const <String>[]).toSet();
    if (incoming.length == _pinnedIds.length &&
        incoming.every(_pinnedIds.contains)) {
      return;
    }
    unawaited(loadPinned());
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
  /// `onSendError` callback.
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
    String? albumId,
  }) async {
    final txnId = _txnIdGenerator();
    if (_disposed) return txnId;

    // TASK19 Chunk 3: для media-сообщений msgType derives из MIME
    // (server sets m.image/m.video/m.file). Optimistic bubble
    // отображает attachment мгновенно — UI выглядит как media-message
    // без spinner-фазы.
    final effectiveMsgType = attachment != null
        ? matrixMsgTypeForMime(attachment.mimeType)
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
      albumId: albumId,
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
      albumId: albumId,
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
    String? albumId,
  }) async {
    if (_disposed) return '';
    final ref = await _rpc.uploadAttachment(
      bytes: ByteData.sublistView(bytes),
      mimeType: mimeType,
      originalFilename: originalFilename,
    );
    if (_disposed) return '';
    return sendMessage(body: body, attachment: ref, albumId: albumId);
  }

  /// **TASK49 (share-in)**: отправить вложение по ЛОКАЛЬНОМУ ПУТИ, без
  /// интерактивного пикера (§2 «вход "отправить файл по локальному пути БЕЗ
  /// пикера"»). Читает байты из [path], выводит MIME (аргумент → из имени/
  /// пути) и имя (basename пути по умолчанию), делает клиентскую
  /// pre-upload валидацию размера ([validateShareFileSize], §3.5), затем —
  /// обычный [sendAttachment] (upload → sendMessage) в целевую комнату
  /// контроллера.
  ///
  /// Бросает [SharedFileTooLargeException] при превышении лимита и
  /// `FileSystemException` если файл не читается — оба ловит share-flow и
  /// показывает дружелюбный snackbar. Возвращает `clientTxnId`.
  Future<String> sendFileByPath({
    required String path,
    String? mimeType,
    String? originalFilename,
    String body = '',
  }) async {
    if (_disposed) return '';
    final name = (originalFilename != null && originalFilename.isNotEmpty)
        ? originalFilename
        : p.basename(path);
    final mime = (mimeType != null && mimeType.isNotEmpty)
        ? mimeType
        : guessMimeFromExtension(name);
    final file = File(path);
    final bytes = await file.readAsBytes();
    validateShareFileSize(sizeBytes: bytes.length, mimeType: mime, name: name);
    if (_disposed) return '';
    return sendAttachment(
      bytes: bytes,
      mimeType: mime,
      originalFilename: name,
      body: body,
    );
  }

  /// **Оптимистичный альбом**: отправить N картинок (+опц. подпись) одним
  /// альбомом, который виден **мгновенно** мозаикой (грузящиеся плитки —
  /// блюр + прогресс). Возвращается **сразу** (host-app / композер свободны,
  /// можно печатать дальше), аплоад идёт фоном и переживает реконнект.
  ///
  /// Отличие от [sendAttachment]: там байты грузятся ДО создания пузыря
  /// (поле заморожено). Здесь — пузырь из локальных байт создаётся сразу,
  /// аплоад в фоне, затем плитка подменяется на mxc.
  ///
  /// Flow:
  ///   1. один `albumId` (если >1 картинки или есть подпись); по одному
  ///      `clientTxnId` на картинку;
  ///   2. СРАЗУ вставляем все pending-пузыри (`attachment: null`,
  ///      `localImageBytes: bytes`) → мозаика видна мгновенно;
  ///   3. подпись — отдельным членом альбома через [sendMessage];
  ///   4. `unawaited(_uploadAlbumInBackground(...))` — НЕ await.
  ///
  /// Возвращает `albumId` (или `null` для одиночной картинки без подписи).
  String? sendAlbumOptimistic({
    required List<PickedAttachment> images,
    String caption = '',
    List<int>? mentions,
  }) {
    if (_disposed) return null;
    if (images.isEmpty) {
      // Только подпись без картинок — обычное текстовое сообщение.
      final text = caption.trim();
      if (text.isNotEmpty) {
        unawaited(sendMessage(body: text, mentionedMessengerUserIds: mentions));
      }
      return null;
    }

    final hasCaption = caption.trim().isNotEmpty;
    // Альбом (общий id) только если это реально ≥2 плитки в мозаике: >1
    // картинка ИЛИ картинка + подпись. Одиночная картинка без подписи —
    // обычное сообщение (albumId=null), рендерится одиночным превью.
    final albumId = (images.length > 1 || hasCaption)
        ? _txnIdGenerator()
        : null;

    // Один clientTxnId на картинку — вставляем все pending-пузыри up front.
    final entries = <_AlbumUploadEntry>[];
    for (final img in images) {
      final txn = _txnIdGenerator();
      entries.add(_AlbumUploadEntry(txnId: txn, image: img));
      final optimistic = ChatMessage.optimistic(
        clientTxnId: txn,
        senderMatrixUserId: _selfMatrixUserId,
        senderMessengerUserId: _selfMessengerUserId,
        // Body-плейсхолдер = filename (как серверный default); в bubble для
        // картинок он не показывается (см. _shouldRenderBodyText).
        body: img.originalFilename,
        msgType: matrixMsgTypeForMime(img.mimeType),
        attachment: null,
        localImageBytes: img.bytes,
        // Issue #54: запоминаем ИСХОДНЫЙ MIME — retry не должен
        // восстанавливать его из msgType (для m.file это невозможно).
        localMimeType: img.mimeType,
        albumId: albumId,
      );
      _insertLocalPending(optimistic);
    }

    // Подпись — отдельным членом альбома (текущая модель: caption = m.text
    // с тем же albumId). Идёт своим optimistic-путём через sendMessage.
    if (hasCaption && albumId != null) {
      unawaited(
        sendMessage(
          body: caption.trim(),
          mentionedMessengerUserIds: mentions,
          albumId: albumId,
        ),
      );
    }

    unawaited(_uploadAlbumInBackground(entries, albumId));
    return albumId;
  }

  /// **Оптимистичный альбом**: последовательный фоновый аплоад (порядок +
  /// ограничение пика памяти). По каждой картинке: upload → `_patchUploaded`
  /// (расблюр) → `unawaited(_shootSendRpc(...))` (send с тем же txnId).
  /// Ошибка аплоада → `_markFailed` (UI покажет retry).
  Future<void> _uploadAlbumInBackground(
    List<_AlbumUploadEntry> entries,
    String? albumId,
  ) async {
    for (final e in entries) {
      if (_disposed) return;
      final AttachmentRef ref;
      try {
        ref = await _rpc.uploadAttachment(
          bytes: ByteData.sublistView(e.image.bytes),
          mimeType: e.image.mimeType,
          originalFilename: e.image.originalFilename,
        );
      } catch (err, st) {
        if (_disposed) return;
        // Issue #54: раньше эта ветка молчала — .txt падал с красным «!»
        // и НУЛЁМ строк в логе. Логируем до пометки failed, чтобы причина
        // (в т.ч. AttachmentRejectedException) была видна в консоли даже
        // если host не подключил onSendError.
        if (kDebugMode) {
          debugPrint(
            '[MessagesController.room=$_roomId] upload failed '
            '(txn=${e.txnId}, mime=${e.image.mimeType}, '
            'file=${e.image.originalFilename}): $err',
          );
        }
        _markFailed(clientTxnId: e.txnId, error: err);
        onSendError?.call(err, st);
        continue;
      }
      if (_disposed) return;
      _patchUploaded(e.txnId, ref);
      // Send RPC в фоне — реконсиляция по clientTxnId (у каждого члена свой),
      // как обычный optimistic-send. НЕ await, чтобы следующий аплоад
      // стартовал сразу.
      unawaited(
        _shootSendRpc(
          clientTxnId: e.txnId,
          body: ref.originalFilename,
          msgType: matrixMsgTypeForMime(ref.mimeType),
          attachment: ref,
          albumId: albumId,
        ),
      );
    }
  }

  /// **Оптимистичный альбом**: найти pending-пузырь по `clientTxnId` и
  /// заменить на `withUploadedAttachment(ref)` (плитка расблюривается, байты
  /// сохраняются до промоута в sent). No-op если пузырь уже promote-нулся
  /// или помечен failed.
  void _patchUploaded(String clientTxnId, AttachmentRef ref) {
    if (_disposed) return;
    final current = _state.value;
    if (current is! MessagesReady) return;
    final idx = current.messages.indexWhere(
      (m) => m.clientTxnId == clientTxnId && m.isPending,
    );
    if (idx < 0) return;
    final newMessages = List<ChatMessage>.of(current.messages);
    newMessages[idx] = current.messages[idx].withUploadedAttachment(ref);
    _state.value = current.copyWith(messages: newMessages);
  }

  /// **Редактирование альбома в композере**: применить дифф к существующему
  /// альбому. Best-effort набор операций (НЕ атомарно — приемлемо для MVP,
  /// каждая идемпотентна по-своему):
  ///   1. Добавить новые картинки (`sendAttachment` с общим `albumId`).
  ///   2. Удалить помеченные существующие картинки (`deleteMessage` = redact).
  ///   3. Подпись:
  ///      * есть подпись + новая непуста → `editMessage` (m.replace);
  ///      * есть подпись + новая пуста → `deleteMessage` (убрать подпись);
  ///      * нет подписи + новая непуста → `sendMessage` (m.text с albumId).
  ///
  /// **Порядок** (сначала добавляем, потом удаляем, потом подпись): пока
  /// новые картинки долетают, альбом ещё «жив» на старых; удаление после —
  /// не оставляет пустого окна.
  ///
  /// **Позиция в ленте**: удаление + добавление событий сдвигает альбом
  /// к низу (новые события — newest), в отличие от m.replace. Для случая
  /// «изменена только подпись» ([ComposerAlbumEditResult.onlyCaptionChanged])
  /// делаем только правку подписи — позиция альбома сохраняется.
  Future<void> editAlbum(ComposerAlbumEditResult r) async {
    if (_disposed) return;

    // 1. Новые картинки — upload + send с общим albumId (порядок сохраняем).
    for (final picked in r.newAttachments) {
      if (_disposed) return;
      await sendAttachment(
        bytes: picked.bytes,
        mimeType: picked.mimeType,
        originalFilename: picked.originalFilename,
        albumId: r.albumId,
      );
    }

    // 2. Удаляем помеченные существующие картинки (redact).
    for (final eventId in r.removedImageEventIds) {
      if (_disposed) return;
      await deleteMessage(matrixEventId: eventId);
    }

    // 3. Подпись.
    if (_disposed) return;
    final caption = r.newCaption.trim();
    final captionEventId = r.captionEventId;
    if (captionEventId != null) {
      if (caption.isEmpty) {
        // Была подпись, стала пустой → убрать (redact).
        await deleteMessage(matrixEventId: captionEventId);
      } else {
        // Правим только если реально изменилась (иначе лишний m.replace).
        final existing = findByEventId(captionEventId);
        if (existing == null || existing.body.trim() != caption) {
          await editMessage(matrixEventId: captionEventId, newBody: caption);
        }
      }
    } else if (caption.isNotEmpty) {
      // Подписи не было, добавили новую → отдельное m.text с albumId.
      await sendMessage(body: caption, albumId: r.albumId);
    }
  }

  // ─── Пересылка (forward) ────────────────────────────────────────────

  /// Члены альбома, к которому принадлежит [message] (включая само
  /// сообщение), из текущей загруженной истории. Если [message] не в
  /// альбоме — пустой список. Используется [forwardMessage] для переноса
  /// альбома целиком.
  List<ChatMessage> albumMembersOf(ChatMessage message) {
    final aid = message.albumId;
    if (aid == null || aid.isEmpty) return const <ChatMessage>[];
    final current = _state.value;
    if (current is! MessagesReady) return <ChatMessage>[message];
    final members = current.messages
        .where((m) => m.albumId == aid)
        .toList(growable: false);
    return members.isEmpty ? <ChatMessage>[message] : members;
  }

  /// **Пересылка (forward)** — переслать [message] (или весь его альбом,
  /// если это член альбома) в комнату [targetRoomId]. Поведение «как в
  /// Telegram»:
  ///   * альбом переносится **целиком** (все картинки + подпись) под
  ///     **новым** `albumId` — на целевой стороне это единая мозаика;
  ///   * картинки **переиспользуют исходный `mxc`** (без скачивания/
  ///     перезагрузки — сервер не привязывает media к комнате, mxc
  ///     глобален для homeserver-а);
  ///   * `reply`/`mentions` **сбрасываются** (ссылаются на исходную комнату);
  ///   * атрибуция «Переслано от X» сохраняет **первого** автора при
  ///     повторной пересылке (`forwardedFromName ?? senderDisplayName`).
  ///
  /// Оптимистичный bubble в **текущей** комнате не создаётся (target не
  /// открыт) — realtime сам покажет сообщение, если целевая комната где-то
  /// открыта. RPC-ошибку **пробрасывает** (host UI показывает snackbar).
  /// Части отправляются последовательно, чтобы сохранить порядок картинок.
  Future<void> forwardMessage({
    required int targetRoomId,
    required ChatMessage message,
  }) async {
    // Захватываем rpc локально — пересылка должна пережить возможный
    // dispose исходного контроллера (юзер ушёл с экрана, пока летели RPC).
    // На _disposed НЕ гейтим сами отправки.
    await _forwardOne(_rpc, targetRoomId, message);
  }

  /// **Пересылка пачкой (мультивыбор)** — переслать список [messages]
  /// (каждое — одиночное сообщение ИЛИ anchor-пузырь альбома) в комнату
  /// [targetRoomId]. Поведение «как в Telegram»:
  ///   * сообщения отправляются в порядке возрастания `serverTimestamp`
  ///     (хронология исходного чата сохраняется на целевой стороне),
  ///     **последовательно** (await по очереди) — иначе гонки RPC могли
  ///     бы перемешать порядок;
  ///   * каждый элемент разворачивается через [_forwardOne] (альбом →
  ///     все части, атрибуция первого автора, новый albumId и т.д.).
  ///
  /// **Дедуп по `albumId`**: [_forwardOne] разворачивает альбом целиком из
  /// ЛЮБОГО его члена, поэтому если в выборку случайно попали два члена
  /// одного альбома (в UI выбираются только anchor-пузыри — скрытые члены
  /// не тапабельны, но защищаемся), альбом пересылается один раз.
  ///
  /// RPC-ошибку любой части **пробрасывает** (host UI показывает snackbar);
  /// уже отправленные ранее части остаются — как в Telegram при обрыве.
  Future<void> forwardMessages({
    required int targetRoomId,
    required List<ChatMessage> messages,
  }) async {
    final rpc = _rpc;
    final ordered = List<ChatMessage>.of(messages)
      ..sort((a, b) => a.serverTimestamp.compareTo(b.serverTimestamp));
    final seenAlbums = <String>{};
    for (final message in ordered) {
      final aid = message.albumId;
      // add() == false ⇒ этот albumId уже переслан из другого члена.
      if (aid != null && aid.isNotEmpty && !seenAlbums.add(aid)) {
        continue;
      }
      await _forwardOne(rpc, targetRoomId, message);
    }
  }

  /// **F1: пересылка нескольким получателям сразу** — переслать [messages]
  /// (одиночные и/или альбомы) в КАЖДУЮ из комнат [targetRoomIds]. Внутри
  /// одной комнаты порядок/дедуп альбомов — как в [forwardMessages];
  /// комнаты обходятся последовательно. RPC-ошибку любой комнаты
  /// **пробрасывает** — уже разосланные ранее остаются (как в Telegram при
  /// обрыве). Дубликаты roomId схлопываются (на случай кривого выбора).
  Future<void> forwardMessagesToRooms({
    required List<int> targetRoomIds,
    required List<ChatMessage> messages,
  }) async {
    final seenRooms = <int>{};
    for (final roomId in targetRoomIds) {
      if (!seenRooms.add(roomId)) continue;
      await forwardMessages(targetRoomId: roomId, messages: messages);
    }
  }

  /// Общее тело пересылки ОДНОГО сообщения (или его альбома). Выделено из
  /// [forwardMessage], чтобы [forwardMessages] переиспользовало ту же логику
  /// разворота/атрибуции/albumId без дублирования. [rpc] передаётся явно —
  /// caller захватывает `_rpc` заранее (пересылка должна пережить dispose).
  Future<void> _forwardOne(
    MessagesRpc rpc,
    int targetRoomId,
    ChatMessage message,
  ) async {
    // Развернуть части: альбом → все члены; иначе — одиночное сообщение.
    final aid = message.albumId;
    final parts = (aid != null && aid.isNotEmpty)
        ? albumMembersOf(message)
        : <ChatMessage>[message];

    // Картинки (attachment != null) — по возрастанию времени (порядок
    // отправки в исходном альбоме); подпись(и) без вложения — после.
    final images =
        parts.where((p) => p.attachment != null).toList(growable: false)
          ..sort((a, b) => a.serverTimestamp.compareTo(b.serverTimestamp));
    final captions =
        parts
            .where((p) => p.attachment == null && p.body.trim().isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) => a.serverTimestamp.compareTo(b.serverTimestamp));
    final ordered = <ChatMessage>[...images, ...captions];
    if (ordered.isEmpty) return; // нечего пересылать (напр. tombstone)

    // Атрибуция: сохраняем ПЕРВОГО автора при re-forward.
    final fwdName =
        message.forwardedFromName ??
        message.senderDisplayName ??
        _matrixLocalpart(message.senderMatrixUserId);
    final fwdUid =
        message.forwardedFromMessengerUserId ?? message.senderMessengerUserId;

    // Новый albumId только если целевое сообщение реально станет альбомом
    // (≥2 части: рендер группирует в мозаику лишь при ≥2 членах одного id).
    final newAlbumId = ordered.length >= 2 ? _txnIdGenerator() : null;

    for (final part in ordered) {
      // Issue #41: координаты первоисточника считаем ПО КАЖДОЙ ЧАСТИ, а не
      // по anchor-у: у альбома каждая плитка — отдельное событие в исходной
      // комнате, и тап должен вести на неё, а не на первую из мозаики.
      // Правило первоисточника при re-forward — внутри resolveForwardSource.
      final src = resolveForwardSource(message: part, currentRoomId: _roomId);
      await rpc.sendMessage(
        roomId: targetRoomId,
        body: part.body,
        msgType: part.attachment != null
            ? matrixMsgTypeForMime(part.attachment!.mimeType)
            : 'm.text',
        clientTxnId: _txnIdGenerator(),
        attachment: part.attachment,
        albumId: newAlbumId,
        forwardedFromName: fwdName,
        forwardedFromMessengerUserId: fwdUid,
        forwardedFromRoomId: src?.roomId,
        forwardedFromEventId: src?.eventId,
      );
    }
  }

  /// Локалпарт из Matrix id `@user:server` → `user`. Fallback на исходную
  /// строку, если формат неожиданный. Используется как последний резерв для
  /// «Переслано от X», когда `senderDisplayName` не резолвится.
  static String _matrixLocalpart(String mxid) {
    var s = mxid;
    if (s.startsWith('@')) s = s.substring(1);
    final colon = s.indexOf(':');
    if (colon >= 0) s = s.substring(0, colon);
    return s.isEmpty ? mxid : s;
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
  ///
  /// **OUTBOX**: если у баббла есть строка персистентной очереди —
  /// повторяем ЧЕРЕЗ очередь ([retryOutbox]), а не in-memory путём ниже.
  /// Иначе retry уходил мимо очереди и делал не то: у outbox-баббла
  /// `attachment == null` (mxc ещё не получен), поэтому вложение без
  /// локальных байтов (файл из Share Extension — не картинка) улетало
  /// в `_shootSendRpc` БЕЗ вложения, т.е. в комнату отправлялось
  /// текстовое сообщение с одним именем файла. Строка при этом
  /// оставалась в очереди и дренировалась параллельно.
  Future<void> retry(String clientTxnId) async {
    if (_disposed) return;
    if (isOutboxTxn(clientTxnId)) {
      await retryOutbox(clientTxnId);
      return;
    }
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

    // **Оптимистичный альбом**: член упал на АПЛОАДЕ (байты есть, mxc нет) —
    // пере-загружаем тем же txnId (одноэлементный _uploadAlbumInBackground).
    // Если упал ПОСЛЕ аплоада (attachment уже есть) — обычный re-send ниже.
    final localBytes = failedMsg.localImageBytes;
    if (failedMsg.attachment == null && localBytes != null) {
      await _uploadAlbumInBackground([
        _AlbumUploadEntry(
          txnId: clientTxnId,
          image: PickedAttachment(
            bytes: localBytes,
            // Issue #54: исходный MIME, сохранённый при первой отправке.
            // Fallback на дериват из msgType — только для бабблов, живших
            // до этого фикса (или восстановленных без localMimeType). Сам
            // дериват — из общей таблицы, чтобы не разъехаться с пикером.
            mimeType:
                failedMsg.localMimeType ??
                mimeForMatrixMsgType(failedMsg.msgType),
            originalFilename: failedMsg.body,
          ),
        ),
      ], failedMsg.albumId);
      return;
    }

    await _shootSendRpc(
      clientTxnId: clientTxnId,
      body: failedMsg.body,
      msgType: failedMsg.msgType,
      attachment: failedMsg.attachment,
      replyToMatrixEventId: failedMsg.replyToMessageId,
      mentionedMessengerUserIds: failedMsg.mentionedMessengerUserIds,
      albumId: failedMsg.albumId,
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

  /// **Реконсиляция «пропущенных входящих»**. Зовётся ChatScreen-ом на
  /// возврате сети (`connectionState → healthy`) и на `resumed` lifecycle.
  ///
  /// Проблема: сообщение, пришедшее пока app был в фоне / на cold-start-е
  /// через push, могло проскочить мимо live-стрима (bus ещё не
  /// синхронизирован) и мимо первичной `listMessages` (гонка) → его не
  /// видно до ручного пере-входа в чат. Здесь до-тягиваем свежую страницу
  /// и вставляем недостающие сообщения на ПРАВИЛЬНУЮ (по времени) позицию
  /// — в отличие от live-мёржа [_acceptIncomingInto] (тот всегда вставляет
  /// в topс как newest, что неверно для «старого» пропущенного).
  ///
  /// Best-effort + идемпотентно: дедуп по `matrixEventId`, promote
  /// pending/failed по `clientTxnId`. На ошибке — тихо, следующий
  /// reconnect/resume/пере-вход повторит.
  Future<void> refreshLatest() async {
    if (_disposed) return;
    if (_state.value is! MessagesReady) return; // только когда уже загружено
    MessengerMessageListPage page;
    try {
      page = await _rpc.listMessages(roomId: _roomId, limit: _initialPageSize);
    } catch (_) {
      return;
    }
    if (_disposed) return;
    final cur = _state.value;
    if (cur is! MessagesReady) return;

    final merged = List<ChatMessage>.of(cur.messages);
    final knownEventIds = <String>{
      for (final c in merged)
        if (c.matrixEventId != null) c.matrixEventId!,
    };
    var changed = false;
    // page.messages — DESC (newest first). Идём с конца (oldest→newest),
    // чтобы ordered-insert каждого не сдвигал позиции ещё не вставленных.
    for (final m in page.messages.reversed) {
      // Promote pending/failed по txnId (наш только что отправленный echo).
      final txnId = m.clientTxnId;
      if (txnId != null) {
        final pIdx = merged.indexWhere(
          (c) => c.clientTxnId == txnId && (c.isPending || c.isFailed),
        );
        if (pIdx >= 0) {
          merged[pIdx] = ChatMessage.fromServer(m);
          changed = true;
          continue;
        }
      }
      if (knownEventIds.contains(m.matrixEventId)) continue; // уже есть
      // Вставка на позицию по времени (список DESC: newest→oldest).
      final cm = ChatMessage.fromServer(m);
      var insertAt = merged.indexWhere(
        (c) => c.serverTimestamp.isBefore(cm.serverTimestamp),
      );
      if (insertAt < 0) insertAt = merged.length;
      merged.insert(insertAt, cm);
      knownEventIds.add(m.matrixEventId);
      changed = true;
    }
    // Мёрж синхронный (без await) → `cur` всё ещё актуален.
    if (changed && !_disposed) {
      _state.value = cur.copyWith(messages: merged);
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
      onSendError?.call(e, st);
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
      onSendError?.call(e, st);
      rethrow;
    }
  }

  /// **TASK38**: создать задачу во внешнем таск-трекере из сообщения.
  /// Тонкий pass-through к RPC — message-list не меняет (подтверждение
  /// прилетает как `@nsg-system` сообщение через realtime, если интеграция
  /// его постит). Бросает [TaskIntegrationNotConfiguredException] если
  /// выключена; action-sheet показывает snackbar по результату/ошибке.
  Future<TaskLink> createTaskFromMessage({
    required String matrixEventId,
    required String body,
  }) {
    return _rpc.createTaskFromMessage(
      roomId: _roomId,
      matrixEventId: matrixEventId,
      body: body,
    );
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
    await _outboxSub?.cancel();
    _outboxSub = null;
    _initBuffer = null;
    _state.dispose();
    _replyTarget.dispose();
    _typingPeers.dispose();
    _readReceiptsVersion.dispose();
    _reactionsVersion.dispose();
    _pinned.dispose();
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

    // **Issue #35**: закрепление изменилось (this или другое устройство/
    // участник). Payload — полный список pinnedEventIds. message=null.
    if (event.eventType == MessengerEventType.pinnedMessagesChanged) {
      if (event.roomId != _roomId) return;
      _handlePinnedChanged(event);
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
        // **Оптимистичный альбом**: если у promote-ящегося пузыря были
        // локальные байты (грузящаяся картинка), пробрасываем их в
        // fromServer — плитка не мигнёт «байты → пусто → сеть», пока
        // подтягивается thumbnail из mxc.
        final prevLocal = target[pendingIdx].localImageBytes;
        target[pendingIdx] = ChatMessage.fromServer(
          m,
          overrideLocalImageBytes: prevLocal,
        );
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

  // ─── OUTBOX: рендер + реконсиляция персистентной очереди ───────────

  /// **OUTBOX**: перечитать очередь комнаты и синхронизировать pending-
  /// бабблы. Зовётся в конце init() и на каждое `outboxRoomChanges` события
  /// для этой комнаты. Best-effort — ошибки не ломают чат.
  Future<void> _refreshOutbox() async {
    final cache = _cache;
    if (cache == null || _disposed) return;
    List<OutboxItem> rows;
    try {
      rows = await cache.outboxForRoom(_roomId);
    } catch (_) {
      return;
    }
    if (_disposed) return;
    // Для image-вложений подгружаем локальные байты (мозаика видна сразу).
    final imageBytes = <String, Uint8List>{};
    for (final item in rows) {
      if (item.isAttachment &&
          item.attachmentPath != null &&
          (item.mimeType?.startsWith('image/') ?? false)) {
        try {
          imageBytes[item.clientTxnId] = await File(
            item.attachmentPath!,
          ).readAsBytes();
        } catch (_) {
          // файл мог быть удалён — покажем без превью.
        }
      }
    }
    if (_disposed) return;
    _syncOutbox(rows, imageBytes);
  }

  /// **OUTBOX**: влить строки очереди в state как pending/failed бабблы.
  ///
  /// Дедуп по `clientTxnId`: если реальное (sent) сообщение с этим txnId уже
  /// в ленте — НЕ дублируем (оно уже приехало через sync). Инъекции трекаем
  /// в [_outboxTxnIds], чтобы снять исчезнувшие (discard / доставлено).
  void _syncOutbox(List<OutboxItem> rows, Map<String, Uint8List> imageBytes) {
    final current = _state.value;
    if (current is! MessagesReady) return;
    final newTxnIds = {for (final r in rows) r.clientTxnId};
    final messages = List<ChatMessage>.of(current.messages);
    var changed = false;

    // 1. Снять ранее инъецированные бабблы, которых больше нет в очереди
    //    (discard или доставлено-и-промоутнуто). Промоутнутые в sent НЕ
    //    трогаем (isPending/isFailed-гард).
    messages.removeWhere((m) {
      final txn = m.clientTxnId;
      if (txn == null) return false;
      final gone = _outboxTxnIds.contains(txn) && !newTxnIds.contains(txn);
      if (gone && (m.isPending || m.isFailed)) {
        changed = true;
        return true;
      }
      return false;
    });

    // 2. Влить/обновить строки очереди.
    for (final item in rows) {
      final idx = messages.indexWhere((m) => m.clientTxnId == item.clientTxnId);
      if (idx >= 0) {
        final existing = messages[idx];
        // Реальное сообщение уже приехало (sent) — не трогаем, sync-путь
        // сам его отрисовал; строка очереди вот-вот удалится sender-ом.
        if (existing.isSent) continue;
        // Обновляем статус (напр. pending → failed) из строки очереди.
        final rebuilt = _outboxToBubble(item, imageBytes[item.clientTxnId]);
        if (existing.status != rebuilt.status) {
          messages[idx] = rebuilt;
          changed = true;
        }
      } else {
        messages.insert(0, _outboxToBubble(item, imageBytes[item.clientTxnId]));
        changed = true;
      }
    }

    _outboxTxnIds
      ..clear()
      ..addAll(newTxnIds);
    if (changed) _state.value = current.copyWith(messages: messages);
  }

  /// **OUTBOX**: строка очереди → ChatMessage-баббл (pending либо failed).
  ChatMessage _outboxToBubble(OutboxItem item, Uint8List? imageBytes) {
    final base = ChatMessage.optimistic(
      clientTxnId: item.clientTxnId,
      senderMatrixUserId: _selfMatrixUserId,
      senderMessengerUserId: _selfMessengerUserId,
      body: item.body,
      msgType: item.msgType,
      serverTimestamp: DateTime.fromMillisecondsSinceEpoch(
        item.createdAt,
      ).toUtc(),
      replyToMessageId: item.replyToMatrixEventId,
      mentionedMessengerUserIds: item.mentionedMessengerUserIds,
      albumId: item.albumId,
      localImageBytes: imageBytes,
    );
    return item.isFailed ? base.failed(item.lastError ?? 'send failed') : base;
  }

  /// **OUTBOX**: стоит ли за бабблом строка персистентной очереди (а не
  /// in-memory отправка контроллера). Гейт для UI-действий «повторить» и
  /// «отменить отправку»: у in-memory баббла строки нет, и
  /// [discardOutbox] для него был бы мёртвой кнопкой. Требует живого
  /// [OutboxSender] — без него обе операции no-op.
  bool isOutboxTxn(String? clientTxnId) =>
      _outbox != null &&
      clientTxnId != null &&
      _outboxTxnIds.contains(clientTxnId);

  /// **OUTBOX**: повторить failed-строку очереди (сброс в pending + kick
  /// дренажа). Баббл обновится через `outboxRoomChanges`.
  Future<void> retryOutbox(String clientTxnId) async {
    if (_disposed) return;
    await _outbox?.retry(clientTxnId);
  }

  /// **OUTBOX**: отменить строку очереди (удалить файл + строку). Баббл
  /// снимется через `outboxRoomChanges`.
  Future<void> discardOutbox(String clientTxnId) async {
    if (_disposed) return;
    await _outbox?.discard(clientTxnId);
  }

  Future<void> _shootSendRpc({
    required String clientTxnId,
    required String body,
    required String msgType,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
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
          albumId: albumId,
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
          // Issue #54: `break` уходил ДО всех debugPrint-ов ниже, поэтому
          // permanent-сбой не оставлял в логе ни строки. Логируем здесь.
          if (kDebugMode) {
            debugPrint(
              '[MessagesController.room=$_roomId] send permanent '
              '(txn=$clientTxnId, msgType=$msgType): $e',
            );
          }
          break;
        }
        // **TASK47 (outbox для композера, 2026-07-12)**: ТЕКСТ при
        // транзиентном (сетевом) сбое уходит в персистентную очередь
        // сразу — она переживает kill приложения и длинный офлайн (in-
        // memory retry жил ~1 мин и терял сообщение при закрытии).
        // Баббл остаётся pending (тот же clientTxnId: _syncOutbox его
        // не задублирует, доставку сделает OutboxSender, промоут в sent
        // придёт через /sync). Вложения — прежний in-memory путь
        // (AttachmentRef уже загружен, переупаковка в outbox — отдельно).
        if (attachment == null && albumId == null && _outbox != null) {
          try {
            await _outbox.enqueueText(
              roomId: _roomId,
              clientTxnId: clientTxnId,
              body: body,
              msgType: msgType,
              mentionedMessengerUserIds: mentionedMessengerUserIds,
              replyToMatrixEventId: replyToMatrixEventId,
            );
            if (kDebugMode) {
              debugPrint(
                '[MessagesController.room=$_roomId] send transient → '
                'персистентный outbox (txn=$clientTxnId): $e',
              );
            }
            return; // очередь доставит; баббл ведёт _syncOutbox.
          } catch (enqueueErr) {
            // Кэш/БД недоступны — продолжаем прежний in-memory retry.
            if (kDebugMode) {
              debugPrint(
                '[MessagesController.room=$_roomId] outbox enqueue failed '
                '($enqueueErr) — fallback на in-memory retry',
              );
            }
          }
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
      onSendError?.call(lastError, lastStack ?? StackTrace.current);
    }
  }

  /// **B10**: классификатор «transient vs permanent» для send-retry.
  /// Делегирует в общий [isTransientSendError] (тот же код используется
  /// [OutboxSender] для персистентной очереди).
  bool _isTransientSendError(Object error) => isTransientSendError(error);

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

/// **Оптимистичный альбом**: одна единица фонового аплоада — связка
/// `clientTxnId` (id pending-пузыря) + исходные байты/MIME/имя для
/// `uploadAttachment`. Хранится только на время последовательного
/// аплоада, потом отбрасывается.
class _AlbumUploadEntry {
  const _AlbumUploadEntry({required this.txnId, required this.image});
  final String txnId;
  final PickedAttachment image;
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
