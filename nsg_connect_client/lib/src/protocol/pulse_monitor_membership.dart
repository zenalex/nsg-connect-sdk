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

/// **TASK79**: членство в конкретном мониторе — зеркало `RoomMembership`.
/// Парная таблица к `PulseFolderMembership` (обоснование «почему две, а не
/// одна полиморфная» — там же).
///
/// Членство на мониторе сильнее наследования: эффективная роль =
/// max(своё членство, роль по цепочке папок-предков). Так владелец может
/// поделиться ОДНИМ монитором, не открывая всю папку.
abstract class PulseMonitorMembership implements _i1.SerializableModel {
  PulseMonitorMembership._({
    this.id,
    required this.monitorId,
    required this.messengerUserId,
    String? role,
    required this.addedAt,
    this.addedByMessengerUserId,
  }) : role = role ?? 'viewer';

  factory PulseMonitorMembership({
    int? id,
    required int monitorId,
    required int messengerUserId,
    String? role,
    required DateTime addedAt,
    int? addedByMessengerUserId,
  }) = _PulseMonitorMembershipImpl;

  factory PulseMonitorMembership.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PulseMonitorMembership(
      id: jsonSerialization['id'] as int?,
      monitorId: jsonSerialization['monitorId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      role: jsonSerialization['role'] as String?,
      addedAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['addedAt']),
      addedByMessengerUserId:
          jsonSerialization['addedByMessengerUserId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int monitorId;

  int messengerUserId;

  /// `owner` | `admin` | `viewer` — семантика см. `PulseFolderMembership`.
  String role;

  DateTime addedAt;

  /// Кто выдал доступ. SetNull — см. `PulseFolderMembership`.
  int? addedByMessengerUserId;

  /// Returns a shallow copy of this [PulseMonitorMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseMonitorMembership copyWith({
    int? id,
    int? monitorId,
    int? messengerUserId,
    String? role,
    DateTime? addedAt,
    int? addedByMessengerUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseMonitorMembership',
      if (id != null) 'id': id,
      'monitorId': monitorId,
      'messengerUserId': messengerUserId,
      'role': role,
      'addedAt': addedAt.toJson(),
      if (addedByMessengerUserId != null)
        'addedByMessengerUserId': addedByMessengerUserId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseMonitorMembershipImpl extends PulseMonitorMembership {
  _PulseMonitorMembershipImpl({
    int? id,
    required int monitorId,
    required int messengerUserId,
    String? role,
    required DateTime addedAt,
    int? addedByMessengerUserId,
  }) : super._(
         id: id,
         monitorId: monitorId,
         messengerUserId: messengerUserId,
         role: role,
         addedAt: addedAt,
         addedByMessengerUserId: addedByMessengerUserId,
       );

  /// Returns a shallow copy of this [PulseMonitorMembership]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseMonitorMembership copyWith({
    Object? id = _Undefined,
    int? monitorId,
    int? messengerUserId,
    String? role,
    DateTime? addedAt,
    Object? addedByMessengerUserId = _Undefined,
  }) {
    return PulseMonitorMembership(
      id: id is int? ? id : this.id,
      monitorId: monitorId ?? this.monitorId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      addedByMessengerUserId: addedByMessengerUserId is int?
          ? addedByMessengerUserId
          : this.addedByMessengerUserId,
    );
  }
}
