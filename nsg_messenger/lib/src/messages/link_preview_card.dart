/// **issue #90**: карточка превью под сообщением.
///
/// Запрос оператора: «обычно по ссылке в мессенджерах запрашивают данные и
/// отображают с заголовком с сайта. Имеет смысл повторить для удобства».
///
/// Данные приносит сервер ([LinkPreviewStore]) — клиент по ссылке НЕ ходит
/// (см. `LinkPreviewService`: иначе ссылка-ловушка собрала бы IP каждого,
/// кто открыл переписку). Единственное, за чем клиент идёт наружу сам, —
/// картинка превью: её адрес человек и так видит в ленте.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:url_launcher/url_launcher.dart';

import 'link_preview_store.dart';
import 'link_preview_urls.dart';

/// Ссылка из тела сообщения → карточка под ним (если сервер её знает).
///
/// Отдельный виджет, а не логика в пузыре: пузырь — `StatelessWidget`, а
/// здесь нужен свой жизненный цикл (спросить, дождаться, перерисоваться), и
/// тащить его в пузырь значило бы делать состояние у всех сообщений ленты
/// ради тех немногих, где есть ссылка.
class LinkPreviewSection extends StatefulWidget {
  const LinkPreviewSection({
    super.key,
    required this.store,
    required this.body,
    required this.textColor,
    required this.accentColor,
    this.onOpen,
  });

  final LinkPreviewStore store;

  /// Тело сообщения — ссылку ищем в нём же, что и рендер (см.
  /// [extractPreviewUrls]).
  final String body;

  final Color textColor;
  final Color accentColor;

  /// Открыть ссылку. Null → `url_launcher` (в тестах подменяется).
  final void Function(String url)? onOpen;

  @override
  State<LinkPreviewSection> createState() => _LinkPreviewSectionState();
}

class _LinkPreviewSectionState extends State<LinkPreviewSection> {
  LinkPreviewView? _view;
  String? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LinkPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сообщение отредактировали — ссылка могла смениться или исчезнуть.
    if (oldWidget.body != widget.body) _load();
  }

  void _load() {
    final urls = extractPreviewUrls(widget.body);
    final url = urls.isEmpty ? null : urls.first;
    _url = url;
    if (url == null) {
      _view = null;
      return;
    }
    // Известное — сразу, без единого лишнего кадра пустоты: при прокрутке
    // назад пузыри пересоздаются, и «мигание» карточки было бы заметно.
    if (widget.store.isResolved(url)) {
      _view = widget.store.peek(url);
      return;
    }
    _view = null;
    widget.store.resolve(url).then((view) {
      // Пузырь мог уехать из ленты или сообщение — смениться, пока ходили.
      if (!mounted || _url != url || view == null) return;
      setState(() => _view = view);
    });
  }

  void _open(String url) {
    final handler = widget.onOpen;
    if (handler != null) {
      handler(url);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // best-effort: у внешнего адреса может не быть обработчика в системе.
    launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    if (view == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LinkPreviewCard(
        preview: view,
        textColor: widget.textColor,
        accentColor: widget.accentColor,
        onTap: () => _open(view.url),
      ),
    );
  }
}

/// Сама карточка. Без состояния и без сети — чтобы её вёрстку можно было
/// проверить тестом, не поднимая ни стора, ни клиента.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({
    super.key,
    required this.preview,
    required this.textColor,
    required this.accentColor,
    this.onTap,
  });

  final LinkPreviewView preview;
  final Color textColor;
  final Color accentColor;
  final VoidCallback? onTap;

  /// Высота картинки. Ограничена намеренно: превью — подпись к сообщению, а
  /// не сама публикация, и картинка на пол-экрана вытеснила бы переписку.
  static const double imageHeight = 132;

  /// Заголовок сайта, если он его не назвал, — по хосту. Пустая шапка
  /// выглядит как недогруженная карточка.
  String? get _siteLabel {
    final name = preview.siteName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final host = Uri.tryParse(preview.url)?.host;
    if (host == null || host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  @override
  Widget build(BuildContext context) {
    final site = _siteLabel;
    final title = preview.title?.trim();
    final description = preview.description?.trim();
    final image = preview.imageUrl;

    return InkWell(
      key: const Key('linkPreviewCard'),
      onTap: onTap,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(6),
        bottomRight: Radius.circular(6),
      ),
      child: Container(
        // Ширину не задаём: карточка живёт внутри пузыря и обязана
        // подчиняться его ширине, а не расталкивать её.
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 3)),
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (site != null)
              Text(
                site,
                key: const Key('linkPreviewSite'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (title != null && title.isNotEmpty) ...[
              if (site != null) const SizedBox(height: 2),
              Text(
                title,
                key: const Key('linkPreviewTitle'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                description,
                key: const Key('linkPreviewDescription'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
            if (image != null && image.isNotEmpty) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  image,
                  key: const Key('linkPreviewImage'),
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Картинка не загрузилась — карточка остаётся текстовой.
                  // Битый прямоугольник посреди переписки хуже, чем его
                  // отсутствие, и «не работает» он ровно на чужой стороне.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
