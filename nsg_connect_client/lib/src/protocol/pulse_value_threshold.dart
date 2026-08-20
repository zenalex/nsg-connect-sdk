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

/// **issue #116**: порог по ЗНАЧЕНИЮ для монитора-heartbeat.
///
/// Число само по себе бесполезно: любой IoT-хаб и любой скрипт умеют
/// посчитать свободное место или температуру, но не умеют решать, когда это
/// становится бедой. Решение — наше, и в этом вся ценность шага.
///
/// Обе стороны (below/above) нужны, потому что беда бывает разной: у
/// свободного места плохо СНИЗУ, у возраста бэкапа и длины очереди — СВЕРХУ,
/// у температуры в серверной — с обеих. Одна универсальная «граница»
/// заставила бы отправителя инвертировать число, и смысл имени разошёлся бы
/// со смыслом порога.
abstract class PulseValueThreshold implements _i1.SerializableModel {
  PulseValueThreshold._({
    this.id,
    required this.monitorId,
    required this.name,
    this.warnBelow,
    this.errorBelow,
    this.warnAbove,
    this.errorAbove,
    required this.createdAt,
  });

  factory PulseValueThreshold({
    int? id,
    required int monitorId,
    required String name,
    double? warnBelow,
    double? errorBelow,
    double? warnAbove,
    double? errorAbove,
    required DateTime createdAt,
  }) = _PulseValueThresholdImpl;

  factory PulseValueThreshold.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseValueThreshold(
      id: jsonSerialization['id'] as int?,
      monitorId: jsonSerialization['monitorId'] as int,
      name: jsonSerialization['name'] as String,
      warnBelow: (jsonSerialization['warnBelow'] as num?)?.toDouble(),
      errorBelow: (jsonSerialization['errorBelow'] as num?)?.toDouble(),
      warnAbove: (jsonSerialization['warnAbove'] as num?)?.toDouble(),
      errorAbove: (jsonSerialization['errorAbove'] as num?)?.toDouble(),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int monitorId;

  /// Имя значения из beat (`disk_free_gb`). Единица живёт в имени.
  String name;

  double? warnBelow;

  double? errorBelow;

  double? warnAbove;

  double? errorAbove;

  DateTime createdAt;

  /// Returns a shallow copy of this [PulseValueThreshold]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseValueThreshold copyWith({
    int? id,
    int? monitorId,
    String? name,
    double? warnBelow,
    double? errorBelow,
    double? warnAbove,
    double? errorAbove,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseValueThreshold',
      if (id != null) 'id': id,
      'monitorId': monitorId,
      'name': name,
      if (warnBelow != null) 'warnBelow': warnBelow,
      if (errorBelow != null) 'errorBelow': errorBelow,
      if (warnAbove != null) 'warnAbove': warnAbove,
      if (errorAbove != null) 'errorAbove': errorAbove,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseValueThresholdImpl extends PulseValueThreshold {
  _PulseValueThresholdImpl({
    int? id,
    required int monitorId,
    required String name,
    double? warnBelow,
    double? errorBelow,
    double? warnAbove,
    double? errorAbove,
    required DateTime createdAt,
  }) : super._(
         id: id,
         monitorId: monitorId,
         name: name,
         warnBelow: warnBelow,
         errorBelow: errorBelow,
         warnAbove: warnAbove,
         errorAbove: errorAbove,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PulseValueThreshold]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseValueThreshold copyWith({
    Object? id = _Undefined,
    int? monitorId,
    String? name,
    Object? warnBelow = _Undefined,
    Object? errorBelow = _Undefined,
    Object? warnAbove = _Undefined,
    Object? errorAbove = _Undefined,
    DateTime? createdAt,
  }) {
    return PulseValueThreshold(
      id: id is int? ? id : this.id,
      monitorId: monitorId ?? this.monitorId,
      name: name ?? this.name,
      warnBelow: warnBelow is double? ? warnBelow : this.warnBelow,
      errorBelow: errorBelow is double? ? errorBelow : this.errorBelow,
      warnAbove: warnAbove is double? ? warnAbove : this.warnAbove,
      errorAbove: errorAbove is double? ? errorAbove : this.errorAbove,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
