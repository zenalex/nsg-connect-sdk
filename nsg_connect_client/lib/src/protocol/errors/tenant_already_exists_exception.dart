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

/// Tenant с таким externalKey уже есть.
/// Отдельное исключение, а не «молча вернуть существующий»: вызывающий
/// решил бы, что завёл новый tenant, и увёл бы чужие данные в свой продукт.
abstract class TenantAlreadyExistsException
    implements _i1.SerializableException, _i1.SerializableModel {
  TenantAlreadyExistsException._({required this.tenantExternalKey});

  factory TenantAlreadyExistsException({required String tenantExternalKey}) =
      _TenantAlreadyExistsExceptionImpl;

  factory TenantAlreadyExistsException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TenantAlreadyExistsException(
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
    );
  }

  String tenantExternalKey;

  /// Returns a shallow copy of this [TenantAlreadyExistsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TenantAlreadyExistsException copyWith({String? tenantExternalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TenantAlreadyExistsException',
      'tenantExternalKey': tenantExternalKey,
    };
  }

  @override
  String toString() {
    return 'TenantAlreadyExistsException(tenantExternalKey: $tenantExternalKey)';
  }
}

class _TenantAlreadyExistsExceptionImpl extends TenantAlreadyExistsException {
  _TenantAlreadyExistsExceptionImpl({required String tenantExternalKey})
    : super._(tenantExternalKey: tenantExternalKey);

  /// Returns a shallow copy of this [TenantAlreadyExistsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TenantAlreadyExistsException copyWith({String? tenantExternalKey}) {
    return TenantAlreadyExistsException(
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
    );
  }
}
