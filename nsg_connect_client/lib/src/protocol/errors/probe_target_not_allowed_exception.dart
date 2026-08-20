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

/// **TASK94 §2**: адрес не годится для allowlist проб.
///
/// Отдельное исключение, а не общий отказ: здесь ошибается администратор,
/// который ЗНАЕТ, что делает, и ему нужно сказать, что именно не так.
/// Anti-enumeration тут не при чём — таблица и так видна только супер-админу
/// платформы, скрывать от него причину не от кого.
///
/// Строка `127.0.0.1:8896` завелась бы и без этой проверки: проба по ней всё
/// равно никуда не пойдёт (запреты сильнее allowlist). Но тогда запись лежит
/// в таблице, выглядит разрешением и молча не работает, а разбираться будет
/// человек с жалобой «монитор красный, хотя адрес добавлен».
abstract class ProbeTargetNotAllowedException
    implements _i1.SerializableException, _i1.SerializableModel {
  ProbeTargetNotAllowedException._({
    required this.address,
    required this.reason,
  });

  factory ProbeTargetNotAllowedException({
    required String address,
    required String reason,
  }) = _ProbeTargetNotAllowedExceptionImpl;

  factory ProbeTargetNotAllowedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProbeTargetNotAllowedException(
      address: jsonSerialization['address'] as String,
      reason: jsonSerialization['reason'] as String,
    );
  }

  /// Что вводили.
  String address;

  /// Машинная причина: `loopback` | `private` | `linkLocal` | `multicast` |
  /// `unspecified` | `malformed` | `badPort` | `badPrefix`.
  String reason;

  /// Returns a shallow copy of this [ProbeTargetNotAllowedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProbeTargetNotAllowedException copyWith({
    String? address,
    String? reason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProbeTargetNotAllowedException',
      'address': address,
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'ProbeTargetNotAllowedException(address: $address, reason: $reason)';
  }
}

class _ProbeTargetNotAllowedExceptionImpl
    extends ProbeTargetNotAllowedException {
  _ProbeTargetNotAllowedExceptionImpl({
    required String address,
    required String reason,
  }) : super._(
         address: address,
         reason: reason,
       );

  /// Returns a shallow copy of this [ProbeTargetNotAllowedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProbeTargetNotAllowedException copyWith({
    String? address,
    String? reason,
  }) {
    return ProbeTargetNotAllowedException(
      address: address ?? this.address,
      reason: reason ?? this.reason,
    );
  }
}
