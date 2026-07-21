/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'room_summary.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// Pagination wrapper для `MessengerEndpoint.listRoomsPage` (issue #46).
///
/// Раньше `listRooms` отдавал `List<RoomSummary>` без курсора, поэтому
/// клиент физически НЕ МОГ дойти дальше первой страницы: курсор строился
/// только внутри сервера и наружу не выходил. Из-за этого
/// `ChatsListController.loadMore()` так и остался заглушкой, а список
/// чатов молча обрезался на 50-й комнате — вместе с папками и бейджами,
/// которые считаются по загруженному набору.
///
/// `listRooms` намеренно оставлен как есть: клиенты в поле (1.0.70 и
/// старее) продолжают ходить в него. Новый метод — отдельный.
///
/// Не table — transient DTO.
abstract class RoomListPage implements _i1.SerializableModel {
  RoomListPage._({
    required this.rooms,
    this.nextCursor,
  });

  factory RoomListPage({
    required List<_i2.RoomSummary> rooms,
    String? nextCursor,
  }) = _RoomListPageImpl;

  factory RoomListPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomListPage(
      rooms: _i3.Protocol().deserialize<List<_i2.RoomSummary>>(
        jsonSerialization['rooms'],
      ),
      nextCursor: jsonSerialization['nextCursor'] as String?,
    );
  }

  /// Комнаты страницы, в порядке `lastMessageAt DESC, id DESC`
  /// (комнаты без сообщений идут первыми — так их кладёт Postgres при
  /// `ORDER BY ... DESC`).
  List<_i2.RoomSummary> rooms;

  /// Курсор для следующего `listRoomsPage(cursor: nextCursor)`.
  /// `null` — страница последняя, список кончился. Именно это условие
  /// завершает полный синк на клиенте; ориентироваться на
  /// `rooms.length < limit` нельзя — при общем числе, кратном limit,
  /// последняя страница полная.
  String? nextCursor;

  /// Returns a shallow copy of this [RoomListPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomListPage copyWith({
    List<_i2.RoomSummary>? rooms,
    String? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomListPage',
      'rooms': rooms.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomListPageImpl extends RoomListPage {
  _RoomListPageImpl({
    required List<_i2.RoomSummary> rooms,
    String? nextCursor,
  }) : super._(
         rooms: rooms,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [RoomListPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomListPage copyWith({
    List<_i2.RoomSummary>? rooms,
    Object? nextCursor = _Undefined,
  }) {
    return RoomListPage(
      rooms: rooms ?? this.rooms.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is String? ? nextCursor : this.nextCursor,
    );
  }
}
