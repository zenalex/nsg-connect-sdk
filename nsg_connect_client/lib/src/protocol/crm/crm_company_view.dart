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
import '../crm/crm_company_kind.dart' as _i2;
import '../crm/crm_company_status.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmCompanyView implements _i1.SerializableModel {
  CrmCompanyView._({
    required this.id,
    required this.spaceId,
    required this.segmentId,
    required this.version,
    required this.name,
    required this.kind,
    this.region,
    this.website,
    required this.ownerUserId,
    required this.tags,
    this.notes,
    this.externalRefsJson,
    required this.status,
    this.archivedAt,
  });

  factory CrmCompanyView({
    required int id,
    required int spaceId,
    required int segmentId,
    required int version,
    required String name,
    required _i2.CrmCompanyKind kind,
    String? region,
    String? website,
    required int ownerUserId,
    required List<String> tags,
    String? notes,
    String? externalRefsJson,
    required _i3.CrmCompanyStatus status,
    DateTime? archivedAt,
  }) = _CrmCompanyViewImpl;

  factory CrmCompanyView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmCompanyView(
      id: jsonSerialization['id'] as int,
      spaceId: jsonSerialization['spaceId'] as int,
      segmentId: jsonSerialization['segmentId'] as int,
      version: jsonSerialization['version'] as int,
      name: jsonSerialization['name'] as String,
      kind: _i2.CrmCompanyKind.fromJson((jsonSerialization['kind'] as String)),
      region: jsonSerialization['region'] as String?,
      website: jsonSerialization['website'] as String?,
      ownerUserId: jsonSerialization['ownerUserId'] as int,
      tags: _i4.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      notes: jsonSerialization['notes'] as String?,
      externalRefsJson: jsonSerialization['externalRefsJson'] as String?,
      status: _i3.CrmCompanyStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['archivedAt']),
    );
  }

  int id;

  int spaceId;

  int segmentId;

  int version;

  String name;

  _i2.CrmCompanyKind kind;

  String? region;

  String? website;

  int ownerUserId;

  List<String> tags;

  String? notes;

  String? externalRefsJson;

  _i3.CrmCompanyStatus status;

  DateTime? archivedAt;

  /// Returns a shallow copy of this [CrmCompanyView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmCompanyView copyWith({
    int? id,
    int? spaceId,
    int? segmentId,
    int? version,
    String? name,
    _i2.CrmCompanyKind? kind,
    String? region,
    String? website,
    int? ownerUserId,
    List<String>? tags,
    String? notes,
    String? externalRefsJson,
    _i3.CrmCompanyStatus? status,
    DateTime? archivedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmCompanyView',
      'id': id,
      'spaceId': spaceId,
      'segmentId': segmentId,
      'version': version,
      'name': name,
      'kind': kind.toJson(),
      if (region != null) 'region': region,
      if (website != null) 'website': website,
      'ownerUserId': ownerUserId,
      'tags': tags.toJson(),
      if (notes != null) 'notes': notes,
      if (externalRefsJson != null) 'externalRefsJson': externalRefsJson,
      'status': status.toJson(),
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmCompanyViewImpl extends CrmCompanyView {
  _CrmCompanyViewImpl({
    required int id,
    required int spaceId,
    required int segmentId,
    required int version,
    required String name,
    required _i2.CrmCompanyKind kind,
    String? region,
    String? website,
    required int ownerUserId,
    required List<String> tags,
    String? notes,
    String? externalRefsJson,
    required _i3.CrmCompanyStatus status,
    DateTime? archivedAt,
  }) : super._(
         id: id,
         spaceId: spaceId,
         segmentId: segmentId,
         version: version,
         name: name,
         kind: kind,
         region: region,
         website: website,
         ownerUserId: ownerUserId,
         tags: tags,
         notes: notes,
         externalRefsJson: externalRefsJson,
         status: status,
         archivedAt: archivedAt,
       );

  /// Returns a shallow copy of this [CrmCompanyView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmCompanyView copyWith({
    int? id,
    int? spaceId,
    int? segmentId,
    int? version,
    String? name,
    _i2.CrmCompanyKind? kind,
    Object? region = _Undefined,
    Object? website = _Undefined,
    int? ownerUserId,
    List<String>? tags,
    Object? notes = _Undefined,
    Object? externalRefsJson = _Undefined,
    _i3.CrmCompanyStatus? status,
    Object? archivedAt = _Undefined,
  }) {
    return CrmCompanyView(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      segmentId: segmentId ?? this.segmentId,
      version: version ?? this.version,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      region: region is String? ? region : this.region,
      website: website is String? ? website : this.website,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      notes: notes is String? ? notes : this.notes,
      externalRefsJson: externalRefsJson is String?
          ? externalRefsJson
          : this.externalRefsJson,
      status: status ?? this.status,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
    );
  }
}
