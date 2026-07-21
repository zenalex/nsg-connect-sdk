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

/// **TASK62**: пользовательская папка чатов. Per-user (owner —
/// `ownerMessengerUserId`, plain int как у Ticket.createdByMessengerUserId),
/// приватна: видит и управляет только владелец. Комнаты входят в папку
/// через M2M [ChatFolderRoom] — один чат может быть в нескольких папках.
/// Удаление папки НЕ трогает комнаты (только membership-строки, Cascade).
abstract class ChatFolderRecord implements _i1.SerializableModel {
  ChatFolderRecord._({
    this.id,
    required this.ownerMessengerUserId,
    required this.name,
    int? sortOrder,
    required this.createdAt,
  }) : sortOrder = sortOrder ?? 0;

  factory ChatFolderRecord({
    int? id,
    required int ownerMessengerUserId,
    required String name,
    int? sortOrder,
    required DateTime createdAt,
  }) = _ChatFolderRecordImpl;

  factory ChatFolderRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatFolderRecord(
      id: jsonSerialization['id'] as int?,
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      name: jsonSerialization['name'] as String,
      sortOrder: jsonSerialization['sortOrder'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int ownerMessengerUserId;

  /// Имя папки, trim, 1..64, уникально per owner (см. индекс).
  String name;

  /// Порядок в корне списка чатов (итер.2 — drag-sort; пока createdAt-порядок).
  int sortOrder;

  DateTime createdAt;

  /// Returns a shallow copy of this [ChatFolderRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatFolderRecord copyWith({
    int? id,
    int? ownerMessengerUserId,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatFolderRecord',
      if (id != null) 'id': id,
      'ownerMessengerUserId': ownerMessengerUserId,
      'name': name,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChatFolderRecordImpl extends ChatFolderRecord {
  _ChatFolderRecordImpl({
    int? id,
    required int ownerMessengerUserId,
    required String name,
    int? sortOrder,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ownerMessengerUserId: ownerMessengerUserId,
         name: name,
         sortOrder: sortOrder,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ChatFolderRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatFolderRecord copyWith({
    Object? id = _Undefined,
    int? ownerMessengerUserId,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ChatFolderRecord(
      id: id is int? ? id : this.id,
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
