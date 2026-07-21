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

/// **TASK45 фаза 2**: эскалация «Обратиться к разработчикам» вызвана для
/// комнаты, которая не является объектовой (productRoom с
/// entityType='object'). Эскалация подключает команду продукта только к
/// объектовым чатам — для support-комнат команда и так входит при
/// создании, для direct/group эскалация не имеет смысла.
///
/// SDK показывает кнопку только для объектовых комнат, поэтому в норме
/// это исключение не возникает; оно — server-side защита от вызова RPC
/// напрямую.
abstract class NotObjectRoomException
    implements _i1.SerializableException, _i1.SerializableModel {
  NotObjectRoomException._();

  factory NotObjectRoomException() = _NotObjectRoomExceptionImpl;

  factory NotObjectRoomException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotObjectRoomException();
  }

  /// Returns a shallow copy of this [NotObjectRoomException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotObjectRoomException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'NotObjectRoomException'};
  }

  @override
  String toString() {
    return 'NotObjectRoomException';
  }
}

class _NotObjectRoomExceptionImpl extends NotObjectRoomException {
  _NotObjectRoomExceptionImpl() : super._();

  /// Returns a shallow copy of this [NotObjectRoomException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotObjectRoomException copyWith() {
    return NotObjectRoomException();
  }
}
