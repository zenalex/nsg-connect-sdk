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

/// **TASK43**: caller — участник команды, но НЕ её владелец (`owner`),
/// поэтому не может менять состав (`addSupportTeamMember` /
/// `removeSupportTeamMember`). Отличается от
/// [NotSupportTeamMemberException]: тут caller имеет право видеть
/// команду, но не управлять ею — SDK показывает экран read-only.
abstract class NotSupportTeamOwnerException
    implements _i1.SerializableException, _i1.SerializableModel {
  NotSupportTeamOwnerException._();

  factory NotSupportTeamOwnerException() = _NotSupportTeamOwnerExceptionImpl;

  factory NotSupportTeamOwnerException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotSupportTeamOwnerException();
  }

  /// Returns a shallow copy of this [NotSupportTeamOwnerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotSupportTeamOwnerException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'NotSupportTeamOwnerException'};
  }

  @override
  String toString() {
    return 'NotSupportTeamOwnerException';
  }
}

class _NotSupportTeamOwnerExceptionImpl extends NotSupportTeamOwnerException {
  _NotSupportTeamOwnerExceptionImpl() : super._();

  /// Returns a shallow copy of this [NotSupportTeamOwnerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotSupportTeamOwnerException copyWith() {
    return NotSupportTeamOwnerException();
  }
}
