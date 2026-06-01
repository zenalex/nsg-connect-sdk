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

/// Edit attempt для own-deleted message. В отличие от
/// [MessageNotEditableException] (anti-enumeration — могут быть
/// foreign messages), здесь точно known: caller является owner,
/// message exists, но был redacted (deletedAt non-null).
///
/// Useful UI feedback — «message was deleted, can't edit» — SDK
/// показывает snackbar; tombstone bubble уже visible.
///
/// **Idempotency contrast** (TASK37 plan):
///   * `deleteMessage` для already-deleted → silent success (как
///     unmute idempotent — same end state).
///   * `editMessage` для already-deleted → этот exception. Edit
///     deleted message изменить не может.
abstract class MessageDeletedException
    implements _i1.SerializableException, _i1.SerializableModel {
  MessageDeletedException._();

  factory MessageDeletedException() = _MessageDeletedExceptionImpl;

  factory MessageDeletedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessageDeletedException();
  }

  /// Returns a shallow copy of this [MessageDeletedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessageDeletedException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'MessageDeletedException'};
  }

  @override
  String toString() {
    return 'MessageDeletedException';
  }
}

class _MessageDeletedExceptionImpl extends MessageDeletedException {
  _MessageDeletedExceptionImpl() : super._();

  /// Returns a shallow copy of this [MessageDeletedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessageDeletedException copyWith() {
    return MessageDeletedException();
  }
}
