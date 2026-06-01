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

/// Room недоступна caller-у: НЕ существует, существует в другом tenant-е,
/// либо caller не состоит в её membership. Один и тот же error shape
/// (anti-enumeration), симметрично с [PeerUnavailableException].
///
/// Бросается из read-by-id endpoint-ов: getRoom, listMessages, и др.
/// `getRoom(roomId)` — целенаправленный read по известному id (deep-link
/// из push, переход из listRooms), и UI должен мочь показать
/// осмысленный «комната недоступна» — поэтому typed exception, а
/// не silent null. Без полей — anti-enumeration сохранён.
abstract class RoomUnavailableException
    implements _i1.SerializableException, _i1.SerializableModel {
  RoomUnavailableException._();

  factory RoomUnavailableException() = _RoomUnavailableExceptionImpl;

  factory RoomUnavailableException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RoomUnavailableException();
  }

  /// Returns a shallow copy of this [RoomUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomUnavailableException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'RoomUnavailableException'};
  }

  @override
  String toString() {
    return 'RoomUnavailableException';
  }
}

class _RoomUnavailableExceptionImpl extends RoomUnavailableException {
  _RoomUnavailableExceptionImpl() : super._();

  /// Returns a shallow copy of this [RoomUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomUnavailableException copyWith() {
    return RoomUnavailableException();
  }
}
