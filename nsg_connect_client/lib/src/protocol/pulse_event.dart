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

/// PulseEvent — событие realtime-стрима дашборда Pulse (TASK60, решение
/// §10.3 — «сразу стрим»). Выделенный канал `pulse:<tenantId>` и собственный
/// DTO: общий MessengerEvent-контракт мессенджера не трогаем.
/// eventType: monitor.changed | incident.opened | incident.acked |
/// incident.resolved. Дашборд перечитывает узел из `monitor`.
abstract class PulseEvent implements _i1.SerializableModel {
  PulseEvent._({
    required this.eventType,
    this.monitor,
    this.incidentId,
    required this.serverTimestamp,
  });

  factory PulseEvent({
    required String eventType,
    _i2.PulseMonitor? monitor,
    int? incidentId,
    required DateTime serverTimestamp,
  }) = _PulseEventImpl;

  factory PulseEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseEvent(
      eventType: jsonSerialization['eventType'] as String,
      monitor: jsonSerialization['monitor'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.PulseMonitor>(
              jsonSerialization['monitor'],
            ),
      incidentId: jsonSerialization['incidentId'] as int?,
      serverTimestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverTimestamp'],
      ),
    );
  }

  String eventType;

  _i2.PulseMonitor? monitor;

  int? incidentId;

  DateTime serverTimestamp;

  /// Returns a shallow copy of this [PulseEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseEvent copyWith({
    String? eventType,
    _i2.PulseMonitor? monitor,
    int? incidentId,
    DateTime? serverTimestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseEvent',
      'eventType': eventType,
      if (monitor != null) 'monitor': monitor?.toJson(),
      if (incidentId != null) 'incidentId': incidentId,
      'serverTimestamp': serverTimestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseEventImpl extends PulseEvent {
  _PulseEventImpl({
    required String eventType,
    _i2.PulseMonitor? monitor,
    int? incidentId,
    required DateTime serverTimestamp,
  }) : super._(
         eventType: eventType,
         monitor: monitor,
         incidentId: incidentId,
         serverTimestamp: serverTimestamp,
       );

  /// Returns a shallow copy of this [PulseEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseEvent copyWith({
    String? eventType,
    Object? monitor = _Undefined,
    Object? incidentId = _Undefined,
    DateTime? serverTimestamp,
  }) {
    return PulseEvent(
      eventType: eventType ?? this.eventType,
      monitor: monitor is _i2.PulseMonitor?
          ? monitor
          : this.monitor?.copyWith(),
      incidentId: incidentId is int? ? incidentId : this.incidentId,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    );
  }
}
