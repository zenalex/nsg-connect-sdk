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

/// TASK95 CRM errors. Access denied is identical for absent and forbidden objects.
abstract class CrmAccessDenied
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmAccessDenied._({String? message})
    : message = message ?? 'CRM access denied';

  factory CrmAccessDenied({String? message}) = _CrmAccessDeniedImpl;

  factory CrmAccessDenied.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmAccessDenied(message: jsonSerialization['message'] as String?);
  }

  String message;

  /// Returns a shallow copy of this [CrmAccessDenied]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmAccessDenied copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmAccessDenied',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'CrmAccessDenied(message: $message)';
  }
}

class _CrmAccessDeniedImpl extends CrmAccessDenied {
  _CrmAccessDeniedImpl({String? message}) : super._(message: message);

  /// Returns a shallow copy of this [CrmAccessDenied]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmAccessDenied copyWith({String? message}) {
    return CrmAccessDenied(message: message ?? this.message);
  }
}
