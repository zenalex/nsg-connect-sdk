import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show
        AttachmentRef,
        WriteBannedException,
        EscalationResult,
        ContactCardInfo,
        RoomDetails,
        RoomParticipant,
        RoomMemberRole,
        MessengerEvent,
        MessengerEventType,
        ParticipantKind,
        RoomSummary,
        RoomType,
        RoomUnavailableException;

import '../contact_card/contact_card_view.dart';
import '../i18n/connection_lost_banner.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messages/attachments/attachment_bubble.dart';
import '../messages/attachments/attachment_picker.dart';
import '../messages/attachments/chat_image_gallery.dart';
import '../messages/attachments/mxc_image_provider.dart';
import '../messages/chat_message.dart';
import '../messages/composer_album_edit.dart';
import '../messages/forward_picker_sheet.dart';
import '../messages/forward_source.dart';
import '../messages/message_action_sheet.dart';
import '../messages/message_bubble.dart';
import '../messages/message_composer.dart';
import '../messages/messages_controller.dart';
import '../messages/messages_rpc.dart';
import '../messages/messages_state.dart';
import '../calls/conference_call_controller.dart';
import '../calls/conference_call_state.dart';
import '../messenger_runtime.dart';
import 'chat_route.dart';
import 'contact_profile_screen.dart';
import 'nsg_route_observer.dart';
import '../rooms/participant_action_sheet.dart' show formatWriteBanUntil;
import '../presence/last_seen_format.dart';
import '../session/auth_retry.dart' show withAuthRetry;
import '../runtime/messenger_connection_state.dart';
import '../theme/nsg_messenger_theme.dart' show NsgMessageBubbleTokens;
import '../widgets/nsg_avatar_image.dart';
import 'group_settings_screen.dart';

/// **TASK45 фаза 2**: productEntityType объектовой комнаты. Синхронно с
/// server-side `RoomService.objectRoomEntityType` ('object'). По нему
/// ChatScreen отличает объектовый чат от прочих productRoom (roomType их
/// не различает) и показывает action «Обратиться к разработчикам».
const String _kObjectRoomEntityType = 'object';

/// **TASK45 фаза 2**: пункты overflow-меню чата.
enum _ChatOverflowAction { escalate, escalateSupport }

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

/// **TASK45 фаза 2**: сигнатура escalation-RPC для [ChatScreen]
/// `@visibleForTesting escalateOverride`. Зеркало
/// `client.messenger.escalateToSupportTeam`. Возвращает Future — UI
/// показывает снекбар после успеха.
typedef EscalateOverride = Future<void> Function({required int roomId});

/// **TASK48 / Review fix #5**: сигнатура тир-эскалации support-чата.
/// В отличие от [EscalateOverride] ВОЗВРАЩАЕТ [EscalationResult] — сервер
/// на no-op (проиграна гонка / нет тира выше / полный откат инвайтов)
/// отвечает пустым `addedMessengerUserIds` БЕЗ исключения, и UI обязан это
/// различать (снекбар + рефреш кнопки), а не рапортовать успех всегда.
typedef EscalateSupportOverride =
    Future<EscalationResult> Function({required int roomId});

/// **TASK46 (UI)**: сигнатура `startCall`-команды для [ChatScreen]
/// `@visibleForTesting startCallOverride`. Зеркало
/// `NsgMessenger.startCall`. Позволяет widget-тесту кнопки «Позвонить»
/// проверить вызов без поднятия runtime/flutter_webrtc.
typedef StartCallOverride =
    Future<void> Function({
      required int roomId,
      int? peerMessengerUserId,
      String? peerDisplayName,
    });

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.roomId,
    this.readOnly = false,
    this.initialDraft,
    this.initialTargetEventId,
    this.active = true,
    this.pagerSetSize = 0,
    this.onOpenSwitcher,
    this.onNavigateBack,
    this.canNavigateBack = false,
    @visibleForTesting this.controllerOverride,
    @visibleForTesting this.setPresenceOverride,
    @visibleForTesting this.loadMoreThresholdPxOverride,
    @visibleForTesting this.escalateOverride,
    @visibleForTesting this.escalateSupportOverride,
    @visibleForTesting this.roomDetailsOverride,
    @visibleForTesting this.startCallOverride,
    @visibleForTesting this.conferenceCallsOverride,
    @visibleForTesting this.forwardRoomsLoaderOverride,
    @visibleForTesting this.forwardSourceProbeOverride,
  });

  final int roomId;

  /// **Пересылка (мультивыбор)**: visible-for-testing загрузчик списка чатов
  /// для forward-пикера. Если передан — используется вместо
  /// `MessengerRuntime.instance.rooms.list` (widget-тест мультивыбора не
  /// поднимает runtime). В production не передаётся.
  final Future<List<RoomSummary>> Function()? forwardRoomsLoaderOverride;

  /// **Issue #41**: visible-for-testing проба доступности комнаты-
  /// первоисточника перед переходом. В production — `rooms.get(roomId)`
  /// (бросает [RoomUnavailableException], если нас там нет). Тест подменяет,
  /// чтобы проверить отказ без поднятия runtime.
  final Future<void> Function(int roomId)? forwardSourceProbeOverride;

  /// **TASK45 фаза 2**: visible-for-testing escalation callback. Если
  /// передан — используется вместо
  /// `MessengerRuntime.instance.client.messenger.escalateToSupportTeam`.
  final EscalateOverride? escalateOverride;

  /// **TASK48**: visible-for-testing колбэк тир-эскалации support-чата.
  /// Если передан — вместо `client.messenger.escalateSupportRoom`.
  /// Возвращает [EscalationResult] (см. [EscalateSupportOverride]).
  final EscalateSupportOverride? escalateSupportOverride;

  /// **TASK46 (UI)**: visible-for-testing `startCall` callback. Если
  /// передан — используется вместо `NsgMessenger.startCall`, чтобы
  /// widget-тест кнопки «Позвонить» не поднимал runtime/flutter_webrtc.
  final StartCallOverride? startCallOverride;

  /// **TASK51 (UI)**: visible-for-testing подмена контроллера
  /// конференций. Если передана — кнопка «Групповой звонок» и плашка
  /// «идёт конференция» работают через неё (fake), runtime не трогается.
  /// В production не передаётся — берём
  /// `MessengerRuntime.instance.conferenceCallsOrNull`.
  final ConferenceCallController? conferenceCallsOverride;

  /// **TASK45 фаза 2**: visible-for-testing подмена RoomDetails, чтобы
  /// widget-тест кнопки эскалации мог задать object-room без runtime
  /// (обычно `_roomDetails` грузится через `_fetchRoomDetails`, который
  /// в test-mode skip-ается).
  final RoomDetails? roomDetailsOverride;

  /// **TASK22-Phase2 Chunk 2**: when true, `MessageComposer` is hidden
  /// — used by demo / view-only contexts (`NsgMessenger.demoChatScreen`
  /// in the theming sandbox). Long-press / action sheet still trigger
  /// edit/delete logic at the controller layer, but in demo mode the
  /// RPC throws `UnimplementedError` so the action sheet's destructive
  /// items are effectively inert.
  final bool readOnly;

  /// **TASK57 фаза 0**: начальный текст композера (шаблон обращения —
  /// «Сообщить об ошибке» / «Предложить идею»). Сидируется в поле ввода
  /// ОДНОКРАТНО при первом построении экрана; пользователь редактирует и
  /// отправляет вручную. `null`/пусто → поведение не меняется.
  final String? initialDraft;

  /// **Issue #41**: сообщение, ради которого экран открыли — к нему нужно
  /// проскроллить сразу после загрузки истории (переход к первоисточнику
  /// пересланного сообщения). `null` — обычное открытие чата (внизу, на
  /// свежих сообщениях).
  ///
  /// Прыжок одноразовый и best-effort: идёт через тот же
  /// `_scrollToSearchResult`, что закреплённые и поиск, — он догружает
  /// историю страницами и сам показывает понятный отказ, если сообщения в
  /// доступной истории нет.
  final String? initialTargetEventId;

  /// **TASK66**: «активен ли этот чат» (сфокусированная вкладка/панель).
  /// Для полноэкранного чата всегда `true`. В рабочем наборе (вкладки /
  /// split view) несколько ChatScreen живут одновременно (keep-alive), но
  /// только активный имеет право метить сообщения прочитанными и держать
  /// серверный presence `currentRoomId` — иначе фоновая вкладка молча
  /// гасит unread и воюет за presence. Меняется на лету (`didUpdateWidget`).
  final bool active;

  /// **TASK66 (телефон)**: размер рабочего набора открытых чатов. ≥2 →
  /// в шапке появляется кнопка-переключатель (стопка с числом), тап зовёт
  /// [onOpenSwitcher] (host показывает шит недавних чатов). 0 = обычный
  /// полноэкранный чат без набора.
  final int pagerSetSize;

  /// **TASK66 (телефон)**: открыть переключатель рабочего набора (шит).
  final VoidCallback? onOpenSwitcher;

  /// **TASK66 / issue #17 (телефон)**: «назад» внутри рабочего набора.
  /// Пейджер передаёт колбэк-переход в предыдущий чат набора; вызывается и
  /// системным back-жестом, и стрелкой «назад» в шапке (обе идут через
  /// [PopScope]). Работает вместе с [canNavigateBack]. `null` (обычный
  /// полноэкранный чат) — поведение back не меняется (выход из экрана).
  final VoidCallback? onNavigateBack;

  /// **TASK66 / issue #17 (телефон)**: есть ли куда вернуться в наборе. Когда
  /// `true`, экран перехватывает back и зовёт [onNavigateBack] вместо выхода;
  /// когда `false` — back покидает пейджер штатно (выход в список чатов).
  /// Передаётся ТОЛЬКО активному чату набора, иначе фоновые keep-alive
  /// `ChatScreen` в IndexedStack перехватывали бы back наперегонки.
  final bool canNavigateBack;

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

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, RouteAware {
  late final MessagesController _controller;
  late final bool _ownsController;

  /// **B10**: подписка на transport `connectionState` — при возврате сети
  /// (reconnecting/disconnected → healthy) авто-переотправляем сообщения,
  /// застрявшие в `failed` пока сеть лежала. Только production-путь
  /// (`_ownsController`); в инжектированном (тестовом) controller-е runtime
  /// может быть не инициализирован.
  StreamSubscription<MessengerConnectionState>? _connSub;
  MessengerConnectionState? _lastConn;

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

  /// **Issue #41**: прыжок к [ChatScreen.initialTargetEventId] уже запущен.
  /// Одноразовый — иначе доскролл пользователя вверх/вниз после перехода
  /// каждый раз отбрасывал бы его обратно к целевому сообщению.
  bool _initialJumpStarted = false;

  /// **Issue #37**: «низ» ленты в пикселях. В `reverse: true` ListView
  /// offset 0 — это ДНО списка, где лежит newest сообщение (index 0 в
  /// DESC-порядке). Пока `pixels` в пределах порога — newest реально
  /// показан на экране; выше — юзер ушёл в историю и newest под
  /// нижней кромкой вьюпорта.
  static const double _newestVisibleThresholdPx = 64;

  /// **Issue #37**: приложение в foreground (OS-уровень).
  ///
  /// Это НЕ то же самое, что [ChatScreen.active] (TASK66-флаг активной
  /// вкладки в мультичатовом наборе). Экран может оставаться активной
  /// панелью, пока приложение свёрнуто/экран заблокирован — и до
  /// issue #37 в этом состоянии realtime-сообщения молча помечались
  /// прочитанными.
  ///
  /// Стартовое значение: `lifecycleState` ещё может быть `null` до
  /// первого lifecycle-сообщения от движка — трактуем как foreground,
  /// иначе обычное открытие чата не пометило бы ничего.
  bool _appResumed =
      (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
      AppLifecycleState.resumed;

  /// **Issue #37**: newest сообщение сейчас в видимой области.
  /// Стартует `true` — свежеоткрытый чат отрисован на дне ленты.
  bool _newestVisible = true;

  /// **Issue #55**: экран перекрыт другим маршрутом ПОВЕРХ внутри
  /// приложения (профиль/настройки/галерея). ЧЕТВЁРТАЯ ось видимости —
  /// первые три ([ChatScreen.active], [_appResumed], [_newestVisible])
  /// перекрытие не ловят: приложение в foreground, вкладка активна,
  /// скролл внизу, а юзер смотрит на профиль. Живёт через RouteAware-
  /// подписку в [didChangeDependencies]; без зарегистрированного у
  /// навигатора `NsgMessenger.routeObserver` никогда не взводится —
  /// деградация к прежнему поведению.
  bool _routeCovered = false;

  /// **Issue #55**: маршрут, на который сейчас подписаны как [RouteAware],
  /// и наблюдатели, в которые подписались, — чтобы переподписаться при
  /// смене маршрута (keep-alive экран мог переехать) и точно отписаться в
  /// dispose. На телефоне это маршрут самого чата/пейджера (перекрытие
  /// пушится тем же корневым навигатором); на десктопе — страница панели
  /// рабочей области (перекрытие пушится вложенным навигатором панели).
  /// Оба случая покрываются одинаково: ближайший `ModalRoute.of(context)`.
  ModalRoute<void>? _subscribedRoute;
  List<RouteObserver<ModalRoute<void>>> _subscribedObservers = const [];

  /// **TASK16-A**: участники комнаты (TASK13 30-cap). Загружаются один
  /// раз в initState через `MessengerRuntime.instance.rooms.get(roomId)`
  /// — cached LRU там же. Используются:
  ///   * для `MessageBubble` — index-ы для mention highlighting + reply
  ///     chip sender displayName.
  ///   * для `MessageComposer` — `@`-typeahead source.
  /// Null пока не загружено / в test-mode без runtime — fallback на
  /// no-mention-styling (acceptable degraded UX).
  RoomDetails? _roomDetails;

  /// **TASK55 итер.1**: last seen собеседника (только direct). null —
  /// не загружен / нет данных / не direct.
  DateTime? _peerLastSeen;

  /// **TASK55 итер.2**: собеседник сейчас в сети (heartbeat < TTL).
  bool _peerOnline = false;

  /// **TASK55 итер.2b**: переподтверждение подписки presence (~2 мин,
  /// TTL на сервере 5 мин); изменения приходят СОБЫТИЯМИ presenceUpdated.
  Timer? _presencePollTimer;
  StreamSubscription<MessengerEvent>? _presenceEventsSub;
  int? _peerUserId;
  Map<int, RoomParticipant>? _participantsByMessengerId;
  Map<String, RoomParticipant>? _participantsByMatrixId;

  /// **TASK69 2C**: канал «упоминаний из контекста» → композер. ChatScreen
  /// эмитит участника (Ответить с упоминанием / тап по аватару), композер
  /// вставляет `@имя ` в каретку. Broadcast — композер пере-подписывается на
  /// rebuild-ах (ValueListenableBuilder вокруг него), а sink живёт со State.
  final StreamController<RoomParticipant> _mentionInserts =
      StreamController<RoomParticipant>.broadcast();

  /// **TASK52 итер.2**: визитка собеседника — интро-карточка в пустом
  /// direct-чате («вы только что познакомились, вот кто это»). Best-effort;
  /// null = нет визитки / не direct / не загрузилась.
  ContactCardInfo? _introCard;

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

  /// **Редактирование альбома в композере**: снимок альбома в режиме
  /// редактирования (картинки + подпись). `null` = обычный режим. Собирается
  /// в [_onLongPressMessage] когда «Изменить» нажато на члене реального
  /// альбома (≥2 сообщения с общим `albumId`, own).
  final ValueNotifier<ComposerAlbumEdit?> _albumEditTarget = ValueNotifier(
    null,
  );

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

  /// **Пересылка (мультивыбор)**: ключи выбранных сообщений (Telegram-style).
  /// Ключ — стабильный id сообщения: `matrixEventId ?? clientTxnId`. Режим
  /// выбора активен ⟺ множество непусто ([_inSelection]). Вход — через пункт
  /// «Выбрать» в action-sheet; далее тап по пузырю тогглит выбор.
  final Set<String> _selectedKeys = <String>{};
  bool get _inSelection => _selectedKeys.isNotEmpty;

  /// Стабильный ключ сообщения для [_selectedKeys]. Выбираемы только sent-
  /// сообщения (у них есть `matrixEventId`); `clientTxnId` — резерв.
  static String? _messageKey(ChatMessage m) => m.matrixEventId ?? m.clientTxnId;

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
        // **TASK47**: read-through дискового кэша истории сообщений.
        cache: runtime.offlineCache,
        // **OUTBOX**: pending-бабблы персистентной очереди + retry/discard.
        outbox: runtime.outbox,
      );
      _ownsController = true;
    }
    _controller.stateListenable.addListener(_onStateChange);
    _controller.init();
    // **TASK45 фаза 2**: тест кнопки эскалации может задать RoomDetails
    // напрямую (в test-mode `_fetchRoomDetails` skip-ается). Раскладываем
    // их тем же `_applyRoomDetails`, что и боевой путь — вместе с
    // индексами участников (issue #39: имена/бот-признак в подписи).
    final overrideDetails = widget.roomDetailsOverride;
    if (overrideDetails != null) _applyRoomDetails(overrideDetails);
    _fetchRoomDetails();
    // **TASK51 (UI)**: разово освежить знание о живой конференции комнаты
    // (плашка «идёт групповой звонок»): события шины шлются только на
    // ИЗМЕНЕНИЯ состава — о конференции, начавшейся до нашего подключения,
    // события не будет. Best-effort внутри контроллера.
    unawaited(_conferenceCalls?.refreshRoomConference(widget.roomId));
    // **B10**: авто-retry failed-сообщений при возврате сети. Только
    // production-путь — в инжектированном controller-е (тесты) runtime
    // connectionStateStream пуст/healthy, но runtime трогать не нужно.
    if (_ownsController) {
      final runtime = MessengerRuntime.instance;
      _lastConn = runtime.connectionState;
      _connSub = runtime.connectionStateStream.listen(_onConnectionChange);
    }
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
    // navigation между rooms без app-resume). **TASK66**: только активный
    // чат заявляет presence `currentRoomId` (фоновые вкладки не воюют).
    if (widget.active) {
      _firePresence(currentRoomId: widget.roomId, foreground: true);
    }
  }

  @override
  void didUpdateWidget(covariant ChatScreen old) {
    super.didUpdateWidget(old);
    // **TASK66**: смена активности вкладки/панели. Стал активным → заявляем
    // presence и метим прочитанным накопившееся; стал фоновым → отпускаем
    // (новый активный чат перезапишет currentRoomId своим).
    if (widget.active && !old.active) {
      // **Issue #55**: если панель прямо сейчас перекрыта маршрутом (юзер
      // сфокусировал панель, над которой открыт профиль) — заявлять
      // presence комнаты нельзя, юзер её не видит. Шлём null: это честнее,
      // чем молчать, — прежний активный чат при деактивации ничего не шлёт
      // (рассчитывает, что новый активный перезапишет), и без null его
      // stale-заявка висела бы до TTL.
      _firePresence(
        currentRoomId: _routeCovered ? null : widget.roomId,
        foreground: true,
      );
      // **Issue #37**: вкладка стала активной — дожимаем отложенное
      // сразу, без debounce (условие видимости только что выполнилось).
      // При перекрытии (#55) внутренний гейт не пропустит — дожмётся
      // на didPopNext.
      _flushMarkRead();
    }
    // **Issue #53**: у keep-alive экрана (панель/вкладка рабочего набора)
    // цель перехода может смениться «на лету» — тап по уведомлению УЖЕ
    // открытого чата приносит новый target. Снимаем одноразовую защёлку и
    // прыгаем к новой цели; если история ещё грузится, прыжок дожмёт
    // `_onStateChange` на ближайшем Ready. Прежняя (уже потреблённая)
    // цель не перезапускается — только реальная смена значения.
    final target = widget.initialTargetEventId;
    if (target != null &&
        target.isNotEmpty &&
        target != old.initialTargetEventId) {
      _initialJumpStarted = false;
      // Пост-фрейм, а не сразу: didUpdateWidget идёт ПОСРЕДИ build, а
      // промах прыжка синхронно показывает снекбар «не удалось перейти»
      // (showSnackBar в build запрещён). Если до конца кадра прыжок уже
      // запустил `_onStateChange` — защёлка сделает вызов no-op.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeJumpToInitialTarget();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // **Issue #55**: RouteAware-подписка на ближайший маршрут — чтобы
    // замечать перекрытие другим экраном ПОВЕРХ (didPushNext/didPopNext).
    // Именно в didChangeDependencies, а не в initState: ModalRoute здесь
    // уже доступен, и при смене маршрута (keep-alive экран переехал)
    // переподписываемся. Если host не включил `NsgMessenger.routeObserver`
    // в navigatorObservers — подписка никогда не выстрелит: деградация к
    // прежнему поведению (перекрытие не замечаем), без исключений.
    final route = ModalRoute.of(context);
    if (route != _subscribedRoute) {
      _unsubscribeRouteAware();
      if (route != null) {
        // Во ВСЕ зарегистрированные наблюдатели (главный + вложенные
        // панельные): выстрелит только тот, чьему навигатору принадлежит
        // маршрут, остальные молчат. Snapshot сохраняем, чтобы в dispose
        // отписаться ровно оттуда, куда подписались.
        _subscribedObservers = nsgAllRouteObservers;
        for (final observer in _subscribedObservers) {
          observer.subscribe(this, route);
        }
        _subscribedRoute = route;
      }
    }
  }

  void _unsubscribeRouteAware() {
    for (final observer in _subscribedObservers) {
      observer.unsubscribe(this);
    }
    _subscribedObservers = const [];
    _subscribedRoute = null;
  }

  /// **Issue #55**: поверх нашего маршрута запушили другой экран
  /// (профиль/настройки/галерея) — юзер чата больше не видит, хотя экран
  /// жив и realtime продолжает приходить.
  ///
  /// Presence отпускаем как в dispose (`currentRoomId: null`) — иначе
  /// серверный кэш продолжает утверждать «пользователь в комнате», и
  /// push-routing (фильтр «foreground в той же комнате → skip») глушит
  /// уведомления, которые юзер ДОЛЖЕН получить. Но только если мы вообще
  /// заявляли presence: неактивная панель (TASK66) комнату не держит, а её
  /// null стёр бы заявку АКТИВНОГО чата (presence на сервере один на
  /// юзера). При свёрнутом приложении (!_appResumed) bus уже отправил
  /// null+background — не перебиваем его «foreground: true»-враньём.
  @override
  void didPushNext() {
    _routeCovered = true;
    if (widget.active && _appResumed) {
      _firePresence(currentRoomId: null, foreground: true);
    }
  }

  /// **Issue #55**: перекрывавший экран закрыли — чат снова виден.
  /// Возвращаем presence комнаты и дожимаем отложенное «прочитано»
  /// (механика догона issue #37: [_flushMarkRead] сам пересчитает newest
  /// и сам проверит гейт). Presence шлём только когда чат реально виден И
  /// имеет право на комнату: didPopNext может прийти в неактивную вкладку
  /// (перекрытие общего маршрута пейджера получают ВСЕ его keep-alive
  /// экраны) или при свёрнутом приложении (программный pop) — тогда
  /// комнату заявит didUpdateWidget(active) / resumed-обработчик, когда
  /// своя ось видимости восстановится.
  @override
  void didPopNext() {
    _routeCovered = false;
    if (widget.active && _appResumed) {
      _firePresence(currentRoomId: widget.roomId, foreground: true);
    }
    _flushMarkRead();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // **Issue #37**: foreground-гейт для auto-markRead. Отслеживаем ВСЕ
    // состояния, а не только `resumed`: `inactive`/`hidden` — это уже «юзер
    // не смотрит», и `MessengerEventBus` в них НЕ рвёт realtime-подписку
    // (он гасит её только на `paused`/`detached`), то есть сообщения
    // продолжают приходить в незримый экран.
    _appResumed = state == AppLifecycleState.resumed;

    if (state == AppLifecycleState.resumed) {
      // Race fix: bus's lifecycle handler уже отправил setPresence с
      // currentRoomId=null. Re-overwrite с актуальным roomId (только если
      // этот чат активен — TASK66). **Issue #55**: при перекрытии
      // маршрутом НЕ перезаписываем — null от bus-а и есть правда (юзер
      // вернулся в приложение, но смотрит на перекрывающий экран);
      // комнату заявит didPopNext.
      if (widget.active && !_routeCovered) {
        _firePresence(currentRoomId: widget.roomId, foreground: true);
      }
      // Реконсиляция «пропущенных входящих»: сообщение, пришедшее пока app
      // был в фоне (в т.ч. открытие чата через push), могло проскочить мимо
      // live-стрима и первичной загрузки — до-тягиваем свежую страницу.
      unawaited(_controller.refreshLatest());
      // **Issue #37**: то, что накопилось в фоне, помечаем прочитанным
      // ИМЕННО СЕЙЧАС — когда юзер вернулся и смотрит на чат. Если
      // `refreshLatest` что-то дотянет, `_onStateChange` сработает сам;
      // но когда новых сообщений нет, а отложенный markRead есть —
      // дожать его должен этот вызов.
      _flushMarkRead();
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
      setState(() => _applyRoomDetails(details));
      unawaited(_fetchPeerLastSeen(details));
    } catch (_) {
      // Tolerable: bubble без mention-styling, composer без typeahead.
      // Reply / send всё ещё работают.
    }
  }

  /// Раскладывает [RoomDetails] по стейту: сами детали + два индекса
  /// участников (по messengerUserId и по matrixUserId). Вынесено, чтобы
  /// `roomDetailsOverride` в widget-тестах давал ТУ ЖЕ картину, что и
  /// боевой `_fetchRoomDetails` — иначе подпись отправителя (issue #39)
  /// не могла бы отрезолвить ни имя, ни `participantKind` бота.
  ///
  /// Вызывать внутри `setState` (или до первого build — из `initState`).
  void _applyRoomDetails(RoomDetails details) {
    _roomDetails = details;
    _participantsByMessengerId = {
      for (final p in details.participants) p.messengerUserId: p,
    };
    _participantsByMatrixId = {
      for (final p in details.participants) p.matrixUserId: p,
    };
  }

  /// **TASK55 итер.2b**: подписка на presence собеседника (только
  /// RoomType.direct, §4 спеки). subscribePresence возвращает снапшот и
  /// регистрирует подписку (TTL 5 мин на сервере) — переподтверждаем раз
  /// в 2 мин, изменения приходят событиями presenceUpdated мгновенно.
  Future<void> _fetchPeerLastSeen(RoomDetails details) async {
    if (details.roomType != RoomType.direct) return;
    try {
      final selfId = MessengerRuntime.instance.session.messengerUserId;
      final peer = details.participants
          .where((p) => p.messengerUserId != selfId)
          .toList();
      if (peer.isEmpty) return;
      _peerUserId = peer.first.messengerUserId;
      // **TASK52 итер.2**: подгрузить визитку собеседника для интро-карточки
      // (best-effort — её отсутствие/ошибка не влияет на чат).
      unawaited(_fetchIntroCard(peer.first.messengerUserId));
      final infos = await withAuthRetry(
        () => MessengerRuntime.instance.client.messenger.subscribePresence(
          userIds: [peer.first.messengerUserId],
        ),
        MessengerRuntime.instance.sessionManager,
      );
      if (!mounted || infos.isEmpty) return;
      setState(() {
        _peerLastSeen = infos.first.lastActiveAt;
        _peerOnline = infos.first.online;
      });
      // Live-события presence собеседника.
      _presenceEventsSub ??= MessengerRuntime.instance.eventBus.events.listen((
        event,
      ) {
        if (event.eventType != MessengerEventType.presenceUpdated) return;
        if (event.presenceUserId != _peerUserId) return;
        if (!mounted) return;
        setState(() {
          _peerOnline = event.presenceOnline ?? false;
          _peerLastSeen = event.presenceLastActiveAt ?? _peerLastSeen;
        });
      });
      // Переподтверждение подписки (TTL-refresh + свежий снапшот).
      _presencePollTimer ??= Timer.periodic(const Duration(minutes: 2), (_) {
        final d = _roomDetails;
        if (d != null && mounted) unawaited(_fetchPeerLastSeen(d));
      });
    } catch (_) {
      // молча: подпись просто не покажется
    }
  }

  /// **TASK52 итер.2**: визитка собеседника для интро-карточки (показывается
  /// только в пустом direct-чате). Best-effort.
  Future<void> _fetchIntroCard(int peerId) async {
    try {
      final card = await MessengerRuntime.instance.contactCards.get(peerId);
      if (!mounted || card == null) return;
      setState(() => _introCard = card);
    } catch (_) {
      // нет визитки / ошибка — интро-карточка просто не покажется
    }
  }

  @override
  void dispose() {
    _presencePollTimer?.cancel();
    unawaited(_presenceEventsSub?.cancel());
    _markReadTimer?.cancel();
    unawaited(_mentionInserts.close());
    _editTarget.dispose();
    _albumEditTarget.dispose();
    _scrollController.dispose();
    _connSub?.cancel();
    _connSub = null;
    _controller.stateListenable.removeListener(_onStateChange);
    WidgetsBinding.instance.removeObserver(this);
    // **Issue #55**: снять RouteAware-подписки (иначе observer держит
    // ссылку на мёртвый State и продолжает дёргать его колбэки).
    _unsubscribeRouteAware();
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

  /// **B10**: transport reconnect-хук. На переходе в `healthy` из
  /// reconnecting/disconnected — авто-переотправляем застрявшие failed
  /// (outgoing) + до-тягиваем пропущенные входящие ([refreshLatest]):
  /// пока сеть/поток лежали, входящее сообщение могло не долететь live —
  /// иначе оно невидимо до ручного пере-входа в чат.
  void _onConnectionChange(MessengerConnectionState s) {
    final prev = _lastConn;
    _lastConn = s;
    if (s == MessengerConnectionState.healthy &&
        prev != null &&
        prev != MessengerConnectionState.healthy) {
      unawaited(_controller.retryAllFailed());
      unawaited(_controller.refreshLatest());
    }
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
  ///
  /// **Issue #37**: оба пути проходят через [_canMarkRead] — «прочитано»
  /// отправляется, только если сообщение реально показано пользователю.
  /// Раньше единственным гейтом был TASK66-флаг [ChatScreen.active], и
  /// realtime-сообщение, прилетевшее в свёрнутое приложение с открытым
  /// чатом, мгновенно получало ✓✓ у отправителя.
  void _onStateChange() {
    // **Issue #41**: прыжок к целевому сообщению ждёт первого Ready — до
    // него скроллить не к чему. Стоит ДО гейта markRead: тот про «юзер
    // видит новое», а прыжок нужен и в неактивной панели рабочего набора.
    _maybeJumpToInitialTarget();
    // **Issue #37**: гейт «юзер это действительно видит». Если не сходится
    // — НЕ метим и не заводим таймер; отложенный markRead дожмётся, как
    // только условия выполнятся (resume / доскролл вниз / активация
    // вкладки / возврат из перекрывшего маршрута — issue #55), потому что
    // [_flushMarkRead] всегда пересчитывает newest из текущего state.
    if (!_canMarkRead) return;
    final eventId = _newestMarkableEventId();
    if (eventId == null) return;
    if (eventId == _lastMarkReadEventId) return;

    if (_firstReady) {
      _firstReady = false;
      // Fire IMMEDIATELY на первом Ready.
      _flushMarkRead();
      return;
    }

    // Subsequent — debounce 500ms.
    _markReadTimer?.cancel();
    _markReadTimer = Timer(_markReadDebounce, _flushMarkRead);
  }

  /// **Issue #37**: можно ли СЕЙЧАС честно сказать «прочитано».
  ///
  /// Четыре независимых условия, все обязательны:
  ///   * [ChatScreen.active] — TASK66-флаг активной вкладки/панели
  ///     (фоновая вкладка рабочего набора не гасит unread молча);
  ///   * [_appResumed] — приложение в foreground на уровне ОС (свёрнутое
  ///     приложение с открытым чатом продолжает получать realtime,
  ///     но юзер ничего не видит — это и был баг issue #37);
  ///   * [_newestVisible] — newest сообщение в видимой области (юзер не
  ///     ушёл вверх в историю);
  ///   * `!`[_routeCovered] — поверх чата не открыт другой маршрут
  ///     (issue #55: пропущенный кейс гейта #37 — приложение в
  ///     foreground, вкладка активна, скролл внизу, а юзер смотрит на
  ///     профиль, и сообщение молча получало «прочитано»).
  bool get _canMarkRead =>
      widget.active && _appResumed && _newestVisible && !_routeCovered;

  /// Newest сообщение с `matrixEventId` из текущего state — то, до
  /// которого метим прочитанным. `null` — метить нечего (не Ready,
  /// пусто, или всё ещё pending без event id).
  String? _newestMarkableEventId() {
    final state = _controller.state;
    if (state is! MessagesReady) return null;
    if (state.messages.isEmpty) return null;
    // Newest message в DESC list — index 0 (для reverse listview =
    // bottom of screen). Skip pending — у него matrixEventId == null,
    // markRead не имеет смысла.
    final newest = state.messages.firstWhere(
      (m) => m.matrixEventId != null,
      orElse: () => state.messages.first,
    );
    return newest.matrixEventId;
  }

  /// **Issue #37**: единственная точка, откуда реально уходит markRead.
  ///
  /// Всегда пере-читает newest из текущего state (а не из захваченной
  /// в замыкании переменной) — поэтому годится и как debounce-callback,
  /// и как «дожать отложенное» при resume/доскролле. Гейт [_canMarkRead]
  /// проверяется ЗДЕСЬ: debounce-таймер, заведённый в foreground и
  /// сработавший уже после сворачивания приложения, не пометит ничего.
  void _flushMarkRead() {
    _markReadTimer?.cancel();
    _markReadTimer = null;
    if (!_canMarkRead) return;
    final eventId = _newestMarkableEventId();
    if (eventId == null) return;
    if (eventId == _lastMarkReadEventId) return;
    _lastMarkReadEventId = eventId;
    unawaited(_controller.markRead(eventId));
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
    // **Issue #37**: reverse: true → pixels≈0 это ДНО ленты, где newest.
    // Ушли вверх в историю — новые сообщения приходят под нижнюю кромку
    // экрана, юзер их не видит, метить нельзя. Вернулись вниз — дожимаем.
    final newestVisible = metrics.pixels <= _newestVisibleThresholdPx;
    if (newestVisible != _newestVisible) {
      _newestVisible = newestVisible;
      if (newestVisible) _flushMarkRead();
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
    String? albumId,
  }) async {
    final reply = _controller.replyTarget;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    try {
      await _controller.sendMessage(
        body: body,
        replyToMatrixEventId: reply?.matrixEventId,
        mentionedMessengerUserIds: mentionedMessengerUserIds,
        albumId: albumId,
      );
    } on WriteBannedException catch (e) {
      // **Write-ban (2026-07-13)**: админ запретил писать — объясняем,
      // а не молча помечаем сообщение failed.
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            e.until.year >= 9000
                ? l.writeBannedForeverSnack
                : l.writeBannedUntilSnack(
                    formatWriteBanUntil(e.until.toLocal()),
                  ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Отправить в трекер ошибку действия чата, которую увидел пользователь.
  /// Тег [action] отделяет пути: снек бывает общий на несколько действий
  /// (`messageEditFailed` — и правка сообщения, и правка альбома).
  void _reportActionFailed(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(e, st, tags: {'chat.action': action});
  }

  /// **B12**: commit edit. После apply — `_editTarget = null`, composer
  /// возвращается в обычный send-mode (через ValueListenable rebuild).
  Future<void> _edit(
    String matrixEventId,
    String newBody, {
    List<int>? mentionedMessengerUserIds,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = NsgL10n.of(context);
    try {
      await _controller.editMessage(
        matrixEventId: matrixEventId,
        newBody: newBody,
        mentionedMessengerUserIds: mentionedMessengerUserIds,
      );
    } catch (e, st) {
      // Без catch editMessage rethrow-ил в unawaited onEdit → unhandled error
      // и ноль фидбека (правка «выглядела» успешной). Показываем snackbar.
      _reportActionFailed(e, st, 'edit');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.messageEditFailed)));
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
  /// * Direct chat → профиль собеседника ([ContactProfileScreen]:
  ///   визитка + «своё имя»/заметка/метки — запрос постановщика
  ///   2026-07-13: правка профиля контакта прямо из чата).
  /// * Group → push [GroupSettingsScreen]; экран сам предлагает
  ///   rename (через callback ниже), список участников, кнопку
  ///   «Добавить участников». После возврата делаем `_fetchRoomDetails`
  ///   — заголовок мог поменяться, или мог добавиться участник.
  Future<void> _onTitleTap() async {
    final details = _roomDetails;
    if (details == null) return;
    if (widget.controllerOverride != null) return;
    if (details.roomType == RoomType.direct) {
      final me = MessengerRuntime.instance.currentMessengerUserId;
      RoomParticipant? peer;
      for (final p in details.participants) {
        if (p.messengerUserId != me) {
          peer = p;
          break;
        }
      }
      if (peer == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ContactProfileScreen(
            contactMessengerUserId: peer!.messengerUserId,
          ),
        ),
      );
      if (!mounted) return;
      // Alias мог смениться — заголовок и список чатов подтянут свежее.
      MessengerRuntime.instance.rooms.invalidate();
      await _fetchRoomDetails();
      return;
    }
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
    } catch (e, st) {
      _reportActionFailed(e, st, 'rename');
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
  Future<void> _sendAttachment(
    PickedAttachment picked, {
    String? albumId,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    try {
      await _controller.sendAttachment(
        bytes: picked.bytes,
        mimeType: picked.mimeType,
        originalFilename: picked.originalFilename,
        albumId: albumId,
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'sendAttachment');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.attachUploadFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **Оптимистичный альбом**: отправить пачку картинок (+опц. подпись)
  /// одним альбомом — мгновенная мозаика, фоновый аплоад в контроллере.
  /// Композер зовёт БЕЗ await, поле свободно сразу.
  void _sendAlbum(
    List<PickedAttachment> images, {
    String caption = '',
    List<int>? mentions,
  }) {
    _controller.sendAlbumOptimistic(
      images: images,
      caption: caption,
      mentions: mentions,
    );
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
      // «Изменить» → inline edit в композере (тот же ввод/визуал, удобно
      // для длинных сообщений), а не отдельный диалог. Если сообщение —
      // член реального альбома (≥2 членов, own), открываем album-edit
      // (картинки + подпись); иначе — обычный edit одного сообщения.
      onStartEdit: (msg) {
        final album = _buildAlbumEditFor(msg);
        if (album != null) {
          _editTarget.value = null;
          _albumEditTarget.value = album;
        } else {
          _albumEditTarget.value = null;
          _editTarget.value = msg;
        }
      },
      // «Выбрать» → войти в режим мультивыбора, стартуя с этого сообщения.
      onSelectMessage: _enterSelection,
      // **TASK69 2C**: «Ответить с упоминанием» — только в группах, для
      // чужих сообщений, и если автор резолвится в участника (иначе некого
      // упоминать). В 1:1 и для своих сообщений — избыточно (пункт скрыт).
      onReplyWithMention:
          (!_isDirectRoom && !isOwn && _authorParticipant(m) != null)
          ? _replyWithMention
          : null,
      // **Issue #35**: пункт «Закрепить/Открепить» — только если у viewer-а
      // есть права (direct — всегда; группы — admin/owner).
      canPin: _canPinMessages,
    );
  }

  /// **TASK69 2C**: участник-автор сообщения (по matrixUserId отправителя).
  RoomParticipant? _authorParticipant(ChatMessage m) =>
      _participantsByMatrixId?[m.senderMatrixUserId];

  /// **TASK69 2C**: ответить на [m] + упомянуть его автора. Ставит reply-target
  /// (как обычный reply) и эмитит автора в композер — тот вставит `@имя `.
  void _replyWithMention(ChatMessage m) {
    final author = _authorParticipant(m);
    if (author == null) return;
    _controller.setReplyTarget(m);
    _mentionInserts.add(author);
  }

  /// **TASK69 2C**: тап по аватару peer-а в групповом пузыре → мини-шит с
  /// «Упомянуть». Отдельный шаг (а не мгновенная вставка) — чтобы случайный
  /// тап по аватару не портил черновик. По подтверждению эмитим участника в
  /// композер (тот вставит `@имя `).
  Future<void> _onMentionSenderTap(String senderMatrixUserId) async {
    final p = _participantsByMatrixId?[senderMatrixUserId];
    if (p == null) return;
    final l = NsgL10n.of(context);
    final name =
        p.displayName ??
        _matrixLocalpartOf(senderMatrixUserId) ??
        senderMatrixUserId;
    final picked = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: NsgAvatarImage(
                mxcUrl: p.avatarUrl,
                fallbackName: name,
                size: 36,
              ),
              title: Text(name),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text(l.mentionParticipantAction),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (picked == true) _mentionInserts.add(p);
  }

  /// Matrix-localpart (`@name:server` → `name`); null если формат неожиданный.
  static String? _matrixLocalpartOf(String matrixUserId) {
    if (!matrixUserId.startsWith('@')) return null;
    final colon = matrixUserId.indexOf(':');
    if (colon <= 1) return null;
    return matrixUserId.substring(1, colon);
  }

  /// **Пересылка (мультивыбор)**: войти в режим выбора, добавив [m] первым.
  void _enterSelection(ChatMessage m) {
    final key = _messageKey(m);
    if (key == null) return;
    setState(() => _selectedKeys.add(key));
  }

  /// **Пересылка (мультивыбор)**: тоггл выбора [m]. Если после снятия выбор
  /// опустел — режим авто-выходит (`_inSelection` станет false).
  void _toggleSelect(ChatMessage m) {
    final key = _messageKey(m);
    if (key == null) return;
    setState(() {
      if (!_selectedKeys.remove(key)) _selectedKeys.add(key);
    });
  }

  /// **Пересылка (мультивыбор)**: выйти из режима, очистив выбор.
  void _clearSelection() {
    if (_selectedKeys.isEmpty) return;
    setState(_selectedKeys.clear);
  }

  /// **Пересылка (мультивыбор)**: резолв `_selectedKeys` → сообщения из
  /// текущего state, отсортированные по времени (ASC) — в этом порядке
  /// [MessagesController.forwardMessages] шлёт их в целевой чат.
  List<ChatMessage> _resolveSelectedMessages() {
    final state = _controller.state;
    if (state is! MessagesReady) return const <ChatMessage>[];
    final selected = state.messages.where((m) {
      final k = _messageKey(m);
      return k != null && _selectedKeys.contains(k);
    }).toList()..sort((a, b) => a.serverTimestamp.compareTo(b.serverTimestamp));
    return selected;
  }

  /// **Пересылка (мультивыбор)**: переслать выбранные сообщения пачкой в
  /// выбранный чат. Пикер тот же ([showForwardPicker]); успех → очистка
  /// выбора + снек; ошибка — снек об ошибке (выбор сохраняется для повтора).
  Future<void> _forwardSelected() async {
    final messages = _resolveSelectedMessages();
    if (messages.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    // **F1**: мультивыбор целевых чатов — переслать сразу во все.
    final rooms = await showForwardPickerMulti(
      context: navigator.context,
      roomsLoader: widget.forwardRoomsLoaderOverride,
    );
    if (rooms == null || rooms.isEmpty) return;
    try {
      await _controller.forwardMessagesToRooms(
        targetRoomIds: rooms.map((r) => r.id).toList(growable: false),
        messages: messages,
      );
      if (mounted) _clearSelection();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.forwardedToChatsSnack(rooms.length)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'forwardSelected');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.forwardFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **Редактирование альбома**: если [m] принадлежит реальному альбому
  /// (≥2 членов с общим `albumId` в текущем state), собрать [ComposerAlbumEdit]
  /// — картинки (`attachment != null`) в порядке `serverTimestamp`, подпись
  /// (член без вложения с непустым body). Иначе — `null` (обычный edit).
  ComposerAlbumEdit? _buildAlbumEditFor(ChatMessage m) {
    final aid = m.albumId;
    if (aid == null || aid.isEmpty) return null;
    final state = _controller.state;
    if (state is! MessagesReady) return null;
    final members = state.messages
        .where((x) => x.albumId == aid)
        .toList(growable: false);
    if (members.length < 2) return null; // одиночка с albumId — не альбом

    final imageMembers = members.where((x) => x.attachment != null).toList()
      ..sort((a, b) => a.serverTimestamp.compareTo(b.serverTimestamp));
    // Нужен stable matrixEventId у каждой картинки (redact-таргет). Pending/
    // failed без eventId в album-edit не попадают — их правка бессмысленна.
    final images = <ComposerAlbumImage>[];
    for (final x in imageMembers) {
      final eventId = x.matrixEventId;
      if (eventId == null) continue;
      images.add(
        ComposerAlbumImage(attachment: x.attachment!, matrixEventId: eventId),
      );
    }
    if (images.isEmpty) return null;

    // Подпись — член без вложения с непустым body (берём самый ранний).
    final caps =
        members
            .where((x) => x.attachment == null && x.body.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => a.serverTimestamp.compareTo(b.serverTimestamp));
    final caption = caps.isNotEmpty ? caps.first : null;

    return ComposerAlbumEdit(
      albumId: aid,
      images: images,
      captionBody: caption?.body ?? '',
      captionEventId: caption?.matrixEventId,
    );
  }

  /// **Редактирование альбома**: commit диффа. После apply — сброс
  /// `_albumEditTarget` (composer возвращается в обычный режим). Errors →
  /// snackbar (best-effort; отдельные операции могли частично примениться).
  Future<void> _editAlbum(ComposerAlbumEditResult result) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = NsgL10n.of(context);
    try {
      await _controller.editAlbum(result);
    } catch (e, st) {
      _reportActionFailed(e, st, 'editAlbum');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.messageEditFailed)));
    } finally {
      if (mounted) _albumEditTarget.value = null;
    }
  }

  void _cancelAlbumEdit() {
    _albumEditTarget.value = null;
  }

  /// **TASK16-A**: best-effort scroll-to-original при tap по reply chip.
  /// Per Q1 — MVP только если original виден в state.messages (cache hit
  /// в lookup). Phase2 — fetch + scroll, см. backlog.
  /// **Issue #35**: открепить из плашки. Ошибку прав/сети показываем
  /// snackbar-ом (плашка сама обновится по realtime / loadPinned).
  Future<void> _unpinFromBanner(String matrixEventId) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    try {
      await _controller.unpinMessage(matrixEventId);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.messageUnpinnedSnack),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'message.action': 'unpinBanner'},
      );
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.unpinMessageFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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

  /// **Issue #41**: одноразовый прыжок к [ChatScreen.initialTargetEventId] —
  /// сообщению, ради которого экран открыли. Переиспользует
  /// [_scrollToSearchResult] (догрузка истории страницами + понятный отказ),
  /// а не «тихий» [_scrollToOriginal]: экран только что открыт, целевое
  /// сообщение почти наверняка старше первой страницы.
  ///
  /// Флаг взводим ДО запуска: `_onStateChange` дёргается на каждой
  /// подгруженной странице, а `_scrollToSearchResult` эти страницы и грузит —
  /// без флага прыжок рекурсивно перезапускал бы сам себя.
  void _maybeJumpToInitialTarget() {
    if (_initialJumpStarted) return;
    final target = widget.initialTargetEventId;
    if (target == null || target.isEmpty) return;
    if (_controller.state is! MessagesReady) return;
    _initialJumpStarted = true;
    unawaited(_scrollToSearchResult(target));
  }

  /// **Issue #41**: тап по шапке «Переслано от X» — открыть первоисточник.
  ///
  /// Два случая:
  ///   * источник в ЭТОЙ же комнате (переслали внутри одного чата) — не
  ///     плодим второй экран той же комнаты, просто скроллим, как по тапу в
  ///     закреплённых/поиске;
  ///   * источник в ДРУГОЙ комнате — открываем её поверх текущей тем же
  ///     [openChatRoom], что и тап по пуш-уведомлению, и просим проскроллить
  ///     к исходному сообщению сразу после загрузки истории.
  ///
  /// Доступность комнаты проверяем ДО перехода. Пересланное сообщение живёт
  /// своей жизнью: его могли переслать из чата, куда текущего пользователя
  /// никогда не пускали, — и это НОРМА, а не сбой. Без пред-проверки юзер
  /// упёрся бы в пустой экран: `_fetchRoomDetails` глотает
  /// [RoomUnavailableException] молча (там это оправдано — детали комнаты
  /// лишь украшают чат), поэтому спрашиваем сами и отвечаем внятно.
  Future<void> _openForwardSource(ForwardSource source) async {
    if (source.roomId == widget.roomId) {
      await _scrollToSearchResult(source.eventId);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    final navigator = Navigator.of(context);
    final probe =
        widget.forwardSourceProbeOverride ??
        (int roomId) => MessengerRuntime.instance.rooms.get(roomId);
    try {
      await probe(source.roomId);
    } on RoomUnavailableException {
      // Штатный промах: комнаты нет, она чужого тенанта или мы не участник.
      // Сервер намеренно не различает эти случаи (анти-перебор) — и нам
      // нечего добавить, кроме «сюда нельзя».
      _showForwardSourceUnavailable(messenger, l);
      return;
    } catch (e, st) {
      // Всё остальное (сеть, таймаут, неожиданный отказ) — тот же отказ
      // пользователю, но с телеметрией: это уже не штатный промах.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'message.action': 'openForwardSource'},
      );
      _showForwardSourceUnavailable(messenger, l);
      return;
    }
    if (!mounted) return;
    await openChatRoom(
      navigator,
      roomId: source.roomId,
      initialTargetEventId: source.eventId,
      // Нужен именно свежий экран с прыжком к сообщению: «комната уже
      // открыта» здесь не ответ — пользователь просил конкретное сообщение,
      // а не комнату.
      skipIfOnTop: false,
    );
  }

  void _showForwardSourceUnavailable(
    ScaffoldMessengerState? messenger,
    NsgL10n l,
  ) {
    if (!mounted) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.forwardSourceUnavailable),
        duration: const Duration(seconds: 3),
      ),
    );
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

  /// **TASK45 фаза 2**: объектовый ли это чат — productRoom с
  /// productEntityType='object'. Признак берём из [RoomDetails]
  /// (`roomType` не различает object от прочих productRoom, а
  /// `productEntityType` — различает). По нему показываем action
  /// «Обратиться к разработчикам».
  bool get _isObjectRoom {
    final d = _roomDetails;
    return d != null &&
        d.roomType == RoomType.productRoom &&
        d.productEntityType == _kObjectRoomEntityType;
  }

  /// **TASK45 фаза 2**: подключить команду поддержки NSG к этому
  /// объектовому чату. Видят кнопку ВСЕ участники объектового чата. По
  /// нажатию — escalateToSupportTeam(roomId) + снекбар «Команда NSG
  /// подключена». Ошибка — снекбар с текстом ошибки.
  Future<void> _escalateToSupportTeam() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    final fn =
        widget.escalateOverride ??
        (widget.controllerOverride == null
            ? ({required int roomId}) => MessengerRuntime
                  .instance
                  .client
                  .messenger
                  .escalateToSupportTeam(roomId: roomId)
            : null);
    if (fn == null) return;
    try {
      await fn(roomId: widget.roomId);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.escalateToDevelopersDone),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'escalateToSupportTeam');
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.escalateToDevelopersFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **TASK48**: можно ли эскалировать этот support-чат на старший тир.
  /// Флаг считает сервер (`RoomDetails.canEscalateSupport`): true ⟺ комната
  /// support-типа, viewer — оператор-член И есть непустой тир выше.
  bool get _canEscalateSupport => _roomDetails?.canEscalateSupport == true;

  /// **TASK48**: позвать старшего оператора (следующий тир) в support-чат.
  /// escalateSupportRoom(roomId) + снекбар. Зеркалит [_escalateToSupportTeam].
  Future<void> _escalateSupportRoom() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    final fn =
        widget.escalateSupportOverride ??
        (widget.controllerOverride == null
            ? ({required int roomId}) => MessengerRuntime
                  .instance
                  .client
                  .messenger
                  .escalateSupportRoom(roomId: roomId)
            : null);
    if (fn == null) return;
    try {
      // **Review fix #5**: сервер на no-op (проиграна гонка / нет тира
      // выше / полный откат инвайтов) отвечает БЕЗ исключения — пустым
      // addedMessengerUserIds. Различаем «подключили» и «некого» вместо
      // безусловного успеха.
      final result = await fn(roomId: widget.roomId);
      // Рефреш деталей — canEscalateSupport пересчитается на сервере
      // (после успеха тир поднят / оператор уже есть → кнопка исчезнет),
      // иначе она осталась бы висеть и повторные тапы снова «успех».
      await _fetchRoomDetails();
      if (!mounted) return;
      final connected = result.addedMessengerUserIds.isNotEmpty;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            connected ? l.escalateSupportDone : l.escalateSupportNoop,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'escalateSupport');
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.escalateSupportFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **TASK46 (UI)**: direct 1:1 ли эта комната. Кнопка «Позвонить»
  /// показывается только для direct — звонки MVP только 1:1.
  bool get _isDirectRoom => _roomDetails?.roomType == RoomType.direct;

  /// **TASK68**: раздел «Избранного» — комната с единственным участником
  /// (собой). Всё, что подразумевает собеседника, тут бессмысленно:
  /// звонки и presence уже отсечены гейтом `direct`-only, остаётся
  /// «печатает» (см. wiring композера).
  bool get _isSavedRoom => _roomDetails?.roomType == RoomType.saved;

  /// **Issue #39**: нужна ли над peer-пузырями подпись «кто написал».
  ///
  /// Раньше признаком был частный случай `roomType == group`, из-за чего
  /// support-лента (бот + операторы + сам пользователь) выглядела как
  /// монолог: непонятно, где автоответ, а где живой человек. Правильный
  /// критерий не «это группа», а «собеседник может быть не один»:
  ///
  ///   * direct / «Избранное» — собеседник ровно один (или его нет),
  ///     подпись была бы шумом на каждом пузыре → скрываем;
  ///   * всё остальное — показываем, если в комнате больше двух
  ///     участников ИЛИ среди них есть бот/интеграция. Второе условие
  ///     важно для свежей support-комнаты, где пока только пользователь
  ///     и бот: участников двое, но подписать их всё равно надо.
  ///
  /// До загрузки `_roomDetails` — false (подпись появится вместе с
  /// участниками; резолвить имена всё равно нечем).
  bool get _showsSenderNames {
    final details = _roomDetails;
    if (details == null) return false;
    switch (details.roomType) {
      case RoomType.direct:
      case RoomType.saved:
        return false;
      case RoomType.group:
      case RoomType.team:
      case RoomType.support:
      case RoomType.family:
      case RoomType.internal:
      case RoomType.system:
      case RoomType.productRoom:
      case RoomType.customerRoom:
        return details.totalParticipants > 2 || _hasNonHumanParticipant;
    }
  }

  /// Есть ли в комнате «не человек» — бот, интеграция или AI-агент.
  /// Признак приходит в `RoomParticipant.participantKind`; старый сервер
  /// его не шлёт (null) — тогда решает только число участников.
  bool get _hasNonHumanParticipant =>
      _roomDetails?.participants.any(
        (p) =>
            p.participantKind == ParticipantKind.bot ||
            p.participantKind == ParticipantKind.integration ||
            p.participantKind == ParticipantKind.aiAgent,
      ) ??
      false;

  /// **Issue #35**: может ли текущий viewer закреплять сообщения — direct:
  /// любой участник; группы/прочее: admin/owner (совпадает с серверным
  /// [PinPolicy]). До загрузки `_roomDetails` и в read-only — false (пункт
  /// скрыт). Финальный guard прав — на сервере.
  bool get _canPinMessages {
    final details = _roomDetails;
    if (details == null || widget.readOnly) return false;
    if (details.roomType == RoomType.direct) return true;
    return details.viewerRole == RoomMemberRole.owner ||
        details.viewerRole == RoomMemberRole.admin;
  }

  /// **TASK46 (UI)**: messengerUserId собеседника в direct-комнате —
  /// единственный участник, чей id ≠ self. Нужен для показа имени в
  /// overlay-е исходящего звонка (сигналинг адресуется через roomId).
  /// null, если участники ещё не загружены или self не найден среди них.
  int? get _peerMessengerUserId {
    final d = _roomDetails;
    if (d == null || d.roomType != RoomType.direct) return null;
    final self = _controller.selfMessengerUserId;
    for (final p in d.participants) {
      if (p.messengerUserId != self) return p.messengerUserId;
    }
    return null;
  }

  /// **TASK46 (UI)**: начать исходящий голосовой звонок собеседнику
  /// (direct 1:1). Сигналинг/pc/микрофон — в `CallController`; UI
  /// (overlay «Звоним…») поднимает `CallOverlayHost` в корне навигации
  /// по смене `CallState`. Здесь — только команда.
  /// **TASK46 (UI)**: displayName собеседника direct-комнаты (участник с
  /// id ≠ self) — чтобы overlay исходящего показал «Звоним <имя>», а не
  /// «Собеседник». null, если участники не загружены / имя пустое.
  String? get _peerDisplayName {
    final d = _roomDetails;
    if (d == null || d.roomType != RoomType.direct) return null;
    final self = _controller.selfMessengerUserId;
    for (final p in d.participants) {
      if (p.messengerUserId != self) {
        final n = p.displayName?.trim();
        return (n != null && n.isNotEmpty) ? n : null;
      }
    }
    return null;
  }

  /// **TASK51 (UI)**: групповая ли эта комната. Кнопка «Групповой звонок»
  /// и плашка «идёт конференция» — только для RoomType.group (в direct
  /// остаётся 1:1; team/support/прочее — вне итерации 1).
  bool get _isGroupRoom => _roomDetails?.roomType == RoomType.group;

  /// **TASK51 (UI)**: контроллер конференций — override (тесты) или
  /// runtime. null в test-mode без override и в окне teardown/reinit
  /// (тогда кнопка/плашка просто не работают — как 1:1-паттерн).
  ConferenceCallController? get _conferenceCalls =>
      widget.conferenceCallsOverride ??
      (widget.controllerOverride == null
          ? MessengerRuntime.instance.conferenceCallsOrNull
          : null);

  /// **TASK51 (UI)**: «позвонить всем в группе» / «присоединиться к
  /// идущей» — обе команды сводятся к `conferenceCalls.join(roomId)`
  /// (сервер создаст конференцию при отсутствии; MVP без выбора
  /// подмножества участников). Гейт второго звонка — как в 1:1.
  Future<void> _startConferenceCall() async {
    final ctrl = _conferenceCalls;
    if (ctrl == null) return;
    // Запрет параллельного звонка: идёт конференция ИЛИ 1:1 (общий
    // микрофон/аудио-сессия — одновременно нельзя). 1:1 проверяем только
    // в production (в test-mode runtime недоступен).
    final oneOnOneBusy =
        widget.conferenceCallsOverride == null &&
        widget.controllerOverride == null &&
        (MessengerRuntime.instance.callsOrNull?.isBusy ?? false);
    if (ctrl.isBusy || oneOnOneBusy) {
      final l = NsgL10n.of(context);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l.callAlreadyActive)));
      return;
    }
    await ctrl.join(roomId: widget.roomId);
  }

  Future<void> _startCall() async {
    // Запрет второго звонка: если уже идёт (любая фаза, кроме idle/ended) —
    // не начинаем новый, показываем подсказку. Hold/конференция — на
    // будущее. В test-mode (любой override) runtime недоступен — скип.
    if (widget.controllerOverride == null &&
        widget.startCallOverride == null &&
        MessengerRuntime.instance.calls.isBusy) {
      final l = NsgL10n.of(context);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l.callAlreadyActive)));
      return;
    }
    final fn =
        widget.startCallOverride ??
        (widget.controllerOverride == null
            ? ({
                required int roomId,
                int? peerMessengerUserId,
                String? peerDisplayName,
              }) => MessengerRuntime.instance.calls.startCall(
                roomId: roomId,
                peerMessengerUserId: peerMessengerUserId,
                peerDisplayName: peerDisplayName,
              )
            : null);
    if (fn == null) return;
    await fn(
      roomId: widget.roomId,
      peerMessengerUserId: _peerMessengerUserId,
      peerDisplayName: _peerDisplayName,
    );
  }

  /// **Пересылка (мультивыбор)**: селекшн-аппбар вместо обычного заголовка,
  /// пока активен режим выбора. Крестик — выйти (очистить выбор), заголовок —
  /// счётчик выбранных, иконка «Переслать» — пачечная пересылка.
  PreferredSizeWidget _buildSelectionAppBar(BuildContext context) {
    final l = NsgL10n.of(context);
    return AppBar(
      key: const Key('chatSelectionAppBar'),
      leading: IconButton(
        key: const Key('chatSelectionClose'),
        icon: const Icon(Icons.close),
        tooltip: l.commonCancel,
        onPressed: _clearSelection,
      ),
      title: Text(l.selectedCountTitle(_selectedKeys.length)),
      actions: [
        IconButton(
          key: const Key('chatSelectionForward'),
          icon: const Icon(Icons.forward),
          tooltip: l.messageActionForward,
          onPressed: _forwardSelected,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Единая точка перехвата «назад» (системный жест + стрелка в шапке — обе
    // идут через Navigator.maybePop → PopScope). Приоритеты:
    //   1) режим мультивыбора → выходим из выбора, а не из экрана
    //      (Telegram-style, TASK «Пересылка»);
    //   2) телефонный рабочий набор с историей ([canNavigateBack]) →
    //      возврат в предыдущий чат набора (issue #17), НЕ покидая пейджер;
    //   3) иначе — обычный back (покидаем экран / пейджер → список).
    // Взаимоисключение (1) и (2) в ОДНОМ обработчике не даёт back в режиме
    // выбора заодно перепрыгнуть на другой чат.
    return PopScope(
      canPop: !_inSelection && !widget.canNavigateBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_inSelection) {
          _clearSelection();
          return;
        }
        if (widget.canNavigateBack) widget.onNavigateBack?.call();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: _inSelection
          ? _buildSelectionAppBar(context)
          : AppBar(
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
                      lastSeen: _peerLastSeen,
                      online: _peerOnline,
                    ),
              actions: [
                // **TASK66 (телефон)**: переключатель чатов — тап открывает
                // шит недавних; бейдж с числом = сколько чатов набора живы.
                if (widget.onOpenSwitcher != null)
                  IconButton(
                    key: const Key('chatSwitcherButton'),
                    tooltip: 'Недавние чаты',
                    onPressed: widget.onOpenSwitcher,
                    icon: Badge(
                      isLabelVisible: widget.pagerSetSize >= 2,
                      label: Text('${widget.pagerSetSize}'),
                      child: const Icon(Icons.dynamic_feed_outlined),
                    ),
                  ),
                // **TASK46 (UI)**: кнопка «Позвонить» — только для direct 1:1
                // (звонки MVP аудио 1:1). Резолвит собеседника из participants и
                // зовёт CallController.startCall; overlay «Звоним…» поднимает
                // CallOverlayHost в корне навигации. В test-mode
                // (`startCallOverride`) тоже показываем, чтобы widget-тест мог
                // проверить visibility + вызов команды.
                if (_isDirectRoom &&
                    (widget.controllerOverride == null ||
                        widget.startCallOverride != null))
                  IconButton(
                    key: const Key('chatCallButton'),
                    icon: const Icon(Icons.call),
                    tooltip: NsgL10n.of(context).callStartTooltip,
                    onPressed: _startCall,
                  ),
                // **TASK51 (UI)**: кнопка «Групповой звонок» — только для
                // group-комнат (mesh-конференция, «позвонить всем»). Тап =
                // conferenceCalls.join(roomId); оверлей конференции
                // поднимает ConferenceOverlayHost в корне навигации. В
                // test-mode показываем при переданном fake-контроллере.
                if (_isGroupRoom &&
                    (widget.controllerOverride == null ||
                        widget.conferenceCallsOverride != null))
                  IconButton(
                    key: const Key('chatConferenceCallButton'),
                    icon: const Icon(Icons.groups),
                    tooltip: NsgL10n.of(context).conferenceStartTooltip,
                    onPressed: _startConferenceCall,
                  ),
                if (widget.controllerOverride == null)
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Поиск',
                    onPressed: _openSearchScreen,
                  ),
                // **TASK45 фаза 2**: overflow-action «Обратиться к разработчикам»
                // — только для объектовых чатов; видят ВСЕ участники (кнопка не
                // гейтится ролью). titan получает её автоматически (openRoom →
                // ChatScreen). В test-mode (controllerOverride) тоже показываем,
                // чтобы widget-тест мог проверить visibility.
                if (_isObjectRoom || _canEscalateSupport)
                  PopupMenuButton<_ChatOverflowAction>(
                    key: const Key('chatOverflowMenu'),
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _ChatOverflowAction.escalate:
                          _escalateToSupportTeam();
                        case _ChatOverflowAction.escalateSupport:
                          _escalateSupportRoom();
                      }
                    },
                    itemBuilder: (context) => [
                      if (_isObjectRoom)
                        PopupMenuItem<_ChatOverflowAction>(
                          key: const Key('escalateToDevelopersItem'),
                          value: _ChatOverflowAction.escalate,
                          child: Row(
                            children: [
                              const Icon(Icons.support_agent, size: 20),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  NsgL10n.of(
                                    context,
                                  ).escalateToDevelopersAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_canEscalateSupport)
                        PopupMenuItem<_ChatOverflowAction>(
                          key: const Key('escalateSupportItem'),
                          value: _ChatOverflowAction.escalateSupport,
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_upward, size: 20),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  NsgL10n.of(context).escalateSupportAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
          // **Issue #35**: плашка закреплённых сообщений над лентой. Тап по
          // телу — переход к сообщению (+ циклический перебор при нескольких);
          // кнопка «открепить» — если у viewer-а есть права.
          ValueListenableBuilder<List<ChatMessage>>(
            valueListenable: _controller.pinnedListenable,
            builder: (context, pinned, _) {
              if (pinned.isEmpty) return const SizedBox.shrink();
              return _PinnedBanner(
                pinned: pinned,
                canUnpin: _canPinMessages,
                onTapMessage: (m) {
                  final id = m.matrixEventId;
                  if (id != null) unawaited(_scrollToSearchResult(id));
                },
                onUnpin: (m) {
                  final id = m.matrixEventId;
                  if (id != null) unawaited(_unpinFromBanner(id));
                },
              );
            },
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
                // **Emoji reactions**: nested version listenable — rebuild
                // когда агрегат реакций изменился (add/remove). Дёшево,
                // ListView.builder сам решает что перерисовать.
                builder: (context, _, _) => ValueListenableBuilder<int>(
                  valueListenable: _controller.reactionsVersionListenable,
                  builder: (context, _, _) => _Body(
                    state: state,
                    selfMessengerUserId: _controller.selfMessengerUserId,
                    onScroll: _onScroll,
                    onRetry: _retry,
                    onLongPressMessage: _onLongPressMessage,
                    // **Пересылка (мультивыбор)**: режим выбора + тоггл.
                    selectionMode: _inSelection,
                    isSelected: (m) {
                      final k = _messageKey(m);
                      return k != null && _selectedKeys.contains(k);
                    },
                    onToggleSelect: _toggleSelect,
                    scrollController: _scrollController,
                    itemKeys: _itemKeys,
                    findReplyTarget: _findReplyTarget,
                    onReplyChipTap: _scrollToOriginal,
                    onForwardedHeaderTap: _openForwardSource,
                    participantsByMessengerId: _participantsByMessengerId,
                    participantsByMatrixId: _participantsByMatrixId,
                    readByPeerCountFor: (m) =>
                        _controller.readByPeerMatrixIds(m).length,
                    isGroupChat: _roomDetails?.roomType == RoomType.group,
                    // **Issue #39**: подпись отправителя — шире, чем
                    // `isGroupChat` (тот заодно рулит read-receipt-ами
                    // и аватарами, его семантику не трогаем).
                    showSenderNames: _showsSenderNames,
                    // **TASK52 итер.2**: интро-карточка в пустом direct-чате.
                    introCard: _roomDetails?.roomType == RoomType.direct
                        ? _introCard
                        : null,
                    onTapReadStatus: _openReadReceiptsSheet,
                    reactionsFor: (m) => m.matrixEventId == null
                        ? const <ReactionGroup>[]
                        : _controller.reactionsFor(m.matrixEventId!),
                    onToggleReaction: (m, key) {
                      final id = m.matrixEventId;
                      if (id == null) return;
                      _controller.toggleReaction(id, key);
                    },
                    thumbnailRpc:
                        ({required String mxcUrl, int? width, int? height}) =>
                            _controller.downloadThumbnail(
                              mxcUrl: mxcUrl,
                              width: width,
                              height: height,
                            ),
                    fullSizeRpc: ({required String mxcUrl}) =>
                        _controller.downloadFullSize(mxcUrl: mxcUrl),
                    // **TASK69 2C**: тап по аватару peer-а в группе → «Упомянуть».
                    onMentionSender: _onMentionSenderTap,
                  ),
                ),
              ),
            ),
          ),
          // **TASK51 (UI)**: плашка «идёт групповой звонок» над композером
          // — если в комнате живая конференция, а мы не в ней. Данные — из
          // контроллера конференций (ChangeNotifier): карта живых
          // конференций комнат наполняется событиями `conferenceUpdated` +
          // разовым refresh при открытии экрана (см. initState).
          if (_conferenceCalls != null)
            ListenableBuilder(
              listenable: _conferenceCalls!,
              builder: (context, _) {
                final ctrl = _conferenceCalls;
                final info = ctrl?.liveConferenceInRoom(widget.roomId);
                if (ctrl == null || info == null) {
                  return const SizedBox.shrink();
                }
                // Уже в этой конференции (входим/активна) — плашка не
                // нужна, оверлей и так поверх всего.
                final s = ctrl.state;
                final inThisRoom = switch (s) {
                  ConferenceJoining(:final roomId) => roomId == widget.roomId,
                  ConferenceActive(:final roomId) => roomId == widget.roomId,
                  _ => false,
                };
                if (inThisRoom) return const SizedBox.shrink();
                return _ConferenceOngoingBanner(
                  memberCount: info.memberCount,
                  onJoin: _startConferenceCall,
                );
              },
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
                          builder: (context, editTarget, _) =>
                              ValueListenableBuilder<ComposerAlbumEdit?>(
                                valueListenable: _albumEditTarget,
                                builder: (context, albumEdit, _) {
                                  // Album-edit подавляет reply/edit-режимы
                                  // (взаимоисключающи).
                                  final inAlbumEdit = albumEdit != null;
                                  final effectiveEdit = inAlbumEdit
                                      ? null
                                      : editTarget;
                                  final senderName = replyTarget == null
                                      ? null
                                      : (_participantsByMatrixId?[replyTarget
                                                    .senderMatrixUserId]
                                                ?.displayName ??
                                            replyTarget.senderMatrixUserId);
                                  return MessageComposer(
                                    onSend: _send,
                                    enabled: state is MessagesReady,
                                    initialText: widget.initialDraft,
                                    onSendAttachment: _sendAttachment,
                                    onSendAlbum: _sendAlbum,
                                    // Reply hidden когда композер в edit /
                                    // album-edit режиме — они не сосуществуют.
                                    replyTarget:
                                        (effectiveEdit == null && !inAlbumEdit)
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
                                    editTarget: effectiveEdit,
                                    onEdit: _edit,
                                    onCancelEdit: effectiveEdit == null
                                        ? null
                                        : _cancelEdit,
                                    onRequestEditLast: _requestEditLast,
                                    // **TASK68**: в self-чате «печатает»
                                    // некому — не тратим RPC на каждый
                                    // debounce-тик композера.
                                    onTyping: _isSavedRoom
                                        ? null
                                        : _controller.sendTyping,
                                    // **Редактирование альбома** wiring.
                                    albumEdit: albumEdit,
                                    onEditAlbum: _editAlbum,
                                    onCancelAlbumEdit: inAlbumEdit
                                        ? _cancelAlbumEdit
                                        : null,
                                    albumThumbnailRpc:
                                        ({
                                          required String mxcUrl,
                                          int? width,
                                          int? height,
                                        }) => _controller.downloadThumbnail(
                                          mxcUrl: mxcUrl,
                                          width: width,
                                          height: height,
                                        ),
                                    albumFullSizeRpc:
                                        ({required String mxcUrl}) =>
                                            _controller.downloadFullSize(
                                              mxcUrl: mxcUrl,
                                            ),
                                    // **TASK69 2C**: «упоминания из контекста»
                                    // (Ответить с упоминанием / тап по аватару).
                                    mentionInsertRequests:
                                        _mentionInserts.stream,
                                  );
                                },
                              ),
                        ),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Лента просмотрщика: только те вложения, которые галерея умеет
/// показать — `image/*` С готовым превью. Видео/аудио/файлы (у них свой
/// `_FileRow`) и картинки без `thumbnailMxcUrl` (HEIC без server-side
/// декодера — рендерятся файловой строкой, а не превью) в набор НЕ
/// попадают: иначе листание упиралось бы в страницы, которые нечем
/// нарисовать, а индикатор «N / total» врал бы про количество.
///
/// Порядок — хронологический: лента приходит DESC (новые сверху при
/// `reverse: true`), поэтому обходим reversed.
@visibleForTesting
List<AttachmentRef> collectChatImages(List<ChatMessage> messages) {
  final images = <AttachmentRef>[];
  for (final m in messages.reversed) {
    final a = m.attachment;
    if (a != null &&
        a.mimeType.startsWith('image/') &&
        a.thumbnailMxcUrl != null) {
      images.add(a);
    }
  }
  return images;
}

/// Открыть галерею всех картинок чата, стартуя с [tapped]. Собирает
/// image-вложения из [messages] в хронологическом порядке (лента —
/// DESC, поэтому reversed), находит индекс тапнутой и пушит
/// [ChatImageGallery] с листанием.
void _openChatImageGallery(
  BuildContext context,
  List<ChatMessage> messages,
  AttachmentRef tapped,
  DownloadAttachmentThumbnailRpc thumbnailRpc,
  DownloadAttachmentRpc fullSizeRpc,
) {
  final images = collectChatImages(messages);
  if (images.isEmpty) return;
  var idx = images.indexWhere((a) => a.mxcUrl == tapped.mxcUrl);
  if (idx < 0) idx = 0;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatImageGallery(
        images: images,
        initialIndex: idx,
        thumbnailRpc: thumbnailRpc,
        fullSizeRpc: fullSizeRpc,
      ),
    ),
  );
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
    required this.onForwardedHeaderTap,
    required this.participantsByMessengerId,
    required this.participantsByMatrixId,
    this.readByPeerCountFor,
    this.isGroupChat = false,
    this.showSenderNames = false,
    this.introCard,
    this.onTapReadStatus,
    this.reactionsFor,
    this.onToggleReaction,
    this.selectionMode = false,
    this.isSelected,
    this.onToggleSelect,
    this.onMentionSender,
  });

  final MessagesState state;

  /// **TASK52 итер.2**: визитка собеседника для интро-карточки в пустом
  /// direct-чате (null → показываем обычный empty-state).
  final ContactCardInfo? introCard;

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

  /// **Пересылка (мультивыбор)**: активен ли режим выбора; резолвер «выбран
  /// ли пузырь»; тоггл выбора. Прокидываются в [MessageBubble].
  final bool selectionMode;
  final bool Function(ChatMessage)? isSelected;
  final void Function(ChatMessage)? onToggleSelect;
  final Map<String, GlobalKey> itemKeys;
  final ChatMessage? Function(String) findReplyTarget;
  final void Function(String) onReplyChipTap;

  /// **Issue #41**: тап по шапке «Переслано от X» пересланного
  /// сообщения — открыть первоисточник (может быть в ДРУГОЙ комнате).
  final void Function(ForwardSource) onForwardedHeaderTap;
  final Map<int, RoomParticipant>? participantsByMessengerId;
  final Map<String, RoomParticipant>? participantsByMatrixId;

  /// **B11**: resolver «сколько peer-ов прочитали этот message».
  /// null → не используем read-receipts (test/demo mode); 0 → одна
  /// галочка; 1+ → две синие.
  final int Function(ChatMessage)? readByPeerCountFor;

  /// **B11 group receipts**: `true` если это group-чат — bubble использует
  /// иконку глаза + count вместо ✓✓.
  final bool isGroupChat;

  /// **Issue #39**: показывать ли подпись отправителя над peer-пузырями.
  /// Считается в ChatScreen (`_showsSenderNames`): группы/команды/support
  /// и вообще любая комната, где собеседник может быть не один. Шире, чем
  /// [isGroupChat], поэтому отдельный флаг, а не переиспользование.
  final bool showSenderNames;

  /// **B11 group receipts**: callback для tap-а по counter — обычно
  /// открывает bottom-sheet «прочитали / не прочитали».
  final void Function(ChatMessage)? onTapReadStatus;

  /// **Emoji reactions**: resolver агрегата реакций для сообщения.
  final List<ReactionGroup> Function(ChatMessage)? reactionsFor;

  /// **Emoji reactions**: toggle callback (message + emoji key).
  final void Function(ChatMessage, String key)? onToggleReaction;

  /// **TASK69 2C**: тап по аватару отправителя (group peer-bubble) →
  /// `senderMatrixUserId` наверх (ChatScreen предлагает «Упомянуть»).
  final void Function(String senderMatrixUserId)? onMentionSender;

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
                onForwardedHeaderTap: onForwardedHeaderTap,
                participantsByMessengerId: participantsByMessengerId,
                participantsByMatrixId: participantsByMatrixId,
                readByPeerCountFor: readByPeerCountFor,
                isGroupChat: isGroupChat,
                showSenderNames: showSenderNames,
                introCard: introCard,
                onTapReadStatus: onTapReadStatus,
                reactionsFor: reactionsFor,
                onToggleReaction: onToggleReaction,
                selectionMode: selectionMode,
                isSelected: isSelected,
                onToggleSelect: onToggleSelect,
                onMentionSender: onMentionSender,
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
        onForwardedHeaderTap: onForwardedHeaderTap,
        participantsByMessengerId: participantsByMessengerId,
        participantsByMatrixId: participantsByMatrixId,
        readByPeerCountFor: readByPeerCountFor,
        isGroupChat: isGroupChat,
        showSenderNames: showSenderNames,
        introCard: introCard,
        onTapReadStatus: onTapReadStatus,
        reactionsFor: reactionsFor,
        onToggleReaction: onToggleReaction,
        selectionMode: selectionMode,
        isSelected: isSelected,
        onToggleSelect: onToggleSelect,
        onMentionSender: onMentionSender,
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
    required this.onForwardedHeaderTap,
    required this.participantsByMessengerId,
    required this.participantsByMatrixId,
    this.readByPeerCountFor,
    this.isGroupChat = false,
    this.showSenderNames = false,
    this.introCard,
    this.onTapReadStatus,
    this.reactionsFor,
    this.onToggleReaction,
    this.selectionMode = false,
    this.isSelected,
    this.onToggleSelect,
    this.onMentionSender,
    this.errorBanner,
  });

  final MessagesReady ready;
  final ContactCardInfo? introCard;
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

  /// **Issue #41**: тап по шапке «Переслано от X» пересланного
  /// сообщения — открыть первоисточник (может быть в ДРУГОЙ комнате).
  final void Function(ForwardSource) onForwardedHeaderTap;
  final Map<int, RoomParticipant>? participantsByMessengerId;
  final Map<String, RoomParticipant>? participantsByMatrixId;
  final int Function(ChatMessage)? readByPeerCountFor;
  final bool isGroupChat;

  /// **Issue #39**: см. одноимённое поле в [_Body].
  final bool showSenderNames;
  final void Function(ChatMessage)? onTapReadStatus;
  final List<ReactionGroup> Function(ChatMessage)? reactionsFor;
  final void Function(ChatMessage, String key)? onToggleReaction;

  /// **Пересылка (мультивыбор)**: режим выбора + резолвер/тоггл (см. [_Body]).
  final bool selectionMode;
  final bool Function(ChatMessage)? isSelected;
  final void Function(ChatMessage)? onToggleSelect;

  /// **TASK69 2C**: тап по аватару отправителя (group peer-bubble).
  final void Function(String senderMatrixUserId)? onMentionSender;
  final Object? errorBanner;

  @override
  Widget build(BuildContext context) {
    final messages = ready.messages;
    // **Альбом**: подряд идущие сообщения с одним `albumId` (≥2) —
    // одно визуальное сообщение-мозаика. anchor = первый встреченный при
    // DESC-обходе (самый новый) член; остальные члены скрываем (рендерятся
    // мозаикой на anchor-е). Одиночка с albumId → обычный bubble.
    //
    // **Оптимистичный альбом**: член считается «картинкой» если у него есть
    // либо загруженное вложение, либо локальные грузящиеся байты — иначе
    // грузящиеся плитки выпали бы из порога и мозаики (баг «сразу столько,
    // сколько будет»).
    final albumMembers = <String, List<ChatMessage>>{};
    for (final m in messages) {
      final aid = m.albumId;
      if (aid != null && aid.isNotEmpty) {
        (albumMembers[aid] ??= <ChatMessage>[]).add(m);
      }
    }
    final albumAnchor = <String, int>{};
    final albumSkip = <int>{};
    for (var i = 0; i < messages.length; i++) {
      final aid = messages[i].albumId;
      if (aid == null || aid.isEmpty) continue;
      if ((albumMembers[aid]?.length ?? 0) < 2) continue;
      if (albumAnchor.containsKey(aid)) {
        albumSkip.add(i);
      } else {
        albumAnchor[aid] = i;
      }
    }
    return Column(
      children: [
        if (errorBanner != null) ConnectionLostBanner(error: errorBanner!),
        if (ready.paginating) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: messages.isEmpty
              ? (introCard != null
                    ? _IntroCard(card: introCard!)
                    : _EmptyState())
              : _selectableMessages(
                  context,
                  NotificationListener<ScrollNotification>(
                    onNotification: onScroll,
                    child: ListView.builder(
                      controller: scrollController,
                      reverse: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        // Не-anchor члены альбома скрыты — они уже нарисованы
                        // мозаикой на anchor-bubble.
                        if (albumSkip.contains(i)) {
                          return const SizedBox.shrink();
                        }
                        final m = messages[i];
                        // Anchor альбома: собрать плитки (в порядке отправки)
                        // + единственную подпись (member без вложения/байт).
                        List<AlbumTile>? albumTiles;
                        String? albumCaption;
                        final aid = m.albumId;
                        if (aid != null && albumAnchor[aid] == i) {
                          final members = albumMembers[aid]!;
                          // Картинка = загруженное вложение ИЛИ грузящиеся байты.
                          final imgs =
                              members
                                  .where(
                                    (x) =>
                                        x.attachment != null ||
                                        x.localImageBytes != null,
                                  )
                                  .toList()
                                ..sort(
                                  (a, b) => a.serverTimestamp.compareTo(
                                    b.serverTimestamp,
                                  ),
                                );
                          albumTiles = [
                            for (final x in imgs)
                              x.attachment != null
                                  ? UploadedTile(x.attachment!)
                                  : UploadingTile(x.localImageBytes!),
                          ];
                          // Подпись — член без вложения И без грузящихся байт
                          // (чтобы грузящаяся картинка не попала в подпись).
                          final caps =
                              members
                                  .where(
                                    (x) =>
                                        x.attachment == null &&
                                        x.localImageBytes == null &&
                                        x.body.trim().isNotEmpty,
                                  )
                                  .toList()
                                ..sort(
                                  (a, b) => a.serverTimestamp.compareTo(
                                    b.serverTimestamp,
                                  ),
                                );
                          albumCaption = caps.isNotEmpty
                              ? caps.first.body
                              : null;
                        }
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
                        // **B16-ext (phase2)**: аватар отправителя слева —
                        // только на НИЖНЕМ сообщении серии одного peer-а
                        // (Telegram-style). reverse:true + DESC messages →
                        // визуально-нижнее = messages[i-1]; показываем аватар,
                        // если оно от другого отправителя (или это самый низ).
                        final showSenderAvatar =
                            !isOwn &&
                            isGroupChat &&
                            (i == 0 ||
                                messages[i - 1].senderMatrixUserId !=
                                    m.senderMatrixUserId);
                        // **Issue #39**: подпись «кто написал» — наоборот, на
                        // ВЕРХНЕМ сообщении серии одного отправителя (как в
                        // Telegram: имя один раз над блоком, а не над каждым
                        // пузырём). reverse:true + DESC messages → визуально-
                        // верхнее = messages[i + 1].
                        final showSenderName =
                            !isOwn &&
                            showSenderNames &&
                            (i == messages.length - 1 ||
                                messages[i + 1].senderMatrixUserId !=
                                    m.senderMatrixUserId);
                        return KeyedSubtree(
                          key: key,
                          child: MessageBubble(
                            message: m,
                            isOwn: isOwn,
                            onRetry: onRetry,
                            thumbnailRpc: thumbnailRpc,
                            fullSizeRpc: fullSizeRpc,
                            albumTiles: albumTiles,
                            albumCaption: albumCaption,
                            onOpenImage: (tapped) => _openChatImageGallery(
                              context,
                              messages,
                              tapped,
                              thumbnailRpc,
                              fullSizeRpc,
                            ),
                            onLongPress: (msg) =>
                                onLongPressMessage(msg, isOwn),
                            findReplyTarget: findReplyTarget,
                            onReplyChipTap: onReplyChipTap,
                            onForwardedHeaderTap: onForwardedHeaderTap,
                            participantsByMessengerId:
                                participantsByMessengerId,
                            participantsByMatrixId: participantsByMatrixId,
                            readByPeerCount: readBy,
                            isGroupChat: isGroupChat,
                            onTapReadStatus:
                                isOwn && isGroupChat && onTapReadStatus != null
                                ? () => onTapReadStatus!(m)
                                : null,
                            reactions: reactionsFor != null
                                ? reactionsFor!(m)
                                : const <ReactionGroup>[],
                            onToggleReaction: onToggleReaction != null
                                ? (key) => onToggleReaction!(m, key)
                                : null,
                            showSenderAvatar: showSenderAvatar,
                            showSenderName: showSenderName,
                            // **TASK69 2C**: тап по аватару → «Упомянуть».
                            onSenderAvatarTap: onMentionSender,
                            // **Пересылка (мультивыбор)**: режим выбора + тоггл.
                            selectionMode: selectionMode,
                            selected: isSelected != null && isSelected!(m),
                            onToggleSelect: onToggleSelect != null
                                ? () => onToggleSelect!(m)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// **U1 (заявка #11)**: на десктопе/web оборачиваем список сообщений в
/// [SelectionArea] — мышью можно выделить произвольный фрагмент текста и
/// скопировать (Ctrl+C / контекст-меню). На тач-платформах НЕ включаем:
/// там long-press открывает action-sheet (Копировать/Изменить/Удалить),
/// а SelectionArea перехватил бы его под выделение слова.
Widget _selectableMessages(BuildContext context, Widget child) {
  final p = Theme.of(context).platform;
  final desktop =
      kIsWeb ||
      p == TargetPlatform.windows ||
      p == TargetPlatform.macOS ||
      p == TargetPlatform.linux;
  return desktop ? SelectionArea(child: child) : child;
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

/// **TASK52 итер.2**: интро-карточка в пустом direct-чате — визитка
/// собеседника + подпись «вы только что познакомились». Сама исчезает,
/// как только в чате появляется первое сообщение (ветка `messages.isEmpty`).
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.card});

  final ContactCardInfo card;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          ContactCardView(card: card, size: ContactCardSize.tile),
          const SizedBox(height: 16),
          Text(
            NsgL10n.of(context).chatIntroConnected,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xB8FFFCF8),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
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
    this.lastSeen,
    this.online = false,
  });

  final RoomDetails? details;
  final int fallbackRoomId;
  final VoidCallback onTap;

  /// **TASK55 итер.1**: last seen собеседника (только direct).
  final DateTime? lastSeen;

  /// **TASK55 итер.2**: собеседник в сети сейчас.
  final bool online;

  @override
  Widget build(BuildContext context) {
    // Loading: spinner instead of «Room #N».
    if (details == null) {
      final color =
          Theme.of(
            context,
          ).appBarTheme.foregroundColor?.withValues(alpha: 0.7) ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    final name = details!.name ?? '';
    final isDirect = details!.roomType == RoomType.direct;
    if (isDirect) {
      // **TASK55 итер.1**: подпись «был(а) в сети…» под именем в 1:1.
      // **2026-07-13**: заголовок 1:1 теперь тоже tappable — открывает
      // профиль собеседника (визитка + «своё имя»/заметка/метки).
      final seen = online
          ? NsgL10n.of(context).lastSeenOnline
          : humanLastSeen(lastSeen, NsgL10n.of(context));
      final dimColor =
          Theme.of(
            context,
          ).appBarTheme.foregroundColor?.withValues(alpha: 0.6) ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? '—' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (seen != null)
                Text(
                  seen,
                  style: TextStyle(fontSize: 11.5, color: dimColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      );
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
              color: Theme.of(
                context,
              ).appBarTheme.foregroundColor?.withValues(alpha: 0.6),
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
          onPressed: () => Navigator.of(context).pop(_ctl.text.trim()),
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
    final colors = theme.colorScheme;
    // **Issue #38**: голый текст на фоне чата терялся — на accent-цветных
    // темах (ember и т.п.) primary сливался с подложкой. Рисуем на такой
    // же плашке, как peer-пузырь: контраст даёт фон, а не подобранный под
    // конкретную тему цвет текста. Токены — те же, что у MessageBubble,
    // поэтому host-app override радиусов/паддингов работает и здесь.
    final tokens =
        theme.extension<NsgMessageBubbleTokens>() ??
        NsgMessageBubbleTokens.fallback;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width * tokens.maxWidthFraction,
          ),
          padding: tokens.padding,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: tokens.radiusPeer,
          ),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
    final showDetailed = details.totalParticipants <= kReadReceiptsDetailedMax;

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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            title: '${l.readReceiptsSectionUnread} (${nonReaders.length})',
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
        l.readReceiptsLargeGroupHint(readCount, details.totalParticipants - 1),
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
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialQuery,
  );
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
          style: TextStyle(fontSize: 17, color: theme.colorScheme.onSurface),
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
        final senderName =
            m.senderDisplayName ??
            p?.displayName ??
            _matrixLocalpart(m.senderMatrixUserId) ??
            m.senderMatrixUserId;
        return _SearchResultTile(
          message: m,
          senderName: senderName,
          query: _lastQuery,
          onTap: () => Navigator.of(context).pop(
            _SearchPick(results: _results, activeIndex: i, query: _lastQuery),
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
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
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

/// **Issue #35**: плашка закреплённых сообщений над лентой чата. Показывает
/// одно закреплённое сообщение (по умолчанию — самое свежее); при нескольких
/// закреплённых тап по телу циклически перебирает их (Telegram-style, «k/N»).
/// Кнопка-крестик открепляет текущее (видна только если у viewer-а есть права).
/// **TASK51 (UI)**: заметная плашка «Идёт групповой звонок · N участников
/// · [Присоединиться]» над композером group-комнаты, пока в ней живёт
/// конференция без нас. Тап по кнопке = `conferenceCalls.join(roomId)`.
class _ConferenceOngoingBanner extends StatelessWidget {
  const _ConferenceOngoingBanner({
    required this.memberCount,
    required this.onJoin,
  });

  final int memberCount;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('conferenceOngoingBanner'),
      color: scheme.primaryContainer,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.groups, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.conferenceOngoingBannerTitle,
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (memberCount > 0)
                      Text(
                        l.conferenceMemberCount(memberCount),
                        style: TextStyle(
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('conferenceJoinButton'),
                onPressed: onJoin,
                child: Text(l.conferenceJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedBanner extends StatefulWidget {
  const _PinnedBanner({
    required this.pinned,
    required this.canUnpin,
    required this.onTapMessage,
    required this.onUnpin,
  });

  /// Закреплённые сообщения, oldest-first (как отдаёт сервер).
  final List<ChatMessage> pinned;
  final bool canUnpin;
  final void Function(ChatMessage message) onTapMessage;
  final void Function(ChatMessage message) onUnpin;

  @override
  State<_PinnedBanner> createState() => _PinnedBannerState();
}

class _PinnedBannerState extends State<_PinnedBanner> {
  /// Индекс в display-порядке (newest-first). 0 = самое свежее закрепление.
  int _index = 0;

  /// Newest-first — свежайшее закрепление показывается первым.
  List<ChatMessage> get _display =>
      widget.pinned.reversed.toList(growable: false);

  @override
  void didUpdateWidget(covariant _PinnedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Список изменился (pin/unpin) — держим индекс в границах.
    if (_index >= widget.pinned.length) _index = 0;
  }

  void _advance() {
    if (widget.pinned.length <= 1) return;
    setState(() => _index = (_index + 1) % widget.pinned.length);
  }

  String _preview(ChatMessage m) {
    final body = m.body.trim();
    if (body.isNotEmpty) return body;
    final att = m.attachment;
    if (att != null) return '📎 ${att.originalFilename}';
    return '…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final l = NsgL10n.of(context);
    final display = _display;
    final total = display.length;
    if (total == 0) return const SizedBox.shrink();
    final idx = _index.clamp(0, total - 1);
    final current = display[idx];
    final title = total > 1
        ? '${l.pinnedMessagesTitle} · ${idx + 1}/$total'
        : l.pinnedMessagesTitle;

    return Material(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.onTapMessage(current);
                    _advance();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.push_pin, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _preview(current),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.canUnpin)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l.messageActionUnpin,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => widget.onUnpin(current),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
