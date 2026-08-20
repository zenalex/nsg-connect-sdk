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
  ///
  /// **TASK88**: [roomId] опционально сужает выборку до ОДНОЙ комнаты (иконка
  /// задач в шапке чата → отфильтрованный список). null → все мои комнаты.
  Future<List<TicketView>> listMyTasks(String filter, {int? roomId});

  /// **TASK90**: задачи ОДНОЙ комнаты — то же множество, что считает бейдж в
  /// шапке чата.
  ///
  /// Отдельный вход, а не `listMyTasks(roomId:)`, потому что сущность другая:
  /// там обращения (`TicketView`), здесь задачи (`RoomTaskView`). У
  /// support-комнаты обращение ровно одно, поэтому прежний путь при любом
  /// числе задач отдавал одну строку.
  Future<List<RoomTaskView>> listRoomTasks(int roomId);
}

/// Продакшн-реализация: generated Serverpod-client через `withAuthRetry`
/// (self-heal на token-rotation, как в остальном SDK).
class ClientMyTasksRpc implements MyTasksRpc {
  ClientMyTasksRpc(this._client);

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<List<TicketView>> listMyTasks(String filter, {int? roomId}) =>
      withAuthRetry(
        () => _client.messenger.listMyTasks(filter: filter, roomId: roomId),
        _session,
      );

  @override
  Future<List<RoomTaskView>> listRoomTasks(int roomId) => withAuthRetry(
    () => _client.messenger.listRoomTasks(roomId: roomId),
    _session,
  );
}
