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

/// **TASK55 итер.2**: кэш-запись «пользователь в сети» (живой heartbeat
/// чата). ОТДЕЛЬНЫЙ ключ `presence:conn:<userId>` — НЕ путать с
/// `presence:<userId>` (foreground для push-роутинга): «в сети» ⊃
/// «на экране», смешение ключей глушило бы пуши (§4 TASK55).
abstract class PresenceConnState implements _i1.SerializableModel {
  PresenceConnState._({required this.lastHeartbeatAt});

  factory PresenceConnState({required DateTime lastHeartbeatAt}) =
      _PresenceConnStateImpl;

  factory PresenceConnState.fromJson(Map<String, dynamic> jsonSerialization) {
    return PresenceConnState(
      lastHeartbeatAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastHeartbeatAt'],
      ),
    );
  }

  DateTime lastHeartbeatAt;

  /// Returns a shallow copy of this [PresenceConnState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PresenceConnState copyWith({DateTime? lastHeartbeatAt});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PresenceConnState',
      'lastHeartbeatAt': lastHeartbeatAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PresenceConnStateImpl extends PresenceConnState {
  _PresenceConnStateImpl({required DateTime lastHeartbeatAt})
    : super._(lastHeartbeatAt: lastHeartbeatAt);

  /// Returns a shallow copy of this [PresenceConnState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PresenceConnState copyWith({DateTime? lastHeartbeatAt}) {
    return PresenceConnState(
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
    );
  }
}
