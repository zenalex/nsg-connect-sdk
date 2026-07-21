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
import 'product_notification_recipient_result.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **TASK72**: ответ `ProductNotificationEndpoint.send` на весь batch.
/// Агрегаты (для счётчиков/логов продукта) + по-адресатная разбивка.
abstract class ProductNotificationSendResult implements _i1.SerializableModel {
  ProductNotificationSendResult._({
    required this.accepted,
    required this.deduped,
    required this.noDevices,
    required this.results,
  });

  factory ProductNotificationSendResult({
    required int accepted,
    required int deduped,
    required int noDevices,
    required List<_i2.ProductNotificationRecipientResult> results,
  }) = _ProductNotificationSendResultImpl;

  factory ProductNotificationSendResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductNotificationSendResult(
      accepted: jsonSerialization['accepted'] as int,
      deduped: jsonSerialization['deduped'] as int,
      noDevices: jsonSerialization['noDevices'] as int,
      results: _i3.Protocol()
          .deserialize<List<_i2.ProductNotificationRecipientResult>>(
            jsonSerialization['results'],
          ),
    );
  }

  /// Приняты и поставлены в очередь (status delivered).
  int accepted;

  /// Схлопнуты дедупом (повтор idempotencyKey).
  int deduped;

  /// Без единого подходящего устройства.
  int noDevices;

  /// По-адресатная детализация (порядок соответствует входному списку).
  List<_i2.ProductNotificationRecipientResult> results;

  /// Returns a shallow copy of this [ProductNotificationSendResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductNotificationSendResult copyWith({
    int? accepted,
    int? deduped,
    int? noDevices,
    List<_i2.ProductNotificationRecipientResult>? results,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductNotificationSendResult',
      'accepted': accepted,
      'deduped': deduped,
      'noDevices': noDevices,
      'results': results.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ProductNotificationSendResultImpl extends ProductNotificationSendResult {
  _ProductNotificationSendResultImpl({
    required int accepted,
    required int deduped,
    required int noDevices,
    required List<_i2.ProductNotificationRecipientResult> results,
  }) : super._(
         accepted: accepted,
         deduped: deduped,
         noDevices: noDevices,
         results: results,
       );

  /// Returns a shallow copy of this [ProductNotificationSendResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductNotificationSendResult copyWith({
    int? accepted,
    int? deduped,
    int? noDevices,
    List<_i2.ProductNotificationRecipientResult>? results,
  }) {
    return ProductNotificationSendResult(
      accepted: accepted ?? this.accepted,
      deduped: deduped ?? this.deduped,
      noDevices: noDevices ?? this.noDevices,
      results: results ?? this.results.map((e0) => e0.copyWith()).toList(),
    );
  }
}
