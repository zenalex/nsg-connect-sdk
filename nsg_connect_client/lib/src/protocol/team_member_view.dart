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
import 'enums/team_member_role.dart' as _i2;

/// Строка состава команды для админки.
///
/// Показываем ИМЯ УЧАСТНИКА, а не того, кто его добавил: на экране
/// поддержки ровно эта путаница уже случалась — у всех пятерых стоял один
/// и тот же email (владельца), потому что бралось поле «кем добавлен».
abstract class TeamMemberView implements _i1.SerializableModel {
  TeamMemberView._({
    required this.messengerUserId,
    this.displayName,
    this.avatarUrl,
    required this.role,
  });

  factory TeamMemberView({
    required int messengerUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.TeamMemberRole role,
  }) = _TeamMemberViewImpl;

  factory TeamMemberView.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamMemberView(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: _i2.TeamMemberRole.fromJson((jsonSerialization['role'] as String)),
    );
  }

  int messengerUserId;

  String? displayName;

  String? avatarUrl;

  _i2.TeamMemberRole role;

  /// Returns a shallow copy of this [TeamMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamMemberView copyWith({
    int? messengerUserId,
    String? displayName,
    String? avatarUrl,
    _i2.TeamMemberRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamMemberView',
      'messengerUserId': messengerUserId,
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

class _TeamMemberViewImpl extends TeamMemberView {
  _TeamMemberViewImpl({
    required int messengerUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.TeamMemberRole role,
  }) : super._(
         messengerUserId: messengerUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
         role: role,
       );

  /// Returns a shallow copy of this [TeamMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamMemberView copyWith({
    int? messengerUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    _i2.TeamMemberRole? role,
  }) {
    return TeamMemberView(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
    );
  }
}
