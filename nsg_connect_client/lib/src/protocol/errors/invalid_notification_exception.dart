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

/// **TASK72**: вход `ProductNotificationEndpoint.send` не прошёл
/// валидацию (пустой список адресатов, пустой контент, слишком длинный
/// текст и т.п.). В отличие от авторизационных отказов это НЕ секретная
/// информация — вызывающий продукт «свой», ему возвращаем внятную
/// причину, чтобы он поправил вызов.
/// `reason` — короткий машиночитаемый код (`empty_recipients`,
/// `empty_content`, `text_too_long`, `too_many_recipients`, …).
abstract class InvalidNotificationException
    implements _i1.SerializableException, _i1.SerializableModel {
  InvalidNotificationException._({required this.reason});

  factory InvalidNotificationException({required String reason}) =
      _InvalidNotificationExceptionImpl;

  factory InvalidNotificationException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InvalidNotificationException(
      reason: jsonSerialization['reason'] as String,
    );
  }

  String reason;

  /// Returns a shallow copy of this [InvalidNotificationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InvalidNotificationException copyWith({String? reason});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvalidNotificationException',
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'InvalidNotificationException(reason: $reason)';
  }
}

class _InvalidNotificationExceptionImpl extends InvalidNotificationException {
  _InvalidNotificationExceptionImpl({required String reason})
    : super._(reason: reason);

  /// Returns a shallow copy of this [InvalidNotificationException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InvalidNotificationException copyWith({String? reason}) {
    return InvalidNotificationException(reason: reason ?? this.reason);
  }
}
