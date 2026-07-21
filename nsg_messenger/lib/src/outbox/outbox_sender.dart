import 'dart:async';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../cache/messenger_cache_store.dart';
import '../messages/messages_rpc.dart';
import '../messages/send_error_classifier.dart';
import 'outbox_item.dart';

/// **OUTBOX**: дефолтное расписание бэкоффа для транзиентных ошибок дренажа.
///
/// Длиннее, чем in-memory `kDefaultSendRetrySchedule` контроллера (тот ~1
/// минута, экран открыт), потому что персистентная очередь переживает kill и
/// длинный офлайн — она должна тихо ждать возврата сети часами. Индекс =
/// `attempts-1`; сверх последнего — берётся последний (5 минут).
const List<Duration> kOutboxBackoffSchedule = [
  Duration(seconds: 2),
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(minutes: 1),
  Duration(minutes: 2),
  Duration(minutes: 5),
];

/// **OUTBOX**: фоновый отправитель персистентной очереди исходящих.
///
/// Синглтон рантайма (`runtime.outbox`). Один активный дренаж (re-entrancy
/// lock): берёт due-строки FIFO по `createdAt`, шлёт через [MessagesRpc]
/// (вложение: файл с диска → `uploadAttachment` → `sendMessage(attachment:)`;
/// текст: `sendMessage`). Успех → удаляет строку и файл; транзиент → бэкофф;
/// перманент → `failed` (UI: повторить/удалить).
///
/// **Триггеры** (connectivity_plus в проекте намеренно выключен — вис на
/// Windows/iOS): [start] на init, [kick] на enqueue/resume, периодический
/// таймер (~20с) пока есть pending. Офлайн = RPC падает транзиентно → бэкофф
/// → уйдёт при возврате сети.
class OutboxSender {
  OutboxSender({
    required MessengerCacheStore store,
    required MessagesRpc rpc,
    List<Duration>? backoffSchedule,
    Duration pollInterval = const Duration(seconds: 20),
    Future<Directory> Function()? directoryResolver,
  }) : _store = store,
       _rpc = rpc,
       _backoff = backoffSchedule ?? kOutboxBackoffSchedule,
       _pollInterval = pollInterval,
       _directoryResolver = directoryResolver ?? _defaultOutboxDir;

  final MessengerCacheStore _store;
  final MessagesRpc _rpc;
  final List<Duration> _backoff;
  final Duration _pollInterval;
  final Future<Directory> Function() _directoryResolver;

  Future<void>? _active;
  bool _disposed = false;
  Timer? _timer;

  /// Дефолтный каталог персистентных копий вложений:
  /// `getApplicationSupportDirectory()/outbox`.
  static Future<Directory> _defaultOutboxDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'outbox'));
  }

  // ──────────────────────────────────────────── enqueue ──

  /// **OUTBOX**: поставить в очередь текстовое сообщение и разбудить дренаж.
  /// `msgType` по умолчанию `m.text`; композер может передать свой (TASK47
  /// handoff из `_shootSendRpc` сохраняет исходный тип).
  Future<void> enqueueText({
    required int roomId,
    required String clientTxnId,
    required String body,
    String msgType = 'm.text',
    List<int>? mentionedMessengerUserIds,
    String? replyToMatrixEventId,
  }) async {
    await _store.enqueueOutbox(
      OutboxItem(
        clientTxnId: clientTxnId,
        userId: _store.userId,
        roomId: roomId,
        kind: OutboxKind.text,
        body: body,
        msgType: msgType,
        mentionedMessengerUserIds: mentionedMessengerUserIds,
        replyToMatrixEventId: replyToMatrixEventId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    kick();
  }

  /// **OUTBOX**: поставить в очередь файл. Байты копируются в персистентный
  /// каталог (`<support>/outbox/<clientTxnId>`) — шаренный temp может
  /// исчезнуть до фактической отправки. Затем enqueue + kick.
  ///
  /// Несколько файлов одного share → один [albumId] (одно сообщение-мозаика).
  Future<void> enqueueFile({
    required int roomId,
    required String clientTxnId,
    required String sourcePath,
    required String msgType,
    String? mimeType,
    String? originalFilename,
    String? albumId,
  }) async {
    final persistentPath = await _copyToOutbox(clientTxnId, sourcePath);
    await _store.enqueueOutbox(
      OutboxItem(
        clientTxnId: clientTxnId,
        userId: _store.userId,
        roomId: roomId,
        kind: OutboxKind.attachment,
        body: originalFilename ?? p.basename(sourcePath),
        msgType: msgType,
        attachmentPath: persistentPath,
        mimeType: mimeType,
        originalFilename: originalFilename ?? p.basename(sourcePath),
        albumId: albumId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    kick();
  }

  Future<String> _copyToOutbox(String clientTxnId, String sourcePath) async {
    final dir = await _directoryResolver();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // Имя файла = clientTxnId (уникален); расширение исходника сохраняем для
    // диагностики, но оно не критично (MIME хранится в строке отдельно).
    final ext = p.extension(sourcePath);
    final dest = p.join(dir.path, '$clientTxnId$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  // ──────────────────────────────────────────── triggers ──

  /// Разбудить дренаж после готовности сессии (init). Идемпотентно.
  void start() => kick();

  /// Разбудить дренаж (enqueue / app-resume / внешний триггер). Fire-and-
  /// forget: если дренаж уже идёт — переиспользуем активный проход.
  void kick() {
    if (_disposed) return;
    unawaited(_ensureDrain());
  }

  /// **@visibleForTesting** / init: дождаться полного прохода дренажа (в т.ч.
  /// уже идущего).
  Future<void> flush() => _ensureDrain();

  // ──────────────────────────────────────────── drain ──

  /// Single active drain (re-entrancy lock): если проход уже идёт — вернуть
  /// его future (не запускать второй параллельно).
  Future<void> _ensureDrain() {
    if (_disposed) return Future<void>.value();
    return _active ??= _runDrain().whenComplete(() => _active = null);
  }

  Future<void> _runDrain() async {
    // Каждый due-item обрабатываем НЕ БОЛЕЕ одного раза за проход: после
    // транзиентной ошибки бэкофф может оказаться в прошлом (короткий),
    // и без этого гарда мы бы крутили тот же item в бесконечном цикле.
    // Повторная попытка — на следующий kick / тик таймера.
    final attempted = <String>{};
    try {
      while (!_disposed) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final due = await _store.outboxDue(now);
        OutboxItem? next;
        for (final item in due) {
          if (!attempted.contains(item.clientTxnId)) {
            next = item;
            break;
          }
        }
        if (next == null) break;
        attempted.add(next.clientTxnId);
        await _sendOne(next);
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[OutboxSender] drain error: $e\n$st');
    }
    await _rescheduleTimer();
  }

  Future<void> _sendOne(OutboxItem item) async {
    await _store.markOutboxSending(item.clientTxnId);
    try {
      if (item.isAttachment) {
        await _sendAttachment(item);
      } else {
        await _rpc.sendMessage(
          roomId: item.roomId,
          body: item.body,
          msgType: item.msgType,
          clientTxnId: item.clientTxnId,
          mentionedMessengerUserIds: item.mentionedMessengerUserIds,
          replyToMatrixEventId: item.replyToMatrixEventId,
        );
      }
      // Success → удалить файл + строку. Реальное событие приедет через
      // sync и промоутит pending-пузырь по clientTxnId.
      await _deleteFileFor(item);
      await _store.deleteOutbox(item.clientTxnId);
    } catch (e, st) {
      if (_disposed) return;
      if (isTransientSendError(e)) {
        final attempts = item.attempts + 1;
        final delay = _backoffFor(attempts);
        final nextAt = DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds;
        await _store.markOutboxBackoff(
          item.clientTxnId,
          attempts: attempts,
          nextAttemptAt: nextAt,
          lastError: e.toString(),
        );
        if (kDebugMode) {
          debugPrint(
            '[OutboxSender] transient (txn=${item.clientTxnId}) '
            'attempt=$attempts retry in ${delay.inSeconds}s: $e',
          );
        }
      } else {
        // Перманент (4xx/доменная/файл пропал) → failed (UI: retry/discard).
        await _store.markOutboxFailed(
          item.clientTxnId,
          lastError: e.toString(),
        );
        if (kDebugMode) {
          debugPrint(
            '[OutboxSender] permanent fail (txn=${item.clientTxnId}): $e\n$st',
          );
        }
      }
    }
  }

  Future<void> _sendAttachment(OutboxItem item) async {
    final path = item.attachmentPath;
    if (path == null) {
      throw StateError('outbox attachment без attachmentPath');
    }
    final bytes = await File(path).readAsBytes();
    final ref = await _rpc.uploadAttachment(
      bytes: ByteData.sublistView(bytes),
      mimeType: (item.mimeType != null && item.mimeType!.isNotEmpty)
          ? item.mimeType!
          : 'application/octet-stream',
      originalFilename: item.originalFilename ?? 'file',
    );
    await _rpc.sendMessage(
      roomId: item.roomId,
      body: ref.originalFilename,
      msgType: _msgTypeForMime(ref.mimeType),
      clientTxnId: item.clientTxnId,
      attachment: ref,
      albumId: item.albumId,
      mentionedMessengerUserIds: item.mentionedMessengerUserIds,
      replyToMatrixEventId: item.replyToMatrixEventId,
    );
  }

  Duration _backoffFor(int attempts) {
    final idx = (attempts - 1).clamp(0, _backoff.length - 1);
    return _backoff[idx];
  }

  static String _msgTypeForMime(String mime) {
    if (mime.startsWith('image/')) return 'm.image';
    if (mime.startsWith('video/')) return 'm.video';
    if (mime.startsWith('audio/')) return 'm.audio';
    return 'm.file';
  }

  // ──────────────────────────────────────────── UI ops ──

  /// **OUTBOX**: ручной retry failed-строки — вернуть в pending с
  /// `nextAttemptAt=0` и разбудить дренаж.
  Future<void> retry(String clientTxnId) async {
    await _store.resetOutboxForRetry(clientTxnId);
    kick();
  }

  /// **OUTBOX**: discard строки (удалить файл + строку). Для failed/pending.
  Future<void> discard(String clientTxnId) async {
    final rows = await _store.allOutbox();
    OutboxItem? item;
    for (final r in rows) {
      if (r.clientTxnId == clientTxnId) {
        item = r;
        break;
      }
    }
    if (item != null) await _deleteFileFor(item);
    await _store.deleteOutbox(clientTxnId);
  }

  Future<void> _deleteFileFor(OutboxItem item) async {
    final path = item.attachmentPath;
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // best-effort — осиротевший файл подчистится при следующем cleanup.
    }
  }

  // ──────────────────────────────────────────── timer ──

  Future<void> _rescheduleTimer() async {
    if (_disposed) return;
    List<OutboxItem> all;
    try {
      all = await _store.allOutbox();
    } catch (_) {
      return;
    }
    final hasPending = all.any((i) => i.status == OutboxStatus.pending);
    if (hasPending) {
      _timer ??= Timer.periodic(_pollInterval, (_) => kick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
