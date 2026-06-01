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

/// EmailAccount — внутренний пользовательский аккаунт для встроенного
/// email/password adapter (alternative to customer SSO / JWT bearer
/// adapters of TASK24). Используется когда tenant выбрал standalone
/// Chatista deployment без внешнего IdP.
///
/// Хранит email + хеш пароля. Сам token-session идёт в [EmailSession].
/// Связь с [MessengerUser] происходит через `externalUserId =
/// emailAccount.id.toString()` в `MessengerAuthContext`.
abstract class EmailAccount implements _i1.SerializableModel {
  EmailAccount._({
    this.id,
    required this.tenantExternalKey,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    int? iterations,
    this.displayName,
    bool? verified,
    required this.createdAt,
    this.lastLoginAt,
  }) : iterations = iterations ?? 100000,
       verified = verified ?? false;

  factory EmailAccount({
    int? id,
    required String tenantExternalKey,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    int? iterations,
    String? displayName,
    bool? verified,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) = _EmailAccountImpl;

  factory EmailAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmailAccount(
      id: jsonSerialization['id'] as int?,
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
      email: jsonSerialization['email'] as String,
      passwordHash: jsonSerialization['passwordHash'] as String,
      passwordSalt: jsonSerialization['passwordSalt'] as String,
      iterations: jsonSerialization['iterations'] as int?,
      displayName: jsonSerialization['displayName'] as String?,
      verified: jsonSerialization['verified'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['verified']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastLoginAt: jsonSerialization['lastLoginAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Tenant.externalKey (обычно 'nsg' на MVP).
  String tenantExternalKey;

  /// Email — case-insensitive lookup. Храним всегда lowercase.
  String email;

  /// PBKDF2-SHA256 hash пароля, hex-encoded (32 bytes = 64 hex chars).
  String passwordHash;

  /// Salt 16 байт, hex-encoded (32 hex chars). Per-user случайный.
  String passwordSalt;

  /// Кол-во итераций PBKDF2 — храним, чтобы можно было увеличивать
  /// для новых пользователей не сломав старые. Default 100k.
  int iterations;

  /// Опциональный display name. Для MVP не валидируем — заполнить
  /// при signUp или позже из profile screen.
  String? displayName;

  /// Email verified (clicked verification link). На MVP всегда true
  /// (verify-by-email пока не реализован — Phase2).
  bool verified;

  DateTime createdAt;

  DateTime? lastLoginAt;

  /// Returns a shallow copy of this [EmailAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmailAccount copyWith({
    int? id,
    String? tenantExternalKey,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    int? iterations,
    String? displayName,
    bool? verified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmailAccount',
      if (id != null) 'id': id,
      'tenantExternalKey': tenantExternalKey,
      'email': email,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'iterations': iterations,
      if (displayName != null) 'displayName': displayName,
      'verified': verified,
      'createdAt': createdAt.toJson(),
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmailAccountImpl extends EmailAccount {
  _EmailAccountImpl({
    int? id,
    required String tenantExternalKey,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    int? iterations,
    String? displayName,
    bool? verified,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) : super._(
         id: id,
         tenantExternalKey: tenantExternalKey,
         email: email,
         passwordHash: passwordHash,
         passwordSalt: passwordSalt,
         iterations: iterations,
         displayName: displayName,
         verified: verified,
         createdAt: createdAt,
         lastLoginAt: lastLoginAt,
       );

  /// Returns a shallow copy of this [EmailAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmailAccount copyWith({
    Object? id = _Undefined,
    String? tenantExternalKey,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    int? iterations,
    Object? displayName = _Undefined,
    bool? verified,
    DateTime? createdAt,
    Object? lastLoginAt = _Undefined,
  }) {
    return EmailAccount(
      id: id is int? ? id : this.id,
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      iterations: iterations ?? this.iterations,
      displayName: displayName is String? ? displayName : this.displayName,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt is DateTime? ? lastLoginAt : this.lastLoginAt,
    );
  }
}
