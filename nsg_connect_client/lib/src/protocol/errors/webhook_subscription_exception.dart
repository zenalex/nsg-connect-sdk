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

/// Stable RPC validation code; no subscription IDs or secrets in the error.
abstract class WebhookSubscriptionException
    implements _i1.SerializableException, _i1.SerializableModel {
  WebhookSubscriptionException._({required this.code});

  factory WebhookSubscriptionException({required String code}) =
      _WebhookSubscriptionExceptionImpl;

  factory WebhookSubscriptionException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WebhookSubscriptionException(
      code: jsonSerialization['code'] as String,
    );
  }

  String code;

  /// Returns a shallow copy of this [WebhookSubscriptionException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookSubscriptionException copyWith({String? code});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookSubscriptionException',
      'code': code,
    };
  }

  @override
  String toString() {
    return 'WebhookSubscriptionException(code: $code)';
  }
}

class _WebhookSubscriptionExceptionImpl extends WebhookSubscriptionException {
  _WebhookSubscriptionExceptionImpl({required String code})
    : super._(code: code);

  /// Returns a shallow copy of this [WebhookSubscriptionException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookSubscriptionException copyWith({String? code}) {
    return WebhookSubscriptionException(code: code ?? this.code);
  }
}
