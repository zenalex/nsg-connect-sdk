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

/// **issue #162, пункт 4**: в комнате не хватает мест.
///
/// Возникает при создании группы или приглашении, когда участников стало
/// бы больше разрешённого. Причина не в правах и не в доступе: комната
/// существует и вызывающий в ней свой — просто она полна.
///
/// **Это НЕ анти-перебор**, поэтому числа возвращаем честно: вызывающий
/// уже участник комнаты и её размер и так видит. Зная предел и текущее
/// число, клиент может сказать человеку «осталось три места», а не
/// «что-то пошло не так».
///
/// Комнаты, набравшие больше предела ДО его введения, продолжают
/// работать — проверка стоит на добавлении, а не на существовании.
abstract class RoomCapacityExceededException
    implements _i1.SerializableException, _i1.SerializableModel {
  RoomCapacityExceededException._({
    required this.limit,
    required this.current,
    required this.requested,
  });

  factory RoomCapacityExceededException({
    required int limit,
    required int current,
    required int requested,
  }) = _RoomCapacityExceededExceptionImpl;

  factory RoomCapacityExceededException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RoomCapacityExceededException(
      limit: jsonSerialization['limit'] as int,
      current: jsonSerialization['current'] as int,
      requested: jsonSerialization['requested'] as int,
    );
  }

  /// Предел (`ROOM_MAX_PARTICIPANTS`, по умолчанию 150).
  int limit;

  /// Сколько участников сейчас.
  int current;

  /// Сколько пытались добавить.
  int requested;

  /// Returns a shallow copy of this [RoomCapacityExceededException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomCapacityExceededException copyWith({
    int? limit,
    int? current,
    int? requested,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomCapacityExceededException',
      'limit': limit,
      'current': current,
      'requested': requested,
    };
  }

  @override
  String toString() {
    return 'RoomCapacityExceededException(limit: $limit, current: $current, requested: $requested)';
  }
}

class _RoomCapacityExceededExceptionImpl extends RoomCapacityExceededException {
  _RoomCapacityExceededExceptionImpl({
    required int limit,
    required int current,
    required int requested,
  }) : super._(
         limit: limit,
         current: current,
         requested: requested,
       );

  /// Returns a shallow copy of this [RoomCapacityExceededException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomCapacityExceededException copyWith({
    int? limit,
    int? current,
    int? requested,
  }) {
    return RoomCapacityExceededException(
      limit: limit ?? this.limit,
      current: current ?? this.current,
      requested: requested ?? this.requested,
    );
  }
}
