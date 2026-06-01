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

/// Peer messenger user недоступен — НЕ существует, **либо** существует
/// но в другом tenant-е, либо забанен/удалён. Один и тот же error
/// shape для всех трёх случаев — это **anti-enumeration**: разница в
/// ответе позволила бы атакующему скрейпить пространство messengerUserId.
///
/// Бросается из всех endpoint-ов, где caller ссылается на другого
/// messenger user-а по id (createDirect, createGroup, getOrCreateProductRoom
/// при invite, и др.).
///
/// **Без полей.** Сознательно — любое поле раскрывает информацию о
/// цели. Если SDK-у нужен hint для UI («может ввели не тот id?»), он
/// это решает по контексту вызова, не из exception-а.
abstract class PeerUnavailableException
    implements _i1.SerializableException, _i1.SerializableModel {
  PeerUnavailableException._();

  factory PeerUnavailableException() = _PeerUnavailableExceptionImpl;

  factory PeerUnavailableException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PeerUnavailableException();
  }

  /// Returns a shallow copy of this [PeerUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PeerUnavailableException copyWith();
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'PeerUnavailableException'};
  }

  @override
  String toString() {
    return 'PeerUnavailableException';
  }
}

class _PeerUnavailableExceptionImpl extends PeerUnavailableException {
  _PeerUnavailableExceptionImpl() : super._();

  /// Returns a shallow copy of this [PeerUnavailableException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PeerUnavailableException copyWith() {
    return PeerUnavailableException();
  }
}
