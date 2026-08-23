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

/// **issue #160**: ответ ручки «состояние адресатов» — по одному на
/// запрошенный `externalUserId`.
///
/// Отвечает на единственный вопрос продукта перед рассылкой: **дойдёт ли
/// до этого человека вообще**. Если нет — рассылку по нему можно не
/// начинать, и это дешевле для всех.
///
/// **Ответ есть всегда, на каждый запрошенный id.** Неизвестный адресат
/// возвращается со `known: false`, а не пропускается: молчание продукт
/// прочитал бы как «всё в порядке», и петля Титана прожила бы ещё
/// полтора месяца.
abstract class DeliveryRecipientStatus implements _i1.SerializableModel {
  DeliveryRecipientStatus._({
    required this.externalUserId,
    required this.known,
    required this.devicesTotal,
    required this.devicesLive,
    required this.deliverable,
    this.lastDeliveredAt,
    this.lastAttemptAt,
    this.lastStatus,
    this.lastReason,
    required this.attemptsTotal,
    required this.undeliveredTotal,
  });

  factory DeliveryRecipientStatus({
    required String externalUserId,
    required bool known,
    required int devicesTotal,
    required int devicesLive,
    required bool deliverable,
    DateTime? lastDeliveredAt,
    DateTime? lastAttemptAt,
    String? lastStatus,
    String? lastReason,
    required int attemptsTotal,
    required int undeliveredTotal,
  }) = _DeliveryRecipientStatusImpl;

  factory DeliveryRecipientStatus.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeliveryRecipientStatus(
      externalUserId: jsonSerialization['externalUserId'] as String,
      known: _i1.BoolJsonExtension.fromJson(jsonSerialization['known']),
      devicesTotal: jsonSerialization['devicesTotal'] as int,
      devicesLive: jsonSerialization['devicesLive'] as int,
      deliverable: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['deliverable'],
      ),
      lastDeliveredAt: jsonSerialization['lastDeliveredAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastDeliveredAt'],
            ),
      lastAttemptAt: jsonSerialization['lastAttemptAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastAttemptAt'],
            ),
      lastStatus: jsonSerialization['lastStatus'] as String?,
      lastReason: jsonSerialization['lastReason'] as String?,
      attemptsTotal: jsonSerialization['attemptsTotal'] as int,
      undeliveredTotal: jsonSerialization['undeliveredTotal'] as int,
    );
  }

  String externalUserId;

  /// Есть ли у нас привязка этого id к пользователю мессенджера. `false`
  /// означает ровно одно: продукт шлёт на идентификатор, которого мы не
  /// знаем. Чинится сверкой id, а не работой с человеком.
  ///
  /// **Чужой id выглядит так же, как несуществующий** — намеренно: иначе
  /// перебором можно было бы выяснить состав чужой базы.
  bool known;

  /// Устройств, зарегистрированных за адресатом (в рамках этого продукта
  /// плюс standalone-установки).
  int devicesTotal;

  /// Из них живых — тех, чья регистрация продлевалась достаточно недавно
  /// (`DeviceRegistrationService.isRegistrationStale`). Ноль при
  /// `devicesTotal > 0` — установка, скорее всего, мертва.
  int devicesLive;

  /// Способна ли платформа доставить прямо сейчас: есть живое устройство
  /// И настроены креды его службы. Итог всех проверок одной строкой —
  /// именно это поле продукт спрашивает перед рассылкой.
  bool deliverable;

  /// Когда до адресата в последний раз ХОТЬ ЧТО-ТО ушло. NULL при
  /// ненулевых попытках — та самая пустота.
  DateTime? lastDeliveredAt;

  /// Последняя попытка и её исход.
  DateTime? lastAttemptAt;

  String? lastStatus;

  /// Причина последнего отказа — те же значения, что в ответе на отправку.
  String? lastReason;

  /// Пожизненные счётчики: за всё время наблюдения, не за период.
  /// Разбивка по часам — в учёте (#158), здесь её нет намеренно.
  int attemptsTotal;

  int undeliveredTotal;

  /// Returns a shallow copy of this [DeliveryRecipientStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliveryRecipientStatus copyWith({
    String? externalUserId,
    bool? known,
    int? devicesTotal,
    int? devicesLive,
    bool? deliverable,
    DateTime? lastDeliveredAt,
    DateTime? lastAttemptAt,
    String? lastStatus,
    String? lastReason,
    int? attemptsTotal,
    int? undeliveredTotal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliveryRecipientStatus',
      'externalUserId': externalUserId,
      'known': known,
      'devicesTotal': devicesTotal,
      'devicesLive': devicesLive,
      'deliverable': deliverable,
      if (lastDeliveredAt != null) 'lastDeliveredAt': lastDeliveredAt?.toJson(),
      if (lastAttemptAt != null) 'lastAttemptAt': lastAttemptAt?.toJson(),
      if (lastStatus != null) 'lastStatus': lastStatus,
      if (lastReason != null) 'lastReason': lastReason,
      'attemptsTotal': attemptsTotal,
      'undeliveredTotal': undeliveredTotal,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeliveryRecipientStatusImpl extends DeliveryRecipientStatus {
  _DeliveryRecipientStatusImpl({
    required String externalUserId,
    required bool known,
    required int devicesTotal,
    required int devicesLive,
    required bool deliverable,
    DateTime? lastDeliveredAt,
    DateTime? lastAttemptAt,
    String? lastStatus,
    String? lastReason,
    required int attemptsTotal,
    required int undeliveredTotal,
  }) : super._(
         externalUserId: externalUserId,
         known: known,
         devicesTotal: devicesTotal,
         devicesLive: devicesLive,
         deliverable: deliverable,
         lastDeliveredAt: lastDeliveredAt,
         lastAttemptAt: lastAttemptAt,
         lastStatus: lastStatus,
         lastReason: lastReason,
         attemptsTotal: attemptsTotal,
         undeliveredTotal: undeliveredTotal,
       );

  /// Returns a shallow copy of this [DeliveryRecipientStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliveryRecipientStatus copyWith({
    String? externalUserId,
    bool? known,
    int? devicesTotal,
    int? devicesLive,
    bool? deliverable,
    Object? lastDeliveredAt = _Undefined,
    Object? lastAttemptAt = _Undefined,
    Object? lastStatus = _Undefined,
    Object? lastReason = _Undefined,
    int? attemptsTotal,
    int? undeliveredTotal,
  }) {
    return DeliveryRecipientStatus(
      externalUserId: externalUserId ?? this.externalUserId,
      known: known ?? this.known,
      devicesTotal: devicesTotal ?? this.devicesTotal,
      devicesLive: devicesLive ?? this.devicesLive,
      deliverable: deliverable ?? this.deliverable,
      lastDeliveredAt: lastDeliveredAt is DateTime?
          ? lastDeliveredAt
          : this.lastDeliveredAt,
      lastAttemptAt: lastAttemptAt is DateTime?
          ? lastAttemptAt
          : this.lastAttemptAt,
      lastStatus: lastStatus is String? ? lastStatus : this.lastStatus,
      lastReason: lastReason is String? ? lastReason : this.lastReason,
      attemptsTotal: attemptsTotal ?? this.attemptsTotal,
      undeliveredTotal: undeliveredTotal ?? this.undeliveredTotal,
    );
  }
}
