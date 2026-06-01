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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tenant({
    int? id,
    required String externalKey,
    required String name,
    required _i2.TenantHostingMode hostingMode,
    required String localpartSecretEncrypted,
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
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         externalKey: externalKey,
         name: name,
         hostingMode: hostingMode,
         localpartSecretEncrypted: localpartSecretEncrypted,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
