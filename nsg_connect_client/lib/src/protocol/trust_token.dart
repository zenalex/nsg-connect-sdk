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
import 'enums/trust_token_kind.dart' as _i2;

/// **TASK52 итер.2 (чанк 3)**: эфемерный trust-токен для обмена
/// визитками. Единый механизм для QR / BLE «Рядом» / инвайт-ссылки
/// (TASK65 1а): выдающий генерирует токен, встречающий его гасит →
/// взаимный ContactLink (source по kind). Заменяет «голый messengerUserId
/// в QR/BLE» — тот не создавал trust и молча отбивался гейтом contacts.
///
/// Анти-абьюз: секрет 128-бит (неперечислим), TTL по kind, потолок
/// использований (qr/nearby одноразовы, invite многоразовый), redeem с
/// rate-limit и тихим отказом на невалидный (anti-enumeration). issuer/
/// tenant — plain int (конвенция contact_meta).
abstract class TrustToken implements _i1.SerializableModel {
  TrustToken._({
    this.id,
    required this.tenantId,
    required this.token,
    required this.issuerMessengerUserId,
    required this.kind,
    required this.maxUses,
    required this.useCount,
    required this.expiresAt,
    required this.createdAt,
  });

  factory TrustToken({
    int? id,
    required int tenantId,
    required String token,
    required int issuerMessengerUserId,
    required _i2.TrustTokenKind kind,
    required int maxUses,
    required int useCount,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) = _TrustTokenImpl;

  factory TrustToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrustToken(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      token: jsonSerialization['token'] as String,
      issuerMessengerUserId: jsonSerialization['issuerMessengerUserId'] as int,
      kind: _i2.TrustTokenKind.fromJson((jsonSerialization['kind'] as String)),
      maxUses: jsonSerialization['maxUses'] as int,
      useCount: jsonSerialization['useCount'] as int,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// Секрет (base64url, 128-бит энтропии) — то, что в QR/ссылке/BLE.
  String token;

  int issuerMessengerUserId;

  _i2.TrustTokenKind kind;

  /// Потолок погашений (qr/nearby = 1; invite = много).
  int maxUses;

  /// Сколько раз уже погашен.
  int useCount;

  /// Момент протухания (по kind). Индекс — под фоновую чистку.
  DateTime expiresAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [TrustToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrustToken copyWith({
    int? id,
    int? tenantId,
    String? token,
    int? issuerMessengerUserId,
    _i2.TrustTokenKind? kind,
    int? maxUses,
    int? useCount,
    DateTime? expiresAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrustToken',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'token': token,
      'issuerMessengerUserId': issuerMessengerUserId,
      'kind': kind.toJson(),
      'maxUses': maxUses,
      'useCount': useCount,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrustTokenImpl extends TrustToken {
  _TrustTokenImpl({
    int? id,
    required int tenantId,
    required String token,
    required int issuerMessengerUserId,
    required _i2.TrustTokenKind kind,
    required int maxUses,
    required int useCount,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         token: token,
         issuerMessengerUserId: issuerMessengerUserId,
         kind: kind,
         maxUses: maxUses,
         useCount: useCount,
         expiresAt: expiresAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TrustToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrustToken copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? token,
    int? issuerMessengerUserId,
    _i2.TrustTokenKind? kind,
    int? maxUses,
    int? useCount,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return TrustToken(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      token: token ?? this.token,
      issuerMessengerUserId:
          issuerMessengerUserId ?? this.issuerMessengerUserId,
      kind: kind ?? this.kind,
      maxUses: maxUses ?? this.maxUses,
      useCount: useCount ?? this.useCount,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
