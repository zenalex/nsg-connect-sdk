import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'my_tasks_rpc.dart';

/// **TASK90**: состояние списка задач ОДНОЙ комнаты (тап по иконке в шапке).
///
/// Отдельно от `MyTasksState` не ради симметрии, а потому что сущность
/// другая: там `TicketView` — обращения, здесь `RoomTaskView` — задачи. До
/// TASK90 комнатный список брали из обращений, а у support-комнаты обращение
/// одно (`UNIQUE roomId`), и список сворачивался в одну строку при любом
/// числе задач — «в шапке 10, внутри одна».
@immutable
sealed class RoomTasksState {
  const RoomTasksState();
}

class RoomTasksLoading extends RoomTasksState {
  const RoomTasksLoading();
}

class RoomTasksReady extends RoomTasksState {
  const RoomTasksReady({required this.tasks});

  final List<RoomTaskView> tasks;
}

class RoomTasksUnavailable extends RoomTasksState {
  const RoomTasksUnavailable({required this.error});

  final Object error;
}

/// Контроллер списка задач комнаты. `ChangeNotifier` + sealed state — как
/// [MyTasksController]; отдельный класс, потому что тип строки другой.
class RoomTasksController extends ChangeNotifier {
  RoomTasksController({required MyTasksRpc rpc, required this.roomId})
    : _rpc = rpc;

  final MyTasksRpc _rpc;
  final int roomId;

  RoomTasksState _state = const RoomTasksLoading();
  RoomTasksState get state => _state;

  bool _disposed = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      _emit(RoomTasksReady(tasks: await _rpc.listRoomTasks(roomId)));
    } catch (e) {
      _emit(RoomTasksUnavailable(error: e));
    }
  }

  void _emit(RoomTasksState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
