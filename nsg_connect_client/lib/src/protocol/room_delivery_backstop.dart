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

/// **issue #164**: страховка выпуска для ВСЕЙ комнаты сразу.
///
/// Раньше страховок было по одной на получателя каждого сообщения:
/// комната на 150 человек давала 150 строк в `serverpod_future_call`.
/// Замер 22.08.2026: планирование стоило 15,3 мс на участника — почти
/// весь остаток цены веера (17 мс) после того, как резолв стал
/// пачечным (#163).
///
/// **Пер-адресатность страховке не нужна по существу.** Основной путь
/// выпуска — таймер в процессе, он срабатывает ровно в срок для каждого
/// отдельно. Задание же существует на случай, когда процесс умер вместе
/// со всеми таймерами; его работа — «после рестарта пройтись и добить
/// забытое», и для этого достаточно знать комнату и событие.
///
/// Текстов уведомлений здесь нет и быть не должно: нагрузки лежат в
/// кэше, а в таблице заданий им не место — ни по объёму, ни по
/// приватности.
abstract class RoomDeliveryBackstop implements _i1.SerializableModel {
  RoomDeliveryBackstop._({
    required this.roomId,
    required this.matrixEventId,
  });

  factory RoomDeliveryBackstop({
    required int roomId,
    required String matrixEventId,
  }) = _RoomDeliveryBackstopImpl;

  factory RoomDeliveryBackstop.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RoomDeliveryBackstop(
      roomId: jsonSerialization['roomId'] as int,
      matrixEventId: jsonSerialization['matrixEventId'] as String,
    );
  }

  int roomId;

  String matrixEventId;

  /// Returns a shallow copy of this [RoomDeliveryBackstop]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomDeliveryBackstop copyWith({
    int? roomId,
    String? matrixEventId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomDeliveryBackstop',
      'roomId': roomId,
      'matrixEventId': matrixEventId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RoomDeliveryBackstopImpl extends RoomDeliveryBackstop {
  _RoomDeliveryBackstopImpl({
    required int roomId,
    required String matrixEventId,
  }) : super._(
         roomId: roomId,
         matrixEventId: matrixEventId,
       );

  /// Returns a shallow copy of this [RoomDeliveryBackstop]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomDeliveryBackstop copyWith({
    int? roomId,
    String? matrixEventId,
  }) {
    return RoomDeliveryBackstop(
      roomId: roomId ?? this.roomId,
      matrixEventId: matrixEventId ?? this.matrixEventId,
    );
  }
}
