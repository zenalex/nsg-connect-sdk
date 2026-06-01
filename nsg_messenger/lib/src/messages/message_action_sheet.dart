import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/generated/nsg_l10n.dart';
import 'chat_message.dart';
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => _MessageActionSheetBody(
      message: message,
      isOwn: isOwn,
      controller: controller,
    ),
  );
}

class _MessageActionSheetBody extends StatelessWidget {
  const _MessageActionSheetBody({
    required this.message,
    required this.isOwn,
    required this.controller,
  });

  final ChatMessage message;
  final bool isOwn;
  final MessagesController controller;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          if (isOwn) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.messageActionEdit),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await _handleEdit(context);
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
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: Text(l.messageActionCopy),
            onTap: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.maybeOf(context);
              final l = NsgL10n.of(context);
              navigator.pop();
              await Clipboard.setData(ClipboardData(text: message.body));
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(l.messageCopiedSnack),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
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
    } catch (_) {
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
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.messageDeleteFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
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
