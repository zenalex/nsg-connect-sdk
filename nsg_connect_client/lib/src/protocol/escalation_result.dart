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

/// **TASK45 фаза 2**: результат `escalateToSupportTeam(roomId)` —
/// подключения команды поддержки NSG к объектовому чату кнопкой
/// «Обратиться к разработчикам». Transient DTO (не table), собирается в
/// `EscalationService.escalate`.
///
/// Идемпотентно: повторная эскалация той же комнаты добавит лишь тех
/// членов команды, кто ещё не вошёл; [addedMessengerUserIds] содержит
/// только НОВО добавленных (уже состоявших пропускаем). [alreadyPresent]
/// — сколько членов команды уже были в комнате. UI показывает снекбар
/// «Команда NSG подключена» независимо от количества.
abstract class EscalationResult implements _i1.SerializableModel {
  EscalationResult._({
    required this.roomId,
    required this.addedMessengerUserIds,
    required this.alreadyPresent,
    required this.systemMessagePosted,
  });

  factory EscalationResult({
    required int roomId,
    required List<int> addedMessengerUserIds,
    required int alreadyPresent,
    required bool systemMessagePosted,
  }) = _EscalationResultImpl;

  factory EscalationResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return EscalationResult(
      roomId: jsonSerialization['roomId'] as int,
      addedMessengerUserIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['addedMessengerUserIds'],
      ),
      alreadyPresent: jsonSerialization['alreadyPresent'] as int,
      systemMessagePosted: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['systemMessagePosted'],
      ),
    );
  }

  int roomId;

  /// messengerUserId членов команды, ДОБАВЛЕННЫХ этим вызовом (не считая
  /// уже состоявших). Каждому отправлен push с deep link в комнату.
  List<int> addedMessengerUserIds;

  /// Сколько членов команды уже были в комнате до эскалации (idempotency).
  int alreadyPresent;

  /// Был ли отправлен системный маркер «🛠 Подключена команда поддержки
  /// NSG» (true если хотя бы один член добавлен и бот/система смогли
  /// отправить сообщение). false → best-effort провалился (комната всё
  /// равно эскалирована по membership).
  bool systemMessagePosted;

  /// Returns a shallow copy of this [EscalationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EscalationResult copyWith({
    int? roomId,
    List<int>? addedMessengerUserIds,
    int? alreadyPresent,
    bool? systemMessagePosted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EscalationResult',
      'roomId': roomId,
      'addedMessengerUserIds': addedMessengerUserIds.toJson(),
      'alreadyPresent': alreadyPresent,
      'systemMessagePosted': systemMessagePosted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EscalationResultImpl extends EscalationResult {
  _EscalationResultImpl({
    required int roomId,
    required List<int> addedMessengerUserIds,
    required int alreadyPresent,
    required bool systemMessagePosted,
  }) : super._(
         roomId: roomId,
         addedMessengerUserIds: addedMessengerUserIds,
         alreadyPresent: alreadyPresent,
         systemMessagePosted: systemMessagePosted,
       );

  /// Returns a shallow copy of this [EscalationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EscalationResult copyWith({
    int? roomId,
    List<int>? addedMessengerUserIds,
    int? alreadyPresent,
    bool? systemMessagePosted,
  }) {
    return EscalationResult(
      roomId: roomId ?? this.roomId,
      addedMessengerUserIds:
          addedMessengerUserIds ??
          this.addedMessengerUserIds.map((e0) => e0).toList(),
      alreadyPresent: alreadyPresent ?? this.alreadyPresent,
      systemMessagePosted: systemMessagePosted ?? this.systemMessagePosted,
    );
  }
}
