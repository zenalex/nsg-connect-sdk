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

/// PulseIncident — инцидент монитора (TASK60). Открывается при переходе в
/// ≥warn, закрывается возвратом в ok. Нужен для эскалации: свипер шлёт
/// уровень 1/2 в личку, пока инцидент не принят (`ackedAt`) и не разрешён.
/// Один открытый инцидент на монитор; повторные переходы апгрейдят severity.
/// Ретенция: храним всё (решение §10.4 дизайна).
abstract class PulseIncident implements _i1.SerializableModel {
  PulseIncident._({
    this.id,
    required this.monitorId,
    required this.openedAt,
    required this.severity,
    this.ackedBy,
    this.ackedAt,
    int? escalationLevel,
    this.lastEscalatedAt,
    this.resolvedAt,
  }) : escalationLevel = escalationLevel ?? 0;

  factory PulseIncident({
    int? id,
    required int monitorId,
    required DateTime openedAt,
    required String severity,
    int? ackedBy,
    DateTime? ackedAt,
    int? escalationLevel,
    DateTime? lastEscalatedAt,
    DateTime? resolvedAt,
  }) = _PulseIncidentImpl;

  factory PulseIncident.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseIncident(
      id: jsonSerialization['id'] as int?,
      monitorId: jsonSerialization['monitorId'] as int,
      openedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['openedAt'],
      ),
      severity: jsonSerialization['severity'] as String,
      ackedBy: jsonSerialization['ackedBy'] as int?,
      ackedAt: jsonSerialization['ackedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['ackedAt']),
      escalationLevel: jsonSerialization['escalationLevel'] as int?,
      lastEscalatedAt: jsonSerialization['lastEscalatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEscalatedAt'],
            ),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int monitorId;

  DateTime openedAt;

  /// Максимальная severity за время инцидента: warn | error | down.
  String severity;

  /// «Взять в работу»: MUID и время. Останавливает эскалацию.
  int? ackedBy;

  DateTime? ackedAt;

  /// 0 = карточка в комнату; 1 = личка level1; 2 = личка level2.
  int escalationLevel;

  DateTime? lastEscalatedAt;

  DateTime? resolvedAt;

  /// Returns a shallow copy of this [PulseIncident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseIncident copyWith({
    int? id,
    int? monitorId,
    DateTime? openedAt,
    String? severity,
    int? ackedBy,
    DateTime? ackedAt,
    int? escalationLevel,
    DateTime? lastEscalatedAt,
    DateTime? resolvedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseIncident',
      if (id != null) 'id': id,
      'monitorId': monitorId,
      'openedAt': openedAt.toJson(),
      'severity': severity,
      if (ackedBy != null) 'ackedBy': ackedBy,
      if (ackedAt != null) 'ackedAt': ackedAt?.toJson(),
      'escalationLevel': escalationLevel,
      if (lastEscalatedAt != null) 'lastEscalatedAt': lastEscalatedAt?.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseIncidentImpl extends PulseIncident {
  _PulseIncidentImpl({
    int? id,
    required int monitorId,
    required DateTime openedAt,
    required String severity,
    int? ackedBy,
    DateTime? ackedAt,
    int? escalationLevel,
    DateTime? lastEscalatedAt,
    DateTime? resolvedAt,
  }) : super._(
         id: id,
         monitorId: monitorId,
         openedAt: openedAt,
         severity: severity,
         ackedBy: ackedBy,
         ackedAt: ackedAt,
         escalationLevel: escalationLevel,
         lastEscalatedAt: lastEscalatedAt,
         resolvedAt: resolvedAt,
       );

  /// Returns a shallow copy of this [PulseIncident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseIncident copyWith({
    Object? id = _Undefined,
    int? monitorId,
    DateTime? openedAt,
    String? severity,
    Object? ackedBy = _Undefined,
    Object? ackedAt = _Undefined,
    int? escalationLevel,
    Object? lastEscalatedAt = _Undefined,
    Object? resolvedAt = _Undefined,
  }) {
    return PulseIncident(
      id: id is int? ? id : this.id,
      monitorId: monitorId ?? this.monitorId,
      openedAt: openedAt ?? this.openedAt,
      severity: severity ?? this.severity,
      ackedBy: ackedBy is int? ? ackedBy : this.ackedBy,
      ackedAt: ackedAt is DateTime? ? ackedAt : this.ackedAt,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      lastEscalatedAt: lastEscalatedAt is DateTime?
          ? lastEscalatedAt
          : this.lastEscalatedAt,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
    );
  }
}
