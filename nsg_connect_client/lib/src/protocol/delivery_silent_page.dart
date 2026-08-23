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
import 'delivery_silent_recipient.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **issue #160**: ответ ручки «кто не получает» за период.
abstract class DeliverySilentPage implements _i1.SerializableModel {
  DeliverySilentPage._({
    required this.recipients,
    required this.totalSilent,
    required this.totalAddressed,
    required this.coverageFrom,
    required this.beyondRetention,
    required this.retentionDays,
  });

  factory DeliverySilentPage({
    required List<_i2.DeliverySilentRecipient> recipients,
    required int totalSilent,
    required int totalAddressed,
    required DateTime coverageFrom,
    required bool beyondRetention,
    required int retentionDays,
  }) = _DeliverySilentPageImpl;

  factory DeliverySilentPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeliverySilentPage(
      recipients: _i3.Protocol().deserialize<List<_i2.DeliverySilentRecipient>>(
        jsonSerialization['recipients'],
      ),
      totalSilent: jsonSerialization['totalSilent'] as int,
      totalAddressed: jsonSerialization['totalAddressed'] as int,
      coverageFrom: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['coverageFrom'],
      ),
      beyondRetention: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['beyondRetention'],
      ),
      retentionDays: jsonSerialization['retentionDays'] as int,
    );
  }

  /// Адресаты, которым в этот период что-то слали, но за него ничего не
  /// доставили. Порядок — от самых безнадёжных: сперва те, кому не
  /// доходило ни разу.
  List<_i2.DeliverySilentRecipient> recipients;

  /// Сколько всего таких адресатов у продукта за период — до отсечки
  /// `limit`. Отвечает на «это два дежурных или полторы тысячи людей».
  int totalSilent;

  /// Сколько адресатов продукт трогал за период всего. Вместе с
  /// `totalSilent` даёт долю пустоты, ради которой ручка и заведена.
  int totalAddressed;

  /// Граница, за которой мы не помним (см. `DeliveryJournalPage`).
  DateTime coverageFrom;

  bool beyondRetention;

  int retentionDays;

  /// Returns a shallow copy of this [DeliverySilentPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliverySilentPage copyWith({
    List<_i2.DeliverySilentRecipient>? recipients,
    int? totalSilent,
    int? totalAddressed,
    DateTime? coverageFrom,
    bool? beyondRetention,
    int? retentionDays,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliverySilentPage',
      'recipients': recipients.toJson(valueToJson: (v) => v.toJson()),
      'totalSilent': totalSilent,
      'totalAddressed': totalAddressed,
      'coverageFrom': coverageFrom.toJson(),
      'beyondRetention': beyondRetention,
      'retentionDays': retentionDays,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeliverySilentPageImpl extends DeliverySilentPage {
  _DeliverySilentPageImpl({
    required List<_i2.DeliverySilentRecipient> recipients,
    required int totalSilent,
    required int totalAddressed,
    required DateTime coverageFrom,
    required bool beyondRetention,
    required int retentionDays,
  }) : super._(
         recipients: recipients,
         totalSilent: totalSilent,
         totalAddressed: totalAddressed,
         coverageFrom: coverageFrom,
         beyondRetention: beyondRetention,
         retentionDays: retentionDays,
       );

  /// Returns a shallow copy of this [DeliverySilentPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliverySilentPage copyWith({
    List<_i2.DeliverySilentRecipient>? recipients,
    int? totalSilent,
    int? totalAddressed,
    DateTime? coverageFrom,
    bool? beyondRetention,
    int? retentionDays,
  }) {
    return DeliverySilentPage(
      recipients:
          recipients ?? this.recipients.map((e0) => e0.copyWith()).toList(),
      totalSilent: totalSilent ?? this.totalSilent,
      totalAddressed: totalAddressed ?? this.totalAddressed,
      coverageFrom: coverageFrom ?? this.coverageFrom,
      beyondRetention: beyondRetention ?? this.beyondRetention,
      retentionDays: retentionDays ?? this.retentionDays,
    );
  }
}
