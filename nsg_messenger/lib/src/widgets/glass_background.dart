import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// **CHATista Glass design (Claude Design handoff 2026-05-24)**:
/// vivid multi-blob radial-gradient wallpaper that sells the "glass"
/// effect of the rest of the UI (translucent surfaces let the wallpaper
/// show through).
///
/// **Painting strategy** — CustomPainter with [BlendMode.screen] per
/// blob so additive light-mixing matches the CSS `mix-blend-mode: screen`
/// of the design source-of-truth. Blob sizes scale to viewport
/// shortest-side (design constants are tuned for ~390px iPhone width —
/// on desktop windows the fixed sizes would shrink to tiny corner dots
/// with dark middle, which is the OPPOSITE of design intent).
///
/// **Usage** — host-app wraps app body in a [Stack] with this widget
/// `Positioned.fill`-ed at the base:
/// ```dart
/// return Stack(
///   children: [
///     Positioned.fill(child: GlassBackground(palette: GlassPalette.sunset)),
///     // app shell on top
///   ],
/// );
/// ```
/// **Производительность (issue #26).** Фон лежит `Positioned.fill` в корневом
/// `Stack` под ВСЕМ приложением (`main.dart`), а рисование тут дорогое:
/// полноэкранный `saveLayer` + 4 радиальных градиента радиусом ~0.4 диагонали
/// с `BlendMode.screen`. Пока это исполнялось на каждый кадр, скролл на слабом
/// Android держал 8–9 fps.
///
/// **Почему одного `RepaintBoundary` не хватило.** Он создаёт отдельный слой,
/// но НЕ гарантирует его растеризацию в переиспользуемую текстуру: решение
/// кэшировать принимает raster cache движка по своим порогам, и полноэкранный
/// слой с `saveLayer` внутри — плохой кандидат. Замер на HONOR VNE-LX1
/// (Android 14, PowerVR GE8320, 60 Гц), сценарий «скролл чата», одни и те же
/// жесты:
///
/// | сборка | raster avg |
/// |---|---|
/// | без `RepaintBoundary` | 113.82 мс |
/// | с `RepaintBoundary` | 113.54 / 113.97 мс (два прогона) |
/// | фон не рисуется вовсе | 5.35 мс |
///
/// То есть слой создавался, а работа выполнялась ровно та же.
///
/// **Что сделано.** Обои растеризуются ОДИН раз в [ui.Image] и дальше
/// блитятся готовой текстурой. `saveLayer` и градиенты уходят с горячего
/// пути гарантированно, а не на усмотрение эвристики. Пересборка картинки —
/// только при смене палитры или размера холста.
///
/// Математика блендинга при этом не меняется: `BlendMode.screen` считается
/// внутри offscreen-картинки ровно так же, как считался внутри `saveLayer`
/// на экране — тот же порядок операций, тот же результат.
class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, this.palette = GlassPalette.sunset});

  final GlassPalette palette;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground> {
  ui.Image? _image;
  Size? _imageSize;
  double? _imageDpr;
  GlassPalette? _imagePalette;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  /// Растеризует обои в [ui.Image], если кэш пуст или его ключ устарел.
  ///
  /// Вызывается из `build` и намеренно не дёргает `setState`: результат
  /// используется тут же, в этом же кадре, а лишний перестроечный цикл
  /// только добавил бы работы.
  void _ensureImage(_GlassPaletteSpec spec, Size size, double dpr) {
    if (size.isEmpty || !size.isFinite) return;
    final fresh =
        _image != null &&
        _imagePalette == widget.palette &&
        _imageSize == size &&
        _imageDpr == dpr;
    if (fresh) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Пишем в физических пикселях, иначе на HiDPI картинка размылится.
    canvas.scale(dpr);
    _WallpaperPainter(spec: spec).paint(canvas, size);
    final picture = recorder.endRecording();
    try {
      final image = picture.toImageSync(
        (size.width * dpr).ceil(),
        (size.height * dpr).ceil(),
      );
      _retire(_image);
      _image = image;
      _imageSize = size;
      _imageDpr = dpr;
      _imagePalette = widget.palette;
    } catch (_) {
      // Растеризация недоступна (например, в widget-тестах без GPU) —
      // рисуем напрямую. Медленнее, но корректно.
      _retire(_image);
      _image = null;
    } finally {
      picture.dispose();
    }
  }

  /// Освобождает старую текстуру ПОСЛЕ кадра: на неё ещё может ссылаться
  /// уже собранный слой, и `dispose` прямо в `build` уронил бы отрисовку.
  void _retire(ui.Image? old) {
    if (old == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final spec = _GlassPaletteSpec.forPalette(widget.palette);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          _ensureImage(spec, size, dpr);
          final image = _image;
          return CustomPaint(
            size: size.isFinite ? size : Size.infinite,
            painter: image == null
                ? _WallpaperPainter(spec: spec)
                : _CachedWallpaperPainter(image: image, spec: spec),
          );
        },
      ),
    );
  }
}

/// Блитит уже растеризованные обои. Вся стоимость кадра — одна текстура.
class _CachedWallpaperPainter extends CustomPainter {
  _CachedWallpaperPainter({required this.image, required this.spec});

  final ui.Image image;
  final _GlassPaletteSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    // Тип может смениться при переходе кэш ↔ прямая отрисовка — тогда
    // перерисовать обязаны.
    if (old is! _CachedWallpaperPainter) return true;
    return !identical(old.image, image) || old.spec.base != spec.base;
  }
}

/// 4 wallpaper presets matching Claude Design `GLASS_PALETTES`.
enum GlassPalette { sunset, oceanic, aurora, ember }

class _GlassPaletteSpec {
  const _GlassPaletteSpec({
    required this.base,
    required this.accent,
    required this.blobs,
  });

  final Color base;
  final Color accent;
  final List<_BlobSpec> blobs;

  static _GlassPaletteSpec forPalette(GlassPalette p) {
    switch (p) {
      case GlassPalette.sunset:
        return const _GlassPaletteSpec(
          base: Color(0xFF2A1428),
          accent: Color(0xFFE89A55),
          blobs: [
            _BlobSpec(
              xFraction: 0.15,
              yFraction: 0.12,
              color: Color(0xFF5A2C57),
            ),
            _BlobSpec(
              xFraction: 0.85,
              yFraction: 0.20,
              color: Color(0xFFD45A78),
            ),
            _BlobSpec(
              xFraction: 0.20,
              yFraction: 0.85,
              color: Color(0xFFE89A55),
            ),
            _BlobSpec(
              xFraction: 0.88,
              yFraction: 0.92,
              color: Color(0xFFF0CFA0),
            ),
          ],
        );
      case GlassPalette.oceanic:
        return const _GlassPaletteSpec(
          base: Color(0xFF0F1F38),
          accent: Color(0xFF5BB8A8),
          blobs: [
            _BlobSpec(
              xFraction: 0.12,
              yFraction: 0.15,
              color: Color(0xFF1E3A5F),
            ),
            _BlobSpec(
              xFraction: 0.85,
              yFraction: 0.18,
              color: Color(0xFF4A7FB8),
            ),
            _BlobSpec(
              xFraction: 0.15,
              yFraction: 0.88,
              color: Color(0xFF5BB8A8),
            ),
            _BlobSpec(
              xFraction: 0.90,
              yFraction: 0.90,
              color: Color(0xFFA8E0D0),
            ),
          ],
        );
      case GlassPalette.aurora:
        return const _GlassPaletteSpec(
          base: Color(0xFF13092E),
          accent: Color(0xFFA65BD8),
          blobs: [
            _BlobSpec(
              xFraction: 0.12,
              yFraction: 0.10,
              color: Color(0xFF2D1B5A),
            ),
            _BlobSpec(
              xFraction: 0.85,
              yFraction: 0.15,
              color: Color(0xFFA65BD8),
            ),
            _BlobSpec(
              xFraction: 0.15,
              yFraction: 0.88,
              color: Color(0xFF5BD8A6),
            ),
            _BlobSpec(
              xFraction: 0.90,
              yFraction: 0.85,
              color: Color(0xFFD8E05B),
            ),
          ],
        );
      case GlassPalette.ember:
        return const _GlassPaletteSpec(
          base: Color(0xFF1F0808),
          accent: Color(0xFFE0682E),
          blobs: [
            _BlobSpec(
              xFraction: 0.10,
              yFraction: 0.10,
              color: Color(0xFF3D0E0E),
            ),
            _BlobSpec(
              xFraction: 0.90,
              yFraction: 0.15,
              color: Color(0xFFA82F3E),
            ),
            _BlobSpec(
              xFraction: 0.15,
              yFraction: 0.88,
              color: Color(0xFFE0682E),
            ),
            _BlobSpec(
              xFraction: 0.88,
              yFraction: 0.90,
              color: Color(0xFFF5C26B),
            ),
          ],
        );
    }
  }
}

class _BlobSpec {
  const _BlobSpec({
    required this.xFraction,
    required this.yFraction,
    required this.color,
  });
  final double xFraction;
  final double yFraction;
  final Color color;
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter({required this.spec});

  final _GlassPaletteSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Solid base color (deep aubergine / navy / indigo / crimson).
    canvas.drawRect(Offset.zero & size, Paint()..color = spec.base);

    // 2. Blob radius scales to viewport so blobs fill the screen
    //    proportionally on both phone-sized (~390px) and desktop windows
    //    (1280+). Design constants are for ~390px width — scale factor
    //    of 0.75 × longest side keeps the visual density consistent.
    final blobRadius = math.max(size.longestSide * 0.4, 220.0);

    // 3. Paint each blob with BlendMode.screen — additive light-mixing
    //    where blobs overlap, exactly matching CSS `mix-blend-mode:
    //    screen` of the design source. Use saveLayer so screen blend is
    //    isolated to the wallpaper layer (doesn't affect widgets above).
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final blob in spec.blobs) {
      final cx = size.width * blob.xFraction;
      final cy = size.height * blob.yFraction;
      final center = Offset(cx, cy);
      final rect = Rect.fromCircle(center: center, radius: blobRadius);
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [blob.color, blob.color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ).createShader(rect);
      canvas.drawCircle(center, blobRadius, paint);
    }
    canvas.restore();
  }

  /// Перерисовываем только при смене палитры.
  ///
  /// Сравниваем `base` + `accent`, а не один `base`: сейчас у всех четырёх
  /// палитр базовые цвета различаются, и проверки по `base` формально хватает,
  /// но это держится на совпадении — палитра с тем же `base` и другими блобами
  /// молча не применилась бы. Цена ошибки выросла: с `RepaintBoundary` (см.
  /// [GlassBackground.build]) слой кэшируется агрессивнее, и промах здесь
  /// означал бы «тема не сменилась до перестроения виджета».
  @override
  bool shouldRepaint(covariant _WallpaperPainter old) =>
      old.spec.base != spec.base ||
      old.spec.accent != spec.accent ||
      old.spec.blobs.length != spec.blobs.length;
}
