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
import '../crm/crm_change_view.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// TASK95 CRM errors. Access denied is identical for absent and forbidden objects.
abstract class CrmConfirmationRequired
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmConfirmationRequired._({
    required this.proposalId,
    required this.diff,
  });

  factory CrmConfirmationRequired({
    required int proposalId,
    required List<_i2.CrmChangeView> diff,
  }) = _CrmConfirmationRequiredImpl;

  factory CrmConfirmationRequired.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CrmConfirmationRequired(
      proposalId: jsonSerialization['proposalId'] as int,
      diff: _i3.Protocol().deserialize<List<_i2.CrmChangeView>>(
        jsonSerialization['diff'],
      ),
    );
  }

  int proposalId;

  List<_i2.CrmChangeView> diff;

  /// Returns a shallow copy of this [CrmConfirmationRequired]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmConfirmationRequired copyWith({
    int? proposalId,
    List<_i2.CrmChangeView>? diff,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmConfirmationRequired',
      'proposalId': proposalId,
      'diff': diff.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return 'CrmConfirmationRequired(proposalId: $proposalId, diff: $diff)';
  }
}

class _CrmConfirmationRequiredImpl extends CrmConfirmationRequired {
  _CrmConfirmationRequiredImpl({
    required int proposalId,
    required List<_i2.CrmChangeView> diff,
  }) : super._(
         proposalId: proposalId,
         diff: diff,
       );

  /// Returns a shallow copy of this [CrmConfirmationRequired]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmConfirmationRequired copyWith({
    int? proposalId,
    List<_i2.CrmChangeView>? diff,
  }) {
    return CrmConfirmationRequired(
      proposalId: proposalId ?? this.proposalId,
      diff: diff ?? this.diff.map((e0) => e0.copyWith()).toList(),
    );
  }
}
