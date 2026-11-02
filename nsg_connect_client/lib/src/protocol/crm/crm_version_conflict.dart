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
import '../crm/crm_version_conflict_item.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// TASK95 CRM errors. Access denied is identical for absent and forbidden objects.
abstract class CrmVersionConflict
    implements _i1.SerializableException, _i1.SerializableModel {
  CrmVersionConflict._({required this.conflicts});

  factory CrmVersionConflict({
    required List<_i2.CrmVersionConflictItem> conflicts,
  }) = _CrmVersionConflictImpl;

  factory CrmVersionConflict.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmVersionConflict(
      conflicts: _i3.Protocol().deserialize<List<_i2.CrmVersionConflictItem>>(
        jsonSerialization['conflicts'],
      ),
    );
  }

  List<_i2.CrmVersionConflictItem> conflicts;

  /// Returns a shallow copy of this [CrmVersionConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmVersionConflict copyWith({List<_i2.CrmVersionConflictItem>? conflicts});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmVersionConflict',
      'conflicts': conflicts.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return 'CrmVersionConflict(conflicts: $conflicts)';
  }
}

class _CrmVersionConflictImpl extends CrmVersionConflict {
  _CrmVersionConflictImpl({required List<_i2.CrmVersionConflictItem> conflicts})
    : super._(conflicts: conflicts);

  /// Returns a shallow copy of this [CrmVersionConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmVersionConflict copyWith({List<_i2.CrmVersionConflictItem>? conflicts}) {
    return CrmVersionConflict(
      conflicts:
          conflicts ?? this.conflicts.map((e0) => e0.copyWith()).toList(),
    );
  }
}
