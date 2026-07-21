import 'dart:async';

import 'package:flutter/foundation.dart';

import 'my_tickets_rpc.dart';
import 'my_tickets_state.dart';

/// **TASK57 фаза 1**: контроллер экрана «Мои обращения». `ChangeNotifier` +
/// sealed state, hand-written fake RPC в тестах (зеркалит
/// `ObjectRoomsCatalogController`).
class MyTicketsController extends ChangeNotifier {
  MyTicketsController({required MyTicketsRpc rpc}) : _rpc = rpc;

  final MyTicketsRpc _rpc;

  MyTicketsState _state = const MyTicketsLoading();
  MyTicketsState get state => _state;

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
      final tickets = await _rpc.listMyTickets();
      _emit(MyTicketsReady(tickets: tickets));
    } catch (e) {
      _emit(MyTicketsUnavailable(error: e));
    }
  }

  void _emit(MyTicketsState s) {
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
