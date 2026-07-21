import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messages/attachments/mxc_image_provider.dart';
import '../messenger_runtime.dart';

/// Размер рендера визитки (§4 спеки: `full | tile | intro`; intro —
/// итер.2 вместе с интро-карточкой первого контакта).
enum ContactCardSize { full, tile }

/// **TASK52 итер.1**: клиентский рендер визитки по server-side JSON
/// (стиль = данные, не растр — §4 спеки): дёшево по трафику,
/// автоконтраст на клиенте, тёмная тема из коробки.
///
/// Шаблоны:
///   * `gradient` — линейный градиент gradientStart→gradientEnd;
///   * `monogram` — тон gradientStart + крупные инициалы по центру;
///   * `photo` — mxc-фото через [MxcImageProvider] (authenticated
///     media), деградация до градиента пока грузится/при ошибке.
///
/// Имя — понизу (full) с автоконтрастом ([contrastOn]) если nameColor
/// не задан; для photo — всегда scrim-градиент понизу (читаемость
/// поверх произвольного фото).
class ContactCardView extends StatelessWidget {
  const ContactCardView({
    super.key,
    required this.card,
    this.size = ContactCardSize.full,
    this.borderRadius,
  });

  final ContactCardInfo card;
  final ContactCardSize size;

  /// null = дефолт по размеру (full 20, tile 16).
  final BorderRadius? borderRadius;

  /// Автоконтраст: цвет текста поверх [background] — тёплый белый на
  /// тёмном, чернильный на светлом (токены Chatista Glass).
  static Color contrastOn(Color background) =>
      background.computeLuminance() > 0.45
      ? const Color(0xFF1A0F1A)
      : const Color(0xF5FFFCF8);

  static Color parseHex(String? hex, Color fallback) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) {
      return fallback;
    }
    final v = int.tryParse(hex.substring(1), radix: 16);
    return v == null ? fallback : Color(0xFF000000 | v);
  }

  /// Пресеты начертания имени (итер.1 — вариации системного шрифта;
  /// бандл OFL-шрифтов отложен, см. TASK52.md §4).
  static TextStyle nameStyle(String? preset, double fontSize, Color color) {
    switch (preset) {
      case 'bold':
        return TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );
      case 'airy':
        return TextStyle(
          color: color,
          fontSize: fontSize * 0.92,
          fontWeight: FontWeight.w400,
          letterSpacing: 2.4,
        );
      case 'mono':
        return TextStyle(
          color: color,
          fontSize: fontSize * 0.9,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier New', 'Courier'],
        );
      case 'classic':
      default:
        return TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        );
    }
  }

  Color get _gradStart => parseHex(card.gradientStart, const Color(0xFFE89A55));
  Color get _gradEnd => parseHex(card.gradientEnd, const Color(0xFF1F1A15));

  /// Базовый цвет для автоконтраста имени (усреднение градиента; для
  /// photo нижняя зона всегда затемнена scrim-ом → белый текст).
  Color get _nameBase => card.template == 'photo'
      ? const Color(0xFF1F1A15)
      : Color.lerp(_gradStart, _gradEnd, 0.6)!;

  String get _initials {
    final name = (card.displayName ?? '').trim();
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final full = size == ContactCardSize.full;
    final radius =
        borderRadius ?? BorderRadius.circular(full ? 20 : 16);
    final nameColor = card.nameColor != null
        ? parseHex(card.nameColor, Colors.white)
        : contrastOn(_nameBase);
    final nameSize = full ? 30.0 : 19.0;

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: full ? 3 / 4 : 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _background(context),
            // Scrim понизу для photo — имя читается на любом фото.
            if (card.template == 'photo')
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.55, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            if (card.template == 'monogram')
              Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: nameColor.withValues(alpha: 0.32),
                    fontSize: full ? 120 : 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(full ? 20 : 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.displayName ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle(card.nameFontStyle, nameSize,
                        card.template == 'photo' ? Colors.white : nameColor),
                  ),
                  if (full &&
                      (card.jobTitle != null || card.company != null)) ...[
                    const SizedBox(height: 4),
                    Text(
                      [card.jobTitle, card.company]
                          .whereType<String>()
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: (card.template == 'photo'
                                ? Colors.white
                                : nameColor)
                            .withValues(alpha: 0.72),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background(BuildContext context) =>
      buildCardBackground(context, card);

  /// Фоновый слой визитки (градиент / фото с деградацией до градиента).
  /// Общий для [ContactCardView] и [ContactCardBackdrop].
  static Widget buildCardBackground(
    BuildContext context,
    ContactCardInfo card,
  ) {
    final start = parseHex(card.gradientStart, const Color(0xFFE89A55));
    final end = parseHex(card.gradientEnd, const Color(0xFF1F1A15));
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
    );
    final mxc = card.backgroundMxc;
    if (card.template != 'photo' || mxc == null || mxc.isEmpty) {
      return gradient;
    }
    // Runtime может быть не инициализирован (тесты) — деградация.
    if (!MessengerRuntime.instance.isInitialized) return gradient;
    final client = MessengerRuntime.instance.client;
    return Image(
      image: MxcImageProvider(
        mxcUrl: mxc,
        thumbnailRpc: client.messenger.downloadAttachmentThumbnail,
        fullSizeRpc: client.messenger.downloadAttachment,
        width: 900,
        height: 1200,
      ),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSync) =>
          frame == null ? gradient : child,
      errorBuilder: (_, _, _) => gradient,
    );
  }
}

/// **TASK52 итер.1 (§3A.4, экран звонка)**: только ФОН визитки — без
/// имени (имя/кнопки рисует сам call-оверлей поверх). Заполняет родителя
/// (fullscreen) + тёмный scrim, чтобы контролы звонка читались на любом
/// фоне.
class ContactCardBackdrop extends StatelessWidget {
  const ContactCardBackdrop({super.key, required this.card});

  final ContactCardInfo card;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ContactCardView.buildCardBackground(context, card),
        // Scrim: сверху легче, к низу плотнее — под кнопками звонка.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
