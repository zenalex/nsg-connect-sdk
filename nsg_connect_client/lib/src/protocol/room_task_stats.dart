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

/// **TASK88**: сводка по задачам комнаты для иконки в шапке чата. Задачи
/// комнаты = `TaskLink` по `roomId`; `active` = не в конечной стадии
/// (`stage` ∉ {accepted, rejected}, через `TicketService.effectiveStage`).
/// Транзиентный DTO (без таблицы) — считается на лету при открытии чата.
///   * `total` — всего задач комнаты (0 → иконки в шапке нет);
///   * `active` — из них активных (>0 → бейдж с числом на иконке).
abstract class RoomTaskStats implements _i1.SerializableModel {
  RoomTaskStats._({
    required this.active,
    required this.total,
  });

  factory RoomTaskStats({
    required int active,
    required int total,
  }) = _RoomTaskStatsImpl;

  factory RoomTaskStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomTaskStats(
      active: jsonSerialization['active'] as int,
      total: jsonSerialization['total'] as int,
    );
  }

  int active;

  int total;

  /// Returns a shallow copy of this [RoomTaskStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomTaskStats copyWith({
    int? active,
    int? total,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomTaskStats',
      'active': active,
      'total': total,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RoomTaskStatsImpl extends RoomTaskStats {
  _RoomTaskStatsImpl({
    required int active,
    required int total,
  }) : super._(
         active: active,
         total: total,
       );

  /// Returns a shallow copy of this [RoomTaskStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomTaskStats copyWith({
    int? active,
    int? total,
  }) {
    return RoomTaskStats(
      active: active ?? this.active,
      total: total ?? this.total,
    );
  }
}
