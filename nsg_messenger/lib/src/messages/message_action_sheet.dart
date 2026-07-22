import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import 'attachments/image_actions.dart';
import 'chat_message.dart';
import 'emoji_reaction_picker.dart';
import 'forward_picker_sheet.dart';
import 'message_share.dart';
import 'messages_controller.dart';

/// Bottom-sheet с per-message actions (Edit / Delete / Copy) — TASK37
/// Chunk 2. Pattern reused from `room_action_sheet.dart` (TASK42).
///
/// **Authorization (Q2 sign-off — own only)**:
///   * Edit / Delete — visible только для `isOwn && !isDeleted &&
///     msg.isSent` (нет stable matrixEventId-а до RPC return для
///     pending/failed). Server enforces real authorization; client-
///     side проверки — UI affordance, не security boundary.
///   * Copy — always-enabled (Q4 sign-off). Empty body → copy
///     attachment filename как fallback.
///
/// **Не блокирует bubble** при не-Ready states — caller (`MessageBubble.
/// onLongPress`) уже фильтрует pending/failed/deleted.
Future<void> showMessageActionSheet({
  required BuildContext context,
  required ChatMessage message,
  required bool isOwn,
  required MessagesController controller,
  void Function(ChatMessage message)? onStartEdit,
  void Function(ChatMessage message)? onSelectMessage,
  void Function(ChatMessage message)? onReplyWithMention,
  ImageActions? imageActions,
  bool canPin = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => _MessageActionSheetBody(
      message: message,
      isOwn: isOwn,
      controller: controller,
      onStartEdit: onStartEdit,
      onSelectMessage: onSelectMessage,
      onReplyWithMention: onReplyWithMention,
      imageActions: imageActions,
      canPin: canPin,
    ),
  );
}

/// **Emoji reactions**: фиксированный набор быстрых реакций (MVP — без
/// полного picker-а). Telegram/Slack-style quick row.
const List<String> kQuickReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class _MessageActionSheetBody extends StatelessWidget {
  const _MessageActionSheetBody({
    required this.message,
    required this.isOwn,
    required this.controller,
    this.onStartEdit,
    this.onSelectMessage,
    this.onReplyWithMention,
    this.imageActions,
    this.canPin = false,
  });

  final ChatMessage message;
  final bool isOwn;
  final MessagesController controller;

  /// **Issue #35**: показывать ли пункт «Закрепить»/«Открепить». ChatScreen
  /// вычисляет по типу комнаты + роли viewer-а (direct — всегда; группы —
  /// admin/owner). Сам pin/unpin ещё раз проверяется сервером.
  final bool canPin;

  /// Share/copy-действия для картинок. `null` → строим из
  /// `controller.downloadFullSize` (прод); тесты инъектят фейк.
  final ImageActions? imageActions;

  /// **TASK69 2C**: если задан — показывается пункт «Ответить с упоминанием»
  /// (reply + @автор в композере). ChatScreen прокидывает его только для
  /// групп и чужих сообщений (в 1:1 и для своих упоминание избыточно).
  final void Function(ChatMessage message)? onReplyWithMention;

  /// Если задан — «Изменить» открывает редактирование **в композере**
  /// (inline edit-mode, тот же ввод/визуал что и новое сообщение) вместо
  /// legacy-диалога. ChatScreen передаёт `(m) => _editTarget.value = m`.
  final void Function(ChatMessage message)? onStartEdit;

  /// **Пересылка (мультивыбор)**: если задан — показывается пункт «Выбрать»,
  /// который включает режим множественного выбора в ChatScreen (стартуя с
  /// этого сообщения). `null` → пункт скрыт (напр. demo без host-обвязки).
  final void Function(ChatMessage message)? onSelectMessage;

  /// Отправить в трекер ошибку действия над сообщением, которую увидел
  /// пользователь. Тег [action] отделяет пути друг от друга.
  ///
  /// Ожидаемый отказ репортить не надо: «интеграция не настроена»
  /// ([TaskIntegrationNotConfiguredException]) ловится отдельной `on`-веткой —
  /// это конфиг тенанта, а не баг.
  void _reportActionFailed(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'message.action': action},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    // **OUTBOX**: сообщение ещё не на сервере (нет stable matrixEventId) —
    // весь основной набор ниже для него неприменим: Reply/Forward/Pin/
    // CreateTask требуют event id, Edit/Delete физически нечего править.
    // Отдельный компактный шит: повторить / отменить отправку / копировать.
    if (message.matrixEventId == null) {
      return _buildQueuedSheet(context, l);
    }
    // **Emoji reactions**: quick-react row доступен только для сообщений
    // с stable matrixEventId (sent, non-tombstone). Pending/failed/
    // deleted — нет id для реакции.
    final canReact = !message.isDeleted && message.matrixEventId != null;
    // Скролл обязателен: на десктопе (невысокое окно) шит обрезается по
    // высоте, и нижние пункты («Копировать» и далее) были недостижимы.
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReact)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in kQuickReactionEmojis)
                      InkResponse(
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.toggleReaction(
                            message.matrixEventId!,
                            emoji,
                          );
                        },
                        radius: 24,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    // **F2 ч.1**: «+» → полный emoji-picker (за пределами
                    // быстрого ряда). Пикер открывается ПОВЕРХ этого шита
                    // (context валиден); на выборе — закрываем шит и ставим
                    // реакцию, на отмене — шит остаётся.
                    InkResponse(
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final picked = await showEmojiReactionPicker(context);
                        if (picked == null) return;
                        navigator.pop();
                        controller.toggleReaction(
                          message.matrixEventId!,
                          picked,
                        );
                      },
                      radius: 24,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_reaction_outlined,
                          size: 26,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (canReact) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l.messageActionSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // **TASK16-A**: Reply visible для всех non-tombstone (Q4
            // sign-off — own AND peer messages reply-able). Tombstone
            // отфильтрован вызовом showMessageActionSheet (long-press
            // disabled на bubble) — defense только UI affordance.
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: Text(l.messageActionReply),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.setReplyTarget(message);
                },
              ),
            // **TASK69 2C**: «Ответить с упоминанием» — reply + @автор в
            // композере. Только для групп/чужих (гейт в ChatScreen через
            // наличие onReplyWithMention).
            if (!message.isDeleted && onReplyWithMention != null)
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(l.messageActionReplyWithMention),
                onTap: () {
                  final cb = onReplyWithMention!;
                  Navigator.of(context).pop();
                  cb(message);
                },
              ),
            // **Issue #35**: закрепить / открепить сообщение. Видно если у
            // viewer-а есть права (canPin — direct всегда, группы admin/owner)
            // и есть stable matrixEventId (sent, non-tombstone). Toggle Pin/
            // Unpin по текущему состоянию `controller.isPinned`.
            if (canPin && !message.isDeleted && message.matrixEventId != null)
              Builder(
                builder: (context) {
                  final pinned = controller.isPinned(message.matrixEventId!);
                  return ListTile(
                    leading: Icon(
                      pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    ),
                    title: Text(
                      pinned ? l.messageActionUnpin : l.messageActionPin,
                    ),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final l = NsgL10n.of(context);
                      final eventId = message.matrixEventId!;
                      navigator.pop();
                      await _handlePinToggle(messenger, l, eventId, pinned);
                    },
                  );
                },
              ),
            // «Копировать» — самый частый пункт, держим наверху (раньше был
            // внизу и на десктопе обрезался высотой шита).
            _copyTile(context, l),
            // **Скопировать изображение** — для сообщений-картинок (запрос
            // постановщика: картинку из сообщения нельзя было скопировать).
            // Кладёт картинку в буфер обмена (desktop — bitmap/файл, mobile/
            // web — bitmap). Расшаривание наружу — отдельный пункт «Поделиться».
            if (!message.isDeleted && _isImageAttachment(message))
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l.messageActionCopyImage),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final l = NsgL10n.of(context);
                  final att = message.attachment!;
                  navigator.pop();
                  final actions =
                      imageActions ??
                      ImageActions.fromDownloader(controller.downloadFullSize);
                  try {
                    await actions.copyImage(att);
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(l.imageCopiedSnack),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } catch (e, st) {
                    _reportActionFailed(e, st, 'copyImage');
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(l.imageCopyFailed),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            // **Пересылка (forward)** — внутренний пикер чата → перенос
            // сообщения/альбома в целевую комнату. Visible для non-deleted
            // (own И peer, как Reply).
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.forward_outlined),
                title: Text(l.messageActionForward),
                onTap: () async {
                  // navigator/messenger захватываем ДО pop (context листа
                  // после pop недействителен). `l` из build — просто объект
                  // локализации, живёт после pop.
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  navigator.pop();
                  // **F1**: мультивыбор целевых чатов — переслать во все.
                  final rooms = await showForwardPickerMulti(
                    context: navigator.context,
                  );
                  if (rooms == null || rooms.isEmpty) return;
                  try {
                    await controller.forwardMessagesToRooms(
                      targetRoomIds: rooms
                          .map((r) => r.id)
                          .toList(growable: false),
                      messages: [message],
                    );
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(l.forwardedToChatsSnack(rooms.length)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } catch (e, st) {
                    _reportActionFailed(e, st, 'forward');
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(l.forwardFailed),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            // **Пересылка (мультивыбор)** — войти в режим выбора нескольких
            // сообщений (Telegram-style) и переслать их пачкой. Видно только
            // если host прокинул колбэк (ChatScreen). Как Forward — для
            // non-deleted (own И peer).
            if (!message.isDeleted && onSelectMessage != null)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l.messageActionSelect),
                onTap: () {
                  final navigator = Navigator.of(context);
                  final cb = onSelectMessage!;
                  navigator.pop();
                  cb(message);
                },
              ),
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l.messageActionEdit),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final startEdit = onStartEdit;
                  navigator.pop();
                  // Предпочитаем inline-редактирование в композере (красиво +
                  // удобно для длинных сообщений, тот же механизм ввода).
                  // Fallback на legacy-диалог — если host не прокинул callback
                  // (напр. в старых тестах).
                  if (startEdit != null) {
                    startEdit(message);
                  } else {
                    await _handleEdit(context);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l.messageActionDelete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  await _handleDelete(context);
                },
              ),
            ],
            // **Внешняя пересылка (share наружу)** — системный share sheet
            // (share_plus): текст / картинки в другие приложения. Visible для
            // non-deleted.
            if (!message.isDeleted)
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(l.messageActionShare),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  navigator.pop();
                  try {
                    await MessageSharer(controller).share(message);
                  } catch (e, st) {
                    _reportActionFailed(e, st, 'share');
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(l.shareFailed),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            // **TASK38**: создать задачу из сообщения. Visible только если
            // tenant настроил task-интеграцию (controller.taskIntegrationEnabled
            // — gated server-side, SDK общий со студенческими аппами) и есть
            // stable matrixEventId (sent, non-tombstone).
            if (controller.taskIntegrationEnabled &&
                !message.isDeleted &&
                message.matrixEventId != null)
              ListTile(
                leading: const Icon(Icons.add_task_outlined),
                title: Text(l.messageActionCreateTask),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final l = NsgL10n.of(context);
                  final eventId = message.matrixEventId!;
                  navigator.pop();
                  await _handleCreateTask(messenger, l, eventId);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// «Копировать» — общий пункт для обоих наборов (отправленное и очередь).
  /// Для вложения `body` — имя файла, что и нужно скопировать.
  Widget _copyTile(BuildContext context, NsgL10n l) => ListTile(
    leading: const Icon(Icons.copy_outlined),
    title: Text(l.messageActionCopy),
    onTap: () async {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      navigator.pop();
      await Clipboard.setData(ClipboardData(text: message.body));
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.messageCopiedSnack),
          duration: const Duration(seconds: 2),
        ),
      );
    },
  );

  /// **OUTBOX**: шит для сообщения, которое ещё НЕ ушло на сервер —
  /// строки персистентной очереди (`enqueueText`/`enqueueFile`, в т.ч. из
  /// Share Extension) и in-memory failed-бабблы.
  ///
  /// До этого long-press на таком пузыре не открывался вообще, а единственной
  /// affordance была кнопка «!» — которой у зависшего в бэкоффе (pending)
  /// item-а нет. Отменить отправку было нельзя ничем: файл висел «в отправке»
  /// неделями.
  ///
  /// «Повторить» для строки очереди идёт через [MessagesController.retryOutbox]
  /// (сброс бэкоффа + kick дренажа), а не через in-memory `retry` — см. doc
  /// у `retry` про то, чем это кончалось для вложений. «Отменить отправку» —
  /// только для строки очереди: у in-memory баббла удалять нечего.
  Widget _buildQueuedSheet(BuildContext context, NsgL10n l) {
    final theme = Theme.of(context);
    final txnId = message.clientTxnId;
    final isQueued = controller.isOutboxTxn(txnId);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l.messageActionSheetTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            // Повторять есть что либо у строки очереди (в любом статусе —
            // ручной retry сбрасывает бэкофф), либо у in-memory failed.
            if (txnId != null && (isQueued || message.isFailed))
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(l.commonRetry),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Строку очереди повторяем ЧЕРЕЗ очередь. `retry` тоже
                  // так диспатчит, но здесь признак уже посчитан — не
                  // завязываемся на его внутреннюю логику.
                  await (isQueued
                      ? controller.retryOutbox(txnId)
                      : controller.retry(txnId));
                },
              ),
            if (txnId != null && isQueued)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  l.messageActionCancelSend,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  navigator.pop();
                  try {
                    await controller.discardOutbox(txnId);
                  } catch (e, st) {
                    _reportActionFailed(e, st, 'cancelSend');
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(l.messageCancelSendFailed),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            _copyTile(context, l),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    final eventId = message.matrixEventId;
    if (eventId == null) return; // pending/failed shouldn't reach here
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);

    final newBody = await _showEditDialog(context, message.body);
    if (newBody == null) return; // user cancelled
    if (newBody.trim().isEmpty) return; // dialog client-side guards;
    // server-side ArgumentError тоже бы упал — defense in depth (Q5).
    try {
      await controller.editMessage(matrixEventId: eventId, newBody: newBody);
    } catch (e, st) {
      _reportActionFailed(e, st, 'edit');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.messageEditFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final eventId = message.matrixEventId;
    if (eventId == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);

    final confirmed = await _showDeleteConfirmDialog(context);
    if (confirmed != true) return;
    try {
      await controller.deleteMessage(matrixEventId: eventId);
    } catch (e, st) {
      _reportActionFailed(e, st, 'delete');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.messageDeleteFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **Issue #35**: закрепить/открепить (toggle). messenger + l захвачены ДО
  /// `pop()`. Сервер — финальный guard прав: [InsufficientPowerException]
  /// (напр. member в группе) → отдельный текст «только админы».
  Future<void> _handlePinToggle(
    ScaffoldMessengerState? messenger,
    NsgL10n l,
    String matrixEventId,
    bool currentlyPinned,
  ) async {
    try {
      if (currentlyPinned) {
        await controller.unpinMessage(matrixEventId);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(l.messageUnpinnedSnack),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        await controller.pinMessage(matrixEventId);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(l.messagePinnedSnack),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on InsufficientPowerException {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.pinNotAllowed),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, currentlyPinned ? 'unpin' : 'pin');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            currentlyPinned ? l.unpinMessageFailed : l.pinMessageFailed,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// **TASK38**: создать задачу во внешнем трекере из сообщения. messenger
  /// и l захвачены ДО `pop()` (sheet-context уже defunct к моменту await).
  /// Успех → snackbar с ключом задачи + кнопка скопировать URL. Нет
  /// конфига → [TaskIntegrationNotConfiguredException] → отдельный текст.
  Future<void> _handleCreateTask(
    ScaffoldMessengerState? messenger,
    NsgL10n l,
    String matrixEventId,
  ) async {
    try {
      final link = await controller.createTaskFromMessage(
        matrixEventId: matrixEventId,
        body: message.body,
      );
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l.taskCreatedSnack(link.externalTaskKey ?? link.externalTaskId),
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l.messageActionCopy,
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: link.externalTaskUrl)),
          ),
        ),
      );
    } on TaskIntegrationNotConfiguredException {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.taskIntegrationDisabled),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'createTask');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.taskCreateFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Сообщение с картинкой-вложением (для пункта «Скопировать изображение»).
bool _isImageAttachment(ChatMessage m) {
  final a = m.attachment;
  return a != null && a.mimeType.startsWith('image/');
}

/// Edit dialog — input field с current body prefilled. Save-button
/// disabled когда trim-empty (Q5 client-side validation; server-side
/// ArgumentError тоже defense).
Future<String?> _showEditDialog(BuildContext context, String currentBody) {
  final l = NsgL10n.of(context);
  return showDialog<String?>(
    context: context,
    builder: (ctx) => _EditDialog(initialBody: currentBody, l: l),
  );
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initialBody, required this.l});

  final String initialBody;
  final NsgL10n l;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _ctl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initialBody);
    _hasText = widget.initialBody.trim().isNotEmpty;
    _ctl.addListener(_syncHasText);
  }

  void _syncHasText() {
    final has = _ctl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _ctl.removeListener(_syncHasText);
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l.messageActionEditDialogTitle),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        maxLines: 5,
        minLines: 1,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(widget.l.commonCancel),
        ),
        FilledButton(
          onPressed: _hasText
              ? () => Navigator.of(context).pop(_ctl.text.trim())
              : null,
          child: Text(widget.l.messageActionEditSave),
        ),
      ],
    );
  }
}

Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
  final l = NsgL10n.of(context);
  return showDialog<bool?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.messageActionDeleteConfirmTitle),
      content: Text(l.messageActionDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.messageActionDelete),
        ),
      ],
    ),
  );
}
