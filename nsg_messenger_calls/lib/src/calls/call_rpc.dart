import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart' show MessengerCallsContext;

/// **TASK46 (SDK)**: абстракция серверных RPC, нужных [CallController]
/// (`sendCallEvent` + `getTurnCredentials`). Тот же pattern, что
/// [MessagesRpc] — production-wiring через `client.messenger.*`, тесты
/// подменяют in-memory fake-ом.
///
/// Сигнатуры зеркалят Serverpod-сгенерированный `Client.messenger`
/// (ветка `feature/voice-calls-server`): если серверный API поменяется,
/// сначала ломается production wiring (compile-time), тесты стабильны.
abstract class CallRpc {
  /// Отправить `m.call.*` событие в комнату через server-proxy (сервер
  /// расшифровывает Matrix-токен юзера и делает PUT в комнату; SDK
  /// Matrix-токена не имеет — TASK46 §1 инвариант). Тип события задаёт
  /// [eventType]; [sdp] для invite/answer, [candidates] для trickle ICE,
  /// [hangupReason] для hangup, [selectedPartyId] для select_answer,
  /// [sdpType] (`offer`/`answer`) — роль SDP в negotiate (ICE restart).
  Future<void> sendCallEvent({
    required int roomId,
    required CallEventType eventType,
    required String callId,
    required String partyId,
    String? sdp,
    List<CallIceCandidate>? candidates,
    String? hangupReason,
    String? selectedPartyId,
    String? sdpType,
  });

  /// Получить эфемерные TURN/STUN креды (TASK46 §2.1). Пустой
  /// `urls` = TURN не сконфигурирован на сервере → используем только
  /// публичные STUN.
  Future<TurnCredentials> getTurnCredentials();
}

/// Production-wrapper над `Client.messenger.*`. Каждый RPC обёрнут в
/// [withAuthRetry] (self-heal на token-rotation), как в [ClientMessagesRpc].
class ClientCallRpc implements CallRpc {
  ClientCallRpc(this._context);
  final MessengerCallsContext _context;
  Client get _client => _context.client;

  @override
  Future<void> sendCallEvent({
    required int roomId,
    required CallEventType eventType,
    required String callId,
    required String partyId,
    String? sdp,
    List<CallIceCandidate>? candidates,
    String? hangupReason,
    String? selectedPartyId,
    String? sdpType,
  }) => _context.authenticated(
    () => _client.messenger.sendCallEvent(
      roomId: roomId,
      eventType: eventType,
      callId: callId,
      partyId: partyId,
      sdp: sdp,
      candidates: candidates,
      hangupReason: hangupReason,
      selectedPartyId: selectedPartyId,
      sdpType: sdpType,
    ),
  );

  @override
  Future<TurnCredentials> getTurnCredentials() =>
      _context.authenticated(() => _client.messenger.getTurnCredentials());
}
