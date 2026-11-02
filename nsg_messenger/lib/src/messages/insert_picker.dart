/// **issue #151: панель вставки — эмодзи и стикеры вкладками.**
///
/// Почему одна панель на двоих, а не вторая кнопка в композере: и то и другое
/// — «вставить в сообщение», и человек не должен помнить, за какой из кнопок
/// что лежит. Ряд композера к тому же тесный (скрепка, эмодзи, микрофон), и
/// на узком экране третья иконка вытесняет поле ввода.
///
/// Вкладок нет, когда стикеры не подключены: без второй вкладки лист остаётся
/// ровно прежним листом эмодзи (см. `showEmojiInsertPicker`) — с заголовком и
/// без пустой полоски вкладок над ним.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../stickers/sticker_picker_panel.dart';
import '../widgets/nsg_modal_sheet.dart';
import 'attachments/mxc_image_provider.dart';
import 'emoji_picker.dart';

/// Что выбрали в панели вставки.
///
/// Своим типом, а не парой `(String?, Sticker?)`: эмодзи уходит в текст на
/// место каретки, стикер — отдельным сообщением, и перепутать эти два пути
/// нельзя.
sealed class ComposerInsertion {
  const ComposerInsertion();
}

final class EmojiInsertion extends ComposerInsertion {
  const EmojiInsertion(this.emoji);
  final String emoji;
}

final class StickerInsertion extends ComposerInsertion {
  const StickerInsertion(this.sticker);
  final Sticker sticker;
}

/// Нажали «Мои стикеры».
///
/// Тоже через результат листа, а не колбэком изнутри: экран управления
/// нельзя открывать под закрывающимся листом — переход должен случиться
/// ПОСЛЕ того, как лист ушёл.
final class ManageStickersRequested extends ComposerInsertion {
  const ManageStickersRequested();
}

/// Ключи вкладок — для тестов.
const Key kInsertPickerTabsKey = ValueKey('insert-picker-tabs');
const Key kInsertPickerStickerTabKey = ValueKey('insert-picker-tab-stickers');

/// Открыть панель вставки. Возвращает `null`, если лист закрыли.
///
/// Состав панели зависит от того, что вообще нужно:
///
///   * **и эмодзи, и стикеры** — вкладки. Это десктоп: своей клавиатуры с
///     эмодзи там нет, а стикеры есть;
///   * **только эмодзи** ([loadStickerPacks] равен `null`) — прежний лист
///     эмодзи, без пустой полоски вкладок над ним;
///   * **только стикеры** ([withEmoji] равен `false`) — это мобильный:
///     эмодзи там даёт системная клавиатура, ради того кнопку эмодзи и не
///     показывают. Вкладка «Эмодзи» из курированного набора рядом с ней была
///     бы заведомо худшей копией.
Future<ComposerInsertion?> showComposerInsertPicker(
  BuildContext context, {
  bool withEmoji = true,
  StickerPacksLoader? loadStickerPacks,
  DownloadAttachmentThumbnailRpc? thumbnailRpc,
  DownloadAttachmentRpc? fullSizeRpc,
  bool withManage = false,
}) async {
  final hasStickers =
      loadStickerPacks != null && thumbnailRpc != null && fullSizeRpc != null;
  if (!hasStickers) {
    final emoji = await showEmojiInsertPicker(context);
    return emoji == null ? null : EmojiInsertion(emoji);
  }
  // Issue #105: через помощник — иначе длинная панель дорастает до верха
  // экрана и ручка уходит под вырез.
  return showNsgModalSheet<ComposerInsertion>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _InsertPickerBody(
      withEmoji: withEmoji,
      withManage: withManage,
      loadStickerPacks: loadStickerPacks,
      thumbnailRpc: thumbnailRpc,
      fullSizeRpc: fullSizeRpc,
    ),
  );
}

class _InsertPickerBody extends StatelessWidget {
  const _InsertPickerBody({
    required this.withEmoji,
    required this.withManage,
    required this.loadStickerPacks,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
  });

  final bool withEmoji;
  final bool withManage;
  final StickerPacksLoader loadStickerPacks;
  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    final stickers = StickerPickerPanel(
      loadPacks: loadStickerPacks,
      thumbnailRpc: thumbnailRpc,
      fullSizeRpc: fullSizeRpc,
      onPick: (s) => Navigator.of(context).pop(StickerInsertion(s)),
      onManage: withManage
          ? () => Navigator.of(context).pop(const ManageStickersRequested())
          : null,
    );
    return SafeArea(
      child: ConstrainedBox(
        // Высота фиксирована, а не по содержимому: панели с разным
        // наполнением иначе прыгали бы при переключении вкладок, а пустая
        // («стикеров нет») схлопнулась бы в полоску.
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: maxHeight),
        child: !withEmoji
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      l.stickerTabStickers,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(child: stickers),
                ],
              )
            : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      key: kInsertPickerTabsKey,
                      tabs: [
                        Tab(text: l.stickerTabEmoji),
                        Tab(
                          key: kInsertPickerStickerTabKey,
                          text: l.stickerTabStickers,
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          EmojiPickerBody(
                            onPick: (emoji) => Navigator.of(
                              context,
                            ).pop(EmojiInsertion(emoji)),
                          ),
                          stickers,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
