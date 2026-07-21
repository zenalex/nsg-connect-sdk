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

/// **Вариант C identity-bridge** (DESIGN_CONNECT_ISSUED_TOKENS.md):
/// одноразовый connect-токен, ВЫДАННЫЙ самой платформой по S2S-запросу
/// продукт-сервера (ConnectTokenEndpoint.issueToken). Проверка —
/// по этой же таблице (IssuedTokenAuthAdapter), обратного звонка в
/// продукт нет; поэтому продукт может жить за NAT без TLS (ровно то,
/// что заблокировало вариант B на titan-проде).
///
/// Сам токен в БД НЕ хранится — только sha256-hex ([tokenHash]).
/// Плейнтекст существует один раз: в ответе issueToken. Утечка дампа
/// БД не даёт валидных токенов (необратимость sha256 для 256-бит
/// случайного прообраза).
///
/// externalUserId/displayName записываются в момент выдачи из
/// АВТОРИЗОВАННОГО S2S-вызова (serviceSecret) — при verify клиентским
/// полям MessengerAuthContext не доверяем, идентичность берётся отсюда.
///
/// tenantId/productId — plain int (конвенция trust_token/contact_meta);
/// внешние ключи денормализованы строками, потому что verify оперирует
/// только MessengerAuthContext (там externalKey-и, не id) и атомарное
/// погашение должно уложиться в один UPDATE без join-ов.
abstract class ConnectIssuedToken implements _i1.SerializableModel {
  ConnectIssuedToken._({
    this.id,
    required this.tenantId,
    required this.productId,
    required this.tenantExternalKey,
    required this.productExternalKey,
    required this.externalUserId,
    required this.displayName,
    this.claimsJson,
    required this.tokenHash,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
  });

  factory ConnectIssuedToken({
    int? id,
    required int tenantId,
    required int productId,
    required String tenantExternalKey,
    required String productExternalKey,
    required String externalUserId,
    required String displayName,
    String? claimsJson,
    required String tokenHash,
    required DateTime expiresAt,
    DateTime? usedAt,
    required DateTime createdAt,
  }) = _ConnectIssuedTokenImpl;

  factory ConnectIssuedToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectIssuedToken(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int,
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
      productExternalKey: jsonSerialization['productExternalKey'] as String,
      externalUserId: jsonSerialization['externalUserId'] as String,
      displayName: jsonSerialization['displayName'] as String,
      claimsJson: jsonSerialization['claimsJson'] as String?,
      tokenHash: jsonSerialization['tokenHash'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
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

  int productId;

  /// Денормализованный Tenant.externalKey — для одно-UPDATE-ного
  /// погашения по контексту клиента. externalKey стабилен по контракту
  /// (см. tenant.spy.yaml), рассинхрон невозможен.
  String tenantExternalKey;

  /// Денормализованный Product.externalKey (та же причина).
  String productExternalKey;

  /// Канонический id пользователя в системе продукта — источник
  /// messenger-идентичности при погашении.
  String externalUserId;

  /// Отображаемое имя на момент выдачи. Пустая строка = продукт не дал
  /// имени (adapter вернёт null → identity mapping применит fallback).
  String displayName;

  /// **TASK78 п.3 (claims в issued-токенах)**: JSON-объект строка→строка
  /// с доменными признаками пользователя от продукт-сервера (например,
  /// `{"futbolista_organizer":"true"}`). Записывается при АВТОРИЗОВАННОЙ
  /// S2S-выдаче и при погашении уезжает в AuthAdapterResult.claims — тот
  /// же контракт, что у legacy-адаптеров варианта B (futbolista/titan),
  /// которые вариант C иначе терял. NULL = claims не переданы (старые
  /// строки живы, миграция аддитивная).
  String? claimsJson;

  /// sha256-hex от плейнтекст-токена (base64url, 32 байта энтропии).
  String tokenHash;

  /// Момент протухания: createdAt + ConnectIssuedTokenService.tokenTtl
  /// (5 минут). Индекс — под sweep.
  DateTime expiresAt;

  /// Момент одноразового погашения. Гасится атомарным
  /// `updateWhere ... where usedAt.equals(null)` — конкурентный повтор
  /// обязан провалиться (см. IssuedTokenAuthAdapter).
  DateTime? usedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [ConnectIssuedToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectIssuedToken copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? tenantExternalKey,
    String? productExternalKey,
    String? externalUserId,
    String? displayName,
    String? claimsJson,
    String? tokenHash,
    DateTime? expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectIssuedToken',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'externalUserId': externalUserId,
      'displayName': displayName,
      if (claimsJson != null) 'claimsJson': claimsJson,
      'tokenHash': tokenHash,
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectIssuedTokenImpl extends ConnectIssuedToken {
  _ConnectIssuedTokenImpl({
    int? id,
    required int tenantId,
    required int productId,
    required String tenantExternalKey,
    required String productExternalKey,
    required String externalUserId,
    required String displayName,
    String? claimsJson,
    required String tokenHash,
    required DateTime expiresAt,
    DateTime? usedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         tenantExternalKey: tenantExternalKey,
         productExternalKey: productExternalKey,
         externalUserId: externalUserId,
         displayName: displayName,
         claimsJson: claimsJson,
         tokenHash: tokenHash,
         expiresAt: expiresAt,
         usedAt: usedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConnectIssuedToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectIssuedToken copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? productId,
    String? tenantExternalKey,
    String? productExternalKey,
    String? externalUserId,
    String? displayName,
    Object? claimsJson = _Undefined,
    String? tokenHash,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return ConnectIssuedToken(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
      productExternalKey: productExternalKey ?? this.productExternalKey,
      externalUserId: externalUserId ?? this.externalUserId,
      displayName: displayName ?? this.displayName,
      claimsJson: claimsJson is String? ? claimsJson : this.claimsJson,
      tokenHash: tokenHash ?? this.tokenHash,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
