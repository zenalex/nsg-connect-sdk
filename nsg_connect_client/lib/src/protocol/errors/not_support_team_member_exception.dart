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

/// **TASK43**: caller не участник команды поддержки продукта (и не бот
/// этой команды) — доступ к `getSupportTeam` запрещён. SDK использует
/// НЕ-исключение как гейт: если getSupportTeam вернул view — экран
/// «Команда поддержки» доступен; это исключение → экран скрыт.
///
/// **Без полей** — anti-enumeration: не раскрываем ни существование
/// команды, ни её продукт. Тот же shape, что для «команды нет вовсе».
abstract class NotSupportTeamMemberException
    implements _i1.SerializableException, _i1.SerializableModel {
  NotSupportTeamMemberException._();

  factory NotSupportTeamMemberException() = _NotSupportTeamMemberExceptionImpl;

  factory NotSupportTeamMemberException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotSupportTeamMemberException();
  }

  /// Returns a shallow copy of this [NotSupportTeamMemberException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotSupportTeamMemberException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'NotSupportTeamMemberException'};
  }

  @override
  String toString() {
    return 'NotSupportTeamMemberException';
  }
}

class _NotSupportTeamMemberExceptionImpl extends NotSupportTeamMemberException {
  _NotSupportTeamMemberExceptionImpl() : super._();

  /// Returns a shallow copy of this [NotSupportTeamMemberException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotSupportTeamMemberException copyWith() {
    return NotSupportTeamMemberException();
  }
}
