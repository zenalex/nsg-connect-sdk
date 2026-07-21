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

/// DTO для экрана «Устройства» (issue #23). Одна запись = одна активная
/// (не отозванная, не истёкшая) [EmailSession] аккаунта. Отдаётся
/// `EmailAuthEndpoint.listMyDevices`; `sessionId` — непрозрачный handle
/// для `revokeDevice(targetSessionId)` (сам sessionToken других устройств
/// клиенту НЕ раскрывается — только id).
///
/// Это DTO (без `table:`) — не персистится, собирается на лету.
abstract class DeviceSessionInfo implements _i1.SerializableModel {
  DeviceSessionInfo._({
    required this.sessionId,
    this.deviceName,
    this.platform,
    this.appVersion,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.isCurrent,
  });

  factory DeviceSessionInfo({
    required int sessionId,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? appVersion,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    required bool isCurrent,
  }) = _DeviceSessionInfoImpl;

  factory DeviceSessionInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceSessionInfo(
      sessionId: jsonSerialization['sessionId'] as int,
      deviceName: jsonSerialization['deviceName'] as String?,
      platform: jsonSerialization['platform'] == null
          ? null
          : _i2.DevicePlatform.fromJson(
              (jsonSerialization['platform'] as String),
            ),
      appVersion: jsonSerialization['appVersion'] as String?,
      firstSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstSeenAt'],
      ),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
      isCurrent: _i1.BoolJsonExtension.fromJson(jsonSerialization['isCurrent']),
    );
  }

  /// EmailSession.id — стабильный handle для точечного revokeDevice.
  /// Не секрет (в отличие от sessionToken), безопасно отдавать клиенту.
  int sessionId;

  /// Имя устройства (hostname / модель). Может быть null для старых
  /// сессий — UI показывает платформу как fallback.
  String? deviceName;

  /// Платформа устройства (ios/android/web/desktop) — иконка в списке.
  _i2.DevicePlatform? platform;

  /// Версия приложения на момент входа ('1.0.57+58').
  String? appVersion;

  /// Дата первого входа этой сессии (= EmailSession.createdAt).
  DateTime firstSeenAt;

  /// Дата последней активности (= lastSeenAt ?? createdAt).
  DateTime lastSeenAt;

  /// true для сессии вызывающего устройства (совпадает sessionToken).
  /// UI помечает её «Это устройство» и не показывает кнопку точечного
  /// выхода (текущее устройство выходит обычным logout).
  bool isCurrent;

  /// Returns a shallow copy of this [DeviceSessionInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceSessionInfo copyWith({
    int? sessionId,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? appVersion,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    bool? isCurrent,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceSessionInfo',
      'sessionId': sessionId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform?.toJson(),
      if (appVersion != null) 'appVersion': appVersion,
      'firstSeenAt': firstSeenAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      'isCurrent': isCurrent,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceSessionInfoImpl extends DeviceSessionInfo {
  _DeviceSessionInfoImpl({
    required int sessionId,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? appVersion,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    required bool isCurrent,
  }) : super._(
         sessionId: sessionId,
         deviceName: deviceName,
         platform: platform,
         appVersion: appVersion,
         firstSeenAt: firstSeenAt,
         lastSeenAt: lastSeenAt,
         isCurrent: isCurrent,
       );

  /// Returns a shallow copy of this [DeviceSessionInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceSessionInfo copyWith({
    int? sessionId,
    Object? deviceName = _Undefined,
    Object? platform = _Undefined,
    Object? appVersion = _Undefined,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    bool? isCurrent,
  }) {
    return DeviceSessionInfo(
      sessionId: sessionId ?? this.sessionId,
      deviceName: deviceName is String? ? deviceName : this.deviceName,
      platform: platform is _i2.DevicePlatform? ? platform : this.platform,
      appVersion: appVersion is String? ? appVersion : this.appVersion,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
