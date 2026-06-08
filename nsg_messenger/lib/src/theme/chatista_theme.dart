import 'package:flutter/material.dart';

import '../widgets/glass_background.dart' show GlassPalette;
import 'nsg_messenger_theme.dart';

/// **CHATista — warm/artisanal theme preset** ("barista of chat").
///
/// Design source: handoff bundle from Claude Design (claude.ai/design),
/// authored 2026-05-23/24. Preserves the design's intent pixel-faithfully:
/// cream backgrounds, warm-brown Crema accent, soft 22px bubble radius
/// with 6px tail position matching Telegram convention (own tail BR,
/// peer tail BL).
///
/// **Usage** — host-app passes preset через `NsgMessenger.init`:
/// ```dart
/// await NsgMessenger.init(
///   apiBaseUrl: '...',
///   authTokenProvider: ...,
///   theme: ChatistaTheme.crema(brightness: Brightness.light),
/// );
/// ```
///
/// **5 accent palettes** доступны через factory:
///   * `ChatistaTheme.crema()` — warm brown coffee (DEFAULT — original
///     CHATista identity).
///   * `ChatistaTheme.matcha()` — green tea.
///   * `ChatistaTheme.cobalt()` — deep blue.
///   * `ChatistaTheme.rose()` — warm pink.
///   * `ChatistaTheme.ink()` — monochrome.
///
/// Each respects [Brightness.light] / [Brightness.dark]. Color values
/// directly transcribed from `chatista/project/design-system.jsx`
/// `CHAT_ACCENTS` + `buildTheme(...)` to ensure faithful match.
///
/// **What this preset overrides** vs SDK defaults:
///   * `colorScheme` — full M3 ColorScheme derived from Crema palette.
///   * `bubbleTokens` — radius 22px (vs SDK 16px) + tail 6px (vs 4px),
///     peer-tail flipped to BL (Telegram convention; SDK fallback had
///     TL which differs from popular messenger UX).
///   * `roomTileTokens` — avatarSize 50 (vs 44), contentPadding vertical
///     14 (vs 8) for designer-intended roomy chat list row density.
///
/// **Empty `textTheme`** — inherits host's `MaterialApp.theme.textTheme`.
/// CHATista design uses Geist body + Instrument Serif italic for the
/// "ista" wordmark suffix, but those are host-app-level font decisions
/// (pubspec deps); SDK doesn't ship fonts. Document for host-app at
/// `docs/integration/theming.md`.
class ChatistaTheme {
  ChatistaTheme._();

  /// Default — warm brown coffee accent (original CHATista identity).
  static NsgMessengerTheme crema({Brightness brightness = Brightness.light}) =>
      _build(brightness, _CremaAccent());

  /// Green tea accent.
  static NsgMessengerTheme matcha({Brightness brightness = Brightness.light}) =>
      _build(brightness, _MatchaAccent());

  /// Deep blue accent.
  static NsgMessengerTheme cobalt({Brightness brightness = Brightness.light}) =>
      _build(brightness, _CobaltAccent());

  /// Warm pink accent.
  static NsgMessengerTheme rose({Brightness brightness = Brightness.light}) =>
      _build(brightness, _RoseAccent());

  /// Monochrome (ink) accent.
  static NsgMessengerTheme ink({Brightness brightness = Brightness.light}) =>
      _build(brightness, _InkAccent());

  // ─── Liquid Glass presets (CHATista Glass design — 2026-05-24) ───
  //
  // Translucent-palette themes designed to sit on top of a vivid
  // multi-blob gradient wallpaper (see [GlassBackground] widget).
  // Surfaces use white-alpha so the wallpaper shows through; bubbles
  // are translucent with accent tints. Always-dark — Glass concept
  // doesn't have a light variant in the design source.
  //
  // **Required setup** — host-app must:
  //   1. Wrap app body in a [Stack] with [GlassBackground] at base.
  //   2. Set `MaterialApp.theme.scaffoldBackgroundColor: Colors.transparent`.
  //   3. Pass the same palette enum to both `GlassBackground` and the
  //      matching `ChatistaTheme.glass*()` factory (their accents must
  //      align — Sunset wallpaper → glassSunset theme).
  //
  // **Tier-2 deferred** (Phase2 — needs SDK widget hooks):
  //   * True backdrop-blur on bubbles / app bar / chat tiles. Token
  //     system can't deliver `BackdropFilter` inside `MessageBubble` —
  //     widget code change required.
  //   * Specular highlight gradients (inset shadows — Flutter
  //     `BoxShadow` has no inset; needs Stack overlay rework inside SDK
  //     widgets).
  //   * Active-filter-chip solid-white pill (currently rendered as M3
  //     standard active chip).

  /// Sunset palette — warm aubergine → rose → amber → cream wallpaper,
  /// amber `#E89A55` accent. Original CHATista Glass identity.
  static NsgMessengerTheme glassSunset() => _buildGlass(GlassPalette.sunset);

  /// Oceanic palette — deep blue → mint, accent `#5BB8A8`.
  static NsgMessengerTheme glassOceanic() => _buildGlass(GlassPalette.oceanic);

  /// Aurora palette — purple → violet → lime, accent `#A65BD8`.
  static NsgMessengerTheme glassAurora() => _buildGlass(GlassPalette.aurora);

  /// Ember palette — dark red → amber → orange, accent `#E0682E`.
  static NsgMessengerTheme glassEmber() => _buildGlass(GlassPalette.ember);

  static NsgMessengerTheme _buildGlass(GlassPalette palette) {
    // Accent extracted from palette spec to keep single source of truth
    // with GlassBackground; kept inline here to avoid leaking the spec
    // type to consumers.
    final accent = switch (palette) {
      GlassPalette.sunset => const Color(0xFFE89A55),
      GlassPalette.oceanic => const Color(0xFF5BB8A8),
      GlassPalette.aurora => const Color(0xFFA65BD8),
      GlassPalette.ember => const Color(0xFFE0682E),
    };
    const transparent = Color(0x00000000);
    // White with varying alpha — matches design tokens fg / fgSoft /
    // fgMuted / fgDim (0.96 / 0.72 / 0.5 / 0.34).
    const fg = Color(0xF5FFFCF8); // alpha 245 ≈ 0.96
    const fgSoft = Color(0xB8FFFCF8); // alpha 184 ≈ 0.72
    // fgMuted (0x80FFFCF8 ≈ 0.5) and fgDim (0x57FFFCF8 ≈ 0.34) are not
    // surfaced through M3 ColorScheme slots; they're documented here so
    // a future Phase2 widget-level pass can use them for placeholder/
    // timestamp dim text.
    // Glass surface: rgba(255,255,255,0.10) approximation. Visible only
    // until widgets add true BackdropFilter (Phase2).
    const glassBg = Color(0x1AFFFFFF); // alpha 26 ≈ 0.10
    const glassBgStrong = Color(0x2EFFFFFF); // alpha 46 ≈ 0.18

    // Bubble own / peer rendering currently routes through ColorScheme
    // primary/surface (Tier-1). The accent-tinted-glass + lower-white-
    // alpha-glass distinction from the design source-of-truth lives in
    // bubble widget code (Phase2 task — needs SDK MessageBubble override
    // hook for accurate two-layer translucent rendering with backdrop
    // blur). Documented here so future Phase2 picks the right tint:
    //   bubbleOwn  = alphaBlend(accent @ 33% over glassBgStrong)
    //   bubblePeer = glassBg (rgba(255,255,255,0.10))

    final colorScheme = ColorScheme.dark(
      primary: accent,
      onPrimary: const Color(0xFF1A0F1A), // dark ink for high contrast on accent
      primaryContainer: accent.withValues(alpha: 0.33),
      onPrimaryContainer: fg,
      secondary: accent,
      onSecondary: const Color(0xFF1A0F1A),
      secondaryContainer: glassBg,
      onSecondaryContainer: fg,
      // Surfaces are TRANSPARENT so wallpaper shows through. Host-app
      // must set scaffoldBackgroundColor: Colors.transparent too.
      surface: transparent,
      onSurface: fg,
      surfaceContainerHighest: glassBgStrong,
      surfaceContainerHigh: glassBgStrong,
      surfaceContainer: glassBg,
      surfaceContainerLow: glassBg,
      surfaceContainerLowest: transparent,
      onSurfaceVariant: fgSoft,
      outline: const Color(0x33FFFFFF), // glass border rgba(255,255,255,0.20)
      outlineVariant: const Color(0x14FFFFFF),
      // Online indicator — mint green per design `#8DE89E`.
      tertiary: const Color(0xFF8DE89E),
      onTertiary: const Color(0xFF1A0F1A),
      // #4: SnackBar / inverse surfaces. ColorScheme.dark() не вычисляет эти
      // слоты, а M3 SnackBar берёт inverseSurface (→ fallback onSurface =
      // почти белый) как фон и onInverseSurface (→ fallback surface =
      // transparent) как цвет текста → «белая плашка с невидимым текстом».
      // Задаём явно: тёмная плашка + светлый читаемый текст.
      inverseSurface: const Color(0xFF2A2330),
      onInverseSurface: fg,
    );

    // Bubble shape — same soft 22 / 6 as Crema; design source-of-truth
    // (glass-conv.jsx) inherits radii from the same screen-conversation
    // spec. Peer-tail bottom-LEFT — same Telegram convention.
    const bubbleTokens = NsgMessageBubbleTokens(
      radiusOwn: BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(6),
      ),
      radiusPeer: BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(22),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      maxWidthFraction: 0.78,
      statusIconSize: 11,
      interBubbleSpacing: 6,
      composerPadding: EdgeInsets.fromLTRB(10, 8, 10, 32),
    );

    // Room tile — designer-intended roomy density. List background is
    // visible glass (surface container), not opaque tile.
    const roomTileTokens = NsgRoomTileTokens(
      avatarSize: 50,
      unreadBadgeSize: 20,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      titleSubtitleSpacing: 2,
    );

    return NsgMessengerTheme(
      colorScheme: colorScheme,
      bubbleTokens: bubbleTokens,
      roomTileTokens: roomTileTokens,
    );
  }

  static NsgMessengerTheme _build(Brightness brightness, _Accent a) {
    final isDark = brightness == Brightness.dark;
    final accentColor = isDark ? a.dark : a.light;
    final accentSoft = isDark ? a.softDark : a.soft;

    // Light-theme neutrals (warm cream family — design-system.jsx
    // `buildTheme({dark: false})`).
    const lightBg = Color(0xFFF6F2EC);
    const lightSurface = Color(0xFFFFFEFB);
    const lightSurfaceAlt = Color(0xFFEFE9DF);
    const lightFg = Color(0xFF1F1812);
    const lightFgMuted = Color(0xFF6B5D52);
    // fgDim #9C8B7C — design uses for very-muted hints (placeholder ish);
    // M3 ColorScheme has no direct slot, host-app can read via custom
    // extension if needed.
    const lightSeparator = Color(0x141F1812); // alpha=20 ≈ 0.08
    const lightOnline = Color(0xFF5C9E5C);

    // Dark-theme neutrals (warm deep-brown family — design-system.jsx
    // `buildTheme({dark: true})`).
    const darkBg = Color(0xFF14110E);
    const darkSurface = Color(0xFF1F1A15);
    const darkSurfaceAlt = Color(0xFF2A231C);
    const darkSurfaceRaise = Color(0xFF352C24);
    const darkFg = Color(0xFFF5EFE6);
    const darkFgMuted = Color(0xFF9C8B7C);
    // fgDim #6B5D52 — see lightFgDim comment above.
    const darkSeparator = Color(0x14F5EFE6); // alpha=20 ≈ 0.08
    const darkOnline = Color(0xFF7BB87B);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: accentColor,
            onPrimary: darkBg,
            primaryContainer: accentSoft,
            onPrimaryContainer: darkFg,
            secondary: accentColor,
            onSecondary: darkBg,
            secondaryContainer: accentSoft,
            onSecondaryContainer: darkFg,
            surface: darkSurface,
            onSurface: darkFg,
            surfaceContainerHighest: darkSurfaceRaise,
            surfaceContainerHigh: darkSurfaceAlt,
            surfaceContainer: darkSurfaceAlt,
            surfaceContainerLow: darkBg,
            surfaceContainerLowest: darkBg,
            onSurfaceVariant: darkFgMuted,
            outline: darkSeparator,
            outlineVariant: darkSeparator,
            tertiary: darkOnline,
            onTertiary: darkBg,
          )
        : ColorScheme.light(
            primary: accentColor,
            onPrimary: lightSurface,
            primaryContainer: accentSoft,
            onPrimaryContainer: lightFg,
            secondary: accentColor,
            onSecondary: lightSurface,
            secondaryContainer: accentSoft,
            onSecondaryContainer: lightFg,
            surface: lightSurface,
            onSurface: lightFg,
            surfaceContainerHighest: lightSurfaceAlt,
            surfaceContainerHigh: lightSurfaceAlt,
            surfaceContainer: lightBg,
            surfaceContainerLow: lightBg,
            surfaceContainerLowest: lightBg,
            onSurfaceVariant: lightFgMuted,
            outline: lightSeparator,
            outlineVariant: lightSeparator,
            tertiary: lightOnline,
            onTertiary: lightSurface,
          );

    // Bubble shape `soft` from design-system.jsx (default of 3 shapes).
    // Tail position: own=BR, peer=BL (Telegram convention; flipped from
    // SDK fallback which puts peer tail TL).
    const bubbleTokens = NsgMessageBubbleTokens(
      radiusOwn: BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(6),
      ),
      radiusPeer: BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(22),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      maxWidthFraction: 0.78,
      statusIconSize: 11,
      interBubbleSpacing: 6, // design uses 3px in `roomy`, 1px compact;
      // SDK applies spacing/2 top + bottom, so 6 here → 3px per side ≈
      // design `roomy`. compact-density host-apps still override.
      composerPadding: EdgeInsets.fromLTRB(10, 8, 10, 32), // ios bottom
    );

    // Room tile tokens — designer-intended roomy density (14px vertical
    // padding, 50px avatar).
    const roomTileTokens = NsgRoomTileTokens(
      avatarSize: 50,
      unreadBadgeSize: 20,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      titleSubtitleSpacing: 2,
    );

    return NsgMessengerTheme(
      colorScheme: colorScheme,
      bubbleTokens: bubbleTokens,
      roomTileTokens: roomTileTokens,
    );
  }
}

/// Accent color tuple — `light` / `dark` для brightness-aware build,
/// `soft` / `softDark` для container-style tints (mention chips,
/// reaction backgrounds).
class _Accent {
  const _Accent({
    required this.light,
    required this.dark,
    required this.soft,
    required this.softDark,
  });
  final Color light;
  final Color dark;
  final Color soft;
  final Color softDark;
}

class _CremaAccent extends _Accent {
  const _CremaAccent()
      : super(
          light: const Color(0xFFB8704A),
          dark: const Color(0xFFD89971),
          soft: const Color(0xFFF0D8C5),
          softDark: const Color(0xFF3D2D22),
        );
}

class _MatchaAccent extends _Accent {
  const _MatchaAccent()
      : super(
          light: const Color(0xFF6B8E5A),
          dark: const Color(0xFF9CB987),
          soft: const Color(0xFFDEE8D2),
          softDark: const Color(0xFF2C3624),
        );
}

class _CobaltAccent extends _Accent {
  const _CobaltAccent()
      : super(
          light: const Color(0xFF3D5BB8),
          dark: const Color(0xFF7A93D8),
          soft: const Color(0xFFD6DEF1),
          softDark: const Color(0xFF1F2A4A),
        );
}

class _RoseAccent extends _Accent {
  const _RoseAccent()
      : super(
          light: const Color(0xFFB85878),
          dark: const Color(0xFFD88FA5),
          soft: const Color(0xFFF1D8E0),
          softDark: const Color(0xFF3D1F28),
        );
}

class _InkAccent extends _Accent {
  const _InkAccent()
      : super(
          light: const Color(0xFF2A2620),
          dark: const Color(0xFFE8E2D6),
          soft: const Color(0xFFD8D4CC),
          softDark: const Color(0xFF33302A),
        );
}
