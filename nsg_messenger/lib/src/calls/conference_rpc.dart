import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK51 итерация 1 (SDK)**: абстракция серверных RPC членства
/// mesh-конференции для `ConferenceCallController` (`joinConference` /
/// `leaveConference` / `getConference`). Тот же pattern, что [CallRpc] —
/// production-wiring через `client.messenger.*`, тесты подменяют
/// in-memory fake-ом.
///
/// Сигналинг пар сюда НЕ входит: pairwise `m.call.*` идут через
/// существующий [CallRpc.sendCallEvent] (TASK46) как есть.
abstract class ConferenceRpc {
  /// Войти в конференцию комнаты (создав при отсутствии). Идемпотентен —
  /// повторный вызов = keepalive-heartbeat (контракт сервера: звать не
  /// реже, чем раз в TTL/2). Бросает `ConferenceFullException` при
  /// серверном лимите mesh, `RoomUnavailableException` — не участник.
  Future<ConferenceState> joinConference({
    required int roomId,
    required String partyId,
  });

  /// Штатный выход (идемпотентен; последний leave убивает конференцию).
  Future<void> leaveConference({required int roomId});

  /// Актуальный состав или null, если активной конференции нет.
  Future<ConferenceState?> getConference({required int roomId});
}

/// Production-wrapper над `Client.messenger.*`. Каждый RPC обёрнут в
/// [withAuthRetry] (self-heal на token-rotation), как [ClientCallRpc].
class ClientConferenceRpc implements ConferenceRpc {
  ClientConferenceRpc(this._client);
  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<ConferenceState> joinConference({
    required int roomId,
    required String partyId,
  }) => withAuthRetry(
    () => _client.messenger.joinConference(roomId: roomId, partyId: partyId),
    _session,
  );

  @override
  Future<void> leaveConference({required int roomId}) => withAuthRetry(
    () => _client.messenger.leaveConference(roomId: roomId),
    _session,
  );

  @override
  Future<ConferenceState?> getConference({required int roomId}) =>
      withAuthRetry(
        () => _client.messenger.getConference(roomId: roomId),
        _session,
      );
}
