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

/// **Здоровье доставки уведомлений по продукту** (issue #120).
///
/// Отсутствие пушей выглядит как тишина: ни экрана, ни лога. Что у продукта
/// ноль зарегистрированных устройств, пришлось выяснять запросом в прод-базу
/// — и выяснилось, что так у ВСЕХ продуктов, кроме Chatista. Пока признака
/// нет, каждая следующая интеграция будет молча оставаться без уведомлений.
///
/// Транзиентный DTO — считается на лету, хранить нечего.
abstract class ProductDeliveryHealth implements _i1.SerializableModel {
  ProductDeliveryHealth._({
    required this.productExternalKey,
    required this.productDisplayName,
    required this.tenantExternalKey,
    required this.devicesFcm,
    required this.devicesRustore,
    required this.devicesVoip,
    required this.staleDevices,
    this.lastSeenAt,
    required this.hasFcmCredentials,
    required this.hasRustoreCredentials,
    required this.hasVoipCredentials,
    required this.verdict,
    required this.deliveryTransport,
    required this.deliveryTransportKnown,
  });

  factory ProductDeliveryHealth({
    required String productExternalKey,
    required String productDisplayName,
    required String tenantExternalKey,
    required int devicesFcm,
    required int devicesRustore,
    required int devicesVoip,
    required int staleDevices,
    DateTime? lastSeenAt,
    required bool hasFcmCredentials,
    required bool hasRustoreCredentials,
    required bool hasVoipCredentials,
    required String verdict,
    required String deliveryTransport,
    required bool deliveryTransportKnown,
  }) = _ProductDeliveryHealthImpl;

  factory ProductDeliveryHealth.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductDeliveryHealth(
      productExternalKey: jsonSerialization['productExternalKey'] as String,
      productDisplayName: jsonSerialization['productDisplayName'] as String,
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
      devicesFcm: jsonSerialization['devicesFcm'] as int,
      devicesRustore: jsonSerialization['devicesRustore'] as int,
      devicesVoip: jsonSerialization['devicesVoip'] as int,
      staleDevices: jsonSerialization['staleDevices'] as int,
      lastSeenAt: jsonSerialization['lastSeenAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeenAt']),
      hasFcmCredentials: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasFcmCredentials'],
      ),
      hasRustoreCredentials: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasRustoreCredentials'],
      ),
      hasVoipCredentials: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasVoipCredentials'],
      ),
      verdict: jsonSerialization['verdict'] as String,
      deliveryTransport: jsonSerialization['deliveryTransport'] as String,
      deliveryTransportKnown: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['deliveryTransportKnown'],
      ),
    );
  }

  String productExternalKey;

  String productDisplayName;

  String tenantExternalKey;

  /// Зарегистрированных устройств по каналам. `voip` — только звонки.
  int devicesFcm;

  int devicesRustore;

  int devicesVoip;

  /// Сколько регистраций не продлевалось дольше порога свежести
  /// (`DeviceRegistrationService.registrationFreshness`). Токен живого
  /// пользователя обновляется на каждом запуске приложения.
  int staleDevices;

  /// Самое свежее продление среди устройств продукта; `null` — устройств нет.
  DateTime? lastSeenAt;

  /// Настроены ли ключи отправки. Boolean, НЕ путь и не содержимое: путь к
  /// файлу с ключом в ответ API попадать не должен.
  bool hasFcmCredentials;

  bool hasRustoreCredentials;

  bool hasVoipCredentials;

  /// Вердикт одним словом: `ok` | `noDevices` | `noCredentials` | `stale`.
  /// Разбор — в `deliveryHealthVerdict`.
  String verdict;

  /// **Модуль доставки (#121)**: чем везётся последняя миля —
  /// `platformPush` | `webhook`. Без этого поля признак здоровья врал бы
  /// продукту на вебхуке: ноль устройств у него — норма, а не поломка,
  /// и красить его красным значит приучать смотреть мимо красного.
  String deliveryTransport;

  /// Записано ли в БД значение, которое мы понимаем. `false` — там
  /// опечатка или значение из будущей версии, и доставка идёт
  /// `platformPush`. Молча делать не то, что настроено, нельзя.
  bool deliveryTransportKnown;

  /// Returns a shallow copy of this [ProductDeliveryHealth]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductDeliveryHealth copyWith({
    String? productExternalKey,
    String? productDisplayName,
    String? tenantExternalKey,
    int? devicesFcm,
    int? devicesRustore,
    int? devicesVoip,
    int? staleDevices,
    DateTime? lastSeenAt,
    bool? hasFcmCredentials,
    bool? hasRustoreCredentials,
    bool? hasVoipCredentials,
    String? verdict,
    String? deliveryTransport,
    bool? deliveryTransportKnown,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductDeliveryHealth',
      'productExternalKey': productExternalKey,
      'productDisplayName': productDisplayName,
      'tenantExternalKey': tenantExternalKey,
      'devicesFcm': devicesFcm,
      'devicesRustore': devicesRustore,
      'devicesVoip': devicesVoip,
      'staleDevices': staleDevices,
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      'hasFcmCredentials': hasFcmCredentials,
      'hasRustoreCredentials': hasRustoreCredentials,
      'hasVoipCredentials': hasVoipCredentials,
      'verdict': verdict,
      'deliveryTransport': deliveryTransport,
      'deliveryTransportKnown': deliveryTransportKnown,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductDeliveryHealthImpl extends ProductDeliveryHealth {
  _ProductDeliveryHealthImpl({
    required String productExternalKey,
    required String productDisplayName,
    required String tenantExternalKey,
    required int devicesFcm,
    required int devicesRustore,
    required int devicesVoip,
    required int staleDevices,
    DateTime? lastSeenAt,
    required bool hasFcmCredentials,
    required bool hasRustoreCredentials,
    required bool hasVoipCredentials,
    required String verdict,
    required String deliveryTransport,
    required bool deliveryTransportKnown,
  }) : super._(
         productExternalKey: productExternalKey,
         productDisplayName: productDisplayName,
         tenantExternalKey: tenantExternalKey,
         devicesFcm: devicesFcm,
         devicesRustore: devicesRustore,
         devicesVoip: devicesVoip,
         staleDevices: staleDevices,
         lastSeenAt: lastSeenAt,
         hasFcmCredentials: hasFcmCredentials,
         hasRustoreCredentials: hasRustoreCredentials,
         hasVoipCredentials: hasVoipCredentials,
         verdict: verdict,
         deliveryTransport: deliveryTransport,
         deliveryTransportKnown: deliveryTransportKnown,
       );

  /// Returns a shallow copy of this [ProductDeliveryHealth]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductDeliveryHealth copyWith({
    String? productExternalKey,
    String? productDisplayName,
    String? tenantExternalKey,
    int? devicesFcm,
    int? devicesRustore,
    int? devicesVoip,
    int? staleDevices,
    Object? lastSeenAt = _Undefined,
    bool? hasFcmCredentials,
    bool? hasRustoreCredentials,
    bool? hasVoipCredentials,
    String? verdict,
    String? deliveryTransport,
    bool? deliveryTransportKnown,
  }) {
    return ProductDeliveryHealth(
      productExternalKey: productExternalKey ?? this.productExternalKey,
      productDisplayName: productDisplayName ?? this.productDisplayName,
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
      devicesFcm: devicesFcm ?? this.devicesFcm,
      devicesRustore: devicesRustore ?? this.devicesRustore,
      devicesVoip: devicesVoip ?? this.devicesVoip,
      staleDevices: staleDevices ?? this.staleDevices,
      lastSeenAt: lastSeenAt is DateTime? ? lastSeenAt : this.lastSeenAt,
      hasFcmCredentials: hasFcmCredentials ?? this.hasFcmCredentials,
      hasRustoreCredentials:
          hasRustoreCredentials ?? this.hasRustoreCredentials,
      hasVoipCredentials: hasVoipCredentials ?? this.hasVoipCredentials,
      verdict: verdict ?? this.verdict,
      deliveryTransport: deliveryTransport ?? this.deliveryTransport,
      deliveryTransportKnown:
          deliveryTransportKnown ?? this.deliveryTransportKnown,
    );
  }
}
