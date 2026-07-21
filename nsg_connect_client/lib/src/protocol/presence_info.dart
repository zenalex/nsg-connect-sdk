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

/// **TASK55**: presence одного пользователя глазами вызывающего.
/// Отдаётся ТОЛЬКО по пользователям с общей комнатой (authz в
/// PresenceService); боты и чужие id тихо отбрасываются из ответа.
abstract class PresenceInfo implements _i1.SerializableModel {
  PresenceInfo._({
    required this.messengerUserId,
    this.lastActiveAt,
    required this.online,
  });

  factory PresenceInfo({
    required int messengerUserId,
    DateTime? lastActiveAt,
    required bool online,
  }) = _PresenceInfoImpl;

  factory PresenceInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return PresenceInfo(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      lastActiveAt: jsonSerialization['lastActiveAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActiveAt'],
            ),
      online: _i1.BoolJsonExtension.fromJson(jsonSerialization['online']),
    );
  }

  int messengerUserId;

  /// Последняя активность, огрублена до минуты. null = неизвестно.
  DateTime? lastActiveAt;

  /// Итерация 2 (realtime). В итер.1 всегда false.
  bool online;

  /// Returns a shallow copy of this [PresenceInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PresenceInfo copyWith({
    int? messengerUserId,
    DateTime? lastActiveAt,
    bool? online,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PresenceInfo',
      'messengerUserId': messengerUserId,
      if (lastActiveAt != null) 'lastActiveAt': lastActiveAt?.toJson(),
      'online': online,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PresenceInfoImpl extends PresenceInfo {
  _PresenceInfoImpl({
    required int messengerUserId,
    DateTime? lastActiveAt,
    required bool online,
  }) : super._(
         messengerUserId: messengerUserId,
         lastActiveAt: lastActiveAt,
         online: online,
       );

  /// Returns a shallow copy of this [PresenceInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PresenceInfo copyWith({
    int? messengerUserId,
    Object? lastActiveAt = _Undefined,
    bool? online,
  }) {
    return PresenceInfo(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      lastActiveAt: lastActiveAt is DateTime?
          ? lastActiveAt
          : this.lastActiveAt,
      online: online ?? this.online,
    );
  }
}
