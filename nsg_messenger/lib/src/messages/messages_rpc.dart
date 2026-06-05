import 'dart:typed_data';

import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// Абстракция RPC-вызовов, нужных [MessagesController] (TASK15).
/// Тот же pattern что в `NsgMessengerRooms.attachWithRpcs` —
/// production wiring через `client.messenger.X`, тесты подменяют
/// in-memory fake-ами.
///
/// Сигнатуры зеркалят Serverpod-сгенерированные сигнатуры на клиенте
/// (`Client.messenger.listMessages` / `sendMessage`). Если Serverpod
/// поменяет API — сначала ломается production wiring (compile-time),
/// а тесты остаются стабильны.
abstract class MessagesRpc {
  /// Backward-pagination через Matrix `dir=b` (TASK15 Chunk 0).
  /// `fromToken == null` → первая страница (50 наиболее свежих).
  /// `fromToken == prevPage.nextToken` → OLDER страница.
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  });

  /// Отправить сообщение. `clientTxnId` обязателен — SDK генерирует
  /// UUID на каждый pending bubble; server-side через него идёт
  /// idempotency (retry тем же id не дублирует). `attachment`
  /// (TASK19 Chunk 3) — optional ref после успешного `uploadAttachment`;
  /// server derives Matrix `m.image`/`m.video`/`m.file` content per
  /// `attachment.mimeType`.
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  });

  /// **TASK19 Chunk 3**: upload media bytes в Matrix media repo через
  /// uploader's matrix token. Server validates MIME whitelist +
  /// extension blacklist + size cap, возвращает [AttachmentRef] для
  /// последующего `sendMessage(attachment:)`. Errors — `ArgumentError`
  /// на validation; SDK-side UI показывает snackbar с
  /// `attachUploadFailed`.
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  });

  /// **TASK19 Chunk 3**: download thumbnail для image preview в bubble.
  /// Server proxies через Authenticated Media `/thumbnail` endpoint.
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  });

  /// **TASK19 Chunk 3**: download full bytes — для tap-fullscreen
  /// viewer + file save. Authenticated Media `/download` endpoint.
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl});

  /// Помечает сообщения комнаты прочитанными до `matrixEventId`
  /// включительно (TASK18). Возвращает `true` если row реально
  /// обновился; `false` — older write rejected monotonic guard
  /// (другое устройство уже прочитало дальше). Не throws на
  /// regression — guard handled server-side как silent noop.
  Future<bool> markRead({required int roomId, required String matrixEventId});

  /// **TASK37**: edit own message через Matrix `m.replace`. Returns
  /// updated [MessengerMessage] с `matrixEventId = original` (NOT
  /// replace event id) + `editedAt` populated + `body = newBody`.
  /// Throws `MessageNotEditableException` (foreign / not-found) либо
  /// `MessageDeletedException` (own-deleted).
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  });

  /// **TASK37**: delete own message через Matrix `m.room.redaction`.
  /// Idempotent (already-deleted → success no-op). Returns void;
  /// SDK получит `messageDeleted` event через realtime `/sync`.
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  });

  /// **B9 typing indicator**: PUT m.typing для текущего юзера в room.
  /// Best-effort — server игнорирует network/Matrix errors. Auto-gases
  /// в Matrix через 30s timeout.
  Future<void> sendTyping({required int roomId, required bool typing});

  /// **Emoji reactions**: поставить реакцию `key` (emoji) на сообщение
  /// `targetEventId`. Возвращает matrixEventId самого `m.reaction`
  /// event-а — controller хранит его для toggle-off.
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  });

  /// **Emoji reactions**: снять свою реакцию через redaction
  /// reaction-event-а `reactionEventId`. Idempotent.
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  });

  /// **Reactions history (phase 2)**: существующие реакции для списка
  /// message `eventIds` как `reactionChanged`-add events. Controller
  /// скармливает их в тот же aggregation-путь после `listMessages` —
  /// реакции видны сразу при открытии чата. Пустой `eventIds` → [].
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  });

  /// **B17 search in messages**: keyword-поиск через Matrix `/search`.
  /// Empty/short query (< 2 chars) → пустой list. Server-side limit
  /// clamp 1..200. Result отсортирован `recent` (newest first).
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit,
  });
}

/// Production-wrapper над `Client.messenger.*`.
///
/// **TASK20 followup (α)**: каждый RPC оборачивается в [withAuthRetry]
/// для self-heal на типизированную auth-invalidation
/// ([MessengerNotAuthenticatedException] / [InvalidTokenException] на
/// 200-ответе, который Serverpod 401-retry pipeline НЕ перехватывает).
/// [MessengerSessionManager] резолвится лениво через
/// [MessengerRuntime.instance.sessionManager].
class ClientMessagesRpc implements MessagesRpc {
  ClientMessagesRpc(this._client);
  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) => withAuthRetry(
    () => _client.messenger.listMessages(
      roomId: roomId,
      fromToken: fromToken,
      limit: limit,
    ),
    _session,
  );

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  }) => withAuthRetry(
    () => _client.messenger.sendMessage(
      roomId: roomId,
      body: body,
      msgType: msgType,
      clientTxnId: clientTxnId,
      attachment: attachment,
      replyToMatrixEventId: replyToMatrixEventId,
      mentionedMessengerUserIds: mentionedMessengerUserIds,
    ),
    _session,
  );

  @override
  Future<bool> markRead({required int roomId, required String matrixEventId}) =>
      withAuthRetry(
        () => _client.messenger.markRead(
          roomId: roomId,
          matrixEventId: matrixEventId,
        ),
        _session,
      );

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => withAuthRetry(
    () => _client.messenger.uploadAttachment(
      bytes: bytes,
      mimeType: mimeType,
      originalFilename: originalFilename,
    ),
    _session,
  );

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => withAuthRetry(
    () => _client.messenger.downloadAttachmentThumbnail(
      mxcUrl: mxcUrl,
      width: width,
      height: height,
    ),
    _session,
  );

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) =>
      withAuthRetry(
        () => _client.messenger.downloadAttachment(mxcUrl: mxcUrl),
        _session,
      );

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => withAuthRetry(
    () => _client.messenger.editMessage(
      roomId: roomId,
      matrixEventId: matrixEventId,
      newBody: newBody,
      mentionedMessengerUserIds: mentionedMessengerUserIds,
    ),
    _session,
  );

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => withAuthRetry(
    () => _client.messenger.deleteMessage(
      roomId: roomId,
      matrixEventId: matrixEventId,
    ),
    _session,
  );

  @override
  Future<void> sendTyping({
    required int roomId,
    required bool typing,
  }) => withAuthRetry(
    () => _client.messenger.sendTyping(roomId: roomId, typing: typing),
    _session,
  );

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) => withAuthRetry(
    () => _client.messenger.sendReaction(
      roomId: roomId,
      targetEventId: targetEventId,
      key: key,
    ),
    _session,
  );

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) => withAuthRetry(
    () => _client.messenger.removeReaction(
      roomId: roomId,
      reactionEventId: reactionEventId,
    ),
    _session,
  );

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) => withAuthRetry(
    () => _client.messenger.searchMessages(
      roomId: roomId,
      query: query,
      limit: limit,
    ),
    _session,
  );

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) => withAuthRetry(
    () => _client.messenger.listReactions(
      roomId: roomId,
      eventIds: eventIds,
    ),
    _session,
  );
}
