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
import '../crm/crm_actor_kind.dart' as _i2;
import '../crm/crm_changeset_status.dart' as _i3;
import '../crm/crm_change_view.dart' as _i4;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i5;

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmChangesetView implements _i1.SerializableModel {
  CrmChangesetView._({
    required this.id,
    required this.spaceId,
    required this.actorUserId,
    required this.actorKind,
    this.onBehalfOfUserId,
    required this.status,
    required this.createdAt,
    this.appliedAt,
    this.undoneAt,
    required this.undoable,
    required this.items,
  });

  factory CrmChangesetView({
    required int id,
    required int spaceId,
    required int actorUserId,
    required _i2.CrmActorKind actorKind,
    int? onBehalfOfUserId,
    required _i3.CrmChangesetStatus status,
    required DateTime createdAt,
    DateTime? appliedAt,
    DateTime? undoneAt,
    required bool undoable,
    required List<_i4.CrmChangeView> items,
  }) = _CrmChangesetViewImpl;

  factory CrmChangesetView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmChangesetView(
      id: jsonSerialization['id'] as int,
      spaceId: jsonSerialization['spaceId'] as int,
      actorUserId: jsonSerialization['actorUserId'] as int,
      actorKind: _i2.CrmActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      onBehalfOfUserId: jsonSerialization['onBehalfOfUserId'] as int?,
      status: _i3.CrmChangesetStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      appliedAt: jsonSerialization['appliedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['appliedAt']),
      undoneAt: jsonSerialization['undoneAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['undoneAt']),
      undoable: _i1.BoolJsonExtension.fromJson(jsonSerialization['undoable']),
      items: _i5.Protocol().deserialize<List<_i4.CrmChangeView>>(
        jsonSerialization['items'],
      ),
    );
  }

  int id;

  int spaceId;

  int actorUserId;

  _i2.CrmActorKind actorKind;

  int? onBehalfOfUserId;

  _i3.CrmChangesetStatus status;

  DateTime createdAt;

  DateTime? appliedAt;

  DateTime? undoneAt;

  bool undoable;

  List<_i4.CrmChangeView> items;

  /// Returns a shallow copy of this [CrmChangesetView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmChangesetView copyWith({
    int? id,
    int? spaceId,
    int? actorUserId,
    _i2.CrmActorKind? actorKind,
    int? onBehalfOfUserId,
    _i3.CrmChangesetStatus? status,
    DateTime? createdAt,
    DateTime? appliedAt,
    DateTime? undoneAt,
    bool? undoable,
    List<_i4.CrmChangeView>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmChangesetView',
      'id': id,
      'spaceId': spaceId,
      'actorUserId': actorUserId,
      'actorKind': actorKind.toJson(),
      if (onBehalfOfUserId != null) 'onBehalfOfUserId': onBehalfOfUserId,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
      if (appliedAt != null) 'appliedAt': appliedAt?.toJson(),
      if (undoneAt != null) 'undoneAt': undoneAt?.toJson(),
      'undoable': undoable,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmChangesetViewImpl extends CrmChangesetView {
  _CrmChangesetViewImpl({
    required int id,
    required int spaceId,
    required int actorUserId,
    required _i2.CrmActorKind actorKind,
    int? onBehalfOfUserId,
    required _i3.CrmChangesetStatus status,
    required DateTime createdAt,
    DateTime? appliedAt,
    DateTime? undoneAt,
    required bool undoable,
    required List<_i4.CrmChangeView> items,
  }) : super._(
         id: id,
         spaceId: spaceId,
         actorUserId: actorUserId,
         actorKind: actorKind,
         onBehalfOfUserId: onBehalfOfUserId,
         status: status,
         createdAt: createdAt,
         appliedAt: appliedAt,
         undoneAt: undoneAt,
         undoable: undoable,
         items: items,
       );

  /// Returns a shallow copy of this [CrmChangesetView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmChangesetView copyWith({
    int? id,
    int? spaceId,
    int? actorUserId,
    _i2.CrmActorKind? actorKind,
    Object? onBehalfOfUserId = _Undefined,
    _i3.CrmChangesetStatus? status,
    DateTime? createdAt,
    Object? appliedAt = _Undefined,
    Object? undoneAt = _Undefined,
    bool? undoable,
    List<_i4.CrmChangeView>? items,
  }) {
    return CrmChangesetView(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      actorUserId: actorUserId ?? this.actorUserId,
      actorKind: actorKind ?? this.actorKind,
      onBehalfOfUserId: onBehalfOfUserId is int?
          ? onBehalfOfUserId
          : this.onBehalfOfUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      appliedAt: appliedAt is DateTime? ? appliedAt : this.appliedAt,
      undoneAt: undoneAt is DateTime? ? undoneAt : this.undoneAt,
      undoable: undoable ?? this.undoable,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
