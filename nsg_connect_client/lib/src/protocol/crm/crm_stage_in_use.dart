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

/// TASK95 4.5: kind/archive edit requires explicit transfer of open deals.
abstract class CrmStageInUse
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmStageInUse._({
    required this.stageId,
    required this.openDealCount,
  });

  factory CrmStageInUse({
    required int stageId,
    required int openDealCount,
  }) = _CrmStageInUseImpl;

  factory CrmStageInUse.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmStageInUse(
      stageId: jsonSerialization['stageId'] as int,
      openDealCount: jsonSerialization['openDealCount'] as int,
    );
  }

  int stageId;

  int openDealCount;

  /// Returns a shallow copy of this [CrmStageInUse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmStageInUse copyWith({
    int? stageId,
    int? openDealCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmStageInUse',
      'stageId': stageId,
      'openDealCount': openDealCount,
    };
  }

  @override
  String toString() {
    return 'CrmStageInUse(stageId: $stageId, openDealCount: $openDealCount)';
  }
}

class _CrmStageInUseImpl extends CrmStageInUse {
  _CrmStageInUseImpl({
    required int stageId,
    required int openDealCount,
  }) : super._(
         stageId: stageId,
         openDealCount: openDealCount,
       );

  /// Returns a shallow copy of this [CrmStageInUse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmStageInUse copyWith({
    int? stageId,
    int? openDealCount,
  }) {
    return CrmStageInUse(
      stageId: stageId ?? this.stageId,
      openDealCount: openDealCount ?? this.openDealCount,
    );
  }
}
