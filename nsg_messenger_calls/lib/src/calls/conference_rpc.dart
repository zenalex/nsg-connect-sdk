import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart' show MessengerCallsContext;

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

  /// **TASK80 итерация 1**: захватить роль докладчика (демонстрация
  /// экрана). Возвращает снапшот с заполненными `screenSharing*`.
  /// Бросает `ScreenShareBusyException`, если показывает кто-то другой
  /// (арбитраж — на сервере: unique-индекс режет гонку двух
  /// одновременных нажатий, клиентский арбитраж этого не умеет).
  /// Идемпотентен для СВОЕГО показа.
  Future<ConferenceState> startScreenShare({
    required int roomId,
    required String partyId,
  });

  /// **TASK80 итерация 1**: остановить свой показ (идемпотентно).
  Future<void> stopScreenShare({required int roomId});
}

/// Production-wrapper над `Client.messenger.*`. Каждый RPC обёрнут в
/// [withAuthRetry] (self-heal на token-rotation), как [ClientCallRpc].
class ClientConferenceRpc implements ConferenceRpc {
  ClientConferenceRpc(this._context);
  final MessengerCallsContext _context;
  Client get _client => _context.client;

  @override
  Future<ConferenceState> joinConference({
    required int roomId,
    required String partyId,
  }) => _context.authenticated(
    () => _client.messenger.joinConference(roomId: roomId, partyId: partyId),
  );

  @override
  Future<void> leaveConference({required int roomId}) => _context.authenticated(
    () => _client.messenger.leaveConference(roomId: roomId),
  );

  @override
  Future<ConferenceState?> getConference({required int roomId}) => _context
      .authenticated(() => _client.messenger.getConference(roomId: roomId));

  @override
  Future<ConferenceState> startScreenShare({
    required int roomId,
    required String partyId,
  }) => _context.authenticated(
    () => _client.messenger.startScreenShare(roomId: roomId, partyId: partyId),
  );

  @override
  Future<void> stopScreenShare({required int roomId}) => _context.authenticated(
    () => _client.messenger.stopScreenShare(roomId: roomId),
  );
}
