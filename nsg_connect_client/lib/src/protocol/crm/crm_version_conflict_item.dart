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

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmVersionConflictItem implements _i1.SerializableModel {
  CrmVersionConflictItem._({
    required this.entity,
    required this.entityId,
    required this.expectedVersion,
    this.actualVersion,
  });

  factory CrmVersionConflictItem({
    required _i2.CrmEntityKind entity,
    required int entityId,
    required int expectedVersion,
    int? actualVersion,
  }) = _CrmVersionConflictItemImpl;

  factory CrmVersionConflictItem.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CrmVersionConflictItem(
      entity: _i2.CrmEntityKind.fromJson(
        (jsonSerialization['entity'] as String),
      ),
      entityId: jsonSerialization['entityId'] as int,
      expectedVersion: jsonSerialization['expectedVersion'] as int,
      actualVersion: jsonSerialization['actualVersion'] as int?,
    );
  }

  _i2.CrmEntityKind entity;

  int entityId;

  int expectedVersion;

  int? actualVersion;

  /// Returns a shallow copy of this [CrmVersionConflictItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmVersionConflictItem copyWith({
    _i2.CrmEntityKind? entity,
    int? entityId,
    int? expectedVersion,
    int? actualVersion,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmVersionConflictItem',
      'entity': entity.toJson(),
      'entityId': entityId,
      'expectedVersion': expectedVersion,
      if (actualVersion != null) 'actualVersion': actualVersion,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmVersionConflictItemImpl extends CrmVersionConflictItem {
  _CrmVersionConflictItemImpl({
    required _i2.CrmEntityKind entity,
    required int entityId,
    required int expectedVersion,
    int? actualVersion,
  }) : super._(
         entity: entity,
         entityId: entityId,
         expectedVersion: expectedVersion,
         actualVersion: actualVersion,
       );

  /// Returns a shallow copy of this [CrmVersionConflictItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmVersionConflictItem copyWith({
    _i2.CrmEntityKind? entity,
    int? entityId,
    int? expectedVersion,
    Object? actualVersion = _Undefined,
  }) {
    return CrmVersionConflictItem(
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      actualVersion: actualVersion is int? ? actualVersion : this.actualVersion,
    );
  }
}
