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

/// Продукт с таким externalKey уже есть В ЭТОМ tenant-е.
/// Уникальность именно в пределах tenant-а: `support` у двух заказчиков —
/// норма, два `support` внутри одного сделали бы адресацию неоднозначной.
abstract class ProductAlreadyExistsException
    implements _i1.SerializableException, _i1.SerializableModel {
  ProductAlreadyExistsException._({required this.productExternalKey});

  factory ProductAlreadyExistsException({required String productExternalKey}) =
      _ProductAlreadyExistsExceptionImpl;

  factory ProductAlreadyExistsException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductAlreadyExistsException(
      productExternalKey: jsonSerialization['productExternalKey'] as String,
    );
  }

  String productExternalKey;

  /// Returns a shallow copy of this [ProductAlreadyExistsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductAlreadyExistsException copyWith({String? productExternalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductAlreadyExistsException',
      'productExternalKey': productExternalKey,
    };
  }

  @override
  String toString() {
    return 'ProductAlreadyExistsException(productExternalKey: $productExternalKey)';
  }
}

class _ProductAlreadyExistsExceptionImpl extends ProductAlreadyExistsException {
  _ProductAlreadyExistsExceptionImpl({required String productExternalKey})
    : super._(productExternalKey: productExternalKey);

  /// Returns a shallow copy of this [ProductAlreadyExistsException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductAlreadyExistsException copyWith({String? productExternalKey}) {
    return ProductAlreadyExistsException(
      productExternalKey: productExternalKey ?? this.productExternalKey,
    );
  }
}
