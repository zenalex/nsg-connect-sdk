import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../i18n/generated/nsg_l10n.dart';
import '../../messenger_runtime.dart';
import 'image_actions.dart';
import 'mxc_image_provider.dart';

/// Полноэкранный просмотрщик картинок чата с листанием (swipe) по всем
/// картинкам комнаты. Открывается тапом по inline-превью
/// ([AttachmentBubble] → `onOpenImage`); ChatScreen собирает
/// упорядоченный список всех image-вложений и стартовый индекс.
///
/// Каждая страница — full-size download через [MxcImageProvider]
/// (`fullSize: true`) с pinch-zoom ([PhotoView]). AppBar показывает имя
/// файла и позицию «N / total».
class ChatImageGallery extends StatefulWidget {
  const ChatImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.thumbnailRpc,
    required this.fullSizeRpc,
    this.actions,
  });

  /// Все картинки чата в порядке ленты (старые → новые, как рендерит UI).
  final List<AttachmentRef> images;

  /// С какой картинки открыть (индекс в [images]).
  final int initialIndex;

  final DownloadAttachmentThumbnailRpc thumbnailRpc;
  final DownloadAttachmentRpc fullSizeRpc;

  /// Share/copy-действия. `null` → строим из [fullSizeRpc] (прод-путь);
  /// тесты инъектят фейк без реальных плагинов.
  final ImageActions? actions;

  @override
  State<ChatImageGallery> createState() => _ChatImageGalleryState();
}

class _ChatImageGalleryState extends State<ChatImageGallery> {
  late final PageController _pageController;
  late final ImageActions _actions;
  late int _current;

  /// Идёт скачивание/запись для share/copy — блокируем повторный тап.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _current);
    _actions =
        widget.actions ?? ImageActions.fromDownloader(widget.fullSizeRpc);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Поделиться (mobile/web) / скопировать (desktop) текущую картинку.
  Future<void> _runPrimaryAction() async {
    // Захватываем l10n/messenger ДО await — context валиден сейчас.
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final att = widget.images[_current];
    final isShare = _actions.primaryAction() == ImagePrimaryAction.share;
    setState(() => _busy = true);
    try {
      await _actions.runPrimary(att);
      if (!mounted) return;
      // Share показывает системный лист (feedback сам по себе) — snackbar
      // только на copy. На ошибку — snackbar в обоих случаях.
      if (!isShare) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(l.imageCopiedSnack),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      // Пользователь видит ошибку — трекер обязан видеть причину. share и copy
      // — разные платформенные пути (системный лист vs буфер обмена) и ломаются
      // по-разному, поэтому вариант в теге.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'image.action': isShare ? 'share' : 'copy'},
      );
      messenger?.showSnackBar(
        SnackBar(
          content: Text(isShare ? l.shareFailed : l.imageCopyFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Пролистать на [delta] страниц с зажимом в границы. Возвращает false,
  /// если листать некуда (одна картинка / уже край) — вызывающий тогда
  /// не «съедает» клавишу.
  bool _jump(int delta) {
    final target = _current + delta;
    if (target < 0 || target >= widget.images.length) return false;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    return true;
  }

  /// Клавиатура десктопа: Escape закрывает, ←/→ листают.
  ///
  /// Обычный [Focus.onKeyEvent] здесь достаточен (в отличие от
  /// `MessageComposer`, где пришлось вешать глобальный
  /// `HardwareKeyboard.addHandler`): там ключи перехватывал `EditableText`
  /// со своими встроенными шорткатами, а на этом экране текстовых полей
  /// нет вовсе. Focus стоит НАД `Scaffold`, поэтому события всплывают
  /// сюда даже когда фокус ушёл на кнопку в AppBar.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // KeyRepeatEvent — чтобы удержание стрелки листало серию.
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return _jump(-1) ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return _jump(1) ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final total = widget.images.length;
    final isShare = _actions.primaryAction() == ImagePrimaryAction.share;
    // Имя файла у картинок не показываем (решение пользователя) — оно
    // остаётся только в Matrix-событии. В заголовке — лишь позиция «N / total».
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            if (total > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '${_current + 1} / $total',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
              ),
            // Поделиться (mobile/web) / Скопировать (desktop) текущую картинку.
            IconButton(
              tooltip: isShare
                  ? l.messageActionShare
                  : l.messageActionCopyImage,
              icon: Icon(isShare ? Icons.ios_share : Icons.content_copy),
              onPressed: _busy ? null : _runPrimaryAction,
            ),
          ],
        ),
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: total,
              pageController: _pageController,
              onPageChanged: (i) => setState(() => _current = i),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (_, _) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              builder: (context, index) {
                final att = widget.images[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: MxcImageProvider(
                    mxcUrl: att.mxcUrl,
                    thumbnailRpc: widget.thumbnailRpc,
                    fullSizeRpc: widget.fullSizeRpc,
                    fullSize: true,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(tag: att.mxcUrl),
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
            // Кнопки листания — только там, где свайпнуть нечем (desktop/web)
            // и только когда есть что листать. На краях набора кнопка
            // неактивна, чтобы не обещать несуществующие соседние картинки.
            //
            // Positioned-полоски по краям, а НЕ Positioned.fill: полоска
            // шириной с саму кнопку не перекрывает центр кадра, поэтому
            // pinch-zoom и панорама PhotoView под ней остаются доступны.
            // По вертикали кнопка отцентрована — с индикатором «N / total»
            // в AppBar не пересекается.
            if (_actions.needsPagingButtons && total > 1) ...[
              _PageArrow(
                icon: Icons.chevron_left,
                alignLeft: true,
                onPressed: _current > 0 ? () => _jump(-1) : null,
              ),
              _PageArrow(
                icon: Icons.chevron_right,
                alignLeft: false,
                onPressed: _current < total - 1 ? () => _jump(1) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Кнопка листания у края кадра. [onPressed] == null → край набора,
/// кнопка видна, но неактивна (приглушена).
class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.alignLeft,
    required this.onPressed,
  });

  final IconData icon;
  final bool alignLeft;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: alignLeft ? 8 : null,
      right: alignLeft ? null : 8,
      top: 0,
      bottom: 0,
      child: Center(
        child: DecoratedBox(
          // Подложка — картинка снизу может быть светлой, белая стрелка
          // на ней иначе теряется.
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 32),
            color: Colors.white,
            disabledColor: Colors.white24,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
