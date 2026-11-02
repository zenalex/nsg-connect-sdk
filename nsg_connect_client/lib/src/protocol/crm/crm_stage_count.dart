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

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmStageCount implements _i1.SerializableModel {
  CrmStageCount._({
    required this.stageId,
    required this.count,
  });

  factory CrmStageCount({
    required int stageId,
    required int count,
  }) = _CrmStageCountImpl;

  factory CrmStageCount.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmStageCount(
      stageId: jsonSerialization['stageId'] as int,
      count: jsonSerialization['count'] as int,
    );
  }

  int stageId;

  int count;

  /// Returns a shallow copy of this [CrmStageCount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmStageCount copyWith({
    int? stageId,
    int? count,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmStageCount',
      'stageId': stageId,
      'count': count,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CrmStageCountImpl extends CrmStageCount {
  _CrmStageCountImpl({
    required int stageId,
    required int count,
  }) : super._(
         stageId: stageId,
         count: count,
       );

  /// Returns a shallow copy of this [CrmStageCount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmStageCount copyWith({
    int? stageId,
    int? count,
  }) {
    return CrmStageCount(
      stageId: stageId ?? this.stageId,
      count: count ?? this.count,
    );
  }
}
