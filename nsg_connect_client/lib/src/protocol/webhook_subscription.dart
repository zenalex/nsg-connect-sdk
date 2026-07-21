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

/// WebhookSubscription — подписка внешнего сервиса на доменные события
/// мессенджера (TASK35 outbound webhooks MVP). Каждая строка — один
/// endpoint (`url`), которому платформа доставляет HMAC-подписанные
/// события, проходящие фильтр по `tenantId`/`productId`/`eventTypes`.
///
/// Циркуляр-брейкер: `failureCount` копит consecutive-fails delivery-worker-а;
/// при достижении порога подписка авто-дизейблится (`enabled=false`,
/// `disabledAt`), чтобы не долбить мёртвый endpoint бесконечно. Admin
/// может ре-энейблить через `updateSubscription` (сбрасывает счётчик).
abstract class WebhookSubscription implements _i1.SerializableModel {
  WebhookSubscription._({
    this.id,
    required this.tenantId,
    this.productId,
    required this.url,
    required this.secret,
    required this.eventTypes,
    this.roomId,
    this.botId,
    bool? enabled,
    int? failureCount,
    this.lastSuccessAt,
    this.disabledAt,
    this.description,
    required this.createdAt,
  }) : enabled = enabled ?? true,
       failureCount = failureCount ?? 0;

  factory WebhookSubscription({
    int? id,
    required int tenantId,
    int? productId,
    required String url,
    required String secret,
    required String eventTypes,
    int? roomId,
    int? botId,
    bool? enabled,
    int? failureCount,
    DateTime? lastSuccessAt,
    DateTime? disabledAt,
    String? description,
    required DateTime createdAt,
  }) = _WebhookSubscriptionImpl;

  factory WebhookSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookSubscription(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      url: jsonSerialization['url'] as String,
      secret: jsonSerialization['secret'] as String,
      eventTypes: jsonSerialization['eventTypes'] as String,
      roomId: jsonSerialization['roomId'] as int?,
      botId: jsonSerialization['botId'] as int?,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      failureCount: jsonSerialization['failureCount'] as int?,
      lastSuccessAt: jsonSerialization['lastSuccessAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSuccessAt'],
            ),
      disabledAt: jsonSerialization['disabledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['disabledAt']),
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade-delete: подписки удаляются вместе с tenant-ом.
  int tenantId;

  /// NULL = подписка на события всего tenant-а (любой продукт). Иначе —
  /// только события этого продукта. SetNull: при удалении продукта
  /// подписка остаётся (становится tenant-wide).
  int? productId;

  /// Целевой HTTPS-URL. Валидируется SSRF-гардом (WebhookUrlValidator)
  /// на create/update и повторно перед каждой доставкой.
  String url;

  /// Секрет для HMAC-SHA256 подписи тела (заголовок X-Webhook-Signature).
  String secret;

  /// CSV имён webhook-событий, на которые подписан endpoint, например
  /// `message.created,room.created`. Low-cardinality — фильтруем в Dart
  /// (substring/exact match по элементам), без отдельной таблицы.
  String eventTypes;

  /// TASK59 (self-service бот-интеграция): room-scoped подписка — доставлять
  /// ТОЛЬКО события, чей `payload.roomId == roomId`. null = прежнее поведение
  /// (tenant/product-wide). Cascade: удаляется вместе с комнатой.
  int? roomId;

  /// TASK59: если задан — подписка принадлежит self-service бот-интеграции
  /// (ротация/отзыв вместе с ботом). null = обычная admin-подписка (TASK35).
  int? botId;

  bool enabled;

  /// Подряд идущих неуспешных ПОПЫТОК доставки (failed HTTP call) для
  /// circuit-breaker — по каждой попытке, не по одной на исчерпавшую ретраи
  /// доставку, иначе мёртвый endpoint не дизейблился бы за разумное время.
  /// Admin-тест (`webhook.test`) не учитывается. Сбрасывается в 0 на первой
  /// успешной доставке.
  int failureCount;

  DateTime? lastSuccessAt;

  /// Выставляется когда circuit-breaker авто-дизейблит подписку.
  DateTime? disabledAt;

  String? description;

  DateTime createdAt;

  /// Returns a shallow copy of this [WebhookSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookSubscription copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? url,
    String? secret,
    String? eventTypes,
    int? roomId,
    int? botId,
    bool? enabled,
    int? failureCount,
    DateTime? lastSuccessAt,
    DateTime? disabledAt,
    String? description,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookSubscription',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'url': url,
      'secret': secret,
      'eventTypes': eventTypes,
      if (roomId != null) 'roomId': roomId,
      if (botId != null) 'botId': botId,
      'enabled': enabled,
      'failureCount': failureCount,
      if (lastSuccessAt != null) 'lastSuccessAt': lastSuccessAt?.toJson(),
      if (disabledAt != null) 'disabledAt': disabledAt?.toJson(),
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebhookSubscriptionImpl extends WebhookSubscription {
  _WebhookSubscriptionImpl({
    int? id,
    required int tenantId,
    int? productId,
    required String url,
    required String secret,
    required String eventTypes,
    int? roomId,
    int? botId,
    bool? enabled,
    int? failureCount,
    DateTime? lastSuccessAt,
    DateTime? disabledAt,
    String? description,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         url: url,
         secret: secret,
         eventTypes: eventTypes,
         roomId: roomId,
         botId: botId,
         enabled: enabled,
         failureCount: failureCount,
         lastSuccessAt: lastSuccessAt,
         disabledAt: disabledAt,
         description: description,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WebhookSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookSubscription copyWith({
    Object? id = _Undefined,
    int? tenantId,
    Object? productId = _Undefined,
    String? url,
    String? secret,
    String? eventTypes,
    Object? roomId = _Undefined,
    Object? botId = _Undefined,
    bool? enabled,
    int? failureCount,
    Object? lastSuccessAt = _Undefined,
    Object? disabledAt = _Undefined,
    Object? description = _Undefined,
    DateTime? createdAt,
  }) {
    return WebhookSubscription(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      url: url ?? this.url,
      secret: secret ?? this.secret,
      eventTypes: eventTypes ?? this.eventTypes,
      roomId: roomId is int? ? roomId : this.roomId,
      botId: botId is int? ? botId : this.botId,
      enabled: enabled ?? this.enabled,
      failureCount: failureCount ?? this.failureCount,
      lastSuccessAt: lastSuccessAt is DateTime?
          ? lastSuccessAt
          : this.lastSuccessAt,
      disabledAt: disabledAt is DateTime? ? disabledAt : this.disabledAt,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
