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

/// **TASK55 итер.2b**: кэш-запись подписчиков presence одного target-а
/// (`presence:watchers:<targetUserId>`, TTL ~5 мин — SDK переподтверждает
/// подписку, закрытый чат отваливается сам). lastKnownOnline — для
/// эмиссии ТОЛЬКО на переходах (дебаунс по построению).
abstract class PresenceWatchers implements _i1.SerializableModel {
  PresenceWatchers._({
    required this.watcherIds,
    required this.lastKnownOnline,
  });

  factory PresenceWatchers({
    required List<int> watcherIds,
    required bool lastKnownOnline,
  }) = _PresenceWatchersImpl;

  factory PresenceWatchers.fromJson(Map<String, dynamic> jsonSerialization) {
    return PresenceWatchers(
      watcherIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['watcherIds'],
      ),
      lastKnownOnline: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['lastKnownOnline'],
      ),
    );
  }

  List<int> watcherIds;

  bool lastKnownOnline;

  /// Returns a shallow copy of this [PresenceWatchers]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PresenceWatchers copyWith({
    List<int>? watcherIds,
    bool? lastKnownOnline,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PresenceWatchers',
      'watcherIds': watcherIds.toJson(),
      'lastKnownOnline': lastKnownOnline,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PresenceWatchersImpl extends PresenceWatchers {
  _PresenceWatchersImpl({
    required List<int> watcherIds,
    required bool lastKnownOnline,
  }) : super._(
         watcherIds: watcherIds,
         lastKnownOnline: lastKnownOnline,
       );

  /// Returns a shallow copy of this [PresenceWatchers]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PresenceWatchers copyWith({
    List<int>? watcherIds,
    bool? lastKnownOnline,
  }) {
    return PresenceWatchers(
      watcherIds: watcherIds ?? this.watcherIds.map((e0) => e0).toList(),
      lastKnownOnline: lastKnownOnline ?? this.lastKnownOnline,
    );
  }
}
