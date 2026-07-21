import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'attachment_picker.dart';

/// **Web**: слушает событие `paste` на `document` и, если в буфере обмена
/// есть картинка (Ctrl+V), отдаёт её как [PickedAttachment] — вставка
/// изображения из буфера прямо в чат. На не-web платформах используется
/// заглушка (см. [clipboard_image_stub.dart]).
class ClipboardImageListener {
  void Function(PickedAttachment picked)? _onImage;
  web.EventListener? _listener;

  void start(void Function(PickedAttachment picked) onImage) {
    _onImage = onImage;
    if (_listener != null) return;
    final l = _handlePaste.toJS;
    _listener = l;
    web.document.addEventListener('paste', l);
  }

  void stop() {
    final l = _listener;
    if (l != null) web.document.removeEventListener('paste', l);
    _listener = null;
    _onImage = null;
  }

  void _handlePaste(web.Event event) {
    final ce = event as web.ClipboardEvent;
    final data = ce.clipboardData;
    if (data == null) return;
    final items = data.items;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final type = item.type;
      if (item.kind != 'file' || !type.startsWith('image/')) continue;
      final file = item.getAsFile();
      if (file == null) continue;
      // Есть картинка — гасим дефолтную обработку браузера.
      ce.preventDefault();
      _readFile(file, type);
      return; // берём первую картинку
    }
  }

  void _readFile(web.File file, String mime) {
    final reader = web.FileReader();
    reader.onload = ((web.Event _) {
      final result = reader.result;
      if (result == null || !result.isA<JSArrayBuffer>()) return;
      final bytes = (result as JSArrayBuffer).toDart.asUint8List();
      final ext = mime.contains('/') ? mime.split('/').last : 'png';
      _onImage?.call(
        PickedAttachment(
          bytes: bytes,
          mimeType: mime,
          originalFilename: 'pasted-image.$ext',
        ),
      );
    }).toJS;
    reader.readAsArrayBuffer(file);
  }
}
