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
    this.reason,
  });

  factory ProductNotificationRecipientResult({
    required String externalUserId,
    required _i2.ProductNotificationStatus status,
    required int deviceCount,
    String? reason,
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
      reason: jsonSerialization['reason'] as String?,
    );
  }

  String externalUserId;

  _i2.ProductNotificationStatus status;

  /// Сколько устройств адресата приняли payload (0 при noDevices/deduped).
  int deviceCount;

  /// **issue #157**: ПОЧЕМУ не доставлено. Пусто у успешных исходов.
  ///
  ///   * `unknown_recipient` — такого адресата мы не знаем: привязки
  ///     `externalUserId` → пользователь мессенджера нет вовсе. Ошибка
  ///     интеграции: продукт шлёт на идентификатор, которого у нас нет
  ///     (или он заведён под другим провайдером). Чинится сверкой id;
  ///   * `no_devices` — адресат известен, но подходящих устройств нет.
  ///     Ситуация продуктовая: человек не обновил приложение, токен не
  ///     выдавался. Чинится работой с людьми, а не с кодом;
  ///   * `stale_tokens` — устройства есть, но все давно не продлевались
  ///     (см. `DeviceRegistrationService.isRegistrationStale`): скорее
  ///     всего установка мертва;
  ///   * `no_credentials` — устройства есть, а службы их доставки у нас не
  ///     настроены. Это НАШ отказ, и продукту он ничего чинить не даёт.
  ///
  /// **Строка, а не enum, намеренно.** Контракт внешний: клиент на C# или
  /// Python разбирает JSON, и добавление пятой причины не должно ломать
  /// тех, кто уже разбирает четыре. Значение неизвестной причины такой
  /// клиент просто покажет как есть.
  String? reason;

  /// Returns a shallow copy of this [ProductNotificationRecipientResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductNotificationRecipientResult copyWith({
    String? externalUserId,
    _i2.ProductNotificationStatus? status,
    int? deviceCount,
    String? reason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductNotificationRecipientResult',
      'externalUserId': externalUserId,
      'status': status.toJson(),
      'deviceCount': deviceCount,
      if (reason != null) 'reason': reason,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductNotificationRecipientResultImpl
    extends ProductNotificationRecipientResult {
  _ProductNotificationRecipientResultImpl({
    required String externalUserId,
    required _i2.ProductNotificationStatus status,
    required int deviceCount,
    String? reason,
  }) : super._(
         externalUserId: externalUserId,
         status: status,
         deviceCount: deviceCount,
         reason: reason,
       );

  /// Returns a shallow copy of this [ProductNotificationRecipientResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductNotificationRecipientResult copyWith({
    String? externalUserId,
    _i2.ProductNotificationStatus? status,
    int? deviceCount,
    Object? reason = _Undefined,
  }) {
    return ProductNotificationRecipientResult(
      externalUserId: externalUserId ?? this.externalUserId,
      status: status ?? this.status,
      deviceCount: deviceCount ?? this.deviceCount,
      reason: reason is String? ? reason : this.reason,
    );
  }
}
