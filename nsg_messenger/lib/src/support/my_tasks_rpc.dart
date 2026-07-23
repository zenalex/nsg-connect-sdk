import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK84 итерация 1**: значения фильтра экрана «Задачи». Зеркалят серверный
/// contract (`TicketService.filterAll` / `filterInitiator`) — держим копию в
/// SDK, потому что серверный `TicketService` в клиентский пакет не
/// экспортируется. Строки ДОЛЖНЫ совпадать с сервером байт-в-байт (сервер
/// неизвестное значение трактует как `all` — forward-compat).
const String tasksFilterAll = 'all';
const String tasksFilterInitiator = 'initiator';

/// **TASK84 итерация 1**: RPC-абстракция экрана «Задачи». Отдельный интерфейс
/// (а не прямой вызов client) — чтобы [MyTasksController] был unit-тестируем с
/// hand-written fake, как [MyTicketsRpc]/[ObjectRoomsCatalogRpc].
///
/// [filter] — строковый contract сервера: `all` (все задачи моих активных
/// комнат) | `initiator` (заведённые мной). Строкой, а не enum-ом — контракт
/// на wire задаёт сервер (`TicketService.filterAll/filterInitiator`), и клиент
/// не тащит дубль-enum, который придётся синхронизировать.
abstract class MyTasksRpc {
  /// Задачи из моих комнат под фильтр [filter], свежие сверху.
  Future<List<TicketView>> listMyTasks(String filter);
}

/// Продакшн-реализация: generated Serverpod-client через `withAuthRetry`
/// (self-heal на token-rotation, как в остальном SDK).
class ClientMyTasksRpc implements MyTasksRpc {
  ClientMyTasksRpc(this._client);

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<List<TicketView>> listMyTasks(String filter) => withAuthRetry(
    () => _client.messenger.listMyTasks(filter: filter),
    _session,
  );
}
