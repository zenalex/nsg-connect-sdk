/// **issue #151: экран управления наборами стикеров.**
///
/// Пункт 3 задачи и последнее звено: до него добавить стикер можно было
/// только вызовом RPC, а пикер у любого живого человека показывал «своих
/// стикеров пока нет».
///
/// **Отказы показываем сервером.** Потолки (5 наборов, 100 стикеров, 512 КБ,
/// 1 МБ для анимированной, PNG/WebP/GIF) живут в серверной политике и
/// приезжают готовым текстом в `StickerRejectedException.detail`. Своей копии
/// правил здесь нет намеренно: копия разъезжается молча, и человек читает
/// вежливую неправду. Локально проверяется ровно одно — что имя вообще
/// введено.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messages/attachments/attachment_picker.dart';
import '../messages/attachments/mxc_image_provider.dart';
import '../messenger_runtime.dart';
import 'nsg_messenger_stickers.dart';

/// Ключи для тестов.
const Key kStickerPacksAddPackKey = ValueKey('sticker-packs-add-pack');
const Key kStickerPacksRetryKey = ValueKey('sticker-packs-retry');

/// Как выбрать картинку. Подменяется в тестах: плагин выбора файлов в
/// тестовой среде недоступен, а проверять надо то, что происходит ПОСЛЕ
/// выбора.
typedef StickerFilePicker = Future<PickedAttachment?> Function();

Future<PickedAttachment?> _pickOneImage() async {
  final outcome = await pickFilesAttachment(limit: 1);
  return outcome.picked.isEmpty ? null : outcome.picked.first;
}

class StickerPacksScreen extends StatefulWidget {
  const StickerPacksScreen({super.key, this.stickers, this.pickFile});

  /// Откуда брать наборы. `null` — из рантайма (обычный путь).
  final NsgMessengerStickers? stickers;

  /// Чем выбирать картинку. `null` — системный выбор файлов.
  final StickerFilePicker? pickFile;

  @override
  State<StickerPacksScreen> createState() => _StickerPacksScreenState();
}

class _StickerPacksScreenState extends State<StickerPacksScreen> {
  late NsgMessengerStickers _stickers;
  late Future<List<StickerPackView>> _future;

  /// Идёт запись (загрузка картинки, удаление). Гасим кнопки: два одинаковых
  /// набора от двойного нажатия человек потом удаляет руками.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stickers = widget.stickers ?? MessengerRuntime.instance.stickers;
    _future = _stickers.listMyPacks();
  }

  void _reload() {
    setState(() {
      _future = _stickers.listMyPacks();
    });
  }

  /// Выполнить запись и перечитать список.
  ///
  /// Отказ политики (`StickerRejectedException`) показываем его же словами:
  /// сервер шлёт готовый текст именно для этого. Всё остальное — сеть и
  /// пятисотки — общим «не получилось»: подробности там всё равно не про
  /// человека.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
      if (!mounted) return;
      _reload();
    } on StickerRejectedException catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.detail)));
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: const {'nsg.screen': 'stickerPacks'},
      );
      messenger?.showSnackBar(SnackBar(content: Text(l.stickerActionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPack() async {
    final l = NsgL10n.of(context);
    final name = await _promptText(
      title: l.stickerPackCreate,
      hint: l.stickerPackNameHint,
    );
    if (name == null) return;
    await _run(() => _stickers.createPack(name));
  }

  Future<void> _renamePack(StickerPack pack) async {
    final l = NsgL10n.of(context);
    final name = await _promptText(
      title: l.stickerPackRename,
      hint: l.stickerPackNameHint,
      initial: pack.name,
    );
    if (name == null) return;
    await _run(() => _stickers.renamePack(pack.id!, name));
  }

  Future<void> _deletePack(StickerPack pack) async {
    final l = NsgL10n.of(context);
    final ok = await _confirm(l.stickerPackDeleteConfirm(pack.name));
    if (!ok) return;
    await _run(() => _stickers.deletePack(pack.id!));
  }

  Future<void> _addSticker(StickerPack pack) async {
    final picked = await (widget.pickFile ?? _pickOneImage)();
    if (picked == null || !mounted) return;
    final l = NsgL10n.of(context);
    final alias = await _promptText(
      title: l.stickerAdd,
      hint: l.stickerNameHint,
      help: l.stickerNameHelp,
      // Имя файла — самая близкая догадка: человек уже назвал картинку.
      initial: _aliasFromFilename(picked.originalFilename),
      preview: picked,
    );
    if (alias == null) return;
    await _run(
      () => _stickers.addSticker(
        packId: pack.id!,
        bytes: ByteData.sublistView(picked.bytes),
        mimeType: picked.mimeType,
        alias: alias,
      ),
    );
  }

  Future<void> _removeSticker(Sticker sticker) async {
    final l = NsgL10n.of(context);
    final ok = await _confirm(l.stickerDeleteConfirm(sticker.alias));
    if (!ok) return;
    await _run(() => _stickers.removeSticker(sticker.id!));
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    String? initial,
    String? help,
    PickedAttachment? preview,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextPromptDialog(
        title: title,
        hint: hint,
        initial: initial,
        help: help,
        preview: preview,
      ),
    );
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<bool> _confirm(String question) async {
    final l = NsgL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.stickerDelete),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.stickerPacksTitle),
        actions: [
          IconButton(
            key: kStickerPacksAddPackKey,
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: l.stickerPackCreate,
            onPressed: _busy ? null : _createPack,
          ),
        ],
      ),
      body: FutureBuilder<List<StickerPackView>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Centered(
              text: l.stickerPacksLoadFailed,
              action: TextButton(
                key: kStickerPacksRetryKey,
                onPressed: _reload,
                child: Text(l.commonRetry),
              ),
            );
          }
          final packs = snap.data ?? const <StickerPackView>[];
          if (packs.isEmpty) {
            return _Centered(
              text: '${l.stickerPacksEmpty}\n\n${l.stickerPacksNoneHint}',
              action: FilledButton(
                onPressed: _busy ? null : _createPack,
                child: Text(l.stickerPackCreate),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final p in packs)
                _PackCard(
                  view: p,
                  busy: _busy,
                  onRename: () => _renamePack(p.pack),
                  onDelete: () => _deletePack(p.pack),
                  onAdd: () => _addSticker(p.pack),
                  onRemoveSticker: _removeSticker,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.view,
    required this.busy,
    required this.onRename,
    required this.onDelete,
    required this.onAdd,
    required this.onRemoveSticker,
  });

  final StickerPackView view;
  final bool busy;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAdd;
  final void Function(Sticker) onRemoveSticker;

  static const double _tile = 72;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    // Картинки грузим напрямую через клиента: экран живёт вне комнаты, и
    // контроллера сообщений с его загрузчиками здесь нет.
    final client = MessengerRuntime.instance.clientOrNull;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    view.pack.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${view.stickers.length}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(l.stickerPackRename),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l.stickerPackDelete),
                    ),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in view.stickers)
                  SizedBox(
                    width: _tile,
                    height: _tile,
                    child: InkWell(
                      // Тап — удаление с подтверждением: экран только про
                      // управление, других действий у стикера здесь нет.
                      onTap: busy ? null : () => onRemoveSticker(s),
                      child: Tooltip(
                        message: ':${s.alias}:',
                        child: client == null
                            ? Center(child: Text(s.alias))
                            : Image(
                                image: MxcImageProvider(
                                  mxcUrl: s.mxcUrl,
                                  thumbnailRpc: client
                                      .messenger
                                      .downloadAttachmentThumbnail,
                                  fullSizeRpc:
                                      client.messenger.downloadAttachment,
                                  fullSize: true,
                                ),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    s.alias,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: _tile,
                  height: _tile,
                  child: OutlinedButton(
                    onPressed: busy ? null : onAdd,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Tooltip(
                      message: l.stickerAdd,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог с одним полем.
///
/// Отдельным виджетом со СВОИМ состоянием, а не замыканием вокруг
/// контроллера: `showDialog` возвращает управление в момент закрытия, а
/// диалог в этот момент ещё анимируется — контроллер, освобождённый сразу
/// после `await`, успевает попасть в кадр уже освобождённым («A
/// TextEditingController was used after being disposed»). Поймано тестом.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hint,
    this.initial,
    this.help,
    this.preview,
  });

  final String title;
  final String hint;
  final String? initial;
  final String? help;
  final PickedAttachment? preview;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final preview = widget.preview;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Image.memory(
                preview.bytes,
                height: 96,
                fit: BoxFit.contain,
                // Битую картинку показываем как отказ здесь, а не после
                // загрузки: человек видит, что выбрал не то.
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
              ),
            ),
          TextField(
            controller: _ctl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.hint,
              helperText: widget.help,
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctl.text),
          child: Text(l.stickerSave),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ?action,
        ],
      ),
    ),
  );
}

/// Догадка об имени по имени файла: `Cat Face.PNG` → `cat_face`.
///
/// Именно догадка — поле остаётся редактируемым, а последнее слово за
/// сервером. Смысл в том, чтобы обычный случай не требовал печатать.
String _aliasFromFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  final base = dot > 0 ? filename.substring(0, dot) : filename;
  final cleaned = base
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9_]+'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return cleaned;
}
