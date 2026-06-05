import 'package:nsg_connect_client/nsg_connect_client.dart';

/// UI-side представление сообщения в чате (TASK15).
///
/// Wrapper поверх серверного [MessengerMessage] с добавлением **status**
/// (pending / sent / failed) — нужно для optimistic-send UX:
/// pending bubble показывается сразу при `sendMessage()`, до того как
/// сервер подтвердит. После confirm — replace на sent. При failure —
/// failed bubble с retry-button.
///
/// **Почему wrapper, а не флаги в MessengerMessage**: серверный DTO
/// требует non-nullable `matrixEventId: String` — для pending у нас
/// его ещё нет. Вместо sentinel-строк (`pending:$txnId`) и проверок на
/// них в UI — отдельный класс с явным `matrixEventId: String?` +
/// status enum. UI bubble просто `switch (msg.status)` без trick-логики.
///
/// **Identity для optimistic dedup** — `clientTxnId` всегда заполнен:
///   * pending: SDK-генерированный UUID до RPC fire;
///   * sent (через RPC return): server echoes наш txnId назад;
///   * sent (через realtime stream): server echoes наш txnId через
///     `unsigned.transaction_id` ТОЛЬКО для sender-а того же device-а
///     (TASK15 Chunk 0 contract; см. doc у MessengerMessage.clientTxnId);
///   * sent (от другого user-а / другого device-а): clientTxnId == null
///     — не наше сообщение, dedup не применим.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.clientTxnId,
    required this.matrixEventId,
    required this.senderMatrixUserId,
    required this.senderMessengerUserId,
    required this.body,
    required this.msgType,
    required this.serverTimestamp,
    required this.status,
    this.threadId,
    this.replyToMessageId,
    this.lastError,
    this.attachment,
    this.editedAt,
    this.deletedAt,
    this.mentionedMessengerUserIds,
    this.senderDisplayName,
  });

  /// Идентификатор для optimistic dedup. Обязателен для собственных
  /// pending/sent сообщений; null допустим только для входящих от
  /// других user-ов / device-ов (где сервер не echoes).
  final String? clientTxnId;

  /// Matrix event id. `null` для pending (RPC ещё не вернулся).
  final String? matrixEventId;

  final String senderMatrixUserId;

  /// `null` если sender — system user (Matrix `m.notice`,
  /// `org.nsg.system`). Не `null` для обычных user-сообщений.
  final int? senderMessengerUserId;

  final String body;
  final String msgType;
  final DateTime serverTimestamp;
  final String? threadId;
  final String? replyToMessageId;
  final ChatMessageStatus status;

  /// Заполняется только для `failed`. Используется UI для retry-tooltip.
  final Object? lastError;

  /// TASK19 Chunk 3: media-вложение. Non-null когда `MessengerMessage`
  /// содержит `m.image` / `m.video` / `m.file` (server-side parser
  /// заполняет [MessengerMessage.attachment] из Matrix `info` block).
  /// SDK MessageBubble switch-ает рендеринг по `attachment.mimeType`.
  final AttachmentRef? attachment;

  /// TASK37: lifecycle metadata.
  /// `editedAt` non-null → bubble показывает «edited» badge inline с
  /// timestamp; `body` уже содержит latest version (server aggregates
  /// `m.replace` events).
  /// `deletedAt` non-null → bubble = tombstone «Message deleted»
  /// placeholder (italic, greyed); attachment hidden, action sheet
  /// disabled.
  final DateTime? editedAt;
  final DateTime? deletedAt;

  /// **TASK16-A**: messengerUserIds, упомянутые в этом сообщении.
  /// `null` = no mentions field; `[]` = explicit empty (rare); non-empty
  /// = resolved internal users. Federation users dropped server-side
  /// (см. `MentionResolver.resolveIncoming` doc).
  ///
  /// SDK uses:
  ///   * **Bubble highlighting**: scan body for `@<displayName>` tokens
  ///     и оборачивать в стилизованный TextSpan ТОЛЬКО если matching
  ///     mention в этом array (anti false-positive — литеральные `@foo`
  ///     в тексте без mention intent остаются plain).
  ///   * **Self-mention badge / push routing** (`currentUserId in
  ///     mentionedMessengerUserIds`).
  final List<int>? mentionedMessengerUserIds;

  /// **B17 phase 2**: server-resolved displayName отправителя
  /// (`MessengerUser.displayName` на момент возврата сообщения сервером).
  /// Null для system events (`senderMessengerUserId == null`) и для
  /// unresolved senders (cross-tenant / deleted users — редкий случай).
  ///
  /// UI приоритет (`chat_screen` search results, peer-headers,
  /// read-receipts list):
  ///   1. `senderDisplayName` — server-side fresh, корректно даже для
  ///      ex-members (вышедших из комнаты);
  ///   2. `RoomDetails.participants[mxid].displayName` — для current
  ///      members резерв (на случай когда server поле = null);
  ///   3. matrix-localpart `@user:server` → `user`;
  ///   4. raw mxid.
  final String? senderDisplayName;

  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;
  bool get hasReply => replyToMessageId != null;
  bool get hasMentions =>
      mentionedMessengerUserIds != null &&
      mentionedMessengerUserIds!.isNotEmpty;

  /// Создать sent-сообщение из серверного DTO (RPC return или realtime
  /// stream). Если у DTO `clientTxnId == null` (входящее от чужого
  /// device-а), переопределить можно через [overrideClientTxnId] —
  /// нужно когда RPC return приходит после того, как мы уже видели
  /// stream-event с null clientTxnId (multi-device sender's other
  /// device через stream — но всё равно наш RPC echo вернёт txnId,
  /// так что override нужен только в edge-cases).
  factory ChatMessage.fromServer(
    MessengerMessage m, {
    String? overrideClientTxnId,
  }) => ChatMessage(
    clientTxnId: overrideClientTxnId ?? m.clientTxnId,
    matrixEventId: m.matrixEventId,
    senderMatrixUserId: m.senderMatrixUserId,
    senderMessengerUserId: m.senderMessengerUserId,
    body: m.body,
    msgType: m.msgType,
    serverTimestamp: m.serverTimestamp,
    threadId: m.threadId,
    replyToMessageId: m.replyToMessageId,
    status: ChatMessageStatus.sent,
    attachment: m.attachment,
    editedAt: m.editedAt,
    deletedAt: m.deletedAt,
    mentionedMessengerUserIds: m.mentionedMessengerUserIds,
    senderDisplayName: m.senderDisplayName,
  );

  /// Создать pending-сообщение для optimistic-render. UI показывает его
  /// сразу при `MessagesController.sendMessage`, replace на sent после
  /// RPC confirm.
  factory ChatMessage.optimistic({
    required String clientTxnId,
    required String senderMatrixUserId,
    required int senderMessengerUserId,
    required String body,
    String msgType = 'm.text',
    DateTime? serverTimestamp,
    String? threadId,
    String? replyToMessageId,
    AttachmentRef? attachment,
    List<int>? mentionedMessengerUserIds,
  }) => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: null,
    senderMatrixUserId: senderMatrixUserId,
    senderMessengerUserId: senderMessengerUserId,
    body: body,
    msgType: msgType,
    serverTimestamp: serverTimestamp ?? DateTime.now().toUtc(),
    threadId: threadId,
    replyToMessageId: replyToMessageId,
    status: ChatMessageStatus.pending,
    attachment: attachment,
    mentionedMessengerUserIds: mentionedMessengerUserIds,
  );

  /// Перевести pending → failed (retainable retry-state). Сохраняет
  /// `clientTxnId` — retry будет с тем же id (server-side idempotency).
  ChatMessage failed(Object error) => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: matrixEventId,
    senderMatrixUserId: senderMatrixUserId,
    senderMessengerUserId: senderMessengerUserId,
    body: body,
    msgType: msgType,
    serverTimestamp: serverTimestamp,
    threadId: threadId,
    replyToMessageId: replyToMessageId,
    status: ChatMessageStatus.failed,
    lastError: error,
    attachment: attachment,
    editedAt: editedAt,
    deletedAt: deletedAt,
    mentionedMessengerUserIds: mentionedMessengerUserIds,
    senderDisplayName: senderDisplayName,
  );

  /// Перевести failed → pending (на retry). Сохраняет тот же
  /// `clientTxnId`.
  ChatMessage retrying() => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: matrixEventId,
    senderMatrixUserId: senderMatrixUserId,
    senderMessengerUserId: senderMessengerUserId,
    body: body,
    msgType: msgType,
    serverTimestamp: serverTimestamp,
    threadId: threadId,
    replyToMessageId: replyToMessageId,
    status: ChatMessageStatus.pending,
    attachment: attachment,
    editedAt: editedAt,
    deletedAt: deletedAt,
    mentionedMessengerUserIds: mentionedMessengerUserIds,
    senderDisplayName: senderDisplayName,
  );

  /// **TASK37**: применить edit — body заменяется, `editedAt`
  /// populated. Использует и optimistic-update в controller, и
  /// `messageUpdated` reactor для realtime apply.
  ChatMessage withEdit({
    required String newBody,
    required DateTime editedAt,
    List<int>? newMentionedMessengerUserIds,
  }) => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: matrixEventId,
    senderMatrixUserId: senderMatrixUserId,
    senderMessengerUserId: senderMessengerUserId,
    body: newBody,
    msgType: msgType,
    serverTimestamp: serverTimestamp,
    threadId: threadId,
    replyToMessageId: replyToMessageId,
    status: status,
    attachment: attachment,
    editedAt: editedAt,
    deletedAt: deletedAt,
    mentionedMessengerUserIds: newMentionedMessengerUserIds,
    senderDisplayName: senderDisplayName,
  );

  /// **TASK37**: применить delete — body cleared, `deletedAt`
  /// populated, attachment dropped. UI рисует tombstone.
  ChatMessage withDelete({required DateTime deletedAt}) => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: matrixEventId,
    senderMatrixUserId: senderMatrixUserId,
    senderMessengerUserId: senderMessengerUserId,
    body: '',
    msgType: msgType,
    serverTimestamp: serverTimestamp,
    threadId: threadId,
    replyToMessageId: replyToMessageId,
    status: status,
    attachment: null,
    editedAt: editedAt,
    deletedAt: deletedAt,
    mentionedMessengerUserIds: null,
    senderDisplayName: senderDisplayName,
  );

  bool get isPending => status == ChatMessageStatus.pending;
  bool get isFailed => status == ChatMessageStatus.failed;
  bool get isSent => status == ChatMessageStatus.sent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.clientTxnId == clientTxnId &&
        other.matrixEventId == matrixEventId &&
        other.senderMatrixUserId == senderMatrixUserId &&
        other.body == body &&
        other.serverTimestamp == serverTimestamp &&
        other.status == status;
  }

  @override
  int get hashCode =>
      Object.hash(clientTxnId, matrixEventId, body, serverTimestamp, status);

  @override
  String toString() =>
      'ChatMessage(${status.name} ${matrixEventId ?? "<pending>"} '
      'body=${body.length > 20 ? "${body.substring(0, 20)}…" : body})';
}

enum ChatMessageStatus { pending, sent, failed }

/// **Emoji reactions**: агрегированная группа реакций одного emoji-ключа
/// на конкретное сообщение. Используется UI (`MessageBubble`) для
/// рендеринга чипа «emoji × count». `mine == true` → чип подсвечен
/// accent-цветом, tap toggle-ит свою реакцию.
@immutable
class ReactionGroup {
  const ReactionGroup({
    required this.key,
    required this.count,
    required this.mine,
  });

  /// Emoji-ключ (`👍`, `❤️`, ...).
  final String key;

  /// Сколько разных пользователей поставили эту реакцию.
  final int count;

  /// `true` если текущий пользователь среди реакторов (для подсветки +
  /// toggle).
  final bool mine;

  @override
  bool operator ==(Object other) =>
      other is ReactionGroup &&
      other.key == key &&
      other.count == count &&
      other.mine == mine;

  @override
  int get hashCode => Object.hash(key, count, mine);

  @override
  String toString() => 'ReactionGroup($key ×$count${mine ? " mine" : ""})';
}
