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

abstract class CrmInputInvalid
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmInputInvalid._({
    required this.field,
    required this.maxLength,
  });

  factory CrmInputInvalid({
    required String field,
    required int maxLength,
  }) = _CrmInputInvalidImpl;

  factory CrmInputInvalid.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmInputInvalid(
      field: jsonSerialization['field'] as String,
      maxLength: jsonSerialization['maxLength'] as int,
    );
  }

  String field;

  int maxLength;

  /// Returns a shallow copy of this [CrmInputInvalid]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmInputInvalid copyWith({
    String? field,
    int? maxLength,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmInputInvalid',
      'field': field,
      'maxLength': maxLength,
    };
  }

  @override
  String toString() {
    return 'CrmInputInvalid(field: $field, maxLength: $maxLength)';
  }
}

class _CrmInputInvalidImpl extends CrmInputInvalid {
  _CrmInputInvalidImpl({
    required String field,
    required int maxLength,
  }) : super._(
         field: field,
         maxLength: maxLength,
       );

  /// Returns a shallow copy of this [CrmInputInvalid]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmInputInvalid copyWith({
    String? field,
    int? maxLength,
  }) {
    return CrmInputInvalid(
      field: field ?? this.field,
      maxLength: maxLength ?? this.maxLength,
    );
  }
}
