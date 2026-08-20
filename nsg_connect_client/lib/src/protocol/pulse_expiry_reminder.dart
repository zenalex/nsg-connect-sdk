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

/// **Напоминания по рубежам срока** (TASK94 MR2, issue #109).
///
/// Общий слой для мониторов ЛЮБОГО рода, а не поля внутри TLS-пробы.
/// Механика «однократное напоминание на рубеже, сброс при смене срока» к
/// сертификатам не привязана: так же напоминают о продлении домена, лицензии
/// или договора. Спрячь мы её в пробу — при следующем применении пришлось бы
/// копировать вместе со всеми граблями. Проба здесь всего лишь ПОСТАВЩИК
/// величины «до какого момента всё в порядке».
///
/// Одна строка на монитор: у монитора один срок. Понадобится несколько —
/// это будет уже другая модель, и лучше завести её тогда, чем угадывать
/// сейчас.
abstract class PulseExpiryReminder implements _i1.SerializableModel {
  PulseExpiryReminder._({
    this.id,
    required this.monitorId,
    String? thresholdDays,
    this.deadlineAt,
    this.lastNotifiedThreshold,
    this.notifiedForDeadlineAt,
    required this.updatedAt,
  }) : thresholdDays = thresholdDays ?? '30,14,7,1';

  factory PulseExpiryReminder({
    int? id,
    required int monitorId,
    String? thresholdDays,
    DateTime? deadlineAt,
    int? lastNotifiedThreshold,
    DateTime? notifiedForDeadlineAt,
    required DateTime updatedAt,
  }) = _PulseExpiryReminderImpl;

  factory PulseExpiryReminder.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseExpiryReminder(
      id: jsonSerialization['id'] as int?,
      monitorId: jsonSerialization['monitorId'] as int,
      thresholdDays: jsonSerialization['thresholdDays'] as String?,
      deadlineAt: jsonSerialization['deadlineAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deadlineAt']),
      lastNotifiedThreshold: jsonSerialization['lastNotifiedThreshold'] as int?,
      notifiedForDeadlineAt: jsonSerialization['notifiedForDeadlineAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['notifiedForDeadlineAt'],
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

  /// Чей срок. Каскад: удалили монитор — ушло и напоминание.
  int monitorId;

  /// Рубежи в днях, CSV по убыванию: ACME `30,14,7,1`, коммерческие
  /// `90,60,30,14,7,1`. Строкой, а не таблицей строк: список короткий,
  /// правится целиком и читается человеком в psql без join-а.
  String thresholdDays;

  /// До какого момента всё в порядке (для пробы — `NotAfter` сертификата).
  /// `null` — срок ещё не наблюдался: напоминать не о чем.
  DateTime? deadlineAt;

  /// Последний ПРОЙДЕННЫЙ рубеж. Именно он делает напоминание однократным
  /// и переживает рестарт процесса: состояние в БД, а не в памяти воркера.
  /// `null` — ни одного рубежа ещё не проходили.
  int? lastNotifiedThreshold;

  /// Срок, на который считался `lastNotifiedThreshold`. Нужен, чтобы
  /// отличить «тот же сертификат, следующий цикл» от «приехал новый». Без
  /// этого поля сброс пришлось бы угадывать по самому `deadlineAt`, а он к
  /// моменту сравнения уже перезаписан.
  DateTime? notifiedForDeadlineAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [PulseExpiryReminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseExpiryReminder copyWith({
    int? id,
    int? monitorId,
    String? thresholdDays,
    DateTime? deadlineAt,
    int? lastNotifiedThreshold,
    DateTime? notifiedForDeadlineAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseExpiryReminder',
      if (id != null) 'id': id,
      'monitorId': monitorId,
      'thresholdDays': thresholdDays,
      if (deadlineAt != null) 'deadlineAt': deadlineAt?.toJson(),
      if (lastNotifiedThreshold != null)
        'lastNotifiedThreshold': lastNotifiedThreshold,
      if (notifiedForDeadlineAt != null)
        'notifiedForDeadlineAt': notifiedForDeadlineAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseExpiryReminderImpl extends PulseExpiryReminder {
  _PulseExpiryReminderImpl({
    int? id,
    required int monitorId,
    String? thresholdDays,
    DateTime? deadlineAt,
    int? lastNotifiedThreshold,
    DateTime? notifiedForDeadlineAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         monitorId: monitorId,
         thresholdDays: thresholdDays,
         deadlineAt: deadlineAt,
         lastNotifiedThreshold: lastNotifiedThreshold,
         notifiedForDeadlineAt: notifiedForDeadlineAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PulseExpiryReminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseExpiryReminder copyWith({
    Object? id = _Undefined,
    int? monitorId,
    String? thresholdDays,
    Object? deadlineAt = _Undefined,
    Object? lastNotifiedThreshold = _Undefined,
    Object? notifiedForDeadlineAt = _Undefined,
    DateTime? updatedAt,
  }) {
    return PulseExpiryReminder(
      id: id is int? ? id : this.id,
      monitorId: monitorId ?? this.monitorId,
      thresholdDays: thresholdDays ?? this.thresholdDays,
      deadlineAt: deadlineAt is DateTime? ? deadlineAt : this.deadlineAt,
      lastNotifiedThreshold: lastNotifiedThreshold is int?
          ? lastNotifiedThreshold
          : this.lastNotifiedThreshold,
      notifiedForDeadlineAt: notifiedForDeadlineAt is DateTime?
          ? notifiedForDeadlineAt
          : this.notifiedForDeadlineAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
