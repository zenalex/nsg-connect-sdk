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
import 'room_participant.dart' as _i3;
import 'enums/room_member_role.dart' as _i4;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i5;

/// Полный DTO одной комнаты. Возвращается из `getRoom`,
/// `createDirect`, `createGroup`, `getOrCreateProductRoom`,
/// `openSupportChat`. Включает RoomSummary-поля + список участников
/// + viewer-роль + matrix room id (для опционального fallback в
/// Element-клиент).
abstract class RoomDetails implements _i1.SerializableModel {
  RoomDetails._({
    required this.id,
    required this.matrixRoomId,
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
    required this.participants,
    required this.totalParticipants,
    required this.viewerRole,
    this.supportEscalationTier,
    required this.canEscalateSupport,
    this.autoCleanupTtlSeconds,
  });

  factory RoomDetails({
    required int id,
    required String matrixRoomId,
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
    required List<_i3.RoomParticipant> participants,
    required int totalParticipants,
    required _i4.RoomMemberRole viewerRole,
    int? supportEscalationTier,
    required bool canEscalateSupport,
    int? autoCleanupTtlSeconds,
  }) = _RoomDetailsImpl;

  factory RoomDetails.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomDetails(
      id: jsonSerialization['id'] as int,
      matrixRoomId: jsonSerialization['matrixRoomId'] as String,
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
      participants: _i5.Protocol().deserialize<List<_i3.RoomParticipant>>(
        jsonSerialization['participants'],
      ),
      totalParticipants: jsonSerialization['totalParticipants'] as int,
      viewerRole: _i4.RoomMemberRole.fromJson(
        (jsonSerialization['viewerRole'] as String),
      ),
      supportEscalationTier: jsonSerialization['supportEscalationTier'] as int?,
      canEscalateSupport: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['canEscalateSupport'],
      ),
      autoCleanupTtlSeconds: jsonSerialization['autoCleanupTtlSeconds'] as int?,
    );
  }

  int id;

  String matrixRoomId;

  String? name;

  String? avatarUrl;

  String? lastMessagePreview;

  DateTime? lastMessageAt;

  int unreadCount;

  bool archived;

  bool muted;

  int? productId;

  String? productEntityType;

  String? productEntityId;

  _i2.RoomType roomType;

  /// Первые 30 участников. Для бóльших групп UI делает отдельный
  /// запрос (paginated, добавим в TASK14/TASK15).
  List<_i3.RoomParticipant> participants;

  /// Общее количество участников (включая тех, что не вошли в первые
  /// 30). UI использует для счётчика "и ещё N участников".
  int totalParticipants;

  /// Роль ТЕКУЩЕГО viewer-а в комнате.
  _i4.RoomMemberRole viewerRole;

  /// **TASK48**: текущий достигнутый тир эскалации support-комнаты
  /// (см. `Room.supportEscalationTier`). null для не-support-комнат и
  /// для support-комнат на базовом уровне.
  int? supportEscalationTier;

  /// **TASK48**: может ли ТЕКУЩИЙ viewer эскалировать этот support-чат
  /// (позвать следующий тир). true ⟺ комната support-типа И viewer —
  /// оператор-член И существует непустой тир выше текущего. Клиент сам
  /// это не вычислит — считаем на сервере, UI лишь рисует кнопку.
  bool canEscalateSupport;

  /// **TASK68**: TTL автоочистки комнаты в секундах (`Room
  /// .autoCleanupTtlSeconds`). `null` = автоочистка выключена. Экран
  /// настроек комнаты рисует по нему выбранный пресет.
  ///
  /// Nullable и НЕ required — старый клиент/сервер-скью трактует
  /// отсутствие как «выключено».
  int? autoCleanupTtlSeconds;

  /// Returns a shallow copy of this [RoomDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomDetails copyWith({
    int? id,
    String? matrixRoomId,
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
    List<_i3.RoomParticipant>? participants,
    int? totalParticipants,
    _i4.RoomMemberRole? viewerRole,
    int? supportEscalationTier,
    bool? canEscalateSupport,
    int? autoCleanupTtlSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomDetails',
      'id': id,
      'matrixRoomId': matrixRoomId,
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
      'participants': participants.toJson(valueToJson: (v) => v.toJson()),
      'totalParticipants': totalParticipants,
      'viewerRole': viewerRole.toJson(),
      if (supportEscalationTier != null)
        'supportEscalationTier': supportEscalationTier,
      'canEscalateSupport': canEscalateSupport,
      if (autoCleanupTtlSeconds != null)
        'autoCleanupTtlSeconds': autoCleanupTtlSeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomDetailsImpl extends RoomDetails {
  _RoomDetailsImpl({
    required int id,
    required String matrixRoomId,
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
    required List<_i3.RoomParticipant> participants,
    required int totalParticipants,
    required _i4.RoomMemberRole viewerRole,
    int? supportEscalationTier,
    required bool canEscalateSupport,
    int? autoCleanupTtlSeconds,
  }) : super._(
         id: id,
         matrixRoomId: matrixRoomId,
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
         participants: participants,
         totalParticipants: totalParticipants,
         viewerRole: viewerRole,
         supportEscalationTier: supportEscalationTier,
         canEscalateSupport: canEscalateSupport,
         autoCleanupTtlSeconds: autoCleanupTtlSeconds,
       );

  /// Returns a shallow copy of this [RoomDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomDetails copyWith({
    int? id,
    String? matrixRoomId,
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
    List<_i3.RoomParticipant>? participants,
    int? totalParticipants,
    _i4.RoomMemberRole? viewerRole,
    Object? supportEscalationTier = _Undefined,
    bool? canEscalateSupport,
    Object? autoCleanupTtlSeconds = _Undefined,
  }) {
    return RoomDetails(
      id: id ?? this.id,
      matrixRoomId: matrixRoomId ?? this.matrixRoomId,
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
      participants:
          participants ?? this.participants.map((e0) => e0.copyWith()).toList(),
      totalParticipants: totalParticipants ?? this.totalParticipants,
      viewerRole: viewerRole ?? this.viewerRole,
      supportEscalationTier: supportEscalationTier is int?
          ? supportEscalationTier
          : this.supportEscalationTier,
      canEscalateSupport: canEscalateSupport ?? this.canEscalateSupport,
      autoCleanupTtlSeconds: autoCleanupTtlSeconds is int?
          ? autoCleanupTtlSeconds
          : this.autoCleanupTtlSeconds,
    );
  }
}
