import 'package:flutter/foundation.dart';

/// **TASK51 итерация 1 (SDK)**: state machine группового (mesh) звонка.
/// Стиль и назначение — как у `call_state.dart` (TASK46): единый источник
/// состояния для UI-биндинга (`ConferenceCallController` = ChangeNotifier),
/// sealed — UI делает exhaustive switch.
///
/// Отличие от 1:1: вместо одного P2P-соединения — набор pairwise-сессий
/// (по одной на каждого участника), поэтому «connected» здесь размазан
/// по участникам: конференция [ConferenceActive] с первого момента после
/// join, а прогресс каждой пары виден в [ConferenceParticipantView.phase].

/// Состояние ОДНОЙ pairwise-сессии с участником (mesh-ребро).
enum ConferencePairPhase {
  /// Сессия устанавливается (invite/answer/ICE в процессе) либо временно
  /// потеряна (`disconnected` — WebRTC часто чинит сам). UI: спиннер /
  /// «соединение…» на плитке участника.
  connecting,

  /// P2P поднят, аудио с этим участником течёт.
  connected,

  /// Пара окончательно провалилась (после одного ретрая). Конференция
  /// живёт дальше без этого ребра (graceful degrade, §3A.3) — участник
  /// остаётся в ростере, но звука с ним нет. UI: пометка «нет связи».
  failed,
}

/// Участник конференции глазами UI: кто (messengerUserId — резолв
/// имени/аватара как в чате), его pairwise-идентичность (partyId) и
/// состояние ребра до него. Собственная запись тоже включена
/// ([isSelf] = true, phase всегда connected) — сетке участников нужна
/// и своя плитка.
@immutable
class ConferenceParticipantView {
  const ConferenceParticipantView({
    required this.messengerUserId,
    required this.partyId,
    required this.joinedAt,
    required this.phase,
    this.isSelf = false,
  });

  final int messengerUserId;

  /// Per-device идентификатор (тот же домен, что party_id TASK46) —
  /// сменился partyId → участник перезашёл с другого устройства/запуска.
  final String partyId;

  /// Момент входа в конференцию (серверное время) — стабильная сортировка
  /// сетки и tie-break-и конвенции «кто зовёт» (см. controller).
  final DateTime joinedAt;

  final ConferencePairPhase phase;
  final bool isSelf;

  @override
  bool operator ==(Object other) =>
      other is ConferenceParticipantView &&
      other.messengerUserId == messengerUserId &&
      other.partyId == partyId &&
      other.joinedAt == joinedAt &&
      other.phase == phase &&
      other.isSelf == isSelf;

  @override
  int get hashCode =>
      Object.hash(messengerUserId, partyId, joinedAt, phase, isSelf);
}

/// Причина завершения/срыва конференции ([ConferenceCallEnded.reason]).
enum ConferenceEndReason {
  /// Мы сами вышли ([ConferenceCallController.leave]).
  localLeave,

  /// Конференция умерла: `conferenceUpdated` с пустым составом (последний
  /// участник вышел / всех зачистило TTL) — полный teardown.
  conferenceDied,

  /// Сервер отказал: конференция полна (`ConferenceFullException`,
  /// серверный лимит mesh §3A.5). [ConferenceCallEnded.maxParticipants]
  /// — лимит для текста «конференция полна (до N участников)».
  conferenceFull,

  /// `getUserMedia` не дал микрофон — в конференцию без него не входим.
  micDenied,

  /// Невосстановимый сбой: join-RPC упал, либо heartbeat не проходит так
  /// долго, что сервер нас гарантированно выпилил как призрака.
  failed,

  /// **Multi-device**: наш же пользователь вошёл в эту конференцию с
  /// ДРУГОГО устройства (сервер держит одного юзера = одно устройство,
  /// last-join-wins) — наша сессия вытеснена. Не ошибка (аналог
  /// answeredElsewhere в 1:1).
  displaced,
}

/// State machine конференции. Sealed — UI делает exhaustive switch.
@immutable
sealed class ConferenceCallState {
  const ConferenceCallState();
}

/// Нет активной конференции. Начальное состояние; сюда же возвращаемся
/// после decline (отклонение входящей — тихий сброс, см. controller).
class ConferenceCallIdle extends ConferenceCallState {
  const ConferenceCallIdle();

  @override
  bool operator ==(Object other) => other is ConferenceCallIdle;
  @override
  int get hashCode => (ConferenceCallIdle).hashCode;
}

/// Входящая конференция «звонит» (ровно один раз на confId): в комнате
/// [roomId] идёт живая конференция [confId], нас в ней нет. UI — overlay
/// входящего группового звонка с кнопками accept/decline.
///
/// [callerMessengerUserId] — «кто зовёт» для заголовка: самый ранний
/// участник состава (инициатор де-факто); null, если ринг стартовал с
/// pairwise-invite и состав ещё не доехал (`conferenceUpdated` его
/// дозаполнит). [memberCount] — размер состава для подписи «N человек»
/// (0 = ещё неизвестен).
class ConferenceIncomingRinging extends ConferenceCallState {
  const ConferenceIncomingRinging({
    required this.roomId,
    required this.confId,
    this.callerMessengerUserId,
    this.memberCount = 0,
  });

  final int roomId;
  final String confId;
  final int? callerMessengerUserId;
  final int memberCount;

  @override
  bool operator ==(Object other) =>
      other is ConferenceIncomingRinging &&
      other.roomId == roomId &&
      other.confId == confId &&
      other.callerMessengerUserId == callerMessengerUserId &&
      other.memberCount == memberCount;
  @override
  int get hashCode =>
      Object.hash(roomId, confId, callerMessengerUserId, memberCount);
}

/// Входим в конференцию: `joinConference` RPC + микрофон в процессе.
/// UI: «Подключение…».
class ConferenceJoining extends ConferenceCallState {
  const ConferenceJoining({required this.roomId});

  final int roomId;

  @override
  bool operator ==(Object other) =>
      other is ConferenceJoining && other.roomId == roomId;
  @override
  int get hashCode => Object.hash((ConferenceJoining), roomId);
}

/// Мы в конференции. [participants] — полный состав (включая себя,
/// isSelf=true), отсортирован по joinedAt; состояние каждого ребра — в
/// [ConferenceParticipantView.phase]. [startedAt] — момент нашего входа
/// (UI-таймер длительности). [muted]/[speakerOn] — как в 1:1.
class ConferenceActive extends ConferenceCallState {
  const ConferenceActive({
    required this.roomId,
    required this.confId,
    required this.startedAt,
    required this.participants,
    required this.muted,
    this.speakerOn = false,
  });

  final int roomId;
  final String confId;
  final DateTime startedAt;
  final List<ConferenceParticipantView> participants;
  final bool muted;
  final bool speakerOn;

  @override
  bool operator ==(Object other) =>
      other is ConferenceActive &&
      other.roomId == roomId &&
      other.confId == confId &&
      other.startedAt == startedAt &&
      other.muted == muted &&
      other.speakerOn == speakerOn &&
      listEquals(other.participants, participants);
  @override
  int get hashCode => Object.hash(
    roomId,
    confId,
    startedAt,
    muted,
    speakerOn,
    Object.hashAll(participants),
  );
}

/// Конференция завершена (для нас). [reason] — почему; [maxParticipants]
/// заполнен только при [ConferenceEndReason.conferenceFull].
class ConferenceCallEnded extends ConferenceCallState {
  const ConferenceCallEnded({
    required this.reason,
    this.roomId,
    this.confId,
    this.maxParticipants,
  });

  final ConferenceEndReason reason;
  final int? roomId;
  final String? confId;
  final int? maxParticipants;

  @override
  bool operator ==(Object other) =>
      other is ConferenceCallEnded &&
      other.reason == reason &&
      other.roomId == roomId &&
      other.confId == confId &&
      other.maxParticipants == maxParticipants;
  @override
  int get hashCode => Object.hash(reason, roomId, confId, maxParticipants);
}
