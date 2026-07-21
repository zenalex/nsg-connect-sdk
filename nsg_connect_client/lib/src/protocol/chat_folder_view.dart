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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// **TASK62**: DTO папки чатов для клиента — папка + roomIds одним
/// объектом (клиентская группировка buildFolders остаётся чистой функцией).
abstract class ChatFolderView implements _i1.SerializableModel {
  ChatFolderView._({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.roomIds,
  });

  factory ChatFolderView({
    required int id,
    required String name,
    required int sortOrder,
    required List<int> roomIds,
  }) = _ChatFolderViewImpl;

  factory ChatFolderView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatFolderView(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      sortOrder: jsonSerialization['sortOrder'] as int,
      roomIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['roomIds'],
      ),
    );
  }

  int id;

  String name;

  int sortOrder;

  List<int> roomIds;

  /// Returns a shallow copy of this [ChatFolderView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatFolderView copyWith({
    int? id,
    String? name,
    int? sortOrder,
    List<int>? roomIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatFolderView',
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
      'roomIds': roomIds.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ChatFolderViewImpl extends ChatFolderView {
  _ChatFolderViewImpl({
    required int id,
    required String name,
    required int sortOrder,
    required List<int> roomIds,
  }) : super._(
         id: id,
         name: name,
         sortOrder: sortOrder,
         roomIds: roomIds,
       );

  /// Returns a shallow copy of this [ChatFolderView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatFolderView copyWith({
    int? id,
    String? name,
    int? sortOrder,
    List<int>? roomIds,
  }) {
    return ChatFolderView(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      roomIds: roomIds ?? this.roomIds.map((e0) => e0).toList(),
    );
  }
}
