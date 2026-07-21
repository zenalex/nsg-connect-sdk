/// **TASK46 (SDK)**: тонкая абстракция над `flutter_webrtc`, за которой
/// прячется весь native/plugin-путь `RTCPeerConnection` / `getUserMedia`.
///
/// **Зачем интерфейс.** `flutter_webrtc` требует MethodChannel /
/// нативного `libwebrtc` (windows) или dart2js-plugin (web) — в
/// `flutter test` (pure Dart VM) он недоступен. Весь [CallController]
/// работает поверх этих интерфейсов, поэтому unit-тесты подсовывают
/// in-memory fake ([FakeWebRtcAdapter] в тестах) без поднятия плагина.
/// Production-обвязка (единственное место, где реально импортируется
/// `package:flutter_webrtc`) — [RealWebRtcAdapter] в
/// `webrtc_adapter_real.dart`.
///
/// Сигнатуры зеркалят `flutter_webrtc` в минимально-необходимом объёме
/// для аудио 1:1 (MVP): создать pc с ICE-серверами, взять микрофон,
/// offer/answer, trickle ICE, mute (toggle track.enabled), teardown.
/// Видео / data-channel / статистика — вне scope MVP.
library;

/// Роль SDP-дескриптора — offer (исходящий invite) или answer
/// (входящий accept). Зеркалит `RTCSessionDescription.type`.
enum SdpType { offer, answer }

/// SDP offer/answer в транспортно-нейтральном виде. `CallController`
/// сериализует `sdp` в `sendCallEvent(sdp: ...)` и восстанавливает из
/// входящего `MessengerEvent.callSdp`.
class RtcSdp {
  const RtcSdp({required this.type, required this.sdp});
  final SdpType type;
  final String sdp;
}

/// Один ICE-кандидат в транспортно-нейтральном виде. Совпадает по
/// форме с `CallIceCandidate` (Serverpod DTO) и `RTCIceCandidate`
/// (flutter_webrtc). Пустой [candidate] допустим — сигнал
/// end-of-candidates.
class RtcIce {
  const RtcIce({required this.candidate, this.sdpMid, this.sdpMLineIndex});
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;
}

/// Состояние P2P-соединения — подмножество `RTCPeerConnectionState`,
/// достаточное для UI-статуса звонка (connecting / connected /
/// closed-or-failed).
enum RtcConnState {
  /// `new` / `connecting` — ICE/DTLS negotiation в процессе.
  connecting,

  /// `connected` — media-канал поднят, аудио течёт P2P.
  connected,

  /// `disconnected` — временная потеря связи (может восстановиться).
  disconnected,

  /// `failed` — negotiation окончательно провалилась.
  failed,

  /// `closed` — pc закрыт (локально или после hangup).
  closed,
}

/// Обёртка над `MediaStream` (набор audio-треков локального
/// микрофона). `CallController` держит её, чтобы mute-ить
/// (toggle [MediaAudioTrack.enabled]) и stop-ать на hangup.
abstract class RtcMediaStream {
  /// Все audio-треки стрима (MVP — обычно один).
  List<MediaAudioTrack> get audioTracks;

  /// Остановить и освободить все треки (release микрофона).
  Future<void> dispose();
}

/// Один audio-трек. `enabled=false` = mute (трек продолжает
/// существовать в pc, но шлёт тишину — стандартный WebRTC-mute).
abstract class MediaAudioTrack {
  bool get enabled;
  set enabled(bool value);
}

/// Абстракция `RTCPeerConnection`. Создаётся через
/// [WebRtcAdapter.createPeerConnection]; закрывается через [close].
abstract class RtcPeerConnection {
  /// Callback на каждый локально-сгенерированный ICE-кандидат (trickle).
  /// `CallController` шлёт его в `sendCallEvent(candidates)`.
  set onIceCandidate(void Function(RtcIce candidate)? cb);

  /// Callback на смену состояния соединения. `CallController`
  /// маппит `connected` → `CallState.connected`, `failed`/`closed` →
  /// `CallState.ended`.
  set onConnectionState(void Function(RtcConnState state)? cb);

  /// Callback на приход удалённого media-трека (аудио собеседника).
  /// На MVP используется только как сигнал «media реально течёт» —
  /// сам рендеринг аудио делает нативный слой автоматически.
  set onRemoteTrack(void Function()? cb);

  /// Добавить локальные audio-треки [stream] в pc (перед offer/answer).
  Future<void> addLocalStream(RtcMediaStream stream);

  /// `createOffer` → возвращает local SDP offer (ещё НЕ set-нутый).
  /// [iceRestart] — сгенерировать offer с новым ICE ufrag/pwd (ICE restart
  /// при смене сети / потере соединения). Через флаг, а не отдельный метод,
  /// чтобы путь offer-а был единым.
  Future<RtcSdp> createOffer({bool iceRestart = false});

  /// `createAnswer` → возвращает local SDP answer (ещё НЕ set-нутый).
  Future<RtcSdp> createAnswer();

  /// `setLocalDescription`.
  Future<void> setLocalDescription(RtcSdp sdp);

  /// `setRemoteDescription`.
  Future<void> setRemoteDescription(RtcSdp sdp);

  /// `addCandidate` — добавить входящий trickle-кандидат.
  Future<void> addIceCandidate(RtcIce candidate);

  /// Закрыть соединение (teardown).
  Future<void> close();
}

/// Ошибка «микрофон запрещён» — маппится `CallController`-ом в
/// `CallEndReason.micDenied`. Real-адаптер бросает её, когда
/// `getUserMedia` кинул permission-denied (web prompt отклонён,
/// mobile permission denied, ОС-блок).
class MicPermissionDeniedException implements Exception {
  const MicPermissionDeniedException([this.cause]);
  final Object? cause;
  @override
  String toString() =>
      'MicPermissionDeniedException(доступ к микрофону запрещён: $cause)';
}

/// Точка входа абстракции. Один инстанс на runtime; `CallController`
/// получает его в конструкторе. Production — [RealWebRtcAdapter],
/// тесты — fake.
abstract class WebRtcAdapter {
  /// Создать `RTCPeerConnection` с заданным списком ICE-серверов.
  /// [iceServers] — уже в формате `flutter_webrtc`
  /// (`[{'urls': [...], 'username': ..., 'credential': ...}]`).
  Future<RtcPeerConnection> createPeerConnection(
    List<Map<String, dynamic>> iceServers,
  );

  /// `getUserMedia({audio:true, video:false})` — взять микрофон.
  /// Бросает [MicPermissionDeniedException], если доступ запрещён.
  Future<RtcMediaStream> getUserMediaAudio();

  /// Переключить маршрут вывода звука звонка: `true` — громкая связь
  /// (внешний динамик), `false` — разговорный динамик («к уху»).
  ///
  /// **Зачем это вообще есть.** Ни iOS, ни Android не отдают звук звонка
  /// в громкий динамик сами: iOS с `playAndRecord`+`voiceChat` и Android
  /// с `MODE_IN_COMMUNICATION` маршрутизируют в РАЗГОВОРНЫЙ динамик
  /// (тихий, у верхней кромки, слышен только прижатым к уху). Телефон,
  /// лежащий на столе, при полностью исправном медиа-тракте звучит
  /// «никак» — это неотличимо от «звонок соединился, но звука нет».
  /// Поэтому маршрут задаём ЯВНО, а не полагаемся на умолчание платформы.
  ///
  /// Best-effort: на платформах без маршрутизации (desktop/web) — no-op;
  /// ошибка маршрутизации не должна ронять сам звонок.
  Future<void> setSpeakerphone(bool enabled);
}
