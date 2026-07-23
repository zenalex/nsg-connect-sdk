import 'package:nsg_connect_client/nsg_connect_client.dart';

/// **TASK84 итерация 1**: состояние одной вкладки экрана «Задачи». Зеркалит
/// `MyTicketsState` — sealed-переключение loading / ready / unavailable.
@immutable
sealed class MyTasksState {
  const MyTasksState();
}

/// Первичная загрузка (listMyTasks ещё не вернулся).
class MyTasksLoading extends MyTasksState {
  const MyTasksLoading();
}

/// Список задач загружен (может быть пустым).
class MyTasksReady extends MyTasksState {
  const MyTasksReady({required this.tasks});

  final List<TicketView> tasks;
}

/// Ошибка загрузки — UI показывает retry.
class MyTasksUnavailable extends MyTasksState {
  const MyTasksUnavailable({required this.error});

  final Object error;
}
