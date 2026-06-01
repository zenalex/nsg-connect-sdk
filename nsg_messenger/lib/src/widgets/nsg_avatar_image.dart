import 'package:flutter/material.dart';

import '../messages/attachments/mxc_image_provider.dart';
import '../messenger_runtime.dart';

/// **B16-extension**: универсальный круглый аватар.
///
/// Поведение:
///   * `mxcUrl != null && !empty` → подтягивает thumbnail (server-side
///     Synapse media) через [MxcImageProvider]. Пока загружается /
///     если падает — рендерим gradient-fallback с инициалами.
///   * `mxcUrl == null` → сразу gradient-fallback.
///
/// **Цвет fallback-а** detеrминирован: hue = sum-of-codeunits(name) %
/// 360. Тот же алгоритм используется в `glass_chat_row.dart` (chatista)
/// и `group_settings_screen.dart` — visual identity юзера не меняется
/// в зависимости от места рендеринга.
///
/// **Кэш**: `MxcImageProvider` интегрирован в Flutter `imageCache` (LRU).
/// Аватар одного юзера, отрендеренный с одинаковым `size`, дёрнет
/// сервер только один раз за TTL imageCache.
class NsgAvatarImage extends StatelessWidget {
  const NsgAvatarImage({
    super.key,
    required this.mxcUrl,
    required this.fallbackName,
    this.size = 40,
  });

  final String? mxcUrl;
  final String fallbackName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = mxcUrl;
    if (url == null || url.isEmpty) {
      return _GradientFallback(name: fallbackName, size: size);
    }

    final client = MessengerRuntime.instance.client;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final pxSize = (size * dpr).round();
    final provider = MxcImageProvider(
      mxcUrl: url,
      thumbnailRpc: client.messenger.downloadAttachmentThumbnail,
      fullSizeRpc: client.messenger.downloadAttachment,
      width: pxSize,
      height: pxSize,
    );

    return ClipOval(
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        // Если frame ещё не построен — fallback gradient (нет белой
        // вспышки или пустого круга).
        frameBuilder: (context, child, frame, wasSync) {
          if (frame == null) {
            return _GradientFallback(name: fallbackName, size: size);
          }
          return child;
        },
        errorBuilder: (_, _, _) =>
            _GradientFallback(name: fallbackName, size: size),
      ),
    );
  }
}

/// Gradient + инициалы. Single source of truth для fallback styling.
class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.name, required this.size});

  final String name;
  final double size;

  int get _hue {
    var sum = 0;
    for (final c in name.codeUnits) {
      sum += c;
    }
    return sum % 360;
  }

  String get _initials {
    final parts = name.split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1.0, h, s, l).toColor();

  @override
  Widget build(BuildContext context) {
    final h = _hue.toDouble();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _hsl(h, 0.55, 0.62),
            _hsl((h + 40) % 360, 0.6, 0.48),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
