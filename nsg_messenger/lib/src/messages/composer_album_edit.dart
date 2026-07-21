import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart' show AttachmentRef;

import 'attachments/attachment_picker.dart' show PickedAttachment;

/// **Редактирование альбома в композере**: модели для открытия существующего
/// альбома в композере (миниатюры существующих картинок + подпись), добавления
/// новых картинок / удаления существующих и применения диффа на сохранении.
///
/// Альбом на клиенте — группа Matrix-событий `m.image` с общим `nsg.album_id`
/// в raw content + опциональное `m.text` (подпись) с тем же id. «Редактировать
/// альбом» значит: убрать часть картинок (redact), добавить новые (upload+send)
/// и поправить подпись — набор best-effort операций (см. [MessagesController.editAlbum]).

/// Одна существующая картинка альбома, открытая в композере как миниатюра.
/// [attachment] — исходный `AttachmentRef` (для рендера мозаики из `mxc`);
/// [matrixEventId] — id события `m.image`, нужен чтобы пометить картинку на
/// удаление (redact) в диффе.
@immutable
class ComposerAlbumImage {
  const ComposerAlbumImage({
    required this.attachment,
    required this.matrixEventId,
  });

  final AttachmentRef attachment;
  final String matrixEventId;

  @override
  bool operator ==(Object other) =>
      other is ComposerAlbumImage &&
      other.matrixEventId == matrixEventId &&
      other.attachment.mxcUrl == attachment.mxcUrl;

  @override
  int get hashCode => Object.hash(matrixEventId, attachment.mxcUrl);
}

/// Снимок альбома, передаваемый в композер для входа в album-edit-mode.
/// Собирается ChatScreen-ом из текущего `MessagesController.state` (все
/// сообщения с общим `albumId`).
@immutable
class ComposerAlbumEdit {
  const ComposerAlbumEdit({
    required this.albumId,
    required this.images,
    required this.captionBody,
    required this.captionEventId,
  });

  /// Общий `nsg.album_id` группы.
  final String albumId;

  /// Существующие картинки в порядке отправки (по возрастанию
  /// `serverTimestamp`).
  final List<ComposerAlbumImage> images;

  /// Текущая подпись альбома (`''` если её нет).
  final String captionBody;

  /// `matrixEventId` события `m.text`-подписи (`null` если подписи нет).
  final String? captionEventId;
}

/// Результат album-edit, который композер отдаёт хосту при сохранении.
/// Хост (через `MessagesController.editAlbum`) применяет дифф.
@immutable
class ComposerAlbumEditResult {
  const ComposerAlbumEditResult({
    required this.albumId,
    required this.removedImageEventIds,
    required this.newAttachments,
    required this.newCaption,
    required this.captionEventId,
  });

  /// `matrixEventId` существующих картинок, помеченных на удаление (redact).
  final List<String> removedImageEventIds;

  /// Добавленные картинки (bytes) — их надо upload + send с этим [albumId].
  final List<PickedAttachment> newAttachments;

  /// Общий `nsg.album_id` группы.
  final String albumId;

  /// Итоговая подпись (trimmed). Пусто → подпись убрать (redact, если была).
  final String newCaption;

  /// `matrixEventId` существующей подписи (для replace/redact), `null` если
  /// подписи не было.
  final String? captionEventId;

  /// Дифф пустой — картинки не добавлялись и не удалялись. В этом случае
  /// правится только подпись (`editMessage`/`deleteMessage`/`sendMessage`),
  /// а позиция альбома в ленте сохраняется (нет новых событий).
  bool get onlyCaptionChanged =>
      removedImageEventIds.isEmpty && newAttachments.isEmpty;
}
