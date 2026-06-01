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

/// Email auth specific failure — отдельный typed exception, чтобы
/// клиент мог отличить от generic InvalidTokenException.
///
/// **Reasons**:
///   * `email_already_taken` — signUp с email, который уже зарегистрирован
///     в этом tenant-е.
///   * `email_invalid_format` — не похоже на email.
///   * `password_too_short` — пароль < 8 chars.
///   * `account_not_found` — signIn с несуществующим email.
///   * `invalid_password` — signIn с неправильным паролем.
///
/// Anti-enumeration: на signIn НЕ должны раскрывать какой именно из
/// {account_not_found, invalid_password} вернулся — клиент видит
/// generic `invalid_credentials`. Это поле reason на serverside для
/// метрик/логов, а wire-DTO унифицирована.
abstract class EmailAuthException
    implements _i1.SerializableException, _i1.SerializableModel {
  EmailAuthException._({required this.reason});

  factory EmailAuthException({required String reason}) =
      _EmailAuthExceptionImpl;

  factory EmailAuthException.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmailAuthException(reason: jsonSerialization['reason'] as String);
  }

  String reason;

  /// Returns a shallow copy of this [EmailAuthException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmailAuthException copyWith({String? reason});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmailAuthException',
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'EmailAuthException(reason: $reason)';
  }
}

class _EmailAuthExceptionImpl extends EmailAuthException {
  _EmailAuthExceptionImpl({required String reason}) : super._(reason: reason);

  /// Returns a shallow copy of this [EmailAuthException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmailAuthException copyWith({String? reason}) {
    return EmailAuthException(reason: reason ?? this.reason);
  }
}
