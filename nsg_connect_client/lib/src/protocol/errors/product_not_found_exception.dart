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

/// Product с заданным externalKey не найден в указанном tenant-е.
abstract class ProductNotFoundException
    implements _i1.SerializableException, _i1.SerializableModel {
  ProductNotFoundException._({
    required this.tenantExternalKey,
    required this.productExternalKey,
  });

  factory ProductNotFoundException({
    required String tenantExternalKey,
    required String productExternalKey,
  }) = _ProductNotFoundExceptionImpl;

  factory ProductNotFoundException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductNotFoundException(
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
      productExternalKey: jsonSerialization['productExternalKey'] as String,
    );
  }

  String tenantExternalKey;

  String productExternalKey;

  /// Returns a shallow copy of this [ProductNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductNotFoundException copyWith({
    String? tenantExternalKey,
    String? productExternalKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductNotFoundException',
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
    };
  }

  @override
  String toString() {
    return 'ProductNotFoundException(tenantExternalKey: $tenantExternalKey, productExternalKey: $productExternalKey)';
  }
}

class _ProductNotFoundExceptionImpl extends ProductNotFoundException {
  _ProductNotFoundExceptionImpl({
    required String tenantExternalKey,
    required String productExternalKey,
  }) : super._(
         tenantExternalKey: tenantExternalKey,
         productExternalKey: productExternalKey,
       );

  /// Returns a shallow copy of this [ProductNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductNotFoundException copyWith({
    String? tenantExternalKey,
    String? productExternalKey,
  }) {
    return ProductNotFoundException(
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
      productExternalKey: productExternalKey ?? this.productExternalKey,
    );
  }
}
