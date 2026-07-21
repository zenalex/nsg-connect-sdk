import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'object_rooms_catalog_rpc.dart';
import 'object_rooms_catalog_state.dart';

/// **TASK45 фаза 1 п.5**: контроллер экрана каталога объектовых комнат.
/// Загружает список через [ObjectRoomsCatalogRpc.listProductObjectRooms];
/// не-член команды → [ObjectRoomsCatalogUnavailable]`(unavailable: true)`
/// (host-app скрывает вход в каталог). join/leave обновляют флаг
/// viewerIsMember у соответствующей строки.
///
/// Паттерн зеркалит `SupportTeamController`: `ChangeNotifier` + sealed
/// state, hand-written fake RPC в тестах.
class ObjectRoomsCatalogController extends ChangeNotifier {
  ObjectRoomsCatalogController({
    required ObjectRoomsCatalogRpc rpc,
    required this.productExternalKey,
  }) : _rpc = rpc;

  final ObjectRoomsCatalogRpc _rpc;
  final String productExternalKey;

  ObjectRoomsCatalogState _state = const ObjectRoomsCatalogLoading();
  ObjectRoomsCatalogState get state => _state;

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
      final rooms = await _rpc.listProductObjectRooms(
        productExternalKey: productExternalKey,
      );
      _emit(ObjectRoomsCatalogReady(rooms: rooms));
    } catch (e) {
      _emit(
        ObjectRoomsCatalogUnavailable(
          error: e,
          unavailable: e is NotSupportTeamMemberException,
        ),
      );
    }
  }

  /// Войти в комнату (член команды). Возвращает [RoomDetails] при успехе,
  /// `null` при ошибке (UI показывает snackbar). После успеха
  /// перезагружает каталог, чтобы флаг viewerIsMember стал true.
  Future<RoomDetails?> join(int roomId) async {
    final current = _state;
    if (current is! ObjectRoomsCatalogReady) return null;
    _emit(current.copyWith(busyRoomId: roomId));
    try {
      final details = await _rpc.joinProductRoom(roomId: roomId);
      await _load();
      return details;
    } catch (_) {
      _emit(current.copyWith(clearBusy: true));
      return null;
    }
  }

  /// Выйти из комнаты (вопрос решён). `true` при успехе. Перезагружает
  /// каталог (флаг viewerIsMember станет false).
  Future<bool> leave(int roomId) async {
    final current = _state;
    if (current is! ObjectRoomsCatalogReady) return false;
    _emit(current.copyWith(busyRoomId: roomId));
    try {
      await _rpc.leaveProductRoom(roomId: roomId);
      await _load();
      return true;
    } catch (_) {
      _emit(current.copyWith(clearBusy: true));
      return false;
    }
  }

  void _emit(ObjectRoomsCatalogState s) {
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
