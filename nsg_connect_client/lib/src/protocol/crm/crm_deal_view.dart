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
import '../crm/crm_company_view.dart' as _i2;
import '../crm/crm_user_view.dart' as _i3;
import '../crm/crm_contact_view.dart' as _i4;
import '../crm/crm_next_step_state.dart' as _i5;
import '../crm/crm_activity_view.dart' as _i6;
import '../crm/crm_document_view.dart' as _i7;
import '../crm/crm_metric_view.dart' as _i8;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i9;

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmDealView implements _i1.SerializableModel {
  CrmDealView._({
    required this.id,
    required this.spaceId,
    required this.segmentId,
    required this.version,
    this.company,
    required this.pipelineId,
    required this.stageId,
    required this.title,
    required this.ownerUserId,
    this.ownerDisplayName,
    required this.participants,
    this.participantUsers,
    required this.contacts,
    this.amount,
    this.currency,
    this.expectedCloseAt,
    this.nextStep,
    this.nextStepAt,
    required this.nextStepPending,
    this.nextStepAssigneeId,
    this.nextStepAssigneeDisplayName,
    required this.nextStepState,
    this.lastActivityAt,
    required this.stageChangedAt,
    required this.activities,
    required this.documents,
    required this.metrics,
    this.roomId,
    this.closedAt,
    this.closeReason,
    this.archivedAt,
  });

  factory CrmDealView({
    required int id,
    required int spaceId,
    required int segmentId,
    required int version,
    _i2.CrmCompanyView? company,
    required int pipelineId,
    required int stageId,
    required String title,
    required int ownerUserId,
    String? ownerDisplayName,
    required List<int> participants,
    List<_i3.CrmUserView>? participantUsers,
    required List<_i4.CrmContactView> contacts,
    String? amount,
    String? currency,
    DateTime? expectedCloseAt,
    String? nextStep,
    DateTime? nextStepAt,
    required bool nextStepPending,
    int? nextStepAssigneeId,
    String? nextStepAssigneeDisplayName,
    required _i5.CrmNextStepState nextStepState,
    DateTime? lastActivityAt,
    required DateTime stageChangedAt,
    required List<_i6.CrmActivityView> activities,
    required List<_i7.CrmDocumentView> documents,
    required List<_i8.CrmMetricView> metrics,
    int? roomId,
    DateTime? closedAt,
    String? closeReason,
    DateTime? archivedAt,
  }) = _CrmDealViewImpl;

  factory CrmDealView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmDealView(
      id: jsonSerialization['id'] as int,
      spaceId: jsonSerialization['spaceId'] as int,
      segmentId: jsonSerialization['segmentId'] as int,
      version: jsonSerialization['version'] as int,
      company: jsonSerialization['company'] == null
          ? null
          : _i9.Protocol().deserialize<_i2.CrmCompanyView>(
              jsonSerialization['company'],
            ),
      pipelineId: jsonSerialization['pipelineId'] as int,
      stageId: jsonSerialization['stageId'] as int,
      title: jsonSerialization['title'] as String,
      ownerUserId: jsonSerialization['ownerUserId'] as int,
      ownerDisplayName: jsonSerialization['ownerDisplayName'] as String?,
      participants: _i9.Protocol().deserialize<List<int>>(
        jsonSerialization['participants'],
      ),
      participantUsers: jsonSerialization['participantUsers'] == null
          ? null
          : _i9.Protocol().deserialize<List<_i3.CrmUserView>>(
              jsonSerialization['participantUsers'],
            ),
      contacts: _i9.Protocol().deserialize<List<_i4.CrmContactView>>(
        jsonSerialization['contacts'],
      ),
      amount: jsonSerialization['amount'] as String?,
      currency: jsonSerialization['currency'] as String?,
      expectedCloseAt: jsonSerialization['expectedCloseAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['expectedCloseAt'],
            ),
      nextStep: jsonSerialization['nextStep'] as String?,
      nextStepAt: jsonSerialization['nextStepAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['nextStepAt']),
      nextStepPending: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['nextStepPending'],
      ),
      nextStepAssigneeId: jsonSerialization['nextStepAssigneeId'] as int?,
      nextStepAssigneeDisplayName:
          jsonSerialization['nextStepAssigneeDisplayName'] as String?,
      nextStepState: _i5.CrmNextStepState.fromJson(
        (jsonSerialization['nextStepState'] as String),
      ),
      lastActivityAt: jsonSerialization['lastActivityAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActivityAt'],
            ),
      stageChangedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['stageChangedAt'],
      ),
      activities: _i9.Protocol().deserialize<List<_i6.CrmActivityView>>(
        jsonSerialization['activities'],
      ),
      documents: _i9.Protocol().deserialize<List<_i7.CrmDocumentView>>(
        jsonSerialization['documents'],
      ),
      metrics: _i9.Protocol().deserialize<List<_i8.CrmMetricView>>(
        jsonSerialization['metrics'],
      ),
      roomId: jsonSerialization['roomId'] as int?,
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
      closeReason: jsonSerialization['closeReason'] as String?,
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['archivedAt']),
    );
  }

  int id;

  int spaceId;

  int segmentId;

  int version;

  /// The company may be in a segment invisible to the deal reader.
  _i2.CrmCompanyView? company;

  int pipelineId;

  int stageId;

  String title;

  int ownerUserId;

  String? ownerDisplayName;

  List<int> participants;

  List<_i3.CrmUserView>? participantUsers;

  List<_i4.CrmContactView> contacts;

  String? amount;

  String? currency;

  DateTime? expectedCloseAt;

  String? nextStep;

  DateTime? nextStepAt;

  bool nextStepPending;

  int? nextStepAssigneeId;

  String? nextStepAssigneeDisplayName;

  _i5.CrmNextStepState nextStepState;

  DateTime? lastActivityAt;

  DateTime stageChangedAt;

  List<_i6.CrmActivityView> activities;

  List<_i7.CrmDocumentView> documents;

  List<_i8.CrmMetricView> metrics;

  int? roomId;

  DateTime? closedAt;

  String? closeReason;

  DateTime? archivedAt;

  /// Returns a shallow copy of this [CrmDealView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmDealView copyWith({
    int? id,
    int? spaceId,
    int? segmentId,
    int? version,
    _i2.CrmCompanyView? company,
    int? pipelineId,
    int? stageId,
    String? title,
    int? ownerUserId,
    String? ownerDisplayName,
    List<int>? participants,
    List<_i3.CrmUserView>? participantUsers,
    List<_i4.CrmContactView>? contacts,
    String? amount,
    String? currency,
    DateTime? expectedCloseAt,
    String? nextStep,
    DateTime? nextStepAt,
    bool? nextStepPending,
    int? nextStepAssigneeId,
    String? nextStepAssigneeDisplayName,
    _i5.CrmNextStepState? nextStepState,
    DateTime? lastActivityAt,
    DateTime? stageChangedAt,
    List<_i6.CrmActivityView>? activities,
    List<_i7.CrmDocumentView>? documents,
    List<_i8.CrmMetricView>? metrics,
    int? roomId,
    DateTime? closedAt,
    String? closeReason,
    DateTime? archivedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmDealView',
      'id': id,
      'spaceId': spaceId,
      'segmentId': segmentId,
      'version': version,
      if (company != null) 'company': company?.toJson(),
      'pipelineId': pipelineId,
      'stageId': stageId,
      'title': title,
      'ownerUserId': ownerUserId,
      if (ownerDisplayName != null) 'ownerDisplayName': ownerDisplayName,
      'participants': participants.toJson(),
      if (participantUsers != null)
        'participantUsers': participantUsers?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      'contacts': contacts.toJson(valueToJson: (v) => v.toJson()),
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (expectedCloseAt != null) 'expectedCloseAt': expectedCloseAt?.toJson(),
      if (nextStep != null) 'nextStep': nextStep,
      if (nextStepAt != null) 'nextStepAt': nextStepAt?.toJson(),
      'nextStepPending': nextStepPending,
      if (nextStepAssigneeId != null) 'nextStepAssigneeId': nextStepAssigneeId,
      if (nextStepAssigneeDisplayName != null)
        'nextStepAssigneeDisplayName': nextStepAssigneeDisplayName,
      'nextStepState': nextStepState.toJson(),
      if (lastActivityAt != null) 'lastActivityAt': lastActivityAt?.toJson(),
      'stageChangedAt': stageChangedAt.toJson(),
      'activities': activities.toJson(valueToJson: (v) => v.toJson()),
      'documents': documents.toJson(valueToJson: (v) => v.toJson()),
      'metrics': metrics.toJson(valueToJson: (v) => v.toJson()),
      if (roomId != null) 'roomId': roomId,
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
      if (closeReason != null) 'closeReason': closeReason,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmDealViewImpl extends CrmDealView {
  _CrmDealViewImpl({
    required int id,
    required int spaceId,
    required int segmentId,
    required int version,
    _i2.CrmCompanyView? company,
    required int pipelineId,
    required int stageId,
    required String title,
    required int ownerUserId,
    String? ownerDisplayName,
    required List<int> participants,
    List<_i3.CrmUserView>? participantUsers,
    required List<_i4.CrmContactView> contacts,
    String? amount,
    String? currency,
    DateTime? expectedCloseAt,
    String? nextStep,
    DateTime? nextStepAt,
    required bool nextStepPending,
    int? nextStepAssigneeId,
    String? nextStepAssigneeDisplayName,
    required _i5.CrmNextStepState nextStepState,
    DateTime? lastActivityAt,
    required DateTime stageChangedAt,
    required List<_i6.CrmActivityView> activities,
    required List<_i7.CrmDocumentView> documents,
    required List<_i8.CrmMetricView> metrics,
    int? roomId,
    DateTime? closedAt,
    String? closeReason,
    DateTime? archivedAt,
  }) : super._(
         id: id,
         spaceId: spaceId,
         segmentId: segmentId,
         version: version,
         company: company,
         pipelineId: pipelineId,
         stageId: stageId,
         title: title,
         ownerUserId: ownerUserId,
         ownerDisplayName: ownerDisplayName,
         participants: participants,
         participantUsers: participantUsers,
         contacts: contacts,
         amount: amount,
         currency: currency,
         expectedCloseAt: expectedCloseAt,
         nextStep: nextStep,
         nextStepAt: nextStepAt,
         nextStepPending: nextStepPending,
         nextStepAssigneeId: nextStepAssigneeId,
         nextStepAssigneeDisplayName: nextStepAssigneeDisplayName,
         nextStepState: nextStepState,
         lastActivityAt: lastActivityAt,
         stageChangedAt: stageChangedAt,
         activities: activities,
         documents: documents,
         metrics: metrics,
         roomId: roomId,
         closedAt: closedAt,
         closeReason: closeReason,
         archivedAt: archivedAt,
       );

  /// Returns a shallow copy of this [CrmDealView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmDealView copyWith({
    int? id,
    int? spaceId,
    int? segmentId,
    int? version,
    Object? company = _Undefined,
    int? pipelineId,
    int? stageId,
    String? title,
    int? ownerUserId,
    Object? ownerDisplayName = _Undefined,
    List<int>? participants,
    Object? participantUsers = _Undefined,
    List<_i4.CrmContactView>? contacts,
    Object? amount = _Undefined,
    Object? currency = _Undefined,
    Object? expectedCloseAt = _Undefined,
    Object? nextStep = _Undefined,
    Object? nextStepAt = _Undefined,
    bool? nextStepPending,
    Object? nextStepAssigneeId = _Undefined,
    Object? nextStepAssigneeDisplayName = _Undefined,
    _i5.CrmNextStepState? nextStepState,
    Object? lastActivityAt = _Undefined,
    DateTime? stageChangedAt,
    List<_i6.CrmActivityView>? activities,
    List<_i7.CrmDocumentView>? documents,
    List<_i8.CrmMetricView>? metrics,
    Object? roomId = _Undefined,
    Object? closedAt = _Undefined,
    Object? closeReason = _Undefined,
    Object? archivedAt = _Undefined,
  }) {
    return CrmDealView(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      segmentId: segmentId ?? this.segmentId,
      version: version ?? this.version,
      company: company is _i2.CrmCompanyView?
          ? company
          : this.company?.copyWith(),
      pipelineId: pipelineId ?? this.pipelineId,
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      ownerDisplayName: ownerDisplayName is String?
          ? ownerDisplayName
          : this.ownerDisplayName,
      participants: participants ?? this.participants.map((e0) => e0).toList(),
      participantUsers: participantUsers is List<_i3.CrmUserView>?
          ? participantUsers
          : this.participantUsers?.map((e0) => e0.copyWith()).toList(),
      contacts: contacts ?? this.contacts.map((e0) => e0.copyWith()).toList(),
      amount: amount is String? ? amount : this.amount,
      currency: currency is String? ? currency : this.currency,
      expectedCloseAt: expectedCloseAt is DateTime?
          ? expectedCloseAt
          : this.expectedCloseAt,
      nextStep: nextStep is String? ? nextStep : this.nextStep,
      nextStepAt: nextStepAt is DateTime? ? nextStepAt : this.nextStepAt,
      nextStepPending: nextStepPending ?? this.nextStepPending,
      nextStepAssigneeId: nextStepAssigneeId is int?
          ? nextStepAssigneeId
          : this.nextStepAssigneeId,
      nextStepAssigneeDisplayName: nextStepAssigneeDisplayName is String?
          ? nextStepAssigneeDisplayName
          : this.nextStepAssigneeDisplayName,
      nextStepState: nextStepState ?? this.nextStepState,
      lastActivityAt: lastActivityAt is DateTime?
          ? lastActivityAt
          : this.lastActivityAt,
      stageChangedAt: stageChangedAt ?? this.stageChangedAt,
      activities:
          activities ?? this.activities.map((e0) => e0.copyWith()).toList(),
      documents:
          documents ?? this.documents.map((e0) => e0.copyWith()).toList(),
      metrics: metrics ?? this.metrics.map((e0) => e0.copyWith()).toList(),
      roomId: roomId is int? ? roomId : this.roomId,
      closedAt: closedAt is DateTime? ? closedAt : this.closedAt,
      closeReason: closeReason is String? ? closeReason : this.closeReason,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
    );
  }
}
