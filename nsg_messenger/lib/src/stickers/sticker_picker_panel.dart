/// **issue #151: панель выбора стикера.**
///
/// Живёт вкладкой рядом с эмодзи (см. `messages/insert_picker.dart`): и то и
/// другое — «вставить в сообщение», разводить их по разным кнопкам значило бы
/// заставить человека помнить, за какой из них что.
///
/// Загрузка — по открытию, кэша нет намеренно (см. `NsgMessengerStickers`):
/// панель открывают редко, а показывать удалённый стикер хуже, чем подождать
/// полсекунды.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messages/attachments/mxc_image_provider.dart';

/// Откуда панель берёт наборы. Функцией, а не рантаймом внутри: панель не
/// должна знать про singleton — иначе её не проверить без живого клиента.
typedef StickerPacksLoader = Future<List<StickerPackView>> Function();

/// Ключи для тестов и для навигации с клавиатуры.
const Key kStickerPickerGridKey = ValueKey('sticker-picker-grid');
const Key kStickerPickerRetryKey = ValueKey('sticker-picker-retry');
const Key kStickerPickerManageKey = ValueKey('sticker-picker-manage');

class StickerPickerPanel extends StatefulWidget {
  const StickerPickerPanel({
    super.key,
    required this.loadPacks,
    required this.onPick,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    this.onManage,
  });

  final StickerPacksLoader loadPacks;

  /// Тап по стикеру. Панель ничего не отправляет сама — решает вызывающая
  /// сторона (закрыть лист, отправить, вставить).
  final void Function(Sticker sticker) onPick;

  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  /// «Мои стикеры» — переход к управлению наборами. `null` — хост перехода
  /// не дал, строки внизу не будет.
  ///
  /// Строка нужна и на пустой панели, и на полной: первый набор откуда-то
  /// должен взяться, а следующий — тем более. Пустая панель без выхода к
  /// управлению это тупик с сообщением «стикеров нет».
  final VoidCallback? onManage;

  /// Сторона плитки. Меньше, чем стикер в ленте: здесь их много и главное —
  /// узнать свой, а не рассмотреть.
  static const double tile = 72;

  @override
  State<StickerPickerPanel> createState() => _StickerPickerPanelState();
}

class _StickerPickerPanelState extends State<StickerPickerPanel> {
  late Future<List<StickerPackView>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadPacks();
  }

  void _reload() {
    // Тело блоком, а не стрелкой: `setState(() => _future = …)` возвращает
    // из замыкания Future, и Flutter это запрещает (принимает за случайно
    // асинхронный колбэк). Поймано тестом на «Повторить».
    setState(() {
      _future = widget.loadPacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final onManage = widget.onManage;
    return Column(
      children: [
        Expanded(child: _content(context, l)),
        if (onManage != null) ...[
          const Divider(height: 1),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: kStickerPickerManageKey,
              onPressed: onManage,
              icon: const Icon(Icons.folder_outlined, size: 18),
              label: Text(l.stickerPacksTitle),
            ),
          ),
        ],
      ],
    );
  }

  Widget _content(BuildContext context, NsgL10n l) {
    return FutureBuilder<List<StickerPackView>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          // Сеть или сервер. Молчаливая пустая панель здесь читалась бы как
          // «у тебя нет стикеров» — а это разные вещи.
          return _Message(
            text: l.stickerPacksLoadFailed,
            action: TextButton(
              key: kStickerPickerRetryKey,
              onPressed: _reload,
              child: Text(l.commonRetry),
            ),
          );
        }
        final packs = (snap.data ?? const <StickerPackView>[])
            .where((p) => p.stickers.isNotEmpty)
            .toList();
        if (packs.isEmpty) {
          return _Message(text: l.stickerPacksEmpty);
        }
        return CustomScrollView(
          key: kStickerPickerGridKey,
          slivers: [
            for (final p in packs) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      p.pack.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: StickerPickerPanel.tile,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final s = p.stickers[i];
                    return InkResponse(
                      onTap: () => widget.onPick(s),
                      radius: StickerPickerPanel.tile / 2,
                      // Подпись именем — она же поиск глазами и она же
                      // запасной вид, если картинка не пришла.
                      child: Tooltip(
                        message: ':${s.alias}:',
                        child: Image(
                          image: MxcImageProvider(
                            mxcUrl: s.mxcUrl,
                            thumbnailRpc: widget.thumbnailRpc,
                            fullSizeRpc: widget.fullSizeRpc,
                            fullSize: true,
                          ),
                          fit: BoxFit.contain,
                          frameBuilder: (ctx, child, frame, sync) =>
                              frame == null ? const SizedBox.shrink() : child,
                          errorBuilder: (ctx, e, st) => Center(
                            child: Text(
                              s.alias,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: p.stickers.length),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
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
          ?action,
        ],
      ),
    ),
  );
}
