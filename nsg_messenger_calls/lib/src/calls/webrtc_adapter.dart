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
///
/// **TASK80 итерация 1** добавила сюда видео РОВНО в объёме демонстрации
/// экрана: захват ([WebRtcAdapter.getDisplayMedia]), добавление/снятие
/// видео-трека в живом pc ([RtcPeerConnection.addVideoTrack]) и рендер
/// входящего видео ([RtcVideoRenderer]). Камеры по-прежнему нет.
library;

import 'package:flutter/widgets.dart' show BoxFit, Widget, immutable;

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

  /// **TASK80**: видео-треки стрима. Для микрофонного стрима — пусто;
  /// для стрима демонстрации экрана — один трек.
  List<MediaVideoTrack> get videoTracks;

  /// Остановить и освободить все треки (release микрофона).
  Future<void> dispose();
}

/// Один audio-трек. `enabled=false` = mute (трек продолжает
/// существовать в pc, но шлёт тишину — стандартный WebRTC-mute).
abstract class MediaAudioTrack {
  bool get enabled;
  set enabled(bool value);
}

/// **TASK80**: один видео-трек (у нас — только демонстрация экрана).
abstract class MediaVideoTrack {
  bool get enabled;
  set enabled(bool value);

  /// **Приватность, п.5 спеки**: захват прекращён ВНЕ нашего UI —
  /// пользователь нажал системную кнопку «Прекратить показ» (плашка
  /// браузера / панель ОС / закрылось расшаренное окно). Без этого
  /// хука UI остался бы врать «показ идёт», а докладчик считал бы, что
  /// его всё ещё видят.
  set onEnded(void Function()? cb);
}

/// **TASK80**: рамки качества демонстрации экрана. Mesh множит
/// исходящий поток на число собеседников (при 4 участниках — ×3),
/// поэтому cap здесь не «настройка на потом», а обязательное условие
/// работоспособности (см. TASK80 «Главный вопрос — пропускная
/// способность»). Значения — в [kScreenShareCaps].
@immutable
class ScreenShareCaps {
  const ScreenShareCaps({
    required this.maxWidth,
    required this.maxHeight,
    required this.maxFramerate,
    required this.maxBitrateBps,
  });

  final int maxWidth;
  final int maxHeight;
  final int maxFramerate;
  final int maxBitrateBps;

  /// Потолок битрейта в кбит/с — форма для SDP-строки `b=AS:`.
  int get maxBitrateKbps => (maxBitrateBps / 1000).round();
}

/// **Рамки демонстрации экрана итерации 1 — обязательные, не «настроим
/// потом».** Арифметика mesh: докладчик шлёт СВОЮ копию каждому, при 4
/// участниках это 3 исходящих потока. Со «свободным» видео (1–3 Мбит/с)
/// это до ~9 Мбит/с upstream — столько нет ни у кого из команды, а через
/// TURN-relay эти же мегабиты множатся ещё раз. Отсюда цифры:
///
///   * **720p** — потолок разрешения. Текст/код на 1080p→720p читаемы,
///     а полоса падает вдвое.
///   * **15 fps** — демонстрация экрана не кино: это верх «плавности»,
///     который нам нужен. Деградация при плохом канале снижает fps
///     дальше (до ~5), но НЕ разрешение — см. ниже.
///   * **800 кбит/с на поток** → при 4 участниках ~2.4 Мбит/с upstream
///     вместо ~9. Это то, что реально уезжает с ноутбука на Wi-Fi.
///   * **degradation preference = maintain-resolution** — это ровно то,
///     во что libwebrtc транслирует `contentHint: 'detail'`: при
///     нехватке полосы жертвуем ЧАСТОТОЙ КАДРОВ, а не чёткостью.
///     Для текста/кода замыленный кадр бесполезен, а «слайд-шоу» —
///     вполне рабочий режим. (Сам `contentHint` в API flutter_webrtc
///     1.5.2 не выведен — см. `webrtc_adapter_real.dart`.)
const ScreenShareCaps kScreenShareCaps = ScreenShareCaps(
  maxWidth: 1280,
  maxHeight: 720,
  maxFramerate: 15,
  maxBitrateBps: 800000,
);

/// Экран/окно, доступное для захвата ([WebRtcAdapter.listScreenShareSources]).
@immutable
class ScreenShareSource {
  const ScreenShareSource({
    required this.id,
    required this.name,
    required this.isWindow,
  });

  /// Платформенный id источника (уходит в `video.deviceId.exact`).
  final String id;

  /// Человекочитаемое имя: заголовок окна либо «Screen 1».
  final String name;

  /// true — окно приложения, false — экран целиком.
  final bool isWindow;
}

/// Отправитель видео-трека в конкретном pc — ручка, за которую трек
/// снимают ([RtcPeerConnection.removeVideoSender]) и через которую
/// накладывают рамки качества.
abstract class RtcVideoSender {
  /// Применить [caps] к этому отправителю (encoding parameters:
  /// maxBitrate/maxFramerate + degradation preference). Best-effort:
  /// платформа может не поддержать часть параметров — страховкой
  /// работает SDP-cap (`b=AS:` на видео-m-line, см. `sdp_tuning.dart`).
  Future<void> applyScreenShareCaps(ScreenShareCaps caps);
}

/// Рендерер видео-трека. Абстракция нужна ровно затем же, зачем весь
/// этот файл: `RTCVideoRenderer`/`RTCVideoView` требуют нативного
/// плагина, а виджет-тесты оверлея конференции гоняются без него.
abstract class RtcVideoRenderer {
  /// Завести текстуру/элемент. Звать до первого [buildView].
  Future<void> initialize();

  /// Привязать поток (null — отвязать, картинка гаснет).
  set srcObject(RtcMediaStream? stream);

  /// Виджет с картинкой текущего [srcObject].
  Widget buildView({BoxFit fit = BoxFit.contain});

  Future<void> dispose();
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

  /// **TASK80**: callback на входящий УДАЛЁННЫЙ видео-поток (собеседник
  /// начал показ экрана). Отдаёт поток целиком — его скармливают
  /// [RtcVideoRenderer.srcObject].
  set onRemoteVideoStream(void Function(RtcMediaStream stream)? cb);

  /// Добавить локальные audio-треки [stream] в pc (перед offer/answer).
  Future<void> addLocalStream(RtcMediaStream stream);

  /// **TASK80**: добавить видео-трек(и) [stream] (демонстрация экрана) в
  /// УЖЕ ЖИВОЙ pc. Возвращает ручку отправителя (null — в стриме нет
  /// видео). После этого сессию надо переустановить через negotiate:
  /// новый трек = новая m-line в SDP.
  Future<RtcVideoSender?> addVideoTrack(RtcMediaStream stream);

  /// **TASK80**: снять ранее добавленный видео-трек (конец показа).
  /// Тоже требует negotiate.
  Future<void> removeVideoSender(RtcVideoSender sender);

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

  // ── TASK80: демонстрация экрана ──────────────────────────────────

  /// **Умеет ли эта платформа ЗАХВАТЫВАТЬ экран.** Смотреть чужой показ
  /// умеют все (входящий видео-трек рендерится где угодно), делиться —
  /// только desktop (Windows/macOS/Linux) и web: на мобильных захват
  /// требует Broadcast Upload Extension (iOS) / MediaProjection +
  /// foreground-service (Android) — отдельная нативная работа, вне
  /// итерации 1. UI обязан по этому флагу СКРЫВАТЬ кнопку, а не
  /// показывать неработающую (DoD: «не нажал — ничего»).
  bool get supportsScreenShare;

  /// **Нужен ли НАШ список источников.** Браузер по `getDisplayMedia`
  /// сам показывает системный диалог выбора экрана/окна — своего поверх
  /// него не рисуем (спека, п.5). На desktop-нативе flutter_webrtc 1.5.2
  /// системного диалога НЕ показывает вовсе: он требует, чтобы
  /// приложение перечислило источники (`getDesktopSources`) и передало
  /// `deviceId.exact`. Рисовать свой список там — не «поверх
  /// системного», а вместо отсутствующего.
  bool get screenShareNeedsSourcePicker;

  /// Перечислить экраны и окна, доступные для захвата. Валидно только
  /// когда [screenShareNeedsSourcePicker] == true.
  Future<List<ScreenShareSource>> listScreenShareSources();

  /// `getDisplayMedia` — взять поток захвата экрана/окна.
  /// [sourceId] обязателен на платформах с [screenShareNeedsSourcePicker];
  /// на web игнорируется (источник выбирает пользователь в системном
  /// диалоге браузера).
  ///
  /// Бросает [ScreenSharePermissionDeniedException] — в т.ч. когда
  /// пользователь просто закрыл системный диалог (отличить «отказ» от
  /// «передумал» платформы не дают, и для UI это одно и то же: показ не
  /// начался).
  Future<RtcMediaStream> getDisplayMedia({
    required ScreenShareCaps caps,
    String? sourceId,
  });

  /// Создать рендерер для показа видео-трека (свой превью или экран
  /// докладчика).
  Future<RtcVideoRenderer> createVideoRenderer();
}

/// **TASK80**: захват экрана не состоялся — пользователь отказал в
/// разрешении, закрыл системный диалог выбора источника, либо
/// платформа/источник недоступны. Для UI все эти случаи эквивалентны:
/// показ не начался, роль докладчика надо освободить.
class ScreenSharePermissionDeniedException implements Exception {
  const ScreenSharePermissionDeniedException([this.cause]);
  final Object? cause;
  @override
  String toString() =>
      'ScreenSharePermissionDeniedException(захват экрана не начат: $cause)';
}
