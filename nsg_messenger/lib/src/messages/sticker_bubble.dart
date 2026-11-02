import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'attachments/mxc_image_provider.dart';
import 'sticker_data.dart';

/// **issue #151**: стикер в ленте.
///
/// Отдельным виджетом, а не размером у [AttachmentBubble]: у вложения свои
/// потолки (оно занимает пол-экрана и открывается по нажатию), и подгонять
/// общий виджет параметром значило бы завести в нём два разных поведения
/// под одним именем.
///
/// **Без пузыря.** Стикер рисуется на прозрачном фоне — так его и ожидают
/// увидеть. Фон и отступы снимает сам `MessageBubble`, здесь только
/// картинка.
class StickerBubble extends StatelessWidget {
  const StickerBubble({
    super.key,
    required this.sticker,
    required this.attachment,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    required this.textColor,
  });

  /// Сколько места занимает стикер. Полтораста — крупнее картинки-превью в
  /// строке, но заметно меньше вложения: стикер это реплика, а не документ.
  static const double maxSide = 150;

  final StickerData sticker;
  final AttachmentRef attachment;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  /// Цвет запасной подписи — приходит из пузыря (свой/чужой).
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxSide, maxHeight: maxSide),
      child: Image(
        // Полный размер, а не превью: стикер и так маленький, а миниатюра
        // сервера рассчитана на другие габариты — на ней он будет мыльным.
        // Анимацию (GIF/WebP) `Image` играет сам, отдельного кода не надо.
        image: MxcImageProvider(
          mxcUrl: attachment.mxcUrl,
          thumbnailRpc: thumbnailRpc,
          fullSizeRpc: fullSizeRpc,
          fullSize: true,
        ),
        fit: BoxFit.contain,
        // Пока грузится — место под стикер, а не прыгающая лента.
        frameBuilder: (context, child, frame, wasSync) => frame == null
            ? const SizedBox(width: maxSide, height: maxSide)
            : child,
        // Картинка не пришла — показываем имя. Пустого места в ленте быть
        // не должно: человек не поймёт, отправилось ли что-нибудь.
        errorBuilder: (context, error, stack) => Text(
          ':${sticker.alias}:',
          style: TextStyle(color: textColor, fontSize: 20),
        ),
      ),
    );
  }
}
