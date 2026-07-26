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
import 'bot_command.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **TASK77 итер.1**: команды ОДНОГО бота в контексте комнаты — элемент
/// ответа `messenger.listRoomBotCommands(roomId)`. Клиент зовёт этот RPC
/// один раз при открытии чата и складывает всё в typeahead по «/».
///
/// Ботов без объявленных команд сервер в ответ НЕ кладёт — пустых секций
/// в подсказке быть не должно (см. DoD итер.1: «нет команд → нет
/// оверлея»).
abstract class RoomBotCommands implements _i1.SerializableModel {
  RoomBotCommands._({
    required this.botMessengerUserId,
    required this.botName,
    required this.commands,
  });

  factory RoomBotCommands({
    required int botMessengerUserId,
    required String botName,
    required List<_i2.BotCommand> commands,
  }) = _RoomBotCommandsImpl;

  factory RoomBotCommands.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomBotCommands(
      botMessengerUserId: jsonSerialization['botMessengerUserId'] as int,
      botName: jsonSerialization['botName'] as String,
      commands: _i3.Protocol().deserialize<List<_i2.BotCommand>>(
        jsonSerialization['commands'],
      ),
    );
  }

  /// MUID бота (`Bot.messengerUserId`), а не `Bot.id`: клиент знает
  /// участников комнаты именно по messengerUserId (`RoomParticipant`),
  /// и внутренний id бота ему знать незачем.
  int botMessengerUserId;

  /// Отображаемое имя бота — во второй строке пункта подсказки, чтобы в
  /// комнате с несколькими ботами было видно, чью команду выбираешь.
  String botName;

  /// Объявленные ботом команды в порядке, заданном самим ботом (порядок
  /// — часть его UX: сначала главное).
  List<_i2.BotCommand> commands;

  /// Returns a shallow copy of this [RoomBotCommands]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomBotCommands copyWith({
    int? botMessengerUserId,
    String? botName,
    List<_i2.BotCommand>? commands,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomBotCommands',
      'botMessengerUserId': botMessengerUserId,
      'botName': botName,
      'commands': commands.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RoomBotCommandsImpl extends RoomBotCommands {
  _RoomBotCommandsImpl({
    required int botMessengerUserId,
    required String botName,
    required List<_i2.BotCommand> commands,
  }) : super._(
         botMessengerUserId: botMessengerUserId,
         botName: botName,
         commands: commands,
       );

  /// Returns a shallow copy of this [RoomBotCommands]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomBotCommands copyWith({
    int? botMessengerUserId,
    String? botName,
    List<_i2.BotCommand>? commands,
  }) {
    return RoomBotCommands(
      botMessengerUserId: botMessengerUserId ?? this.botMessengerUserId,
      botName: botName ?? this.botName,
      commands: commands ?? this.commands.map((e0) => e0.copyWith()).toList(),
    );
  }
}
