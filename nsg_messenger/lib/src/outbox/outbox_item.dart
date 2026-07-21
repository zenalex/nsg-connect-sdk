import 'dart:convert';

import 'package:flutter/foundation.dart';

/// **OUTBOX**: вид элемента очереди — текстовое сообщение или вложение.
///
///   * [text] — обычное `m.text`-сообщение (текст/URL из share);
///   * [attachment] — файл: сначала `uploadAttachment` (байты берутся из
///     [OutboxItem.attachmentPath]), затем `sendMessage(attachment:)`.
class OutboxKind {
  OutboxKind._();
  static const String text = 'text';
  static const String attachment = 'attachment';
}

/// **OUTBOX**: статус элемента очереди.
///
///   * [pending] — ждёт отправки (или бэкоффа после транзиентной ошибки);
///   * [sending] — сейчас обрабатывается дренажом (re-entrancy guard);
///   * [failed] — перманентная ошибка (4xx/доменная) → UI показывает
///     «повторить»/«удалить».
class OutboxStatus {
  OutboxStatus._();
  static const String pending = 'pending';
  static const String sending = 'sending';
  static const String failed = 'failed';
}

/// **OUTBOX**: одна строка персистентной очереди исходящих сообщений.
///
/// Пишется в sqflite-таблицу `outbox` (см. [MessengerCacheStore]) в момент,
/// когда пользователь «отправил» контент. [OutboxSender] дренажит очередь в
/// фоне с ретраем — доставка переживает офлайн И kill/restart приложения.
///
/// **Идентичность** — [clientTxnId]: сервер дедупит по нему (TASK09), а
/// оптимистичный UI матчит по нему pending-бабблы с реальными событиями.
@immutable
class OutboxItem {
  const OutboxItem({
    required this.clientTxnId,
    required this.userId,
    required this.roomId,
    required this.kind,
    required this.createdAt,
    this.body = '',
    this.msgType = 'm.text',
    this.attachmentPath,
    this.mimeType,
    this.originalFilename,
    this.albumId,
    this.mentionedMessengerUserIds,
    this.replyToMatrixEventId,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    this.nextAttemptAt = 0,
    this.lastError,
  });

  /// Server-side dedup + реконсиляция с оптимистичным пузырём.
  final String clientTxnId;

  /// Владелец очереди (скоуп мультиаккаунта, как в cache-таблицах).
  final int userId;

  final int roomId;

  /// [OutboxKind.text] | [OutboxKind.attachment].
  final String kind;

  final String body;

  /// Matrix msgType: `m.text` | `m.image` | `m.video` | `m.file`.
  final String msgType;

  /// Персистентная копия файла (для [OutboxKind.attachment]). Удаляется при
  /// успешной отправке / discard.
  final String? attachmentPath;
  final String? mimeType;
  final String? originalFilename;

  /// Общий id для мульти-фото → одно сообщение-мозаика.
  final String? albumId;

  final List<int>? mentionedMessengerUserIds;
  final String? replyToMatrixEventId;

  /// [OutboxStatus.pending] | [OutboxStatus.sending] | [OutboxStatus.failed].
  final String status;

  final int attempts;

  /// Epoch ms; бэкофф — до этого времени due-выборка строку не отдаёт.
  final int nextAttemptAt;
  final String? lastError;

  /// Epoch ms; FIFO-порядок дренажа per room.
  final int createdAt;

  bool get isAttachment => kind == OutboxKind.attachment;
  bool get isFailed => status == OutboxStatus.failed;

  OutboxItem copyWith({
    String? status,
    int? attempts,
    int? nextAttemptAt,
    Object? lastError = _sentinel,
  }) => OutboxItem(
    clientTxnId: clientTxnId,
    userId: userId,
    roomId: roomId,
    kind: kind,
    createdAt: createdAt,
    body: body,
    msgType: msgType,
    attachmentPath: attachmentPath,
    mimeType: mimeType,
    originalFilename: originalFilename,
    albumId: albumId,
    mentionedMessengerUserIds: mentionedMessengerUserIds,
    replyToMatrixEventId: replyToMatrixEventId,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: identical(lastError, _sentinel)
        ? this.lastError
        : lastError as String?,
  );

  /// Строка sqflite → модель. `mentionsJson` декодируется best-effort.
  factory OutboxItem.fromRow(Map<String, Object?> row) {
    final mentionsRaw = row['mentionsJson'] as String?;
    List<int>? mentions;
    if (mentionsRaw != null && mentionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(mentionsRaw);
        if (decoded is List) {
          mentions = decoded.whereType<int>().toList();
        }
      } catch (_) {
        mentions = null;
      }
    }
    return OutboxItem(
      clientTxnId: row['clientTxnId'] as String,
      userId: row['userId'] as int,
      roomId: row['roomId'] as int,
      kind: row['kind'] as String,
      body: (row['body'] as String?) ?? '',
      msgType: (row['msgType'] as String?) ?? 'm.text',
      attachmentPath: row['attachmentPath'] as String?,
      mimeType: row['mimeType'] as String?,
      originalFilename: row['originalFilename'] as String?,
      albumId: row['albumId'] as String?,
      mentionedMessengerUserIds: mentions,
      replyToMatrixEventId: row['replyToMatrixEventId'] as String?,
      status: (row['status'] as String?) ?? OutboxStatus.pending,
      attempts: (row['attempts'] as int?) ?? 0,
      nextAttemptAt: (row['nextAttemptAt'] as int?) ?? 0,
      lastError: row['lastError'] as String?,
      createdAt: (row['createdAt'] as int?) ?? 0,
    );
  }

  /// Модель → строка sqflite (для insert). `userId` проставляет store.
  Map<String, Object?> toRow() => {
    'clientTxnId': clientTxnId,
    'userId': userId,
    'roomId': roomId,
    'kind': kind,
    'body': body,
    'msgType': msgType,
    'attachmentPath': attachmentPath,
    'mimeType': mimeType,
    'originalFilename': originalFilename,
    'albumId': albumId,
    'mentionsJson': mentionedMessengerUserIds == null
        ? null
        : jsonEncode(mentionedMessengerUserIds),
    'replyToMatrixEventId': replyToMatrixEventId,
    'status': status,
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt,
    'lastError': lastError,
    'createdAt': createdAt,
  };

  static const Object _sentinel = Object();
}
