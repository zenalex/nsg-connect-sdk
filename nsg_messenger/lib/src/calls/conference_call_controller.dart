import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
// См. пояснение в call_controller.dart: uuid — прямая зависимость, не
// полагаемся на transitive re-export serverpod_client.
// ignore: unnecessary_import
import 'package:uuid/uuid.dart';

import '../auth_token_provider.dart' show ErrorReporter;
import 'call_controller.dart' show IdGenerator;
import 'call_rpc.dart';
import 'conference_call_state.dart';
import 'conference_rpc.dart';
import 'ice_servers.dart';
import 'webrtc_adapter.dart';

/// Префикс callId pairwise-сессий конференции. По нему:
///   * `CallController` (1:1) игнорирует конференц-сигналинг (guard в его
///     `_onInvite` — иначе первый pairwise-invite зазвонил бы как 1:1);
///   * сервер (`MatrixCallService`) пускает такие события в group-комнаты
///     и пропускает reachability-гейт (он писался под 1:1).
/// Значение продублировано строкой на сервере (SDK не зависит от
/// server-пакета) — менять синхронно.
const String kConferenceCallIdPrefix = 'conf:';

/// Интервал keepalive-heartbeat-а (идемпотентный re-`joinConference`).
///
/// Сервер зачищает участника без keepalive по TTL
/// (`ConferenceService.participantTtl`, default **90с**, env
/// `CONFERENCE_PARTICIPANT_TTL_SECONDS`). SDK серверного env не знает и
/// не должен (клиент не читает конфиг сервера) — берём TTL/2 от
/// ДЕФОЛТНОГО TTL: 45с. Контракт сервера — «не реже, чем раз в половину
/// TTL», так что 45с ровно на границе с запасом в один пропущенный тик
/// (TTL = 2×interval, сервер прощает один потерянный heartbeat).
const Duration kConferenceHeartbeatInterval = Duration(seconds: 45);

/// **UI-чанк TASK51**: живая конференция в комнате глазами стороннего
/// наблюдателя (я НЕ участник) — данные для плашки «Групповой звонок ·
/// N участников · [Присоединиться]» в шапке комнаты.
///
/// Почему отдельная поверхность, а не state machine: [ConferenceCallState]
/// описывает МОЮ конференцию (одна за раз), а плашка — свойство КОМНАТЫ
/// и должна жить и после decline (ринг одноразовый, конференция — нет).
/// Контроллер и так слушает все `conferenceUpdated` — держим карту
/// roomId → инфо и отдаём её UI через тот же ChangeNotifier.
@immutable
class ConferenceRoomInfo {
  const ConferenceRoomInfo({
    required this.confId,
    required this.memberCount,
    this.initiatorMessengerUserId,
  });

  final String confId;

  /// Размер состава (для подписи «N участников»).
  final int memberCount;

  /// Самый ранний участник состава (де-факто инициатор) — как
  /// `callerMessengerUserId` в [ConferenceIncomingRinging].
  final int? initiatorMessengerUserId;

  @override
  bool operator ==(Object other) =>
      other is ConferenceRoomInfo &&
      other.confId == confId &&
      other.memberCount == memberCount &&
      other.initiatorMessengerUserId == initiatorMessengerUserId;

  @override
  int get hashCode => Object.hash(confId, memberCount, initiatorMessengerUserId);
}

/// Разобранный callId pairwise-сессии конференции. Конвенция:
///
///     conf:<confId>:<inviteeMessengerUserId>:<pairUuid>
///
/// Зачем в callId зашит АДРЕСАТ: `m.call.invite` уходит в Matrix-комнату
/// и доставляется ВСЕМ её участникам (у сигналинга TASK46 нет поля
/// `invitee`) — в 1:1 это не мешало (участников двое), в группе каждый
/// обязан уметь ответить на вопрос «этот invite мне или паре двух
/// других?». `messengerUserId` (а не partyId) — потому что стабилен через
/// перезапуск приложения, а сервер и так держит «один юзер = одно
/// устройство в конференции» (unique(conferenceId, messengerUserId), MVP).
@immutable
class ConferencePairCallId {
  const ConferencePairCallId({
    required this.confId,
    required this.inviteeMessengerUserId,
    required this.pairId,
  });

  final String confId;
  final int inviteeMessengerUserId;
  final String pairId;

  /// Собрать callId пары (инвайтер → [inviteeMessengerUserId]).
  static String build({
    required String confId,
    required int inviteeMessengerUserId,
    required String pairId,
  }) => '$kConferenceCallIdPrefix$confId:$inviteeMessengerUserId:$pairId';

  /// Распарсить; null — не конференц-callId / malformed (не бросаем:
  /// чужой мусор в шине не должен ничего ронять).
  static ConferencePairCallId? tryParse(String callId) {
    if (!callId.startsWith(kConferenceCallIdPrefix)) return null;
    final parts = callId.split(':');
    if (parts.length != 4) return null;
    final invitee = int.tryParse(parts[2]);
    if (invitee == null || parts[1].isEmpty || parts[3].isEmpty) return null;
    return ConferencePairCallId(
      confId: parts[1],
      inviteeMessengerUserId: invitee,
      pairId: parts[3],
    );
  }
}

/// **TASK51 итерация 1 (SDK)**: контроллер группового (mesh) аудиозвонка.
/// `ChangeNotifier` — единый источник состояния для UI (см.
/// `conference_call_state.dart`). Живёт в `MessengerRuntime` весь lifetime
/// сессии (attach/dispose как у `CallController`), слушает ту же шину
/// [MessengerEvent] — входящая конференция ловится на любом экране.
///
/// **Архитектура (§3A.2): mesh без группового протокола.** Медиа — до
/// N×(N−1)/2 независимых pairwise 1:1-сессий на существующем
/// TASK46-сигналинге (`sendCallEvent` / `m.call.*`), по своей паре pc на
/// каждого участника; членство — серверное (`joinConference` /
/// `conferenceUpdated`, Postgres — TASK51 серверная часть).
/// [CallController] НЕ наследуем и не форкаем: он остаётся владельцем 1:1,
/// а [WebRtcAdapter]/[CallRpc]/`sdp_tuning` переиспользуются как
/// библиотеки. Разграничение трафика — префикс callId
/// [kConferenceCallIdPrefix].
///
/// **Кто кого зовёт (анти-glare конвенция).** Invite в паре шлёт тот, кто
/// ПОЗЖЕ joined (поздний устанавливает сессии со всеми текущими членами
/// из ответа joinConference); при равном joinedAt — больший
/// messengerUserId. Обе стороны считают ответ по одному и тому же
/// серверному ростеру → направления детерминированы, встречных invite-ов
/// в штатном режиме нет. Если рассинхрон ростера всё же дал встречные
/// invite-ы — разрешаем как 1:1-glare (MSC2746): лексикографически
/// меньший callId выигрывает.
///
/// **Входящая конференция звонит один раз** на confId: триггер —
/// `conferenceUpdated` с живым составом без нас (основной путь: pairwise
/// invite-ы не-участнику вообще не адресуются — зовёт поздний, а
/// не-участник не «раньше» никого) ИЛИ первый pairwise-invite с
/// `conf:`-callId, адресованный нам (страховка на гонки перезахода).
/// Принятие = joinConference + ответ на скопившиеся invite-ы + установка
/// пар с остальными; отклонение = ничего не слать, состояние сбросить.
/// Отклонённый/покинутый confId запоминается и повторно не звонит.
///
/// **Ростер — источник правды состава**: `conferenceUpdated` несёт ПОЛНЫЙ
/// состав (override). Участник исчез → его пара закрывается; пустой
/// состав → полный teardown; наш выход = leaveConference + hangup всех
/// пар (дублирующая страховка к серверному событию).
///
/// **Graceful degrade (§3A.3)**: сбой одной пары НЕ валит конференцию —
/// пара ретраится один раз (с бэкоффом, ретрай — со стороны инвайтера
/// пары, чтобы не породить glare), дальше помечается failed и живём без
/// неё.
class ConferenceCallController extends ChangeNotifier {
  ConferenceCallController({
    required ConferenceRpc conferenceRpc,
    required CallRpc callRpc,
    required WebRtcAdapter webrtc,
    required Stream<MessengerEvent> events,
    required int Function() selfMessengerUserId,
    IdGenerator? idGenerator,
    Duration heartbeatInterval = kConferenceHeartbeatInterval,
    Duration pairRetryBackoff = const Duration(seconds: 2),
    Duration inviteLifetime = const Duration(seconds: 60),
    DateTime Function()? nowUtc,
    ErrorReporter? reporter,
  }) : _rpc = conferenceRpc,
       _callRpc = callRpc,
       _webrtc = webrtc,
       _selfUserIdFn = selfMessengerUserId,
       _idGen = idGenerator ?? _defaultIdGen,
       _heartbeatInterval = heartbeatInterval,
       _pairRetryBackoff = pairRetryBackoff,
       _inviteLifetime = inviteLifetime,
       _nowUtc = nowUtc ?? _defaultNowUtc,
       _reporter = reporter {
    // Собственный partyId устройства для конференций — стабилен на весь
    // lifetime контроллера (свой, не от CallController: домены сессий
    // независимы, а его selfPartyId — приватная деталь).
    _selfPartyId = _idGen();
    _sub = events.listen(_onEvent);
  }

  final ConferenceRpc _rpc;
  final CallRpc _callRpc;
  final WebRtcAdapter _webrtc;
  final int Function() _selfUserIdFn;
  final IdGenerator _idGen;
  final Duration _heartbeatInterval;
  final Duration _pairRetryBackoff;
  final Duration _inviteLifetime;
  final DateTime Function() _nowUtc;
  final ErrorReporter? _reporter;

  late final String _selfPartyId;
  StreamSubscription<MessengerEvent>? _sub;
  bool _disposed = false;

  /// После стольких ПОДРЯД проваленных heartbeat-ов сдаёмся: интервал 45с
  /// × 3 = 135с > серверного TTL (90с) — сервер нас гарантированно зачистил
  /// как призрака, остальные уже закрыли пары с нами. Висеть в «активной»
  /// конференции без членства — врать пользователю.
  static const int _maxHeartbeatFailures = 3;

  /// confId, по которым решение уже принято (звонили/отклонили/вышли) —
  /// повторные invite-ы/события той же конференции НЕ звонят снова.
  /// LinkedHashMap с капом — как dedup event bus-а (FIFO-вытеснение).
  static const int _handledCap = 64;
  final LinkedHashMap<String, void> _handledConfIds = LinkedHashMap();

  /// Invite-ы, прилетевшие, пока мы в фазе Joining (join-RPC в полёте):
  /// ответить сможем только после активации — буферим, теряя их, повисла
  /// бы пара (у инвайтера ретрай один).
  final List<MessengerEvent> _joiningInviteBuffer = [];

  /// Последний `conferenceUpdated`, прилетевший в фазе Joining: состав из
  /// ответа join к моменту активации мог устареть (кто-то ушёл, пока мы
  /// брали микрофон) — доприменяем после активации, не ждём heartbeat-а.
  MessengerEvent? _joiningRosterEvent;

  /// Громкая связь — предпочтение пользователя, переживает конкретную
  /// конференцию (в рамках сессии), как в [CallController].
  bool _speakerOn = false;
  bool get speakerOn => _speakerOn;

  /// Заглушен ли локальный микрофон. Один shared local-stream добавлен во
  /// ВСЕ pairwise-pc — toggle `track.enabled` действует на все пары разом.
  bool _muted = false;

  ConferenceCallState _state = const ConferenceCallIdle();

  /// Текущее состояние конференции. UI слушает через `addListener` /
  /// `ListenableBuilder`.
  ConferenceCallState get state => _state;

  /// Идёт ли конференция (любая фаза, кроме простоя/завершения).
  bool get isBusy =>
      _state is! ConferenceCallIdle && _state is! ConferenceCallEnded;

  /// partyId этого устройства (для отладки / тестов).
  @visibleForTesting
  String get selfPartyId => _selfPartyId;

  _ActiveConference? _active;
  _IncomingConference? _incoming;

  /// Живые конференции по комнатам (UI-плашка «идёт групповой звонок»).
  /// Наполняется из `conferenceUpdated` (полный override; пустой состав =
  /// смерть → удаление) и [refreshRoomConference] (комнаты, чья
  /// конференция началась ДО нашего подключения, событий не получали).
  final Map<int, ConferenceRoomInfo> _liveRoomConferences = {};

  /// Живая конференция в комнате [roomId] или null. Обновления — через
  /// тот же `addListener`/`ListenableBuilder`, что и [state].
  ConferenceRoomInfo? liveConferenceInRoom(int roomId) =>
      _liveRoomConferences[roomId];

  /// Разово освежить знание о конференции комнаты с сервера (для экрана
  /// комнаты при открытии: событий шины о старой конференции не будет —
  /// они шлются только на изменения состава). Best-effort: ошибки
  /// глотаются, карта просто не обновится.
  Future<void> refreshRoomConference(int roomId) async {
    if (_disposed) return;
    try {
      final resp = await _rpc.getConference(roomId: roomId);
      if (_disposed) return;
      if (resp == null || resp.members.isEmpty) {
        _updateLiveRoomConference(roomId, null);
      } else {
        _updateLiveRoomConference(
          roomId,
          ConferenceRoomInfo(
            confId: resp.confId,
            memberCount: resp.members.length,
            initiatorMessengerUserId: resp.members.isEmpty
                ? null
                : resp.members.first.messengerUserId,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConferenceCall] refreshRoomConference failed: $e');
      }
    }
  }

  /// Обновить карту живых конференций и уведомить слушателей, если
  /// что-то реально поменялось. НЕ через [_setState]: карта — отдельная
  /// от state-machine поверхность (плашка комнаты живёт и в Idle).
  void _updateLiveRoomConference(int roomId, ConferenceRoomInfo? info) {
    final prev = _liveRoomConferences[roomId];
    if (info == null) {
      if (prev == null) return;
      _liveRoomConferences.remove(roomId);
    } else {
      if (prev == info) return;
      _liveRoomConferences[roomId] = info;
    }
    if (!_disposed) notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────
  // Public API (команды UI)
  // ───────────────────────────────────────────────────────────────────

  /// **Войти в конференцию комнаты** (создав её на сервере, если активной
  /// нет) — и «позвонить всем в группе», и «присоединиться к идущей»
  /// (бейдж). No-op, если конференция уже идёт/входим (одна за раз, MVP).
  Future<void> join({required int roomId}) async {
    if (_disposed || isBusy) return;
    _incoming = null;
    _setState(ConferenceJoining(roomId: roomId));
    await _joinAndActivate(roomId);
  }

  /// **Принять входящую конференцию.** Валиден только в
  /// [ConferenceIncomingRinging]: joinConference + ответ на скопившиеся
  /// pairwise-invite-ы + установка пар с остальными.
  Future<void> accept() async {
    if (_disposed) return;
    final inc = _incoming;
    if (inc == null || _state is! ConferenceIncomingRinging) return;
    _incoming = null;
    // Скопившиеся invite-ы поедут через _joiningInviteBuffer — единый
    // буфер фазы Joining (accept — частный случай join-а).
    _joiningInviteBuffer.addAll(inc.bufferedInvites);
    _setState(ConferenceJoining(roomId: inc.roomId));
    await _joinAndActivate(inc.roomId);
  }

  /// **Отклонить входящую конференцию.** По спеке — НИЧЕГО не слать
  /// (пары с нами не установлены, гасить на той стороне нечего), состояние
  /// сбросить; confId запоминается — повторно не звонит.
  void decline() {
    if (_disposed) return;
    final inc = _incoming;
    if (inc == null || _state is! ConferenceIncomingRinging) return;
    _incoming = null;
    _rememberHandled(inc.confId);
    _setState(const ConferenceCallIdle());
  }

  /// **Выйти из конференции.** leaveConference (сервер разошлёт остальным
  /// обновлённый состав) + hangup всех пар (дублирующая страховка — пары
  /// закроются и без события) + локальный teardown. В фазе ринга —
  /// эквивалент [decline].
  Future<void> leave() async {
    if (_disposed) return;
    if (_state is ConferenceIncomingRinging) {
      decline();
      return;
    }
    final conf = _active;
    if (conf == null) return;
    await _teardown(
      conf,
      reason: ConferenceEndReason.localLeave,
      notifyPeers: true,
      leaveServer: true,
    );
  }

  /// **Mute/unmute** локального микрофона во всех парах разом (shared
  /// local-stream → toggle `track.enabled` виден каждому pc). Валиден
  /// только в [ConferenceActive] (иначе no-op → false). Возвращает новое
  /// состояние mute.
  bool toggleMute() {
    if (_disposed) return false;
    final conf = _active;
    if (conf == null || _state is! ConferenceActive) return false;
    _muted = !_muted;
    for (final track
        in conf.localStream?.audioTracks ?? const <MediaAudioTrack>[]) {
      track.enabled = !_muted;
    }
    _publishActive(conf);
    return _muted;
  }

  /// **Громкая связь вкл/выкл** — паттерн [CallController.toggleSpeaker]:
  /// состояние эмитим сразу, маршрут в нативном слое догоняет
  /// (best-effort). Валиден только в [ConferenceActive].
  bool toggleSpeaker() {
    if (_disposed) return _speakerOn;
    final conf = _active;
    if (conf == null || _state is! ConferenceActive) return _speakerOn;
    _speakerOn = !_speakerOn;
    unawaited(_applySpeakerRoute());
    _publishActive(conf);
    return _speakerOn;
  }

  // ───────────────────────────────────────────────────────────────────
  // Join / activate
  // ───────────────────────────────────────────────────────────────────

  Future<void> _joinAndActivate(int roomId) async {
    final int selfUserId;
    try {
      selfUserId = _selfUserIdFn();
    } catch (_) {
      // Сессии нет (окно teardown/reinit) — конференцию не поднять.
      _joiningInviteBuffer.clear();
    _joiningRosterEvent = null;
      _setState(
        const ConferenceCallEnded(reason: ConferenceEndReason.failed),
      );
      return;
    }
    final ConferenceState resp;
    try {
      resp = await _rpc.joinConference(roomId: roomId, partyId: _selfPartyId);
    } on ConferenceFullException catch (e) {
      _joiningInviteBuffer.clear();
    _joiningRosterEvent = null;
      _setState(
        ConferenceCallEnded(
          reason: ConferenceEndReason.conferenceFull,
          roomId: roomId,
          maxParticipants: e.maxParticipants,
        ),
      );
      return;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[ConferenceCall] join failed: $e\n$st');
      _joiningInviteBuffer.clear();
    _joiningRosterEvent = null;
      _setState(
        ConferenceCallEnded(reason: ConferenceEndReason.failed, roomId: roomId),
      );
      return;
    }
    if (_disposed) {
      // Рантайм умер, пока ждали RPC — членство на сервере снимаем, иначе
      // висим призраком до TTL.
      unawaited(_rpc.leaveConference(roomId: roomId).catchError((_) {}));
      return;
    }
    _rememberHandled(resp.confId);

    // Микрофон — ДО активации (_active): пары обязаны рождаться уже с
    // локальным стримом, иначе первое же событие состава в окне «join
    // прошёл, микрофона ещё нет» установило бы пары без нашего аудио.
    final RtcMediaStream stream;
    try {
      stream = await _webrtc.getUserMediaAudio();
    } on MicPermissionDeniedException {
      _joiningInviteBuffer.clear();
    _joiningRosterEvent = null;
      unawaited(_rpc.leaveConference(roomId: roomId).catchError((_) {}));
      _setState(
        ConferenceCallEnded(
          reason: ConferenceEndReason.micDenied,
          roomId: roomId,
          confId: resp.confId,
        ),
      );
      return;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[ConferenceCall] mic failed: $e\n$st');
      _joiningInviteBuffer.clear();
    _joiningRosterEvent = null;
      unawaited(_rpc.leaveConference(roomId: roomId).catchError((_) {}));
      _setState(
        ConferenceCallEnded(
          reason: ConferenceEndReason.failed,
          roomId: roomId,
          confId: resp.confId,
        ),
      );
      return;
    }
    if (_disposed) {
      unawaited(stream.dispose());
      unawaited(_rpc.leaveConference(roomId: roomId).catchError((_) {}));
      return;
    }
    await _applySpeakerRoute();

    final conf = _ActiveConference(
      roomId: roomId,
      confId: resp.confId,
      selfUserId: selfUserId,
      myJoinedAt: _findSelfJoinedAt(resp.members, selfUserId) ?? _nowUtc(),
      startedAt: DateTime.now(),
    )..localStream = stream;
    _active = conf;
    // Новая конференция — микрофон стартует включённым (mute — решение
    // в рамках конкретного звонка, как в 1:1).
    _muted = false;

    // 1) Ответить на invite-ы, скопившиеся за ринг/joining (их прислали
    //    те, для кого инвайтер — ОНИ; нам остаётся answer).
    final buffered = List<MessengerEvent>.of(_joiningInviteBuffer);
    _joiningInviteBuffer.clear();
    for (final ev in buffered) {
      final callId = ev.callId;
      final partyId = ev.callPartyId;
      final sdp = ev.callSdp;
      if (callId == null || partyId == null || sdp == null) continue;
      final parsed = ConferencePairCallId.tryParse(callId);
      // Буфер мог накопить invite-ы умершей конференции — отвечаем только
      // на актуальный confId (для остальных пар нет).
      if (parsed == null || parsed.confId != conf.confId) continue;
      if (conf.pairs.containsKey(partyId)) continue;
      _answerPairInvite(conf, callId: callId, peerPartyId: partyId, sdp: sdp);
    }
    // 2) Установить пары с остальными по составу из ответа join
    //    (мы joined позже всех → по конвенции инвайтер — мы).
    _applyRoster(conf, resp.members);
    // 3) Событие состава, прилетевшее за время Joining, может быть свежее
    //    ответа — доприменяем (idempotent override).
    final pendingRoster = _joiningRosterEvent;
    _joiningRosterEvent = null;
    if (!conf.ended &&
        pendingRoster != null &&
        pendingRoster.conferenceConfId == conf.confId &&
        pendingRoster.conferenceMembers != null) {
      _applyRoster(conf, pendingRoster.conferenceMembers!);
    }
    if (conf.ended) return; // _applyRoster мог снести (displaced и т.п.)
    _startHeartbeat(conf);
    _publishActive(conf);
  }

  DateTime? _findSelfJoinedAt(List<ConferenceMember> members, int selfUserId) {
    for (final m in members) {
      if (m.messengerUserId == selfUserId && m.partyId == _selfPartyId) {
        return m.joinedAt;
      }
    }
    return null;
  }

  void _rememberHandled(String confId) {
    _handledConfIds[confId] = null;
    while (_handledConfIds.length > _handledCap) {
      _handledConfIds.remove(_handledConfIds.keys.first);
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // Event bus reactor
  // ───────────────────────────────────────────────────────────────────

  void _onEvent(MessengerEvent event) {
    if (_disposed) return;
    switch (event.eventType) {
      case MessengerEventType.conferenceUpdated:
        _onConferenceUpdated(event);
      case MessengerEventType.callInvite:
        _onCallInvite(event);
      case MessengerEventType.callAnswer:
        _onPairAnswer(event);
      case MessengerEventType.callCandidates:
        _onPairCandidates(event);
      case MessengerEventType.callHangup:
      case MessengerEventType.callReject:
        _onPairHangup(event);
      // ignore: no_default_cases
      default:
        break;
    }
  }

  /// `conferenceUpdated` — источник правды состава (полный override).
  void _onConferenceUpdated(MessengerEvent event) {
    final confId = event.conferenceConfId;
    final members = event.conferenceMembers;
    final roomId = event.roomId;
    if (confId == null || members == null || roomId == null) return;

    // Карта живых конференций комнат (плашка «идёт групповой звонок») —
    // ДО ветвлений state-machine: события чужих комнат/конференций ниже
    // отбрасываются, а плашке нужны все.
    _updateLiveRoomConference(
      roomId,
      members.isEmpty
          ? null
          : ConferenceRoomInfo(
              confId: confId,
              memberCount: members.length,
              initiatorMessengerUserId: members.first.messengerUserId,
            ),
    );

    final conf = _active;
    if (conf != null && !conf.ended) {
      // Конференция ДРУГОЙ комнаты, пока мы в своей — информация для
      // бейджей комнат (UI-чанк), контроллеру не интересна (одна за раз).
      if (roomId != conf.roomId) return;
      if (confId != conf.confId) {
        if (members.isEmpty) return; // смерть какой-то прежней — не нашей.
        final iAmMember = members.any(
          (m) =>
              m.messengerUserId == conf.selfUserId &&
              m.partyId == _selfPartyId,
        );
        if (iAmMember) {
          // Конференция умерла и возродилась «под нами» (наш же heartbeat
          // пересоздал её после смерти, событий смерти мы не видели —
          // reconnect). Старые пары адресуют мёртвый confId — сносим и
          // отстраиваемся заново по свежему составу.
          _adoptRebornConference(conf, confId, members);
        } else {
          // В комнате живёт ДРУГАЯ конференция без нас → наша давно
          // мертва (пропустили её смерть). Teardown; новая зазвонит
          // отдельным событием, если состав переживёт наш handled-гейт.
          unawaited(
            _teardown(
              conf,
              reason: ConferenceEndReason.conferenceDied,
              notifyPeers: false,
              leaveServer: false,
            ),
          );
        }
        return;
      }
      _applyRoster(conf, members);
      if (!conf.ended) _publishActive(conf);
      return;
    }

    // Не в конференции: ринг / отбой ринга.
    final inc = _incoming;
    if (inc != null && _state is ConferenceIncomingRinging) {
      if (confId != inc.confId) return; // один ринг за раз (MVP).
      if (members.isEmpty) {
        // Конференция умерла, пока звонила — снимаем ринг (missed).
        _incoming = null;
        _rememberHandled(confId);
        _setState(const ConferenceCallIdle());
        return;
      }
      // Дозаполняем «кто зовёт»/счётчик (ринг мог стартовать с invite,
      // где состава ещё не было).
      _setState(
        ConferenceIncomingRinging(
          roomId: roomId,
          confId: confId,
          callerMessengerUserId: members.first.messengerUserId,
          memberCount: members.length,
        ),
      );
      return;
    }
    if (_state is ConferenceJoining) {
      // Состав приедет ответом join; событие запоминаем — оно может быть
      // свежее ответа (изменение состава, пока берём микрофон).
      _joiningRosterEvent = event;
      return;
    }
    if (isBusy) return;
    if (members.isEmpty) return;
    if (_handledConfIds.containsKey(confId)) return; // уже решали — молчим.
    final selfUserId = _trySelfUserId();
    if (selfUserId == null) return;
    // Мы в составе (другое наше устройство вошло / наш свежий призрак) —
    // самому себе не звоним.
    if (members.any((m) => m.messengerUserId == selfUserId)) return;

    _incoming = _IncomingConference(roomId: roomId, confId: confId);
    _setState(
      ConferenceIncomingRinging(
        roomId: roomId,
        confId: confId,
        // «Кто зовёт» = самый ранний участник (сервер сортирует состав по
        // joinedAt) — де-факто инициатор.
        callerMessengerUserId: members.first.messengerUserId,
        memberCount: members.length,
      ),
    );
  }

  /// Pairwise-invite конференции (страховочный ринг-триггер + установка
  /// входящих пар в активной конференции).
  void _onCallInvite(MessengerEvent event) {
    final callId = event.callId;
    final roomId = event.roomId;
    final sdp = event.callSdp;
    final peerPartyId = event.callPartyId;
    if (callId == null || roomId == null || sdp == null) return;
    final parsed = ConferencePairCallId.tryParse(callId);
    if (parsed == null) return; // обычный 1:1 — не наш.

    // Staleness-guard как в 1:1: /sync-replay при reconnect-е может
    // переиграть старые invite-ы — пара по ним давно мертва.
    final lifetimeMs = event.callLifetime ?? _inviteLifetime.inMilliseconds;
    final maxAge =
        Duration(milliseconds: lifetimeMs) + const Duration(seconds: 30);
    if (_nowUtc().difference(event.serverTimestamp.toUtc()) > maxAge) return;

    final selfUserId = _trySelfUserId();
    if (selfUserId == null) return;
    // Адресат зашит в callId: invite паре ДРУГИХ участников игнорируем
    // (Matrix-комната доставляет всем).
    if (parsed.inviteeMessengerUserId != selfUserId) return;
    if (peerPartyId == null) return;

    final conf = _active;
    if (conf != null && !conf.ended) {
      if (parsed.confId != conf.confId) return; // мёртвый/чужой confId.
      final existing = conf.pairs[peerPartyId];
      if (existing != null && existing.callId == callId) return; // дубль.
      if (existing != null &&
          existing.isOutgoing &&
          !existing.answered &&
          !existing.ended) {
        // Встречные invite-ы (оба сочли себя инвайтером — рассинхрон
        // ростера). Разрешение как 1:1-glare (MSC2746): меньший callId
        // выигрывает; считают обе стороны одинаково.
        if (existing.callId.compareTo(callId) < 0) return; // наш выиграл.
        _closePair(existing);
        conf.pairs.remove(peerPartyId);
      } else if (existing != null) {
        // Пир пересобирает пару (его ретрай после сбоя / переустановка) —
        // старую сносим, отвечаем на новую.
        _closePair(existing);
        conf.pairs.remove(peerPartyId);
      }
      _answerPairInvite(
        conf,
        callId: callId,
        peerPartyId: peerPartyId,
        sdp: sdp,
      );
      _publishActive(conf);
      return;
    }

    // Не в конференции.
    if (_handledConfIds.containsKey(parsed.confId)) return; // не звонить.
    final inc = _incoming;
    if (inc != null && _state is ConferenceIncomingRinging) {
      // Уже звоним этой конференцией — копим invite (ответим на accept);
      // повторные НЕ звонят второй раз.
      if (inc.confId == parsed.confId) inc.bufferedInvites.add(event);
      return;
    }
    if (_state is ConferenceJoining) {
      // Join в полёте — ответить сможем после активации.
      _joiningInviteBuffer.add(event);
      return;
    }
    if (isBusy) return;
    // Первый invite незнакомой конференции — ринг (кто зовёт/размер
    // состава дозаполнит conferenceUpdated).
    _incoming = _IncomingConference(roomId: roomId, confId: parsed.confId)
      ..bufferedInvites.add(event);
    _setState(
      ConferenceIncomingRinging(roomId: roomId, confId: parsed.confId),
    );
  }

  void _onPairAnswer(MessengerEvent event) {
    final conf = _active;
    final callId = event.callId;
    if (conf == null || conf.ended || callId == null) return;
    if (event.roomId != conf.roomId) return;
    final pair = _pairByCallId(conf, callId);
    if (pair == null || !pair.isOutgoing || pair.answered || pair.ended) {
      return;
    }
    final sdp = event.callSdp;
    final pc = pair.pc;
    if (sdp == null || pc == null) return;
    pair.answered = true;
    pair.inviteTimer?.cancel();
    pair.inviteTimer = null;
    unawaited(() async {
      try {
        await pc.setRemoteDescription(RtcSdp(type: SdpType.answer, sdp: sdp));
        pair.remoteDescriptionSet = true;
        _drainPairRemoteIce(pair);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[ConferenceCall] answer apply failed: $e\n$st');
        }
        _failOrRetryPair(conf, pair);
      }
    }());
  }

  void _onPairCandidates(MessengerEvent event) {
    final conf = _active;
    final callId = event.callId;
    if (conf == null || conf.ended || callId == null) return;
    if (event.roomId != conf.roomId) return;
    final pair = _pairByCallId(conf, callId);
    if (pair == null || pair.ended) return;
    for (final c in event.callCandidates ?? const <CallIceCandidate>[]) {
      final ice = RtcIce(
        candidate: c.candidate,
        sdpMid: c.sdpMid,
        sdpMLineIndex: c.sdpMLineIndex,
      );
      if (pair.pc == null || !pair.remoteDescriptionSet) {
        // WebRTC требует remote SDP до кандидатов — буферим (как в 1:1).
        pair.pendingRemoteIce.add(ice);
      } else {
        unawaited(_addPairIce(pair, ice));
      }
    }
    _drainPairRemoteIce(pair);
  }

  /// hangup/reject пары: пир свернул это ребро (обычно — уходит из
  /// конференции; серверный ростер вскоре подтвердит). Пару закрываем и
  /// держим failed-надгробием: НЕ переустанавливаем до ростера, иначе
  /// hangup уходящего порождал бы петлю re-invite.
  void _onPairHangup(MessengerEvent event) {
    final conf = _active;
    final callId = event.callId;
    if (conf == null || conf.ended || callId == null) return;
    if (event.roomId != conf.roomId) return;
    final pair = _pairByCallId(conf, callId);
    if (pair == null || pair.ended) return;
    _closePair(pair);
    pair.phase = ConferencePairPhase.failed;
    _publishActive(conf);
  }

  // ───────────────────────────────────────────────────────────────────
  // Roster reconcile
  // ───────────────────────────────────────────────────────────────────

  /// Применить свежий ПОЛНЫЙ состав (ответ join/heartbeat-а или событие):
  /// пустой состав → конференция умерла; ушедшие → закрыть пары; новые →
  /// установить пары, где инвайтер — мы; наш partyId сменился в составе →
  /// нас вытеснило другое наше устройство.
  void _applyRoster(_ActiveConference conf, List<ConferenceMember> members) {
    if (conf.ended) return;
    if (members.isEmpty) {
      unawaited(
        _teardown(
          conf,
          reason: ConferenceEndReason.conferenceDied,
          notifyPeers: false,
          leaveServer: false,
        ),
      );
      return;
    }
    ConferenceMember? me;
    for (final m in members) {
      if (m.messengerUserId == conf.selfUserId) me = m;
    }
    if (me != null && me.partyId != _selfPartyId) {
      // Сервер держит «один юзер = одно устройство»: наш же аккаунт вошёл
      // с другого устройства и перезаписал partyId — эта сессия вытеснена.
      unawaited(
        _teardown(
          conf,
          reason: ConferenceEndReason.displaced,
          notifyPeers: false,
          leaveServer: false,
        ),
      );
      return;
    }
    if (me != null) {
      // joinedAt мог сдвинуться (сервер двигает его при смене partyId и
      // пере-вставке после prune) — tie-break-и считаем от актуального.
      conf.myJoinedAt = me.joinedAt;
    }
    // me == null — prune-блип (нас зачистило TTL, но мы живы): пары не
    // трогаем, ближайший heartbeat-join вернёт членство.
    conf.roster = List.of(members);

    // Ушедшие: закрыть их пары. hangup не шлём — участник вышел сам (его
    // leave уже разослал hangup-и) либо зачищен как призрак (слать некому).
    final livePartyIds = {for (final m in members) m.partyId};
    final gone = conf.pairs.keys
        .where((p) => !livePartyIds.contains(p))
        .toList();
    for (final partyId in gone) {
      final pair = conf.pairs.remove(partyId);
      if (pair != null) _closePair(pair);
    }

    // Новые (без пары): устанавливаем ТОЛЬКО там, где инвайтер — мы
    // (конвенция «зовёт поздний»); иначе ждём их invite. Failed-надгробия
    // остаются в map и сюда не попадают — живём без этой пары (§3A.3).
    for (final m in members) {
      if (m.messengerUserId == conf.selfUserId) continue;
      if (conf.pairs.containsKey(m.partyId)) continue;
      if (_iAmPairCaller(conf, m)) {
        _establishPair(conf, m, isRetry: false);
      }
    }
  }

  /// Конвенция «кто кого зовёт»: invite в паре шлёт тот, кто ПОЗЖЕ
  /// joined; при равном joinedAt (одновременный join, одна миллисекунда
  /// БД) — больший messengerUserId. Обе стороны считают по одному
  /// серверному ростеру → детерминировано, встречных invite-ов нет.
  bool _iAmPairCaller(_ActiveConference conf, ConferenceMember m) {
    if (conf.myJoinedAt.isAfter(m.joinedAt)) return true;
    if (m.joinedAt.isAfter(conf.myJoinedAt)) return false;
    return conf.selfUserId > m.messengerUserId;
  }

  /// Возрождение конференции «под нами» (умерла и создана заново нашим же
  /// heartbeat-ом, событий смерти мы не видели): пары старого confId
  /// мертвы — снести и отстроиться по свежему составу.
  void _adoptRebornConference(
    _ActiveConference conf,
    String confId,
    List<ConferenceMember> members,
  ) {
    for (final pair in conf.pairs.values) {
      _closePair(pair);
    }
    conf.pairs.clear();
    conf.confId = confId;
    _rememberHandled(confId);
    _applyRoster(conf, members);
    if (!conf.ended) _publishActive(conf);
  }

  // ───────────────────────────────────────────────────────────────────
  // Pairwise-сессии
  // ───────────────────────────────────────────────────────────────────

  _ConferencePair? _pairByCallId(_ActiveConference conf, String callId) {
    for (final pair in conf.pairs.values) {
      if (pair.callId == callId) return pair;
    }
    return null;
  }

  /// Исходящая пара (мы — инвайтер): pc → offer → invite c
  /// `conf:`-callId, адресованным [m].
  void _establishPair(
    _ActiveConference conf,
    ConferenceMember m, {
    required bool isRetry,
  }) {
    final pair = _ConferencePair(
      callId: ConferencePairCallId.build(
        confId: conf.confId,
        inviteeMessengerUserId: m.messengerUserId,
        pairId: _idGen(),
      ),
      peerPartyId: m.partyId,
      isOutgoing: true,
      isRetry: isRetry,
    );
    conf.pairs[m.partyId] = pair;
    unawaited(() async {
      try {
        final pc = await _buildPairPc(conf, pair);
        final stream = conf.localStream;
        if (stream != null) await pc.addLocalStream(stream);
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        if (_isPairStale(conf, pair)) return;
        await _callRpc.sendCallEvent(
          roomId: conf.roomId,
          eventType: CallEventType.invite,
          callId: pair.callId,
          partyId: _selfPartyId,
          sdp: offer.sdp,
        );
        pair.signalingSent = true;
        _flushPairLocalIce(conf, pair);
        // Пир в конференции отвечает автоматически; нет answer-а за
        // lifetime = invite потерян/пир мёртв → ретрай/failed.
        pair.inviteTimer = Timer(_inviteLifetime, () {
          pair.inviteTimer = null;
          if (_isPairStale(conf, pair) || pair.answered) return;
          _failOrRetryPair(conf, pair);
        });
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[ConferenceCall] establish pair failed: $e\n$st');
        }
        if (!_isPairStale(conf, pair)) _failOrRetryPair(conf, pair);
      }
    }());
  }

  /// Входящая пара (инвайтер — пир): pc → setRemote(offer) → answer.
  void _answerPairInvite(
    _ActiveConference conf, {
    required String callId,
    required String peerPartyId,
    required String sdp,
  }) {
    final pair = _ConferencePair(
      callId: callId,
      peerPartyId: peerPartyId,
      isOutgoing: false,
      isRetry: false,
    );
    conf.pairs[peerPartyId] = pair;
    unawaited(() async {
      try {
        final pc = await _buildPairPc(conf, pair);
        await pc.setRemoteDescription(RtcSdp(type: SdpType.offer, sdp: sdp));
        final stream = conf.localStream;
        if (stream != null) await pc.addLocalStream(stream);
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        if (_isPairStale(conf, pair)) return;
        await _callRpc.sendCallEvent(
          roomId: conf.roomId,
          eventType: CallEventType.answer,
          callId: pair.callId,
          partyId: _selfPartyId,
          sdp: answer.sdp,
        );
        pair.signalingSent = true;
        pair.remoteDescriptionSet = true;
        _flushPairLocalIce(conf, pair);
        _drainPairRemoteIce(pair);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[ConferenceCall] answer pair failed: $e\n$st');
        }
        if (!_isPairStale(conf, pair)) _failOrRetryPair(conf, pair);
      }
    }());
  }

  Future<RtcPeerConnection> _buildPairPc(
    _ActiveConference conf,
    _ConferencePair pair,
  ) async {
    // TURN-креды берём на каждую пару (как 1:1 на каждый звонок): пары
    // рождаются и в середине долгой конференции (поздние участники,
    // ретраи) — кэшировать креды с TTL себе дороже. N≤4 → максимум 3
    // запроса на вход.
    final iceServers = await resolveIceServers(_callRpc, _reporter);
    final pc = await _webrtc.createPeerConnection(iceServers);
    pair.pc = pc;

    pc.onIceCandidate = (RtcIce ice) {
      if (_isPairStale(conf, pair)) return;
      if (!pair.signalingSent) {
        pair.pendingLocalIce.add(ice);
        return;
      }
      unawaited(_sendPairLocalIce(conf, pair, ice));
    };
    pc.onConnectionState = (RtcConnState s) {
      if (_isPairStale(conf, pair)) return;
      switch (s) {
        case RtcConnState.connected:
          pair.phase = ConferencePairPhase.connected;
          // Активация аудио-сессии могла сбросить маршрут вывода на
          // платформенный дефолт — переприменяем (как 1:1 в connected).
          unawaited(_applySpeakerRoute());
          _publishActive(conf);
        case RtcConnState.failed:
          _failOrRetryPair(conf, pair);
        case RtcConnState.disconnected:
          // Временная потеря — WebRTC часто чинит сам. MVP конференции:
          // без ICE-restart-механики 1:1 — показываем «reconnecting»
          // (connecting), окончательный вердикт вынесет failed.
          pair.phase = ConferencePairPhase.connecting;
          _publishActive(conf);
        case RtcConnState.closed:
          if (!pair.ended) _failOrRetryPair(conf, pair);
        case RtcConnState.connecting:
          break;
      }
    };
    pc.onRemoteTrack = () {
      if (kDebugMode) {
        debugPrint('[ConferenceCall] remote track pair=${pair.callId}');
      }
    };
    return pc;
  }

  /// Сбой пары ≠ сбой конференции (§3A.3 graceful degrade): исходящую
  /// пару ретраим ОДИН раз с бэкоффом (новый callId — полная
  /// переустановка), дальше failed-надгробие. Входящую не ретраим —
  /// пересбор инициирует инвайтер (пир), его новый invite заменит пару;
  /// симметричный ретрай с двух сторон дал бы glare.
  void _failOrRetryPair(_ActiveConference conf, _ConferencePair pair) {
    if (pair.ended || conf.ended || _disposed) return;
    _closePair(pair);
    if (pair.isOutgoing && !pair.isRetry) {
      pair.phase = ConferencePairPhase.connecting; // ретрай идёт.
      _publishActive(conf);
      pair.retryTimer = Timer(_pairRetryBackoff, () {
        pair.retryTimer = null;
        if (conf.ended || _disposed) return;
        if (!identical(conf.pairs[pair.peerPartyId], pair)) return;
        ConferenceMember? member;
        for (final m in conf.roster) {
          if (m.partyId == pair.peerPartyId) member = m;
        }
        if (member == null) {
          // Участник уже ушёл из состава — ретраить некому.
          conf.pairs.remove(pair.peerPartyId);
          _publishActive(conf);
          return;
        }
        conf.pairs.remove(pair.peerPartyId);
        _establishPair(conf, member, isRetry: true);
        _publishActive(conf);
      });
      return;
    }
    pair.phase = ConferencePairPhase.failed;
    _publishActive(conf);
  }

  /// Закрыть ресурсы пары (pc/таймеры) и пометить завершённой. Запись в
  /// `conf.pairs` НЕ трогаем — этим управляет вызывающий (надгробие/
  /// удаление/замена).
  void _closePair(_ConferencePair pair) {
    if (pair.ended) return;
    pair.ended = true;
    pair.inviteTimer?.cancel();
    pair.inviteTimer = null;
    pair.retryTimer?.cancel();
    pair.retryTimer = null;
    unawaited(pair.pc?.close());
    pair.pc = null;
  }

  // ── trickle ICE (per pair, паттерн 1:1) ────────────────────────────

  void _flushPairLocalIce(_ActiveConference conf, _ConferencePair pair) {
    final pending = List<RtcIce>.of(pair.pendingLocalIce);
    pair.pendingLocalIce.clear();
    for (final ice in pending) {
      unawaited(_sendPairLocalIce(conf, pair, ice));
    }
  }

  Future<void> _sendPairLocalIce(
    _ActiveConference conf,
    _ConferencePair pair,
    RtcIce ice,
  ) async {
    if (_isPairStale(conf, pair)) return;
    try {
      await _callRpc.sendCallEvent(
        roomId: conf.roomId,
        eventType: CallEventType.candidates,
        callId: pair.callId,
        partyId: _selfPartyId,
        candidates: [
          CallIceCandidate(
            candidate: ice.candidate,
            sdpMid: ice.sdpMid,
            sdpMLineIndex: ice.sdpMLineIndex,
          ),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConferenceCall] candidates send failed: $e (best-effort)');
      }
    }
  }

  void _drainPairRemoteIce(_ConferencePair pair) {
    if (pair.pc == null || !pair.remoteDescriptionSet) return;
    final pending = List<RtcIce>.of(pair.pendingRemoteIce);
    pair.pendingRemoteIce.clear();
    for (final ice in pending) {
      unawaited(_addPairIce(pair, ice));
    }
  }

  Future<void> _addPairIce(_ConferencePair pair, RtcIce ice) async {
    final pc = pair.pc;
    if (pc == null) return;
    try {
      await pc.addIceCandidate(ice);
    } catch (e) {
      if (kDebugMode) debugPrint('[ConferenceCall] addIce failed: $e');
    }
  }

  bool _isPairStale(_ActiveConference conf, _ConferencePair pair) =>
      _disposed ||
      conf.ended ||
      pair.ended ||
      !identical(_active, conf) ||
      !identical(conf.pairs[pair.peerPartyId], pair);

  // ───────────────────────────────────────────────────────────────────
  // Heartbeat
  // ───────────────────────────────────────────────────────────────────

  void _startHeartbeat(_ActiveConference conf) {
    conf.heartbeatTimer?.cancel();
    conf.heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      unawaited(_heartbeat(conf));
    });
  }

  /// Keepalive = идемпотентный re-join (контракт сервера). Заодно —
  /// самовосстановление ростера: ответ несёт полный состав, потерянные
  /// `conferenceUpdated` (reconnect) чинятся ближайшим тиком.
  Future<void> _heartbeat(_ActiveConference conf) async {
    if (conf.ended || _disposed) return;
    try {
      final resp = await _rpc.joinConference(
        roomId: conf.roomId,
        partyId: _selfPartyId,
      );
      if (conf.ended || _disposed || !identical(_active, conf)) return;
      conf.heartbeatFailures = 0;
      if (resp.confId != conf.confId) {
        _adoptRebornConference(conf, resp.confId, resp.members);
        return;
      }
      _applyRoster(conf, resp.members);
      if (!conf.ended) _publishActive(conf);
    } on ConferenceFullException catch (e) {
      // Нас зачистило TTL, и место успели занять — назад не пускают.
      await _teardown(
        conf,
        reason: ConferenceEndReason.conferenceFull,
        notifyPeers: false,
        leaveServer: false,
        maxParticipants: e.maxParticipants,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[ConferenceCall] heartbeat failed: $e');
      conf.heartbeatFailures++;
      if (conf.heartbeatFailures >= _maxHeartbeatFailures) {
        await _teardown(
          conf,
          reason: ConferenceEndReason.failed,
          notifyPeers: true,
          leaveServer: false,
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // Teardown / state
  // ───────────────────────────────────────────────────────────────────

  Future<void> _teardown(
    _ActiveConference conf, {
    required ConferenceEndReason reason,
    required bool notifyPeers,
    required bool leaveServer,
    int? maxParticipants,
  }) async {
    if (conf.ended) return;
    conf.ended = true;
    conf.heartbeatTimer?.cancel();
    conf.heartbeatTimer = null;
    for (final pair in conf.pairs.values) {
      if (notifyPeers && pair.signalingSent && !pair.ended) {
        // Дублирующая страховка к серверному conferenceUpdated: пары
        // закроются и без hangup-ов, но явный сигнал мгновеннее.
        unawaited(_safeSendHangup(conf.roomId, pair.callId));
      }
      _closePair(pair);
    }
    conf.pairs.clear();
    unawaited(conf.localStream?.dispose());
    conf.localStream = null;
    if (leaveServer) {
      try {
        await _rpc.leaveConference(roomId: conf.roomId);
      } catch (e) {
        // Best-effort: не вышло — сервер зачистит нас TTL-ом.
        if (kDebugMode) debugPrint('[ConferenceCall] leave failed: $e');
      }
    }
    if (identical(_active, conf)) {
      _active = null;
      _setState(
        ConferenceCallEnded(
          reason: reason,
          roomId: conf.roomId,
          confId: conf.confId,
          maxParticipants: maxParticipants,
        ),
      );
    }
  }

  Future<void> _safeSendHangup(int roomId, String callId) async {
    try {
      await _callRpc.sendCallEvent(
        roomId: roomId,
        eventType: CallEventType.hangup,
        callId: callId,
        partyId: _selfPartyId,
        hangupReason: 'user_hangup',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConferenceCall] hangup send failed: $e (best-effort)');
      }
    }
  }

  Future<void> _applySpeakerRoute() => _webrtc.setSpeakerphone(_speakerOn);

  int? _trySelfUserId() {
    try {
      return _selfUserIdFn();
    } catch (_) {
      return null; // Сессии нет (teardown/reinit) — события пропускаем.
    }
  }

  /// Пересобрать и опубликовать [ConferenceActive] из ростера + фаз пар.
  void _publishActive(_ActiveConference conf) {
    if (conf.ended || _disposed || !identical(_active, conf)) return;
    final views = <ConferenceParticipantView>[];
    var selfListed = false;
    for (final m in conf.roster) {
      final isSelf =
          m.messengerUserId == conf.selfUserId && m.partyId == _selfPartyId;
      if (isSelf) selfListed = true;
      final pair = conf.pairs[m.partyId];
      views.add(
        ConferenceParticipantView(
          messengerUserId: m.messengerUserId,
          partyId: m.partyId,
          joinedAt: m.joinedAt,
          isSelf: isSelf,
          phase: isSelf
              ? ConferencePairPhase.connected
              : (pair?.phase ?? ConferencePairPhase.connecting),
        ),
      );
    }
    if (!selfListed) {
      // Prune-блип: сервер временно не видит нас в составе, но сетке
      // участников своя плитка нужна всегда — синтезируем.
      views.add(
        ConferenceParticipantView(
          messengerUserId: conf.selfUserId,
          partyId: _selfPartyId,
          joinedAt: conf.myJoinedAt,
          isSelf: true,
          phase: ConferencePairPhase.connected,
        ),
      );
    }
    views.sort((a, b) {
      final byJoin = a.joinedAt.compareTo(b.joinedAt);
      if (byJoin != 0) return byJoin;
      return a.messengerUserId.compareTo(b.messengerUserId);
    });
    _setState(
      ConferenceActive(
        roomId: conf.roomId,
        confId: conf.confId,
        startedAt: conf.startedAt,
        participants: views,
        muted: _muted,
        speakerOn: _speakerOn,
      ),
    );
  }

  void _setState(ConferenceCallState next) {
    if (_disposed) return;
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final conf = _active;
    if (conf != null && !conf.ended) {
      conf.ended = true;
      conf.heartbeatTimer?.cancel();
      for (final pair in conf.pairs.values) {
        if (pair.signalingSent && !pair.ended) {
          unawaited(_safeSendHangup(conf.roomId, pair.callId));
        }
        _closePair(pair);
      }
      conf.pairs.clear();
      unawaited(conf.localStream?.dispose());
      // Спека п.5: dispose рантайма = наш выход. Fire-and-forget (dispose
      // синхронный); не успеет — сервер зачистит TTL-ом.
      unawaited(_rpc.leaveConference(roomId: conf.roomId).catchError((_) {}));
    }
    _active = null;
    _incoming = null;
    _joiningInviteBuffer.clear();
    _joiningRosterEvent = null;
    unawaited(_sub?.cancel());
    _sub = null;
    super.dispose();
  }
}

/// Внутреннее состояние активной конференции: серверная идентичность
/// (confId может смениться при возрождении), последний известный ростер,
/// pairwise-сессии (key = partyId пира), общий локальный медиапоток и
/// heartbeat.
class _ActiveConference {
  _ActiveConference({
    required this.roomId,
    required this.confId,
    required this.selfUserId,
    required this.myJoinedAt,
    required this.startedAt,
  });

  final int roomId;
  String confId;

  /// Кэш собственного messengerUserId на момент входа: teardown/публикации
  /// не должны зависеть от живости сессии.
  final int selfUserId;

  /// Наш joinedAt из серверного ростера — базис tie-break-ов «кто зовёт».
  DateTime myJoinedAt;

  final DateTime startedAt;

  /// Последний известный полный состав (источник — сервер).
  List<ConferenceMember> roster = const [];

  /// Pairwise-сессии по partyId пира. Может содержать failed-надгробия
  /// (живём без пары, §3A.3) — их вычищает только ростер/замена.
  final Map<String, _ConferencePair> pairs = {};

  /// Общий локальный аудиопоток (микрофон), добавлен во все pc; mute —
  /// toggle `track.enabled` на нём одном.
  RtcMediaStream? localStream;

  Timer? heartbeatTimer;
  int heartbeatFailures = 0;
  bool ended = false;
}

/// Одна pairwise-сессия (mesh-ребро) с участником.
class _ConferencePair {
  _ConferencePair({
    required this.callId,
    required this.peerPartyId,
    required this.isOutgoing,
    required this.isRetry,
  });

  final String callId;
  final String peerPartyId;

  /// Мы — инвайтер пары (только инвайтер ретраит, см. `_failOrRetryPair`).
  final bool isOutgoing;

  /// Эта пара — уже ретрай (второй сбой = окончательный failed).
  final bool isRetry;

  ConferencePairPhase phase = ConferencePairPhase.connecting;
  RtcPeerConnection? pc;
  bool signalingSent = false;
  bool remoteDescriptionSet = false;
  bool answered = false;
  bool ended = false;

  final List<RtcIce> pendingLocalIce = [];
  final List<RtcIce> pendingRemoteIce = [];

  Timer? inviteTimer;
  Timer? retryTimer;
}

class _IncomingConference {
  _IncomingConference({required this.roomId, required this.confId});
  final int roomId;
  final String confId;

  /// Pairwise-invite-ы, скопившиеся за время ринга (ответим на accept).
  final List<MessengerEvent> bufferedInvites = [];
}

String _defaultIdGen() => const Uuid().v4();
DateTime _defaultNowUtc() => DateTime.now().toUtc();
