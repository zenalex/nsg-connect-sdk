import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../i18n/generated/nsg_l10n.dart';

/// Результат выбора attachment-а юзером — bytes + MIME + filename
/// для последующего `uploadAttachment` server-side. SDK абстрагирует
/// `image_picker` API; downstream UI оперирует только `PickedAttachment`.
@immutable
class PickedAttachment {
  const PickedAttachment({
    required this.bytes,
    required this.mimeType,
    required this.originalFilename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String originalFilename;
}

/// Bottom-sheet с действиями attach в `MessageComposer` (TASK19 Chunk 3).
/// На MVP — image_picker camera/gallery. file_picker для arbitrary
/// файлов — TASK19-Phase2 (см. backlog в TASK19.md).
///
/// Возвращает [PickedAttachment] либо null если юзер cancel-нул.
Future<PickedAttachment?> showAttachmentPicker({
  required BuildContext context,
  ImagePicker? pickerOverride,
}) {
  return showModalBottomSheet<PickedAttachment?>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) =>
        _AttachmentPickerSheet(picker: pickerOverride ?? ImagePicker()),
  );
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet({required this.picker});

  final ImagePicker picker;

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
              l.attachActionSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.attachActionCamera),
            onTap: () async {
              final result = await _pick(picker, ImageSource.camera);
              if (!context.mounted) return;
              Navigator.of(context).pop(result);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.attachActionGallery),
            onTap: () async {
              final result = await _pick(picker, ImageSource.gallery);
              if (!context.mounted) return;
              Navigator.of(context).pop(result);
            },
          ),
        ],
      ),
    );
  }

  /// Pick → read bytes → derive MIME из path extension. `image_picker`
  /// возвращает `XFile` с `.mimeType` опционально (на iOS/Android может
  /// быть null если platform не resolve-ит). Fallback по extension —
  /// server-side validate.
  Future<PickedAttachment?> _pick(
    ImagePicker picker,
    ImageSource source,
  ) async {
    final XFile? file;
    try {
      file = await picker.pickImage(source: source);
    } catch (_) {
      // image_picker может бросить если permissions denied / cancelled
      // / camera unavailable. UI снаружи покажет snackbar.
      return null;
    }
    if (file == null) return null; // user cancelled
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? _guessMimeFromExtension(file.name);
    return PickedAttachment(
      bytes: bytes,
      mimeType: mime,
      originalFilename: file.name,
    );
  }

  /// Heuristic MIME guess по расширению — fallback когда `XFile.mimeType`
  /// null (некоторые platforms не resolve). Server-side затем валидирует
  /// MIME whitelist; если MIME не определён правильно — server reject-нет
  /// с ArgumentError, UI покажет error snackbar.
  static String _guessMimeFromExtension(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    if (lower.endsWith('.avif')) return 'image/avif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
