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

/// **TASK29**: попытка demote последнего owner-а в admin/member —
/// блокируется server-side в [RoomAdminService.setRoomMemberRole].
/// Без guard-а комната оказывается без owner-а: никто не может
/// promote-нуть нового owner-а (нужны owner privs), и tenant теряет
/// admin-control над комнатой.
///
/// **Transactional check** (`session.db.transaction`):
/// `SELECT COUNT(*) FROM room_membership WHERE roomId=? AND
/// role='owner'` → если `count <= 1` И self demote — throw. Между
/// read и demote держится lock; concurrent demote двух owner-ов
/// serialized → второй correctly видит «теперь last» и rejects.
///
/// **Без полей.** Anti-enumeration consistent с
/// InsufficientPower / RoomUnavailable — SDK получает opaque
/// typed-exception, UI рендерит specific message без owner count
/// leak.
abstract class LastOwnerCannotDemoteException
    implements _i1.SerializableException, _i1.SerializableModel {
  LastOwnerCannotDemoteException._();

  factory LastOwnerCannotDemoteException() =
      _LastOwnerCannotDemoteExceptionImpl;

  factory LastOwnerCannotDemoteException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LastOwnerCannotDemoteException();
  }

  /// Returns a shallow copy of this [LastOwnerCannotDemoteException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LastOwnerCannotDemoteException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'LastOwnerCannotDemoteException'};
  }

  @override
  String toString() {
    return 'LastOwnerCannotDemoteException';
  }
}

class _LastOwnerCannotDemoteExceptionImpl
    extends LastOwnerCannotDemoteException {
  _LastOwnerCannotDemoteExceptionImpl() : super._();

  /// Returns a shallow copy of this [LastOwnerCannotDemoteException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LastOwnerCannotDemoteException copyWith() {
    return LastOwnerCannotDemoteException();
  }
}
