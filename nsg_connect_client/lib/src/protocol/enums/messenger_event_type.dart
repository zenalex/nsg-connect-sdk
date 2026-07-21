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
  typingChanged,

  /// Реакция на сообщение добавлена/снята (emoji reactions). Payload —
  /// reaction* поля в [MessengerEvent]. SDK клиентски агрегирует
  /// (target, key) → count + own-flag; см. MessagesController.
  reactionChanged,

  /// **TASK46** — 1:1 голосовой сигналинг (WebRTC поверх Matrix). Каждое
  /// значение — входящее (Matrix `/sync` → клиент) call-событие с
  /// payload в `call*` полях [MessengerEvent] (callId / callPartyId /
  /// callSdp / callCandidates / ...). Dispatcher мапит Matrix `m.call.*`
  /// → сюда и эмитит в канал ПОЛУЧАТЕЛЯ (echo-skip отправителю, как для
  /// message). SDK CallController паттерн-матчит по этим типам. Маппинг:
  ///   * `m.call.invite`        → callInvite       (SDP offer в callSdp)
  ///   * `m.call.answer`        → callAnswer       (SDP answer в callSdp)
  ///   * `m.call.candidates`    → callCandidates   (trickle ICE в callCandidates)
  ///   * `m.call.hangup`        → callHangup       (причина в callHangupReason)
  ///   * `m.call.select_answer` → callSelectAnswer (callSelectedPartyId)
  ///   * `m.call.reject`        → callReject
  ///   * `m.call.negotiate`     → callNegotiate    (ICE restart / renegotiation:
  ///                                                SDP в callSdp, роль
  ///                                                offer/answer в callSdpType)
  callInvite,
  callAnswer,
  callCandidates,
  callHangup,
  callSelectAnswer,
  callReject,
  callNegotiate,

  /// **TASK55 итер.2b**: смена online-статуса подписанного контакта.
  /// Гейтится capability `presence` (см. userEventStream) — старым
  /// клиентам не доставляется (unknown enum уронил бы стрим).
  presenceUpdated,

  /// **TASK62/63 realtime-синк (2026-07-13)**: набор папок/membership
  /// чатов пользователя изменился (create/rename/delete/add/remove) —
  /// другие устройства сбрасывают кэш папок. Payload не нужен.
  chatFoldersChanged,

  /// Контакт-данные пользователя изменились (alias/заметка/метки) —
  /// сброс кэша меток + списка комнат (alias в именах direct).
  contactMetaChanged,

  /// **TASK52 итер.2**: пришла/изменилась карточка-заявка (message-
  /// request) — получатель сбрасывает список входящих заявок. Payload
  /// не нужен (клиент дочитывает listIncomingContactRequests).
  contactRequestChanged,

  /// **Issue #35 — закрепление сообщений**: список закреплённых
  /// сообщений комнаты изменился (pin/unpin). Payload — `pinnedEventIds`
  /// (полный новый список matrixEventId в порядке закрепления). SDK
  /// открытого чата обновляет плашку закреплённых. Источник правды —
  /// Matrix state event `m.room.pinned_events`; dispatcher парсит его
  /// (state + timeline) и эмитит это событие. Гейтится capability
  /// `pinned-messages` (для легаси-клиента без knownEventTypes — unknown
  /// enum уронил бы стрим; урок callNegotiate/presence).
  pinnedMessagesChanged;

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
      case 'reactionChanged':
        return MessengerEventType.reactionChanged;
      case 'callInvite':
        return MessengerEventType.callInvite;
      case 'callAnswer':
        return MessengerEventType.callAnswer;
      case 'callCandidates':
        return MessengerEventType.callCandidates;
      case 'callHangup':
        return MessengerEventType.callHangup;
      case 'callSelectAnswer':
        return MessengerEventType.callSelectAnswer;
      case 'callReject':
        return MessengerEventType.callReject;
      case 'callNegotiate':
        return MessengerEventType.callNegotiate;
      case 'presenceUpdated':
        return MessengerEventType.presenceUpdated;
      case 'chatFoldersChanged':
        return MessengerEventType.chatFoldersChanged;
      case 'contactMetaChanged':
        return MessengerEventType.contactMetaChanged;
      case 'contactRequestChanged':
        return MessengerEventType.contactRequestChanged;
      case 'pinnedMessagesChanged':
        return MessengerEventType.pinnedMessagesChanged;
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
