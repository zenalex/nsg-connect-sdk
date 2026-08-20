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

/// Product — конкретное приложение, в которое встроен мессенджер.
/// Например для tenant `nsg`: products `chatista`, `futbolista`, `artista`.
/// См. ТЗ §3, §13.
abstract class Product implements _i1.SerializableModel {
  Product._({
    this.id,
    required this.tenantId,
    required this.externalKey,
    required this.displayName,
    this.pushBrandingJson,
    this.authAdapterConfigJson,
    String? deliveryTransport,
    String? defaultLocale,
    required this.createdAt,
    required this.updatedAt,
  }) : deliveryTransport = deliveryTransport ?? 'platformPush',
       defaultLocale = defaultLocale ?? 'ru';

  factory Product({
    int? id,
    required int tenantId,
    required String externalKey,
    required String displayName,
    String? pushBrandingJson,
    String? authAdapterConfigJson,
    String? deliveryTransport,
    String? defaultLocale,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductImpl;

  factory Product.fromJson(Map<String, dynamic> jsonSerialization) {
    return Product(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      externalKey: jsonSerialization['externalKey'] as String,
      displayName: jsonSerialization['displayName'] as String,
      pushBrandingJson: jsonSerialization['pushBrandingJson'] as String?,
      authAdapterConfigJson:
          jsonSerialization['authAdapterConfigJson'] as String?,
      deliveryTransport: jsonSerialization['deliveryTransport'] as String?,
      defaultLocale: jsonSerialization['defaultLocale'] as String?,
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

  /// FK на Tenant. Cascade-delete: продукты удаляются вместе с tenant-ом.
  int tenantId;

  /// Стабильный ключ продукта, передаётся клиентом в MessengerAuthContext.
  /// Например `chatista`, `futbolista`.
  String externalKey;

  String displayName;

  /// PushBranding и AuthAdapter-конфиги хранятся в JSON.
  /// Структура — задача TASK28 / TASK24, на TASK04 поле просто заведено.
  String? pushBrandingJson;

  String? authAdapterConfigJson;

  /// **Модуль доставки (#121)**: чем везётся ПОСЛЕДНЯЯ МИЛЯ побудки.
  /// Решение «будить ли этого человека» остаётся у платформы всегда —
  /// оно требует знания о членстве, заглушении, упоминании, архиве и
  /// факте показа на другом устройстве, и отдавать его наружу значит
  /// получить кривую копию правил (см. DESIGN_CONNECT_DELIVERY_MODULE §2).
  ///
  /// `platformPush` — сами дёргаем FCM/RuStore ключами продукта (как
  /// было всегда). `webhook` — шлём готовую инструкцию их серверу
  /// существующей машиной подписок; годится продукту со СВОИМ реестром
  /// устройств. Дефолт делает миграцию тождественной.
  ///
  /// Звонки этим полем не управляются: VoIP-побудка обязана дойти за
  /// секунды (CallKit ждёт ограниченное время), и лишний прыжок через
  /// чужой сервер — это и задержка, и точка отказа.
  String deliveryTransport;

  String defaultLocale;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Product copyWith({
    int? id,
    int? tenantId,
    String? externalKey,
    String? displayName,
    String? pushBrandingJson,
    String? authAdapterConfigJson,
    String? deliveryTransport,
    String? defaultLocale,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Product',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'externalKey': externalKey,
      'displayName': displayName,
      if (pushBrandingJson != null) 'pushBrandingJson': pushBrandingJson,
      if (authAdapterConfigJson != null)
        'authAdapterConfigJson': authAdapterConfigJson,
      'deliveryTransport': deliveryTransport,
      'defaultLocale': defaultLocale,
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

class _ProductImpl extends Product {
  _ProductImpl({
    int? id,
    required int tenantId,
    required String externalKey,
    required String displayName,
    String? pushBrandingJson,
    String? authAdapterConfigJson,
    String? deliveryTransport,
    String? defaultLocale,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         externalKey: externalKey,
         displayName: displayName,
         pushBrandingJson: pushBrandingJson,
         authAdapterConfigJson: authAdapterConfigJson,
         deliveryTransport: deliveryTransport,
         defaultLocale: defaultLocale,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Product copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? externalKey,
    String? displayName,
    Object? pushBrandingJson = _Undefined,
    Object? authAdapterConfigJson = _Undefined,
    String? deliveryTransport,
    String? defaultLocale,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      externalKey: externalKey ?? this.externalKey,
      displayName: displayName ?? this.displayName,
      pushBrandingJson: pushBrandingJson is String?
          ? pushBrandingJson
          : this.pushBrandingJson,
      authAdapterConfigJson: authAdapterConfigJson is String?
          ? authAdapterConfigJson
          : this.authAdapterConfigJson,
      deliveryTransport: deliveryTransport ?? this.deliveryTransport,
      defaultLocale: defaultLocale ?? this.defaultLocale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
