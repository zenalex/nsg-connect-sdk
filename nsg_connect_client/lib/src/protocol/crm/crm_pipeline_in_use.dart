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

abstract class CrmPipelineInUse
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmPipelineInUse._({
    required this.pipelineId,
    required this.openDealCount,
  });

  factory CrmPipelineInUse({
    required int pipelineId,
    required int openDealCount,
  }) = _CrmPipelineInUseImpl;

  factory CrmPipelineInUse.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmPipelineInUse(
      pipelineId: jsonSerialization['pipelineId'] as int,
      openDealCount: jsonSerialization['openDealCount'] as int,
    );
  }

  int pipelineId;

  int openDealCount;

  /// Returns a shallow copy of this [CrmPipelineInUse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmPipelineInUse copyWith({
    int? pipelineId,
    int? openDealCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmPipelineInUse',
      'pipelineId': pipelineId,
      'openDealCount': openDealCount,
    };
  }

  @override
  String toString() {
    return 'CrmPipelineInUse(pipelineId: $pipelineId, openDealCount: $openDealCount)';
  }
}

class _CrmPipelineInUseImpl extends CrmPipelineInUse {
  _CrmPipelineInUseImpl({
    required int pipelineId,
    required int openDealCount,
  }) : super._(
         pipelineId: pipelineId,
         openDealCount: openDealCount,
       );

  /// Returns a shallow copy of this [CrmPipelineInUse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmPipelineInUse copyWith({
    int? pipelineId,
    int? openDealCount,
  }) {
    return CrmPipelineInUse(
      pipelineId: pipelineId ?? this.pipelineId,
      openDealCount: openDealCount ?? this.openDealCount,
    );
  }
}
