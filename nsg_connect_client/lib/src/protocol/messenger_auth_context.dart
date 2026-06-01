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

/// Auth-контекст, который SDK передаёт в MessengerEndpoint.session().
/// См. ТЗ §7, TASK05/TASK12.
///
/// Это DTO (без `table:`) — не персистится, передаётся каждый раз заново.
abstract class MessengerAuthContext implements _i1.SerializableModel {
  MessengerAuthContext._({
    required this.tenantExternalKey,
    this.productExternalKey,
    required this.identityProvider,
    required this.externalUserId,
    required this.accessToken,
    this.deviceId,
  });

  factory MessengerAuthContext({
    required String tenantExternalKey,
    String? productExternalKey,
    required _i2.IdentityProvider identityProvider,
    required String externalUserId,
    required String accessToken,
    String? deviceId,
  }) = _MessengerAuthContextImpl;

  factory MessengerAuthContext.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MessengerAuthContext(
      tenantExternalKey: jsonSerialization['tenantExternalKey'] as String,
      productExternalKey: jsonSerialization['productExternalKey'] as String?,
      identityProvider: _i2.IdentityProvider.fromJson(
        (jsonSerialization['identityProvider'] as String),
      ),
      externalUserId: jsonSerialization['externalUserId'] as String,
      accessToken: jsonSerialization['accessToken'] as String,
      deviceId: jsonSerialization['deviceId'] as String?,
    );
  }

  /// Стабильный ключ tenant-а (см. Tenant.externalKey).
  String tenantExternalKey;

  /// Опциональный ключ продукта в этом tenant-е (Product.externalKey).
  /// NULL = standalone-вход без привязки к конкретному продукту.
  String? productExternalKey;

  /// Крупный bucket identity (nsg / customer / guest).
  /// `identityProviderKey` определяется адаптером, не передаётся клиентом
  /// (см. CustomerAuthAdapter.identityProviderKey).
  _i2.IdentityProvider identityProvider;

  /// ID пользователя в системе заказчика / NSG-приложения.
  String externalUserId;

  /// Token, который проверит CustomerAuthAdapter.verify(). Внутренняя
  /// структура зависит от адаптера: JWT, opaque token, что угодно.
  String accessToken;

  /// Опциональный идентификатор устройства SDK. Используется для
  /// push-регистрации (TASK20) и для multi-device сессий.
  String? deviceId;

  /// Returns a shallow copy of this [MessengerAuthContext]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerAuthContext copyWith({
    String? tenantExternalKey,
    String? productExternalKey,
    _i2.IdentityProvider? identityProvider,
    String? externalUserId,
    String? accessToken,
    String? deviceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerAuthContext',
      'tenantExternalKey': tenantExternalKey,
      if (productExternalKey != null) 'productExternalKey': productExternalKey,
      'identityProvider': identityProvider.toJson(),
      'externalUserId': externalUserId,
      'accessToken': accessToken,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerAuthContextImpl extends MessengerAuthContext {
  _MessengerAuthContextImpl({
    required String tenantExternalKey,
    String? productExternalKey,
    required _i2.IdentityProvider identityProvider,
    required String externalUserId,
    required String accessToken,
    String? deviceId,
  }) : super._(
         tenantExternalKey: tenantExternalKey,
         productExternalKey: productExternalKey,
         identityProvider: identityProvider,
         externalUserId: externalUserId,
         accessToken: accessToken,
         deviceId: deviceId,
       );

  /// Returns a shallow copy of this [MessengerAuthContext]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerAuthContext copyWith({
    String? tenantExternalKey,
    Object? productExternalKey = _Undefined,
    _i2.IdentityProvider? identityProvider,
    String? externalUserId,
    String? accessToken,
    Object? deviceId = _Undefined,
  }) {
    return MessengerAuthContext(
      tenantExternalKey: tenantExternalKey ?? this.tenantExternalKey,
      productExternalKey: productExternalKey is String?
          ? productExternalKey
          : this.productExternalKey,
      identityProvider: identityProvider ?? this.identityProvider,
      externalUserId: externalUserId ?? this.externalUserId,
      accessToken: accessToken ?? this.accessToken,
      deviceId: deviceId is String? ? deviceId : this.deviceId,
    );
  }
}
