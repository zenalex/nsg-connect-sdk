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

/// **issue #158**: счётчики доставки по тенанту — основа тарифов, квот и
/// антиспама.
///
/// **Почему счётчик, а не запрос к журналу.** Журнал доставок живёт год
/// (#155) и предназначен для разбора инцидентов: его чистят, из него
/// удаляют, он про «что случилось с этим уведомлением». Счёт за март
/// должен сходиться в апреле и через три года — значит он не может
/// зависеть от таблицы, которую мы вправе почистить. Агрегат пишется в
/// момент решения и больше не пересчитывается никогда.
///
/// **Три единицы, потому что три разных вопроса** (см.
/// `DESIGN_CONNECT_DELIVERY_ACCOUNTING` §2.5):
///
///   * `request` — вызовов API. Нагрузка на приём и частота: по ней режут
///     спам;
///   * `recipient` — уведомлений на человека. Основа тарифа: у человека
///     может быть три устройства, и брать втрое было бы нечестно;
///   * `delivery` — отправок на устройство. Наша себестоимость: столько
///     обращений к FCM/APNs/RuStore мы реально делаем.
///
/// **Час, а не сутки.** Квоты режут по часу, графики строят по часу, а
/// сутки и месяц получаются свёрткой. Обратно из суток час не достать.
abstract class DeliveryUsage implements _i1.SerializableModel {
  DeliveryUsage._({
    this.id,
    required this.tenantId,
    required this.productId,
    required this.hour,
    required this.unit,
    required this.outcome,
    required this.service,
    int? total,
    required this.updatedAt,
  }) : total = total ?? 0;

  factory DeliveryUsage({
    int? id,
    required int tenantId,
    required int productId,
    required DateTime hour,
    required String unit,
    required String outcome,
    required String service,
    int? total,
    required DateTime updatedAt,
  }) = _DeliveryUsageImpl;

  factory DeliveryUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeliveryUsage(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int,
      hour: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['hour']),
      unit: jsonSerialization['unit'] as String,
      outcome: jsonSerialization['outcome'] as String,
      service: jsonSerialization['service'] as String,
      total: jsonSerialization['total'] as int?,
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

  /// NULL быть не может: учёт всегда привязан к продукту, иначе счёт не
  /// разложить по договорам.
  int productId;

  /// Начало часа (UTC). Ключ агрегации.
  DateTime hour;

  /// `request` | `recipient` | `delivery` — см. заголовок.
  String unit;

  /// Исход в терминах этой единицы: для `request` — принят или отвергнут,
  /// для `recipient` — статус уведомления, для `delivery` — постановка в
  /// очередь на устройство.
  String outcome;

  /// Служба доставки (`fcm`, `apns`, `rustore`, `webpush`) — только для
  /// единицы `delivery`.
  ///
  /// Пустая строка, а не NULL, намеренно: в Postgres NULL-ы в уникальном
  /// индексе считаются различными, и `ON CONFLICT` перестал бы схлопывать
  /// строки — счётчик размножился бы на каждый вызов.
  String service;

  /// Само число. Не `count`: это имя Serverpod держит за собой.
  int total;

  DateTime updatedAt;

  /// Returns a shallow copy of this [DeliveryUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliveryUsage copyWith({
    int? id,
    int? tenantId,
    int? productId,
    DateTime? hour,
    String? unit,
    String? outcome,
    String? service,
    int? total,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliveryUsage',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'hour': hour.toJson(),
      'unit': unit,
      'outcome': outcome,
      'service': service,
      'total': total,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeliveryUsageImpl extends DeliveryUsage {
  _DeliveryUsageImpl({
    int? id,
    required int tenantId,
    required int productId,
    required DateTime hour,
    required String unit,
    required String outcome,
    required String service,
    int? total,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         hour: hour,
         unit: unit,
         outcome: outcome,
         service: service,
         total: total,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [DeliveryUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliveryUsage copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? productId,
    DateTime? hour,
    String? unit,
    String? outcome,
    String? service,
    int? total,
    DateTime? updatedAt,
  }) {
    return DeliveryUsage(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      hour: hour ?? this.hour,
      unit: unit ?? this.unit,
      outcome: outcome ?? this.outcome,
      service: service ?? this.service,
      total: total ?? this.total,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
