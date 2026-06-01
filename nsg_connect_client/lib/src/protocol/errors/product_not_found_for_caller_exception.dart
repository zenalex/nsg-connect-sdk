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

/// Бросается из RoomService-методов, которые принимают
/// `productExternalKey` (getOrCreateProductRoom, openSupportChat) —
/// product не найден в tenant-е caller-а.
///
/// Отдельный тип от `ProductNotFoundException`: тот используется на
/// path-е аутентификации (TASK05 `session()`) и принимает оба ключа
/// `tenantExternalKey` + `productExternalKey` для контекста. Здесь
/// tenant у caller-а уже доказан (он аутентифицирован), и поле
/// `tenantExternalKey` было бы пустым workaround-ом — выделили
/// отдельный shape с одним полем (см. ревью fc7cbe3 #2).
abstract class ProductNotFoundForCallerException
    implements _i1.SerializableException, _i1.SerializableModel {
  ProductNotFoundForCallerException._({required this.productExternalKey});

  factory ProductNotFoundForCallerException({
    required String productExternalKey,
  }) = _ProductNotFoundForCallerExceptionImpl;

  factory ProductNotFoundForCallerException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductNotFoundForCallerException(
      productExternalKey: jsonSerialization['productExternalKey'] as String,
    );
  }

  String productExternalKey;

  /// Returns a shallow copy of this [ProductNotFoundForCallerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductNotFoundForCallerException copyWith({String? productExternalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductNotFoundForCallerException',
      'productExternalKey': productExternalKey,
    };
  }

  @override
  String toString() {
    return 'ProductNotFoundForCallerException(productExternalKey: $productExternalKey)';
  }
}

class _ProductNotFoundForCallerExceptionImpl
    extends ProductNotFoundForCallerException {
  _ProductNotFoundForCallerExceptionImpl({required String productExternalKey})
    : super._(productExternalKey: productExternalKey);

  /// Returns a shallow copy of this [ProductNotFoundForCallerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductNotFoundForCallerException copyWith({String? productExternalKey}) {
    return ProductNotFoundForCallerException(
      productExternalKey: productExternalKey ?? this.productExternalKey,
    );
  }
}
