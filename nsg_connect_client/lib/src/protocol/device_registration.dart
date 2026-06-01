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

/// Регистрация push-устройства пользователя (TASK20 §8).
///
/// **Lifecycle:**
///   * SDK при `MessengerRuntime.init` через `PushTokenProvider`
///     получает push-token (FCM / APNs / WebPush), вызывает
///     `MessengerEndpoint.registerDevice(...)` — upsert по unique
///     `(pushToken, pushService)`.
///   * При token rotation (FCM / APNs выдал новый token) — повторный
///     `registerDevice` upsert-ит row, `lastSeenAt` обновляется.
///   * `MessengerEndpoint.unregisterDevice(pushToken)` при logout
///     или `MessengerRuntime.dispose` — idempotent delete.
///   * Token cleanup при INVALID_ARGUMENT / UNREGISTERED от FCM/APNs
///     (TASK20 Phase2 push routing service).
///
/// **Per-product attribution (§8 ТЗ):**
///   * `productId` — какой продукт SDK работает в этом app (Futbolista
///     / Chatista / customer-specific). Push delivery: предпочтение
///     `device.productId == room.productId`; fallback — null /
///     standalone (см. TASK20-Phase2 PushRoutingService).
///
/// Не храним `muted` per-device — это per-room (RoomMembership.mutedUntil
/// per `(user, room)`). Возможно в TASK33 settings появится «mute all
/// push на этом устройстве» — тогда добавим.
abstract class DeviceRegistration implements _i1.SerializableModel {
  DeviceRegistration._({
    this.id,
    required this.messengerUserId,
    this.productId,
    required this.platform,
    required this.pushToken,
    required this.pushService,
    required this.locale,
    required this.appVersion,
    this.deviceModel,
    required this.createdAt,
    required this.lastSeenAt,
  });

  factory DeviceRegistration({
    int? id,
    required int messengerUserId,
    int? productId,
    required _i2.DevicePlatform platform,
    required String pushToken,
    required _i3.PushService pushService,
    required String locale,
    required String appVersion,
    String? deviceModel,
    required DateTime createdAt,
    required DateTime lastSeenAt,
  }) = _DeviceRegistrationImpl;

  factory DeviceRegistration.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceRegistration(
      id: jsonSerialization['id'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      productId: jsonSerialization['productId'] as int?,
      platform: _i2.DevicePlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      pushToken: jsonSerialization['pushToken'] as String,
      pushService: _i3.PushService.fromJson(
        (jsonSerialization['pushService'] as String),
      ),
      locale: jsonSerialization['locale'] as String,
      appVersion: jsonSerialization['appVersion'] as String,
      deviceModel: jsonSerialization['deviceModel'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int messengerUserId;

  /// Опциональный — null когда SDK работает в standalone-mode
  /// (Chatista app без привязки к product). Используется для
  /// per-product push branding (TASK20-Phase2 / TASK21).
  int? productId;

  _i2.DevicePlatform platform;

  String pushToken;

  _i3.PushService pushService;

  /// IETF BCP 47 locale (`ru`, `en-US`); используется для localizing
  /// push body в `PushRoutingService` (TASK20-Phase2 + TASK21).
  String locale;

  /// Semver-style ('1.0.0+1' Flutter `package_info_plus` format).
  String appVersion;

  /// Best-effort identifier для troubleshooting (e.g., 'iPhone15,2',
  /// 'Pixel 7'). Может быть null если SDK не получил info.
  String? deviceModel;

  DateTime createdAt;

  /// Last известный `register-device` call. Используется для:
  ///   * stale-token cleanup (если > 90 дней — потенциально dead
  ///     install, удалить);
  ///   * troubleshooting в admin tooling (TASK28).
  DateTime lastSeenAt;

  /// Returns a shallow copy of this [DeviceRegistration]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceRegistration copyWith({
    int? id,
    int? messengerUserId,
    int? productId,
    _i2.DevicePlatform? platform,
    String? pushToken,
    _i3.PushService? pushService,
    String? locale,
    String? appVersion,
    String? deviceModel,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceRegistration',
      if (id != null) 'id': id,
      'messengerUserId': messengerUserId,
      if (productId != null) 'productId': productId,
      'platform': platform.toJson(),
      'pushToken': pushToken,
      'pushService': pushService.toJson(),
      'locale': locale,
      'appVersion': appVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      'createdAt': createdAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceRegistrationImpl extends DeviceRegistration {
  _DeviceRegistrationImpl({
    int? id,
    required int messengerUserId,
    int? productId,
    required _i2.DevicePlatform platform,
    required String pushToken,
    required _i3.PushService pushService,
    required String locale,
    required String appVersion,
    String? deviceModel,
    required DateTime createdAt,
    required DateTime lastSeenAt,
  }) : super._(
         id: id,
         messengerUserId: messengerUserId,
         productId: productId,
         platform: platform,
         pushToken: pushToken,
         pushService: pushService,
         locale: locale,
         appVersion: appVersion,
         deviceModel: deviceModel,
         createdAt: createdAt,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [DeviceRegistration]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceRegistration copyWith({
    Object? id = _Undefined,
    int? messengerUserId,
    Object? productId = _Undefined,
    _i2.DevicePlatform? platform,
    String? pushToken,
    _i3.PushService? pushService,
    String? locale,
    String? appVersion,
    Object? deviceModel = _Undefined,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceRegistration(
      id: id is int? ? id : this.id,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      productId: productId is int? ? productId : this.productId,
      platform: platform ?? this.platform,
      pushToken: pushToken ?? this.pushToken,
      pushService: pushService ?? this.pushService,
      locale: locale ?? this.locale,
      appVersion: appVersion ?? this.appVersion,
      deviceModel: deviceModel is String? ? deviceModel : this.deviceModel,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
