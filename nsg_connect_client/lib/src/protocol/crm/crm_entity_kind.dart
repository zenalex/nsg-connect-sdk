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

/// TASK95 CRM wire names are stable.
enum CrmEntityKind implements _i1.SerializableModel {
  space,
  segment,
  company,
  contact,
  pipeline,
  stage,
  deal,
  activity,
  document,
  message,
  segment_member,
  space_admin;

  static CrmEntityKind fromJson(String name) {
    switch (name) {
      case 'space':
        return CrmEntityKind.space;
      case 'segment':
        return CrmEntityKind.segment;
      case 'company':
        return CrmEntityKind.company;
      case 'contact':
        return CrmEntityKind.contact;
      case 'pipeline':
        return CrmEntityKind.pipeline;
      case 'stage':
        return CrmEntityKind.stage;
      case 'deal':
        return CrmEntityKind.deal;
      case 'activity':
        return CrmEntityKind.activity;
      case 'document':
        return CrmEntityKind.document;
      case 'message':
        return CrmEntityKind.message;
      case 'segment_member':
        return CrmEntityKind.segment_member;
      case 'space_admin':
        return CrmEntityKind.space_admin;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "CrmEntityKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
