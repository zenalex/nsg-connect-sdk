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
import 'enums/room_type.dart' as _i2;
import 'enums/room_ownership.dart' as _i3;
import 'enums/room_state.dart' as _i4;

/// Room — Matrix-комната с продуктовой/NSG-метадатой поверх.
/// Matrix хранит участников и сообщения; здесь — type/ownership/state и
/// product context для быстрых выборок без обращения к Matrix.
/// См. ТЗ §9, §10, §11, §13.
abstract class Room implements _i1.SerializableModel {
  Room._({
    this.id,
    required this.tenantId,
    this.productId,
    required this.matrixRoomId,
    required this.roomType,
    required this.ownership,
    required this.state,
    this.productEntityType,
    this.productEntityId,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessageBody,
  });

  factory Room({
    int? id,
    required int tenantId,
    int? productId,
    required String matrixRoomId,
    required _i2.RoomType roomType,
    required _i3.RoomOwnership ownership,
    required _i4.RoomState state,
    String? productEntityType,
    String? productEntityId,
    String? name,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageBody,
  }) = _RoomImpl;

  factory Room.fromJson(Map<String, dynamic> jsonSerialization) {
    return Room(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      matrixRoomId: jsonSerialization['matrixRoomId'] as String,
      roomType: _i2.RoomType.fromJson(
        (jsonSerialization['roomType'] as String),
      ),
      ownership: _i3.RoomOwnership.fromJson(
        (jsonSerialization['ownership'] as String),
      ),
      state: _i4.RoomState.fromJson((jsonSerialization['state'] as String)),
      productEntityType: jsonSerialization['productEntityType'] as String?,
      productEntityId: jsonSerialization['productEntityId'] as String?,
      name: jsonSerialization['name'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      lastMessageBody: jsonSerialization['lastMessageBody'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// NULL = комната принадлежит tenant, не привязана к продукту.
  int? productId;

  /// Полный matrix room id `!abc:server`.
  String matrixRoomId;

  _i2.RoomType roomType;

  _i3.RoomOwnership ownership;

  _i4.RoomState state;

  /// Product context (§13). entityType: 'team', 'support_ticket' и т.д.
  String? productEntityType;

  String? productEntityId;

  String? name;

  /// **B16-ext (group avatar)**: mxc-URL аватара группы. Заполняется
  /// `setRoomAvatar` endpoint-ом (owner/admin only) + при `/sync`
  /// парсинге `m.room.avatar` state event. Для direct-чатов поле
  /// остаётся null — `RoomSummary.avatarUrl` для direct берётся из
  /// peer's MessengerUser.avatarUrl (computed). Для group/team —
  /// берётся отсюда.
  String? avatarUrl;

  DateTime createdAt;

  DateTime updatedAt;

  /// Кэш для listRooms: lastMessageAt + preview body (обрезается до 120 chars).
  /// Заполняется sync-loop-ом TASK09.
  DateTime? lastMessageAt;

  String? lastMessageBody;

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Room copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? matrixRoomId,
    _i2.RoomType? roomType,
    _i3.RoomOwnership? ownership,
    _i4.RoomState? state,
    String? productEntityType,
    String? productEntityId,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageBody,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Room',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'matrixRoomId': matrixRoomId,
      'roomType': roomType.toJson(),
      'ownership': ownership.toJson(),
      'state': state.toJson(),
      if (productEntityType != null) 'productEntityType': productEntityType,
      if (productEntityId != null) 'productEntityId': productEntityId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastMessageBody != null) 'lastMessageBody': lastMessageBody,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomImpl extends Room {
  _RoomImpl({
    int? id,
    required int tenantId,
    int? productId,
    required String matrixRoomId,
    required _i2.RoomType roomType,
    required _i3.RoomOwnership ownership,
    required _i4.RoomState state,
    String? productEntityType,
    String? productEntityId,
    String? name,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageBody,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         matrixRoomId: matrixRoomId,
         roomType: roomType,
         ownership: ownership,
         state: state,
         productEntityType: productEntityType,
         productEntityId: productEntityId,
         name: name,
         avatarUrl: avatarUrl,
         createdAt: createdAt,
         updatedAt: updatedAt,
         lastMessageAt: lastMessageAt,
         lastMessageBody: lastMessageBody,
       );

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Room copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    String? matrixRoomId,
    _i2.RoomType? roomType,
    _i3.RoomOwnership? ownership,
    _i4.RoomState? state,
    Object? productEntityType = _Undefined,
    Object? productEntityId = _Undefined,
    Object? name = _Undefined,
    Object? avatarUrl = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastMessageAt = _Undefined,
    Object? lastMessageBody = _Undefined,
  }) {
    return Room(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      matrixRoomId: matrixRoomId ?? this.matrixRoomId,
      roomType: roomType ?? this.roomType,
      ownership: ownership ?? this.ownership,
      state: state ?? this.state,
      productEntityType: productEntityType is String?
          ? productEntityType
          : this.productEntityType,
      productEntityId: productEntityId is String?
          ? productEntityId
          : this.productEntityId,
      name: name is String? ? name : this.name,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      lastMessageBody: lastMessageBody is String?
          ? lastMessageBody
          : this.lastMessageBody,
    );
  }
}
