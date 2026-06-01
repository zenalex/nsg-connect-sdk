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

/// Для tenant-а не зарегистрирован CustomerAuthAdapter.
/// Конфигурация адаптеров — TASK24 (config-driven loader).
abstract class AdapterNotConfiguredException
    implements _i1.SerializableException, _i1.SerializableModel {
  AdapterNotConfiguredException._({required this.tenantExternalKey});

  factory AdapterNotConfiguredException({required String tenantExternalKey}) =
      _AdapterNotConfiguredExceptionImpl;

  factory AdapterNotConfiguredException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AdapterNotConfiguredException(
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
    );
  }

  String tenantExternalKey;

  /// Returns a shallow copy of this [AdapterNotConfiguredException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdapterNotConfiguredException copyWith({String? tenantExternalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdapterNotConfiguredException',
      'tenantExternalKey': tenantExternalKey,
    };
  }

  @override
  String toString() {
    return 'AdapterNotConfiguredException(tenantExternalKey: $tenantExternalKey)';
  }
}

class _AdapterNotConfiguredExceptionImpl extends AdapterNotConfiguredException {
  _AdapterNotConfiguredExceptionImpl({required String tenantExternalKey})
    : super._(tenantExternalKey: tenantExternalKey);

  /// Returns a shallow copy of this [AdapterNotConfiguredException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdapterNotConfiguredException copyWith({String? tenantExternalKey}) {
    return AdapterNotConfiguredException(
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
    );
  }
}
