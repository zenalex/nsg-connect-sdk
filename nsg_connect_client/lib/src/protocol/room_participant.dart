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
import 'enums/room_member_role.dart' as _i2;

/// Один участник комнаты в DTO `RoomDetails.participants`. Возвращает
/// display-уровень: SDK показывает рядом с именем role-badge и аватарку.
/// messengerUserId полезен только для followup-запросов (профиль,
/// remove-from-room — TASK29).
abstract class RoomParticipant implements _i1.SerializableModel {
  RoomParticipant._({
    required this.messengerUserId,
    required this.matrixUserId,
    this.displayName,
    this.avatarUrl,
    required this.role,
  });

  factory RoomParticipant({
    required int messengerUserId,
    required String matrixUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.RoomMemberRole role,
  }) = _RoomParticipantImpl;

  factory RoomParticipant.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomParticipant(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      matrixUserId: jsonSerialization['matrixUserId'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: _i2.RoomMemberRole.fromJson((jsonSerialization['role'] as String)),
    );
  }

  int messengerUserId;

  String matrixUserId;

  String? displayName;

  String? avatarUrl;

  _i2.RoomMemberRole role;

  /// Returns a shallow copy of this [RoomParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomParticipant copyWith({
    int? messengerUserId,
    String? matrixUserId,
    String? displayName,
    String? avatarUrl,
    _i2.RoomMemberRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomParticipant',
      'messengerUserId': messengerUserId,
      'matrixUserId': matrixUserId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomParticipantImpl extends RoomParticipant {
  _RoomParticipantImpl({
    required int messengerUserId,
    required String matrixUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.RoomMemberRole role,
  }) : super._(
         messengerUserId: messengerUserId,
         matrixUserId: matrixUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
         role: role,
       );

  /// Returns a shallow copy of this [RoomParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomParticipant copyWith({
    int? messengerUserId,
    String? matrixUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    _i2.RoomMemberRole? role,
  }) {
    return RoomParticipant(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      matrixUserId: matrixUserId ?? this.matrixUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
    );
  }
}
