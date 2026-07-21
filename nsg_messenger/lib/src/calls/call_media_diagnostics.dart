/// **Диагностика «соединились, звука нет»** (медиа-путь звонка).
///
/// Чистые (без `flutter_webrtc`) хелперы для debug-логов: сводка по SDP
/// (направление аудио-m-line + Opus fmtp) и форматирование снимка RTP-статов.
/// Реальный парс `RTCStatsReport` / вызовы происходят в
/// `webrtc_adapter_real.dart` (единственный импортёр flutter_webrtc), а сюда
/// приходят уже примитивы — поэтому файл тестируется в чистом Dart VM.
///
/// Всё используется ТОЛЬКО под `kDebugMode` и не меняет поведение звонка —
/// это временный инструмент, чтобы на реальных устройствах определить, где
/// рвётся аудио: отправка (мало packetsSent / нулевой micLevel), приём
/// (нулевой packetsReceived при connected) или проигрывание (пакеты идут,
/// звука нет → маршрутизация/аудио-сессия).
library;

/// Однострочная сводка SDP для лога: наличие аудио-m-line, его направление
/// (`sendrecv`/`sendonly`/`recvonly`/`inactive`), payload/fmtp Opus и число
/// ICE-кандидатов в SDP. Голосовой звонок 1:1 — одна аудио-m-line, поэтому
/// скан по всему тексту достаточен (видео нет).
String summarizeSdp(String sdp) {
  final lines = sdp.split(RegExp(r'\r\n|\n'));
  final hasAudio = lines.any((l) => l.startsWith('m=audio'));
  if (!hasAudio) return 'audio m-line: ОТСУТСТВУЕТ (!)';

  // Направление — последний из sendrecv/…/inactive в аудио-секции. Для
  // audio-only одной m-line берём первый встреченный direction-атрибут.
  String? direction;
  for (final l in lines) {
    if (l == 'a=sendrecv' ||
        l == 'a=sendonly' ||
        l == 'a=recvonly' ||
        l == 'a=inactive') {
      direction = l.substring(2);
      break;
    }
  }

  final opusRe = RegExp(r'^a=rtpmap:(\d+)\s+opus/', caseSensitive: false);
  String? opusPt;
  for (final l in lines) {
    final m = opusRe.firstMatch(l);
    if (m != null) {
      opusPt = m.group(1);
      break;
    }
  }
  String? opusFmtp;
  if (opusPt != null) {
    final fmtpRe = RegExp('^a=fmtp:$opusPt\\s+(.*)\$');
    for (final l in lines) {
      final m = fmtpRe.firstMatch(l);
      if (m != null) {
        opusFmtp = m.group(1);
        break;
      }
    }
  }

  final candidates = lines.where((l) => l.startsWith('a=candidate:')).length;
  return 'audio dir=${direction ?? '?'} '
      'opus=${opusPt ?? 'НЕТ(!)'} '
      'fmtp=[${opusFmtp ?? '-'}] '
      'sdpCandidates=$candidates';
}

/// Снимок ключевых RTP-статов (примитивы, извлечённые из `RTCStatsReport`).
/// [toLogLine] даёт готовую строку для `debugPrint`.
class CallStatsSnapshot {
  const CallStatsSnapshot({
    this.packetsSent,
    this.bytesSent,
    this.micAudioLevel,
    this.packetsReceived,
    this.bytesReceived,
    this.recvAudioLevel,
    this.pairState,
    this.localCandidateType,
    this.remoteCandidateType,
    this.jitterSeconds,
    this.packetsLost,
  });

  /// outbound-rtp(audio).packetsSent — сколько RTP-пакетов МЫ отправили.
  final int? packetsSent;
  final int? bytesSent;

  /// media-source(audio).audioLevel — уровень МИКРОФОНА (0..1). >0 при речи =
  /// микрофон реально захватывает звук (иначе send-side мёртв).
  final double? micAudioLevel;

  /// inbound-rtp(audio).packetsReceived — сколько RTP МЫ приняли. 0 при
  /// connected = медиа не течёт (SRTP/negotiation/сеть), несмотря на «связь».
  final int? packetsReceived;
  final int? bytesReceived;

  /// inbound-rtp(audio).audioLevel — уровень ПРИНЯТОГО звука. >0, но не слышно
  /// = проблема проигрывания/маршрутизации/аудио-сессии.
  final double? recvAudioLevel;

  /// Выбранная candidate-pair: state + типы кандидатов (host/srflx/relay).
  /// relay = идём через TURN.
  final String? pairState;
  final String? localCandidateType;
  final String? remoteCandidateType;

  /// inbound-rtp(audio).jitter — джиттер приёма в СЕКУНДАХ (WebRTC отдаёт
  /// именно секунды). Высокий = сеть «дёргает» пакеты по времени → звук
  /// булькает даже когда потерь нет. Ориентир: >0.03с (30мс) уже слышно.
  final double? jitterSeconds;

  /// inbound-rtp(audio).packetsLost — накопительно потеряно RTP-пакетов.
  /// Растёт вместе с [packetsReceived]; смотреть надо на ДЕЛЬТУ/долю
  /// (см. [CallMediaCollector.tags] `diag.loss_pct`), а не на абсолют.
  final int? packetsLost;

  String toLogLine() =>
      'SEND(pkt=${packetsSent ?? '-'} bytes=${bytesSent ?? '-'} '
      'mic=${_lvl(micAudioLevel)}) '
      'RECV(pkt=${packetsReceived ?? '-'} bytes=${bytesReceived ?? '-'} '
      'level=${_lvl(recvAudioLevel)}) '
      'pair=${pairState ?? '-'} '
      'cand=${localCandidateType ?? '?'}/${remoteCandidateType ?? '?'} '
      'jitter=${_lvl(jitterSeconds)} lost=${packetsLost ?? '-'}';

  static String _lvl(double? v) => v == null ? '-' : v.toStringAsFixed(3);
}

/// Слать ли отчёт диагностики в трекер (GlitchTip) — включено на время
/// разбора бага «соединились, звука нет». Отключить в сборке:
/// `--dart-define=CALL_DIAG=false`.
const bool kCallDiagReportEnabled = bool.fromEnvironment(
  'CALL_DIAG',
  defaultValue: true,
);

/// Событие диагностики медиа для трекера (GlitchTip через `ErrorReporter`).
///
/// [toString] НАМЕРЕННО стабилен (только вердикт): Sentry/GlitchTip группирует
/// issue по `type + value`, поэтому переменные детали идут ТЕГАМИ
/// ([CallMediaCollector.tags]), а не в value — иначе каждый звонок плодил бы
/// новый issue вместо одной группы на вердикт.
class CallMediaDiagnosticsReport implements Exception {
  const CallMediaDiagnosticsReport(this.verdict);

  final String verdict;

  @override
  String toString() => 'CallMedia: $verdict';
}

/// Копит диагностику ОДНОГО звонка (сводки SDP + история снимков статов +
/// инфо оremote-треке) и строит вердикт/теги для отчёта в GlitchTip.
///
/// Вердикты (что искать в трекере):
///   * `never_connected` — согласование началось (собеседник ответил), но pc
///     так и не дошёл до connected. Смотреть `diag.pair` и `diag.cand`: они
///     показывают, докуда добрался ICE — набрал ли relay-кандидатов и нашёл
///     ли рабочую пару.
///   * `no_rtp_received` — при connected НЕ пришло ни одного RTP-пакета →
///     медиа не течёт (SRTP/negotiation/сеть), несмотря на «связь есть».
///   * `rtp_received_but_silent` — пакеты идут, но уровень принятого звука 0 →
///     собеседник шлёт тишину (его микрофон / DTX / send-side у него).
///   * `rtp_ok_playout_suspect` — и пакеты, и уровень есть → приём исправен,
///     значит не слышно из-за ПРОИГРЫВАНИЯ (маршрутизация/аудио-сессия).
///   * `no_stats` — getStats ничего не отдал.
class CallMediaCollector {
  final Map<String, String> _sdp = {};
  final List<CallStatsSnapshot> _stats = [];

  /// Инфо о пришедшем remote-треке (`onTrack`) — null, если трек не пришёл
  /// вовсе (сам по себе сильный сигнал).
  String? trackInfo;

  /// Дошёл ли pc до `connected`. Проставляет адаптер перед отправкой отчёта.
  bool wasConnected = false;

  bool _reported = false;

  void addSdp(String label, String sdp) => _sdp[label] = summarizeSdp(sdp);

  void addStats(CallStatsSnapshot s) => _stats.add(s);

  CallStatsSnapshot? get _last => _stats.isEmpty ? null : _stats.last;

  /// Рос ли приём пакетов между первым и последним снимком (отличает
  /// «поток идёт» от «замер на месте»).
  bool get _recvGrew {
    if (_stats.length < 2) return false;
    final first = _stats.first.packetsReceived ?? 0;
    final last = _stats.last.packetsReceived ?? 0;
    return last > first;
  }

  /// Доля потерянных пакетов ЗА ЗВОНОК, %. `packetsLost`/`packetsReceived`
  /// накопительны, поэтому считаем по ДЕЛЬТЕ между первым и последним
  /// снимком: так «плохой участок» не размывается всей историей звонка.
  /// null, если снимков <2 или в них нет счётчика потерь.
  double? get _lossPct {
    if (_stats.length < 2) return null;
    final lostFirst = _stats.first.packetsLost;
    final lostLast = _stats.last.packetsLost;
    if (lostFirst == null || lostLast == null) return null;
    final recvFirst = _stats.first.packetsReceived ?? 0;
    final recvLast = _stats.last.packetsReceived ?? 0;
    final dLost = lostLast - lostFirst;
    final dRecv = recvLast - recvFirst;
    final denom = dLost + dRecv;
    if (denom <= 0) return null; // за окно не пришло ничего — доля не определена
    return 100.0 * dLost / denom;
  }

  String get verdict {
    final s = _last;
    if (s == null) return 'no_stats';
    // Не соединились вовсе — вердикты про RTP ниже к такому звонку неприменимы
    // (пакетов нет не потому, что медиа сломано, а потому, что канала нет).
    if (!wasConnected) return 'never_connected';
    if ((s.packetsReceived ?? 0) == 0) return 'no_rtp_received';
    if ((s.recvAudioLevel ?? 0) == 0) return 'rtp_received_but_silent';
    return 'rtp_ok_playout_suspect';
  }

  /// Теги для GlitchTip — вся суть отчёта в короткие searchable-значения.
  Map<String, String> tags() {
    final s = _last;
    final t = <String, String>{
      'diag.verdict': verdict,
      'diag.samples': '${_stats.length}',
      'diag.recv_growth': _recvGrew ? 'yes' : 'no',
      'diag.track': trackInfo ?? 'NONE(!)',
    };
    if (s != null) {
      t['diag.sent_pkt'] = '${s.packetsSent ?? -1}';
      t['diag.recv_pkt'] = '${s.packetsReceived ?? -1}';
      t['diag.mic_level'] = CallStatsSnapshot._lvl(s.micAudioLevel);
      t['diag.recv_level'] = CallStatsSnapshot._lvl(s.recvAudioLevel);
      t['diag.pair'] = s.pairState ?? '-';
      t['diag.cand'] =
          '${s.localCandidateType ?? '?'}/${s.remoteCandidateType ?? '?'}';
      // Качество приёма: джиттер (последний снимок, мс для читаемости) и
      // доля потерь за звонок. По ним «момент плохой связи» виден числом.
      final j = s.jitterSeconds;
      if (j != null) t['diag.jitter_ms'] = (j * 1000).toStringAsFixed(1);
      final loss = _lossPct;
      if (loss != null) t['diag.loss_pct'] = loss.toStringAsFixed(2);
    }
    _sdp.forEach((label, summary) => t['diag.sdp.$label'] = summary);
    return t.map((k, v) => MapEntry(k, _tagValue(v)));
  }

  /// Забрать отчёт ОДИН раз (идемпотентно — flush может прийти и по таймеру,
  /// и на close). null, если уже отправляли.
  CallMediaDiagnosticsReport? takeReport() {
    if (_reported) return null;
    _reported = true;
    return CallMediaDiagnosticsReport(verdict);
  }

  /// Sentry/GlitchTip режет теги ~200 символов — подрезаем сами.
  static String _tagValue(String v) =>
      v.length <= 190 ? v : '${v.substring(0, 187)}...';
}
