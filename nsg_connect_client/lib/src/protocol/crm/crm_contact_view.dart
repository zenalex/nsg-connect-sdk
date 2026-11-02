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
import '../crm/crm_pd_basis.dart' as _i2;

/// TASK95 4.4/5: nullable PD fields. When pdRedacted, all PD fields must be null.
abstract class CrmContactView implements _i1.SerializableModel {
  CrmContactView._({
    required this.id,
    required this.segmentId,
    this.companyId,
    this.dealId,
    required this.version,
    this.fullName,
    this.position,
    this.phone,
    this.email,
    this.messenger,
    this.messengerUserId,
    this.notes,
    this.pdBasis,
    this.pdSource,
    this.pdCollectedAt,
    required this.pdRedacted,
  });

  factory CrmContactView({
    required int id,
    required int segmentId,
    int? companyId,
    int? dealId,
    required int version,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    String? messenger,
    int? messengerUserId,
    String? notes,
    _i2.CrmPdBasis? pdBasis,
    String? pdSource,
    DateTime? pdCollectedAt,
    required bool pdRedacted,
  }) = _CrmContactViewImpl;

  factory CrmContactView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmContactView(
      id: jsonSerialization['id'] as int,
      segmentId: jsonSerialization['segmentId'] as int,
      companyId: jsonSerialization['companyId'] as int?,
      dealId: jsonSerialization['dealId'] as int?,
      version: jsonSerialization['version'] as int,
      fullName: jsonSerialization['fullName'] as String?,
      position: jsonSerialization['position'] as String?,
      phone: jsonSerialization['phone'] as String?,
      email: jsonSerialization['email'] as String?,
      messenger: jsonSerialization['messenger'] as String?,
      messengerUserId: jsonSerialization['messengerUserId'] as int?,
      notes: jsonSerialization['notes'] as String?,
      pdBasis: jsonSerialization['pdBasis'] == null
          ? null
          : _i2.CrmPdBasis.fromJson((jsonSerialization['pdBasis'] as String)),
      pdSource: jsonSerialization['pdSource'] as String?,
      pdCollectedAt: jsonSerialization['pdCollectedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['pdCollectedAt'],
            ),
      pdRedacted: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['pdRedacted'],
      ),
    );
  }

  int id;

  int segmentId;

  /// Hidden parent in another segment: never disclose its reference.
  int? companyId;

  int? dealId;

  int version;

  String? fullName;

  String? position;

  String? phone;

  String? email;

  String? messenger;

  int? messengerUserId;

  String? notes;

  _i2.CrmPdBasis? pdBasis;

  String? pdSource;

  DateTime? pdCollectedAt;

  bool pdRedacted;

  /// Returns a shallow copy of this [CrmContactView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmContactView copyWith({
    int? id,
    int? segmentId,
    int? companyId,
    int? dealId,
    int? version,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    String? messenger,
    int? messengerUserId,
    String? notes,
    _i2.CrmPdBasis? pdBasis,
    String? pdSource,
    DateTime? pdCollectedAt,
    bool? pdRedacted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmContactView',
      'id': id,
      'segmentId': segmentId,
      if (companyId != null) 'companyId': companyId,
      if (dealId != null) 'dealId': dealId,
      'version': version,
      if (fullName != null) 'fullName': fullName,
      if (position != null) 'position': position,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (messenger != null) 'messenger': messenger,
      if (messengerUserId != null) 'messengerUserId': messengerUserId,
      if (notes != null) 'notes': notes,
      if (pdBasis != null) 'pdBasis': pdBasis?.toJson(),
      if (pdSource != null) 'pdSource': pdSource,
      if (pdCollectedAt != null) 'pdCollectedAt': pdCollectedAt?.toJson(),
      'pdRedacted': pdRedacted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmContactViewImpl extends CrmContactView {
  _CrmContactViewImpl({
    required int id,
    required int segmentId,
    int? companyId,
    int? dealId,
    required int version,
    String? fullName,
    String? position,
    String? phone,
    String? email,
    String? messenger,
    int? messengerUserId,
    String? notes,
    _i2.CrmPdBasis? pdBasis,
    String? pdSource,
    DateTime? pdCollectedAt,
    required bool pdRedacted,
  }) : super._(
         id: id,
         segmentId: segmentId,
         companyId: companyId,
         dealId: dealId,
         version: version,
         fullName: fullName,
         position: position,
         phone: phone,
         email: email,
         messenger: messenger,
         messengerUserId: messengerUserId,
         notes: notes,
         pdBasis: pdBasis,
         pdSource: pdSource,
         pdCollectedAt: pdCollectedAt,
         pdRedacted: pdRedacted,
       );

  /// Returns a shallow copy of this [CrmContactView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmContactView copyWith({
    int? id,
    int? segmentId,
    Object? companyId = _Undefined,
    Object? dealId = _Undefined,
    int? version,
    Object? fullName = _Undefined,
    Object? position = _Undefined,
    Object? phone = _Undefined,
    Object? email = _Undefined,
    Object? messenger = _Undefined,
    Object? messengerUserId = _Undefined,
    Object? notes = _Undefined,
    Object? pdBasis = _Undefined,
    Object? pdSource = _Undefined,
    Object? pdCollectedAt = _Undefined,
    bool? pdRedacted,
  }) {
    return CrmContactView(
      id: id ?? this.id,
      segmentId: segmentId ?? this.segmentId,
      companyId: companyId is int? ? companyId : this.companyId,
      dealId: dealId is int? ? dealId : this.dealId,
      version: version ?? this.version,
      fullName: fullName is String? ? fullName : this.fullName,
      position: position is String? ? position : this.position,
      phone: phone is String? ? phone : this.phone,
      email: email is String? ? email : this.email,
      messenger: messenger is String? ? messenger : this.messenger,
      messengerUserId: messengerUserId is int?
          ? messengerUserId
          : this.messengerUserId,
      notes: notes is String? ? notes : this.notes,
      pdBasis: pdBasis is _i2.CrmPdBasis? ? pdBasis : this.pdBasis,
      pdSource: pdSource is String? ? pdSource : this.pdSource,
      pdCollectedAt: pdCollectedAt is DateTime?
          ? pdCollectedAt
          : this.pdCollectedAt,
      pdRedacted: pdRedacted ?? this.pdRedacted,
    );
  }
}
