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

/// Edit / delete недоступен для данного matrixEventId: либо не
/// существует (или caller не имеет доступа к комнате), либо
/// `event.sender != caller.matrixUserId` (TASK37 plan Q2 — own
/// only authorization).
///
/// Один и тот же error shape для обоих случаев (anti-enumeration —
/// mirrors [RoomUnavailableException]). Attacker не может probe
/// message ids через diff между «not exists» и «not yours» — single
/// `WHERE matrixEventId AND sender == caller` в proxy logic.
///
/// Cross-user delete (kick spam, moderation) — TASK29 через
/// `m.power_levels.redact` parsing; на TASK37 закрыта own-only
/// семантика.
abstract class MessageNotEditableException
    implements _i1.SerializableException, _i1.SerializableModel {
  MessageNotEditableException._();

  factory MessageNotEditableException() = _MessageNotEditableExceptionImpl;

  factory MessageNotEditableException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessageNotEditableException();
  }

  /// Returns a shallow copy of this [MessageNotEditableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessageNotEditableException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'MessageNotEditableException'};
  }

  @override
  String toString() {
    return 'MessageNotEditableException';
  }
}

class _MessageNotEditableExceptionImpl extends MessageNotEditableException {
  _MessageNotEditableExceptionImpl() : super._();

  /// Returns a shallow copy of this [MessageNotEditableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessageNotEditableException copyWith() {
    return MessageNotEditableException();
  }
}
