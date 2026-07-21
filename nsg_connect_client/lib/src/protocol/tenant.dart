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
import 'enums/tenant_hosting_mode.dart' as _i2;

/// Tenant — корневая многоарендная сущность платформы.
/// См. ТЗ §6 (identity model), §19 (admin), §20 (hosting modes).
abstract class Tenant implements _i1.SerializableModel {
  Tenant._({
    this.id,
    required this.externalKey,
    required this.name,
    required this.hostingMode,
    required this.localpartSecretEncrypted,
    this.connectServiceSecretHash,
    bool? connectIssuedTokenEnabled,
    this.connectServiceSecretHashPrev,
    this.connectServiceSecretPrevExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  }) : connectIssuedTokenEnabled = connectIssuedTokenEnabled ?? false;

  factory Tenant({
    int? id,
    required String externalKey,
    required String name,
    required _i2.TenantHostingMode hostingMode,
    required String localpartSecretEncrypted,
    String? connectServiceSecretHash,
    bool? connectIssuedTokenEnabled,
    String? connectServiceSecretHashPrev,
    DateTime? connectServiceSecretPrevExpiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TenantImpl;

  factory Tenant.fromJson(Map<String, dynamic> jsonSerialization) {
    return Tenant(
      id: jsonSerialization['id'] as int?,
      externalKey: jsonSerialization['externalKey'] as String,
      name: jsonSerialization['name'] as String,
      hostingMode: _i2.TenantHostingMode.fromJson(
        (jsonSerialization['hostingMode'] as String),
      ),
      localpartSecretEncrypted:
          jsonSerialization['localpartSecretEncrypted'] as String,
      connectServiceSecretHash:
          jsonSerialization['connectServiceSecretHash'] as String?,
      connectIssuedTokenEnabled:
          jsonSerialization['connectIssuedTokenEnabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['connectIssuedTokenEnabled'],
            ),
      connectServiceSecretHashPrev:
          jsonSerialization['connectServiceSecretHashPrev'] as String?,
      connectServiceSecretPrevExpiresAt:
          jsonSerialization['connectServiceSecretPrevExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['connectServiceSecretPrevExpiresAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Стабильный человеко-читаемый ключ, передаётся клиентом в
  /// MessengerAuthContext.tenantExternalKey. Например `nsg`, `customer-acme`.
  String externalKey;

  String name;

  _i2.TenantHostingMode hostingMode;

  /// AES-GCM-шифрованный 32-байтный секрет для HMAC-генерации Matrix
  /// localpart-ов (см. TASK07). Шифруется KEK-ом `tenantSecretKek`
  /// из passwords.yaml. Хранится как base64 от nonce(12)||ct||tag(16).
  /// Не меняется в течение жизни tenant-а — иначе ломается связь
  /// existing matrix-пользователей.
  /// Seed (TASK04) пишет sentinel-base64 от 64 нулевых байт; TASK07
  /// при первом обращении lazy-init-ит реальное значение через
  /// TenantSecretService.getOrInit() с SELECT FOR UPDATE.
  String localpartSecretEncrypted;

  /// **Вариант C** (DESIGN_CONNECT_ISSUED_TOKENS.md): sha256-hex от
  /// per-tenant serviceSecret для S2S-выдачи connect-токенов
  /// (ConnectTokenEndpoint.issueToken). NULL = issued-token-режим для
  /// tenant-а выключен на стороне выдачи. Хранится ТОЛЬКО хэш —
  /// плейнтекст секрета живёт в конфиге продукт-сервера; сравнение
  /// constant-time (ConnectIssuedTokenService.verifySecret).
  String? connectServiceSecretHash;

  /// **TASK78 п.1**: issued-token-режим включён для этого tenant-а.
  /// Читается СВЕЖИМ на каждой аутентификации (`_authenticate` и так
  /// грузит tenant перед резолвом адаптера), поэтому включение/отзыв
  /// действуют БЕЗ рестарта и без кэша реестра — флаг и есть источник
  /// правды. Раньше режим задавался env `CONNECT_ISSUED_TOKEN_TENANTS`
  /// (тот остаётся legacy-оверрайдом для обратной совместимости).
  /// `enabled == false` → динамический адаптер не резолвится, tenant
  /// получает прежний AdapterNotConfiguredException.
  bool connectIssuedTokenEnabled;

  /// **TASK78 п.2 (ротация без простоя)**: предыдущий sha256-хэш секрета,
  /// принимается наравне с текущим до [connectServiceSecretPrevExpiresAt].
  /// Даёт продукту grace-окно на выкатку нового секрета: ротировали →
  /// старый ещё работает N минут → продукт обновил конфиг → старый
  /// протух. NULL — grace не активен.
  String? connectServiceSecretHashPrev;

  /// Момент, после которого [connectServiceSecretHashPrev] перестаёт
  /// приниматься. NULL когда prev не задан.
  DateTime? connectServiceSecretPrevExpiresAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Tenant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Tenant copyWith({
    int? id,
    String? externalKey,
    String? name,
    _i2.TenantHostingMode? hostingMode,
    String? localpartSecretEncrypted,
    String? connectServiceSecretHash,
    bool? connectIssuedTokenEnabled,
    String? connectServiceSecretHashPrev,
    DateTime? connectServiceSecretPrevExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Tenant',
      if (id != null) 'id': id,
      'externalKey': externalKey,
      'name': name,
      'hostingMode': hostingMode.toJson(),
      'localpartSecretEncrypted': localpartSecretEncrypted,
      if (connectServiceSecretHash != null)
        'connectServiceSecretHash': connectServiceSecretHash,
      'connectIssuedTokenEnabled': connectIssuedTokenEnabled,
      if (connectServiceSecretHashPrev != null)
        'connectServiceSecretHashPrev': connectServiceSecretHashPrev,
      if (connectServiceSecretPrevExpiresAt != null)
        'connectServiceSecretPrevExpiresAt': connectServiceSecretPrevExpiresAt
            ?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TenantImpl extends Tenant {
  _TenantImpl({
    int? id,
    required String externalKey,
    required String name,
    required _i2.TenantHostingMode hostingMode,
    required String localpartSecretEncrypted,
    String? connectServiceSecretHash,
    bool? connectIssuedTokenEnabled,
    String? connectServiceSecretHashPrev,
    DateTime? connectServiceSecretPrevExpiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         externalKey: externalKey,
         name: name,
         hostingMode: hostingMode,
         localpartSecretEncrypted: localpartSecretEncrypted,
         connectServiceSecretHash: connectServiceSecretHash,
         connectIssuedTokenEnabled: connectIssuedTokenEnabled,
         connectServiceSecretHashPrev: connectServiceSecretHashPrev,
         connectServiceSecretPrevExpiresAt: connectServiceSecretPrevExpiresAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Tenant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Tenant copyWith({
    Object? id = _Undefined,
    String? externalKey,
    String? name,
    _i2.TenantHostingMode? hostingMode,
    String? localpartSecretEncrypted,
    Object? connectServiceSecretHash = _Undefined,
    bool? connectIssuedTokenEnabled,
    Object? connectServiceSecretHashPrev = _Undefined,
    Object? connectServiceSecretPrevExpiresAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id is int? ? id : this.id,
      externalKey: externalKey ?? this.externalKey,
      name: name ?? this.name,
      hostingMode: hostingMode ?? this.hostingMode,
      localpartSecretEncrypted:
          localpartSecretEncrypted ?? this.localpartSecretEncrypted,
      connectServiceSecretHash: connectServiceSecretHash is String?
          ? connectServiceSecretHash
          : this.connectServiceSecretHash,
      connectIssuedTokenEnabled:
          connectIssuedTokenEnabled ?? this.connectIssuedTokenEnabled,
      connectServiceSecretHashPrev: connectServiceSecretHashPrev is String?
          ? connectServiceSecretHashPrev
          : this.connectServiceSecretHashPrev,
      connectServiceSecretPrevExpiresAt:
          connectServiceSecretPrevExpiresAt is DateTime?
          ? connectServiceSecretPrevExpiresAt
          : this.connectServiceSecretPrevExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
