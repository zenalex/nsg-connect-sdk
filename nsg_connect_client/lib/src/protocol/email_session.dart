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

/// EmailSession — issued session token для [EmailAccount]. Используется
/// как `MessengerAuthContext.accessToken` клиентом; verify-ится
/// [EmailAuthAdapter].
///
/// Тоkens — opaque base64 random 32 bytes (256 бит энтропии). НЕ JWT —
/// нет смысла нести claims, всё лежит в БД. Revocation = delete row
/// (или set revokedAt).
abstract class EmailSession implements _i1.SerializableModel {
  EmailSession._({
    this.id,
    required this.emailAccountId,
    required this.sessionToken,
    this.deviceId,
    this.platform,
    this.deviceName,
    this.appVersion,
    required this.createdAt,
    required this.expiresAt,
    this.lastSeenAt,
    this.revokedAt,
  });

  factory EmailSession({
    int? id,
    required int emailAccountId,
    required String sessionToken,
    String? deviceId,
    _i2.DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? lastSeenAt,
    DateTime? revokedAt,
  }) = _EmailSessionImpl;

  factory EmailSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmailSession(
      id: jsonSerialization['id'] as int?,
      emailAccountId: jsonSerialization['emailAccountId'] as int,
      sessionToken: jsonSerialization['sessionToken'] as String,
      deviceId: jsonSerialization['deviceId'] as String?,
      platform: jsonSerialization['platform'] == null
          ? null
          : _i2.DevicePlatform.fromJson(
              (jsonSerialization['platform'] as String),
            ),
      deviceName: jsonSerialization['deviceName'] as String?,
      appVersion: jsonSerialization['appVersion'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      lastSeenAt: jsonSerialization['lastSeenAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeenAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на EmailAccount.id.
  int emailAccountId;

  /// Random opaque token. Уникальный.
  String sessionToken;

  /// Опциональная device-метка из MessengerAuthContext.deviceId.
  /// Полезна для управления sessions ("выйти на других устройствах").
  String? deviceId;

  /// Платформа устройства, с которого создана сессия (issue #23 — экран
  /// «Устройства»). Nullable — сессии, выпущенные до фичи, платформы не
  /// знают; клиент присылает при signIn/signUp.
  _i2.DevicePlatform? platform;

  /// Человекочитаемое имя устройства для списка сессий (issue #23):
  /// hostname / модель («Alex-iPhone», «DESKTOP-ABC», «iPhone»). Best-
  /// effort — может быть null (UI fallback на платформу).
  String? deviceName;

  /// Версия приложения на момент входа ('1.0.57+58'). Помогает отличить
  /// устройства в списке и триаге. Nullable по тем же причинам.
  String? appVersion;

  DateTime createdAt;

  /// Server-side expiry (на MVP — 90 дней). Client SDK сам не следит
  /// за expiry; expired-сессия даст InvalidTokenException на verify.
  DateTime expiresAt;

  /// Последняя активность сессии (issue #23 — «последнее использование»).
  /// Обновляется в `EmailAuthAdapter.verify` (throttled) при обмене
  /// email-токена на messenger-сессию (cold-start / refresh). Nullable —
  /// legacy-строки без активности; UI показывает createdAt как fallback.
  DateTime? lastSeenAt;

  /// Явный revoke (logout / admin force-logout). Истечение через expiresAt
  /// менее explicit; revokedAt = stamped sign-off.
  DateTime? revokedAt;

  /// Returns a shallow copy of this [EmailSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmailSession copyWith({
    int? id,
    int? emailAccountId,
    String? sessionToken,
    String? deviceId,
    _i2.DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastSeenAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmailSession',
      if (id != null) 'id': id,
      'emailAccountId': emailAccountId,
      'sessionToken': sessionToken,
      if (deviceId != null) 'deviceId': deviceId,
      if (platform != null) 'platform': platform?.toJson(),
      if (deviceName != null) 'deviceName': deviceName,
      if (appVersion != null) 'appVersion': appVersion,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmailSessionImpl extends EmailSession {
  _EmailSessionImpl({
    int? id,
    required int emailAccountId,
    required String sessionToken,
    String? deviceId,
    _i2.DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? lastSeenAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         emailAccountId: emailAccountId,
         sessionToken: sessionToken,
         deviceId: deviceId,
         platform: platform,
         deviceName: deviceName,
         appVersion: appVersion,
         createdAt: createdAt,
         expiresAt: expiresAt,
         lastSeenAt: lastSeenAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [EmailSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmailSession copyWith({
    Object? id = _Undefined,
    int? emailAccountId,
    String? sessionToken,
    Object? deviceId = _Undefined,
    Object? platform = _Undefined,
    Object? deviceName = _Undefined,
    Object? appVersion = _Undefined,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? lastSeenAt = _Undefined,
    Object? revokedAt = _Undefined,
  }) {
    return EmailSession(
      id: id is int? ? id : this.id,
      emailAccountId: emailAccountId ?? this.emailAccountId,
      sessionToken: sessionToken ?? this.sessionToken,
      deviceId: deviceId is String? ? deviceId : this.deviceId,
      platform: platform is _i2.DevicePlatform? ? platform : this.platform,
      deviceName: deviceName is String? ? deviceName : this.deviceName,
      appVersion: appVersion is String? ? appVersion : this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastSeenAt: lastSeenAt is DateTime? ? lastSeenAt : this.lastSeenAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
