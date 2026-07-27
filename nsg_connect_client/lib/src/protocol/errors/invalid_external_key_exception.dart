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

/// Внешний ключ не годится: ключ попадает в URL-ы, конфиги интеграторов и
/// в localpart matrix-пользователей, поэтому строчная латиница, цифры,
/// `_`/`-`, начало — буква или цифра.
abstract class InvalidExternalKeyException
    implements _i1.SerializableException, _i1.SerializableModel {
  InvalidExternalKeyException._({required this.externalKey});

  factory InvalidExternalKeyException({required String externalKey}) =
      _InvalidExternalKeyExceptionImpl;

  factory InvalidExternalKeyException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InvalidExternalKeyException(
      externalKey: jsonSerialization['externalKey'] as String,
    );
  }

  String externalKey;

  /// Returns a shallow copy of this [InvalidExternalKeyException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InvalidExternalKeyException copyWith({String? externalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvalidExternalKeyException',
      'externalKey': externalKey,
    };
  }

  @override
  String toString() {
    return 'InvalidExternalKeyException(externalKey: $externalKey)';
  }
}

class _InvalidExternalKeyExceptionImpl extends InvalidExternalKeyException {
  _InvalidExternalKeyExceptionImpl({required String externalKey})
    : super._(externalKey: externalKey);

  /// Returns a shallow copy of this [InvalidExternalKeyException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InvalidExternalKeyException copyWith({String? externalKey}) {
    return InvalidExternalKeyException(
      externalKey: externalKey ?? this.externalKey,
    );
  }
}
