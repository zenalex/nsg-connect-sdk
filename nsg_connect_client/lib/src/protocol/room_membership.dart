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
import 'enums/participant_kind.dart' as _i2;

/// RoomMembership — членство в комнате с per-user атрибутами
/// (mute, archive, role, lastRead). Параллельная Matrix membership;
/// Matrix хранит свой membership state, мы — продуктовый.
/// См. ТЗ §9, §14 (mute/archive — TASK42).
abstract class RoomMembership implements _i1.SerializableModel {
  RoomMembership._({
    this.id,
    required this.roomId,
    required this.messengerUserId,
    required this.participantKind,
    String? role,
    required this.joinedAt,
    this.mutedUntil,
    bool? archived,
    this.lastReadEventId,
    this.lastReadAt,
    int? unreadCount,
    this.powerLevel,
  }) : role = role ?? 'member',
       archived = archived ?? false,
       unreadCount = unreadCount ?? 0;

  factory RoomMembership({
    int? id,
    required int roomId,
    required int messengerUserId,
    required _i2.ParticipantKind participantKind,
    String? role,
    required DateTime joinedAt,
    DateTime? mutedUntil,
    bool? archived,
    String? lastReadEventId,
    DateTime? lastReadAt,
    int? unreadCount,
    int? powerLevel,
  }) = _RoomMembershipImpl;

  factory RoomMembership.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomMembership(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      participantKind: _i2.ParticipantKind.fromJson(
        (jsonSerialization['participantKind'] as String),
      ),
      role: jsonSerialization['role'] as String?,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      mutedUntil: jsonSerialization['mutedUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['mutedUntil']),
      archived: jsonSerialization['archived'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['archived']),
      lastReadEventId: jsonSerialization['lastReadEventId'] as String?,
      lastReadAt: jsonSerialization['lastReadAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastReadAt']),
      unreadCount: jsonSerialization['unreadCount'] as int?,
      powerLevel: jsonSerialization['powerLevel'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  int messengerUserId;

  _i2.ParticipantKind participantKind;

  /// Свободная строка: 'admin' | 'moderator' | 'member' | custom-роли tenant-а.
  String role;

  DateTime joinedAt;

  /// Заглушение комнаты до конкретного момента; null = не заглушена.
  /// См. TASK42.
  DateTime? mutedUntil;

  /// Per-user архив (комната скрыта из default listRooms у этого user-а).
  bool archived;

  /// lastReadEventId — matrix event id, до которого пользователь прочитал
  /// (TASK18). null до первого markRead.
  ///
  /// **Monotonic invariant**: lastReadAt только движется вперёд во
  /// времени. `MarkReadService.markRead` UPDATE-ит row только при
  /// `newLastReadAt > current.lastReadAt OR current IS NULL` —
  /// старые markRead из device-B (с устаревшим horizon) НЕ
  /// регрессируют lastReadAt и не открывают окно для double-увеличения
  /// unreadCount следующим сообщением. См. ревью TASK18 plan #Q5.
  String? lastReadEventId;

  DateTime? lastReadAt;

  /// Unread message counter (TASK18). Инкрементируется в
  /// `MatrixSyncDispatcher._publishEvents` для всех participants
  /// кроме sender при каждом m.room.message; обнуляется в
  /// `MarkReadService.markRead`. Race-guard через `serverTimestamp >
  /// lastReadAt` исключает out-of-order increments после markRead.
  ///
  /// Не backfill для existing rows — default=0; реальные счётчики
  /// начинают расти со следующего сообщения, markRead подтянет
  /// до нуля при первом открытии чата.
  int unreadCount;

  /// **TASK29**: raw Matrix power level (0-100). Заполняется когда
  /// `MatrixSyncDispatcher._processPowerLevels` парсит
  /// `m.room.power_levels` event (initial /sync state ИЛИ subsequent
  /// timeline). `null` до первого parse — fallback на `role` string
  /// в [RoomService._roleOf]/[RoomAdminService] для guard checks.
  ///
  /// Mapping `_mapPowerLevelToRole`: pl >= 100 → owner, pl >= 50 →
  /// admin, иначе member. SetRoomMemberRole inverse: member → 0,
  /// admin → 50, owner → 100. Raw int хранится для precision (Matrix
  /// может выставить custom levels e.g. 30, не маппящиеся в role-
  /// enum) — SDK видит производный `role`, server держит точное PL
  /// для round-trip к Matrix.
  int? powerLevel;

  /// Returns a shallow copy of this [RoomMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomMembership copyWith({
    int? id,
    int? roomId,
    int? messengerUserId,
    _i2.ParticipantKind? participantKind,
    String? role,
    DateTime? joinedAt,
    DateTime? mutedUntil,
    bool? archived,
    String? lastReadEventId,
    DateTime? lastReadAt,
    int? unreadCount,
    int? powerLevel,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomMembership',
      if (id != null) 'id': id,
      'roomId': roomId,
      'messengerUserId': messengerUserId,
      'participantKind': participantKind.toJson(),
      'role': role,
      'joinedAt': joinedAt.toJson(),
      if (mutedUntil != null) 'mutedUntil': mutedUntil?.toJson(),
      'archived': archived,
      if (lastReadEventId != null) 'lastReadEventId': lastReadEventId,
      if (lastReadAt != null) 'lastReadAt': lastReadAt?.toJson(),
      'unreadCount': unreadCount,
      if (powerLevel != null) 'powerLevel': powerLevel,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomMembershipImpl extends RoomMembership {
  _RoomMembershipImpl({
    int? id,
    required int roomId,
    required int messengerUserId,
    required _i2.ParticipantKind participantKind,
    String? role,
    required DateTime joinedAt,
    DateTime? mutedUntil,
    bool? archived,
    String? lastReadEventId,
    DateTime? lastReadAt,
    int? unreadCount,
    int? powerLevel,
  }) : super._(
         id: id,
         roomId: roomId,
         messengerUserId: messengerUserId,
         participantKind: participantKind,
         role: role,
         joinedAt: joinedAt,
         mutedUntil: mutedUntil,
         archived: archived,
         lastReadEventId: lastReadEventId,
         lastReadAt: lastReadAt,
         unreadCount: unreadCount,
         powerLevel: powerLevel,
       );

  /// Returns a shallow copy of this [RoomMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomMembership copyWith({
    Object? id = _Undefined,
    int? roomId,
    int? messengerUserId,
    _i2.ParticipantKind? participantKind,
    String? role,
    DateTime? joinedAt,
    Object? mutedUntil = _Undefined,
    bool? archived,
    Object? lastReadEventId = _Undefined,
    Object? lastReadAt = _Undefined,
    int? unreadCount,
    Object? powerLevel = _Undefined,
  }) {
    return RoomMembership(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      participantKind: participantKind ?? this.participantKind,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      mutedUntil: mutedUntil is DateTime? ? mutedUntil : this.mutedUntil,
      archived: archived ?? this.archived,
      lastReadEventId: lastReadEventId is String?
          ? lastReadEventId
          : this.lastReadEventId,
      lastReadAt: lastReadAt is DateTime? ? lastReadAt : this.lastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      powerLevel: powerLevel is int? ? powerLevel : this.powerLevel,
    );
  }
}
