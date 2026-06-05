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
import 'enums/messenger_event_type.dart' as _i2;
import 'messenger_message.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// Событие в realtime-стриме мессенджера. Tagged union через
/// [MessengerEventType], плюс опциональные payload-поля для каждого
/// варианта.
///
/// Serverpod 3.x не поддерживает `sealed` иерархии в YAML, поэтому
/// используем единый класс с дискриминатором — клиент паттерн-матчит
/// `eventType` и читает соответствующее под-поле (например, `message`
/// для `messageCreated`). См. TASK09 § Streaming endpoints.
abstract class MessengerEvent implements _i1.SerializableModel {
  MessengerEvent._({
    required this.eventType,
    required this.serverTimestamp,
    this.roomId,
    this.matrixRoomId,
    this.message,
    this.membershipMessengerUserId,
    this.membershipMatrixUserId,
    this.oldRole,
    this.newRole,
    this.roomStateField,
    this.roomStateNewValue,
    this.readReceiptEventId,
    this.readReceiptUserId,
    this.readReceiptMatrixUserId,
    this.typingMatrixUserIds,
    this.typingDisplayNames,
    this.unreadCount,
    this.membershipChangedField,
    this.reactionTargetEventId,
    this.reactionKey,
    this.reactionReactorMatrixUserId,
    this.reactionEventId,
    this.reactionRedacted,
  });

  factory MessengerEvent({
    required _i2.MessengerEventType eventType,
    required DateTime serverTimestamp,
    int? roomId,
    String? matrixRoomId,
    _i3.MessengerMessage? message,
    int? membershipMessengerUserId,
    String? membershipMatrixUserId,
    String? oldRole,
    String? newRole,
    String? roomStateField,
    String? roomStateNewValue,
    String? readReceiptEventId,
    int? readReceiptUserId,
    String? readReceiptMatrixUserId,
    List<String>? typingMatrixUserIds,
    List<String>? typingDisplayNames,
    int? unreadCount,
    String? membershipChangedField,
    String? reactionTargetEventId,
    String? reactionKey,
    String? reactionReactorMatrixUserId,
    String? reactionEventId,
    bool? reactionRedacted,
  }) = _MessengerEventImpl;

  factory MessengerEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessengerEvent(
      eventType: _i2.MessengerEventType.fromJson(
        (jsonSerialization['eventType'] as String),
      ),
      serverTimestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverTimestamp'],
      ),
      roomId: jsonSerialization['roomId'] as int?,
      matrixRoomId: jsonSerialization['matrixRoomId'] as String?,
      message: jsonSerialization['message'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.MessengerMessage>(
              jsonSerialization['message'],
            ),
      membershipMessengerUserId:
          jsonSerialization['membershipMessengerUserId'] as int?,
      membershipMatrixUserId:
          jsonSerialization['membershipMatrixUserId'] as String?,
      oldRole: jsonSerialization['oldRole'] as String?,
      newRole: jsonSerialization['newRole'] as String?,
      roomStateField: jsonSerialization['roomStateField'] as String?,
      roomStateNewValue: jsonSerialization['roomStateNewValue'] as String?,
      readReceiptEventId: jsonSerialization['readReceiptEventId'] as String?,
      readReceiptUserId: jsonSerialization['readReceiptUserId'] as int?,
      readReceiptMatrixUserId:
          jsonSerialization['readReceiptMatrixUserId'] as String?,
      typingMatrixUserIds: jsonSerialization['typingMatrixUserIds'] == null
          ? null
          : _i4.Protocol().deserialize<List<String>>(
              jsonSerialization['typingMatrixUserIds'],
            ),
      typingDisplayNames: jsonSerialization['typingDisplayNames'] == null
          ? null
          : _i4.Protocol().deserialize<List<String>>(
              jsonSerialization['typingDisplayNames'],
            ),
      unreadCount: jsonSerialization['unreadCount'] as int?,
      membershipChangedField:
          jsonSerialization['membershipChangedField'] as String?,
      reactionTargetEventId:
          jsonSerialization['reactionTargetEventId'] as String?,
      reactionKey: jsonSerialization['reactionKey'] as String?,
      reactionReactorMatrixUserId:
          jsonSerialization['reactionReactorMatrixUserId'] as String?,
      reactionEventId: jsonSerialization['reactionEventId'] as String?,
      reactionRedacted: jsonSerialization['reactionRedacted'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['reactionRedacted'],
            ),
    );
  }

  _i2.MessengerEventType eventType;

  DateTime serverTimestamp;

  /// Идентификатор затронутой Room (локальный) — для всех событий,
  /// кроме чисто user-scoped (например, profile updates, если появятся).
  int? roomId;

  String? matrixRoomId;

  /// Заполнено для message* событий.
  _i3.MessengerMessage? message;

  /// Заполнено для membership* событий.
  /// `membershipMessengerUserId` — local id; **null** для federation
  /// participants и admin-invited юзеров, не прошедших через нашу
  /// `session()` / identity mapping. Сознательный invariant
  /// (см. TASK17 Chunk 2 Q1): `MessengerUser` появляется только
  /// через `IdentityMappingService.getOrCreate`; `m.room.member`-
  /// event-ы НЕ auto-create-ят локальные строки.
  /// `membershipMatrixUserId` — всегда задан (Matrix `state_key`).
  /// SDK display-сторона использует local id когда есть, иначе
  /// fallback на `@user-id:server` строку.
  int? membershipMessengerUserId;

  String? membershipMatrixUserId;

  /// Для роли — старая/новая (membershipRoleChanged).
  String? oldRole;

  String? newRole;

  /// Для `roomStateChanged` — Matrix state-event-name без префикса
  /// `m.room.` + новое значение поля. На TASK17 dispatcher эмитит
  /// ТОЛЬКО `roomStateField='name'` (см. TASK17 Chunk 2 Q2 — topic/
  /// avatar отложены до TASK22, когда `Room` model получит
  /// соответствующие поля). String, а не enum, чтобы расширение
  /// в TASK22 не было breaking change для client-а.
  String? roomStateField;

  String? roomStateNewValue;

  /// **B11 read receipts** — для `readReceiptUpdated`:
  ///   * `readReceiptEventId` — matrixEventId сообщения, которое
  ///     прочитали;
  ///   * `readReceiptUserId` — local `messengerUserId` читавшего
  ///     (если он есть в нашей БД; null для federation users
  ///     или ещё-не-mapped accounts);
  ///   * `readReceiptMatrixUserId` — всегда задан (Matrix `@user:server`);
  ///     SDK display-сторона уточняет local-id если есть, иначе
  ///     fallback на matrix id для лукапа displayName.
  String? readReceiptEventId;

  int? readReceiptUserId;

  String? readReceiptMatrixUserId;

  /// **B9 typing indicator** — для `typingChanged`. Matrix `m.typing`
  /// EDU присылает FULL CURRENT LIST печатающих в комнате, поэтому
  /// мы передаём её целиком (override, не diff). Пустой список =
  /// никто не печатает (явное стирание indicator-а в UI).
  /// `roomId` обязательно для этих events.
  List<String>? typingMatrixUserIds;

  /// Параллельный список к `typingMatrixUserIds`: resolved displayName
  /// для каждого matrix-id. Server резолвит через `MessengerUser` row
  /// по matrixUserId; если null displayName или user не в нашей БД
  /// (federation) — fallback на matrix localpart (`@bob:srv` → `bob`).
  ///
  /// Используется UI chats-list-а (chatista GlassChatRow), где
  /// RoomDetails.participants не загружены — server-enriched
  /// displayName единственный способ показать красивое имя без
  /// дополнительного RPC.
  List<String>? typingDisplayNames;

  /// Для `roomUnreadChanged` (TASK18) — новое значение counter-а
  /// для recipient-а (юзер на которого канал направлен). Эмитится
  /// в двух случаях:
  ///   * Dispatcher после успешного `_publishEvents` для
  ///     `m.room.message`: per affected participant publish-ится
  ///     один event с `unreadCount = newValue` (после SQL UPDATE
  ///     с race-guard).
  ///   * `MarkReadService.markRead`: после atomic `UPDATE rm SET
  ///     unreadCount=0`, publish-ится один event с
  ///     `unreadCount = 0` (cross-device обновляет другой device-у
  ///     ChatsListScreen badge без новой message).
  ///
  /// `roomId` обязательно задан для этих event-ов; SDK reactor
  /// invalidates list-cache (badge перерендерится при следующем
  /// `list()` вызове) ИЛИ можно patch in-place через invalidate
  /// details — `NsgMessengerRooms` решит.
  int? unreadCount;

  /// TASK42: для `roomMembershipUpdated` событий — какое поле
  /// изменилось. Возможные значения: `'mutedUntil'`, `'archived'`.
  /// SDK reactor по этому полю решает: invalidate list (любое
  /// изменение видно в `RoomSummary.muted/archived`).
  ///
  /// **Privacy boundary**: эти events эмитятся ТОЛЬКО в channel
  /// того user-а, чей RoomMembership row updated (caller =
  /// viewer). Cross-device update (alice device A mutes →
  /// device B sees) — да; cross-user (alice mutes → bob sees) —
  /// **нет**. См. TASK42 plan Q1.
  String? membershipChangedField;

  /// **Emoji reactions** — для `reactionChanged` событий. Реакция в
  /// Matrix = `m.reaction` event с `m.relates_to {rel_type:
  /// m.annotation, event_id: <target>, key: <emoji>}`. Снятие реакции
  /// = `m.room.redaction` того reaction-event-а.
  ///   * `reactionTargetEventId` — matrixEventId сообщения, на которое
  ///     поставлена/снята реакция;
  ///   * `reactionKey` — сам emoji (`👍`, `❤️`, ...). Для redaction —
  ///     может быть null если reaction-event не сохранён локально
  ///     (SDK пересчитает по following sync или relogin);
  ///   * `reactionReactorMatrixUserId` — кто поставил/снял (Matrix id).
  ///     SDK сравнивает с self для own-highlight + toggle;
  ///   * `reactionEventId` — matrixEventId самого `m.reaction` event-а.
  ///     Нужен для redaction (toggle off — SDK помнит свой reaction
  ///     event id чтобы redact-нуть его);
  ///   * `reactionRedacted` — `true` если это снятие реакции
  ///     (redaction reaction-event-а), `false`/null — добавление.
  ///
  /// Все nullable (backward compat — старые клиенты игнорируют).
  String? reactionTargetEventId;

  String? reactionKey;

  String? reactionReactorMatrixUserId;

  String? reactionEventId;

  bool? reactionRedacted;

  /// Returns a shallow copy of this [MessengerEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerEvent copyWith({
    _i2.MessengerEventType? eventType,
    DateTime? serverTimestamp,
    int? roomId,
    String? matrixRoomId,
    _i3.MessengerMessage? message,
    int? membershipMessengerUserId,
    String? membershipMatrixUserId,
    String? oldRole,
    String? newRole,
    String? roomStateField,
    String? roomStateNewValue,
    String? readReceiptEventId,
    int? readReceiptUserId,
    String? readReceiptMatrixUserId,
    List<String>? typingMatrixUserIds,
    List<String>? typingDisplayNames,
    int? unreadCount,
    String? membershipChangedField,
    String? reactionTargetEventId,
    String? reactionKey,
    String? reactionReactorMatrixUserId,
    String? reactionEventId,
    bool? reactionRedacted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerEvent',
      'eventType': eventType.toJson(),
      'serverTimestamp': serverTimestamp.toJson(),
      if (roomId != null) 'roomId': roomId,
      if (matrixRoomId != null) 'matrixRoomId': matrixRoomId,
      if (message != null) 'message': message?.toJson(),
      if (membershipMessengerUserId != null)
        'membershipMessengerUserId': membershipMessengerUserId,
      if (membershipMatrixUserId != null)
        'membershipMatrixUserId': membershipMatrixUserId,
      if (oldRole != null) 'oldRole': oldRole,
      if (newRole != null) 'newRole': newRole,
      if (roomStateField != null) 'roomStateField': roomStateField,
      if (roomStateNewValue != null) 'roomStateNewValue': roomStateNewValue,
      if (readReceiptEventId != null) 'readReceiptEventId': readReceiptEventId,
      if (readReceiptUserId != null) 'readReceiptUserId': readReceiptUserId,
      if (readReceiptMatrixUserId != null)
        'readReceiptMatrixUserId': readReceiptMatrixUserId,
      if (typingMatrixUserIds != null)
        'typingMatrixUserIds': typingMatrixUserIds?.toJson(),
      if (typingDisplayNames != null)
        'typingDisplayNames': typingDisplayNames?.toJson(),
      if (unreadCount != null) 'unreadCount': unreadCount,
      if (membershipChangedField != null)
        'membershipChangedField': membershipChangedField,
      if (reactionTargetEventId != null)
        'reactionTargetEventId': reactionTargetEventId,
      if (reactionKey != null) 'reactionKey': reactionKey,
      if (reactionReactorMatrixUserId != null)
        'reactionReactorMatrixUserId': reactionReactorMatrixUserId,
      if (reactionEventId != null) 'reactionEventId': reactionEventId,
      if (reactionRedacted != null) 'reactionRedacted': reactionRedacted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerEventImpl extends MessengerEvent {
  _MessengerEventImpl({
    required _i2.MessengerEventType eventType,
    required DateTime serverTimestamp,
    int? roomId,
    String? matrixRoomId,
    _i3.MessengerMessage? message,
    int? membershipMessengerUserId,
    String? membershipMatrixUserId,
    String? oldRole,
    String? newRole,
    String? roomStateField,
    String? roomStateNewValue,
    String? readReceiptEventId,
    int? readReceiptUserId,
    String? readReceiptMatrixUserId,
    List<String>? typingMatrixUserIds,
    List<String>? typingDisplayNames,
    int? unreadCount,
    String? membershipChangedField,
    String? reactionTargetEventId,
    String? reactionKey,
    String? reactionReactorMatrixUserId,
    String? reactionEventId,
    bool? reactionRedacted,
  }) : super._(
         eventType: eventType,
         serverTimestamp: serverTimestamp,
         roomId: roomId,
         matrixRoomId: matrixRoomId,
         message: message,
         membershipMessengerUserId: membershipMessengerUserId,
         membershipMatrixUserId: membershipMatrixUserId,
         oldRole: oldRole,
         newRole: newRole,
         roomStateField: roomStateField,
         roomStateNewValue: roomStateNewValue,
         readReceiptEventId: readReceiptEventId,
         readReceiptUserId: readReceiptUserId,
         readReceiptMatrixUserId: readReceiptMatrixUserId,
         typingMatrixUserIds: typingMatrixUserIds,
         typingDisplayNames: typingDisplayNames,
         unreadCount: unreadCount,
         membershipChangedField: membershipChangedField,
         reactionTargetEventId: reactionTargetEventId,
         reactionKey: reactionKey,
         reactionReactorMatrixUserId: reactionReactorMatrixUserId,
         reactionEventId: reactionEventId,
         reactionRedacted: reactionRedacted,
       );

  /// Returns a shallow copy of this [MessengerEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerEvent copyWith({
    _i2.MessengerEventType? eventType,
    DateTime? serverTimestamp,
    Object? roomId = _Undefined,
    Object? matrixRoomId = _Undefined,
    Object? message = _Undefined,
    Object? membershipMessengerUserId = _Undefined,
    Object? membershipMatrixUserId = _Undefined,
    Object? oldRole = _Undefined,
    Object? newRole = _Undefined,
    Object? roomStateField = _Undefined,
    Object? roomStateNewValue = _Undefined,
    Object? readReceiptEventId = _Undefined,
    Object? readReceiptUserId = _Undefined,
    Object? readReceiptMatrixUserId = _Undefined,
    Object? typingMatrixUserIds = _Undefined,
    Object? typingDisplayNames = _Undefined,
    Object? unreadCount = _Undefined,
    Object? membershipChangedField = _Undefined,
    Object? reactionTargetEventId = _Undefined,
    Object? reactionKey = _Undefined,
    Object? reactionReactorMatrixUserId = _Undefined,
    Object? reactionEventId = _Undefined,
    Object? reactionRedacted = _Undefined,
  }) {
    return MessengerEvent(
      eventType: eventType ?? this.eventType,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      roomId: roomId is int? ? roomId : this.roomId,
      matrixRoomId: matrixRoomId is String? ? matrixRoomId : this.matrixRoomId,
      message: message is _i3.MessengerMessage?
          ? message
          : this.message?.copyWith(),
      membershipMessengerUserId: membershipMessengerUserId is int?
          ? membershipMessengerUserId
          : this.membershipMessengerUserId,
      membershipMatrixUserId: membershipMatrixUserId is String?
          ? membershipMatrixUserId
          : this.membershipMatrixUserId,
      oldRole: oldRole is String? ? oldRole : this.oldRole,
      newRole: newRole is String? ? newRole : this.newRole,
      roomStateField: roomStateField is String?
          ? roomStateField
          : this.roomStateField,
      roomStateNewValue: roomStateNewValue is String?
          ? roomStateNewValue
          : this.roomStateNewValue,
      readReceiptEventId: readReceiptEventId is String?
          ? readReceiptEventId
          : this.readReceiptEventId,
      readReceiptUserId: readReceiptUserId is int?
          ? readReceiptUserId
          : this.readReceiptUserId,
      readReceiptMatrixUserId: readReceiptMatrixUserId is String?
          ? readReceiptMatrixUserId
          : this.readReceiptMatrixUserId,
      typingMatrixUserIds: typingMatrixUserIds is List<String>?
          ? typingMatrixUserIds
          : this.typingMatrixUserIds?.map((e0) => e0).toList(),
      typingDisplayNames: typingDisplayNames is List<String>?
          ? typingDisplayNames
          : this.typingDisplayNames?.map((e0) => e0).toList(),
      unreadCount: unreadCount is int? ? unreadCount : this.unreadCount,
      membershipChangedField: membershipChangedField is String?
          ? membershipChangedField
          : this.membershipChangedField,
      reactionTargetEventId: reactionTargetEventId is String?
          ? reactionTargetEventId
          : this.reactionTargetEventId,
      reactionKey: reactionKey is String? ? reactionKey : this.reactionKey,
      reactionReactorMatrixUserId: reactionReactorMatrixUserId is String?
          ? reactionReactorMatrixUserId
          : this.reactionReactorMatrixUserId,
      reactionEventId: reactionEventId is String?
          ? reactionEventId
          : this.reactionEventId,
      reactionRedacted: reactionRedacted is bool?
          ? reactionRedacted
          : this.reactionRedacted,
    );
  }
}
