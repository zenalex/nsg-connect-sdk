/// **Тап по файловому вложению** (issue #69): лист действий и просмотр
/// текста прямо в приложении.
///
/// Пользователь: «прикрепил файл, в данном случае md — не открывает по
/// нажатию; при понятном формате должен быть просмотр, при непонятном —
/// показать, что за файл, и предложить открыть внешней программой или
/// сохранить».
///
/// Отсюда две ветки. Понятный формат (текстовый, см. [isTextPreviewable]) —
/// открываем просмотр СРАЗУ, без промежуточного меню: лишний тап на пути к
/// содержимому раздражает, а действия остаются в шапке просмотра.
/// Непонятный — лист с именем, размером и действиями, как и просил
/// пользователь.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../../i18n/generated/nsg_l10n.dart';
import 'file_actions.dart';
import 'file_preview_screen.dart';

/// Точка входа: тап по файловому вложению.
Future<void> openAttachment(
  BuildContext context, {
  required AttachmentRef attachment,
  required FileActions actions,
}) async {
  final previewable = isTextPreviewable(
    filename: attachment.originalFilename,
    mimeType: attachment.mimeType,
    sizeBytes: attachment.sizeBytes,
  );
  if (previewable) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FilePreviewScreen(attachment: attachment, actions: actions),
      ),
    );
    return;
  }
  await showFileActionsSheet(
    context,
    attachment: attachment,
    actions: actions,
  );
}

/// Лист действий по файлу (без просмотра — формат нетекстовый).
Future<void> showFileActionsSheet(
  BuildContext context, {
  required AttachmentRef attachment,
  required FileActions actions,
}) {
  final l = NsgL10n.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(
              attachment.originalFilename.isNotEmpty
                  ? attachment.originalFilename
                  : l.attachUnnamedFallback,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(formatFileSize(attachment.sizeBytes)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l.fileActionOpenExternal),
            onTap: () {
              Navigator.of(sheetContext).pop();
              runFileAction(
                context,
                () => actions.openExternally(attachment),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l.fileActionSave),
            onTap: () {
              Navigator.of(sheetContext).pop();
              runFileAction(
                context,
                () => actions.saveToDisk(attachment),
                onSavedPath: true,
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Выполнить действие, показав результат пользователю.
///
/// Молчаливый провал здесь недопустим ровно по причине самого issue #69:
/// пользователь уже один раз нажимал на файл и не понимал, происходит
/// что-нибудь или нет. Поэтому у каждого исхода свой текст: сохранили —
/// путь, нет ассоциации — про отсутствие программы, всё прочее — общая
/// ошибка.
Future<void> runFileAction(
  BuildContext context,
  Future<Object?> Function() action, {
  bool onSavedPath = false,
}) async {
  final l = NsgL10n.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await action();
    if (onSavedPath && result is String) {
      messenger.showSnackBar(SnackBar(content: Text(l.fileSavedTo(result))));
    }
  } on NoHandlerForFileException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.fileNoHandler(e.filename))));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.fileOpenFailed)));
  }
}

/// Human-readable размер: 102400 → «100 KB», 5242880 → «5.0 MB».
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
