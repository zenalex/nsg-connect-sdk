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

/// Ключ продукта не опознаёт команду однозначно — нужен тенант.
///
/// Ключ продукта уникален только ВНУТРИ тенанта: `titan112_operator`
/// законно живёт и в `titan`, и в `titan112`. Если вызывающий состоит в
/// командах обоих, поиск «по ключу» не может выбрать за него.
///
/// Раньше в этом месте молча бралась первая попавшаяся команда — админка
/// показывала состав ЧУЖОГО тенанта (5 участников вместо 1), и тем же
/// путём резолвились записи: добавленный оператор мог уехать в чужой
/// тенант. Отказ лучше тихой подмены: вызывающий обязан назвать тенант.
abstract class AmbiguousProductKeyException
    implements _i1.SerializableException, _i1.SerializableModel {
  AmbiguousProductKeyException._({required this.productExternalKey});

  factory AmbiguousProductKeyException({required String productExternalKey}) =
      _AmbiguousProductKeyExceptionImpl;

  factory AmbiguousProductKeyException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AmbiguousProductKeyException(
      productExternalKey: jsonSerialization['productExternalKey'] as String,
    );
  }

  String productExternalKey;

  /// Returns a shallow copy of this [AmbiguousProductKeyException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AmbiguousProductKeyException copyWith({String? productExternalKey});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AmbiguousProductKeyException',
      'productExternalKey': productExternalKey,
    };
  }

  @override
  String toString() {
    return 'AmbiguousProductKeyException(productExternalKey: $productExternalKey)';
  }
}

class _AmbiguousProductKeyExceptionImpl extends AmbiguousProductKeyException {
  _AmbiguousProductKeyExceptionImpl({required String productExternalKey})
    : super._(productExternalKey: productExternalKey);

  /// Returns a shallow copy of this [AmbiguousProductKeyException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AmbiguousProductKeyException copyWith({String? productExternalKey}) {
    return AmbiguousProductKeyException(
      productExternalKey: productExternalKey ?? this.productExternalKey,
    );
  }
}
