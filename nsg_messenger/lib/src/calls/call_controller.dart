import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
// `Uuid` также реэкспортируется транзитивно через serverpod_client, но
// мы объявляем uuid прямой зависимостью (pubspec) и импортируем явно —
// не полагаться на transitive re-export (может пропасть при обновлении
// serverpod). Lint unnecessary_import — ложное срабатывание из-за этого
// же transitive-реэкспорта.
// ignore: unnecessary_import
import 'package:uuid/uuid.dart';

import '../auth_token_provider.dart' show ErrorReporter;
import 'call_rpc.dart';
import 'call_state.dart';
import 'ice_servers.dart';
import 'webrtc_adapter.dart';

// **TASK51**: CallTurnUnavailableReport переехал в ice_servers.dart (общий
// путь TURN у 1:1 и конференций); реэкспорт — совместимость для тестов и
// host-кода, импортировавших его отсюда.
export 'ice_servers.dart' show CallTurnUnavailableReport;

/// Генератор идентификаторов (callId / partyId). Вынесен для
/// детерминизма тестов (glare-resolution зависит от лексикографического
/// сравнения callId).
typedef IdGenerator = String Function();

/// **TASK46 (SDK)**: контроллер голосового звонка 1:1 (WebRTC поверх
/// Matrix-сигналинга через server-proxy). `ChangeNotifier` — единый
/// источник состояния для UI (overlay входящего/исходящего/in-call).
///
/// **Один звонок за раз** (MVP). Пока идёт звонок, новый исходящий
/// [startCall] no-op-ит; входящий invite во время активного звонка
/// авто-reject-ится (busy).
///
/// **Подписка на event bus — всегда.** Контроллер живёт в
/// `MessengerRuntime` весь lifetime сессии и слушает call-события из
/// [MessengerEventBus] (`callInvite`/`callAnswer`/`callCandidates`/
/// `callHangup`/`callReject`/`callSelectAnswer`), чтобы входящий звонок
/// ловился на любом экране.
///
/// **flutter_webrtc абстрагирован** за [WebRtcAdapter] — весь pc/media
/// lifecycle идёт через интерфейсы, поэтому state-machine тестируется
/// без нативного плагина (fake adapter + fake rpc + in-memory event
/// stream).
///
/// **Поток исходящего:** [startCall] → getTurnCredentials → pc(iceServers)
/// → getUserMedia(audio) → createOffer → setLocalDescription →
/// sendCallEvent(invite, sdp=offer). Trickle: onIceCandidate →
/// sendCallEvent(candidates). Входящий `callAnswer` →
/// setRemoteDescription(answer). onConnectionState=connected →
/// [CallConnected].
///
/// **Поток входящего:** `callInvite` из bus → [CallIncomingRinging].
/// [accept] → getTurn → pc → setRemoteDescription(offer) →
/// getUserMedia → createAnswer → setLocalDescription →
/// sendCallEvent(answer). [decline] → sendCallEvent(reject) → [CallEnded].
///
/// **Glare** (оба звонят одновременно A↔B): при получении invite пока у
/// нас уже есть исходящий звонок в той же комнате — сравниваем callId
/// лексикографически (MSC2746): меньший выигрывает. Если наш меньше —
/// игнорируем чужой invite (продолжаем свой); если чужой меньше —
/// сворачиваем свой ([CallEndReason.glareLost]) и принимаем входящий.
class CallController extends ChangeNotifier {
  CallController({
    required CallRpc rpc,
    required WebRtcAdapter webrtc,
    required Stream<MessengerEvent> events,
    IdGenerator? idGenerator,
    Duration inviteLifetime = const Duration(seconds: 60),
    DateTime Function()? nowUtc,
    ErrorReporter? reporter,
  }) : _rpc = rpc,
       _webrtc = webrtc,
       _idGen = idGenerator ?? _defaultIdGen,
       _inviteLifetime = inviteLifetime,
       _nowUtc = nowUtc ?? _defaultNowUtc,
       _reporter = reporter {
    // Собственный partyId устройства — стабилен на весь lifetime
    // контроллера (per-device identity для multi-device, TASK46 §1).
    _selfPartyId = _idGen();
    _sub = events.listen(_onEvent);
  }

  final CallRpc _rpc;
  final WebRtcAdapter _webrtc;

  /// Хук host-app-а для отправки ошибок в трекер. null — репортить некуда
  /// (интегратор не передал), поведение прежнее.
  final ErrorReporter? _reporter;
  final IdGenerator _idGen;
  final Duration _inviteLifetime;

  /// Источник «сейчас» (UTC) для проверки возраста invite-а. Инъекция —
  /// для детерминизма тестов staleness-guard-а.
  final DateTime Function() _nowUtc;

  late final String _selfPartyId;
  StreamSubscription<MessengerEvent>? _sub;
  bool _disposed = false;

  /// Маршрут вывода звука звонка: `true` — громкая связь (внешний
  /// динамик), `false` — разговорный динамик («к уху»).
  ///
  /// **Дефолт `false` — как в любой звонилке**: звук идёт «к уху», а при
  /// подключённых наушниках/гарнитуре ОС сама уводит его туда (оба стека
  /// маршрутизируют сами: iOS `voiceChat`, Android `MODE_IN_COMMUNICATION`).
  /// Громкая связь — осознанный выбор пользователя ([toggleSpeaker]).
  ///
  /// Раньше дефолтом была громкая связь, но по ОТЛАДОЧНОЙ причине: пока
  /// ловили баг «соединились, а звука нет», телефон на столе с исправным
  /// трактом звучал «никак» — неотличимо от поломки, и hands-free делал
  /// работу тракта слышимой. Причину бага нашли и починили (CallKit не
  /// активировал аудиосессию), так что костыль снят: включать динамик на
  /// весь кабинет по умолчанию — не то, чего ждут от звонка.
  ///
  /// Живёт на контроллере, а не в `_ActiveCall`: это предпочтение
  /// пользователя, оно переживает конкретный звонок (в рамках сессии).
  bool _speakerOn = false;

  /// Текущий маршрут вывода (см. [_speakerOn]). Для UI/тестов.
  bool get speakerOn => _speakerOn;

  CallState _state = const CallIdle();

  /// Текущее состояние звонка. UI слушает через `addListener` /
  /// `AnimatedBuilder` / `ListenableBuilder`.
  CallState get state => _state;

  /// Идёт ли уже звонок (любая фаза, кроме простоя/завершения). UI-кнопка
  /// «Позвонить» использует, чтобы не начинать второй звонок (один за раз,
  /// MVP; hold/конференция — на будущее) и показать подсказку вместо
  /// тихого no-op в [startCall].
  bool get isBusy => _state is! CallIdle && _state is! CallEnded;

  /// partyId этого устройства (для отладки / тестов).
  @visibleForTesting
  String get selfPartyId => _selfPartyId;

  // ── Активная сессия звонка (null когда idle/ended) ─────────────────
  _ActiveCall? _active;

  // ───────────────────────────────────────────────────────────────────
  // Public API (команды UI)
  // ───────────────────────────────────────────────────────────────────

  /// **Исходящий звонок.** No-op, если уже есть активный звонок
  /// (`state != idle/ended`). Поднимает pc, берёт микрофон, шлёт invite.
  /// Ошибка микрофона → [CallEnded]`(micDenied)`; прочие ошибки setup →
  /// [CallEnded]`(failed)` + teardown.
  Future<void> startCall({
    required int roomId,
    int? peerMessengerUserId,
    String? peerDisplayName,
  }) async {
    if (_disposed) return;
    if (_active != null && _state is! CallEnded) {
      if (kDebugMode) {
        debugPrint('[CallController] startCall ignored — call already active');
      }
      return;
    }
    final callId = _idGen();
    final call = _ActiveCall(
      callId: callId,
      roomId: roomId,
      partyId: _selfPartyId,
      isOutgoing: true,
    );
    _active = call;
    // Стадия 1 ringback — «дозвон до сервера» (reachedPeer=false): держится,
    // пока идёт TURN-fetch + микрофон + createOffer + отправка invite.
    _setState(
      CallOutgoingRinging(
        callId: callId,
        roomId: roomId,
        peerMessengerUserId: peerMessengerUserId,
        peerDisplayName: peerDisplayName,
      ),
    );

    try {
      final pc = await _buildPeerConnection(call);
      final stream = await _acquireMic(call);
      await pc.addLocalStream(stream);

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      if (_isStale(call)) return;

      await _rpc.sendCallEvent(
        roomId: roomId,
        eventType: CallEventType.invite,
        callId: callId,
        partyId: _selfPartyId,
        sdp: offer.sdp,
      );
      // Стадия 2 ringback — «звонит на устройстве» (reachedPeer=true): invite
      // доставлен серверу → он маршрутизирует его на устройство собеседника
      // (/sync + VoIP-push). Явного «callee ringing» ack в протоколе нет,
      // поэтому успешная доставка invite — лучшая аппроксимация. Перевыставляем
      // состояние только если всё ещё звоним ЭТИМ звонком (answer/hangup за
      // время await мог увести нас дальше — тогда не откатываем).
      if (!_isStale(call) && _state is CallOutgoingRinging) {
        _setState(
          CallOutgoingRinging(
            callId: callId,
            roomId: roomId,
            peerMessengerUserId: peerMessengerUserId,
            peerDisplayName: peerDisplayName,
            reachedPeer: true,
          ),
        );
      }
      _flushPendingIce(call);
      _armInviteTimeout(call);
    } on MicPermissionDeniedException {
      await _endCall(call, CallEndReason.micDenied, notifyPeer: false);
    } on PeerUnavailableException {
      // **issue #5**: сервер отклонил invite — собеседник недоступен (не
      // активирован / нет устройства и офлайн). Не «идёт вызов» в пустоту:
      // сразу завершаем понятной причиной. notifyPeer:false — invite не
      // ушёл, звонка на той стороне нет, гасить нечего.
      if (kDebugMode) {
        debugPrint('[CallController] startCall — peer unavailable');
      }
      await _endCall(call, CallEndReason.peerUnavailable, notifyPeer: false);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CallController] startCall failed: $e\n$st');
      await _endCall(call, CallEndReason.failed, notifyPeer: true);
    }
  }

  /// **Принять входящий звонок.** Валиден только в [CallIncomingRinging].
  /// Поднимает pc, применяет удалённый offer, берёт микрофон, шлёт answer.
  Future<void> accept() async {
    if (_disposed) return;
    final call = _active;
    final s = _state;
    if (call == null || s is! CallIncomingRinging) return;
    final offerSdp = call.remoteOfferSdp;
    if (offerSdp == null) return;

    _cancelInviteTimeout(call);
    _enterConnecting(call);

    try {
      final pc = await _buildPeerConnection(call);
      await pc.setRemoteDescription(RtcSdp(type: SdpType.offer, sdp: offerSdp));
      final stream = await _acquireMic(call);
      await pc.addLocalStream(stream);

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      if (_isStale(call)) return;

      await _rpc.sendCallEvent(
        roomId: call.roomId,
        eventType: CallEventType.answer,
        callId: call.callId,
        partyId: _selfPartyId,
        sdp: answer.sdp,
      );
      _flushPendingIce(call);
    } on MicPermissionDeniedException {
      await _endCall(call, CallEndReason.micDenied, notifyPeer: true);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CallController] accept failed: $e\n$st');
      await _endCall(call, CallEndReason.failed, notifyPeer: true);
    }
  }

  /// **Отклонить входящий звонок.** Шлёт `reject`, завершает.
  Future<void> decline() async {
    if (_disposed) return;
    final call = _active;
    if (call == null || _state is! CallIncomingRinging) return;
    _cancelInviteTimeout(call);
    // reject (v1 explicit decline) — сервер маппит в m.call.reject.
    await _safeSend(
      roomId: call.roomId,
      eventType: CallEventType.reject,
      callId: call.callId,
    );
    await _endCall(call, CallEndReason.declined, notifyPeer: false);
  }

  /// **Положить трубку.** Валиден в любом активном состоянии. Шлёт
  /// hangup, закрывает pc, останавливает треки, → [CallEnded].
  Future<void> hangup() async {
    if (_disposed) return;
    final call = _active;
    if (call == null) return;
    await _endCall(call, CallEndReason.localHangup, notifyPeer: true);
  }

  /// **Mute/unmute** локального микрофона (toggle `audioTrack.enabled`).
  /// Валиден только в [CallConnected] (иначе no-op → возвращает false).
  /// Возвращает новое состояние mute.
  bool toggleMute() {
    if (_disposed) return false;
    final call = _active;
    final s = _state;
    if (call == null || s is! CallConnected) return false;
    final newMuted = !s.muted;
    for (final track
        in call.localStream?.audioTracks ?? const <MediaAudioTrack>[]) {
      track.enabled = !newMuted;
    }
    _setState(s.copyWith(muted: newMuted));
    return newMuted;
  }

  /// **Громкая связь вкл/выкл** (маршрут вывода звука звонка: внешний
  /// динамик ↔ разговорный «к уху»). Валиден только в [CallConnected]
  /// (иначе no-op). Возвращает новое состояние громкой связи.
  ///
  /// В отличие от [toggleMute] (чисто локальный `track.enabled`), меняет
  /// маршрут в нативном слое — асинхронно и best-effort, поэтому UI не
  /// ждёт результата: состояние эмитим сразу, маршрут догоняет.
  bool toggleSpeaker() {
    if (_disposed) return _speakerOn;
    final s = _state;
    if (_active == null || s is! CallConnected) return _speakerOn;
    _speakerOn = !_speakerOn;
    unawaited(_applySpeakerRoute());
    _setState(s.copyWith(speakerOn: _speakerOn));
    return _speakerOn;
  }

  // ───────────────────────────────────────────────────────────────────
  // Event bus reactor
  // ───────────────────────────────────────────────────────────────────

  /// **TASK46 (звонки в фоне)**: впрыснуть `callInvite`, полученный НЕ из
  /// live-стрима, а через `NsgMessenger.fetchCallInvite` (эндпоинт).
  ///
  /// Нужно, когда приложение разбудили push-ом на входящий звонок из
  /// убитого состояния: сервер уже consumed live `m.call.invite` (чтобы
  /// послать push) до того, как клиент успел подписаться на стрим, поэтому
  /// invite надо дотянуть отдельно. Идёт через тот же путь `_onInvite`
  /// (идемпотентно по callId — двойная доставка live+fetch безопасна).
  void ingestFetchedInvite(MessengerEvent event) {
    if (_disposed) return;
    if (event.eventType != MessengerEventType.callInvite) return;
    _onInvite(event);
  }

  void _onEvent(MessengerEvent event) {
    if (_disposed) return;
    switch (event.eventType) {
      case MessengerEventType.callInvite:
        _onInvite(event);
      case MessengerEventType.callAnswer:
        _onAnswer(event);
      case MessengerEventType.callCandidates:
        _onCandidates(event);
      case MessengerEventType.callHangup:
        _onHangupOrReject(event, CallEndReason.remoteHangup);
      case MessengerEventType.callReject:
        _onHangupOrReject(event, CallEndReason.remoteHangup);
      case MessengerEventType.callSelectAnswer:
        _onSelectAnswer(event);
      case MessengerEventType.callNegotiate:
        _onNegotiate(event);
      // ignore: no_default_cases
      default:
        break;
    }
  }

  void _onInvite(MessengerEvent event) {
    final callId = event.callId;
    final roomId = event.roomId;
    final offerSdp = event.callSdp;
    // roomId обязателен для call-событий (server гарантирует), но тип
    // nullable — guard, чтобы не пропустить malformed event.
    if (callId == null || roomId == null || offerSdp == null) return;

    // **TASK51**: pairwise-invite mesh-конференции (callId `conf:...`) —
    // НЕ наш звонок: его обрабатывает ConferenceCallController. Без guard-а
    // первый же pairwise-invite конференции зазвонил бы здесь как обычный
    // 1:1-входящий (а при нашем активном исходящем в той же комнате ещё и
    // ушёл бы в glare-ветку и мог свернуть живой 1:1-звонок). Guard именно
    // в _onInvite: прочие события чужого callId и так отсекает `_matches`,
    // а invite — единственное, что создаёт состояние с нуля. Покрывает оба
    // пути доставки (live-шина и `ingestFetchedInvite` push-побудки).
    if (callId.startsWith('conf:')) return;

    // Защита от «звонков из прошлого». Invite может прилететь спустя
    // минуты/часы — replay-ем Matrix-синхронизации при reconnect-е или
    // бэклогом отложенных пушей. Ринговать его = фантомный входящий.
    // Отбрасываем, если возраст события превышает его lifetime + запас
    // (на fetch-из-кэша push-побудки убитого app ~65с и перекос часов).
    // Свежий live/fetch invite (возраст ~секунды) проходит.
    final lifetimeMs = event.callLifetime ?? _inviteLifetime.inMilliseconds;
    final maxInviteAge =
        Duration(milliseconds: lifetimeMs) + const Duration(seconds: 30);
    final inviteAge = _nowUtc().difference(event.serverTimestamp.toUtc());
    if (inviteAge > maxInviteAge) {
      if (kDebugMode) {
        debugPrint(
          '[CallController] drop stale invite $callId '
          'age=${inviteAge.inSeconds}s > ${maxInviteAge.inSeconds}s',
        );
      }
      return;
    }

    // Идемпотентность: тот же звонок уже активен. Invite может прийти
    // дважды — из live-стрима И через `ingestFetchedInvite` (push-побудка
    // убитого app, см. fetchCallInvite). Второй раз — no-op, иначе ниже
    // busy-ветка ошибочно авто-reject-нула бы наш же входящий.
    final existing = _active;
    if (existing != null && existing.callId == callId && _state is! CallEnded) {
      return;
    }

    final active = _active;
    // Glare: у нас уже есть исходящий звонок в этой же комнате.
    if (active != null &&
        active.isOutgoing &&
        active.roomId == roomId &&
        _state is! CallEnded) {
      // MSC2746: лексикографически меньший callId выигрывает.
      if (active.callId.compareTo(callId) < 0) {
        // Наш меньше → мы выигрываем; игнорируем входящий invite.
        if (kDebugMode) {
          debugPrint(
            '[CallController] glare: keeping our call ${active.callId}',
          );
        }
        return;
      }
      // Чужой меньше (или равен) → сворачиваем свой, принимаем входящий.
      if (kDebugMode) {
        debugPrint('[CallController] glare: yielding to incoming $callId');
      }
      // Синхронно эмитим CallEnded(glareLost) для проигравшего звонка ДО
      // переключения на входящий — иначе async _endCall потерял бы этот
      // переход (к моменту его выполнения _active уже был бы новым).
      _yieldForGlare(active);
    } else if (active != null && _state is! CallEnded) {
      // Busy другим звонком (другая комната / уже соединяемся) →
      // авто-reject входящий, не трогаем текущий.
      unawaited(
        _safeSend(
          roomId: roomId,
          eventType: CallEventType.reject,
          callId: callId,
        ),
      );
      return;
    }

    final call = _ActiveCall(
      callId: callId,
      roomId: roomId,
      partyId: _selfPartyId,
      isOutgoing: false,
    )..remoteOfferSdp = offerSdp;
    _active = call;
    _setState(
      CallIncomingRinging(
        callId: callId,
        roomId: roomId,
        callerMatrixUserId: event.callSenderMatrixUserId,
      ),
    );
    _armInviteTimeout(call, lifetimeMs: event.callLifetime);
  }

  void _onAnswer(MessengerEvent event) {
    final call = _active;
    if (call == null || !_matches(call, event)) return;
    if (!call.isOutgoing) return;
    final answerSdp = event.callSdp;
    if (answerSdp == null) return;
    if (call.answered) return; // первый answer выигрывает (MVP)
    call.answered = true;
    // Multi-device: запоминаем, С КЕМ именно говорим. Дальше hangup/reject от
    // ДРУГИХ устройств собеседника игнорируем (см. `_onHangupOrReject`).
    call.answeredPartyId = event.callPartyId;
    _cancelInviteTimeout(call);
    _enterConnecting(call);

    final pc = call.pc;
    if (pc == null) return;
    unawaited(() async {
      try {
        await pc.setRemoteDescription(
          RtcSdp(type: SdpType.answer, sdp: answerSdp),
        );
        // Caller: remote SDP установлен → входящие ICE теперь можно
        // применять; сливаем накопленный буфер.
        call.remoteDescriptionSet = true;
        _drainRemoteIce(call);
        // Multi-device корректность: подтверждаем выбранного отвечающего.
        final answererParty = event.callPartyId;
        if (answererParty != null) {
          await _safeSend(
            roomId: call.roomId,
            eventType: CallEventType.selectAnswer,
            callId: call.callId,
            selectedPartyId: answererParty,
          );
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[CallController] setRemoteDescription(answer) failed: '
            '$e\n$st',
          );
        }
        await _endCall(call, CallEndReason.failed, notifyPeer: true);
      }
    }());
  }

  void _onCandidates(MessengerEvent event) {
    final call = _active;
    if (call == null || !_matches(call, event)) return;
    final incoming = event.callCandidates ?? const <CallIceCandidate>[];
    final pc = call.pc;
    for (final c in incoming) {
      final ice = RtcIce(
        candidate: c.candidate,
        sdpMid: c.sdpMid,
        sdpMLineIndex: c.sdpMLineIndex,
      );
      if (pc == null || !call.remoteDescriptionSet) {
        // pc ещё не готов / remote SDP не установлен — буферим,
        // применим после setRemoteDescription (WebRTC требует порядок).
        call.pendingRemoteIce.add(ice);
      } else {
        unawaited(_addIce(call, ice));
      }
    }
    // Если pc уже готов — попробуем слить накопленный буфер.
    _drainRemoteIce(call);
  }

  /// **Network resilience — renegotiation (ICE restart).**
  ///
  /// Инициатор рестарта всегда caller (см. `_restartIce`), поэтому роли
  /// детерминированы, glare встречных offer-ов невозможен:
  ///   * callee получает negotiate-**offer** → применяет как
  ///     remoteDescription, создаёт answer, шлёт negotiate-**answer**;
  ///   * caller получает negotiate-**answer** → просто применяет
  ///     remoteDescription (ICE перезапустится, придут свежие кандидаты).
  ///
  /// Glare-защита: callee сам рестарт НЕ инициирует (`_canRestartIce`
  /// требует isOutgoing) и на negotiate-answer не реагирует.
  void _onNegotiate(MessengerEvent event) {
    final call = _active;
    if (call == null || !_matches(call, event)) return;
    final sdp = event.callSdp;
    final pc = call.pc;
    if (sdp == null || pc == null) return;
    // Роль SDP: 'answer' — ответ нам (caller); иначе offer — нам (callee).
    final isAnswer = event.callSdpType == 'answer';

    if (isAnswer) {
      // Caller: применяем answer на наш restart-offer. Не-caller игнорирует
      // (glare-защита — только инициатор ждёт answer).
      if (!call.isOutgoing) return;
      unawaited(() async {
        try {
          await pc.setRemoteDescription(RtcSdp(type: SdpType.answer, sdp: sdp));
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              '[CallController] negotiate answer apply failed: '
              '$e\n$st',
            );
          }
        }
      }());
      return;
    }

    // Callee: получили restart-offer → отвечаем answer-ом. Только сторона,
    // которая изначально приняла (не caller) — иначе оба слали бы offer.
    if (call.isOutgoing) return; // glare-guard: caller не отвечает на offer.
    // **fix#2**: negotiate-offer = «caller запустил рестарт» → снимаем/
    // перевзводим callee kill-таймер (не убивать, пока рестарт в процессе).
    // Перевзвод, а не просто отмена: если сам рестарт не поднимет P2P за окно,
    // звонок всё равно завершится (не зависает навсегда).
    _armCalleeRecoveryWindow(call);
    unawaited(() async {
      try {
        await pc.setRemoteDescription(RtcSdp(type: SdpType.offer, sdp: sdp));
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        if (_isStale(call)) return;
        await _rpc.sendCallEvent(
          roomId: call.roomId,
          eventType: CallEventType.negotiate,
          callId: call.callId,
          partyId: _selfPartyId,
          sdp: answer.sdp,
          sdpType: 'answer',
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[CallController] negotiate offer handling failed: '
            '$e\n$st',
          );
        }
      }
    }());
  }

  /// **Multi-device**: caller выбрал, КАКОЕ устройство собеседника ответило
  /// (`m.call.select_answer`, MSC2746). Если выбрали НЕ нас — на этом
  /// устройстве звонок надо тихо погасить: трубку взяли на другом.
  ///
  /// Без этого вторая сессия того же пользователя (напр. Windows рядом с
  /// телефоном) продолжала звонить «как будто никто не взял» до
  /// invite-таймаута — и, что хуже, нажатие «отклонить» на ней слало `reject`
  /// с тем же callId и обрывало ЖИВОЙ разговор на первом устройстве.
  void _onSelectAnswer(MessengerEvent event) {
    final call = _active;
    if (call == null || !_matches(call, event)) return;
    // select_answer шлёт сам caller — себе он не адресован.
    if (call.isOutgoing) return;
    // Реагируем только пока ещё звоним; приняв звонок, мы и есть выбранные.
    if (_state is! CallIncomingRinging) return;
    final selected = event.callSelectedPartyId;
    if (selected == null) return;
    if (selected == _selfPartyId) return; // выбрали нас — продолжаем
    if (kDebugMode) {
      debugPrint(
        '[CallController] answered elsewhere (party=$selected) — '
        'гасим ринг ${call.callId}',
      );
    }
    // notifyPeer:false — звонок жив на другом устройстве, обрывать нельзя.
    unawaited(_endCall(call, CallEndReason.answeredElsewhere, notifyPeer: false));
  }

  void _onHangupOrReject(MessengerEvent event, CallEndReason reason) {
    final call = _active;
    if (call == null || !_matches(call, event)) return;
    // **Multi-device guard**: когда мы уже соединились с конкретным
    // устройством собеседника, hangup/reject от ДРУГОГО его устройства
    // (второй сессии, которую мы погасили select_answer-ом) не должен
    // обрывать живой разговор. Если partyId неизвестен — ведём себя
    // как раньше (честно завершаем): 1:1-кейс не ломаем.
    final answeredWith = call.answeredPartyId;
    final from = event.callPartyId;
    if (call.isOutgoing &&
        call.answered &&
        answeredWith != null &&
        from != null &&
        from != answeredWith) {
      if (kDebugMode) {
        debugPrint(
          '[CallController] игнорируем ${event.eventType.name} от чужого '
          'устройства (party=$from, говорим с $answeredWith)',
        );
      }
      return;
    }
    // Удалённое завершение — pc закрываем, hangup обратно НЕ шлём.
    unawaited(_endCall(call, reason, notifyPeer: false));
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals — pc lifecycle
  // ───────────────────────────────────────────────────────────────────

  Future<RtcPeerConnection> _buildPeerConnection(_ActiveCall call) async {
    final iceServers = await _resolveIceServers();
    final pc = await _webrtc.createPeerConnection(iceServers);
    call.pc = pc;

    pc.onIceCandidate = (RtcIce ice) {
      if (_isStale(call)) return;
      // Локальный кандидат → trickle в комнату. Буферим до отправки
      // invite/answer, чтобы не гнать candidates раньше сигнала.
      if (!call.signalingSent) {
        call.pendingLocalIce.add(ice);
        return;
      }
      unawaited(_sendLocalIce(call, ice));
    };
    pc.onConnectionState = (RtcConnState s) {
      if (_isStale(call)) return;
      switch (s) {
        case RtcConnState.connected:
          _onPcConnected(call);
        case RtcConnState.failed:
          _onPcFailed(call);
        case RtcConnState.disconnected:
          _onPcDisconnected(call);
        case RtcConnState.closed:
          // Закрытие без нашего hangup — трактуем как завершение.
          if (_state is! CallEnded) {
            unawaited(_endCall(call, CallEndReason.failed, notifyPeer: false));
          }
        case RtcConnState.connecting:
          break;
      }
    };
    pc.onRemoteTrack = () {
      if (kDebugMode) debugPrint('[CallController] remote audio track');
    };
    return pc;
  }

  void _onPcConnected(_ActiveCall call) {
    if (_isStale(call)) return;
    // P2P поднялся (первично или после ICE-рестарта): снимаем connect-таймаут
    // и дебаунс disconnect-а, обнуляем счётчик рестартов (следующий обрыв —
    // «с чистого листа»), помечаем что соединение было живым.
    _cancelConnectTimeout(call);
    _cancelDisconnectDebounce(call);
    _cancelRestartRecovery(call);
    call.wasConnected = true;
    call.iceRestartAttempts = 0;
    // Переприменяем маршрут вывода: активация аудио-сессии (в т.ч. после
    // ICE-рестарта / смены сети / перехвата сессии системой) сбрасывает
    // маршрут на умолчание платформы — то есть в разговорный динамик.
    unawaited(_applySpeakerRoute());
    // Идемпотентно — connected может прийти повторно; после ре-connect-а
    // (успешный рестарт) состояние уже CallConnected, повторно не эмитим,
    // но сброс таймеров/счётчиков и маршрута выше сделать нужно.
    if (_state is CallConnected) return;
    _setState(
      CallConnected(
        callId: call.callId,
        roomId: call.roomId,
        startedAt: DateTime.now(),
        muted: false,
        speakerOn: _speakerOn,
      ),
    );
  }

  // ── network resilience: ICE restart на смену сети / потерю связи ─────

  /// `failed` — negotiation окончательно провалилась. Разведено по ролям:
  ///
  ///   * **caller** (может рестартить): если звонок уже был connected —
  ///     ICE restart немедленно (сеть точно менялась); иначе первичный
  ///     connect не поднялся → `CallEnded(failed)`.
  ///   * **callee** (рестарт не инициирует): НЕ убиваем мгновенно, пока есть
  ///     шанс поймать caller-restart negotiate-offer-ом. Взводим длинный
  ///     kill-таймер [_calleeRecoveryWindow] (≫ caller-restart+RPC), который
  ///     входящий negotiate-offer снимет/перевзведёт. Только если окно
  ///     истекло без negotiate — `CallEnded(failed)`.
  void _onPcFailed(_ActiveCall call) {
    _cancelDisconnectDebounce(call);
    if (call.wasConnected && call.isOutgoing) {
      if (_canRestartIce(call)) {
        _restartIce(call);
        return;
      }
      // caller исчерпал рестарты → конец.
      unawaited(_endCall(call, CallEndReason.failed, notifyPeer: true));
      return;
    }
    if (call.wasConnected && !call.isOutgoing) {
      // callee: не убивать сразу — ждём negotiate от caller (fix#2).
      _armCalleeRecoveryWindow(call);
      return;
    }
    // Первичный connect не поднялся (ни разу не был connected) → конец.
    unawaited(_endCall(call, CallEndReason.failed, notifyPeer: true));
  }

  /// `disconnected` — временная потеря связи. WebRTC часто чинит сам за
  /// пару секунд. Разведено по ролям (fix#2 — при смене сети ОБА видят
  /// disconnected одновременно, симметричные таймеры устраивали гонку):
  ///
  ///   * **caller**: дебаунс [_disconnectDebounce] (5с) → ICE restart, если
  ///     за окно не вернулись в connected.
  ///   * **callee**: длинный kill-таймер [_calleeRecoveryWindow] (20с) —
  ///     столько ждём caller-restart; negotiate-offer его снимет.
  void _onPcDisconnected(_ActiveCall call) {
    if (!call.wasConnected) return; // до первого connected — не наш кейс.
    if (call.disconnectTimer != null) return; // таймер уже взведён.
    if (!call.isOutgoing) {
      _armCalleeRecoveryWindow(call);
      return;
    }
    call.disconnectTimer = Timer(_disconnectDebounce, () {
      call.disconnectTimer = null;
      if (_isStale(call)) return;
      // За окно не восстановилось (иначе connected сбросил бы таймер) →
      // рестарт, если ещё можем.
      if (_canRestartIce(call)) {
        _restartIce(call);
      } else {
        unawaited(_endCall(call, CallEndReason.failed, notifyPeer: true));
      }
    });
  }

  /// **Callee kill-таймер** (fix#2): взвести/перевзвести окно ожидания
  /// caller-restart-а. Идёт через `disconnectTimer` (переиспользуем слот —
  /// у callee нет своего рестарта). Пока таймер жив, звонок держим; при
  /// истечении без negotiate — `CallEnded(failed)`. Входящий negotiate-offer
  /// зовёт этот метод повторно (перевзвод) — «рестарт пошёл, дай ещё время».
  void _armCalleeRecoveryWindow(_ActiveCall call) {
    if (_isStale(call)) return;
    call.disconnectTimer?.cancel();
    if (kDebugMode) {
      debugPrint(
        '[CallController] callee recovery window '
        '(${_calleeRecoveryWindow.inSeconds}s) callId=${call.callId}',
      );
    }
    call.disconnectTimer = Timer(_calleeRecoveryWindow, () {
      call.disconnectTimer = null;
      if (_isStale(call)) return;
      // Окно истекло, negotiate так и не пришёл → соединение мертво.
      unawaited(_endCall(call, CallEndReason.failed, notifyPeer: true));
    });
  }

  /// Инициировать рестарт может ТОЛЬКО caller (кто изначально звонил) —
  /// детерминированная сторона, чтобы не было glare встречных offer-ов.
  /// Callee ждёт negotiate-offer и отвечает answer-ом. Плюс лимит попыток.
  bool _canRestartIce(_ActiveCall call) =>
      call.isOutgoing && call.iceRestartAttempts < _maxIceRestarts;

  /// **Caller-side ICE restart**: пересобрать offer с новым ICE
  /// (`iceRestart:true`), отправить как `negotiate`-offer (с ретраями на
  /// транзиентный сетевой сбой — fix#4), взвести recovery-таймаут (fix#5).
  /// Callee ответит negotiate-answer, придут свежие кандидаты, P2P поднимется
  /// заново → `connected` снимет recovery-таймаут и обнулит счётчик.
  void _restartIce(_ActiveCall call) {
    if (_isStale(call)) return;
    final pc = call.pc;
    if (pc == null) return;
    call.iceRestartAttempts++;
    if (kDebugMode) {
      debugPrint(
        '[CallController] ICE restart #${call.iceRestartAttempts} '
        'callId=${call.callId}',
      );
    }
    // **fix#5 — recovery-таймаут вместо мёртвого connect-таймаута.** Рестарт
    // идёт из CallConnected, где `_armConnectTimeout` был бы мёртвым кодом
    // (его callback стреляет только в CallConnecting). Взводим отдельный
    // таймаут, срабатывающий НЕЗАВИСИМО от состояния: если за окно P2P не
    // восстановился (re-`connected` снял бы таймер), звонок гарантированно
    // завершается `CallEnded(failed)` — «Соединение…» не висит вечно.
    _armRestartRecovery(call);
    unawaited(() async {
      try {
        final offer = await pc.createOffer(iceRestart: true);
        await pc.setLocalDescription(offer);
        if (_isStale(call)) return;
        final ok = await _sendNegotiateWithRetry(
          call,
          sdp: offer.sdp,
          sdpType: 'offer',
        );
        if (!ok && !_isStale(call)) {
          // Все ретраи RPC провалились (fix#4): попытка рестарта не
          // состоялась. Recovery-таймаут добьёт звонок, если не сможем
          // рестартить снова — но при исчерпании лимита завершаем сразу.
          if (kDebugMode) {
            debugPrint(
              '[CallController] negotiate send exhausted retries '
              'callId=${call.callId}',
            );
          }
          if (!_canRestartIce(call)) {
            await _endCall(call, CallEndReason.failed, notifyPeer: true);
          }
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[CallController] ICE restart failed: $e\n$st');
        }
        await _endCall(call, CallEndReason.failed, notifyPeer: true);
      }
    }());
  }

  /// **fix#4** — отправка `negotiate`-события с ретраями. При смене сети RPC
  /// может отвалиться транзиентно; повторяем до 3 раз с бэкоффом (1с/2с/4с).
  /// Возвращает `true`, если отправка удалась (на любой попытке), иначе
  /// `false` (все ретраи исчерпаны). Между попытками проверяем staleness —
  /// звонок мог завершиться/смениться.
  Future<bool> _sendNegotiateWithRetry(
    _ActiveCall call, {
    required String? sdp,
    required String sdpType,
  }) async {
    for (var attempt = 0; attempt < _negotiateRetryBackoff.length; attempt++) {
      if (_isStale(call)) return false;
      try {
        await _rpc.sendCallEvent(
          roomId: call.roomId,
          eventType: CallEventType.negotiate,
          callId: call.callId,
          partyId: _selfPartyId,
          sdp: sdp,
          sdpType: sdpType,
        );
        return true;
      } catch (e) {
        final isLast = attempt == _negotiateRetryBackoff.length - 1;
        if (kDebugMode) {
          debugPrint(
            '[CallController] negotiate send attempt ${attempt + 1} '
            'failed: $e${isLast ? ' (giving up)' : ' (retrying)'}',
          );
        }
        if (isLast) return false;
        await Future<void>.delayed(_negotiateRetryBackoff[attempt]);
      }
    }
    return false;
  }

  /// **fix#5** — взвести recovery-таймаут caller-restart-а. Срабатывает
  /// независимо от `CallState` (в отличие от connect-таймаута). Если за
  /// [_restartRecoveryTimeout] соединение не вернулось в `connected` (что
  /// сняло бы таймер в `_onPcConnected`), звонок завершается `failed`.
  void _armRestartRecovery(_ActiveCall call) {
    _cancelRestartRecovery(call);
    call.restartRecoveryTimer = Timer(_restartRecoveryTimeout, () {
      call.restartRecoveryTimer = null;
      if (_isStale(call)) return;
      // Не вернулись в connected за окно (re-connect снял бы таймер) →
      // звонок мёртв. Гарантированное завершение (не зависаем в «Соединение…»
      // / Connected без медиа).
      if (_state is! CallEnded) {
        if (kDebugMode) {
          debugPrint(
            '[CallController] restart recovery timeout → failed '
            'callId=${call.callId}',
          );
        }
        unawaited(_endCall(call, CallEndReason.failed, notifyPeer: true));
      }
    });
  }

  void _cancelRestartRecovery(_ActiveCall call) {
    call.restartRecoveryTimer?.cancel();
    call.restartRecoveryTimer = null;
  }

  void _cancelDisconnectDebounce(_ActiveCall call) {
    call.disconnectTimer?.cancel();
    call.disconnectTimer = null;
  }

  /// Взять микрофон и сразу применить маршрут вывода звука.
  ///
  /// Маршрут применяем ИМЕННО здесь: `getUserMedia` — тот момент, когда
  /// нативный слой поднимает аудио-сессию звонка (iOS переводит её в
  /// `playAndRecord`, Android — в `MODE_IN_COMMUNICATION`); до этого
  /// маршрутизировать нечего. Повторно — в [_onPcConnected].
  Future<RtcMediaStream> _acquireMic(_ActiveCall call) async {
    final stream = await _webrtc.getUserMediaAudio();
    call.localStream = stream;
    await _applySpeakerRoute();
    return stream;
  }

  /// Применить текущий [_speakerOn] к нативному слою. Best-effort:
  /// адаптер сам глушит ошибки и no-op-ит на desktop/web.
  Future<void> _applySpeakerRoute() => _webrtc.setSpeakerphone(_speakerOn);

  /// Список ICE-серверов для pc — общий путь с конференциями (TASK51):
  /// TURN-креды + STUN-fallback + громкий репорт деградации, см.
  /// [resolveIceServers] в `ice_servers.dart` (код вынесен туда 1:1).
  Future<List<Map<String, dynamic>>> _resolveIceServers() =>
      resolveIceServers(_rpc, _reporter);

  // ── ICE trickle helpers ────────────────────────────────────────────

  /// После отправки invite/answer — сливаем накопленные локальные
  /// кандидаты и разрешаем немедленную отправку последующих.
  ///
  /// - Callee: к этому моменту `setRemoteDescription(offer)` уже сделан
  ///   (в [accept]) → remote SDP есть, входящие ICE можно применять.
  /// - Caller: remote SDP (answer) ещё НЕ пришёл → `remoteDescriptionSet`
  ///   выставится позже в [_onAnswer]. Локальные ICE при этом гнать
  ///   уже можно (invite отправлен).
  void _flushPendingIce(_ActiveCall call) {
    call.signalingSent = true;
    if (!call.isOutgoing) {
      call.remoteDescriptionSet = true;
    }
    final pending = List<RtcIce>.of(call.pendingLocalIce);
    call.pendingLocalIce.clear();
    for (final ice in pending) {
      unawaited(_sendLocalIce(call, ice));
    }
    _drainRemoteIce(call);
  }

  Future<void> _sendLocalIce(_ActiveCall call, RtcIce ice) async {
    if (_isStale(call)) return;
    await _safeSend(
      roomId: call.roomId,
      eventType: CallEventType.candidates,
      callId: call.callId,
      candidates: [
        CallIceCandidate(
          candidate: ice.candidate,
          sdpMid: ice.sdpMid,
          sdpMLineIndex: ice.sdpMLineIndex,
        ),
      ],
    );
  }

  void _drainRemoteIce(_ActiveCall call) {
    final pc = call.pc;
    if (pc == null || !call.remoteDescriptionSet) return;
    final pending = List<RtcIce>.of(call.pendingRemoteIce);
    call.pendingRemoteIce.clear();
    for (final ice in pending) {
      unawaited(_addIce(call, ice));
    }
  }

  Future<void> _addIce(_ActiveCall call, RtcIce ice) async {
    final pc = call.pc;
    if (pc == null) return;
    try {
      await pc.addIceCandidate(ice);
    } catch (e) {
      if (kDebugMode) debugPrint('[CallController] addIceCandidate failed: $e');
    }
  }

  // ── invite lifetime timeout ─────────────────────────────────────────

  void _armInviteTimeout(_ActiveCall call, {int? lifetimeMs}) {
    _cancelInviteTimeout(call);
    final dur = lifetimeMs != null
        ? Duration(milliseconds: lifetimeMs)
        : _inviteLifetime;
    call.inviteTimer = Timer(dur, () {
      if (_disposed || _isStale(call)) return;
      // Никто не ответил / мы не приняли за lifetime → таймаут.
      final ended =
          _state is CallOutgoingRinging || _state is CallIncomingRinging;
      if (ended) {
        unawaited(_endCall(call, CallEndReason.timeout, notifyPeer: true));
      }
    });
  }

  void _cancelInviteTimeout(_ActiveCall call) {
    call.inviteTimer?.cancel();
    call.inviteTimer = null;
  }

  // ── connect timeout ─────────────────────────────────────────────────

  /// Максимум на установку P2P-соединения после accept/answer. WebRTC
  /// (ICE-gathering + connectivity + DTLS) при живом TURN укладывается в
  /// секунды; 45с — щедрый потолок, чтобы не убить медленное-но-рабочее
  /// соединение.
  static const _connectTimeout = Duration(seconds: 45);

  // ── network resilience (ICE restart) ────────────────────────────────

  /// **Caller-side** дебаунс перед рестартом на `disconnected`: WebRTC часто
  /// чинит временную потерю связи сам за пару секунд (roaming Wi-Fi↔LTE),
  /// поэтому не дёргаем renegotiation сразу — ждём окно и рестартим только
  /// если соединение так и не вернулось.
  static const _disconnectDebounce = Duration(seconds: 5);

  /// **Callee-side** kill-таймер на `disconnected`/`failed`. НАМЕРЕННО
  /// существенно длиннее caller-дебаунса (5с): при смене сети ОБА пира видят
  /// `disconnected` примерно одновременно, и раньше симметричный 5с-таймер
  /// callee убивал звонок ровно в тот момент, когда caller только начинал
  /// ICE-restart (гонка «kill vs negotiate»). Даём callee широкое окно, за
  /// которое caller-restart (дебаунс 5с + createOffer + RPC + доставка через
  /// /sync) успевает долететь negotiate-offer-ом. Любой входящий
  /// negotiate-offer перевзводит/снимает этот таймер (см. `_onNegotiate`) —
  /// «рестарт идёт, не убивать».
  static const _calleeRecoveryWindow = Duration(seconds: 20);

  /// **Caller-side recovery-таймаут**: максимум на восстановление P2P от
  /// СТАРТА ICE-restart-а до re-`connected`. В отличие от [_connectTimeout]
  /// (который жив только в `CallConnecting`), этот срабатывает НЕЗАВИСИМО от
  /// состояния — рестарт идёт из `CallConnected`, где connect-таймаут был бы
  /// мёртвым кодом. Покрывает: createOffer+RPC+доставку negotiate-offer,
  /// answer обратно, повторную ICE/DTLS-сходимость. Если за окно не
  /// восстановились и лимит ретраев/рестартов исчерпан → `CallEnded(failed)`.
  static const _restartRecoveryTimeout = Duration(seconds: 15);

  /// Ретраи отправки `negotiate` по RPC (fix#4): смена сети — ровно тот
  /// момент, когда транзиентный сетевой сбой RPC наиболее вероятен. 3 попытки
  /// с экспоненциальным бэкоффом (1с/2с/4с) поверх лимита [_maxIceRestarts].
  /// Неудача ВСЕХ ретраев = провал этой попытки рестарта.
  static const _negotiateRetryBackoff = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  /// Максимум ICE-рестартов на звонок. Дальше — существующий путь
  /// `CallEnded(failed)` (сеть не поднимается, дальнейшие попытки бесполезны
  /// и лишь тянут «Соединение…»).
  static const _maxIceRestarts = 2;

  /// Переход в [CallConnecting] + взвод connect-таймаута. Если P2P не
  /// поднимется за [_connectTimeout], звонок завершается явной ошибкой
  /// вместо бесконечного «Соединение…» (индикация для пользователя).
  void _enterConnecting(_ActiveCall call) {
    _setState(CallConnecting(callId: call.callId, roomId: call.roomId));
    _armConnectTimeout(call);
  }

  void _armConnectTimeout(_ActiveCall call) {
    _cancelConnectTimeout(call);
    call.connectTimer = Timer(_connectTimeout, () {
      if (_disposed || _isStale(call)) return;
      // Всё ещё «Соединение…» → P2P не установился (TURN/сеть) → фейл.
      if (_state is CallConnecting) {
        unawaited(_endCall(call, CallEndReason.failed, notifyPeer: true));
      }
    });
  }

  void _cancelConnectTimeout(_ActiveCall call) {
    call.connectTimer?.cancel();
    call.connectTimer = null;
  }

  // ── teardown ────────────────────────────────────────────────────────

  /// **Glare-yield**: свернуть проигравший исходящий звонок синхронно с
  /// эмитом [CallEnded]`(glareLost)`, ПЕРЕД переключением на входящий.
  /// Обычный async [_endCall] тут не годится: к моменту его выполнения
  /// `_active` уже указывал бы на новый входящий звонок, и guard
  /// `identical(_active, call)` подавил бы переход. Ресурсы (hangup-signal,
  /// pc, tracks) освобождаются fire-and-forget.
  void _yieldForGlare(_ActiveCall call) {
    if (call.ended) return;
    call.ended = true;
    _cancelInviteTimeout(call);
    _cancelConnectTimeout(call);
    _cancelDisconnectDebounce(call);
    _cancelRestartRecovery(call);
    if (call.signalingSent) {
      unawaited(
        _safeSend(
          roomId: call.roomId,
          eventType: CallEventType.hangup,
          callId: call.callId,
          hangupReason: _hangupReasonString(CallEndReason.glareLost),
        ),
      );
    }
    unawaited(call.pc?.close());
    unawaited(call.localStream?.dispose());
    call.pc = null;
    call.localStream = null;
    _active = null;
    _setState(CallEnded(reason: CallEndReason.glareLost, callId: call.callId));
  }

  Future<void> _endCall(
    _ActiveCall call,
    CallEndReason reason, {
    required bool notifyPeer,
  }) async {
    // Идемпотентно — teardown может прийти из нескольких источников
    // (hangup event + pc closed).
    if (call.ended) return;
    call.ended = true;
    _cancelInviteTimeout(call);
    _cancelConnectTimeout(call);
    _cancelDisconnectDebounce(call);
    _cancelRestartRecovery(call);

    if (notifyPeer && call.signalingSent) {
      await _safeSend(
        roomId: call.roomId,
        eventType: CallEventType.hangup,
        callId: call.callId,
        hangupReason: _hangupReasonString(reason),
      );
    }
    await call.pc?.close();
    await call.localStream?.dispose();
    call.pc = null;
    call.localStream = null;

    // Сбрасываем активный звонок только если это он же (защита от race
    // с уже начатым следующим звонком).
    if (identical(_active, call)) {
      _active = null;
      _setState(CallEnded(reason: reason, callId: call.callId));
    }
  }

  /// Отправка call-события, не бросающая (best-effort — сигналинг
  /// hangup/reject/candidates не должен ронять teardown).
  Future<void> _safeSend({
    required int roomId,
    required CallEventType eventType,
    required String callId,
    String? sdp,
    List<CallIceCandidate>? candidates,
    String? hangupReason,
    String? selectedPartyId,
  }) async {
    try {
      await _rpc.sendCallEvent(
        roomId: roomId,
        eventType: eventType,
        callId: callId,
        partyId: _selfPartyId,
        sdp: sdp,
        candidates: candidates,
        hangupReason: hangupReason,
        selectedPartyId: selectedPartyId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CallController] sendCallEvent(${eventType.name}) '
          'failed: $e (best-effort)',
        );
      }
    }
  }

  // ── guards / helpers ────────────────────────────────────────────────

  /// Событие относится к текущему звонку (roomId + callId).
  bool _matches(_ActiveCall call, MessengerEvent event) =>
      event.roomId == call.roomId && event.callId == call.callId;

  /// Звонок больше не активен (сменился/завершился) — async-continuation
  /// должна прекратиться.
  bool _isStale(_ActiveCall call) =>
      _disposed || call.ended || !identical(_active, call);

  void _setState(CallState next) {
    if (_disposed) return;
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  static String _hangupReasonString(CallEndReason reason) {
    switch (reason) {
      case CallEndReason.localHangup:
      case CallEndReason.remoteHangup:
        return 'user_hangup';
      case CallEndReason.declined:
        return 'user_reject';
      case CallEndReason.micDenied:
        return 'ice_failed';
      case CallEndReason.failed:
        return 'ice_failed';
      case CallEndReason.peerUnavailable:
        // На практике не уходит в комнату: этот путь всегда notifyPeer:false
        // (invite отклонён сервером — звонка на той стороне нет).
        return 'user_unavailable';
      case CallEndReason.timeout:
        return 'invite_timeout';
      case CallEndReason.glareLost:
        return 'glare';
      case CallEndReason.answeredElsewhere:
        // Стандартная причина Matrix VoIP. На практике не уходит в комнату:
        // этот путь всегда notifyPeer:false (звонок жив на другом устройстве).
        return 'answered_elsewhere';
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final call = _active;
    // Помечаем звонок завершённым ДО teardown: in-flight _restartIce, поймав
    // падение createOffer на уже закрытом pc, зовёт _endCall(notifyPeer:true).
    // Без флага _endCall не сработает идемпотентно и отправит в комнату
    // паразитный m.call.hangup(ice_failed) уже после dispose (мусор в истории).
    call?.ended = true;
    _active = null;
    unawaited(_sub?.cancel());
    _sub = null;
    call?.inviteTimer?.cancel();
    call?.connectTimer?.cancel();
    call?.disconnectTimer?.cancel();
    call?.restartRecoveryTimer?.cancel();
    // Fire-and-forget teardown pc/tracks (не await — dispose синхронный).
    unawaited(call?.pc?.close());
    unawaited(call?.localStream?.dispose());
    super.dispose();
  }
}

/// Внутреннее состояние одного активного звонка. Держит pc, локальный
/// media-stream, буферы trickle-ICE, таймер invite.
class _ActiveCall {
  _ActiveCall({
    required this.callId,
    required this.roomId,
    required this.partyId,
    required this.isOutgoing,
  });

  final String callId;
  final int roomId;
  final String partyId;
  final bool isOutgoing;

  RtcPeerConnection? pc;
  RtcMediaStream? localStream;

  /// SDP offer входящего звонка (callee, до accept).
  String? remoteOfferSdp;

  /// Первый answer уже применён (MVP: первый выигрывает).
  bool answered = false;

  /// **Multi-device**: partyId устройства собеседника, чей answer мы приняли
  /// (с кем реально говорим). Служит фильтром для hangup/reject от его же
  /// ОСТАЛЬНЫХ устройств. null — answer без partyId (старый сервер/1:1).
  String? answeredPartyId;

  /// invite/answer уже отправлен — можно гнать локальные ICE.
  bool signalingSent = false;

  /// remote SDP установлен — можно добавлять входящие ICE.
  bool remoteDescriptionSet = false;

  bool ended = false;

  final List<RtcIce> pendingLocalIce = [];
  final List<RtcIce> pendingRemoteIce = [];

  Timer? inviteTimer;

  /// Таймаут установки P2P после accept/answer (см. `_armConnectTimeout`).
  Timer? connectTimer;

  /// **Network resilience**: звонок хотя бы раз доходил до connected —
  /// значит P2P реально поднимался и restart имеет смысл (в отличие от
  /// первичного connect, где failed → сразу конец).
  bool wasConnected = false;

  /// Caller: дебаунс `disconnected` перед рестартом. Callee: kill-таймер
  /// ожидания caller-restart-а (переиспользуем слот — у callee своего
  /// рестарта нет).
  Timer? disconnectTimer;

  /// **fix#5**: recovery-таймаут caller-restart-а — завершает звонок, если
  /// P2P не восстановился за окно после старта рестарта (независимо от
  /// CallState, в отличие от connect-таймаута).
  Timer? restartRecoveryTimer;

  /// Сколько ICE-рестартов уже выполнено в этом звонке (лимит попыток).
  int iceRestartAttempts = 0;
}

const _uuid = Uuid();
String _defaultIdGen() => _uuid.v4();
DateTime _defaultNowUtc() => DateTime.now().toUtc();
