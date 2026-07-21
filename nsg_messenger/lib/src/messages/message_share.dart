import 'package:share_plus/share_plus.dart';

import 'chat_message.dart';
import 'messages_controller.dart';

/// **Внешняя пересылка (share наружу)** — отдать сообщение/альбом в
/// системный share sheet (share_plus): текст → как text, картинки → как
/// файлы (+подпись).
///
/// Сбор байтов ([buildImageFiles]) вынесен отдельно от самого системного
/// вызова [share], чтобы его можно было юнит-тестить (сеть мокается на
/// уровне `MessagesController.downloadFullSize`). Реальный share sheet —
/// платформенный, в тестах не дёргается.
class MessageSharer {
  MessageSharer(this._controller);

  final MessagesController _controller;

  /// Скачать полноразмерные байты картинок [parts] (через
  /// `controller.downloadFullSize`) и обернуть в [XFile] для share_plus.
  /// Части без вложения игнорируются.
  Future<List<XFile>> buildImageFiles(List<ChatMessage> parts) async {
    final files = <XFile>[];
    for (final p in parts) {
      final a = p.attachment;
      if (a == null) continue;
      final data = await _controller.downloadFullSize(mxcUrl: a.mxcUrl);
      final bytes = data.bytes.buffer.asUint8List(
        data.bytes.offsetInBytes,
        data.bytes.lengthInBytes,
      );
      files.add(
        XFile.fromData(bytes, mimeType: a.mimeType, name: a.originalFilename),
      );
    }
    return files;
  }

  /// Развернуть [message] в части (весь альбом, если это член альбома;
  /// иначе — одиночное сообщение). Картинки — с вложением, подпись — без.
  List<ChatMessage> _expand(ChatMessage message) {
    final aid = message.albumId;
    if (aid != null && aid.isNotEmpty) {
      final members = _controller.albumMembersOf(message);
      if (members.isNotEmpty) return members;
    }
    return <ChatMessage>[message];
  }

  static String? _captionOf(List<ChatMessage> parts) {
    for (final p in parts) {
      if (p.attachment == null && p.body.trim().isNotEmpty) return p.body;
    }
    return null;
  }

  /// Поделиться [message] наружу. Текст → share text; картинка/альбом →
  /// share файлов (+подпись). Бросает при ошибке — host UI покажет snackbar.
  Future<void> share(ChatMessage message) async {
    final parts = _expand(message);
    final imageParts = parts
        .where((p) => p.attachment != null)
        .toList(growable: false);
    if (imageParts.isEmpty) {
      // Чистый текст. share_plus v12 API (SharePlus.instance/ShareParams) —
      // общий пакет nsg_controls на ^12, старый Share.share() удалён.
      await SharePlus.instance.share(ShareParams(text: message.body));
      return;
    }
    final files = await buildImageFiles(imageParts);
    final caption = _captionOf(parts);
    await SharePlus.instance.share(ShareParams(files: files, text: caption));
  }
}
