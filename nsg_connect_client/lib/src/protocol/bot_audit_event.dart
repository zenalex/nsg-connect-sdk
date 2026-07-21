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

/// BotAuditEvent — журнал значимых событий бота (TASK36, риски «Token
/// leak» / «Bot abuse»). Отвечает на вопросы «кто и когда выдал/ротировал
/// credential этого бота» и «кто ломился за capability, которой у него нет».
///
/// Пишется best-effort: сбой записи аудита НЕ должен ронять само действие
/// (см. `BotService.logAudit`). Строки immutable — только INSERT, апдейтов
/// нет; журнал читается через `botAdmin.listAuditEvents`.
///
/// **Секретов не хранит**: `accessToken` (старый или новый) в `details`
/// не попадает — иначе журнал сам стал бы утечкой того, что защищает.
abstract class BotAuditEvent implements _i1.SerializableModel {
  BotAuditEvent._({
    this.id,
    required this.botId,
    required this.action,
    this.actorMessengerUserId,
    this.actorEmail,
    this.details,
    required this.createdAt,
  });

  factory BotAuditEvent({
    int? id,
    required int botId,
    required String action,
    int? actorMessengerUserId,
    String? actorEmail,
    String? details,
    required DateTime createdAt,
  }) = _BotAuditEventImpl;

  factory BotAuditEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return BotAuditEvent(
      id: jsonSerialization['id'] as int?,
      botId: jsonSerialization['botId'] as int,
      action: jsonSerialization['action'] as String,
      actorMessengerUserId: jsonSerialization['actorMessengerUserId'] as int?,
      actorEmail: jsonSerialization['actorEmail'] as String?,
      details: jsonSerialization['details'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на бота. Cascade-delete: журнал уходит вместе с ботом.
  int botId;

  /// Что произошло:
  ///   'created'           — бот заведён (createBot);
  ///   'token_rotated'     — выдан новый accessToken, старые отозваны;
  ///   'enabled'           — включён (setBotEnabled true);
  ///   'disabled'          — выключен, kill-switch (setBotEnabled false);
  ///   'added_to_room'     — добавлен в комнату (addBotToRoom);
  ///   'capability_denied' — действие отклонено гейтом (abuse-сигнал).
  String action;

  /// MUID инициатора. Для admin-действий — админ; для 'capability_denied'
  /// — сам бот. SetNull: удаление юзера не стирает историю действия.
  int? actorMessengerUserId;

  /// Email админа-инициатора на момент действия (snapshot — аккаунт могут
  /// переименовать/удалить, журнал должен остаться читаемым). Для
  /// 'capability_denied' — null (инициатор не человек).
  String? actorEmail;

  /// Свободнотекстовые детали: `capability=send_messages`, `roomId=42`,
  /// `caps=send_messages,manage_room`. Без секретов.
  String? details;

  DateTime createdAt;

  /// Returns a shallow copy of this [BotAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BotAuditEvent copyWith({
    int? id,
    int? botId,
    String? action,
    int? actorMessengerUserId,
    String? actorEmail,
    String? details,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BotAuditEvent',
      if (id != null) 'id': id,
      'botId': botId,
      'action': action,
      if (actorMessengerUserId != null)
        'actorMessengerUserId': actorMessengerUserId,
      if (actorEmail != null) 'actorEmail': actorEmail,
      if (details != null) 'details': details,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BotAuditEventImpl extends BotAuditEvent {
  _BotAuditEventImpl({
    int? id,
    required int botId,
    required String action,
    int? actorMessengerUserId,
    String? actorEmail,
    String? details,
    required DateTime createdAt,
  }) : super._(
         id: id,
         botId: botId,
         action: action,
         actorMessengerUserId: actorMessengerUserId,
         actorEmail: actorEmail,
         details: details,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BotAuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BotAuditEvent copyWith({
    Object? id = _Undefined,
    int? botId,
    String? action,
    Object? actorMessengerUserId = _Undefined,
    Object? actorEmail = _Undefined,
    Object? details = _Undefined,
    DateTime? createdAt,
  }) {
    return BotAuditEvent(
      id: id is int? ? id : this.id,
      botId: botId ?? this.botId,
      action: action ?? this.action,
      actorMessengerUserId: actorMessengerUserId is int?
          ? actorMessengerUserId
          : this.actorMessengerUserId,
      actorEmail: actorEmail is String? ? actorEmail : this.actorEmail,
      details: details is String? ? details : this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
