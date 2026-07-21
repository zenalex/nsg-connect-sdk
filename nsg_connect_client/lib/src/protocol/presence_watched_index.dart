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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// **TASK55 итер.2b**: реестр target-ов с активными подписчиками —
/// обходится свипером offline-переходов (`presence:watched:index`).
abstract class PresenceWatchedIndex implements _i1.SerializableModel {
  PresenceWatchedIndex._({required this.targetIds});

  factory PresenceWatchedIndex({required List<int> targetIds}) =
      _PresenceWatchedIndexImpl;

  factory PresenceWatchedIndex.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PresenceWatchedIndex(
      targetIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['targetIds'],
      ),
    );
  }

  List<int> targetIds;

  /// Returns a shallow copy of this [PresenceWatchedIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PresenceWatchedIndex copyWith({List<int>? targetIds});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PresenceWatchedIndex',
      'targetIds': targetIds.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PresenceWatchedIndexImpl extends PresenceWatchedIndex {
  _PresenceWatchedIndexImpl({required List<int> targetIds})
    : super._(targetIds: targetIds);

  /// Returns a shallow copy of this [PresenceWatchedIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PresenceWatchedIndex copyWith({List<int>? targetIds}) {
    return PresenceWatchedIndex(
      targetIds: targetIds ?? this.targetIds.map((e0) => e0).toList(),
    );
  }
}
