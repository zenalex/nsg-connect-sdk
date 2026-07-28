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

/// Email оператора не резолвится в пользователя мессенджера.
/// Отдельное исключение (не общий отказ): платформенному админу «нет
/// такого пользователя» и «человек ни разу не входил» требуют разных
/// действий, а anti-enumeration тут не нужен — он и так видит все тенанты.
abstract class OperatorEmailNotResolvedException
    implements _i1.SerializableException, _i1.SerializableModel {
  OperatorEmailNotResolvedException._({required this.email});

  factory OperatorEmailNotResolvedException({required String email}) =
      _OperatorEmailNotResolvedExceptionImpl;

  factory OperatorEmailNotResolvedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OperatorEmailNotResolvedException(
      email: jsonSerialization['email'] as String,
    );
  }

  String email;

  /// Returns a shallow copy of this [OperatorEmailNotResolvedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OperatorEmailNotResolvedException copyWith({String? email});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OperatorEmailNotResolvedException',
      'email': email,
    };
  }

  @override
  String toString() {
    return 'OperatorEmailNotResolvedException(email: $email)';
  }
}

class _OperatorEmailNotResolvedExceptionImpl
    extends OperatorEmailNotResolvedException {
  _OperatorEmailNotResolvedExceptionImpl({required String email})
    : super._(email: email);

  /// Returns a shallow copy of this [OperatorEmailNotResolvedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OperatorEmailNotResolvedException copyWith({String? email}) {
    return OperatorEmailNotResolvedException(email: email ?? this.email);
  }
}
