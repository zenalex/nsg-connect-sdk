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

/// accessToken отвергнут CustomerAuthAdapter-ом.
/// `reason` — короткое неконфиденциальное описание (не содержит сам токен).
abstract class InvalidTokenException
    implements _i1.SerializableException, _i1.SerializableModel {
  InvalidTokenException._({required this.reason});

  factory InvalidTokenException({required String reason}) =
      _InvalidTokenExceptionImpl;

  factory InvalidTokenException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InvalidTokenException(reason: jsonSerialization['reason'] as String);
  }

  String reason;

  /// Returns a shallow copy of this [InvalidTokenException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InvalidTokenException copyWith({String? reason});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvalidTokenException',
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'InvalidTokenException(reason: $reason)';
  }
}

class _InvalidTokenExceptionImpl extends InvalidTokenException {
  _InvalidTokenExceptionImpl({required String reason})
    : super._(reason: reason);

  /// Returns a shallow copy of this [InvalidTokenException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InvalidTokenException copyWith({String? reason}) {
    return InvalidTokenException(reason: reason ?? this.reason);
  }
}
