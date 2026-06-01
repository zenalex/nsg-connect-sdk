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

/// Lightweight DTO для `listRooms` — оптимизирован под рендер списка
/// чатов в SDK без отдельного RPC за каждой комнатой. См. TASK13.
///
/// Не table — это transient DTO, собирается в RoomService из Room +
/// RoomMembership с join-ом.
abstract class RoomSummary implements _i1.SerializableModel {
  RoomSummary._({
    required this.id,
    this.name,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
    required this.archived,
    required this.muted,
    this.productId,
    this.productEntityType,
    this.productEntityId,
    required this.roomType,
  });

  factory RoomSummary({
    required int id,
    String? name,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    required int unreadCount,
    required bool archived,
    required bool muted,
    int? productId,
    String? productEntityType,
    String? productEntityId,
    required _i2.RoomType roomType,
  }) = _RoomSummaryImpl;

  factory RoomSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomSummary(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      lastMessagePreview: jsonSerialization['lastMessagePreview'] as String?,
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      unreadCount: jsonSerialization['unreadCount'] as int,
      archived: _i1.BoolJsonExtension.fromJson(jsonSerialization['archived']),
      muted: _i1.BoolJsonExtension.fromJson(jsonSerialization['muted']),
      productId: jsonSerialization['productId'] as int?,
      productEntityType: jsonSerialization['productEntityType'] as String?,
      productEntityId: jsonSerialization['productEntityId'] as String?,
      roomType: _i2.RoomType.fromJson(
        (jsonSerialization['roomType'] as String),
      ),
    );
  }

  int id;

  /// Computed name: для direct — display peer-а; для group/product —
  /// Room.name; null если ничего не задано (SDK покажет fallback).
  String? name;

  /// Computed avatarUrl: для direct — peer.avatarUrl; для group —
  /// общая аватарка комнаты (TASK19 / null на MVP).
  String? avatarUrl;

  /// Превью последнего сообщения, обрезано до 120 символов
  /// в RoomLastMessageWatcher. Для не-text типов (m.image / m.file) —
  /// placeholder типа `📷 image` / `📎 filename`.
  String? lastMessagePreview;

  DateTime? lastMessageAt;

  /// Per-user unread (TASK18). На TASK13 MVP всегда 0 — поле в DTO
  /// есть для стабильности контракта.
  int unreadCount;

  /// Per-user архив (RoomMembership.archived).
  bool archived;

  /// Per-user mute (RoomMembership.mutedUntil > now).
  bool muted;

  int? productId;

  /// Привязка к product entity ('team' / 'support_ticket' / etc).
  String? productEntityType;

  String? productEntityId;

  _i2.RoomType roomType;

  /// Returns a shallow copy of this [RoomSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomSummary copyWith({
    int? id,
    String? name,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? archived,
    bool? muted,
    int? productId,
    String? productEntityType,
    String? productEntityId,
    _i2.RoomType? roomType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomSummary',
      'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      'unreadCount': unreadCount,
      'archived': archived,
      'muted': muted,
      if (productId != null) 'productId': productId,
      if (productEntityType != null) 'productEntityType': productEntityType,
      if (productEntityId != null) 'productEntityId': productEntityId,
      'roomType': roomType.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomSummaryImpl extends RoomSummary {
  _RoomSummaryImpl({
    required int id,
    String? name,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    required int unreadCount,
    required bool archived,
    required bool muted,
    int? productId,
    String? productEntityType,
    String? productEntityId,
    required _i2.RoomType roomType,
  }) : super._(
         id: id,
         name: name,
         avatarUrl: avatarUrl,
         lastMessagePreview: lastMessagePreview,
         lastMessageAt: lastMessageAt,
         unreadCount: unreadCount,
         archived: archived,
         muted: muted,
         productId: productId,
         productEntityType: productEntityType,
         productEntityId: productEntityId,
         roomType: roomType,
       );

  /// Returns a shallow copy of this [RoomSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomSummary copyWith({
    int? id,
    Object? name = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? lastMessagePreview = _Undefined,
    Object? lastMessageAt = _Undefined,
    int? unreadCount,
    bool? archived,
    bool? muted,
    Object? productId = _Undefined,
    Object? productEntityType = _Undefined,
    Object? productEntityId = _Undefined,
    _i2.RoomType? roomType,
  }) {
    return RoomSummary(
      id: id ?? this.id,
      name: name is String? ? name : this.name,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      lastMessagePreview: lastMessagePreview is String?
          ? lastMessagePreview
          : this.lastMessagePreview,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      archived: archived ?? this.archived,
      muted: muted ?? this.muted,
      productId: productId is int? ? productId : this.productId,
      productEntityType: productEntityType is String?
          ? productEntityType
          : this.productEntityType,
      productEntityId: productEntityId is String?
          ? productEntityId
          : this.productEntityId,
      roomType: roomType ?? this.roomType,
    );
  }
}
