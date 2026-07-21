import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../theme/overlay_surface.dart';
import 'chats_list_controller.dart';

/// **TASK62**: шит «Добавить в папку» — чекбоксы membership комнаты по
/// всем пользовательским папкам + «Новая папка…». Один чат может быть в
/// нескольких папках (M2M). Мутации идут через [ChatsListController]
/// (RPC + invalidate + notify), изменения применяются сразу по тапу.
///
/// RU-строки хардкодом (как MyTicketsScreen) — l10n итерацией 2.
Future<void> showChatFolderPicker(
  BuildContext context, {
  required ChatsListController controller,
  required RoomSummary room,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Chatista Glass: тёмный тёплый шит со скруглённым верхом
    // (docs/design/chatista-glass-design-prompt.md).
    backgroundColor: kOverlaySurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ChatFolderPickerSheet(
      controller: controller,
      room: room,
    ),
  );
}

// Chatista Glass: тёплый белый с фиксированными альфами.
const _fg = Color(0xF5FFFCF8);
const _fgMuted = Color(0xB8FFFCF8);
const _fgDim = Color(0x80FFFCF8);

class _ChatFolderPickerSheet extends StatefulWidget {
  const _ChatFolderPickerSheet({
    required this.controller,
    required this.room,
  });

  final ChatsListController controller;
  final RoomSummary room;

  @override
  State<_ChatFolderPickerSheet> createState() => _ChatFolderPickerSheetState();
}

class _ChatFolderPickerSheetState extends State<_ChatFolderPickerSheet> {
  /// folderId → комната в папке (локальный снапшот для мгновенного UI;
  /// источник правды — controller.customFolders после каждой мутации).
  late Map<int, bool> _membership;
  bool _busy = false;

  /// Инлайн-создание папки (макет sheet-addfolder: без диалога).
  bool _creating = false;
  final _newNameCtl = TextEditingController();

  @override
  void dispose() {
    _newNameCtl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _syncFromController();
  }

  void _syncFromController() {
    _membership = {
      for (final f in widget.controller.customFolders)
        f.id: f.roomIds.contains(widget.room.id),
    };
  }

  /// Отправить в трекер ошибку работы с папкой, которую увидел пользователь.
  /// Тег [action] отделяет пути: часть из них делит один снек, а часть
  /// откатывает optimistic-состояние — внешне «просто не сработало».
  void _reportActionFailed(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'folder.action': action},
    );
  }

  Future<void> _toggle(ChatFolderView folder, bool inFolder) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _membership[folder.id] = inFolder;
    });
    try {
      await widget.controller.setRoomInChatFolder(
        folderId: folder.id,
        roomId: widget.room.id,
        inFolder: inFolder,
      );
    } catch (e, st) {
      _reportActionFailed(e, st, inFolder ? 'addRoom' : 'removeRoom');
      if (mounted) {
        setState(() => _membership[folder.id] = !inFolder); // revert
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NsgL10n.of(context).folderChangeFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _syncFromController();
        });
      }
    }
  }

  /// Инлайн-коммит новой папки (Enter или «ОК»); чат сразу кладётся в неё.
  Future<void> _commitNewFolder() async {
    final name = _newNameCtl.text.trim();
    if (name.isEmpty) {
      setState(() => _creating = false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    setState(() {
      _creating = false;
      _newNameCtl.clear();
    });
    try {
      final created = await widget.controller.createChatFolder(name.trim());
      // Сразу кладём текущий чат в новую папку.
      await widget.controller.setRoomInChatFolder(
        folderId: created.id,
        roomId: widget.room.id,
        inFolder: true,
      );
      if (mounted) setState(_syncFromController);
    } catch (e, st) {
      _reportActionFailed(e, st, 'create');
      messenger.showSnackBar(
        SnackBar(content: Text(l.folderCreateFailed)),
      );
    }
  }

  /// Долг TASK62: управление папкой — переименовать / удалить.
  Future<void> _folderMenu(ChatFolderView folder) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kOverlaySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _fgMuted),
              title: Text(
                NsgL10n.of(context).folderRenameMenu(folder.name),
                style: const TextStyle(color: _fg, fontSize: 15),
              ),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _fgMuted),
              title: Text(
                NsgL10n.of(context).folderDelete,
                style: const TextStyle(color: _fg, fontSize: 15),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);

    if (action == 'rename') {
      final ctl = TextEditingController(text: folder.name);
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(NsgL10n.of(context).folderRenameTitle),
          content: TextField(
            controller: ctl,
            autofocus: true,
            maxLength: 64,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(NsgL10n.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctl.text),
              child: Text(NsgL10n.of(context).contactSave),
            ),
          ],
        ),
      );
      if (name == null || name.trim().isEmpty || !mounted) return;
      try {
        await widget.controller.renameChatFolder(folder.id, name.trim());
        if (mounted) setState(_syncFromController);
      } catch (e, st) {
        _reportActionFailed(e, st, 'rename');
        messenger.showSnackBar(
          SnackBar(content: Text(l.contactRenameFailed)),
        );
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(NsgL10n.of(context).folderDeleteConfirm(folder.name)),
        content: Text(NsgL10n.of(context).folderDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(NsgL10n.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(NsgL10n.of(context).contactDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.controller.deleteChatFolder(folder.id);
      if (mounted) setState(_syncFromController);
    } catch (e, st) {
      _reportActionFailed(e, st, 'delete');
      messenger.showSnackBar(
        SnackBar(content: Text(l.folderDeleteFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final folders = widget.controller.customFolders;
    final selectedCount = _membership.values.where((v) => v).length;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header (макет: title 17 w600 + subtitle dim 12.5 = имя чата).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.folderPickerHeader,
                  style: const TextStyle(
                    color: _fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.room.name ?? '',
                  style: const TextStyle(
                    color: _fgDim,
                    fontSize: 12.5,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // «Новая папка» / инлайн-создание (макет sheet-addfolder).
                if (_creating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      children: [
                        _accentCircle(accent, Icons.folder_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x1FFFFFFF),
                                width: 0.5,
                              ),
                            ),
                            child: TextField(
                              controller: _newNameCtl,
                              autofocus: true,
                              cursorColor: accent,
                              style:
                                  const TextStyle(color: _fg, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: l.folderNameHint,
                                hintStyle: const TextStyle(
                                  color: _fgDim,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              onSubmitted: (_) => _commitNewFolder(),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _commitNewFolder,
                          child: Text(
                            l.folderOk,
                            style: TextStyle(
                              color: accent,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap:
                        _busy ? null : () => setState(() => _creating = true),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(Icons.add, size: 20, color: accent),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            l.folderNewTitle,
                            style: TextStyle(
                              color: accent,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 74, right: 20),
                  child:
                      Container(height: 0.5, color: const Color(0x17FFFFFF)),
                ),
                for (var i = 0; i < folders.length; i++)
                  _folderRow(
                    folders[i],
                    accent: accent,
                    l: l,
                    last: i == folders.length - 1,
                  ),
                if (folders.isEmpty && !_creating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      l.folderPickerEmpty,
                      style:
                          const TextStyle(color: _fgMuted, fontSize: 13.5),
                    ),
                  ),
              ],
            ),
          ),
          // Footer: primary «Готово · N» (макет).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF1A0F1A),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              child: Text(
                selectedCount > 0
                    ? l.folderDoneN(selectedCount)
                    : l.folderDone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accentCircle(Color accent, IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: accent.withValues(alpha: 0.16),
      border: Border.all(color: accent.withValues(alpha: 0.32), width: 0.5),
    ),
    child: Icon(icon, size: 20, color: accent),
  );

  /// Строка папки по макету: акцент-круг 40 → имя 15.5 + «N чатов» →
  /// круглый чек; inset-разделитель слева 74. Long-press — управление.
  Widget _folderRow(
    ChatFolderView f, {
    required Color accent,
    required NsgL10n l,
    required bool last,
  }) {
    final checked = _membership[f.id] ?? false;
    return InkWell(
      onTap: _busy ? null : () => _toggle(f, !checked),
      onLongPress: _busy ? null : () => _folderMenu(f),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      splashColor: Colors.white.withValues(alpha: 0.06),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                _accentCircle(accent, Icons.folder_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l.folderChatCount(f.roomIds.length),
                        style:
                            const TextStyle(color: _fgDim, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? accent : Colors.transparent,
                    border: checked
                        ? null
                        : Border.all(
                            color: const Color(0x52FFFCF8),
                            width: 1.6,
                          ),
                  ),
                  child: checked
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF1A0F1A),
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (!last)
            const Positioned(
              left: 74,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 0.5,
                child: ColoredBox(color: Color(0x17FFFFFF)),
              ),
            ),
        ],
      ),
    );
  }
}
