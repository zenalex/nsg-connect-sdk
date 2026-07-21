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
import 'enums/product_notification_status.dart' as _i2;

/// **TASK72**: результат приёма уведомления для ОДНОГО адресата batch-а.
/// Продукт видит по-адресатный исход (кого уведомили, у кого нет
/// устройств, кто схлопнулся дедупом) — этого достаточно для пилота
/// без webhook-ов статуса обратно (открытый вопрос №2 спеки).
abstract class ProductNotificationRecipientResult
    implements _i1.SerializableModel {
  ProductNotificationRecipientResult._({
    required this.externalUserId,
    required this.status,
    required this.deviceCount,
  });

  factory ProductNotificationRecipientResult({
    required String externalUserId,
    required _i2.ProductNotificationStatus status,
    required int deviceCount,
  }) = _ProductNotificationRecipientResultImpl;

  factory ProductNotificationRecipientResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductNotificationRecipientResult(
      externalUserId: jsonSerialization['externalUserId'] as String,
      status: _i2.ProductNotificationStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      deviceCount: jsonSerialization['deviceCount'] as int,
    );
  }

  String externalUserId;

  _i2.ProductNotificationStatus status;

  /// Сколько устройств адресата приняли payload (0 при noDevices/deduped).
  int deviceCount;

  /// Returns a shallow copy of this [ProductNotificationRecipientResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductNotificationRecipientResult copyWith({
    String? externalUserId,
    _i2.ProductNotificationStatus? status,
    int? deviceCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductNotificationRecipientResult',
      'externalUserId': externalUserId,
      'status': status.toJson(),
      'deviceCount': deviceCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ProductNotificationRecipientResultImpl
    extends ProductNotificationRecipientResult {
  _ProductNotificationRecipientResultImpl({
    required String externalUserId,
    required _i2.ProductNotificationStatus status,
    required int deviceCount,
  }) : super._(
         externalUserId: externalUserId,
         status: status,
         deviceCount: deviceCount,
       );

  /// Returns a shallow copy of this [ProductNotificationRecipientResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductNotificationRecipientResult copyWith({
    String? externalUserId,
    _i2.ProductNotificationStatus? status,
    int? deviceCount,
  }) {
    return ProductNotificationRecipientResult(
      externalUserId: externalUserId ?? this.externalUserId,
      status: status ?? this.status,
      deviceCount: deviceCount ?? this.deviceCount,
    );
  }
}
