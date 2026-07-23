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
import 'dart:typed_data' as _i2;
import 'attachment_ref.dart' as _i3;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i4;

/// Сообщение мессенджера. DTO для клиента + payload в realtime-стримах.
/// См. ТЗ §12, TASK09.
///
/// `roomId`/`matrixRoomId` — обе ID присутствуют для удобства клиента
/// (избегаем round-trip через Room для конвертации). При отсутствии
/// связанной local Room (system events до её создания) — roomId=0,
/// matrixRoomId — настоящий.
///
/// `senderMessengerUserId == null` — system event (Matrix `m.notice`,
/// `org.nsg.system`, события lifecycle комнат). senderMatrixUserId
/// всегда задан (Matrix всегда даёт sender).
///
/// Поля для тредов (TASK37) — сразу в DTO, чтобы при добавлении UI
/// тредов не переписывать модель сообщений (см. ТЗ §24).
abstract class MessengerMessage implements _i1.SerializableModel {
  MessengerMessage._({
    required this.matrixEventId,
    required this.roomId,
    required this.matrixRoomId,
    this.senderMessengerUserId,
    required this.senderMatrixUserId,
    required this.msgType,
    required this.body,
    this.content,
    this.parentMessageId,
    this.threadId,
    this.replyToMessageId,
    this.threadReplyCount,
    this.threadLastReplyAt,
    this.taskStage,
    this.taskThreadRootEventId,
    this.taskUrl,
    required this.serverTimestamp,
    this.clientTxnId,
    this.attachment,
    this.editedAt,
    this.deletedAt,
    this.mentionedMessengerUserIds,
    bool? mentionedRoom,
    this.senderDisplayName,
  }) : mentionedRoom = mentionedRoom ?? false;

  factory MessengerMessage({
    required String matrixEventId,
    required int roomId,
    required String matrixRoomId,
    int? senderMessengerUserId,
    required String senderMatrixUserId,
    required String msgType,
    required String body,
    _i2.ByteData? content,
    String? parentMessageId,
    String? threadId,
    String? replyToMessageId,
    int? threadReplyCount,
    DateTime? threadLastReplyAt,
    String? taskStage,
    String? taskThreadRootEventId,
    String? taskUrl,
    required DateTime serverTimestamp,
    String? clientTxnId,
    _i3.AttachmentRef? attachment,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<int>? mentionedMessengerUserIds,
    bool? mentionedRoom,
    String? senderDisplayName,
  }) = _MessengerMessageImpl;

  factory MessengerMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessengerMessage(
      matrixEventId: jsonSerialization['matrixEventId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      matrixRoomId: jsonSerialization['matrixRoomId'] as String,
      senderMessengerUserId: jsonSerialization['senderMessengerUserId'] as int?,
      senderMatrixUserId: jsonSerialization['senderMatrixUserId'] as String,
      msgType: jsonSerialization['msgType'] as String,
      body: jsonSerialization['body'] as String,
      content: jsonSerialization['content'] == null
          ? null
          : _i1.ByteDataJsonExtension.fromJson(jsonSerialization['content']),
      parentMessageId: jsonSerialization['parentMessageId'] as String?,
      threadId: jsonSerialization['threadId'] as String?,
      replyToMessageId: jsonSerialization['replyToMessageId'] as String?,
      threadReplyCount: jsonSerialization['threadReplyCount'] as int?,
      threadLastReplyAt: jsonSerialization['threadLastReplyAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['threadLastReplyAt'],
            ),
      taskStage: jsonSerialization['taskStage'] as String?,
      taskThreadRootEventId:
          jsonSerialization['taskThreadRootEventId'] as String?,
      taskUrl: jsonSerialization['taskUrl'] as String?,
      serverTimestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverTimestamp'],
      ),
      clientTxnId: jsonSerialization['clientTxnId'] as String?,
      attachment: jsonSerialization['attachment'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.AttachmentRef>(
              jsonSerialization['attachment'],
            ),
      editedAt: jsonSerialization['editedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['editedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      mentionedMessengerUserIds:
          jsonSerialization['mentionedMessengerUserIds'] == null
          ? null
          : _i4.Protocol().deserialize<List<int>>(
              jsonSerialization['mentionedMessengerUserIds'],
            ),
      mentionedRoom: jsonSerialization['mentionedRoom'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['mentionedRoom']),
      senderDisplayName: jsonSerialization['senderDisplayName'] as String?,
    );
  }

  String matrixEventId;

  int roomId;

  String matrixRoomId;

  int? senderMessengerUserId;

  String senderMatrixUserId;

  /// Matrix msgtype: 'm.text', 'm.image', 'm.file', 'm.notice',
  /// 'm.emote', 'org.nsg.system' (custom).
  String msgType;

  String body;

  /// Сырой content из Matrix event (raw JSON, byte-encoded). Нужен,
  /// чтобы пробрасывать extension-поля (m.relates_to, info, и т.п.)
  /// в SDK без переноса каждого поля в DTO.
  _i2.ByteData? content;

  /// См. §24 ТЗ. parentMessageId — Matrix event id родительского
  /// сообщения треда; threadId — корень треда; replyToMessageId —
  /// m.in_reply_to. На MVP UI тредов нет, поля заполняются если в
  /// content.m.relates_to это указано.
  String? parentMessageId;

  String? threadId;

  String? replyToMessageId;

  /// **TASK82 threadSummary**: заполняются ТОЛЬКО у якорного сообщения задачи в
  /// ОСНОВНОЙ ленте (`listMessages`) — счётчик ответов в треде и время
  /// последнего. DTO-only (не persisted): считаются на лету из `message_index`
  /// по (roomId, threadRootEventId). null у обычных сообщений и у самих ответов
  /// треда. SDK рисует по ним строку-кнопку «Обсуждение (N) →» на карточке
  /// задачи. Аддитивные nullable-поля: старые клиенты игнорируют неизвестный
  /// ключ при десериализации → capability-гейт не нужен.
  int? threadReplyCount;

  DateTime? threadLastReplyAt;

  /// **TASK83 значок задачи**: у ИСХОДНОГО сообщения (того, из которого
  /// завели задачу — `TaskLink.matrixEventId`) — метаданные заведённой
  /// задачи, чтобы bubble нарисовал значок цвета стадии и по тапу вёл в
  /// обсуждение. Заполняются батчем в `listMessages`/`listThreadMessages`
  /// через `MessageIndexService.taskBadges` (цепочка сообщение → TaskLink →
  /// Ticket). DTO-only (не persisted), как `threadReplyCount`.
  ///
  /// `taskStage` — гранулярная стадия тикета (`new`/`in_progress`/`accepted`/
  /// `rejected`, см. `TicketService`); **null**, когда TaskLink есть, а тикета
  /// нет (задача заведена во внешней системе, но локального тикета мы не
  /// завели) — значок рисуется нейтральным «задача заведена». Цвет решает
  /// клиент (цвета — тема), сервер отдаёт стадию строкой.
  /// `taskThreadRootEventId` — корень треда задачи (TASK82); есть → тап ведёт
  /// в тред, нет → в issue-URL (`taskUrl`).
  /// `taskUrl` — ссылка на issue (fallback-переход и признак «задача есть»).
  /// Все три null → задачи нет, значка нет (старый клиент поля игнорирует).
  String? taskStage;

  String? taskThreadRootEventId;

  String? taskUrl;

  DateTime serverTimestamp;

  /// Client-side transaction id, который sender передал в `sendMessage`.
  /// Используется SDK для optimistic-send dedup (TASK15): pending bubble
  /// → real entry matched по `clientTxnId`.
  ///
  /// **Видимость**: заполняется ТОЛЬКО для sender-а того же устройства,
  /// которое выполнило `sendMessage`:
  ///   * RPC return path: `MatrixMessageService.sendMessage` plug-ит txnId
  ///     напрямую в DTO.
  ///   * `/sync` echo path: Synapse кладёт `unsigned.transaction_id` ТОЛЬКО
  ///     для sender-а того же device-а (Matrix spec). Other recipients и
  ///     другие устройства того же юзера получат `null` — у них нет
  ///     pending-message, dedup не нужен.
  ///
  /// **Не persisted в БД** — DTO-only поле, нужно только в момент receive
  /// (within seconds от send). Исторические queries клиента
  /// (`listMessages` по pagination) вернут null здесь — это OK.
  String? clientTxnId;

  /// TASK19: media attachment (image / video / file). null для plain
  /// text сообщений. SDK reactor смотрит `attachment != null` →
  /// рендерит соответствующий bubble per `attachment.mimeType`.
  ///
  /// Server заполняет это поле когда парсит Matrix `m.image` /
  /// `m.video` / `m.file` event с `info` block — derives mxcUrl, mime,
  /// dimensions из event.content. Backward compat: старые text-only
  /// messages приходят с `attachment: null`.
  _i3.AttachmentRef? attachment;

  /// TASK37: lifecycle metadata. Non-null `editedAt` → message был
  /// edited через Matrix `m.replace`; `body` всегда содержит **latest**
  /// version, история всех edits живёт Matrix-side (Phase2 «edit history
  /// viewer»). Non-null `deletedAt` → message redacted через Matrix
  /// `m.room.redaction`; `body`/`attachment` cleared, SDK рисует
  /// tombstone «Message deleted».
  ///
  /// **Authorization** (TASK37 plan Q2): edit/delete только own messages
  /// (`event.sender == caller.matrixUserId`). Cross-user redact (admin
  /// moderation) — TASK29 через `m.power_levels.redact` field.
  ///
  /// **No edit time window** (TASK37 plan Q1) — Matrix allows
  /// indefinitely; tenant cutoff в TASK33 если customer попросит.
  DateTime? editedAt;

  DateTime? deletedAt;

  /// TASK16-A: список упомянутых юзеров (Matrix `m.mentions.user_ids`).
  /// Convention: `null` = no mentions field в content. `[]` (empty
  /// list) — explicit empty mentions block, rare-case. Federation
  /// users (matrix users без MessengerUser row у нас) silently
  /// dropped из array — push routing TASK20-Phase2 reach-ит только
  /// известных юзеров. SDK MessageBubble использует array для
  /// highlighting `@displayName` tokens в body (anti-injection: только
  /// matching tokens styled, arbitrary `@unknown` plain text).
  List<int>? mentionedMessengerUserIds;

  /// **TASK29 / TASK16-A Q5 closure**: `@room` mention flag (Matrix
  /// `m.mentions.room == true`). Sender выделил **всех** participants
  /// одним токеном; SDK MessageBubble рендерит `@room` highlighted
  /// всегда (in отличие от user-mentions, где highlight conditional
  /// на match с participants displayName).
  ///
  /// `default=false` для backward compat — старые messages без
  /// parsing-а получают `false`. SDK degrade-ится gracefully (no
  /// highlight). Push routing для `@room` — TASK20-Phase2 (broadcast
  /// всем room members с notification override).
  bool mentionedRoom;

  /// B17 phase 2: server-resolved displayName отправителя.
  /// Заполняется в `MatrixMessageService._convertEvent` через
  /// batch lookup MessengerUser.db. Null для system messages
  /// (senderMessengerUserId == null) и для unresolved senders
  /// (cross-tenant / deleted users — редкий случай).
  /// SDK использует как первичный source для search results,
  /// bubble peer-header, read-receipts list (вместо
  /// participantsByMatrixId.displayName который не имеет
  /// ex-members).
  String? senderDisplayName;

  /// Returns a shallow copy of this [MessengerMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerMessage copyWith({
    String? matrixEventId,
    int? roomId,
    String? matrixRoomId,
    int? senderMessengerUserId,
    String? senderMatrixUserId,
    String? msgType,
    String? body,
    _i2.ByteData? content,
    String? parentMessageId,
    String? threadId,
    String? replyToMessageId,
    int? threadReplyCount,
    DateTime? threadLastReplyAt,
    String? taskStage,
    String? taskThreadRootEventId,
    String? taskUrl,
    DateTime? serverTimestamp,
    String? clientTxnId,
    _i3.AttachmentRef? attachment,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<int>? mentionedMessengerUserIds,
    bool? mentionedRoom,
    String? senderDisplayName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerMessage',
      'matrixEventId': matrixEventId,
      'roomId': roomId,
      'matrixRoomId': matrixRoomId,
      if (senderMessengerUserId != null)
        'senderMessengerUserId': senderMessengerUserId,
      'senderMatrixUserId': senderMatrixUserId,
      'msgType': msgType,
      'body': body,
      if (content != null) 'content': content?.toJson(),
      if (parentMessageId != null) 'parentMessageId': parentMessageId,
      if (threadId != null) 'threadId': threadId,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (threadReplyCount != null) 'threadReplyCount': threadReplyCount,
      if (threadLastReplyAt != null)
        'threadLastReplyAt': threadLastReplyAt?.toJson(),
      if (taskStage != null) 'taskStage': taskStage,
      if (taskThreadRootEventId != null)
        'taskThreadRootEventId': taskThreadRootEventId,
      if (taskUrl != null) 'taskUrl': taskUrl,
      'serverTimestamp': serverTimestamp.toJson(),
      if (clientTxnId != null) 'clientTxnId': clientTxnId,
      if (attachment != null) 'attachment': attachment?.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (mentionedMessengerUserIds != null)
        'mentionedMessengerUserIds': mentionedMessengerUserIds?.toJson(),
      'mentionedRoom': mentionedRoom,
      if (senderDisplayName != null) 'senderDisplayName': senderDisplayName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerMessageImpl extends MessengerMessage {
  _MessengerMessageImpl({
    required String matrixEventId,
    required int roomId,
    required String matrixRoomId,
    int? senderMessengerUserId,
    required String senderMatrixUserId,
    required String msgType,
    required String body,
    _i2.ByteData? content,
    String? parentMessageId,
    String? threadId,
    String? replyToMessageId,
    int? threadReplyCount,
    DateTime? threadLastReplyAt,
    String? taskStage,
    String? taskThreadRootEventId,
    String? taskUrl,
    required DateTime serverTimestamp,
    String? clientTxnId,
    _i3.AttachmentRef? attachment,
    DateTime? editedAt,
    DateTime? deletedAt,
    List<int>? mentionedMessengerUserIds,
    bool? mentionedRoom,
    String? senderDisplayName,
  }) : super._(
         matrixEventId: matrixEventId,
         roomId: roomId,
         matrixRoomId: matrixRoomId,
         senderMessengerUserId: senderMessengerUserId,
         senderMatrixUserId: senderMatrixUserId,
         msgType: msgType,
         body: body,
         content: content,
         parentMessageId: parentMessageId,
         threadId: threadId,
         replyToMessageId: replyToMessageId,
         threadReplyCount: threadReplyCount,
         threadLastReplyAt: threadLastReplyAt,
         taskStage: taskStage,
         taskThreadRootEventId: taskThreadRootEventId,
         taskUrl: taskUrl,
         serverTimestamp: serverTimestamp,
         clientTxnId: clientTxnId,
         attachment: attachment,
         editedAt: editedAt,
         deletedAt: deletedAt,
         mentionedMessengerUserIds: mentionedMessengerUserIds,
         mentionedRoom: mentionedRoom,
         senderDisplayName: senderDisplayName,
       );

  /// Returns a shallow copy of this [MessengerMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerMessage copyWith({
    String? matrixEventId,
    int? roomId,
    String? matrixRoomId,
    Object? senderMessengerUserId = _Undefined,
    String? senderMatrixUserId,
    String? msgType,
    String? body,
    Object? content = _Undefined,
    Object? parentMessageId = _Undefined,
    Object? threadId = _Undefined,
    Object? replyToMessageId = _Undefined,
    Object? threadReplyCount = _Undefined,
    Object? threadLastReplyAt = _Undefined,
    Object? taskStage = _Undefined,
    Object? taskThreadRootEventId = _Undefined,
    Object? taskUrl = _Undefined,
    DateTime? serverTimestamp,
    Object? clientTxnId = _Undefined,
    Object? attachment = _Undefined,
    Object? editedAt = _Undefined,
    Object? deletedAt = _Undefined,
    Object? mentionedMessengerUserIds = _Undefined,
    bool? mentionedRoom,
    Object? senderDisplayName = _Undefined,
  }) {
    return MessengerMessage(
      matrixEventId: matrixEventId ?? this.matrixEventId,
      roomId: roomId ?? this.roomId,
      matrixRoomId: matrixRoomId ?? this.matrixRoomId,
      senderMessengerUserId: senderMessengerUserId is int?
          ? senderMessengerUserId
          : this.senderMessengerUserId,
      senderMatrixUserId: senderMatrixUserId ?? this.senderMatrixUserId,
      msgType: msgType ?? this.msgType,
      body: body ?? this.body,
      content: content is _i2.ByteData? ? content : this.content?.clone(),
      parentMessageId: parentMessageId is String?
          ? parentMessageId
          : this.parentMessageId,
      threadId: threadId is String? ? threadId : this.threadId,
      replyToMessageId: replyToMessageId is String?
          ? replyToMessageId
          : this.replyToMessageId,
      threadReplyCount: threadReplyCount is int?
          ? threadReplyCount
          : this.threadReplyCount,
      threadLastReplyAt: threadLastReplyAt is DateTime?
          ? threadLastReplyAt
          : this.threadLastReplyAt,
      taskStage: taskStage is String? ? taskStage : this.taskStage,
      taskThreadRootEventId: taskThreadRootEventId is String?
          ? taskThreadRootEventId
          : this.taskThreadRootEventId,
      taskUrl: taskUrl is String? ? taskUrl : this.taskUrl,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      clientTxnId: clientTxnId is String? ? clientTxnId : this.clientTxnId,
      attachment: attachment is _i3.AttachmentRef?
          ? attachment
          : this.attachment?.copyWith(),
      editedAt: editedAt is DateTime? ? editedAt : this.editedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      mentionedMessengerUserIds: mentionedMessengerUserIds is List<int>?
          ? mentionedMessengerUserIds
          : this.mentionedMessengerUserIds?.map((e0) => e0).toList(),
      mentionedRoom: mentionedRoom ?? this.mentionedRoom,
      senderDisplayName: senderDisplayName is String?
          ? senderDisplayName
          : this.senderDisplayName,
    );
  }
}
