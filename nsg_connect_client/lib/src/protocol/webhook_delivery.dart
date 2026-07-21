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

/// WebhookDelivery — лог одной попытки/жизненного цикла доставки события
/// в подписку (TASK35). Служит одновременно журналом и DLQ: строки со
/// `status='dead'` — это окончательно непроставленные события (исчерпан
/// ретрай или мёртвая/невалидная подписка).
///
/// Lifecycle статусов:
///   pending  — вставлена, первая попытка запланирована FutureCall-ом.
///   failed   — попытка не удалась, есть ещё ретраи (см. nextRetryAt).
///   success  — 2xx-ответ получен.
///   dead     — DLQ: ретраи исчерпаны / подписка невалидна / SSRF-reject.
abstract class WebhookDelivery implements _i1.SerializableModel {
  WebhookDelivery._({
    this.id,
    required this.subscriptionId,
    this.eventId,
    required this.eventType,
    required this.payload,
    required this.status,
    int? attempt,
    this.statusCode,
    this.error,
    required this.createdAt,
    this.deliveredAt,
    this.nextRetryAt,
  }) : attempt = attempt ?? 0;

  factory WebhookDelivery({
    int? id,
    required int subscriptionId,
    String? eventId,
    required String eventType,
    required String payload,
    required String status,
    int? attempt,
    int? statusCode,
    String? error,
    required DateTime createdAt,
    DateTime? deliveredAt,
    DateTime? nextRetryAt,
  }) = _WebhookDeliveryImpl;

  factory WebhookDelivery.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookDelivery(
      id: jsonSerialization['id'] as int?,
      subscriptionId: jsonSerialization['subscriptionId'] as int,
      eventId: jsonSerialization['eventId'] as String?,
      eventType: jsonSerialization['eventType'] as String,
      payload: jsonSerialization['payload'] as String,
      status: jsonSerialization['status'] as String,
      attempt: jsonSerialization['attempt'] as int?,
      statusCode: jsonSerialization['statusCode'] as int?,
      error: jsonSerialization['error'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deliveredAt: jsonSerialization['deliveredAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['deliveredAt'],
            ),
      nextRetryAt: jsonSerialization['nextRetryAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextRetryAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на подписку. Cascade-delete: журнал удаляется вместе с подпиской.
  int subscriptionId;

  /// Идемпотентный ключ доменного события (`buildWebhookEventId` →
  /// `<eventType>:<натуральный ключ>`). Вместе с `subscriptionId` даёт
  /// unique-ключ: одно доменное событие → максимум одна delivery в
  /// подписку, сколько бы publisher-ов его ни опубликовало (см. дедуп
  /// на 23505 в WebhookDispatchWorker).
  ///
  /// Nullable ТОЛЬКО ради строк, вставленных до этой миграции: NOT NULL
  /// без default не накатился бы на непустую таблицу. Новые строки поле
  /// всегда заполняют (envelope.eventId — required). Легаси-строки друг
  /// другу не мешают: в Postgres NULL-ы в unique-индексе считаются
  /// различными.
  String? eventId;

  String eventType;

  /// JSON-тело, которое (будет) отправлено POST-ом. Хранится целиком —
  /// для пере-доставки на ретрае и для DLQ-инспекции.
  String payload;

  /// 'pending' | 'failed' | 'success' | 'dead'.
  String status;

  /// Сколько попыток доставки уже сделано (0 = ещё ни одной).
  int attempt;

  /// HTTP-код последней попытки (null если сети не было — timeout/DNS).
  int? statusCode;

  /// Сообщение об ошибке последней попытки (timeout/4xx/5xx/network).
  String? error;

  DateTime createdAt;

  DateTime? deliveredAt;

  /// Когда запланирована следующая попытка (для status='failed').
  DateTime? nextRetryAt;

  /// Returns a shallow copy of this [WebhookDelivery]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookDelivery copyWith({
    int? id,
    int? subscriptionId,
    String? eventId,
    String? eventType,
    String? payload,
    String? status,
    int? attempt,
    int? statusCode,
    String? error,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? nextRetryAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookDelivery',
      if (id != null) 'id': id,
      'subscriptionId': subscriptionId,
      if (eventId != null) 'eventId': eventId,
      'eventType': eventType,
      'payload': payload,
      'status': status,
      'attempt': attempt,
      if (statusCode != null) 'statusCode': statusCode,
      if (error != null) 'error': error,
      'createdAt': createdAt.toJson(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt?.toJson(),
      if (nextRetryAt != null) 'nextRetryAt': nextRetryAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebhookDeliveryImpl extends WebhookDelivery {
  _WebhookDeliveryImpl({
    int? id,
    required int subscriptionId,
    String? eventId,
    required String eventType,
    required String payload,
    required String status,
    int? attempt,
    int? statusCode,
    String? error,
    required DateTime createdAt,
    DateTime? deliveredAt,
    DateTime? nextRetryAt,
  }) : super._(
         id: id,
         subscriptionId: subscriptionId,
         eventId: eventId,
         eventType: eventType,
         payload: payload,
         status: status,
         attempt: attempt,
         statusCode: statusCode,
         error: error,
         createdAt: createdAt,
         deliveredAt: deliveredAt,
         nextRetryAt: nextRetryAt,
       );

  /// Returns a shallow copy of this [WebhookDelivery]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookDelivery copyWith({
    Object? id = _Undefined,
    int? subscriptionId,
    Object? eventId = _Undefined,
    String? eventType,
    String? payload,
    String? status,
    int? attempt,
    Object? statusCode = _Undefined,
    Object? error = _Undefined,
    DateTime? createdAt,
    Object? deliveredAt = _Undefined,
    Object? nextRetryAt = _Undefined,
  }) {
    return WebhookDelivery(
      id: id is int? ? id : this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      eventId: eventId is String? ? eventId : this.eventId,
      eventType: eventType ?? this.eventType,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempt: attempt ?? this.attempt,
      statusCode: statusCode is int? ? statusCode : this.statusCode,
      error: error is String? ? error : this.error,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt is DateTime? ? deliveredAt : this.deliveredAt,
      nextRetryAt: nextRetryAt is DateTime? ? nextRetryAt : this.nextRetryAt,
    );
  }
}
