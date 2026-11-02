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

/// Human UI identity only; no contact PD, login, membership or roles.
abstract class CrmUserView implements _i1.SerializableModel {
  CrmUserView._({
    required this.id,
    this.displayName,
  });

  factory CrmUserView({
    required int id,
    String? displayName,
  }) = _CrmUserViewImpl;

  factory CrmUserView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmUserView(
      id: jsonSerialization['id'] as int,
      displayName: jsonSerialization['displayName'] as String?,
    );
  }

  int id;

  String? displayName;

  /// Returns a shallow copy of this [CrmUserView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmUserView copyWith({
    int? id,
    String? displayName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmUserView',
      'id': id,
      if (displayName != null) 'displayName': displayName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmUserViewImpl extends CrmUserView {
  _CrmUserViewImpl({
    required int id,
    String? displayName,
  }) : super._(
         id: id,
         displayName: displayName,
       );

  /// Returns a shallow copy of this [CrmUserView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmUserView copyWith({
    int? id,
    Object? displayName = _Undefined,
  }) {
    return CrmUserView(
      id: id ?? this.id,
      displayName: displayName is String? ? displayName : this.displayName,
    );
  }
}
