import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show RoomDetails, RoomParticipant, RoomType;

import '../i18n/connection_lost_banner.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messages/attachments/attachment_picker.dart';
import '../messages/attachments/mxc_image_provider.dart';
import '../messages/chat_message.dart';
import '../messages/message_action_sheet.dart';
import '../messages/message_bubble.dart';
import '../messages/message_composer.dart';
import '../messages/messages_controller.dart';
import '../messages/messages_rpc.dart';
import '../messages/messages_state.dart';
import '../messenger_runtime.dart';
import '../widgets/nsg_avatar_image.dart';
import 'group_settings_screen.dart';

/// Экран чата (TASK15 Chunk 2).
///
/// Lifecycle:
///   * `initState`: создаём (или принимаем извне) [MessagesController]
///     для `roomId`, зовём `init()`. Subscribe-before-fetch +
///     2-layer dedup живут в controller-е.
///   * `dispose`: гасим controller (cancel-stream + state.dispose).
///
/// UI:
///   * `ListView.builder(reverse: true)` — newest at bottom (DESC
///     порядок в `state.messages` совпадает с reverse-render-ом:
///     index 0 → bottom). loadMore вызывается через
///     `NotificationListener<ScrollNotification>` когда докрутили
///     близко к верху списка (в reversed listview — `maxScrollExtent`).
///   * `MessageComposer` снизу. Disabled пока state ≠ Ready —
///     enforce-ит контракт sendMessage из controller-doc-а
///     (избегаем visual flicker pending bubble).

/// Сигнатура `setPresence` callback для [ChatScreen]
/// `@visibleForTesting setPresenceOverride`. Зеркало
/// `client.messenger.setPresence`.
typedef SetPresenceOverride =
    Future<void> Function({int? currentRoomId, required bool foreground});

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.roomId,
    this.readOnly = false,
    @visibleForTesting this.controllerOverride,
    @visibleForTesting this.setPresenceOverride,
    @visibleForTesting this.loadMoreThresholdPxOverride,
  });

  final int roomId;

  /// **TASK22-Phase2 Chunk 2**: when true, `MessageComposer` is hidden
  /// — used by demo / view-only contexts (`NsgMessenger.demoChatScreen`
  /// in the theming sandbox). Long-press / action sheet still trigger
  /// edit/delete logic at the controller layer, but in demo mode the
  /// RPC throws `UnimplementedError` so the action sheet's destructive
  /// items are effectively inert.
  final bool readOnly;

  /// Visible-for-testing: позволяет widget-тестам подменить production
  /// runtime-зависимый MessagesController на test-instance с
  /// in-memory rpc + event bus. В production не передаётся —
  /// ChatScreen строит controller из `MessengerRuntime.instance`.
  final MessagesController? controllerOverride;

  /// **TASK20 Chunk 4-prep**: visible-for-testing setPresence callback
  /// для widget-тестов lifecycle observer-а. Если передан — используется
  /// вместо `MessengerRuntime.instance.client.messenger.setPresence`.
  final SetPresenceOverride? setPresenceOverride;

  /// **TASK22-Phase2 Chunk 1-B**: visible-for-testing override of
  /// load-more pagination threshold (px). В production читается из
  /// `MessengerRuntime.instance.config.scrollThresholds.chatLoadMorePx`.
  /// Widget-тесты передают явное значение, чтобы не зависеть от
  /// инициализированного runtime singleton (controllerOverride-flow
  /// идёт без runtime).
  final double? loadMoreThresholdPxOverride;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final MessagesController _controller;
  late final bool _ownsController;

  /// Пиксельный порог от верха reversed-listview, при достижении
  /// которого зовём loadMore. Default 200px = чуть меньше одной
  /// screen-page — подгрузка стартует когда юзер ещё видит контент,
  /// чтобы скролл был непрерывным.
  ///
  /// **TASK22-Phase2 Chunk 1-B**: host-app может tune через
  /// `NsgMessengerConfig.scrollThresholds.chatLoadMorePx` (передаётся в
  /// `NsgMessenger.init(config: ...)`). `loadMoreThresholdPxOverride`
  /// — для widget-тестов; `controllerOverride`-flow означает test
  /// без runtime singleton, поэтому fallback на hardcoded 200.
  double get _loadMoreThresholdPx =>
      widget.loadMoreThresholdPxOverride ??
      (widget.controllerOverride == null
          ? MessengerRuntime.instance.config.scrollThresholds.chatLoadMorePx
          : 200);

  /// Debounce для auto-markRead на новые сообщения в открытом чате
  /// (TASK18). 500ms — компромисс: достаточно мало чтобы badge сразу
  /// сбросился, достаточно много чтобы burst из 5+ сообщений вызвал
  /// один markRead. Первый Ready переход (chat just opened) — БЕЗ
  /// debounce-а, fire-immediately, иначе «opened+swiped» edge case
  /// оставит unread (см. ревью plan TASK18 #Q3).
  static const Duration _markReadDebounce = Duration(milliseconds: 500);

  Timer? _markReadTimer;
  bool _firstReady = true;
  String? _lastMarkReadEventId;

  /// **TASK16-A**: участники комнаты (TASK13 30-cap). Загружаются один
  /// раз в initState через `MessengerRuntime.instance.rooms.get(roomId)`
  /// — cached LRU там же. Используются:
  ///   * для `MessageBubble` — index-ы для mention highlighting + reply
  ///     chip sender displayName.
  ///   * для `MessageComposer` — `@`-typeahead source.
  /// Null пока не загружено / в test-mode без runtime — fallback на
  /// no-mention-styling (acceptable degraded UX).
  RoomDetails? _roomDetails;
  Map<int, RoomParticipant>? _participantsByMessengerId;
  Map<String, RoomParticipant>? _participantsByMatrixId;

  /// **TASK16-A**: ScrollController используем чтобы реализовать
  /// best-effort scroll-to-original при tap по reply chip. Per Q1 —
  /// MVP только если original в текущем preloaded окне; pre-paginated
  /// → silent no-op.
  final ScrollController _scrollController = ScrollController();

  /// Контролируем actual itemPositions через ключи на каждом item
  /// (ListView.builder + GlobalKey per matrixEventId). Memory-cap —
  /// keys держатся пока в state.messages. Acceptable для MVP roomы
  /// с pageSize 50 + paginate.
  final Map<String, GlobalKey> _itemKeys = {};

  /// **B12 (BACKLOG)**: ChatMessage в режиме редактирования (через
  /// ↑-arrow shortcut в composer-е, либо через action sheet «Edit»
  /// — TASK37). Composer pre-populate-ит body и отправляет через
  /// `_edit` callback. `null` = обычный send-mode.
  final ValueNotifier<ChatMessage?> _editTarget = ValueNotifier(null);

  /// **B17 search persistence + nav-bar**: текущее состояние поиска
  /// в этом ChatScreen. Сохраняется между открытиями search-экрана
  /// (юзер вернулся → видит тот же query+результаты) И используется
  /// для overlay-бара с prev/next/close после tap-а на результат.
  ///
  /// `_searchResults.isEmpty` ↔ overlay скрыт. Order: DESC по
  /// `serverTimestamp` (как возвращает Matrix /search + наш fallback).
  List<ChatMessage> _searchResults = const [];
  int _searchActiveIdx = -1;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final injected = widget.controllerOverride;
    if (injected != null) {
      _controller = injected;
      _ownsController = false;
    } else {
      final runtime = MessengerRuntime.instance;
      _controller = MessagesController(
        roomId: widget.roomId,
        rpc: ClientMessagesRpc(runtime.client),
        events: runtime.eventBus.events,
        selfMessengerUserId: runtime.session.messengerUserId,
        selfMatrixUserId: runtime.session.matrixUserId,
      );
      _ownsController = true;
    }
    _controller.stateListenable.addListener(_onStateChange);
    _controller.init();
    _fetchRoomDetails();
    // **TASK20 Chunk 4-prep**: presence lifecycle observer — fix race
    // из ревью TASK20 Chunk 2 28e343f #1. Bus's `onAppLifecycleChanged`
    // на `resumed` шлёт `setPresence(currentRoomId: null, foreground:
    // true)` (он не знает про active ChatScreen). ChatScreen после
    // получает `didChangeAppLifecycleState(resumed)` и re-шлёт
    // `setPresence(currentRoomId: widget.roomId, foreground: true)` —
    // последний writer wins, server-side cache корректно отражает
    // foreground-room. Без этого re-write push-routing skip foreground
    // room ломается на каждом app-resume.
    WidgetsBinding.instance.addObserver(this);
    // Initial fire — set currentRoomId на open (cold-start case +
    // navigation между rooms без app-resume).
    _firePresence(currentRoomId: widget.roomId, foreground: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Race fix: bus's lifecycle handler уже отправил setPresence с
      // currentRoomId=null. Re-overwrite с актуальным roomId.
      _firePresence(currentRoomId: widget.roomId, foreground: true);
    }
  }

  Future<void> _firePresence({
    int? currentRoomId,
    required bool foreground,
  }) async {
    final fn =
        widget.setPresenceOverride ??
        (widget.controllerOverride == null
            ? MessengerRuntime.instance.client.messenger.setPresence
            : null);
    if (fn == null) return;
    try {
      await fn(currentRoomId: currentRoomId, foreground: foreground);
    } catch (_) {
      // Fire-and-forget: errors не блокируют UI; lifecycle handler в
      // bus уже логирует свой `setPresence` failure (TTL 60s server-
      // side подстраховывает).
    }
  }

  /// **TASK16-A**: подгрузка participants для mention typeahead +
  /// reply chip resolution. Не блокирует render — bubble / composer
  /// degrade gracefully когда `_participantsByMessengerId == null`.
  Future<void> _fetchRoomDetails() async {
    // В test-mode (`controllerOverride` set) MessengerRuntime может быть
    // не инициализирован — skip silently. Production flow всегда имеет
    // runtime после init.
    if (widget.controllerOverride != null) return;
    try {
      final rooms = MessengerRuntime.instance.rooms;
      final details = await rooms.get(widget.roomId);
      if (!mounted) return;
      setState(() {
        _roomDetails = details;
        _participantsByMessengerId = {
          for (final p in details.participants) p.messengerUserId: p,
        };
        _participantsByMatrixId = {
          for (final p in details.participants) p.matrixUserId: p,
        };
      });
    } catch (_) {
      // Tolerable: bubble без mention-styling, composer без typeahead.
      // Reply / send всё ещё работают.
    }
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    _editTarget.dispose();
    _scrollController.dispose();
    _controller.stateListenable.removeListener(_onStateChange);
    WidgetsBinding.instance.removeObserver(this);
    // **TASK20 Chunk 4-prep**: clear currentRoomId на close — иначе
    // server-side presence-cache держит stale `currentRoomId=widget
    // .roomId` 60s после navigation away, и push-routing будет
    // ошибочно считать пользователя «в этой комнате» → suppress
    // notifications которые он должен получить.
    _firePresence(currentRoomId: null, foreground: true);
    if (_ownsController) {
      // Fire-and-forget — Future<void> dispose; виджет уже unmounted-ится,
      // нам важно cancel-нуть subscription, остальное cleanup-ится sync.
      _controller.dispose();
    }
    super.dispose();
  }

  /// Обрабатывает каждое изменение `MessagesState` для auto-markRead
  /// (TASK18). Триггерит markRead с newest matrixEventId в state:
  ///   * **Первый** переход в Ready (chat just opened) — fire IMMEDIATELY,
  ///     без debounce-а: «opened+swiped» edge case иначе оставил бы
  ///     unread non-zero (ревью plan #Q3).
  ///   * Subsequent изменения (новые сообщения через realtime stream
  ///     ИЛИ own send promote) — debounced 500ms; burst из N coalesce-ится
  ///     в один markRead с newest event id.
  /// Дедуп через `_lastMarkReadEventId`: если newest id уже передан в
  /// markRead, не дёргаем сервер второй раз (markRead идемпотентен,
  /// но избегаем holiday ridicule traffic).
  void _onStateChange() {
    final state = _controller.state;
    if (state is! MessagesReady) return;
    if (state.messages.isEmpty) return;
    // Newest message в DESC list — index 0 (для reverse listview =
    // bottom of screen). Skip pending — у него matrixEventId == null,
    // markRead не имеет смысла.
    final newest = state.messages.firstWhere(
      (m) => m.matrixEventId != null,
      orElse: () => state.messages.first,
    );
    final eventId = newest.matrixEventId;
    if (eventId == null) return;
    if (eventId == _lastMarkReadEventId) return;

    if (_firstReady) {
      _firstReady = false;
      _lastMarkReadEventId = eventId;
      _markReadTimer?.cancel();
      // Fire IMMEDIATELY на первом Ready.
      unawaited(_controller.markRead(eventId));
      return;
    }

    // Subsequent — debounce 500ms.
    _markReadTimer?.cancel();
    _markReadTimer = Timer(_markReadDebounce, () {
      _lastMarkReadEventId = eventId;
      unawaited(_controller.markRead(eventId));
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) {
      return false;
    }
    final metrics = n.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - _loadMoreThresholdPx) {
      // В reversed=true listview maxScrollExtent — это «начало»
      // списка (старые сообщения). Триггерим загрузку OLDER.
      _controller.loadMore();
    }
    return false;
  }

  /// **TASK16-A**: composer передаёт `mentionedMessengerUserIds` +
  /// (опционально) reply target из текущего state. Reply id берём
  /// из `_controller.replyTarget` (composer сам не знает eventId —
  /// он рендерит quote chip из value listener-а).
  Future<void> _send(
    String body, {
    List<int>? mentionedMessengerUserIds,
  }) async {
    final reply = _controller.replyTarget;
    await _controller.sendMessage(
      body: body,
      replyToMatrixEventId: reply?.matrixEventId,
      mentionedMessengerUserIds: mentionedMessengerUserIds,
    );
  }

  /// **B12**: commit edit. После apply — `_editTarget = null`, composer
  /// возвращается в обычный send-mode (через ValueListenable rebuild).
  Future<void> _edit(
    String matrixEventId,
    String newBody, {
    List<int>? mentionedMessengerUserIds,
  }) async {
    try {
      await _controller.editMessage(
        matrixEventId: matrixEventId,
        newBody: newBody,
        mentionedMessengerUserIds: mentionedMessengerUserIds,
      );
    } finally {
      if (mounted) _editTarget.value = null;
    }
  }

  /// **B12**: ↑-arrow shortcut в пустом composer-е. Резолвим
  /// last own sent через controller, выставляем `_editTarget` →
  /// composer переходит в edit-mode.
  void _requestEditLast() {
    final last = _controller.lastOwnSentMessage;
    if (last == null) return;
    _editTarget.value = last;
  }

  void _cancelEdit() {
    _editTarget.value = null;
  }

  /// **B15 rename + B16 group settings**: tap по AppBar title.
  ///
  /// * Direct chat → silent ignore (см. doc у `_RoomTitle`).
  /// * Group → push [GroupSettingsScreen]; экран сам предлагает
  ///   rename (через callback ниже), список участников, кнопку
  ///   «Добавить участников». После возврата делаем `_fetchRoomDetails`
  ///   — заголовок мог поменяться, или мог добавиться участник.
  Future<void> _onTitleTap() async {
    final details = _roomDetails;
    if (details == null) return;
    if (details.roomType == RoomType.direct) return;
    if (widget.controllerOverride != null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupSettingsScreen(
          roomId: widget.roomId,
          onRequestRename: _showRenameDialogAndApply,
        ),
      ),
    );
    if (!mounted) return;
    // Settings экран мог изменить name / participants; refresh title.
    await _fetchRoomDetails();
  }

  /// Открывает rename dialog и применяет результат. Вызывается из
  /// `GroupSettingsScreen` по тапу на name-row. Возвращает `true` если
  /// rename успешен (settings экран пере-загрузит details).
  Future<bool?> _showRenameDialogAndApply(
    BuildContext context,
    String currentName,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameRoomDialog(initialName: currentName),
    );
    if (newName == null || newName.isEmpty) return false;
    if (!context.mounted) return false;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    try {
      await MessengerRuntime.instance.rooms.renameRoom(
        roomId: widget.roomId,
        newName: newName,
      );
      return true;
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.roomRenameFailed),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  /// **TASK19 Chunk 3**: media attachment send. Errors → snackbar
  /// (server reject MIME / oversized / network blip). Optimistic
  /// bubble уже виден к моменту complete; failure auto-revert
  /// внутри controller (failed status).
  Future<void> _sendAttachment(PickedAttachment picked) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    try {
      await _controller.sendAttachment(
        bytes: picked.bytes,
        mimeType: picked.mimeType,
        originalFilename: picked.originalFilename,
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.attachUploadFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _retry(ChatMessage m) {
    final txnId = m.clientTxnId;
    if (txnId == null) return;
    _controller.retry(txnId);
  }

  /// **TASK37 Chunk 2**: long-press на bubble → action sheet (Edit/
  /// Delete/Copy). `isOwn` derive-ится в `_Loaded` и пробрасывается —
  /// MessageBubble сам не вычисляет (consistency с rendering layout).
  void _onLongPressMessage(ChatMessage m, bool isOwn) {
    showMessageActionSheet(
      context: context,
      message: m,
      isOwn: isOwn,
      controller: _controller,
    );
  }

  /// **TASK16-A**: best-effort scroll-to-original при tap по reply chip.
  /// Per Q1 — MVP только если original виден в state.messages (cache hit
  /// в lookup). Phase2 — fetch + scroll, см. backlog.
  void _scrollToOriginal(String matrixEventId) {
    final key = _itemKeys[matrixEventId];
    final ctx = key?.currentContext;
    if (ctx == null) return; // not visible — silent no-op (MVP).
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      alignment: 0.5,
    );
  }

  /// **TASK16-A**: lookup для Reply chip target — wrap controller.
  ChatMessage? _findReplyTarget(String matrixEventId) =>
      _controller.findByEventId(matrixEventId);

  /// **B17 search-in-room**: открывает overlay поиска. На pop — если
  /// был выбран результат, сохраняем (results, query, idx) для overlay
  /// nav-bar и scroll-имся к message-у.
  ///
  /// **State persistence**: передаём `_lastSearchQuery` и `_searchResults`
  /// в search screen — юзер видит тот же набор / поле уже заполнено.
  ///
  /// **Title-spinner fix**: если `_roomDetails == null` к моменту
  /// возврата (cache TTL истёк / network blip), повторно дёргаем
  /// `_fetchRoomDetails` — иначе `_RoomTitle` показывает spinner.
  Future<void> _openSearchScreen() async {
    final picked = await Navigator.of(context).push<_SearchPick>(
      MaterialPageRoute(
        builder: (_) => _SearchInRoomScreen(
          controller: _controller,
          participantsByMatrixId: _participantsByMatrixId,
          initialQuery: _lastSearchQuery,
          initialResults: _searchResults,
        ),
      ),
    );
    if (!mounted) return;
    if (_roomDetails == null) {
      unawaited(_fetchRoomDetails());
    }
    if (picked == null) return;
    setState(() {
      _searchResults = picked.results;
      _searchActiveIdx = picked.activeIndex;
      _lastSearchQuery = picked.query;
    });
    final target = picked.results[picked.activeIndex];
    final eventId = target.matrixEventId;
    if (eventId == null) return;
    await _scrollToSearchResult(eventId);
  }

  /// **B17 search nav-bar**: следующий результат (по DESC list ↦ older).
  Future<void> _searchNext() async {
    if (_searchActiveIdx + 1 >= _searchResults.length) return;
    setState(() => _searchActiveIdx++);
    final id = _searchResults[_searchActiveIdx].matrixEventId;
    if (id != null) await _scrollToSearchResult(id);
  }

  /// **B17 search nav-bar**: предыдущий результат (newer).
  Future<void> _searchPrev() async {
    if (_searchActiveIdx <= 0) return;
    setState(() => _searchActiveIdx--);
    final id = _searchResults[_searchActiveIdx].matrixEventId;
    if (id != null) await _scrollToSearchResult(id);
  }

  /// Закрыть overlay-бар. Query НЕ очищается — `_lastSearchQuery`
  /// сохраняется, чтобы при повторном open-е search-экрана юзер видел
  /// предыдущий запрос.
  void _searchClose() {
    setState(() {
      _searchResults = const [];
      _searchActiveIdx = -1;
    });
  }

  /// **B17 search**: расширенный scroll-to-target. Search возвращает
  /// сообщения, которые могут быть СТАРШЕ текущего loaded окна — обычный
  /// `_scrollToOriginal` (поиск GlobalKey по уже-отрендеренным items)
  /// тогда silent-miss-ит.
  ///
  /// Алгоритм:
  ///   1. Если target уже в state.messages — scroll сразу.
  ///   2. Иначе — циклически `loadMore` страницы (cap 15 страниц = 750
  ///      сообщений), после каждой проверяя `findByEventId`. На success
  ///      — wait 1 frame чтобы ListView построил item с GlobalKey,
  ///      потом scroll.
  ///   3. Если страницы закончились (`hasMore == false`) или cap
  ///      исчерпан — snackbar «не удалось перейти».
  Future<void> _scrollToSearchResult(String matrixEventId) async {
    const maxPages = 15;
    for (var attempt = 0; attempt <= maxPages; attempt++) {
      if (!mounted) return;
      final found = _controller.findByEventId(matrixEventId);
      if (found != null) {
        // Дать ListView собрать item (рендерится при следующем frame
        // если только что появился в state.messages).
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final key = _itemKeys[matrixEventId];
        final ctx = key?.currentContext;
        if (ctx != null && ctx.mounted) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            alignment: 0.3, // target ближе к верху видимой области
            curve: Curves.easeOut,
          );
          return;
        }
        // Item есть в state, но ListView ещё не построил key — даём
        // следующий frame и пробуем снова (loop через outer iteration).
      }
      // Target нет в state — пробуем подгрузить older page.
      final state = _controller.state;
      if (state is! MessagesReady || !state.hasMore) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text(
                'Сообщение слишком далеко в истории — не удалось перейти.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      await _controller.loadMore();
    }
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Не удалось перейти к сообщению.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// **B11 group receipts**: открыть bottom-sheet со списком «прочитали /
  /// не прочитали» для конкретного own message. Доступ к деталям
  /// (per-user list) ограничен группами `<= kReadReceiptsDetailedMax`
  /// участников; для бо́льших — sheet показывает только агрегированное
  /// число (privacy + perf, см. B11 #2 пользовательский ответ).
  void _openReadReceiptsSheet(ChatMessage message) {
    final details = _roomDetails;
    if (details == null) return;
    final readerMxids = _controller.readByPeerMatrixIds(message);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReadReceiptsSheet(
        details: details,
        readerMatrixIds: readerMxids,
        selfMatrixUserId: _controller.selfMatrixUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // **B15 rename**: title показывает room.name из RoomDetails
        // (через `_fetchRoomDetails`). Для group-чатов тап по title
        // открывает edit-dialog (только для admin-ов; не-admin получит
        // server-side InsufficientPowerException, которую мы поймаем
        // и покажем snackbar). Для direct — tap игнорируется (rename
        // direct == rename peer-а, semantic нелепый).
        //
        // В test-mode (`controllerOverride != null`) `_fetchRoomDetails`
        // не вызывается — `_roomDetails` остаётся null. Показываем
        // plain fallback вместо вечного spinner-а, чтобы существующие
        // chat_screen-widget-тесты не ломались.
        title: widget.controllerOverride != null && _roomDetails == null
            ? Text('Room #${widget.roomId}')
            : _RoomTitle(
                details: _roomDetails,
                fallbackRoomId: widget.roomId,
                onTap: _onTitleTap,
              ),
        actions: [
          if (widget.controllerOverride == null)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Поиск',
              onPressed: _openSearchScreen,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_searchResults.isNotEmpty)
            _SearchNavBar(
              query: _lastSearchQuery,
              activeIndex: _searchActiveIdx,
              totalCount: _searchResults.length,
              onPrev: _searchActiveIdx > 0 ? _searchPrev : null,
              onNext: _searchActiveIdx < _searchResults.length - 1
                  ? _searchNext
                  : null,
              onClose: _searchClose,
            ),
          Expanded(
            child: ValueListenableBuilder<MessagesState>(
              valueListenable: _controller.stateListenable,
              // **B11**: read-receipt version triggers rebuild когда
              // peer прочитал что-то новое. Nested ValueListenableBuilder —
              // дёшево, ListView.builder сам решает какие items
              // перерисовывать.
              builder: (context, state, _) => ValueListenableBuilder<int>(
                valueListenable: _controller.readReceiptsVersionListenable,
                builder: (context, _, _) => _Body(
                  state: state,
                  selfMessengerUserId: _controller.selfMessengerUserId,
                  onScroll: _onScroll,
                  onRetry: _retry,
                  onLongPressMessage: _onLongPressMessage,
                  scrollController: _scrollController,
                  itemKeys: _itemKeys,
                  findReplyTarget: _findReplyTarget,
                  onReplyChipTap: _scrollToOriginal,
                  participantsByMessengerId: _participantsByMessengerId,
                  participantsByMatrixId: _participantsByMatrixId,
                  readByPeerCountFor: (m) =>
                      _controller.readByPeerMatrixIds(m).length,
                  isGroupChat:
                      _roomDetails?.roomType == RoomType.group,
                  onTapReadStatus: _openReadReceiptsSheet,
                  thumbnailRpc:
                      ({required String mxcUrl, int? width, int? height}) =>
                          _controller.downloadThumbnail(
                            mxcUrl: mxcUrl,
                            width: width,
                            height: height,
                          ),
                  fullSizeRpc: ({required String mxcUrl}) =>
                      _controller.downloadFullSize(mxcUrl: mxcUrl),
                ),
              ),
            ),
          ),
          // **TASK22-Phase2 Chunk 2**: hide composer entirely in read-
          // only / demo mode. Without this the demo would crash on
          // first send (RPC throws UnimplementedError).
          if (!widget.readOnly) ...[
            // **B9 typing indicator footer** — ровно над composer-ом.
            // Hidden когда никто не печатает (Set пуст).
            ValueListenableBuilder<Set<String>>(
              valueListenable: _controller.typingPeersListenable,
              builder: (context, typing, _) {
                if (typing.isEmpty) return const SizedBox.shrink();
                return _TypingFooter(
                  matrixUserIds: typing.toList(),
                  participantsByMatrixId: _participantsByMatrixId,
                );
              },
            ),
            ValueListenableBuilder<MessagesState>(
              valueListenable: _controller.stateListenable,
              builder: (context, state, _) =>
                  ValueListenableBuilder<ChatMessage?>(
                    valueListenable: _controller.replyTargetListenable,
                    builder: (context, replyTarget, _) =>
                        ValueListenableBuilder<ChatMessage?>(
                          valueListenable: _editTarget,
                          builder: (context, editTarget, _) {
                            final senderName = replyTarget == null
                                ? null
                                : (_participantsByMatrixId?[replyTarget
                                              .senderMatrixUserId]
                                          ?.displayName ??
                                      replyTarget.senderMatrixUserId);
                            return MessageComposer(
                              onSend: _send,
                              enabled: state is MessagesReady,
                              onSendAttachment: _sendAttachment,
                              // Reply hidden когда композер в edit-mode —
                              // одновременно они не активны.
                              replyTarget: editTarget == null
                                  ? replyTarget
                                  : null,
                              onCancelReply: replyTarget == null
                                  ? null
                                  : _controller.clearReplyTarget,
                              participants: _roomDetails?.participants,
                              totalParticipants:
                                  _roomDetails?.totalParticipants,
                              replyTargetSenderName: senderName,
                              // **B12** edit-mode wiring.
                              editTarget: editTarget,
                              onEdit: _edit,
                              onCancelEdit: editTarget == null
                                  ? null
                                  : _cancelEdit,
                              onRequestEditLast: _requestEditLast,
                              onTyping: _controller.sendTyping,
                            );
                          },
                        ),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.selfMessengerUserId,
    required this.onScroll,
    required this.onRetry,
    required this.onLongPressMessage,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.scrollController,
    required this.itemKeys,
    required this.findReplyTarget,
    required this.onReplyChipTap,
    required this.participantsByMessengerId,
    required this.participantsByMatrixId,
    this.readByPeerCountFor,
    this.isGroupChat = false,
    this.onTapReadStatus,
  });

  final MessagesState state;

  /// Передаётся прямо из [MessagesController.selfMessengerUserId].
  /// Используется для own/peer discriminator-а в [MessageBubble]
  /// layout. В test-режиме controller всё равно создаётся с явным
  /// `selfMessengerUserId`, что делает bubble layout детерминированным
  /// без зависимости от `MessengerRuntime`.
  final int selfMessengerUserId;
  final bool Function(ScrollNotification) onScroll;
  final void Function(ChatMessage) onRetry;
  final void Function(ChatMessage, bool isOwn) onLongPressMessage;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;
  final ScrollController scrollController;
  final Map<String, GlobalKey> itemKeys;
  final ChatMessage? Function(String) findReplyTarget;
  final void Function(String) onReplyChipTap;
  final Map<int, RoomParticipant>? participantsByMessengerId;
  final Map<String, RoomParticipant>? participantsByMatrixId;

  /// **B11**: resolver «сколько peer-ов прочитали этот message».
  /// null → не используем read-receipts (test/demo mode); 0 → одна
  /// галочка; 1+ → две синие.
  final int Function(ChatMessage)? readByPeerCountFor;

  /// **B11 group receipts**: `true` если это group-чат — bubble использует
  /// иконку глаза + count вместо ✓✓.
  final bool isGroupChat;

  /// **B11 group receipts**: callback для tap-а по counter — обычно
  /// открывает bottom-sheet «прочитали / не прочитали».
  final void Function(ChatMessage)? onTapReadStatus;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return switch (s) {
      MessagesLoading() => const Center(child: CircularProgressIndicator()),
      MessagesError(error: final e, lastKnown: final last) =>
        last == null
            ? _ErrorEmpty(error: e)
            : _Loaded(
                ready: last,
                selfMessengerUserId: selfMessengerUserId,
                onScroll: onScroll,
                onRetry: onRetry,
                onLongPressMessage: onLongPressMessage,
                thumbnailRpc: thumbnailRpc,
                fullSizeRpc: fullSizeRpc,
                scrollController: scrollController,
                itemKeys: itemKeys,
                findReplyTarget: findReplyTarget,
                onReplyChipTap: onReplyChipTap,
                participantsByMessengerId: participantsByMessengerId,
                participantsByMatrixId: participantsByMatrixId,
                readByPeerCountFor: readByPeerCountFor,
                isGroupChat: isGroupChat,
                onTapReadStatus: onTapReadStatus,
                errorBanner: e,
              ),
      MessagesReady() => _Loaded(
        ready: s,
        selfMessengerUserId: selfMessengerUserId,
        onScroll: onScroll,
        onRetry: onRetry,
        onLongPressMessage: onLongPressMessage,
        thumbnailRpc: thumbnailRpc,
        fullSizeRpc: fullSizeRpc,
        scrollController: scrollController,
        itemKeys: itemKeys,
        findReplyTarget: findReplyTarget,
        onReplyChipTap: onReplyChipTap,
        participantsByMessengerId: participantsByMessengerId,
        participantsByMatrixId: participantsByMatrixId,
        readByPeerCountFor: readByPeerCountFor,
        isGroupChat: isGroupChat,
        onTapReadStatus: onTapReadStatus,
      ),
    };
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.ready,
    required this.selfMessengerUserId,
    required this.onScroll,
    required this.onRetry,
    required this.onLongPressMessage,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.scrollController,
    required this.itemKeys,
    required this.findReplyTarget,
    required this.onReplyChipTap,
    required this.participantsByMessengerId,
    required this.participantsByMatrixId,
    this.readByPeerCountFor,
    this.isGroupChat = false,
    this.onTapReadStatus,
    this.errorBanner,
  });

  final MessagesReady ready;
  final int selfMessengerUserId;
  final bool Function(ScrollNotification) onScroll;
  final void Function(ChatMessage) onRetry;
  final void Function(ChatMessage, bool isOwn) onLongPressMessage;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;
  final ScrollController scrollController;
  final Map<String, GlobalKey> itemKeys;
  final ChatMessage? Function(String) findReplyTarget;
  final void Function(String) onReplyChipTap;
  final Map<int, RoomParticipant>? participantsByMessengerId;
  final Map<String, RoomParticipant>? participantsByMatrixId;
  final int Function(ChatMessage)? readByPeerCountFor;
  final bool isGroupChat;
  final void Function(ChatMessage)? onTapReadStatus;
  final Object? errorBanner;

  @override
  Widget build(BuildContext context) {
    final messages = ready.messages;
    return Column(
      children: [
        if (errorBanner != null) ConnectionLostBanner(error: errorBanner!),
        if (ready.paginating) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: messages.isEmpty
              ? _EmptyState()
              : NotificationListener<ScrollNotification>(
                  onNotification: onScroll,
                  child: ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isOwn =
                          m.isPending ||
                          m.isFailed ||
                          m.senderMessengerUserId == selfMessengerUserId;
                      // TASK16-A: каждое sent-message получает GlobalKey
                      // для best-effort scroll-to-original. Pending/failed
                      // у нас нет stable matrixEventId, скроллить на них
                      // нельзя — пропускаем.
                      final eventId = m.matrixEventId;
                      Key? key;
                      if (eventId != null) {
                        final existing = itemKeys[eventId];
                        if (existing != null) {
                          key = existing;
                        } else {
                          final fresh = GlobalKey();
                          itemKeys[eventId] = fresh;
                          key = fresh;
                        }
                      }
                      // **B11**: count peer-ов прочитавших — для own
                      // bubble переключает _StatusIcon на двойную
                      // синюю галочку. Для peer-сообщений
                      // (isOwn=false) индикатор не показывается, поэтому
                      // resolver можно не вызывать (микро-оптимизация).
                      final readBy = (isOwn && readByPeerCountFor != null)
                          ? readByPeerCountFor!(m)
                          : 0;
                      return KeyedSubtree(
                        key: key,
                        child: MessageBubble(
                          message: m,
                          isOwn: isOwn,
                          onRetry: onRetry,
                          thumbnailRpc: thumbnailRpc,
                          fullSizeRpc: fullSizeRpc,
                          onLongPress: (msg) => onLongPressMessage(msg, isOwn),
                          findReplyTarget: findReplyTarget,
                          onReplyChipTap: onReplyChipTap,
                          participantsByMessengerId: participantsByMessengerId,
                          participantsByMatrixId: participantsByMatrixId,
                          readByPeerCount: readBy,
                          isGroupChat: isGroupChat,
                          onTapReadStatus:
                              isOwn && isGroupChat && onTapReadStatus != null
                              ? () => onTapReadStatus!(m)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        NsgL10n.of(context).chatScreenEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorEmpty extends StatelessWidget {
  const _ErrorEmpty({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            NsgL10n.of(context).chatScreenLoadFailed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// **B15 rename room** — clickable AppBar title.
///
/// * `details == null` (ещё загружается): маленький spinner вместо
///   уродливого «Room #N» placeholder-а — UX-чище пока RoomDetails
///   на пути. Замещается реальным title-ом как только `_fetchRoom
///   Details()` отрабатывает.
/// * Direct chat: статичный Text (без InkWell — tap игнорируется).
/// * Group: InkWell с pencil-иконкой (visual hint что можно нажать).
class _RoomTitle extends StatelessWidget {
  const _RoomTitle({
    required this.details,
    required this.fallbackRoomId,
    required this.onTap,
  });

  final RoomDetails? details;
  final int fallbackRoomId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Loading: spinner instead of «Room #N».
    if (details == null) {
      final color = Theme.of(context).appBarTheme.foregroundColor
              ?.withValues(alpha: 0.7) ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    final name = details!.name ?? '';
    final isDirect = details!.roomType == RoomType.direct;
    final canRename = !isDirect;
    if (!canRename) {
      return Text(name.isEmpty ? '—' : name);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name.isEmpty ? '—' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: Theme.of(context).appBarTheme.foregroundColor
                  ?.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// **B15 rename room** — modal dialog с TextField + maxLength=100 +
/// trim. Возвращает new name на Save, `null` на Cancel.
class _RenameRoomDialog extends StatefulWidget {
  const _RenameRoomDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameRoomDialog> createState() => _RenameRoomDialogState();
}

class _RenameRoomDialogState extends State<_RenameRoomDialog> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initialName);
    _ctl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _ctl.text.length,
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return AlertDialog(
      title: Text(l.roomRenameTitle),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        maxLength: 100,
        decoration: InputDecoration(hintText: l.roomRenameHint),
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.roomRenameCancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_ctl.text.trim()),
          child: Text(l.roomRenameSave),
        ),
      ],
    );
  }
}

/// **B9 typing indicator** — footer над composer-ом «X печатает…».
///
/// Резолвит displayName для каждого matrixUserId через
/// `participantsByMatrixId` map (передаётся ChatScreen-ом). Fallback —
/// matrix localpart (`@bob:home` → `bob`).
///
/// Strategy:
///   * 1 user  → «{name} печатает…»
///   * 2 users → «{name1} и {name2} печатают…»
///   * 3+      → «N участников печатают…» (без имён, чтобы не растягивать)
class _TypingFooter extends StatelessWidget {
  const _TypingFooter({
    required this.matrixUserIds,
    required this.participantsByMatrixId,
  });

  final List<String> matrixUserIds;
  final Map<String, RoomParticipant>? participantsByMatrixId;

  String _resolveName(String mxid) {
    final p = participantsByMatrixId?[mxid];
    if (p != null && (p.displayName?.isNotEmpty ?? false)) {
      return p.displayName!;
    }
    // Fallback: localpart from `@bob:home.tld` → `bob`.
    if (mxid.startsWith('@')) {
      final colon = mxid.indexOf(':');
      if (colon > 1) return mxid.substring(1, colon);
    }
    return mxid;
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final names = matrixUserIds.map(_resolveName).toList();
    final String text;
    if (names.length == 1) {
      text = l.typingSingle(names.first);
    } else if (names.length == 2) {
      text = l.typingPair(names[0], names[1]);
    } else {
      text = l.typingManyCount(names.length);
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.85),
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// **B11 group receipts**: порог группы, выше которого детальный список
/// «прочитали / не прочитали» скрывается (показывается только число).
///
/// Telegram использует ~50, WhatsApp — 32; мы выбрали 25 чтобы:
///   * сохранить privacy в больших группах (не пушить ленту прочтений
///     на всех);
///   * избежать перебора 100+ participants в bottom-sheet (perf).
///
/// Если в будущем нужно — host-app сможет override через theme tokens
/// (пока not exposed).
const int kReadReceiptsDetailedMax = 25;

/// **B11 group receipts**: bottom-sheet, открываемый по tap-у на иконку
/// глаза рядом с own bubble. Показывает «Прочитали» (peers с receipt
/// timestamp ≥ message.serverTimestamp) и «Не прочитали» (все остальные
/// participants кроме self).
///
/// Для групп > [kReadReceiptsDetailedMax] участников вместо списков
/// показывается только агрегированная строка `count из total`.
class _ReadReceiptsSheet extends StatelessWidget {
  const _ReadReceiptsSheet({
    required this.details,
    required this.readerMatrixIds,
    required this.selfMatrixUserId,
  });

  final RoomDetails details;
  final Set<String> readerMatrixIds;
  final String selfMatrixUserId;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final showDetailed =
        details.totalParticipants <= kReadReceiptsDetailedMax;

    // Considered «peers»: все participants кроме self. Используем
    // matrixUserId как key — readReceiptMatrixUserId приходит в том
    // же формате.
    final peers = details.participants
        .where((p) => p.matrixUserId != selfMatrixUserId)
        .toList();

    final readers = <RoomParticipant>[];
    final nonReaders = <RoomParticipant>[];
    for (final p in peers) {
      if (readerMatrixIds.contains(p.matrixUserId)) {
        readers.add(p);
      } else {
        nonReaders.add(p);
      }
    }

    final maxSheetHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.readReceiptsSheetTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${readers.length} / ${details.totalParticipants - 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: showDetailed
                  ? _detailedList(context, readers, nonReaders)
                  : _aggregateOnly(context, readers.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailedList(
    BuildContext context,
    List<RoomParticipant> readers,
    List<RoomParticipant> nonReaders,
  ) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    if (readers.isEmpty && nonReaders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l.readReceiptsNobodyRead,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        if (readers.isNotEmpty) ...[
          _SectionHeader(
            title: '${l.readReceiptsSectionRead} (${readers.length})',
          ),
          for (final p in readers) _ParticipantTile(p: p, didRead: true),
        ],
        if (nonReaders.isNotEmpty) ...[
          _SectionHeader(
            title:
                '${l.readReceiptsSectionUnread} (${nonReaders.length})',
          ),
          for (final p in nonReaders) _ParticipantTile(p: p, didRead: false),
        ],
      ],
    );
  }

  Widget _aggregateOnly(BuildContext context, int readCount) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: Text(
        l.readReceiptsLargeGroupHint(
          readCount,
          details.totalParticipants - 1,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.p, required this.didRead});

  final RoomParticipant p;
  final bool didRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final name = p.displayName ?? p.matrixUserId;
    return ListTile(
      dense: true,
      leading: NsgAvatarImage(
        mxcUrl: p.avatarUrl,
        fallbackName: name,
        size: 36,
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        p.matrixUserId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          fontSize: 11,
        ),
      ),
      trailing: didRead
          ? Icon(Icons.visibility, color: accent, size: 18)
          : Icon(
              Icons.visibility_off_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              size: 18,
            ),
    );
  }
}

/// **B17 search-in-room**: pop-результат из search-экрана.
class _SearchPick {
  const _SearchPick({
    required this.results,
    required this.activeIndex,
    required this.query,
  });

  final List<ChatMessage> results;
  final int activeIndex;
  final String query;
}

/// **B17 search-in-room**: отдельный экран с TextField + результатами.
///
/// UX:
///   * Autofocus при открытии.
///   * Debounce 350ms между keystroke-ами → меньше RPC при typeahead.
///   * Empty/short (< 2) query → hint «Введи 2+ символа».
///   * Loading → spinner; results → list of `_SearchResultTile`;
///     empty → «ничего не нашлось».
///   * Tap по result → `Navigator.pop(_SearchPick)` — родитель сохраняет
///     state и скроллится к выбранному message-у.
class _SearchInRoomScreen extends StatefulWidget {
  const _SearchInRoomScreen({
    required this.controller,
    required this.participantsByMatrixId,
    this.initialQuery = '',
    this.initialResults = const [],
  });

  final MessagesController controller;
  final Map<String, RoomParticipant>? participantsByMatrixId;

  /// **B17 persistence**: previous query от parent ChatScreen. Если
  /// non-empty, экран предзаполняет TextField и сразу показывает
  /// `initialResults` без повторного RPC (instant restore).
  final String initialQuery;
  final List<ChatMessage> initialResults;

  @override
  State<_SearchInRoomScreen> createState() => _SearchInRoomScreenState();
}

class _SearchInRoomScreenState extends State<_SearchInRoomScreen> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialQuery);
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _busy = false;
  String? _error;
  late List<ChatMessage> _results = widget.initialResults;
  late bool _searched = widget.initialResults.isNotEmpty;
  late String _lastQuery = widget.initialQuery;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
        _error = null;
        _lastQuery = trimmed;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    setState(() {
      _busy = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final results = await widget.controller.searchMessages(query);
      if (!mounted) return;
      // Гонка: пока RPC летел, пользователь мог стереть text-field.
      if (_ctrl.text.trim() != query) return;
      setState(() {
        _results = results;
        _searched = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Поиск по чату…',
            border: InputBorder.none,
          ),
          style: TextStyle(
            fontSize: 17,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Очистить',
              onPressed: () {
                _ctrl.clear();
                _onChanged('');
                _focusNode.requestFocus();
              },
            ),
        ],
      ),
      body: _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (_lastQuery.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Введите 2+ символа для поиска по тексту сообщений.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Не удалось выполнить поиск: $_error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }
    if (_results.isEmpty && _searched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ничего не нашлось.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = _results[i];
        final p = widget.participantsByMatrixId?[m.senderMatrixUserId];
        // Пути резолва имени отправителя (приоритет ↓), B17 phase 2:
        //   1. ChatMessage.senderDisplayName — server-resolved fresh
        //      MessengerUser.displayName, корректен даже для ex-members
        //      (вышедших из комнаты — participants map их не содержит);
        //   2. RoomDetails.participants — current member fallback;
        //   3. matrix-localpart `@user:server` → `user`;
        //   4. raw mxid как последний fallback.
        final senderName = m.senderDisplayName ??
            p?.displayName ??
            _matrixLocalpart(m.senderMatrixUserId) ??
            m.senderMatrixUserId;
        return _SearchResultTile(
          message: m,
          senderName: senderName,
          query: _lastQuery,
          onTap: () => Navigator.of(context).pop(
            _SearchPick(
              results: _results,
              activeIndex: i,
              query: _lastQuery,
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.message,
    required this.senderName,
    required this.query,
    required this.onTap,
  });

  final ChatMessage message;
  final String senderName;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(
        senderName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: _HighlightedBody(
        body: message.body,
        query: query,
        baseStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
        ),
        highlightStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        _shortDate(message.serverTimestamp.toLocal()),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  static String _shortDate(DateTime t) {
    final now = DateTime.now();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final mo = t.month.toString().padLeft(2, '0');
    const dow = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    final dayName = dow[(t.weekday - 1).clamp(0, 6)];
    // Сегодня: «пн, HH:MM».
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '$dayName, $h:$m';
    }
    // Этот год: «пн, DD.MM, HH:MM».
    if (t.year == now.year) {
      return '$dayName, $d.$mo, $h:$m';
    }
    // Старше года: «пн, DD.MM.YYYY».
    return '$dayName, $d.$mo.${t.year}';
  }
}

/// Подсвечивает match-и query (case-insensitive) в body. Один tile
/// может иметь несколько вхождений — все подсвечиваются.
class _HighlightedBody extends StatelessWidget {
  const _HighlightedBody({
    required this.body,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  final String body;
  final String query;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty || body.isEmpty) {
      return Text(
        body,
        style: baseStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lower = body.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var cursor = 0;
    while (cursor < body.length) {
      final idx = lower.indexOf(q, cursor);
      if (idx < 0) {
        spans.add(TextSpan(text: body.substring(cursor), style: baseStyle));
        break;
      }
      if (idx > cursor) {
        spans.add(
          TextSpan(text: body.substring(cursor, idx), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: body.substring(idx, idx + query.length),
          style: highlightStyle,
        ),
      );
      cursor = idx + query.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// `@user:server` → `user`. `null` если не matrix-id-shape.
String? _matrixLocalpart(String matrixUserId) {
  if (!matrixUserId.startsWith('@')) return null;
  final colon = matrixUserId.indexOf(':');
  if (colon <= 1) return null;
  return matrixUserId.substring(1, colon);
}

/// **B17 search nav-bar**: горизонтальная полоска над списком сообщений
/// после перехода из search-экрана. Показывает «активный/всего» +
/// prev/next/close.
///
/// Order list-а DESC (newest first): `prev` идёт к более новому
/// (idx--), `next` — к более старому (idx++). Иконки в bar-е
/// `keyboard_arrow_up/down` чтобы соответствовать визуальному
/// направлению (chat reverse-scrolls: newer вверху reversed-list →
/// внизу экрана).
class _SearchNavBar extends StatelessWidget {
  const _SearchNavBar({
    required this.query,
    required this.activeIndex,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
  });

  final String query;
  final int activeIndex;
  final int totalCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Material(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant
                    .withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '${activeIndex + 1}/$totalCount ',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: '«$query»',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: 'Новее',
                visualDensity: VisualDensity.compact,
                onPressed: onPrev,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: 'Старше',
                visualDensity: VisualDensity.compact,
                onPressed: onNext,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Закрыть поиск',
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
