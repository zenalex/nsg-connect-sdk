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
import '../crm/crm_stage_count.dart' as _i2;
import '../crm/crm_deal_view.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmDigest implements _i1.SerializableModel {
  CrmDigest._({
    required this.from,
    required this.to,
    required this.stageCounts,
    required this.stageTransitionCount,
    required this.newActivityCount,
    required this.overdue,
    required this.stale,
    required this.pending,
  });

  factory CrmDigest({
    required DateTime from,
    required DateTime to,
    required List<_i2.CrmStageCount> stageCounts,
    required int stageTransitionCount,
    required int newActivityCount,
    required List<_i3.CrmDealView> overdue,
    required List<_i3.CrmDealView> stale,
    required List<_i3.CrmDealView> pending,
  }) = _CrmDigestImpl;

  factory CrmDigest.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmDigest(
      from: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['from']),
      to: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['to']),
      stageCounts: _i4.Protocol().deserialize<List<_i2.CrmStageCount>>(
        jsonSerialization['stageCounts'],
      ),
      stageTransitionCount: jsonSerialization['stageTransitionCount'] as int,
      newActivityCount: jsonSerialization['newActivityCount'] as int,
      overdue: _i4.Protocol().deserialize<List<_i3.CrmDealView>>(
        jsonSerialization['overdue'],
      ),
      stale: _i4.Protocol().deserialize<List<_i3.CrmDealView>>(
        jsonSerialization['stale'],
      ),
      pending: _i4.Protocol().deserialize<List<_i3.CrmDealView>>(
        jsonSerialization['pending'],
      ),
    );
  }

  DateTime from;

  DateTime to;

  List<_i2.CrmStageCount> stageCounts;

  int stageTransitionCount;

  int newActivityCount;

  List<_i3.CrmDealView> overdue;

  List<_i3.CrmDealView> stale;

  List<_i3.CrmDealView> pending;

  /// Returns a shallow copy of this [CrmDigest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmDigest copyWith({
    DateTime? from,
    DateTime? to,
    List<_i2.CrmStageCount>? stageCounts,
    int? stageTransitionCount,
    int? newActivityCount,
    List<_i3.CrmDealView>? overdue,
    List<_i3.CrmDealView>? stale,
    List<_i3.CrmDealView>? pending,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmDigest',
      'from': from.toJson(),
      'to': to.toJson(),
      'stageCounts': stageCounts.toJson(valueToJson: (v) => v.toJson()),
      'stageTransitionCount': stageTransitionCount,
      'newActivityCount': newActivityCount,
      'overdue': overdue.toJson(valueToJson: (v) => v.toJson()),
      'stale': stale.toJson(valueToJson: (v) => v.toJson()),
      'pending': pending.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CrmDigestImpl extends CrmDigest {
  _CrmDigestImpl({
    required DateTime from,
    required DateTime to,
    required List<_i2.CrmStageCount> stageCounts,
    required int stageTransitionCount,
    required int newActivityCount,
    required List<_i3.CrmDealView> overdue,
    required List<_i3.CrmDealView> stale,
    required List<_i3.CrmDealView> pending,
  }) : super._(
         from: from,
         to: to,
         stageCounts: stageCounts,
         stageTransitionCount: stageTransitionCount,
         newActivityCount: newActivityCount,
         overdue: overdue,
         stale: stale,
         pending: pending,
       );

  /// Returns a shallow copy of this [CrmDigest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmDigest copyWith({
    DateTime? from,
    DateTime? to,
    List<_i2.CrmStageCount>? stageCounts,
    int? stageTransitionCount,
    int? newActivityCount,
    List<_i3.CrmDealView>? overdue,
    List<_i3.CrmDealView>? stale,
    List<_i3.CrmDealView>? pending,
  }) {
    return CrmDigest(
      from: from ?? this.from,
      to: to ?? this.to,
      stageCounts:
          stageCounts ?? this.stageCounts.map((e0) => e0.copyWith()).toList(),
      stageTransitionCount: stageTransitionCount ?? this.stageTransitionCount,
      newActivityCount: newActivityCount ?? this.newActivityCount,
      overdue: overdue ?? this.overdue.map((e0) => e0.copyWith()).toList(),
      stale: stale ?? this.stale.map((e0) => e0.copyWith()).toList(),
      pending: pending ?? this.pending.map((e0) => e0.copyWith()).toList(),
    );
  }
}
