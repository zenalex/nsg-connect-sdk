/// **Просмотр текстового вложения внутри приложения** (issue #69).
///
/// Только текст как текст: моноширинный, выделяемый, с горизонтальной
/// прокруткой (в .md/.log/коде длинные строки — норма, а перенос ломает
/// таблицы и отступы). Рендер markdown сознательно не делаем — это issue
/// #56 про форматирование сообщений; когда он приедет, этот экран станет
/// его же потребителем.
///
/// Действия «открыть внешней программой» / «сохранить» — в шапке: они
/// нужны и из просмотра (посмотрел .md → сохранил).
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../../i18n/generated/nsg_l10n.dart';
import 'file_actions.dart';
import 'file_open_sheet.dart';

class FilePreviewScreen extends StatefulWidget {
  const FilePreviewScreen({
    super.key,
    required this.attachment,
    required this.actions,
  });

  final AttachmentRef attachment;
  final FileActions actions;

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  late Future<String> _text;

  @override
  void initState() {
    super.initState();
    _text = widget.actions.loadTextPreview(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final name = widget.attachment.originalFilename.isNotEmpty
        ? widget.attachment.originalFilename
        : l.attachUnnamedFallback;
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l.fileActionOpenExternal,
            icon: const Icon(Icons.open_in_new),
            onPressed: () => runFileAction(
              context,
              () => widget.actions.openExternally(widget.attachment),
            ),
          ),
          IconButton(
            tooltip: l.fileActionSave,
            icon: const Icon(Icons.download_outlined),
            onPressed: () => runFileAction(
              context,
              () => widget.actions.saveToDisk(widget.attachment),
              onSavedPath: true,
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _text,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.fileOpenFailed, textAlign: TextAlign.center),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                snap.data ?? '',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}
