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

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmProposal implements _i1.SerializableModel {
  CrmProposal._({
    required this.proposalId,
    required this.onBehalfOfUserId,
    required this.proposalHash,
    required this.expiresAt,
    required this.diff,
    this.cardRoomId,
    this.cardEventId,
  });

  factory CrmProposal({
    required int proposalId,
    required int onBehalfOfUserId,
    required String proposalHash,
    required DateTime expiresAt,
    required List<_i2.CrmChangeView> diff,
    int? cardRoomId,
    String? cardEventId,
  }) = _CrmProposalImpl;

  factory CrmProposal.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmProposal(
      proposalId: jsonSerialization['proposalId'] as int,
      onBehalfOfUserId: jsonSerialization['onBehalfOfUserId'] as int,
      proposalHash: jsonSerialization['proposalHash'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      diff: _i3.Protocol().deserialize<List<_i2.CrmChangeView>>(
        jsonSerialization['diff'],
      ),
      cardRoomId: jsonSerialization['cardRoomId'] as int?,
      cardEventId: jsonSerialization['cardEventId'] as String?,
    );
  }

  int proposalId;

  int onBehalfOfUserId;

  String proposalHash;

  DateTime expiresAt;

  List<_i2.CrmChangeView> diff;

  int? cardRoomId;

  String? cardEventId;

  /// Returns a shallow copy of this [CrmProposal]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmProposal copyWith({
    int? proposalId,
    int? onBehalfOfUserId,
    String? proposalHash,
    DateTime? expiresAt,
    List<_i2.CrmChangeView>? diff,
    int? cardRoomId,
    String? cardEventId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmProposal',
      'proposalId': proposalId,
      'onBehalfOfUserId': onBehalfOfUserId,
      'proposalHash': proposalHash,
      'expiresAt': expiresAt.toJson(),
      'diff': diff.toJson(valueToJson: (v) => v.toJson()),
      if (cardRoomId != null) 'cardRoomId': cardRoomId,
      if (cardEventId != null) 'cardEventId': cardEventId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmProposalImpl extends CrmProposal {
  _CrmProposalImpl({
    required int proposalId,
    required int onBehalfOfUserId,
    required String proposalHash,
    required DateTime expiresAt,
    required List<_i2.CrmChangeView> diff,
    int? cardRoomId,
    String? cardEventId,
  }) : super._(
         proposalId: proposalId,
         onBehalfOfUserId: onBehalfOfUserId,
         proposalHash: proposalHash,
         expiresAt: expiresAt,
         diff: diff,
         cardRoomId: cardRoomId,
         cardEventId: cardEventId,
       );

  /// Returns a shallow copy of this [CrmProposal]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmProposal copyWith({
    int? proposalId,
    int? onBehalfOfUserId,
    String? proposalHash,
    DateTime? expiresAt,
    List<_i2.CrmChangeView>? diff,
    Object? cardRoomId = _Undefined,
    Object? cardEventId = _Undefined,
  }) {
    return CrmProposal(
      proposalId: proposalId ?? this.proposalId,
      onBehalfOfUserId: onBehalfOfUserId ?? this.onBehalfOfUserId,
      proposalHash: proposalHash ?? this.proposalHash,
      expiresAt: expiresAt ?? this.expiresAt,
      diff: diff ?? this.diff.map((e0) => e0.copyWith()).toList(),
      cardRoomId: cardRoomId is int? ? cardRoomId : this.cardRoomId,
      cardEventId: cardEventId is String? ? cardEventId : this.cardEventId,
    );
  }
}
