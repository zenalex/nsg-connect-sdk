import 'package:flutter/foundation.dart';

/// **TASK46 (SDK)**: причина завершения звонка ([CallEnded.reason]).
/// UI показывает соответствующий текст («Звонок завершён» / «Отклонён» /
/// «Нет доступа к микрофону» / ...).
enum CallEndReason {
  /// Локальный пользователь положил трубку (наш hangup).
  localHangup,

  /// Собеседник положил трубку / отклонил (входящий hangup/reject).
  remoteHangup,

  /// Входящий звонок отклонён локально (мы нажали decline).
  declined,

  /// `getUserMedia` не дал доступ к микрофону (denied / нет устройства).
  micDenied,

  /// P2P-соединение провалилось (ICE/DTLS failed) или pc закрылся с ошибкой.
  failed,

  /// **issue #5**: собеседник недоступен — сервер отклонил `invite`
  /// ([PeerUnavailableException]), потому что у callee нет способа принять
  /// звонок (не активирован / нет устройства и офлайн). Отдельная причина
  /// от [failed]: это не сбой соединения, а «звонить некому» — UI
  /// показывает «Пользователь недоступен» сразу, без фазы «идёт вызов».
  peerUnavailable,

  /// Invite протух (никто не ответил за `lifetime`) — на MVP таймаут звонка.
  timeout,

  /// Проигранный glare — параллельный звонок с меньшим callId выиграл,
  /// этот свёрнут (MSC2746). Не ошибка.
  glareLost,

  /// **Multi-device**: на входящий звонок ответило ДРУГОЕ наше устройство
  /// (caller прислал `select_answer` с чужим partyId) — гасим свой ринг.
  /// Не ошибка: звонок жив, просто на другом устройстве.
  answeredElsewhere,
}

/// State machine звонка 1:1 (TASK46 §UI/§1). Единый источник состояния
/// для UI-биндинга (`CallController` = ChangeNotifier). Sealed — UI делает
/// exhaustive switch.
@immutable
sealed class CallState {
  const CallState();
}

/// Нет активного звонка. Начальное и конечное-переходное состояние.
class CallIdle extends CallState {
  const CallIdle();

  @override
  bool operator ==(Object other) => other is CallIdle;
  @override
  int get hashCode => (CallIdle).hashCode;
}

/// Исходящий звонок: offer отправлен, ждём answer от собеседника
/// («Звоним…»).
class CallOutgoingRinging extends CallState {
  const CallOutgoingRinging({
    required this.callId,
    required this.roomId,
    required this.peerMessengerUserId,
    this.peerDisplayName,
    this.reachedPeer = false,
  });

  final String callId;
  final int roomId;

  /// messengerUserId собеседника (для показа имени/аватара в UI).
  final int? peerMessengerUserId;

  /// **TASK46**: имя собеседника, известное инициатору звонка в момент
  /// вызова (из participants чата). Overlay показывает его напрямую, не
  /// завися от host-resolver/кэша — «звоним <имя>» вместо «Собеседник».
  final String? peerDisplayName;

  /// **Ringback (обратный сигнал каллеру)**: доставлен ли invite. Две
  /// различимые стадии исходящего звонка ДО ответа — по ним overlay
  /// выбирает тон «гудка» (см. `call_ringback_player.dart`):
  ///
  ///   * `false` — стадия 1 «дозвон до сервера»: от `startCall` до
  ///     успешного `sendCallEvent(invite)` (TURN-креды, микрофон,
  ///     createOffer, RPC round-trip). Проигрываем «connecting»-блип.
  ///   * `true`  — стадия 2 «звонит на устройстве»: invite успешно
  ///     доставлен серверу (сервер маршрутизирует его на устройство
  ///     собеседника через /sync + VoIP-push). Явного «callee ringing»
  ///     сигнала в протоколе нет — успешная доставка invite это лучшая
  ///     доступная аппроксимация «дошло до собеседника». Проигрываем
  ///     ringback-гудок в петле до answer/connected/ended.
  final bool reachedPeer;

  @override
  bool operator ==(Object other) =>
      other is CallOutgoingRinging &&
      other.callId == callId &&
      other.roomId == roomId &&
      other.peerMessengerUserId == peerMessengerUserId &&
      other.peerDisplayName == peerDisplayName &&
      other.reachedPeer == reachedPeer;
  @override
  int get hashCode => Object.hash(
    callId,
    roomId,
    peerMessengerUserId,
    peerDisplayName,
    reachedPeer,
  );
}

/// Входящий звонок: получили invite, ждём accept/decline от локального
/// пользователя (overlay входящего звонка).
class CallIncomingRinging extends CallState {
  const CallIncomingRinging({
    required this.callId,
    required this.roomId,
    required this.callerMatrixUserId,
  });

  final String callId;
  final int roomId;

  /// Matrix user id звонящего (Matrix `sender` из invite). UI резолвит
  /// имя/аватар через свой список участников комнаты.
  final String? callerMatrixUserId;

  @override
  bool operator ==(Object other) =>
      other is CallIncomingRinging &&
      other.callId == callId &&
      other.roomId == roomId &&
      other.callerMatrixUserId == callerMatrixUserId;
  @override
  int get hashCode => Object.hash(callId, roomId, callerMatrixUserId);
}

/// Устанавливаем P2P-соединение (answer отправлен/получен, идёт
/// ICE/DTLS negotiation). UI показывает «Соединение…».
class CallConnecting extends CallState {
  const CallConnecting({required this.callId, required this.roomId});

  final String callId;
  final int roomId;

  @override
  bool operator ==(Object other) =>
      other is CallConnecting &&
      other.callId == callId &&
      other.roomId == roomId;
  @override
  int get hashCode => Object.hash(callId, roomId);
}

/// Соединение установлено, аудио течёт P2P. [startedAt] — момент
/// перехода в connected (UI считает таймер длительности от него).
/// [muted] — заглушён ли локальный микрофон. [speakerOn] — играет ли звук
/// в громкий динамик (иначе — в разговорный, «к уху»).
class CallConnected extends CallState {
  const CallConnected({
    required this.callId,
    required this.roomId,
    required this.startedAt,
    required this.muted,
    this.speakerOn = false,
  });

  final String callId;
  final int roomId;
  final DateTime startedAt;
  final bool muted;

  /// Громкая связь включена. Дефолт — `false`: звонок стартует в разговорный
  /// динамик («к уху»), как в обычной телефонии. Источник правды —
  /// `CallController._speakerOn`, он всегда передаёт значение явно; дефолт
  /// здесь держим совпадающим с ним, чтобы не разъезжались.
  final bool speakerOn;

  CallConnected copyWith({bool? muted, bool? speakerOn}) => CallConnected(
    callId: callId,
    roomId: roomId,
    startedAt: startedAt,
    muted: muted ?? this.muted,
    speakerOn: speakerOn ?? this.speakerOn,
  );

  @override
  bool operator ==(Object other) =>
      other is CallConnected &&
      other.callId == callId &&
      other.roomId == roomId &&
      other.startedAt == startedAt &&
      other.muted == muted &&
      other.speakerOn == speakerOn;
  @override
  int get hashCode =>
      Object.hash(callId, roomId, startedAt, muted, speakerOn);
}

/// Звонок завершён. [reason] — почему. UI показывает финальный статус,
/// затем закрывает overlay (обычно controller сам вернётся в [CallIdle]
/// на следующем звонке).
class CallEnded extends CallState {
  const CallEnded({required this.reason, this.callId});

  final CallEndReason reason;
  final String? callId;

  @override
  bool operator ==(Object other) =>
      other is CallEnded && other.reason == reason && other.callId == callId;
  @override
  int get hashCode => Object.hash(reason, callId);
}
