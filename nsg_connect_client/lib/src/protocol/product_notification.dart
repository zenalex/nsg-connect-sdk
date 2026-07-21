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
import 'enums/product_notification_status.dart' as _i2;

/// **TASK72**: журнал приёма продуктовых уведомлений + носитель
/// идемпотентности. Одна строка = один адресат одной рассылки.
///
/// **Зачем строка на адресата, а не на рассылку.** Продукт шлёт ОДИН
/// `idempotencyKey` на batch (событие матча → обе команды), но дедуп и
/// журнал нужны per-recipient: при rehandle-петле продукта уже
/// доставленный адресат должен схлопнуться в `deduped`, а добавленный
/// позже — получить push. Поэтому в колонке `idempotencyKey` лежит
/// ЭФФЕКТИВНЫЙ (составной) ключ `<len>:<rawKey>:<externalUserId>`
/// (см. `ProductNotificationService.effectiveIdempotencyKey`), а
/// уникальный индекс `(productId, idempotencyKey)` даёт ровно одну
/// строку на (продукт, событие, адресат).
///
/// **Почему НЕ храним title/body.** Осознанное решение приватности:
/// содержимое продуктового уведомления — это PII/чувствительные данные
/// (код верификации, персональное событие пользователя), а журнал живёт
/// под TTL и нужен для ДЕДУПА и НАБЛЮДАЕМОСТИ, не для аудита контента.
/// Дедуп держится на `idempotencyKey`, а не на тексте, поэтому хранение
/// текста повышало бы приватностный риск без операционной пользы. Тот же
/// мотив, что в комментарии CleanupConnectIssuedTokensFutureCall про PII.
/// `externalUserId` храним (нужен для per-recipient журнала и
/// диагностики «уведомили ли X») — это та же PII, что уже лежит в
/// connect_issued_tokens.
///
/// tenantId/productId — plain int (конвенция connect_issued_token):
/// журнал пишется в авторизованном S2S-вызове, join-ы на горячем пути
/// не нужны.
abstract class ProductNotification implements _i1.SerializableModel {
  ProductNotification._({
    this.id,
    required this.tenantId,
    required this.productId,
    required this.externalUserId,
    required this.idempotencyKey,
    required this.status,
    required this.deviceCount,
    required this.createdAt,
  });

  factory ProductNotification({
    int? id,
    required int tenantId,
    required int productId,
    required String externalUserId,
    required String idempotencyKey,
    required _i2.ProductNotificationStatus status,
    required int deviceCount,
    required DateTime createdAt,
  }) = _ProductNotificationImpl;

  factory ProductNotification.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProductNotification(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int,
      externalUserId: jsonSerialization['externalUserId'] as String,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      status: _i2.ProductNotificationStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      deviceCount: jsonSerialization['deviceCount'] as int,
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

  /// Канонический id пользователя в системе продукта (адресат).
  String externalUserId;

  /// ЭФФЕКТИВНЫЙ ключ идемпотентности (составной, per-recipient) —
  /// см. docstring класса. На нём держится уникальный индекс.
  String idempotencyKey;

  _i2.ProductNotificationStatus status;

  /// Сколько устройств адресата приняли payload (0 при noDevices/deduped).
  int deviceCount;

  DateTime createdAt;

  /// Returns a shallow copy of this [ProductNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductNotification copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? externalUserId,
    String? idempotencyKey,
    _i2.ProductNotificationStatus? status,
    int? deviceCount,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductNotification',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'externalUserId': externalUserId,
      'idempotencyKey': idempotencyKey,
      'status': status.toJson(),
      'deviceCount': deviceCount,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProductNotificationImpl extends ProductNotification {
  _ProductNotificationImpl({
    int? id,
    required int tenantId,
    required int productId,
    required String externalUserId,
    required String idempotencyKey,
    required _i2.ProductNotificationStatus status,
    required int deviceCount,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         externalUserId: externalUserId,
         idempotencyKey: idempotencyKey,
         status: status,
         deviceCount: deviceCount,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ProductNotification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductNotification copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? productId,
    String? externalUserId,
    String? idempotencyKey,
    _i2.ProductNotificationStatus? status,
    int? deviceCount,
    DateTime? createdAt,
  }) {
    return ProductNotification(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      externalUserId: externalUserId ?? this.externalUserId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      deviceCount: deviceCount ?? this.deviceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
