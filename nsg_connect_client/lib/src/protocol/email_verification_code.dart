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

/// EmailVerificationCode — 6-digit OTP отправляется на email при signUp +
/// resendVerification. Verify endpoint ищет unused/unexpired row, помечает
/// `usedAt = now`, ставит `account.verified = true`.
///
/// **TTL**: 15 минут (определяется server-side при создании). Не auto-
/// cleanup — старые rows остаются с usedAt=null, но игнорируются по
/// `expiresAt`. Phase2: cron-job очищает.
///
/// **Anti-brute**: rate-limit на resendVerification (1 раз в 60s per
/// account) — Phase2; на MVP без rate limit.
abstract class EmailVerificationCode implements _i1.SerializableModel {
  EmailVerificationCode._({
    this.id,
    required this.emailAccountId,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    String? purpose,
  }) : purpose = purpose ?? 'verify';

  factory EmailVerificationCode({
    int? id,
    required int emailAccountId,
    required String code,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
    String? purpose,
  }) = _EmailVerificationCodeImpl;

  factory EmailVerificationCode.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EmailVerificationCode(
      id: jsonSerialization['id'] as int?,
      emailAccountId: jsonSerialization['emailAccountId'] as int,
      code: jsonSerialization['code'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
      purpose: jsonSerialization['purpose'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на EmailAccount.id. Cascade — при delete-аккаунта чистится.
  int emailAccountId;

  /// 6-digit numeric code (хранится как String чтобы padding-нули
  /// сохранялись: '001234' ≠ '1234').
  String code;

  DateTime createdAt;

  /// Server-side expiry (default 15 минут).
  DateTime expiresAt;

  /// Когда юзер успешно verify-нулся. NULL = still active.
  DateTime? usedAt;

  /// `'verify'` — email verification (signUp/resendVerification flow).
  /// `'reset'` — password reset (forgot-password flow). Default 'verify'
  /// для backward compat (existing rows = verify codes).
  String purpose;

  /// Returns a shallow copy of this [EmailVerificationCode]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmailVerificationCode copyWith({
    int? id,
    int? emailAccountId,
    String? code,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? purpose,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmailVerificationCode',
      if (id != null) 'id': id,
      'emailAccountId': emailAccountId,
      'code': code,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      'purpose': purpose,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmailVerificationCodeImpl extends EmailVerificationCode {
  _EmailVerificationCodeImpl({
    int? id,
    required int emailAccountId,
    required String code,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
    String? purpose,
  }) : super._(
         id: id,
         emailAccountId: emailAccountId,
         code: code,
         createdAt: createdAt,
         expiresAt: expiresAt,
         usedAt: usedAt,
         purpose: purpose,
       );

  /// Returns a shallow copy of this [EmailVerificationCode]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmailVerificationCode copyWith({
    Object? id = _Undefined,
    int? emailAccountId,
    String? code,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
    String? purpose,
  }) {
    return EmailVerificationCode(
      id: id is int? ? id : this.id,
      emailAccountId: emailAccountId ?? this.emailAccountId,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
      purpose: purpose ?? this.purpose,
    );
  }
}
