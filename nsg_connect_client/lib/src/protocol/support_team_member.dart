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
import 'enums/support_team_role.dart' as _i2;

/// **TASK43**: участник операторской команды поддержки ([SupportTeam]).
/// Участником может быть человек-оператор ИЛИ БОТ продукта (у бота тоже
/// есть `MessengerUser`, см. TASK36) — это закрывает gap «бот не
/// добавляется в новые support-комнаты»: бот-член команды добавляется
/// тем же механизмом, что и люди.
///
/// `role` = [SupportTeamRole]: `owner` может менять состав команды
/// (add/remove), `member` — нет.
abstract class SupportTeamMember implements _i1.SerializableModel {
  SupportTeamMember._({
    this.id,
    required this.teamId,
    required this.messengerUserId,
    required this.role,
    int? tier,
    this.addedByEmail,
    required this.createdAt,
  }) : tier = tier ?? 1;

  factory SupportTeamMember({
    int? id,
    required int teamId,
    required int messengerUserId,
    required _i2.SupportTeamRole role,
    int? tier,
    String? addedByEmail,
    required DateTime createdAt,
  }) = _SupportTeamMemberImpl;

  factory SupportTeamMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return SupportTeamMember(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      role: _i2.SupportTeamRole.fromJson((jsonSerialization['role'] as String)),
      tier: jsonSerialization['tier'] as int?,
      addedByEmail: jsonSerialization['addedByEmail'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на команду. Cascade-delete: участники уходят вместе с командой.
  int teamId;

  /// FK на MessengerUser (человек-оператор или бот).
  /// Cascade-delete: membership пропадает вместе с MessengerUser-ом.
  int messengerUserId;

  _i2.SupportTeamRole role;

  /// **TASK48**: уровень (тир) оператора. `1` = фронт-линия (получают
  /// support-чат при создании); `2` = эскалация (подключаются по кнопке
  /// «Позвать старшего» или по таймауту без ответа). Ортогонально [role]
  /// (owner/member — права управления командой). MVP-значения {1,2};
  /// схема готова к N. ALTER на непустую таблицу требует DB-дефолта.
  int tier;

  /// Email, по которому оператор был добавлен (audit + первичный seed из
  /// env). Хранится lowercase; для бота может быть пустым/owner-email.
  String? addedByEmail;

  DateTime createdAt;

  /// Returns a shallow copy of this [SupportTeamMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SupportTeamMember copyWith({
    int? id,
    int? teamId,
    int? messengerUserId,
    _i2.SupportTeamRole? role,
    int? tier,
    String? addedByEmail,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SupportTeamMember',
      if (id != null) 'id': id,
      'teamId': teamId,
      'messengerUserId': messengerUserId,
      'role': role.toJson(),
      'tier': tier,
      if (addedByEmail != null) 'addedByEmail': addedByEmail,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SupportTeamMemberImpl extends SupportTeamMember {
  _SupportTeamMemberImpl({
    int? id,
    required int teamId,
    required int messengerUserId,
    required _i2.SupportTeamRole role,
    int? tier,
    String? addedByEmail,
    required DateTime createdAt,
  }) : super._(
         id: id,
         teamId: teamId,
         messengerUserId: messengerUserId,
         role: role,
         tier: tier,
         addedByEmail: addedByEmail,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SupportTeamMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SupportTeamMember copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? messengerUserId,
    _i2.SupportTeamRole? role,
    int? tier,
    Object? addedByEmail = _Undefined,
    DateTime? createdAt,
  }) {
    return SupportTeamMember(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      role: role ?? this.role,
      tier: tier ?? this.tier,
      addedByEmail: addedByEmail is String? ? addedByEmail : this.addedByEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
