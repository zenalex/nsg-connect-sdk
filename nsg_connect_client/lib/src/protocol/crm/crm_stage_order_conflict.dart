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

abstract class CrmStageOrderConflict
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmStageOrderConflict._({
    required this.pipelineId,
    required this.sortOrder,
  });

  factory CrmStageOrderConflict({
    required int pipelineId,
    required int sortOrder,
  }) = _CrmStageOrderConflictImpl;

  factory CrmStageOrderConflict.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CrmStageOrderConflict(
      pipelineId: jsonSerialization['pipelineId'] as int,
      sortOrder: jsonSerialization['sortOrder'] as int,
    );
  }

  int pipelineId;

  int sortOrder;

  /// Returns a shallow copy of this [CrmStageOrderConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmStageOrderConflict copyWith({
    int? pipelineId,
    int? sortOrder,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmStageOrderConflict',
      'pipelineId': pipelineId,
      'sortOrder': sortOrder,
    };
  }

  @override
  String toString() {
    return 'CrmStageOrderConflict(pipelineId: $pipelineId, sortOrder: $sortOrder)';
  }
}

class _CrmStageOrderConflictImpl extends CrmStageOrderConflict {
  _CrmStageOrderConflictImpl({
    required int pipelineId,
    required int sortOrder,
  }) : super._(
         pipelineId: pipelineId,
         sortOrder: sortOrder,
       );

  /// Returns a shallow copy of this [CrmStageOrderConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmStageOrderConflict copyWith({
    int? pipelineId,
    int? sortOrder,
  }) {
    return CrmStageOrderConflict(
      pipelineId: pipelineId ?? this.pipelineId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
