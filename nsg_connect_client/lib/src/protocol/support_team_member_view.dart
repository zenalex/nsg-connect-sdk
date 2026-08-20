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

/// **TASK43**: один участник команды поддержки для SDK-экрана
/// «Команда поддержки». Transient DTO (не table), собирается в
/// `SupportTeamService` из [SupportTeamMember] + [MessengerUser].
abstract class SupportTeamMemberView implements _i1.SerializableModel {
  SupportTeamMemberView._({
    required this.messengerUserId,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.tier,
    required this.isBot,
    this.email,
    bool? inherited,
  }) : inherited = inherited ?? false;

  factory SupportTeamMemberView({
    required int messengerUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.SupportTeamRole role,
    required int tier,
    required bool isBot,
    String? email,
    bool? inherited,
  }) = _SupportTeamMemberViewImpl;

  factory SupportTeamMemberView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SupportTeamMemberView(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: _i2.SupportTeamRole.fromJson((jsonSerialization['role'] as String)),
      tier: jsonSerialization['tier'] as int,
      isBot: _i1.BoolJsonExtension.fromJson(jsonSerialization['isBot']),
      email: jsonSerialization['email'] as String?,
      inherited: jsonSerialization['inherited'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['inherited']),
    );
  }

  int messengerUserId;

  String? displayName;

  String? avatarUrl;

  _i2.SupportTeamRole role;

  /// **TASK48**: тир оператора (1 = фронт-линия, 2 = эскалация). Для
  /// бота значение не используется (бот вне тиринга). UI показывает/
  /// редактирует уровень человека.
  int tier;

  /// Признак бота (ParticipantKind / наличие Bot-записи) — UI рисует
  /// иконку бота вместо аватара и не даёт его «удалить как человека»
  /// без явного подтверждения.
  bool isBot;

  /// Email, по которому добавлен (audit; для бота может быть null).
  String? email;

  /// **Откуда человек в этой команде.** true — он не вписан в команду, а
  /// унаследован от тенанта (список поддержки заказчика). Экран обязан это
  /// показывать: у унаследованного другое удаление (исключить в этом
  /// продукте или убрать из тенанта во всех), и без пометки владелец жал бы
  /// «убрать» и не понимал, почему человек вернулся.
  bool inherited;

  /// Returns a shallow copy of this [SupportTeamMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SupportTeamMemberView copyWith({
    int? messengerUserId,
    String? displayName,
    String? avatarUrl,
    _i2.SupportTeamRole? role,
    int? tier,
    bool? isBot,
    String? email,
    bool? inherited,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SupportTeamMemberView',
      'messengerUserId': messengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role.toJson(),
      'tier': tier,
      'isBot': isBot,
      if (email != null) 'email': email,
      'inherited': inherited,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SupportTeamMemberViewImpl extends SupportTeamMemberView {
  _SupportTeamMemberViewImpl({
    required int messengerUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.SupportTeamRole role,
    required int tier,
    required bool isBot,
    String? email,
    bool? inherited,
  }) : super._(
         messengerUserId: messengerUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
         role: role,
         tier: tier,
         isBot: isBot,
         email: email,
         inherited: inherited,
       );

  /// Returns a shallow copy of this [SupportTeamMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SupportTeamMemberView copyWith({
    int? messengerUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    _i2.SupportTeamRole? role,
    int? tier,
    bool? isBot,
    Object? email = _Undefined,
    bool? inherited,
  }) {
    return SupportTeamMemberView(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
      tier: tier ?? this.tier,
      isBot: isBot ?? this.isBot,
      email: email is String? ? email : this.email,
      inherited: inherited ?? this.inherited,
    );
  }
}
