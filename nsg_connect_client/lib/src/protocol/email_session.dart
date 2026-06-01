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
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });

  factory EmailSession({
    int? id,
    required int emailAccountId,
    required String sessionToken,
    String? deviceId,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) = _EmailSessionImpl;

  factory EmailSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmailSession(
      id: jsonSerialization['id'] as int?,
      emailAccountId: jsonSerialization['emailAccountId'] as int,
      sessionToken: jsonSerialization['sessionToken'] as String,
      deviceId: jsonSerialization['deviceId'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
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

  DateTime createdAt;

  /// Server-side expiry (на MVP — 90 дней). Client SDK сам не следит
  /// за expiry; expired-сессия даст InvalidTokenException на verify.
  DateTime expiresAt;

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
    DateTime? createdAt,
    DateTime? expiresAt,
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
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
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
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         emailAccountId: emailAccountId,
         sessionToken: sessionToken,
         deviceId: deviceId,
         createdAt: createdAt,
         expiresAt: expiresAt,
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
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? revokedAt = _Undefined,
  }) {
    return EmailSession(
      id: id is int? ? id : this.id,
      emailAccountId: emailAccountId ?? this.emailAccountId,
      sessionToken: sessionToken ?? this.sessionToken,
      deviceId: deviceId is String? ? deviceId : this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
