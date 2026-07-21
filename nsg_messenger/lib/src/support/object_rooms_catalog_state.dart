import 'package:nsg_connect_client/nsg_connect_client.dart';

/// **TASK45 фаза 1 п.5**: состояние экрана каталога объектовых комнат.
@immutable
sealed class ObjectRoomsCatalogState {
  const ObjectRoomsCatalogState();
}

/// Первичная загрузка (listProductObjectRooms ещё не вернулся).
class ObjectRoomsCatalogLoading extends ObjectRoomsCatalogState {
  const ObjectRoomsCatalogLoading();
}

/// Каталог загружен. `busyRoomId` — комната, для которой идёт join/leave
/// (UI блокирует её строку).
class ObjectRoomsCatalogReady extends ObjectRoomsCatalogState {
  const ObjectRoomsCatalogReady({required this.rooms, this.busyRoomId});

  final List<ProductObjectRoom> rooms;
  final int? busyRoomId;

  ObjectRoomsCatalogReady copyWith({
    List<ProductObjectRoom>? rooms,
    int? busyRoomId,
    bool clearBusy = false,
  }) => ObjectRoomsCatalogReady(
    rooms: rooms ?? this.rooms,
    busyRoomId: clearBusy ? null : (busyRoomId ?? this.busyRoomId),
  );
}

/// Каталог недоступен — caller не член команды
/// ([NotSupportTeamMemberException]) ИЛИ иная ошибка. По [unavailable]
/// host-app решает: скрыть вход (не член) vs показать retry.
class ObjectRoomsCatalogUnavailable extends ObjectRoomsCatalogState {
  const ObjectRoomsCatalogUnavailable({
    required this.error,
    required this.unavailable,
  });

  final Object error;
  final bool unavailable;
}
