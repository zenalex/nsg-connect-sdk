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
import 'delivery_journal_entry.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **issue #160**: страница журнала доставки.
///
/// **Почему не просто список.** Журнал живёт год (#155, #160), и вопрос
/// про март позапрошлого года мы обязаны отличать от вопроса, на который
/// ответ «ничего не слали». Пустой список без оговорки читается как
/// второе, хотя означает первое, — и продукт сделает неверный вывод
/// именно в тот момент, когда разбирает инцидент.
abstract class DeliveryJournalPage implements _i1.SerializableModel {
  DeliveryJournalPage._({
    required this.entries,
    required this.coverageFrom,
    required this.beyondRetention,
    required this.retentionDays,
    required this.hasMore,
    this.nextOffset,
  });

  factory DeliveryJournalPage({
    required List<_i2.DeliveryJournalEntry> entries,
    required DateTime coverageFrom,
    required bool beyondRetention,
    required int retentionDays,
    required bool hasMore,
    int? nextOffset,
  }) = _DeliveryJournalPageImpl;

  factory DeliveryJournalPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeliveryJournalPage(
      entries: _i3.Protocol().deserialize<List<_i2.DeliveryJournalEntry>>(
        jsonSerialization['entries'],
      ),
      coverageFrom: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['coverageFrom'],
      ),
      beyondRetention: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['beyondRetention'],
      ),
      retentionDays: jsonSerialization['retentionDays'] as int,
      hasMore: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasMore']),
      nextOffset: jsonSerialization['nextOffset'] as int?,
    );
  }

  List<_i2.DeliveryJournalEntry> entries;

  /// С какого момента журнал вообще способен отвечать: позднее из
  /// запрошенного начала и границы хранения. Всё, что раньше, — не
  /// «не было», а «не знаем».
  DateTime coverageFrom;

  /// Запрошенный период уходит за границу хранения. Если `true`, пустой
  /// ответ НЕ означает «ничего не отправлялось».
  bool beyondRetention;

  /// Сколько суток журнал хранится — чтобы клиент мог объяснить это
  /// человеку, не заглядывая в документацию.
  int retentionDays;

  /// Есть ли ещё записи за этим окном (запросить со сдвигом `nextOffset`).
  bool hasMore;

  int? nextOffset;

  /// Returns a shallow copy of this [DeliveryJournalPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliveryJournalPage copyWith({
    List<_i2.DeliveryJournalEntry>? entries,
    DateTime? coverageFrom,
    bool? beyondRetention,
    int? retentionDays,
    bool? hasMore,
    int? nextOffset,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliveryJournalPage',
      'entries': entries.toJson(valueToJson: (v) => v.toJson()),
      'coverageFrom': coverageFrom.toJson(),
      'beyondRetention': beyondRetention,
      'retentionDays': retentionDays,
      'hasMore': hasMore,
      if (nextOffset != null) 'nextOffset': nextOffset,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeliveryJournalPageImpl extends DeliveryJournalPage {
  _DeliveryJournalPageImpl({
    required List<_i2.DeliveryJournalEntry> entries,
    required DateTime coverageFrom,
    required bool beyondRetention,
    required int retentionDays,
    required bool hasMore,
    int? nextOffset,
  }) : super._(
         entries: entries,
         coverageFrom: coverageFrom,
         beyondRetention: beyondRetention,
         retentionDays: retentionDays,
         hasMore: hasMore,
         nextOffset: nextOffset,
       );

  /// Returns a shallow copy of this [DeliveryJournalPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliveryJournalPage copyWith({
    List<_i2.DeliveryJournalEntry>? entries,
    DateTime? coverageFrom,
    bool? beyondRetention,
    int? retentionDays,
    bool? hasMore,
    Object? nextOffset = _Undefined,
  }) {
    return DeliveryJournalPage(
      entries: entries ?? this.entries.map((e0) => e0.copyWith()).toList(),
      coverageFrom: coverageFrom ?? this.coverageFrom,
      beyondRetention: beyondRetention ?? this.beyondRetention,
      retentionDays: retentionDays ?? this.retentionDays,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset is int? ? nextOffset : this.nextOffset,
    );
  }
}
