import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK57 фаза 1**: RPC-абстракция «Мои обращения». Отдельный интерфейс (а не
/// прямой вызов client) — чтобы [MyTicketsController] был unit-тестируем с
/// hand-written fake (как `ObjectRoomsCatalogRpc`).
abstract class MyTicketsRpc {
  /// Тикеты текущего пользователя, свежие сверху.
  Future<List<TicketView>> listMyTickets();
}

/// Продакшн-реализация: generated Serverpod-client через `withAuthRetry`
/// (self-heal на token-rotation, как в остальном SDK).
class ClientMyTicketsRpc implements MyTicketsRpc {
  ClientMyTicketsRpc(this._client);

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<List<TicketView>> listMyTickets() =>
      withAuthRetry(() => _client.messenger.listMyTickets(), _session);
}
