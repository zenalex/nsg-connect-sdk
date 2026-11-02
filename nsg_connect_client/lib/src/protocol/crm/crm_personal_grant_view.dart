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

/// Owner-visible metadata; never includes a bearer or its digest.
abstract class CrmPersonalGrantView implements _i1.SerializableModel {
  CrmPersonalGrantView._({
    required this.grantId,
    required this.spaceId,
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });

  factory CrmPersonalGrantView({
    required String grantId,
    required int spaceId,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) = _CrmPersonalGrantViewImpl;

  factory CrmPersonalGrantView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CrmPersonalGrantView(
      grantId: jsonSerialization['grantId'] as String,
      spaceId: jsonSerialization['spaceId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  String grantId;

  int spaceId;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? revokedAt;

  /// Returns a shallow copy of this [CrmPersonalGrantView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmPersonalGrantView copyWith({
    String? grantId,
    int? spaceId,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmPersonalGrantView',
      'grantId': grantId,
      'spaceId': spaceId,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmPersonalGrantViewImpl extends CrmPersonalGrantView {
  _CrmPersonalGrantViewImpl({
    required String grantId,
    required int spaceId,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) : super._(
         grantId: grantId,
         spaceId: spaceId,
         createdAt: createdAt,
         expiresAt: expiresAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [CrmPersonalGrantView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmPersonalGrantView copyWith({
    String? grantId,
    int? spaceId,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? revokedAt = _Undefined,
  }) {
    return CrmPersonalGrantView(
      grantId: grantId ?? this.grantId,
      spaceId: spaceId ?? this.spaceId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
