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
enum CrmActivityType implements _i1.SerializableModel {
  meeting,
  call,
  message,
  email,
  note,
  stage_change,
  next_step_change,
  document,
  system;

  static CrmActivityType fromJson(String name) {
    switch (name) {
      case 'meeting':
        return CrmActivityType.meeting;
      case 'call':
        return CrmActivityType.call;
      case 'message':
        return CrmActivityType.message;
      case 'email':
        return CrmActivityType.email;
      case 'note':
        return CrmActivityType.note;
      case 'stage_change':
        return CrmActivityType.stage_change;
      case 'next_step_change':
        return CrmActivityType.next_step_change;
      case 'document':
        return CrmActivityType.document;
      case 'system':
        return CrmActivityType.system;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "CrmActivityType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
