import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messages/attachments/attachment_picker.dart' show guessMimeFromExtension;
import '../messages/messages_rpc.dart';
import '../messenger_runtime.dart';
import '../rooms/room_picker_sheet.dart';
import '../screens/chat_screen.dart';
import '../theme/messenger_theme_scope.dart';
import 'share_limits.dart';
import 'shared_payload.dart';

/// **TASK49 (share-in)**: одноместный слот отложенного share-payload.
///
/// Payload может прийти, когда SDK ещё не готов принять его в UI (юзер не
/// залогинен / рантайм не инициализирован — §3.5). Его нельзя терять молча:
/// держим здесь ОДИН payload (MVP без очереди) и отдаём, как только host
/// дёрнет flush после успешного входа.
///
/// Второй входящий payload при занятом слоте — перезаписывает (последний
/// шаринг важнее; очередь — не в MVP). Чистый класс без Flutter-зависимостей
/// — покрыт юнит-тестами.
class SharePendingSlot {
  SharedPayload? _pending;

  /// Есть ли отложенный payload.
  bool get hasPending => _pending != null;

  /// Отложить payload (перезаписывает предыдущий, если был).
  void store(SharedPayload payload) {
    _pending = payload;
  }

  /// Забрать отложенный payload (и очистить слот). `null`, если пусто.
  SharedPayload? take() {
    final p = _pending;
    _pending = null;
    return p;
  }

  /// Сбросить слот без выдачи (напр. на logout).
  void clear() {
    _pending = null;
  }
}

/// **TASK49**: один шаг отправки share (sealed): файл или текст.
@immutable
sealed class ShareSendStep {
  const ShareSendStep();
}

/// Шаг: отправить файл через attachment-пайплайн.
@immutable
class ShareFileStep extends ShareSendStep {
  const ShareFileStep(this.file);
  final SharedFile file;
}

/// Шаг: отправить текст отдельным сообщением.
@immutable
class ShareTextStep extends ShareSendStep {
  const ShareTextStep(this.text);
  final String text;
}

/// **TASK49**: чистое планирование порядка отправки (§3.4).
///
/// Правило: сначала ВСЕ файлы (последовательно, с прогрессом), затем — текст
/// ОТДЕЛЬНЫМ сообщением ПОСЛЕ файлов (caption-в-медиа — итерация 2). Если
/// файлов нет — только текст; если текста нет — только файлы.
///
/// Вынесено из UI, чтобы «текст после файлов» покрыть юнит-тестом.
List<ShareSendStep> planShareSend(SharedPayload payload) {
  final steps = <ShareSendStep>[];
  for (final f in payload.files) {
    steps.add(ShareFileStep(f));
  }
  if (payload.hasText) {
    steps.add(ShareTextStep(payload.text!.trim()));
  }
  return steps;
}

/// Matrix msgType по MIME (сервер тоже деривит из attachment, но передаём
/// корректный для консистентности с обычным send-path).
String _shareMsgTypeForMime(String mime) {
  if (mime.startsWith('image/')) return 'm.image';
  if (mime.startsWith('video/')) return 'm.video';
  return 'm.file';
}

int _shareTxnSeq = 0;

/// Уникальный clientTxnId для share-send (server-side dedup по нему).
String _shareTxnId() => 'share-${DateTime.now().microsecondsSinceEpoch}-${_shareTxnSeq++}';

/// Является ли шаренный файл изображением (для album-группировки). MIME
/// берётся из payload либо выводится из имени/пути.
bool shareFileIsImage(SharedFile f) {
  final mime = (f.mimeType != null && f.mimeType!.isNotEmpty)
      ? f.mimeType!
      : guessMimeFromExtension(f.name ?? f.path);
  return mime.startsWith('image/');
}

/// **OUTBOX / album-планирование**: общий `albumId` для мульти-фото share.
///
/// Правило (§4): если шарятся ≥2 изображения — им присваивается ОДИН общий
/// id (одно сообщение-мозаика). Одиночная картинка / файлы без картинок /
/// один-image+файлы → `null` (обычные одиночные сообщения). Не-image файлы
/// в альбом не входят даже при активном id (см. [runShareInFlow]).
///
/// Чистая функция (вынесена из UI для юнит-теста). [genId] генерирует id
/// только когда он реально нужен.
String? shareAlbumIdForPayload(
  SharedPayload payload, {
  required String Function() genId,
}) {
  final imageCount = payload.files.where(shareFileIsImage).length;
  return imageCount > 1 ? genId() : null;
}

/// **TASK49 (share-in)**: запустить flow «Куда отправить?» для [payload].
///
/// Шаги (§3):
///   1. Пикер чата (переиспользует forward-picker core: поиск + сортировка
///      по активности) → выбранная комната.
///   2. Превью того, что отправляем (текст и/или число файлов) → подтверждение.
///   3. Последовательная отправка: файлы → attachment-пайплайн (с прогрессом),
///      затем текст → отдельным сообщением ([planShareSend]).
///   4. Переход в целевой чат + snackbar (успех / часть не отправилась).
///
/// [roomsLoader] — точка подмены списка чатов для тестов (по умолчанию
/// `rooms.list`). **Отправка идёт через персистентный OUTBOX** ([OutboxSender]
/// в `runtime.outbox`): контент enqueue-ится (файлы копируются в персистентный
/// каталог), а фоновый sender доставляет их с ретраем — переживая офлайн И
/// kill/restart приложения. UI-«прогресс» теперь = быстрый enqueue.
///
/// **Album-группировка**: если шарятся ≥2 изображения — им присваивается один
/// `albumId` (одно сообщение-мозаика). Текст (если есть) enqueue-ится
/// ОТДЕЛЬНОЙ строкой ПОСЛЕ файлов (см. [planShareSend], §3.4).
///
/// Fallback: если outbox выключен (кэш недоступен — web / host отключил),
/// откатываемся к прямому await-ящему RPC-пути (без персистентности).
///
/// Ничего не бросает — все ошибки конвертируются в snackbar.
Future<void> runShareInFlow(
  BuildContext context,
  SharedPayload payload, {
  Future<List<RoomSummary>> Function()? roomsLoader,
}) async {
  if (payload.isEmpty) return;
  final l = NsgL10n.of(context);
  final theme = MessengerRuntime.instance.theme;

  // 1. Выбор чата (то же ядро, что forward-пикер).
  final room = await showRoomPicker(
    context: context,
    title: l.sharePickerTitle,
    searchHint: l.forwardSearchHint,
    emptyText: l.forwardNoRooms,
    errorText: l.forwardFailed,
    roomsLoader: roomsLoader,
  );
  if (room == null) return;
  if (!context.mounted) return;

  // 2. Превью + подтверждение — bottom-sheet (современный Apple-стиль:
  //    весь flow «пикер → подтверждение → прогресс» выезжает снизу, как
  //    системный share sheet; центр--AlertDialog убран по итогам
  //    девайс-смоука TASK49).
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) => MessengerThemeScope(
      theme: theme,
      child: _SharePreviewSheet(payload: payload, room: room),
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final runtime = MessengerRuntime.instance;
  final outbox = runtime.outbox;

  final steps = planShareSend(payload);
  final progress = ValueNotifier<int>(0);
  final tooLargeNames = <String>[];
  final enqueueFailures = <Object>[];

  // **Album-группировка**: ≥2 изображения → один общий albumId (одно
  // сообщение-мозаика). Одиночная картинка / файлы — без albumId.
  final albumId = shareAlbumIdForPayload(payload, genId: _shareTxnId);

  // Прогресс — такой же bottom-sheet (не закрываемый свайпом/тапом), в
  // одном визуальном ряду с пикером и подтверждением. Enqueue быстр, но
  // копия файла на диск может занять момент на больших вложениях.
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (dialogCtx) => MessengerThemeScope(
        theme: theme,
        child: _ShareProgressSheet(total: steps.length, progress: progress),
      ),
    ),
  );

  // Fallback-RPC создаём лениво только если outbox выключен.
  ClientMessagesRpc? fallbackRpc;
  ClientMessagesRpc rpc() => fallbackRpc ??= ClientMessagesRpc(runtime.client);

  try {
    for (final step in steps) {
      switch (step) {
        case ShareFileStep(:final file):
          try {
            final mime = (file.mimeType != null && file.mimeType!.isNotEmpty)
                ? file.mimeType!
                : guessMimeFromExtension(file.name ?? file.path);
            final size = await File(file.path).length();
            validateShareFileSize(
              sizeBytes: size,
              mimeType: mime,
              name: file.name,
            );
            final msgType = _shareMsgTypeForMime(mime);
            final fileAlbumId = mime.startsWith('image/') ? albumId : null;
            // (mime.startsWith('image/') эквивалентно shareFileIsImage здесь —
            //  mime уже разрезолвен выше.)
            if (outbox != null) {
              await outbox.enqueueFile(
                roomId: room.id,
                clientTxnId: _shareTxnId(),
                sourcePath: file.path,
                msgType: msgType,
                mimeType: mime,
                originalFilename: file.name,
                albumId: fileAlbumId,
              );
            } else {
              // Fallback: прямой upload → send (без персистентности).
              final bytes = await File(file.path).readAsBytes();
              final ref = await rpc().uploadAttachment(
                bytes: ByteData.sublistView(bytes),
                mimeType: mime,
                originalFilename: file.name ?? 'file',
              );
              await rpc().sendMessage(
                roomId: room.id,
                body: ref.originalFilename,
                msgType: _shareMsgTypeForMime(ref.mimeType),
                clientTxnId: _shareTxnId(),
                attachment: ref,
                albumId: fileAlbumId,
              );
            }
          } on SharedFileTooLargeException {
            tooLargeNames.add(file.name ?? file.path);
          } catch (e) {
            enqueueFailures.add(e);
          }
        case ShareTextStep(:final text):
          try {
            if (outbox != null) {
              await outbox.enqueueText(
                roomId: room.id,
                clientTxnId: _shareTxnId(),
                body: text,
              );
            } else {
              await rpc().sendMessage(
                roomId: room.id,
                body: text,
                msgType: 'm.text',
                clientTxnId: _shareTxnId(),
              );
            }
          } catch (e) {
            enqueueFailures.add(e);
          }
      }
      progress.value = progress.value + 1;
    }
  } finally {
    // Закрыть модалку прогресса.
    if (navigator.canPop()) navigator.pop();
    progress.dispose();
  }

  // 4. Навигация в чат + итоговый snackbar. Outbox доставит в фоне —
  //    pending-бабблы уже видны в чате (MessagesController рендерит очередь).
  //
  //    ВАЖНО: push БЕЗ await. Иначе flow (и guard `shareFlowActive`) висит
  //    активным, пока пользователь не выйдет из чата, и повторный share в
  //    это время молча отбивается «отправка ещё идёт» (payload теряется) —
  //    воспроизведено на девайс-смоуке TASK49. Снекбар показываем сразу
  //    поверх открывшегося чата, а не после возврата из него.
  unawaited(
    navigator.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: 'chat/${room.id}'),
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: ChatScreen(roomId: room.id),
        ),
      ),
    ),
  );

  if (tooLargeNames.isNotEmpty) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.shareFileTooLarge(tooLargeNames.join(', '))),
        duration: const Duration(seconds: 4),
      ),
    );
  } else if (enqueueFailures.isNotEmpty) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.shareSomeFailed),
        duration: const Duration(seconds: 3),
      ),
    );
  } else {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.shareQueued),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Превью-шит «Отправить в …?»: bottom-sheet в стиле системного share sheet
/// (drag handle, карточка-превью, крупная pill-кнопка на всю ширину).
/// Заменил центр-AlertDialog (архаично + на glass-теме просвечивал).
class _SharePreviewSheet extends StatelessWidget {
  const _SharePreviewSheet({required this.payload, required this.room});

  final SharedPayload payload;
  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final roomName = room.name ?? l.roomSummaryNoName;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.shareConfirmTitle(roomName),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (payload.hasFiles)
              Padding(
                padding: EdgeInsets.only(bottom: payload.hasText ? 10 : 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l.shareConfirmFiles(payload.files.length),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (payload.hasText)
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    payload.text!.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.shareSend),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.commonCancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Шит прогресса последовательной постановки в очередь (не закрываемый).
class _ShareProgressSheet extends StatelessWidget {
  const _ShareProgressSheet({required this.total, required this.progress});

  final int total;
  final ValueListenable<int> progress;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: progress,
                  builder: (context, done, _) {
                    final current = (done + 1).clamp(1, total);
                    return Text(l.shareProgress(current, total));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
