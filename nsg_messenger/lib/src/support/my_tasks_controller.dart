import 'dart:async';

import 'package:flutter/foundation.dart';

import 'my_tasks_rpc.dart';
import 'my_tasks_state.dart';

/// **TASK84 итерация 1**: контроллер ОДНОЙ вкладки экрана «Задачи». По
/// контроллеру на фильтр (`all` / `initiator`) — так переключение вкладки
/// естественно тянет свою выборку, а не мультиплексирует одна на всех (проще
/// и тестируемо: fake-RPC видит, с каким [filter] пришли). `ChangeNotifier` +
/// sealed state — как `MyTicketsController`.
class MyTasksController extends ChangeNotifier {
  MyTasksController({required MyTasksRpc rpc, required this.filter})
    : _rpc = rpc;

  final MyTasksRpc _rpc;

  /// Фильтр этой вкладки — прокидывается в RPC как есть (`all` | `initiator`).
  final String filter;

  MyTasksState _state = const MyTasksLoading();
  MyTasksState get state => _state;

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
      final tasks = await _rpc.listMyTasks(filter);
      _emit(MyTasksReady(tasks: tasks));
    } catch (e) {
      _emit(MyTasksUnavailable(error: e));
    }
  }

  void _emit(MyTasksState s) {
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
