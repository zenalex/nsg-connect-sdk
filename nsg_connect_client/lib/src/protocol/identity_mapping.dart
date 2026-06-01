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
import 'enums/identity_provider.dart' as _i2;

/// IdentityMapping — связка external user (заказчик/NSG-приложение)
/// ↔ messenger user. См. ТЗ §6 + архитектурное решение TASK04
/// об identity scope = (tenant, identityProviderKey).
///
/// `identityProvider` — крупный bucket (nsg/customer/guest).
/// `identityProviderKey` — уточнение namespace-а внутри bucket-а:
///   default — совпадает с tenantExternalKey;
///   per-product изоляция — разные адаптеры одного tenant-а возвращают
///   разные ключи (например 'customer-A' vs 'customer-B').
///
/// Уникальность гарантируется по (tenantId, identityProvider,
/// identityProviderKey, externalUserId).
abstract class IdentityMapping implements _i1.SerializableModel {
  IdentityMapping._({
    this.id,
    required this.messengerUserId,
    required this.tenantId,
    this.productId,
    required this.identityProvider,
    required this.identityProviderKey,
    required this.externalUserId,
    required this.createdAt,
  });

  factory IdentityMapping({
    int? id,
    required int messengerUserId,
    required int tenantId,
    int? productId,
    required _i2.IdentityProvider identityProvider,
    required String identityProviderKey,
    required String externalUserId,
    required DateTime createdAt,
  }) = _IdentityMappingImpl;

  factory IdentityMapping.fromJson(Map<String, dynamic> jsonSerialization) {
    return IdentityMapping(
      id: jsonSerialization['id'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      identityProvider: _i2.IdentityProvider.fromJson(
        (jsonSerialization['identityProvider'] as String),
      ),
      identityProviderKey: jsonSerialization['identityProviderKey'] as String,
      externalUserId: jsonSerialization['externalUserId'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int messengerUserId;

  int tenantId;

  int? productId;

  _i2.IdentityProvider identityProvider;

  String identityProviderKey;

  String externalUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [IdentityMapping]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IdentityMapping copyWith({
    int? id,
    int? messengerUserId,
    int? tenantId,
    int? productId,
    _i2.IdentityProvider? identityProvider,
    String? identityProviderKey,
    String? externalUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IdentityMapping',
      if (id != null) 'id': id,
      'messengerUserId': messengerUserId,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'identityProvider': identityProvider.toJson(),
      'identityProviderKey': identityProviderKey,
      'externalUserId': externalUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IdentityMappingImpl extends IdentityMapping {
  _IdentityMappingImpl({
    int? id,
    required int messengerUserId,
    required int tenantId,
    int? productId,
    required _i2.IdentityProvider identityProvider,
    required String identityProviderKey,
    required String externalUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         messengerUserId: messengerUserId,
         tenantId: tenantId,
         productId: productId,
         identityProvider: identityProvider,
         identityProviderKey: identityProviderKey,
         externalUserId: externalUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [IdentityMapping]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IdentityMapping copyWith({
    Object? id = _Undefined,
    int? messengerUserId,
    int? tenantId,
    Object? productId = _Undefined,
    _i2.IdentityProvider? identityProvider,
    String? identityProviderKey,
    String? externalUserId,
    DateTime? createdAt,
  }) {
    return IdentityMapping(
      id: id is int? ? id : this.id,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      identityProvider: identityProvider ?? this.identityProvider,
      identityProviderKey: identityProviderKey ?? this.identityProviderKey,
      externalUserId: externalUserId ?? this.externalUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
