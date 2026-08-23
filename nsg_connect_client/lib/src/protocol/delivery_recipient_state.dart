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

/// **issue #160**: состояние адресата — компактная форма, из которой
/// собирается реестр.
///
/// **Зачем отдельная таблица.** До #159 «кому мы шлём в пустоту» читалось
/// по журналу: каждое оповещение писало строку, в том числе безнадёжное.
/// От этого журнал за сутки набирал 12 608 строк, из которых 12 603
/// бесполезны, и мы перестали такие строки писать. Но вопрос-то остался —
/// его и задаёт реестр (§2.2 DESIGN_CONNECT_DELIVERY_ACCOUNTING). Значит
/// нужна форма, которая переживает уборку журнала и не растёт вместе с
/// потоком.
///
/// **Строка на адресата, а не на событие.** Здесь ровно то, что нужно
/// ответу «дойдёт ли до него»: последняя попытка, последняя доставка,
/// последняя причина отказа. Титановская петля на 3020 оповещений в сутки
/// даёт тут ДВЕ строки — по числу дежурных, а не по числу тревог. Цена
/// хранения пропорциональна размеру беды, а не объёму трафика.
///
/// **Счётчики пожизненные, и это сказано вслух.** «Сколько попыток за
/// март» отсюда не достать — для этого есть `delivery_usage` (#158),
/// который считает по часам. Здесь другое: сам факт, что в этот адрес
/// стучались 45 000 раз и ни разу не попали.
abstract class DeliveryRecipientState implements _i1.SerializableModel {
  DeliveryRecipientState._({
    this.id,
    required this.tenantId,
    required this.productId,
    required this.externalUserId,
    required this.firstAttemptAt,
    required this.lastAttemptAt,
    this.lastDeliveredAt,
    required this.lastStatus,
    this.lastReason,
    int? attemptsTotal,
    int? undeliveredTotal,
    required this.updatedAt,
  }) : attemptsTotal = attemptsTotal ?? 0,
       undeliveredTotal = undeliveredTotal ?? 0;

  factory DeliveryRecipientState({
    int? id,
    required int tenantId,
    required int productId,
    required String externalUserId,
    required DateTime firstAttemptAt,
    required DateTime lastAttemptAt,
    DateTime? lastDeliveredAt,
    required String lastStatus,
    String? lastReason,
    int? attemptsTotal,
    int? undeliveredTotal,
    required DateTime updatedAt,
  }) = _DeliveryRecipientStateImpl;

  factory DeliveryRecipientState.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeliveryRecipientState(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int,
      externalUserId: jsonSerialization['externalUserId'] as String,
      firstAttemptAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstAttemptAt'],
      ),
      lastAttemptAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastAttemptAt'],
      ),
      lastDeliveredAt: jsonSerialization['lastDeliveredAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastDeliveredAt'],
            ),
      lastStatus: jsonSerialization['lastStatus'] as String,
      lastReason: jsonSerialization['lastReason'] as String?,
      attemptsTotal: jsonSerialization['attemptsTotal'] as int?,
      undeliveredTotal: jsonSerialization['undeliveredTotal'] as int?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// Продукт обязателен: один и тот же человек у разных продуктов —
  /// разные пути доставки и разные их беды.
  int productId;

  /// Идентификатор адресата в системе продукта — тот же, что в отправке.
  String externalUserId;

  /// Первое обращение к этому адресату. Отвечает на «давно ли это тянется».
  DateTime firstAttemptAt;

  /// Последнее обращение — по нему реестр отбирает адресатов за период.
  DateTime lastAttemptAt;

  /// Когда последний раз ХОТЬ ЧТО-ТО ушло на устройство. NULL здесь —
  /// главный признак пустоты: сколько бы ни было попыток, ни одна не
  /// дошла до отправки.
  DateTime? lastDeliveredAt;

  /// Исход последней попытки (`ProductNotificationStatus.name`).
  String lastStatus;

  /// Причина последнего отказа (`unknown_recipient` | `no_devices` |
  /// `stale_tokens` | `no_credentials`), пусто у успеха. Строка, а не
  /// enum: контракт внешний, пятая причина не должна ломать разбор
  /// четырёх — как в `ProductNotificationRecipientResult`.
  String? lastReason;

  /// Всего попыток за всё время наблюдения.
  int attemptsTotal;

  /// Из них таких, где доставлять было некому или нечем.
  int undeliveredTotal;

  DateTime updatedAt;

  /// Returns a shallow copy of this [DeliveryRecipientState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliveryRecipientState copyWith({
    int? id,
    int? tenantId,
    int? productId,
    String? externalUserId,
    DateTime? firstAttemptAt,
    DateTime? lastAttemptAt,
    DateTime? lastDeliveredAt,
    String? lastStatus,
    String? lastReason,
    int? attemptsTotal,
    int? undeliveredTotal,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliveryRecipientState',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'externalUserId': externalUserId,
      'firstAttemptAt': firstAttemptAt.toJson(),
      'lastAttemptAt': lastAttemptAt.toJson(),
      if (lastDeliveredAt != null) 'lastDeliveredAt': lastDeliveredAt?.toJson(),
      'lastStatus': lastStatus,
      if (lastReason != null) 'lastReason': lastReason,
      'attemptsTotal': attemptsTotal,
      'undeliveredTotal': undeliveredTotal,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeliveryRecipientStateImpl extends DeliveryRecipientState {
  _DeliveryRecipientStateImpl({
    int? id,
    required int tenantId,
    required int productId,
    required String externalUserId,
    required DateTime firstAttemptAt,
    required DateTime lastAttemptAt,
    DateTime? lastDeliveredAt,
    required String lastStatus,
    String? lastReason,
    int? attemptsTotal,
    int? undeliveredTotal,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         externalUserId: externalUserId,
         firstAttemptAt: firstAttemptAt,
         lastAttemptAt: lastAttemptAt,
         lastDeliveredAt: lastDeliveredAt,
         lastStatus: lastStatus,
         lastReason: lastReason,
         attemptsTotal: attemptsTotal,
         undeliveredTotal: undeliveredTotal,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [DeliveryRecipientState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliveryRecipientState copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? productId,
    String? externalUserId,
    DateTime? firstAttemptAt,
    DateTime? lastAttemptAt,
    Object? lastDeliveredAt = _Undefined,
    String? lastStatus,
    Object? lastReason = _Undefined,
    int? attemptsTotal,
    int? undeliveredTotal,
    DateTime? updatedAt,
  }) {
    return DeliveryRecipientState(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      externalUserId: externalUserId ?? this.externalUserId,
      firstAttemptAt: firstAttemptAt ?? this.firstAttemptAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastDeliveredAt: lastDeliveredAt is DateTime?
          ? lastDeliveredAt
          : this.lastDeliveredAt,
      lastStatus: lastStatus ?? this.lastStatus,
      lastReason: lastReason is String? ? lastReason : this.lastReason,
      attemptsTotal: attemptsTotal ?? this.attemptsTotal,
      undeliveredTotal: undeliveredTotal ?? this.undeliveredTotal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
