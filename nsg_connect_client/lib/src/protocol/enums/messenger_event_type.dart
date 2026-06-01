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

/// Тип события в `userEventStream` / `roomStream` (TASK09 + TASK17).
/// Discriminator для тэг-юнион [MessengerEvent].
///
/// Группы:
///   * `messageCreated` (TASK09) — single message append.
///   * `roomCreated` (TASK17 Chunk 2) — caller получил доступ к новой
///     комнате (через invite или create).
///   * `membershipJoined` / `membershipLeft` / `membershipRemoved`
///     (TASK17 Chunk 2) — изменение участников. `joined` = invitee
///     принял; `left` = `sender == affectedUser` (добровольный leave);
///     `removed` = `sender != affected` (kick/ban; на MVP не различаем,
///     TASK29 расширит).
///   * `roomStateChanged` (TASK17 Chunk 2) — Matrix room metadata
///     state-event (`m.room.name` / `m.room.topic` / `m.room.avatar`).
///     На MVP dispatcher эмитит ТОЛЬКО для `field='name'` (см. TASK17
///     review Chunk 2 Q2 — topic/avatar до их хранения в Room model
///     отложены TASK22). Поле `field` в [RoomStateChange] оставлено
///     `String` для расширяемости без enum-breaking.
///   * `roomUnreadChanged` (TASK18) — per-user counter изменился
///     (либо инкремент через dispatcher на новое сообщение, либо
///     обнуление через `markRead`). SDK reactor invalidates list
///     cache → ChatsListScreen badge перерендеривается. Cross-device:
///     device A markRead → device B видит обновлённый counter без
///     прихода нового сообщения.
///   * `roomMembershipUpdated` (TASK42) — per-user `RoomMembership`
///     state изменился (mute / archive). **Privacy boundary**: emit
///     ТОЛЬКО в channel того user-а, чей RoomMembership row updated;
///     **не** broadcast другим participants. Иначе bob узнаёт что
///     alice его замутила = leak. См. TASK42 plan Q1.
///   * Зарезервировано (не используется на TASK17/18/42): `messageUpdated`,
///     `messageDeleted` (TASK37 threads), `roomUpdated`,
///     `roomArchived`, `roomClosed`, `membershipRoleChanged`,
///     `readReceiptUpdated` (per-message read indicator —
///     deferred до TASK33 settings + read-receipt toggle, см. TASK18
///     plan Q1).
enum MessengerEventType implements _i1.SerializableModel {
  messageCreated,
  messageUpdated,
  messageDeleted,
  roomCreated,
  roomUpdated,
  roomArchived,
  roomClosed,
  roomStateChanged,
  roomUnreadChanged,
  roomMembershipUpdated,
  membershipJoined,
  membershipLeft,
  membershipRemoved,
  membershipRoleChanged,
  readReceiptUpdated,
  typingChanged;

  static MessengerEventType fromJson(String name) {
    switch (name) {
      case 'messageCreated':
        return MessengerEventType.messageCreated;
      case 'messageUpdated':
        return MessengerEventType.messageUpdated;
      case 'messageDeleted':
        return MessengerEventType.messageDeleted;
      case 'roomCreated':
        return MessengerEventType.roomCreated;
      case 'roomUpdated':
        return MessengerEventType.roomUpdated;
      case 'roomArchived':
        return MessengerEventType.roomArchived;
      case 'roomClosed':
        return MessengerEventType.roomClosed;
      case 'roomStateChanged':
        return MessengerEventType.roomStateChanged;
      case 'roomUnreadChanged':
        return MessengerEventType.roomUnreadChanged;
      case 'roomMembershipUpdated':
        return MessengerEventType.roomMembershipUpdated;
      case 'membershipJoined':
        return MessengerEventType.membershipJoined;
      case 'membershipLeft':
        return MessengerEventType.membershipLeft;
      case 'membershipRemoved':
        return MessengerEventType.membershipRemoved;
      case 'membershipRoleChanged':
        return MessengerEventType.membershipRoleChanged;
      case 'readReceiptUpdated':
        return MessengerEventType.readReceiptUpdated;
      case 'typingChanged':
        return MessengerEventType.typingChanged;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "MessengerEventType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
