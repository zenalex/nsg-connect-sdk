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
import '../crm/crm_entity_kind.dart' as _i2;
import '../crm/crm_change_operation.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// TASK95 4.11: only owner/onBehalfOf or admin may receive snapshots via proposals/undo. Others receive names only, null snapshots.
abstract class CrmChangeView implements _i1.SerializableModel {
  CrmChangeView._({
    required this.seq,
    required this.entity,
    this.entityId,
    this.tempRef,
    required this.op,
    required this.changedFields,
    required this.versionBefore,
    required this.versionAfter,
    this.beforeJson,
    this.afterJson,
    required this.pdRedacted,
  });

  factory CrmChangeView({
    required int seq,
    required _i2.CrmEntityKind entity,
    int? entityId,
    String? tempRef,
    required _i3.CrmChangeOperation op,
    required List<String> changedFields,
    required int versionBefore,
    required int versionAfter,
    String? beforeJson,
    String? afterJson,
    required bool pdRedacted,
  }) = _CrmChangeViewImpl;

  factory CrmChangeView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmChangeView(
      seq: jsonSerialization['seq'] as int,
      entity: _i2.CrmEntityKind.fromJson(
        (jsonSerialization['entity'] as String),
      ),
      entityId: jsonSerialization['entityId'] as int?,
      tempRef: jsonSerialization['tempRef'] as String?,
      op: _i3.CrmChangeOperation.fromJson((jsonSerialization['op'] as String)),
      changedFields: _i4.Protocol().deserialize<List<String>>(
        jsonSerialization['changedFields'],
      ),
      versionBefore: jsonSerialization['versionBefore'] as int,
      versionAfter: jsonSerialization['versionAfter'] as int,
      beforeJson: jsonSerialization['beforeJson'] as String?,
      afterJson: jsonSerialization['afterJson'] as String?,
      pdRedacted: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['pdRedacted'],
      ),
    );
  }

  int seq;

  _i2.CrmEntityKind entity;

  int? entityId;

  String? tempRef;

  _i3.CrmChangeOperation op;

  List<String> changedFields;

  int versionBefore;

  int versionAfter;

  String? beforeJson;

  String? afterJson;

  bool pdRedacted;

  /// Returns a shallow copy of this [CrmChangeView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmChangeView copyWith({
    int? seq,
    _i2.CrmEntityKind? entity,
    int? entityId,
    String? tempRef,
    _i3.CrmChangeOperation? op,
    List<String>? changedFields,
    int? versionBefore,
    int? versionAfter,
    String? beforeJson,
    String? afterJson,
    bool? pdRedacted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmChangeView',
      'seq': seq,
      'entity': entity.toJson(),
      if (entityId != null) 'entityId': entityId,
      if (tempRef != null) 'tempRef': tempRef,
      'op': op.toJson(),
      'changedFields': changedFields.toJson(),
      'versionBefore': versionBefore,
      'versionAfter': versionAfter,
      if (beforeJson != null) 'beforeJson': beforeJson,
      if (afterJson != null) 'afterJson': afterJson,
      'pdRedacted': pdRedacted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmChangeViewImpl extends CrmChangeView {
  _CrmChangeViewImpl({
    required int seq,
    required _i2.CrmEntityKind entity,
    int? entityId,
    String? tempRef,
    required _i3.CrmChangeOperation op,
    required List<String> changedFields,
    required int versionBefore,
    required int versionAfter,
    String? beforeJson,
    String? afterJson,
    required bool pdRedacted,
  }) : super._(
         seq: seq,
         entity: entity,
         entityId: entityId,
         tempRef: tempRef,
         op: op,
         changedFields: changedFields,
         versionBefore: versionBefore,
         versionAfter: versionAfter,
         beforeJson: beforeJson,
         afterJson: afterJson,
         pdRedacted: pdRedacted,
       );

  /// Returns a shallow copy of this [CrmChangeView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmChangeView copyWith({
    int? seq,
    _i2.CrmEntityKind? entity,
    Object? entityId = _Undefined,
    Object? tempRef = _Undefined,
    _i3.CrmChangeOperation? op,
    List<String>? changedFields,
    int? versionBefore,
    int? versionAfter,
    Object? beforeJson = _Undefined,
    Object? afterJson = _Undefined,
    bool? pdRedacted,
  }) {
    return CrmChangeView(
      seq: seq ?? this.seq,
      entity: entity ?? this.entity,
      entityId: entityId is int? ? entityId : this.entityId,
      tempRef: tempRef is String? ? tempRef : this.tempRef,
      op: op ?? this.op,
      changedFields:
          changedFields ?? this.changedFields.map((e0) => e0).toList(),
      versionBefore: versionBefore ?? this.versionBefore,
      versionAfter: versionAfter ?? this.versionAfter,
      beforeJson: beforeJson is String? ? beforeJson : this.beforeJson,
      afterJson: afterJson is String? ? afterJson : this.afterJson,
      pdRedacted: pdRedacted ?? this.pdRedacted,
    );
  }
}
