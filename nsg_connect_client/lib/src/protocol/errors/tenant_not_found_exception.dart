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

/// Tenant с заданным externalKey не найден.
/// Serverpod-`exception:` сериализуется и доходит до клиента типизированно.
abstract class TenantNotFoundException
    implements _i1.SerializableException, _i1.SerializableModel {
  TenantNotFoundException._({required this.tenantExternalKey});

  factory TenantNotFoundException({required String tenantExternalKey}) =
      _TenantNotFoundExceptionImpl;

  factory TenantNotFoundException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TenantNotFoundException(
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
    );
  }

  String tenantExternalKey;

  /// Returns a shallow copy of this [TenantNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TenantNotFoundException copyWith({String? tenantExternalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TenantNotFoundException',
      'tenantExternalKey': tenantExternalKey,
    };
  }

  @override
  String toString() {
    return 'TenantNotFoundException(tenantExternalKey: $tenantExternalKey)';
  }
}

class _TenantNotFoundExceptionImpl extends TenantNotFoundException {
  _TenantNotFoundExceptionImpl({required String tenantExternalKey})
    : super._(tenantExternalKey: tenantExternalKey);

  /// Returns a shallow copy of this [TenantNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TenantNotFoundException copyWith({String? tenantExternalKey}) {
    return TenantNotFoundException(
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
    );
  }
}
