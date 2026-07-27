import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BoxFit, Widget;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../auth_token_provider.dart' show ErrorReporter;
import 'call_media_diagnostics.dart';
import 'sdp_tuning.dart';
import 'webrtc_adapter.dart';

/// **TASK46 (SDK)**: production-реализация [WebRtcAdapter] поверх
/// `flutter_webrtc`. **Единственный** файл SDK, импортирующий
/// `package:flutter_webrtc` — весь остальной call-код (CallController)
/// работает через транспортно-нейтральные интерфейсы
/// (`webrtc_adapter.dart`), что даёт тестируемость без нативного плагина.
///
/// Конфиг pc — `unified-plan`, один audio m-line (MVP аудио 1:1). См.
/// спайк `apps/spike/lib/webrtc_loopback_spike.dart` — доказал, что этот
/// путь собирается на web (dart2js) + windows (нативный libwebrtc) и
/// проходит ICE/DTLS до `connected` с Opus audio-треком.
class RealWebRtcAdapter implements WebRtcAdapter {
  const RealWebRtcAdapter({this.reporter});

  /// **Диагностика «звука нет»**: репортер host-app-а (chatista мостит его в
  /// GlitchTip). Если задан — на каждый СОСТОЯВШИЙСЯ звонок уходит один
  /// отчёт с вердиктом и тегами (см. [CallMediaCollector]). null (титан/
  /// тесты) → только debugPrint.
  final ErrorReporter? reporter;

  @override
  Future<RtcPeerConnection> createPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    final config = <String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    };
    final pc = await rtc.createPeerConnection(config);
    return _RealPeerConnection(pc, reporter);
  }

  @override
  Future<RtcMediaStream> getUserMediaAudio() async {
    try {
      final stream = await rtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      return _RealMediaStream(stream);
    } catch (e) {
      // getUserMedia бросает по-разному на web (DOMException
      // NotAllowedError / SecurityError) и mobile/desktop. Единый маппинг
      // в доменную ошибку, которую CallController превратит в
      // CallEndReason.micDenied. Мы не различаем «denied» и «нет
      // устройства» точно — для MVP любой отказ getUserMedia = не можем
      // начать звонок (mic недоступен).
      if (kDebugMode) {
        debugPrint('[RealWebRtcAdapter] getUserMedia failed: $e');
      }
      throw MicPermissionDeniedException(e);
    }
  }

  // ── TASK80: демонстрация экрана ─────────────────────────────────

  /// Захват экрана есть на web (`getDisplayMedia` браузера) и на
  /// desktop-нативе (flutter_webrtc `common/cpp` для Windows/Linux,
  /// `RTCDesktopCapturer`/ScreenCaptureKit для macOS). На iOS/Android
  /// плагин формально умеет `getDisplayMedia`, но ТОЛЬКО с нативной
  /// обвязкой (iOS — Broadcast Upload Extension + App Group; Android —
  /// MediaProjection + foreground-service `mediaProjection`), которой у
  /// нас нет. Возвращать здесь true = кнопка, которая не работает —
  /// прямо запрещено DoD. Смотреть чужой показ мобильные умеют и без
  /// этого (входящий трек рендерится везде).
  @override
  bool get supportsScreenShare =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  /// На web источник выбирает системный диалог браузера — свой список
  /// не рисуем. На desktop-нативе flutter_webrtc 1.5.2 системного
  /// диалога не показывает: `getDisplayMedia` там ищет источник в
  /// списке, наполняемом `getDesktopSources`, и без `deviceId.exact`
  /// отвечает `source not found`. Значит список — на нас.
  @override
  bool get screenShareNeedsSourcePicker => !kIsWeb;

  @override
  Future<List<ScreenShareSource>> listScreenShareSources() async {
    if (kIsWeb) return const [];
    final sources = await rtc.desktopCapturer.getSources(
      types: const [rtc.SourceType.Screen, rtc.SourceType.Window],
    );
    return [
      for (final s in sources)
        ScreenShareSource(
          id: s.id,
          name: s.name,
          isWindow: s.type == rtc.SourceType.Window,
        ),
    ];
  }

  @override
  Future<RtcMediaStream> getDisplayMedia({
    required ScreenShareCaps caps,
    String? sourceId,
  }) async {
    try {
      final stream = await rtc.navigator.mediaDevices.getDisplayMedia(
        _displayMediaConstraints(caps, sourceId),
      );
      return _RealMediaStream(stream);
    } catch (e) {
      // Как и у микрофона: «запретил», «закрыл диалог», «источник
      // пропал» платформы разделяют по-разному и ненадёжно. Для UI это
      // один случай — показ не начался, роль докладчика надо вернуть.
      if (kDebugMode) {
        debugPrint('[RealWebRtcAdapter] getDisplayMedia failed: $e');
      }
      throw ScreenSharePermissionDeniedException(e);
    }
  }

  /// Constraints захвата. Формы РАЗНЫЕ:
  ///   * web — стандартные MediaTrackConstraints (`width/height/
  ///     frameRate` с `ideal`/`max`), их применяет сам браузер;
  ///   * native — flutter_webrtc читает ровно два места:
  ///     `video.deviceId.exact` (какой экран/окно) и
  ///     `video.mandatory.frameRate` (частота захвата); остальное
  ///     уезжает в `ParseMediaConstraints` как есть.
  static Map<String, dynamic> _displayMediaConstraints(
    ScreenShareCaps caps,
    String? sourceId,
  ) {
    if (kIsWeb) {
      return <String, dynamic>{
        // Системный звук не берём: спека про экран, а лишний
        // audio-трек ломал бы mute-семантику микрофона.
        'audio': false,
        'video': {
          'width': {'ideal': caps.maxWidth, 'max': caps.maxWidth},
          'height': {'ideal': caps.maxHeight, 'max': caps.maxHeight},
          'frameRate': {'ideal': caps.maxFramerate, 'max': caps.maxFramerate},
        },
      };
    }
    return <String, dynamic>{
      'audio': false,
      'video': {
        if (sourceId != null) 'deviceId': {'exact': sourceId},
        'mandatory': {
          'frameRate': caps.maxFramerate.toDouble(),
          'maxWidth': caps.maxWidth,
          'maxHeight': caps.maxHeight,
          'maxFrameRate': caps.maxFramerate,
        },
      },
    };
  }

  @override
  Future<RtcVideoRenderer> createVideoRenderer() async {
    final renderer = _RealVideoRenderer();
    await renderer.initialize();
    return renderer;
  }

  @override
  Future<void> setSpeakerphone(bool enabled) async {
    // Маршрутизация вывода есть только на мобильных: `Helper
    // .setSpeakerphoneOn` бьёт в нативный канал flutter_webrtc, которого
    // на desktop/web нет (там маршрут выбирает ОС/браузер).
    if (!_supportsAudioRouting) return;
    try {
      await rtc.Helper.setSpeakerphoneOn(enabled);
      if (kDebugMode) {
        debugPrint('[CallAudio] маршрут: ${enabled ? "динамик" : "ухо"}');
      }
    } catch (e) {
      // Best-effort: не тот маршрут — плохо, но упавший звонок хуже.
      if (kDebugMode) {
        debugPrint('[CallAudio] setSpeakerphoneOn($enabled) failed: $e');
      }
    }
  }

  /// Есть ли на этой платформе управляемый маршрут вывода звонка.
  /// `defaultTargetPlatform`, а не `dart:io Platform`, — файл собирается
  /// и под web (dart2js), где `dart:io` недоступен.
  static bool get _supportsAudioRouting =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
}

class _RealPeerConnection implements RtcPeerConnection {
  _RealPeerConnection(this._pc, this._reporter) {
    _pc.onIceCandidate = (rtc.RTCIceCandidate c) {
      final cb = _onIce;
      if (cb == null) return;
      cb(
        RtcIce(
          candidate: c.candidate ?? '',
          sdpMid: c.sdpMid,
          sdpMLineIndex: c.sdpMLineIndex,
        ),
      );
    };
    _pc.onConnectionState = (rtc.RTCPeerConnectionState s) {
      _onConn?.call(_mapConnState(s));
      // **Диагностика «звука нет»**: пока connected — периодически снимаем
      // RTP-статы (packetsSent/Received, уровни, тип ICE-пары).
      _syncStatsProbe(_mapConnState(s));
    };
    _pc.onTrack = (rtc.RTCTrackEvent event) {
      _onRemoteTrack?.call();
      // **TASK80**: видео-трек собеседника = он начал показ экрана.
      // Отдаём поток целиком — рендереру нужен `MediaStream`.
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        _onRemoteVideo?.call(_RealMediaStream(event.streams.first));
      }
      final info =
          'kind=${event.track.kind} streams=${event.streams.length} '
          'enabled=${event.track.enabled}';
      _diag.trackInfo = info;
      if (kDebugMode) debugPrint('[CallDiag] onTrack $info');
    };
  }

  final rtc.RTCPeerConnection _pc;

  /// Репортер host-app-а → GlitchTip (null = только debugPrint).
  final ErrorReporter? _reporter;

  void Function(RtcIce candidate)? _onIce;
  void Function(RtcConnState state)? _onConn;
  void Function()? _onRemoteTrack;
  void Function(RtcMediaStream stream)? _onRemoteVideo;

  /// **Диагностика**: копилка данных по этому звонку (SDP + статы + трек).
  final CallMediaCollector _diag = CallMediaCollector();

  /// Таймер периодического снятия getStats, пока соединение живо.
  Timer? _statsTimer;

  /// Одноразовый таймер отправки отчёта в трекер (даём накопить снимки).
  Timer? _flushTimer;

  /// Звонок реально дошёл до connected.
  bool _wasConnected = false;

  /// Согласование действительно началось: пришёл remote SDP, т.е. собеседник
  /// ответил и ICE пошёл проверять пары. Признак отчётности.
  ///
  /// **Почему не `_wasConnected`.** Раньше отчёт слался только для дошедших до
  /// connected звонков — и звонок, который ТАК И НЕ СОЕДИНИЛСЯ, не давал в
  /// трекер ровно ничего: проб не заводился, снимков не было, `_flushReport`
  /// выходил на первой строке. Это ровно тот отказ, который мы и ловим
  /// (сборка 62: сигналинг прошёл за 3.5 с, потом 43 с тишины и отбой) — и
  /// смотреть было не на что, отсюда «в логах всё штатно».
  ///
  /// Отклонённый/неотвеченный звонок сюда не попадает: без ответа собеседника
  /// remote SDP не приходит — значит шуметь на них не начнём.
  bool _negotiationStarted = false;

  @override
  set onIceCandidate(void Function(RtcIce candidate)? cb) => _onIce = cb;

  @override
  set onConnectionState(void Function(RtcConnState state)? cb) => _onConn = cb;

  @override
  set onRemoteTrack(void Function()? cb) => _onRemoteTrack = cb;

  @override
  set onRemoteVideoStream(void Function(RtcMediaStream stream)? cb) =>
      _onRemoteVideo = cb;

  @override
  Future<void> addLocalStream(RtcMediaStream stream) async {
    final real = stream as _RealMediaStream;
    for (final track in real.stream.getAudioTracks()) {
      await _pc.addTrack(track, real.stream);
    }
  }

  @override
  Future<RtcVideoSender?> addVideoTrack(RtcMediaStream stream) async {
    final real = stream as _RealMediaStream;
    final tracks = real.stream.getVideoTracks();
    if (tracks.isEmpty) return null;
    // Стрим захвата — ровно один видео-трек (см. getDisplayMedia).
    final sender = await _pc.addTrack(tracks.first, real.stream);
    return _RealVideoSender(sender);
  }

  @override
  Future<void> removeVideoSender(RtcVideoSender sender) async {
    final real = sender as _RealVideoSender;
    try {
      await _pc.removeTrack(real.sender);
    } catch (e) {
      // Pc уже закрыт / трек снят — не повод ронять остановку показа.
      if (kDebugMode) debugPrint('[RealWebRtcAdapter] removeTrack failed: $e');
    }
  }

  @override
  Future<RtcSdp> createOffer({bool iceRestart = false}) async {
    // iceRestart:true → flutter_webrtc сгенерирует offer с новым ICE
    // ufrag/pwd (перезапуск ICE при смене сети / disconnect).
    //
    // **Кросс-платформенный ключ.** flutter_webrtc 1.5.2 читает флаг
    // ICE-restart из РАЗНЫХ мест на разных платформах:
    //   * native (Android/iOS/desktop libwebrtc) — из
    //     `constraints['mandatory']['IceRestart']` (MediaConstraints,
    //     ключ с ЗАГЛАВНОЙ `I`; верхнеуровневый `iceRestart` натив
    //     молча игнорирует — `createOffer` берёт только mandatory/optional);
    //   * web (dart_webrtc → RTCOfferOptions) — из верхнеуровневого
    //     `constraints['iceRestart']` (map передаётся в JS `createOffer`
    //     как-есть, браузер читает camelCase-поле).
    // Поэтому кладём ОБА ключа — лишний на каждой платформе безвреден.
    final desc = await _pc.createOffer(
      iceRestart
          ? {
              'mandatory': {'IceRestart': true},
              'iceRestart': true,
            }
          : {},
    );
    return _tuneOpus(_fromDesc(desc, SdpType.offer));
  }

  @override
  Future<RtcSdp> createAnswer() async {
    final desc = await _pc.createAnswer({});
    return _tuneOpus(_fromDesc(desc, SdpType.answer));
  }

  /// **TASK46**: оттюнить Opus в локальном SDP (FEC/DTX/моно/битрейт) —
  /// применяем к offer и answer перед их отдачей контроллеру (тот делает
  /// `setLocalDescription`). Идемпотентно; если Opus в SDP нет — no-op.
  ///
  /// **TASK80**: тем же проходом кладём потолок битрейта на видео-m-line
  /// (демонстрация экрана). Тут, а не в контроллере: любой SDP,
  /// уезжающий в setLocalDescription, обязан быть с cap-ом — включая
  /// negotiate-offer/answer при добавлении показа в идущий звонок. Если
  /// видео в SDP нет (обычный аудио-звонок) — no-op.
  static RtcSdp _tuneOpus(RtcSdp sdp) => RtcSdp(
    type: sdp.type,
    sdp: capVideoBitrateSdp(
      tuneOpusSdp(sdp.sdp),
      maxKbps: kScreenShareCaps.maxBitrateKbps,
    ),
  );

  @override
  Future<void> setLocalDescription(RtcSdp sdp) {
    _recordSdp('local', sdp);
    return _pc.setLocalDescription(_toDesc(sdp));
  }

  @override
  Future<void> setRemoteDescription(RtcSdp sdp) {
    _recordSdp('remote', sdp);
    // Собеседник ответил → ICE пошёл. С этого момента снимаем статы, даже если
    // до connected дело так и не дойдёт: иначе провал установки не оставляет
    // никаких следов (см. [_negotiationStarted]).
    _startStatsProbe();
    return _pc.setRemoteDescription(_toDesc(sdp));
  }

  /// Сводку SDP — в копилку (уйдёт тегом в GlitchTip), полный текст — в
  /// debugPrint (в трекер не тащим: не влезет в тег и незачем).
  void _recordSdp(String side, RtcSdp sdp) {
    final role = sdp.type == SdpType.offer ? 'offer' : 'answer';
    _diag.addSdp('${side}_$role', sdp.sdp);
    if (kDebugMode) {
      debugPrint('[CallDiag] ${side.toUpperCase()} $role — '
          '${summarizeSdp(sdp.sdp)}');
      debugPrint('[CallDiag] ${side.toUpperCase()} $role full SDP:\n${sdp.sdp}');
    }
  }

  @override
  Future<void> addIceCandidate(RtcIce candidate) => _pc.addCandidate(
    rtc.RTCIceCandidate(
      candidate.candidate,
      candidate.sdpMid,
      candidate.sdpMLineIndex,
    ),
  );

  @override
  Future<void> close() async {
    // Звонок кончился — досылаем отчёт, если таймер не успел (короткий звонок).
    _flushReport();
    _statsTimer?.cancel();
    _statsTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    try {
      await _pc.close();
    } catch (e) {
      if (kDebugMode) debugPrint('[RealWebRtcAdapter] pc.close failed: $e');
    }
  }

  // ── Диагностика медиа (поведение звонка не меняет) ─────────────────────

  /// Остановить проб и отчитаться на `closed`; на `connected` — отметить
  /// успех и завести таймер отчёта. Сам проб заводится раньше, из
  /// [setRemoteDescription] (см. [_startStatsProbe]).
  void _syncStatsProbe(RtcConnState state) {
    if (state == RtcConnState.closed) {
      _flushReport();
      _statsTimer?.cancel();
      _statsTimer = null;
      _flushTimer?.cancel();
      _flushTimer = null;
      return;
    }
    if (state == RtcConnState.connected) {
      _wasConnected = true;
      // Через 10с после connected накопится несколько снимков → видно, растёт
      // ли приём. Тогда и шлём отчёт, не дожидаясь конца разговора.
      //
      // Таймер ставим ТОЛЬКО здесь: если завести его вместе с пробом, звонок,
      // который не соединился, отчитался бы через 10 с промежуточным
      // вердиктом и `takeReport` закрыл бы отчёт — финальную картину на
      // `close` мы бы уже не увидели. Для таких звонков отчёт уходит на
      // `close`, где статы максимально полные.
      _flushTimer ??= Timer(const Duration(seconds: 10), _flushReport);
    }
  }

  /// Завести периодический getStats-проб. Идемпотентно. Живёт через
  /// disconnected/failed (наблюдаем восстановление), снимается на `closed`.
  void _startStatsProbe() {
    if (_statsTimer != null) return;
    _negotiationStarted = true;
    unawaited(_logStats()); // первый снимок сразу
    _statsTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_logStats()),
    );
  }

  /// Отправить ОДИН отчёт по звонку в трекер (GlitchTip через host-репортер).
  /// Идемпотентно ([CallMediaCollector.takeReport]); только для состоявшихся
  /// (connected) звонков; best-effort — диагностика не должна ничего ронять.
  void _flushReport() {
    if (!kCallDiagReportEnabled || !_negotiationStarted) return;
    _diag.wasConnected = _wasConnected;
    final reporter = _reporter;
    if (reporter == null) return;
    final report = _diag.takeReport();
    if (report == null) return; // уже отправляли
    try {
      reporter.reportError(report, null, tags: _diag.tags());
      if (kDebugMode) {
        debugPrint('[CallDiag] отчёт отправлен в трекер: $report');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CallDiag] отправка отчёта упала: $e');
    }
  }

  /// Снять RTCStats, извлечь ключевые примитивы, залогировать одной строкой.
  /// Best-effort — ошибки getStats глушим (диагностика не должна ничего ронять).
  Future<void> _logStats() async {
    try {
      final reports = await _pc.getStats();
      int? packetsSent, bytesSent, packetsReceived, bytesReceived, packetsLost;
      double? micLevel, recvLevel, jitter;
      String? pairState, localCandId, remoteCandId;
      final candTypeById = <String, String>{};

      for (final r in reports) {
        final v = r.values;
        final isAudio = v['kind'] == 'audio' || v['mediaType'] == 'audio';
        switch (r.type) {
          case 'outbound-rtp':
            if (isAudio) {
              packetsSent = _asInt(v['packetsSent']) ?? packetsSent;
              bytesSent = _asInt(v['bytesSent']) ?? bytesSent;
            }
          case 'inbound-rtp':
            if (isAudio) {
              packetsReceived = _asInt(v['packetsReceived']) ?? packetsReceived;
              bytesReceived = _asInt(v['bytesReceived']) ?? bytesReceived;
              recvLevel = _asDouble(v['audioLevel']) ?? recvLevel;
              // Джиттер (секунды) и накопленные потери — качество приёма.
              jitter = _asDouble(v['jitter']) ?? jitter;
              packetsLost = _asInt(v['packetsLost']) ?? packetsLost;
            }
          case 'media-source':
            if (isAudio) micLevel = _asDouble(v['audioLevel']) ?? micLevel;
          case 'candidate-pair':
            final nominated = v['nominated'] == true || v['selected'] == true;
            if (nominated || v['state'] == 'succeeded') {
              pairState = v['state']?.toString();
              localCandId = v['localCandidateId']?.toString();
              remoteCandId = v['remoteCandidateId']?.toString();
            }
          case 'local-candidate':
          case 'remote-candidate':
            final ct = v['candidateType']?.toString();
            if (ct != null) candTypeById[r.id] = ct;
        }
      }

      final snap = CallStatsSnapshot(
        packetsSent: packetsSent,
        bytesSent: bytesSent,
        micAudioLevel: micLevel,
        packetsReceived: packetsReceived,
        bytesReceived: bytesReceived,
        recvAudioLevel: recvLevel,
        pairState: pairState,
        localCandidateType: localCandId == null
            ? null
            : candTypeById[localCandId],
        remoteCandidateType: remoteCandId == null
            ? null
            : candTypeById[remoteCandId],
        jitterSeconds: jitter,
        packetsLost: packetsLost,
      );
      _diag.addStats(snap); // копим для отчёта в трекер
      if (kDebugMode) debugPrint('[CallDiag] ${snap.toLogLine()}');
    } catch (e) {
      if (kDebugMode) debugPrint('[CallDiag] getStats failed: $e');
    }
  }

  static int? _asInt(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));

  static double? _asDouble(Object? v) =>
      v is double ? v : (v is num ? v.toDouble() : double.tryParse('$v'));

  static RtcSdp _fromDesc(rtc.RTCSessionDescription d, SdpType fallbackType) {
    final type = d.type == 'answer' ? SdpType.answer : SdpType.offer;
    return RtcSdp(type: d.type != null ? type : fallbackType, sdp: d.sdp ?? '');
  }

  static rtc.RTCSessionDescription _toDesc(RtcSdp sdp) =>
      rtc.RTCSessionDescription(
        sdp.sdp,
        sdp.type == SdpType.offer ? 'offer' : 'answer',
      );

  static RtcConnState _mapConnState(rtc.RTCPeerConnectionState s) {
    switch (s) {
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return RtcConnState.connected;
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return RtcConnState.disconnected;
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return RtcConnState.failed;
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return RtcConnState.closed;
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return RtcConnState.connecting;
    }
  }
}

class _RealMediaStream implements RtcMediaStream {
  _RealMediaStream(this.stream);
  final rtc.MediaStream stream;

  /// Обёртки видео-треков кэшируем (в отличие от аудио): на видео-трек
  /// вешается `onEnded` — «пользователь нажал системную остановку», и
  /// свежая обёртка на каждый геттер этот колбэк теряла бы.
  final Map<String, _RealVideoTrack> _videoWrappers = {};

  @override
  List<MediaAudioTrack> get audioTracks =>
      stream.getAudioTracks().map(_RealAudioTrack.new).toList();

  @override
  List<MediaVideoTrack> get videoTracks => [
    for (final t in stream.getVideoTracks())
      _videoWrappers.putIfAbsent(t.id ?? '${t.hashCode}', () =>
          _RealVideoTrack(t)),
  ];

  @override
  Future<void> dispose() async {
    for (final t in stream.getTracks()) {
      await t.stop();
    }
    await stream.dispose();
  }
}

class _RealAudioTrack implements MediaAudioTrack {
  _RealAudioTrack(this._track);
  final rtc.MediaStreamTrack _track;

  @override
  bool get enabled => _track.enabled;

  @override
  set enabled(bool value) => _track.enabled = value;
}

/// **TASK80**: видео-трек демонстрации. `onEnded` — единственный
/// сигнал о системной остановке захвата («Прекратить показ» в плашке
/// браузера, закрытие расшаренного окна, отзыв разрешения ОС).
class _RealVideoTrack implements MediaVideoTrack {
  _RealVideoTrack(this._track);
  final rtc.MediaStreamTrack _track;

  @override
  bool get enabled => _track.enabled;

  @override
  set enabled(bool value) => _track.enabled = value;

  @override
  set onEnded(void Function()? cb) => _track.onEnded = cb;
}

/// **TASK80**: ручка отправителя видео + применение рамок качества.
class _RealVideoSender implements RtcVideoSender {
  _RealVideoSender(this.sender);
  final rtc.RTCRtpSender sender;

  @override
  Future<void> applyScreenShareCaps(ScreenShareCaps caps) async {
    try {
      final params = sender.parameters;
      // `contentHint: 'detail'` в API flutter_webrtc 1.5.2 не выведен
      // (ни в `MediaStreamTrack`, ни в `Helper`). Его смысл — «при
      // нехватке полосы режь fps, не разрешение» — задаём напрямую тем
      // же, во что libwebrtc транслирует detail/text: degradation
      // preference = maintain-resolution.
      params.degradationPreference =
          rtc.RTCDegradationPreference.MAINTAIN_RESOLUTION;
      final encodings = params.encodings;
      if (encodings == null || encodings.isEmpty) {
        params.encodings = [
          rtc.RTCRtpEncoding(
            maxBitrate: caps.maxBitrateBps,
            maxFramerate: caps.maxFramerate,
          ),
        ];
      } else {
        for (final e in encodings) {
          e.maxBitrate = caps.maxBitrateBps;
          e.maxFramerate = caps.maxFramerate;
          // Разрешение не даунскейлим сверх захвата — чёткость важнее
          // (см. kScreenShareCaps).
          e.scaleResolutionDownBy = 1.0;
        }
      }
      await sender.setParameters(params);
    } catch (e) {
      // Best-effort: часть платформ игнорирует часть параметров.
      // Жёсткий потолок всё равно стоит в SDP (`b=AS:`).
      if (kDebugMode) {
        debugPrint('[RealWebRtcAdapter] applyScreenShareCaps failed: $e');
      }
    }
  }
}

/// **TASK80**: обёртка `RTCVideoRenderer` + `RTCVideoView`.
class _RealVideoRenderer implements RtcVideoRenderer {
  final rtc.RTCVideoRenderer _renderer = rtc.RTCVideoRenderer();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _renderer.initialize();
    _initialized = true;
  }

  @override
  set srcObject(RtcMediaStream? stream) {
    _renderer.srcObject = stream == null
        ? null
        : (stream as _RealMediaStream).stream;
  }

  @override
  Widget buildView({BoxFit fit = BoxFit.contain}) => rtc.RTCVideoView(
    _renderer,
    objectFit: fit == BoxFit.cover
        ? rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
        : rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
  );

  @override
  Future<void> dispose() async {
    _renderer.srcObject = null;
    await _renderer.dispose();
    _initialized = false;
  }
}
