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

/// **TASK77 итер.3**: карточка бота — одна запись каталога «Добавить бота»
/// и она же содержимое карточки бота (тап по боту в списке участников /
/// в шапке 1:1 / по имени автора сообщения).
///
/// Один DTO на оба сценария намеренно: каталог и карточка показывают одно и
/// то же — кто это, чей он, что умеет и **сколько он читает**. Разделив их,
/// мы получили бы два места, где режим чтения можно забыть показать, а это
/// главный trust-сигнал перед подключением чужой программы в свою группу.
///
/// Внутри — только то, что можно показывать любому пользователю тенанта:
/// ни `accessToken`, ни webhook-URL, ни секретов.
abstract class AvailableBot implements _i1.SerializableModel {
  AvailableBot._({
    required this.botId,
    required this.messengerUserId,
    required this.name,
    this.avatarUrl,
    this.description,
    required this.ownerEmail,
    this.ownerDisplayName,
    required this.commands,
    required this.readMode,
    required this.discoverable,
    required this.inRoom,
  });

  factory AvailableBot({
    required int botId,
    required int messengerUserId,
    required String name,
    String? avatarUrl,
    String? description,
    required String ownerEmail,
    String? ownerDisplayName,
    required List<_i2.BotCommand> commands,
    required String readMode,
    required bool discoverable,
    required bool inRoom,
  }) = _AvailableBotImpl;

  factory AvailableBot.fromJson(Map<String, dynamic> jsonSerialization) {
    return AvailableBot(
      botId: jsonSerialization['botId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      name: jsonSerialization['name'] as String,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      description: jsonSerialization['description'] as String?,
      ownerEmail: jsonSerialization['ownerEmail'] as String,
      ownerDisplayName: jsonSerialization['ownerDisplayName'] as String?,
      commands: _i3.Protocol().deserialize<List<_i2.BotCommand>>(
        jsonSerialization['commands'],
      ),
      readMode: jsonSerialization['readMode'] as String,
      discoverable: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['discoverable'],
      ),
      inRoom: _i1.BoolJsonExtension.fromJson(jsonSerialization['inRoom']),
    );
  }

  /// Внутренний `Bot.id` — им оперируют `addBotToMyRoom` /
  /// `removeBotFromMyRoom`.
  int botId;

  /// `Bot.messengerUserId` — по нему клиент сопоставляет карточку с
  /// участником комнаты (`RoomParticipant.messengerUserId`) и с автором
  /// сообщения.
  int messengerUserId;

  String name;

  /// Аватар бот-пользователя (`MessengerUser.avatarUrl`).
  String? avatarUrl;

  /// Свободное описание «что этот бот делает» (`Bot.description`), которое
  /// задаёт владелец или сам бот своим токеном.
  String? description;

  /// Email владельца — он же fallback-подпись, если отображаемого имени
  /// найти не удалось (владелец мог заводить бота из другого тенанта
  /// email-аккаунтов или через админку).
  String ownerEmail;

  /// Отображаемое имя владельца (`EmailAccount.displayName`/`username`).
  /// `null` — не разрезолвилось, показываем [ownerEmail].
  String? ownerDisplayName;

  /// Объявленные ботом slash-команды (TASK77 итер.1) в его собственном
  /// порядке. Пусто — бот команд не объявил.
  List<_i2.BotCommand> commands;

  /// **Действующий** режим чтения (`read_all` / `read_addressed`), уже
  /// разрешённый через `BotService.effectiveReadMode`: клиент НЕ должен
  /// повторять правило grandfathering-а (`NULL` = `read_all`) — иначе
  /// старый бот выглядел бы в каталоге приватнее, чем он есть.
  String readMode;

  /// Публичность в каталоге. В карточке бота, открытой из комнаты, может
  /// быть `false` (бот уже в комнате, но в каталоге его нет).
  bool discoverable;

  /// Бот уже состоит в комнате, для которой запрашивался каталог/карточка.
  /// Без контекста комнаты — всегда `false`.
  bool inRoom;

  /// Returns a shallow copy of this [AvailableBot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AvailableBot copyWith({
    int? botId,
    int? messengerUserId,
    String? name,
    String? avatarUrl,
    String? description,
    String? ownerEmail,
    String? ownerDisplayName,
    List<_i2.BotCommand>? commands,
    String? readMode,
    bool? discoverable,
    bool? inRoom,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AvailableBot',
      'botId': botId,
      'messengerUserId': messengerUserId,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (description != null) 'description': description,
      'ownerEmail': ownerEmail,
      if (ownerDisplayName != null) 'ownerDisplayName': ownerDisplayName,
      'commands': commands.toJson(valueToJson: (v) => v.toJson()),
      'readMode': readMode,
      'discoverable': discoverable,
      'inRoom': inRoom,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AvailableBotImpl extends AvailableBot {
  _AvailableBotImpl({
    required int botId,
    required int messengerUserId,
    required String name,
    String? avatarUrl,
    String? description,
    required String ownerEmail,
    String? ownerDisplayName,
    required List<_i2.BotCommand> commands,
    required String readMode,
    required bool discoverable,
    required bool inRoom,
  }) : super._(
         botId: botId,
         messengerUserId: messengerUserId,
         name: name,
         avatarUrl: avatarUrl,
         description: description,
         ownerEmail: ownerEmail,
         ownerDisplayName: ownerDisplayName,
         commands: commands,
         readMode: readMode,
         discoverable: discoverable,
         inRoom: inRoom,
       );

  /// Returns a shallow copy of this [AvailableBot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AvailableBot copyWith({
    int? botId,
    int? messengerUserId,
    String? name,
    Object? avatarUrl = _Undefined,
    Object? description = _Undefined,
    String? ownerEmail,
    Object? ownerDisplayName = _Undefined,
    List<_i2.BotCommand>? commands,
    String? readMode,
    bool? discoverable,
    bool? inRoom,
  }) {
    return AvailableBot(
      botId: botId ?? this.botId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      name: name ?? this.name,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      description: description is String? ? description : this.description,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerDisplayName: ownerDisplayName is String?
          ? ownerDisplayName
          : this.ownerDisplayName,
      commands: commands ?? this.commands.map((e0) => e0.copyWith()).toList(),
      readMode: readMode ?? this.readMode,
      discoverable: discoverable ?? this.discoverable,
      inRoom: inRoom ?? this.inRoom,
    );
  }
}
