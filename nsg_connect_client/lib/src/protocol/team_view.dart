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
import 'enums/team_kind.dart' as _i2;
import 'enums/team_member_role.dart' as _i3;

/// Строка списка команд для админки и для экрана «Мои команды».
/// `memberCount` считается на сервере: без него админ видел бы имена без
/// всякого представления о размере, а именно размер — то, что решает,
/// справочник это или свалка (потолок — `TeamService.maxMembers`).
abstract class TeamView implements _i1.SerializableModel {
  TeamView._({
    required this.id,
    required this.name,
    this.description,
    required this.kind,
    required this.memberCount,
    this.myRole,
  });

  factory TeamView({
    required int id,
    required String name,
    String? description,
    required _i2.TeamKind kind,
    required int memberCount,
    _i3.TeamMemberRole? myRole,
  }) = _TeamViewImpl;

  factory TeamView.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamView(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      kind: _i2.TeamKind.fromJson((jsonSerialization['kind'] as String)),
      memberCount: jsonSerialization['memberCount'] as int,
      myRole: jsonSerialization['myRole'] == null
          ? null
          : _i3.TeamMemberRole.fromJson(
              (jsonSerialization['myRole'] as String),
            ),
    );
  }

  int id;

  String name;

  String? description;

  _i2.TeamKind kind;

  int memberCount;

  /// Моя роль в этой команде (этап 3). `null` — когда список не про
  /// конкретного человека (админка платформы смотрит справочник тенанта
  /// со стороны). От роли зависит, показывать ли кнопки правки состава:
  /// рисовать «убрать» тому, кому сервер откажет, — обман интерфейса.
  _i3.TeamMemberRole? myRole;

  /// Returns a shallow copy of this [TeamView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamView copyWith({
    int? id,
    String? name,
    String? description,
    _i2.TeamKind? kind,
    int? memberCount,
    _i3.TeamMemberRole? myRole,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamView',
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'kind': kind.toJson(),
      'memberCount': memberCount,
      if (myRole != null) 'myRole': myRole?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamViewImpl extends TeamView {
  _TeamViewImpl({
    required int id,
    required String name,
    String? description,
    required _i2.TeamKind kind,
    required int memberCount,
    _i3.TeamMemberRole? myRole,
  }) : super._(
         id: id,
         name: name,
         description: description,
         kind: kind,
         memberCount: memberCount,
         myRole: myRole,
       );

  /// Returns a shallow copy of this [TeamView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamView copyWith({
    int? id,
    String? name,
    Object? description = _Undefined,
    _i2.TeamKind? kind,
    int? memberCount,
    Object? myRole = _Undefined,
  }) {
    return TeamView(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      kind: kind ?? this.kind,
      memberCount: memberCount ?? this.memberCount,
      myRole: myRole is _i3.TeamMemberRole? ? myRole : this.myRole,
    );
  }
}
