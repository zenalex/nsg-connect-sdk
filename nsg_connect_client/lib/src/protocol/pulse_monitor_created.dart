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
import 'pulse_monitor.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// DTO create/rotate монитора Pulse (TASK60): монитор + beat-токен.
/// Токен показывается ОДИН раз (в БД — только хеш); `beatUrl` — готовый
/// URL для curl-сниппета (`<hooks-base>/beat/<token>`).
abstract class PulseMonitorCreated implements _i1.SerializableModel {
  PulseMonitorCreated._({
    required this.monitor,
    required this.token,
    required this.beatUrl,
  });

  factory PulseMonitorCreated({
    required _i2.PulseMonitor monitor,
    required String token,
    required String beatUrl,
  }) = _PulseMonitorCreatedImpl;

  factory PulseMonitorCreated.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseMonitorCreated(
      monitor: _i3.Protocol().deserialize<_i2.PulseMonitor>(
        jsonSerialization['monitor'],
      ),
      token: jsonSerialization['token'] as String,
      beatUrl: jsonSerialization['beatUrl'] as String,
    );
  }

  _i2.PulseMonitor monitor;

  String token;

  String beatUrl;

  /// Returns a shallow copy of this [PulseMonitorCreated]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseMonitorCreated copyWith({
    _i2.PulseMonitor? monitor,
    String? token,
    String? beatUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseMonitorCreated',
      'monitor': monitor.toJson(),
      'token': token,
      'beatUrl': beatUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PulseMonitorCreatedImpl extends PulseMonitorCreated {
  _PulseMonitorCreatedImpl({
    required _i2.PulseMonitor monitor,
    required String token,
    required String beatUrl,
  }) : super._(
         monitor: monitor,
         token: token,
         beatUrl: beatUrl,
       );

  /// Returns a shallow copy of this [PulseMonitorCreated]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseMonitorCreated copyWith({
    _i2.PulseMonitor? monitor,
    String? token,
    String? beatUrl,
  }) {
    return PulseMonitorCreated(
      monitor: monitor ?? this.monitor.copyWith(),
      token: token ?? this.token,
      beatUrl: beatUrl ?? this.beatUrl,
    );
  }
}
