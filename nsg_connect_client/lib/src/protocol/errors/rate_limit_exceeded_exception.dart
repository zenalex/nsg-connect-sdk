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

/// **B6 (BACKLOG)**: rate-limit exceeded на anti-abuse endpoint-ах
/// (resendVerification, requestPasswordReset, possibly others).
///
/// Поле `retryAfterSeconds` подсказывает клиенту когда можно повторить.
/// SDK показывает snackbar «Попробуйте через N секунд» + блокирует
/// кнопку до истечения.
///
/// **Anti-enumeration**: один и тот же exception бросается независимо
/// от того, существует ли email/account. Атакующий не может через 429
/// enumerate registered emails.
abstract class RateLimitExceededException
    implements _i1.SerializableException, _i1.SerializableModel {
  RateLimitExceededException._({
    required this.retryAfterSeconds,
    required this.operation,
  });

  factory RateLimitExceededException({
    required int retryAfterSeconds,
    required String operation,
  }) = _RateLimitExceededExceptionImpl;

  factory RateLimitExceededException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RateLimitExceededException(
      retryAfterSeconds: jsonSerialization['retryAfterSeconds'] as int,
      operation: jsonSerialization['operation'] as String,
    );
  }

  /// Через сколько секунд можно повторить. >=1.
  int retryAfterSeconds;

  /// Operation marker — `'resend_verification'` / `'password_reset'` /
  /// произвольная строка. Используется клиентом для контекстного
  /// UX-сообщения (разные snackbar-ы для разных endpoint-ов).
  String operation;

  /// Returns a shallow copy of this [RateLimitExceededException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RateLimitExceededException copyWith({
    int? retryAfterSeconds,
    String? operation,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RateLimitExceededException',
      'retryAfterSeconds': retryAfterSeconds,
      'operation': operation,
    };
  }

  @override
  String toString() {
    return 'RateLimitExceededException(retryAfterSeconds: $retryAfterSeconds, operation: $operation)';
  }
}

class _RateLimitExceededExceptionImpl extends RateLimitExceededException {
  _RateLimitExceededExceptionImpl({
    required int retryAfterSeconds,
    required String operation,
  }) : super._(
         retryAfterSeconds: retryAfterSeconds,
         operation: operation,
       );

  /// Returns a shallow copy of this [RateLimitExceededException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RateLimitExceededException copyWith({
    int? retryAfterSeconds,
    String? operation,
  }) {
    return RateLimitExceededException(
      retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
      operation: operation ?? this.operation,
    );
  }
}
