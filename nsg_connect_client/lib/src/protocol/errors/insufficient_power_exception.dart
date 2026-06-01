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

/// **TASK29**: caller не имеет достаточной power level в комнате для
/// admin/moderation action — kick/ban/unban требуют `role >= admin`
/// (PL >= 50); setRoomMemberRole требует `role == owner` (PL >= 100).
///
/// Бросается из [RoomAdminService] при authorization mismatch.
/// Anti-enumeration consistent с peer/room exceptions: caller не
/// может distinguish «room exists с другим membership» vs «caller
/// не member» vs «caller member но недостаточно роли» — все три
/// upstream разветвляются в этот exception.
///
/// **Без полей.** Любое поле раскрывает internal state — даже
/// текущий PL caller-а или required PL — это hint о структуре
/// authorization. SDK получает opaque «not authorized», UI рендерит
/// generic message.
abstract class InsufficientPowerException
    implements _i1.SerializableException, _i1.SerializableModel {
  InsufficientPowerException._();

  factory InsufficientPowerException() = _InsufficientPowerExceptionImpl;

  factory InsufficientPowerException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InsufficientPowerException();
  }

  /// Returns a shallow copy of this [InsufficientPowerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InsufficientPowerException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'InsufficientPowerException'};
  }

  @override
  String toString() {
    return 'InsufficientPowerException';
  }
}

class _InsufficientPowerExceptionImpl extends InsufficientPowerException {
  _InsufficientPowerExceptionImpl() : super._();

  /// Returns a shallow copy of this [InsufficientPowerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InsufficientPowerException copyWith() {
    return InsufficientPowerException();
  }
}
