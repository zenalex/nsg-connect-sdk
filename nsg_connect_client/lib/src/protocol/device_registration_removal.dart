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
import 'enums/device_platform.dart' as _i2;
import 'enums/push_service.dart' as _i3;
import 'enums/device_removal_reason.dart' as _i4;

/// **issue #150**: след от снятой push-регистрации.
///
/// **Зачем.** `device_registrations` удаляется в четырёх местах (отказ
/// провайдера, выход из аккаунта, плановая уборка), и до этой таблицы
/// удаление не оставляло ничего. Из-за этого нельзя было ответить на
/// единственный вопрос, который задают при разборе «мне не приходят
/// уведомления»: регистрация была и пропала — или её никогда не заводили?
/// Доказать отсутствие потерь тоже было нечем: удалённая строка молчит.
///
/// **Только на запись.** Никаких апдейтов: журнал описывает событие, а
/// событие не меняется. Пишется best-effort — сбой журнала НЕ отменяет
/// само снятие (как в `ConnectKeyAuditEvent`).
///
/// **Токена здесь нет.** Хранится только [tokenHashPrefix] — начало
/// sha256. Этого хватает, чтобы связать повторные отказы по одному и тому
/// же токену, и недостаточно, чтобы кому-то что-то отправить.
///
/// **Ссылок на пользователя и продукт намеренно нет** (обычный `int`, а не
/// `relation`). Журнал должен пережить удаление аккаунта: с `Cascade` он
/// исчез бы вместе с тем, чью пропажу и объясняет, а с `SetNull` потерял
/// бы главное — чья это была регистрация.
abstract class DeviceRegistrationRemoval implements _i1.SerializableModel {
  DeviceRegistrationRemoval._({
    this.id,
    required this.tenantId,
    this.productId,
    required this.messengerUserId,
    required this.platform,
    required this.pushService,
    this.appVersion,
    this.deviceModel,
    required this.tokenHashPrefix,
    required this.reason,
    this.providerErrorCode,
    this.providerStatusCode,
    required this.registrationCreatedAt,
    required this.registrationLastSeenAt,
    required this.removed,
    required this.removedAt,
  });

  factory DeviceRegistrationRemoval({
    int? id,
    required int tenantId,
    int? productId,
    required int messengerUserId,
    required _i2.DevicePlatform platform,
    required _i3.PushService pushService,
    String? appVersion,
    String? deviceModel,
    required String tokenHashPrefix,
    required _i4.DeviceRemovalReason reason,
    String? providerErrorCode,
    int? providerStatusCode,
    required DateTime registrationCreatedAt,
    required DateTime registrationLastSeenAt,
    required bool removed,
    required DateTime removedAt,
  }) = _DeviceRegistrationRemovalImpl;

  factory DeviceRegistrationRemoval.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeviceRegistrationRemoval(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      platform: _i2.DevicePlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      pushService: _i3.PushService.fromJson(
        (jsonSerialization['pushService'] as String),
      ),
      appVersion: jsonSerialization['appVersion'] as String?,
      deviceModel: jsonSerialization['deviceModel'] as String?,
      tokenHashPrefix: jsonSerialization['tokenHashPrefix'] as String,
      reason: _i4.DeviceRemovalReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
      providerErrorCode: jsonSerialization['providerErrorCode'] as String?,
      providerStatusCode: jsonSerialization['providerStatusCode'] as int?,
      registrationCreatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['registrationCreatedAt'],
      ),
      registrationLastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['registrationLastSeenAt'],
      ),
      removed: _i1.BoolJsonExtension.fromJson(jsonSerialization['removed']),
      removedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['removedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Тенант владельца регистрации (снимок на момент снятия).
  int tenantId;

  /// Продукт регистрации; `null` — standalone-режим SDK.
  int? productId;

  /// MUID владельца. Без FK — см. заголовок.
  int messengerUserId;

  _i2.DevicePlatform platform;

  _i3.PushService pushService;

  /// Версия приложения и модель устройства на момент снятия: по ним
  /// видно, не бьёт ли беда по конкретной сборке или вендору.
  String? appVersion;

  String? deviceModel;

  /// Первые 12 символов sha256 от push-токена. Сам токен не хранится.
  String tokenHashPrefix;

  _i4.DeviceRemovalReason reason;

  /// Код и HTTP-статус от провайдера (`UNREGISTERED`,
  /// `INVALID_ARGUMENT`, 404, 400…). Пусто для снятий не по отказу.
  String? providerErrorCode;

  int? providerStatusCode;

  /// Возраст регистрации: когда завели и когда в последний раз
  /// продлевали. Снятие свежей регистрации — куда более тревожный
  /// признак, чем снятие годовалой.
  DateTime registrationCreatedAt;

  DateTime registrationLastSeenAt;

  /// `false` — отказ ЗАМЕЧЕН, но регистрация оставлена (первый
  /// `INVALID_ARGUMENT`, см. [DeviceRemovalReason]). Именно эти записи
  /// отличают «сломалась нагрузка» от «умер токен»: если после пометки
  /// повтора не было, значит удалять было бы ошибкой.
  bool removed;

  DateTime removedAt;

  /// Returns a shallow copy of this [DeviceRegistrationRemoval]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceRegistrationRemoval copyWith({
    int? id,
    int? tenantId,
    int? productId,
    int? messengerUserId,
    _i2.DevicePlatform? platform,
    _i3.PushService? pushService,
    String? appVersion,
    String? deviceModel,
    String? tokenHashPrefix,
    _i4.DeviceRemovalReason? reason,
    String? providerErrorCode,
    int? providerStatusCode,
    DateTime? registrationCreatedAt,
    DateTime? registrationLastSeenAt,
    bool? removed,
    DateTime? removedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceRegistrationRemoval',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'messengerUserId': messengerUserId,
      'platform': platform.toJson(),
      'pushService': pushService.toJson(),
      if (appVersion != null) 'appVersion': appVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      'tokenHashPrefix': tokenHashPrefix,
      'reason': reason.toJson(),
      if (providerErrorCode != null) 'providerErrorCode': providerErrorCode,
      if (providerStatusCode != null) 'providerStatusCode': providerStatusCode,
      'registrationCreatedAt': registrationCreatedAt.toJson(),
      'registrationLastSeenAt': registrationLastSeenAt.toJson(),
      'removed': removed,
      'removedAt': removedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceRegistrationRemovalImpl extends DeviceRegistrationRemoval {
  _DeviceRegistrationRemovalImpl({
    int? id,
    required int tenantId,
    int? productId,
    required int messengerUserId,
    required _i2.DevicePlatform platform,
    required _i3.PushService pushService,
    String? appVersion,
    String? deviceModel,
    required String tokenHashPrefix,
    required _i4.DeviceRemovalReason reason,
    String? providerErrorCode,
    int? providerStatusCode,
    required DateTime registrationCreatedAt,
    required DateTime registrationLastSeenAt,
    required bool removed,
    required DateTime removedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         messengerUserId: messengerUserId,
         platform: platform,
         pushService: pushService,
         appVersion: appVersion,
         deviceModel: deviceModel,
         tokenHashPrefix: tokenHashPrefix,
         reason: reason,
         providerErrorCode: providerErrorCode,
         providerStatusCode: providerStatusCode,
         registrationCreatedAt: registrationCreatedAt,
         registrationLastSeenAt: registrationLastSeenAt,
         removed: removed,
         removedAt: removedAt,
       );

  /// Returns a shallow copy of this [DeviceRegistrationRemoval]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceRegistrationRemoval copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    int? messengerUserId,
    _i2.DevicePlatform? platform,
    _i3.PushService? pushService,
    Object? appVersion = _Undefined,
    Object? deviceModel = _Undefined,
    String? tokenHashPrefix,
    _i4.DeviceRemovalReason? reason,
    Object? providerErrorCode = _Undefined,
    Object? providerStatusCode = _Undefined,
    DateTime? registrationCreatedAt,
    DateTime? registrationLastSeenAt,
    bool? removed,
    DateTime? removedAt,
  }) {
    return DeviceRegistrationRemoval(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      platform: platform ?? this.platform,
      pushService: pushService ?? this.pushService,
      appVersion: appVersion is String? ? appVersion : this.appVersion,
      deviceModel: deviceModel is String? ? deviceModel : this.deviceModel,
      tokenHashPrefix: tokenHashPrefix ?? this.tokenHashPrefix,
      reason: reason ?? this.reason,
      providerErrorCode: providerErrorCode is String?
          ? providerErrorCode
          : this.providerErrorCode,
      providerStatusCode: providerStatusCode is int?
          ? providerStatusCode
          : this.providerStatusCode,
      registrationCreatedAt:
          registrationCreatedAt ?? this.registrationCreatedAt,
      registrationLastSeenAt:
          registrationLastSeenAt ?? this.registrationLastSeenAt,
      removed: removed ?? this.removed,
      removedAt: removedAt ?? this.removedAt,
    );
  }
}
