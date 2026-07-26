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

/// **TASK77 итер.1**: одна slash-команда бота — то, что бот объявил о себе
/// сам (аналог Telegram `setMyCommands`), и то, что SDK показывает
/// пользователю в typeahead по вводу «/».
///
/// Не table-класс: команды не живут своей жизнью и никогда не читаются
/// по одной — только целым списком бота (см. `Bot.commandsJson`).
abstract class BotCommand implements _i1.SerializableModel {
  BotCommand._({
    required this.command,
    required this.description,
  });

  factory BotCommand({
    required String command,
    required String description,
  }) = _BotCommandImpl;

  factory BotCommand.fromJson(Map<String, dynamic> jsonSerialization) {
    return BotCommand(
      command: jsonSerialization['command'] as String,
      description: jsonSerialization['description'] as String,
    );
  }

  /// Имя БЕЗ ведущего слэша: `deploy`, `status_all`. Латиница/цифры/`_`,
  /// ≤32 символа — валидируется в `BotService.parseAndValidateCommands`
  /// (мусор на входе не храним, иначе он поедет в UI всем участникам
  /// комнаты).
  String command;

  /// Однострочное описание для подсказки: «показать статус деплоя». ≤256
  /// символов.
  String description;

  /// Returns a shallow copy of this [BotCommand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotCommand copyWith({
    String? command,
    String? description,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotCommand',
      'command': command,
      'description': description,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BotCommandImpl extends BotCommand {
  _BotCommandImpl({
    required String command,
    required String description,
  }) : super._(
         command: command,
         description: description,
       );

  /// Returns a shallow copy of this [BotCommand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotCommand copyWith({
    String? command,
    String? description,
  }) {
    return BotCommand(
      command: command ?? this.command,
      description: description ?? this.description,
    );
  }
}
