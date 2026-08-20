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

/// **Участник команды** ([Team]).
///
/// Один человек может состоять во множестве команд — это просто
/// несколько строк, никакой особой обработки не требуется.
///
/// Исключение из команды удаляет строку — и человек исчезает из списка
/// знакомых, ЕСЛИ не остался знакомым по другой причине (общая комната,
/// ручной контакт, другая общая команда). Это правильное поведение, но
/// интерфейс обязан его объяснять: иначе «убрал из команды, а он не
/// пропал» читается как баг.
abstract class TeamMember implements _i1.SerializableModel {
  TeamMember._({
    this.id,
    required this.teamId,
    required this.messengerUserId,
    required this.role,
    required this.createdAt,
  });

  factory TeamMember({
    int? id,
    required int teamId,
    required int messengerUserId,
    required _i2.TeamMemberRole role,
    required DateTime createdAt,
  }) = _TeamMemberImpl;

  factory TeamMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamMember(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      role: _i2.TeamMemberRole.fromJson((jsonSerialization['role'] as String)),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на команду. Cascade-delete: состав уходит вместе с командой.
  int teamId;

  /// FK на MessengerUser. Cascade-delete: членство пропадает вместе с
  /// пользователем.
  int messengerUserId;

  _i2.TeamMemberRole role;

  DateTime createdAt;

  /// Returns a shallow copy of this [TeamMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamMember copyWith({
    int? id,
    int? teamId,
    int? messengerUserId,
    _i2.TeamMemberRole? role,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamMember',
      if (id != null) 'id': id,
      'teamId': teamId,
      'messengerUserId': messengerUserId,
      'role': role.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamMemberImpl extends TeamMember {
  _TeamMemberImpl({
    int? id,
    required int teamId,
    required int messengerUserId,
    required _i2.TeamMemberRole role,
    required DateTime createdAt,
  }) : super._(
         id: id,
         teamId: teamId,
         messengerUserId: messengerUserId,
         role: role,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TeamMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamMember copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? messengerUserId,
    _i2.TeamMemberRole? role,
    DateTime? createdAt,
  }) {
    return TeamMember(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
