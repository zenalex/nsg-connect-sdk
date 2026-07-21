import 'dart:convert';
import 'dart:typed_data';

import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'forward_source.dart';
import 'status_card_data.dart';

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
    this.albumId,
    this.forwardedFromName,
    this.forwardedFromMessengerUserId,
    this.forwardedSource,
    this.statusCard,
    this.localImageBytes,
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

  /// **Альбом**: общий id для нескольких картинок, отправленных одним
  /// действием (клиентская группировка «одно сообщение с мозаикой»).
  /// Едет в custom-поле `nsg.album_id` сырого Matrix-content-а (см.
  /// [_albumIdFromContent]); optimistic-сообщения проставляют напрямую.
  /// Non-null → рендер группирует подряд идущие сообщения одного альбома
  /// в один пузырь-мозаику. Null → обычное одиночное сообщение.
  final String? albumId;

  /// **Пересылка (forward)**: имя исходного автора пересланного сообщения
  /// (как в Telegram — «Переслано от X»). Едет в custom-поле
  /// `nsg.forwarded_from` сырого Matrix-content-а (см. [_forwardedFromContent]).
  /// Non-null → bubble рисует шапку «Переслано от <имя>». Null → обычное
  /// (не пересланное) сообщение.
  ///
  /// **Re-forward**: при пересылке уже-пересланного сообщения сохраняется
  /// ПЕРВЫЙ автор (значение переносится как есть, а не имя промежуточного
  /// пересыльщика) — см. `MessagesController.forwardMessage`.
  final String? forwardedFromName;

  /// **Пересылка**: `messengerUserId` исходного автора (custom-поле
  /// `nsg.forwarded_from_uid`). Опционально — для будущего tap-to-profile
  /// на шапке «Переслано от X». Может быть null даже при заполненном
  /// [forwardedFromName] (старый сервер / cross-tenant автор).
  final int? forwardedFromMessengerUserId;

  /// **Пересылка, issue #41**: координаты ПЕРВОИСТОЧНИКА (roomId + eventId)
  /// в custom-полях `nsg.forwarded_room_id` / `nsg.forwarded_event_id`.
  /// Non-null → шапка «Переслано от X» кликабельна и открывает исходный чат
  /// на исходном сообщении.
  ///
  /// Null — **штатная** ситуация, а не ошибка: у сообщений, пересланных ДО
  /// issue #41, этих полей в content-е нет (на старте это большинство
  /// пересланных сообщений). UI в таком случае просто не делает шапку
  /// кликабельной — см. [ForwardSource.tryParse].
  final ForwardSource? forwardedSource;

  /// **TASK58 (автопост статусов)**: структурированная статус-карточка,
  /// приезжающая в custom-поле `nsg.status_card` сырого Matrix-content-а
  /// (см. [StatusCardData.tryParse]). Заполняется для сообщений с
  /// `msgType == 'nsg.status_card'` от бота-подпорки входящего webhook-а.
  /// Non-null → bubble рисует карточку (`_StatusCardBubble`) вместо plain
  /// body; null → обычный fallback на body (в т.ч. если поле не распарсилось).
  final StatusCardData? statusCard;

  /// **Оптимистичный альбом**: локальные байты картинки, показанные СРАЗУ
  /// (мозаика видна до аплоада). Заполнено только для собственных pending-
  /// картинок, у которых `attachment` ещё null (аплоад в фоне). После
  /// `withUploadedAttachment` байты **сохраняются** (плитка расблюривается
  /// без перезагрузки), обнуляются только при promote в sent из /sync или
  /// в tombstone. НЕ участвует в `==`/`hashCode` (identity Uint8List
  /// сломал бы optimistic dedup).
  final Uint8List? localImageBytes;

  /// **Оптимистичный альбом**: картинка ещё грузится (bytes есть, mxc —
  /// нет). UI рисует плитку блюром + прогресс-индикатор. После аплоада
  /// (`attachment != null`) — расблюр.
  bool get isUploadingImage =>
      status == ChatMessageStatus.pending &&
      attachment == null &&
      localImageBytes != null;

  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;
  bool get hasReply => replyToMessageId != null;
  bool get isForwarded =>
      forwardedFromName != null && forwardedFromName!.isNotEmpty;
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
    Uint8List? overrideLocalImageBytes,
  }) {
    // Декодируем сырой Matrix-content ОДИН раз — из него достаём и
    // `nsg.album_id`, и forward-атрибуцию (`nsg.forwarded_from[_uid]`).
    final content = _decodeContent(m);
    final fwdUid = content?['nsg.forwarded_from_uid'];
    return ChatMessage(
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
      albumId: _nonEmptyString(content?['nsg.album_id']),
      forwardedFromName: _nonEmptyString(content?['nsg.forwarded_from']),
      forwardedFromMessengerUserId: fwdUid is int ? fwdUid : null,
      // Issue #41: координаты первоисточника — весь defensive-парсинг
      // (полупара / не-число / пустая строка) внутри tryParse.
      forwardedSource: ForwardSource.tryParse(content),
      // **TASK58**: статус-карточка автопоста — тот же passthrough из
      // сырого content-а, что album_id/forwarded_from.
      statusCard: StatusCardData.tryParse(content),
      localImageBytes: overrideLocalImageBytes,
    );
  }

  /// Декодировать сырой Matrix-content DTO (server UTF-8/JSON-кодирует
  /// полный content в [MessengerMessage.content]) в Map. Any decode-ошибка /
  /// отсутствие content-а → null.
  static Map<String, dynamic>? _decodeContent(MessengerMessage m) {
    final raw = m.content;
    if (raw == null) return null;
    try {
      final bytes = raw.buffer.asUint8List(
        raw.offsetInBytes,
        raw.lengthInBytes,
      );
      if (bytes.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Вернуть значение, если это непустая строка; иначе null.
  static String? _nonEmptyString(Object? v) =>
      (v is String && v.isNotEmpty) ? v : null;

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
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    ForwardSource? forwardedSource,
    Uint8List? localImageBytes,
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
    albumId: albumId,
    forwardedFromName: forwardedFromName,
    forwardedFromMessengerUserId: forwardedFromMessengerUserId,
    forwardedSource: forwardedSource,
    localImageBytes: localImageBytes,
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
    albumId: albumId,
    forwardedFromName: forwardedFromName,
    forwardedFromMessengerUserId: forwardedFromMessengerUserId,
    forwardedSource: forwardedSource,
    statusCard: statusCard,
    localImageBytes: localImageBytes,
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
    albumId: albumId,
    forwardedFromName: forwardedFromName,
    forwardedFromMessengerUserId: forwardedFromMessengerUserId,
    forwardedSource: forwardedSource,
    statusCard: statusCard,
    localImageBytes: localImageBytes,
  );

  /// **Оптимистичный альбом**: аплоад завершён — привязать `attachment`
  /// (расблюр плитки). `msgType` пере-деривится из mime, `localImageBytes`
  /// **сохраняются** (плитка показывает те же байты, пока не прилетит mxc —
  /// без промежуточной перезагрузки), status остаётся `pending` (send RPC
  /// ещё впереди). Промоут в sent/tombstone обнулит байты.
  ChatMessage withUploadedAttachment(AttachmentRef ref) => ChatMessage(
    clientTxnId: clientTxnId,
    matrixEventId: matrixEventId,
    senderMatrixUserId: senderMatrixUserId,
    senderMessengerUserId: senderMessengerUserId,
    body: body,
    msgType: _msgTypeForMime(ref.mimeType),
    serverTimestamp: serverTimestamp,
    threadId: threadId,
    replyToMessageId: replyToMessageId,
    status: status,
    attachment: ref,
    editedAt: editedAt,
    deletedAt: deletedAt,
    mentionedMessengerUserIds: mentionedMessengerUserIds,
    senderDisplayName: senderDisplayName,
    albumId: albumId,
    forwardedFromName: forwardedFromName,
    forwardedFromMessengerUserId: forwardedFromMessengerUserId,
    forwardedSource: forwardedSource,
    localImageBytes: localImageBytes,
  );

  /// Matrix msgType из MIME для оптимистичного bubble (`m.image`/`m.video`/
  /// `m.file`). Идентично серверному деривату; сервер подтверждает точное
  /// значение в RPC-return.
  static String _msgTypeForMime(String mime) {
    if (mime.startsWith('image/')) return 'm.image';
    if (mime.startsWith('video/')) return 'm.video';
    if (mime.startsWith('audio/')) return 'm.audio';
    return 'm.file';
  }

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
    albumId: albumId,
    forwardedFromName: forwardedFromName,
    forwardedFromMessengerUserId: forwardedFromMessengerUserId,
    forwardedSource: forwardedSource,
    statusCard: statusCard,
    localImageBytes: localImageBytes,
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
    albumId: albumId,
    forwardedFromName: forwardedFromName,
    forwardedFromMessengerUserId: forwardedFromMessengerUserId,
    forwardedSource: forwardedSource,
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
