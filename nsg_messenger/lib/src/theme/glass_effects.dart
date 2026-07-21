import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'glass_blur.dart';

/// **Эффекты стекла: рантайм-выключатель (issue #26).**
///
/// Профилирование показало, что цена `BackdropFilter` целиком зависит от
/// бэкенда рендера — один и тот же код, данные и дизайн:
///
/// | устройство | бэкенд | blur ВКЛ | blur ВЫКЛ (авто) |
/// |---|---|---|---|
/// | HONOR VNE-LX1 (PowerVR GE8320) | Impeller **GLES** | 40.5 мс → 8 fps | **17.7 мс** |
/// | iPhone 15 Pro (A17 Pro) | Impeller Metal | 2.4 мс | не отключается |
/// | MacBook M2 | Impeller Metal | 4.7 мс | не отключается |
///
/// (raster avg, скролл списка чатов; финальная верификация — живая петля
/// на HONOR: авто-режим отключил эффекты сам и дал 17.67 мс, ручное
/// «Вкл» вернуло 40.16 — совпало с базовой линией до сотых. Полный отчёт
/// с методикой: nsg-connect#26.)
///
/// На Metal/Vulkan стекло практически бесплатно; на GLES-фолбэке —
/// разорительно, причём ослабление sigma не помогает (28→12.6 даёт 6%,
/// см. `glass_blur.dart`). Единственная работающая деградация —
/// **не создавать `BackdropFilter`-узлы вовсе**: даже sigma 0 оставляет
/// узлу его фиксированную цену (readback подложки каждый кадр). Вместо
/// блюра под панель подкладывается почти непрозрачная заливка
/// [kGlassOffBackplate] (issue #48) — обычный однослойный paint, для
/// GPU бесплатный.
///
/// Отсюда три режима:
///  * [GlassEffectsMode.auto] (дефолт) — по способностям устройства:
///    хост-приложение сообщает их через [configureDevice];
///  * [GlassEffectsMode.on] / [GlassEffectsMode.off] — ручной override
///    пользователя (настройки темы).
///
/// SDK намеренно не знает, КАК определяется способность устройства —
/// это платформенная эвристика хост-приложения (Vulkan-фича, объём RAM).
enum GlassEffectsMode {
  auto,
  on,
  off;

  /// Персистентный id (никогда не менять без миграции).
  String get id => name;

  static GlassEffectsMode fromIdOrAuto(String? raw) =>
      values.asNameMap()[raw] ?? GlassEffectsMode.auto;
}

/// Синглтон-резолвер «рисовать ли blur». Все glass-поверхности слушают
/// [enabledListenable] через [GlassBackdrop] — смена режима в настройках
/// перерисовывает их без перезапуска.
class GlassEffects {
  GlassEffects._();

  static final GlassEffects instance = GlassEffects._();

  bool _deviceCapable = true;
  GlassEffectsMode _mode = GlassEffectsMode.auto;

  final ValueNotifier<bool> _enabled = ValueNotifier<bool>(true);

  /// true — рисуем полноценный blur; false — glass-поверхности
  /// полупрозрачны, но без `BackdropFilter`.
  ValueListenable<bool> get enabledListenable => _enabled;
  bool get enabled => _enabled.value;

  GlassEffectsMode get mode => _mode;
  bool get deviceCapable => _deviceCapable;

  /// Хост-приложение сообщает способность устройства (обычно один раз,
  /// при boot, ДО первого кадра — чтобы не мигать сменой поверхности).
  void configureDevice({required bool strongBlurCapable}) {
    _deviceCapable = strongBlurCapable;
    _recompute();
  }

  /// Смена режима (настройки темы). Персистенс — на стороне хоста.
  void setMode(GlassEffectsMode mode) {
    _mode = mode;
    _recompute();
  }

  void _recompute() {
    _enabled.value = switch (_mode) {
      GlassEffectsMode.on => true,
      GlassEffectsMode.off => false,
      GlassEffectsMode.auto => _deviceCapable,
    };
  }

  /// Только для тестов: вернуть дефолтное состояние.
  @visibleForTesting
  void resetForTest() {
    _deviceCapable = true;
    _mode = GlassEffectsMode.auto;
    _recompute();
  }
}

/// **Подложка glass-панели в режиме «без блюра» (issue #48).**
///
/// Без `BackdropFilter` полупрозрачный тинт панели (белый ~0.12 у
/// вызывающих) перестаёт быть «матовым стеклом» и превращается в дырку:
/// сквозь панель читается контент под ней — пользователь описал это как
/// «кашу». Поэтому в off-режиме [GlassBackdrop] сам подкладывает под
/// [child] эту почти непрозрачную заливку.
///
/// Почему именно такой цвет и альфа:
///  * тон `0x2A2330` — тот же тёмный нейтральный с лёгким пурпуром, что
///    уже выбран в `chatista_theme.dart` как `inverseSurface` glass-тем
///    (единственная там НЕпрозрачная тёмная поверхность, фон SnackBar).
///    Он нейтрален ко всем четырём glass-палитрам (sunset/oceanic/
///    aurora/ember — все тёмные «jewel»-обои), в отличие от кофейного
///    [kOverlayBaseInk] классической тёмной темы, который под
///    сине-зелёным oceanic уходил бы в грязно-бурый;
///  * alpha 0.90 (`0xE6`), а не 1.0 — обои под панелью ещё едва
///    угадываются (панель не выглядит глухой заплаткой и палитры
///    различимы), но контраст контента под ней падает до ~10% и текст
///    не читается. Это ровно просьба пользователя: «непрозрачную или
///    значительно менее прозрачную».
///
/// Тинт вызывающего (его `DecoratedBox`) ложится ПОВЕРХ подложки и
/// сохраняет фирменный оттенок панели.
const Color kGlassOffBackplate = Color(0xE62A2330);

/// Замена прямому `BackdropFilter(filter: glassBlur(σ), child: ...)`.
///
/// При включённых эффектах строит ровно его; при выключенных — кладёт
/// под [child] почти непрозрачную подложку [kGlassOffBackplate]: узла
/// фильтра в дереве нет, его per-frame цена (readback + blur-проход) не
/// платится, а панель не становится «дыркой» (issue #48). Внешние
/// `ClipRRect`/`ClipOval` и `DecoratedBox` остаются у вызывающего —
/// форма и тинт поверхности сохраняются в обоих режимах (подложка
/// обрезается его же клипом).
///
/// Всегда используй его вместо голого `BackdropFilter` на glass-
/// поверхностях — иначе узел выпадет из настройки «Эффекты стекла».
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    required this.designSigma,
    required this.child,
  });

  /// Sigma из дизайна (до масштабирования `GLASS_BLUR_PCT`).
  final double designSigma;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlassEffects.instance.enabledListenable,
      builder: (context, enabled, _) => enabled
          ? BackdropFilter(filter: glassBlur(designSigma), child: child)
          // Off-режим: НЕ голый child (иначе полупрозрачный тинт
          // вызывающего превращает панель в «дырку», issue #48), а child
          // на почти непрозрачной подложке. ColoredBox, а не
          // DecoratedBox — это один дешёвый drawRect, никакой лишней
          // цены в горячем off-режиме слабых устройств.
          : ColoredBox(color: kGlassOffBackplate, child: child),
    );
  }
}
