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

/// TASK95 4.5: final active pipeline needs >=1 open and >=1 lost stage.
abstract class CrmPipelineInvalid
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmPipelineInvalid._({
    this.pipelineId,
    required this.openStageCount,
    required this.lostStageCount,
  });

  factory CrmPipelineInvalid({
    int? pipelineId,
    required int openStageCount,
    required int lostStageCount,
  }) = _CrmPipelineInvalidImpl;

  factory CrmPipelineInvalid.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmPipelineInvalid(
      pipelineId: jsonSerialization['pipelineId'] as int?,
      openStageCount: jsonSerialization['openStageCount'] as int,
      lostStageCount: jsonSerialization['lostStageCount'] as int,
    );
  }

  int? pipelineId;

  int openStageCount;

  int lostStageCount;

  /// Returns a shallow copy of this [CrmPipelineInvalid]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmPipelineInvalid copyWith({
    int? pipelineId,
    int? openStageCount,
    int? lostStageCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmPipelineInvalid',
      if (pipelineId != null) 'pipelineId': pipelineId,
      'openStageCount': openStageCount,
      'lostStageCount': lostStageCount,
    };
  }

  @override
  String toString() {
    return 'CrmPipelineInvalid(pipelineId: $pipelineId, openStageCount: $openStageCount, lostStageCount: $lostStageCount)';
  }
}

class _Undefined {}

class _CrmPipelineInvalidImpl extends CrmPipelineInvalid {
  _CrmPipelineInvalidImpl({
    int? pipelineId,
    required int openStageCount,
    required int lostStageCount,
  }) : super._(
         pipelineId: pipelineId,
         openStageCount: openStageCount,
         lostStageCount: lostStageCount,
       );

  /// Returns a shallow copy of this [CrmPipelineInvalid]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmPipelineInvalid copyWith({
    Object? pipelineId = _Undefined,
    int? openStageCount,
    int? lostStageCount,
  }) {
    return CrmPipelineInvalid(
      pipelineId: pipelineId is int? ? pipelineId : this.pipelineId,
      openStageCount: openStageCount ?? this.openStageCount,
      lostStageCount: lostStageCount ?? this.lostStageCount,
    );
  }
}
