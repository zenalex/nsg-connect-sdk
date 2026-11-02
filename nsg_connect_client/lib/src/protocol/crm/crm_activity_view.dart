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
import '../crm/crm_activity_type.dart' as _i2;
import '../crm/crm_actor_kind.dart' as _i3;

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmActivityView implements _i1.SerializableModel {
  CrmActivityView._({
    required this.id,
    required this.segmentId,
    this.companyId,
    this.dealId,
    required this.version,
    required this.type,
    required this.occurredAt,
    required this.summary,
    this.outcome,
    required this.sourceJson,
    required this.authorUserId,
    this.authorDisplayName,
    this.onBehalfOfUserId,
    this.onBehalfOfDisplayName,
    this.actorKind,
  });

  factory CrmActivityView({
    required int id,
    required int segmentId,
    int? companyId,
    int? dealId,
    required int version,
    required _i2.CrmActivityType type,
    required DateTime occurredAt,
    required String summary,
    String? outcome,
    required String sourceJson,
    required int authorUserId,
    String? authorDisplayName,
    int? onBehalfOfUserId,
    String? onBehalfOfDisplayName,
    _i3.CrmActorKind? actorKind,
  }) = _CrmActivityViewImpl;

  factory CrmActivityView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmActivityView(
      id: jsonSerialization['id'] as int,
      segmentId: jsonSerialization['segmentId'] as int,
      companyId: jsonSerialization['companyId'] as int?,
      dealId: jsonSerialization['dealId'] as int?,
      version: jsonSerialization['version'] as int,
      type: _i2.CrmActivityType.fromJson((jsonSerialization['type'] as String)),
      occurredAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['occurredAt'],
      ),
      summary: jsonSerialization['summary'] as String,
      outcome: jsonSerialization['outcome'] as String?,
      sourceJson: jsonSerialization['sourceJson'] as String,
      authorUserId: jsonSerialization['authorUserId'] as int,
      authorDisplayName: jsonSerialization['authorDisplayName'] as String?,
      onBehalfOfUserId: jsonSerialization['onBehalfOfUserId'] as int?,
      onBehalfOfDisplayName:
          jsonSerialization['onBehalfOfDisplayName'] as String?,
      actorKind: jsonSerialization['actorKind'] == null
          ? null
          : _i3.CrmActorKind.fromJson(
              (jsonSerialization['actorKind'] as String),
            ),
    );
  }

  int id;

  int segmentId;

  /// Hidden parent in another segment: never disclose its reference.
  int? companyId;

  int? dealId;

  int version;

  _i2.CrmActivityType type;

  DateTime occurredAt;

  String summary;

  String? outcome;

  String sourceJson;

  int authorUserId;

  String? authorDisplayName;

  int? onBehalfOfUserId;

  String? onBehalfOfDisplayName;

  /// Authoritative create-audit kind; null if historical provenance is absent.
  _i3.CrmActorKind? actorKind;

  /// Returns a shallow copy of this [CrmActivityView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmActivityView copyWith({
    int? id,
    int? segmentId,
    int? companyId,
    int? dealId,
    int? version,
    _i2.CrmActivityType? type,
    DateTime? occurredAt,
    String? summary,
    String? outcome,
    String? sourceJson,
    int? authorUserId,
    String? authorDisplayName,
    int? onBehalfOfUserId,
    String? onBehalfOfDisplayName,
    _i3.CrmActorKind? actorKind,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmActivityView',
      'id': id,
      'segmentId': segmentId,
      if (companyId != null) 'companyId': companyId,
      if (dealId != null) 'dealId': dealId,
      'version': version,
      'type': type.toJson(),
      'occurredAt': occurredAt.toJson(),
      'summary': summary,
      if (outcome != null) 'outcome': outcome,
      'sourceJson': sourceJson,
      'authorUserId': authorUserId,
      if (authorDisplayName != null) 'authorDisplayName': authorDisplayName,
      if (onBehalfOfUserId != null) 'onBehalfOfUserId': onBehalfOfUserId,
      if (onBehalfOfDisplayName != null)
        'onBehalfOfDisplayName': onBehalfOfDisplayName,
      if (actorKind != null) 'actorKind': actorKind?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmActivityViewImpl extends CrmActivityView {
  _CrmActivityViewImpl({
    required int id,
    required int segmentId,
    int? companyId,
    int? dealId,
    required int version,
    required _i2.CrmActivityType type,
    required DateTime occurredAt,
    required String summary,
    String? outcome,
    required String sourceJson,
    required int authorUserId,
    String? authorDisplayName,
    int? onBehalfOfUserId,
    String? onBehalfOfDisplayName,
    _i3.CrmActorKind? actorKind,
  }) : super._(
         id: id,
         segmentId: segmentId,
         companyId: companyId,
         dealId: dealId,
         version: version,
         type: type,
         occurredAt: occurredAt,
         summary: summary,
         outcome: outcome,
         sourceJson: sourceJson,
         authorUserId: authorUserId,
         authorDisplayName: authorDisplayName,
         onBehalfOfUserId: onBehalfOfUserId,
         onBehalfOfDisplayName: onBehalfOfDisplayName,
         actorKind: actorKind,
       );

  /// Returns a shallow copy of this [CrmActivityView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmActivityView copyWith({
    int? id,
    int? segmentId,
    Object? companyId = _Undefined,
    Object? dealId = _Undefined,
    int? version,
    _i2.CrmActivityType? type,
    DateTime? occurredAt,
    String? summary,
    Object? outcome = _Undefined,
    String? sourceJson,
    int? authorUserId,
    Object? authorDisplayName = _Undefined,
    Object? onBehalfOfUserId = _Undefined,
    Object? onBehalfOfDisplayName = _Undefined,
    Object? actorKind = _Undefined,
  }) {
    return CrmActivityView(
      id: id ?? this.id,
      segmentId: segmentId ?? this.segmentId,
      companyId: companyId is int? ? companyId : this.companyId,
      dealId: dealId is int? ? dealId : this.dealId,
      version: version ?? this.version,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      summary: summary ?? this.summary,
      outcome: outcome is String? ? outcome : this.outcome,
      sourceJson: sourceJson ?? this.sourceJson,
      authorUserId: authorUserId ?? this.authorUserId,
      authorDisplayName: authorDisplayName is String?
          ? authorDisplayName
          : this.authorDisplayName,
      onBehalfOfUserId: onBehalfOfUserId is int?
          ? onBehalfOfUserId
          : this.onBehalfOfUserId,
      onBehalfOfDisplayName: onBehalfOfDisplayName is String?
          ? onBehalfOfDisplayName
          : this.onBehalfOfDisplayName,
      actorKind: actorKind is _i3.CrmActorKind? ? actorKind : this.actorKind,
    );
  }
}
