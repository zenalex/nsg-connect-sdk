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

/// **issue #160**: адресат, до которого не доходит, — строка ответа
/// ручки «кто не получает».
///
/// Ручка, ради которой написан весь документ: она отвечает на «кому мы
/// шлём в пустоту». Титан увидел бы своих двух дежурных за одну секунду.
abstract class DeliverySilentRecipient implements _i1.SerializableModel {
  DeliverySilentRecipient._({
    required this.externalUserId,
    required this.known,
    this.lastReason,
    required this.firstAttemptAt,
    required this.lastAttemptAt,
    this.lastDeliveredAt,
    required this.attemptsTotal,
    required this.undeliveredTotal,
  });

  factory DeliverySilentRecipient({
    required String externalUserId,
    required bool known,
    String? lastReason,
    required DateTime firstAttemptAt,
    required DateTime lastAttemptAt,
    DateTime? lastDeliveredAt,
    required int attemptsTotal,
    required int undeliveredTotal,
  }) = _DeliverySilentRecipientImpl;

  factory DeliverySilentRecipient.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeliverySilentRecipient(
      externalUserId: jsonSerialization['externalUserId'] as String,
      known: _i1.BoolJsonExtension.fromJson(jsonSerialization['known']),
      lastReason: jsonSerialization['lastReason'] as String?,
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
      attemptsTotal: jsonSerialization['attemptsTotal'] as int,
      undeliveredTotal: jsonSerialization['undeliveredTotal'] as int,
    );
  }

  String externalUserId;

  /// Известен ли адресат вообще. Разделяет две беды, которые лечатся
  /// по-разному: `false` — ошибка интеграции (шлём на чужой id),
  /// `true` — беда продуктовая (человек не обновил приложение).
  bool known;

  /// Причина последнего отказа.
  String? lastReason;

  /// Первая и последняя попытка — «давно ли это тянется».
  DateTime firstAttemptAt;

  DateTime lastAttemptAt;

  /// Когда до него доходило в последний раз; NULL — не доходило никогда.
  DateTime? lastDeliveredAt;

  /// Пожизненные счётчики, не за период (см. `periodCounters` в ответе).
  int attemptsTotal;

  int undeliveredTotal;

  /// Returns a shallow copy of this [DeliverySilentRecipient]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliverySilentRecipient copyWith({
    String? externalUserId,
    bool? known,
    String? lastReason,
    DateTime? firstAttemptAt,
    DateTime? lastAttemptAt,
    DateTime? lastDeliveredAt,
    int? attemptsTotal,
    int? undeliveredTotal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliverySilentRecipient',
      'externalUserId': externalUserId,
      'known': known,
      if (lastReason != null) 'lastReason': lastReason,
      'firstAttemptAt': firstAttemptAt.toJson(),
      'lastAttemptAt': lastAttemptAt.toJson(),
      if (lastDeliveredAt != null) 'lastDeliveredAt': lastDeliveredAt?.toJson(),
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

class _DeliverySilentRecipientImpl extends DeliverySilentRecipient {
  _DeliverySilentRecipientImpl({
    required String externalUserId,
    required bool known,
    String? lastReason,
    required DateTime firstAttemptAt,
    required DateTime lastAttemptAt,
    DateTime? lastDeliveredAt,
    required int attemptsTotal,
    required int undeliveredTotal,
  }) : super._(
         externalUserId: externalUserId,
         known: known,
         lastReason: lastReason,
         firstAttemptAt: firstAttemptAt,
         lastAttemptAt: lastAttemptAt,
         lastDeliveredAt: lastDeliveredAt,
         attemptsTotal: attemptsTotal,
         undeliveredTotal: undeliveredTotal,
       );

  /// Returns a shallow copy of this [DeliverySilentRecipient]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliverySilentRecipient copyWith({
    String? externalUserId,
    bool? known,
    Object? lastReason = _Undefined,
    DateTime? firstAttemptAt,
    DateTime? lastAttemptAt,
    Object? lastDeliveredAt = _Undefined,
    int? attemptsTotal,
    int? undeliveredTotal,
  }) {
    return DeliverySilentRecipient(
      externalUserId: externalUserId ?? this.externalUserId,
      known: known ?? this.known,
      lastReason: lastReason is String? ? lastReason : this.lastReason,
      firstAttemptAt: firstAttemptAt ?? this.firstAttemptAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastDeliveredAt: lastDeliveredAt is DateTime?
          ? lastDeliveredAt
          : this.lastDeliveredAt,
      attemptsTotal: attemptsTotal ?? this.attemptsTotal,
      undeliveredTotal: undeliveredTotal ?? this.undeliveredTotal,
    );
  }
}
