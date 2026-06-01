import 'dart:ui' show PlatformDispatcher, lerpDouble;

import 'package:flutter/material.dart';

/// Theme tokens для SDK widgets (TASK22 Chunk 2).
///
/// `NsgMessengerTheme` — opt-in override: host-app передаёт через
/// `NsgMessenger.init(theme: ...)` или wrap-ает свой `Navigator`/route
/// в `MessengerThemeScope`. Без override SDK widgets читают через
/// стандартный `Theme.of(context)` (host's `MaterialApp.theme`) +
/// fallback-константы для domain-specific tokens (bubble radius,
/// chat-tile padding).
///
/// **Что в scope MVP** (Chunk 2):
///   * `colorScheme: ColorScheme?` — переопределяет host's color scheme
///     для SDK widgets (primary/surface/error используются в bubbles +
///     error states + AppBar).
///   * `textTheme: TextTheme?` — переопределяет typography (titleMedium
///     в room tiles, bodyMedium в bubbles, bodySmall для timestamps).
///   * `bubbleTokens: NsgMessageBubbleTokens?` — domain-specific tokens
///     для chat bubble (radius, padding, max width).
///   * `roomTileTokens: NsgRoomTileTokens?` — domain tokens для list
///     tiles (avatar size, padding).
///
/// **Что НЕ в scope MVP** (defer):
///   * Per-product theming (Chatista vs Futbolista разные брандbooks)
///     — TASK28 admin tooling territory; нужен multi-runtime context.
///   * Spacing / iconography token extensions — TASK41 design tokens.
///   * `fromTokens(Map)` JSON loader — после TASK41 design handoff,
///     когда схема tokens.json зафиксируется.
///
/// **Compatibility note:** legacy fields (`primaryColor`, `bubbleSelfColor`,
/// `defaultAvatar`, `emptyChatsBuilder`, etc) из TASK11 stub удалены —
/// они никогда не использовались widget-ами.
///
/// **Example** (host-app integration):
/// ```dart
/// await NsgMessenger.init(
///   apiBaseUrl: '...',
///   authTokenProvider: ...,
///   theme: NsgMessengerTheme(
///     // Override host's brand color для SDK widgets:
///     colorScheme: ColorScheme.fromSeed(
///       seedColor: Color(0xFFFF6F00),  // Chatista orange
///       brightness: Brightness.dark,
///     ),
///     // Override domain tokens:
///     bubbleTokens: NsgMessageBubbleTokens.fallback.copyWith(
///       maxWidthFraction: 0.85,    // Шире bubble на tablets
///       statusIconSize: 16,
///     ),
///   ),
/// );
/// ```
///
/// Без override (`theme: NsgMessengerTheme.empty` или просто не
/// передавать) — SDK widgets читают `Theme.of(context)` из host's
/// `MaterialApp.theme` напрямую.
@immutable
class NsgMessengerTheme {
  const NsgMessengerTheme({
    this.colorScheme,
    this.textTheme,
    this.bubbleTokens,
    this.roomTileTokens,
  });

  final ColorScheme? colorScheme;
  final TextTheme? textTheme;
  final NsgMessageBubbleTokens? bubbleTokens;
  final NsgRoomTileTokens? roomTileTokens;

  /// Пустая тема — SDK везде falls back на host's `Theme.of(context)`
  /// + fallback-константы.
  static const NsgMessengerTheme empty = NsgMessengerTheme();

  bool get isEmpty =>
      colorScheme == null &&
      textTheme == null &&
      bubbleTokens == null &&
      roomTileTokens == null;

  /// Применяет theme поверх existing (parent's) `ThemeData`. Возвращает
  /// composite ThemeData с:
  ///   * `colorScheme` override (если задан);
  ///   * `textTheme` merged (override → parent fields где не задано);
  ///   * `extensions` extended with bubble + room-tile tokens.
  ///
  /// Используется в [MessengerThemeScope] для overlay поверх host's
  /// `MaterialApp.theme`.
  ThemeData applyTo(ThemeData parent) {
    // Cast нужен — `parent.extensions.values` имеет self-typed
    // `Iterable<ThemeExtension<ThemeExtension<dynamic>>>` (Flutter
    // ThemeExtension's recursive type parameter); collection literal
    // type не помогает, dart compiler во-таки требует cast при
    // spread-е этих values. Verified во время review TASK22 Chunk2:
    // attempt без cast → compile error в test ядре. Минорный
    // overhead — cast<> на iterable lazy.
    final extensions = [
      ...parent.extensions.values,
      ?bubbleTokens,
      ?roomTileTokens,
    ].cast<ThemeExtension<dynamic>>();
    return parent.copyWith(
      colorScheme: colorScheme ?? parent.colorScheme,
      textTheme: textTheme == null
          ? parent.textTheme
          : parent.textTheme.merge(textTheme),
      extensions: extensions,
    );
  }
}

/// Domain-specific tokens для chat-bubble UI (TASK22 Chunk 2).
/// Хранятся в `ThemeData.extensions` — widget-ы читают через
/// `Theme.of(context).extension<NsgMessageBubbleTokens>()` с safe
/// fallback на [NsgMessageBubbleTokens.fallback].
@immutable
class NsgMessageBubbleTokens extends ThemeExtension<NsgMessageBubbleTokens> {
  const NsgMessageBubbleTokens({
    required this.radiusOwn,
    required this.radiusPeer,
    required this.padding,
    required this.maxWidthFraction,
    required this.statusIconSize,
    required this.interBubbleSpacing,
    required this.composerPadding,
  });

  /// Border-radius для own (sender) bubble. Стандартно
  /// `top: 16, bottomRight: 4, bottomLeft: 16, topRight: 16` —
  /// «хвостик» внизу-справа.
  final BorderRadius radiusOwn;

  /// Border-radius для peer (recipient) bubble. Зеркально own:
  /// `top: 16, bottomLeft: 4, bottomRight: 16` — хвостик внизу-слева.
  final BorderRadius radiusPeer;

  /// Inner padding содержимого bubble (text + status icon).
  final EdgeInsets padding;

  /// Доля экрана для max-width bubble (0.0..1.0). На phone-portrait
  /// 0.78 даёт ~78% ширины — стандарт мессенджеров.
  final double maxWidthFraction;

  /// Размер status icon (pending spinner / sent checkmark / failed
  /// error icon) в pixel-ах.
  final double statusIconSize;

  /// **TASK22 Phase2 Chunk 1**: вертикальный gap между последовательными
  /// bubble-ами. Применяется через `MessageBubble`'s outer Padding
  /// (top/bottom = interBubbleSpacing / 2) — итоговый visual gap между
  /// соседними равен полной величине.
  final double interBubbleSpacing;

  /// **TASK22 Phase2 Chunk 1**: outer-padding для `MessageComposer`.
  /// Применяется к Row-у с attach/textfield/send.
  final EdgeInsets composerPadding;

  /// Default tokens — используются widget-ами когда host-app не задал
  /// override. Совпадают с hardcoded values из TASK15 Chunk 2.
  static const NsgMessageBubbleTokens fallback = NsgMessageBubbleTokens(
    radiusOwn: BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    ),
    radiusPeer: BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    ),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    maxWidthFraction: 0.78,
    statusIconSize: 14,
    interBubbleSpacing: 8.0,
    composerPadding: EdgeInsets.fromLTRB(8, 4, 8, 8),
  );

  @override
  NsgMessageBubbleTokens copyWith({
    BorderRadius? radiusOwn,
    BorderRadius? radiusPeer,
    EdgeInsets? padding,
    double? maxWidthFraction,
    double? statusIconSize,
    double? interBubbleSpacing,
    EdgeInsets? composerPadding,
  }) => NsgMessageBubbleTokens(
    radiusOwn: radiusOwn ?? this.radiusOwn,
    radiusPeer: radiusPeer ?? this.radiusPeer,
    padding: padding ?? this.padding,
    maxWidthFraction: maxWidthFraction ?? this.maxWidthFraction,
    statusIconSize: statusIconSize ?? this.statusIconSize,
    interBubbleSpacing: interBubbleSpacing ?? this.interBubbleSpacing,
    composerPadding: composerPadding ?? this.composerPadding,
  );

  @override
  NsgMessageBubbleTokens lerp(
    ThemeExtension<NsgMessageBubbleTokens>? other,
    double t,
  ) {
    if (other is! NsgMessageBubbleTokens) return this;
    return NsgMessageBubbleTokens(
      radiusOwn: BorderRadius.lerp(radiusOwn, other.radiusOwn, t) ?? radiusOwn,
      radiusPeer:
          BorderRadius.lerp(radiusPeer, other.radiusPeer, t) ?? radiusPeer,
      padding: EdgeInsets.lerp(padding, other.padding, t) ?? padding,
      maxWidthFraction:
          ((1 - t) * maxWidthFraction + t * other.maxWidthFraction),
      statusIconSize: ((1 - t) * statusIconSize + t * other.statusIconSize),
      interBubbleSpacing:
          lerpDouble(interBubbleSpacing, other.interBubbleSpacing, t) ??
          interBubbleSpacing,
      composerPadding:
          EdgeInsets.lerp(composerPadding, other.composerPadding, t) ??
          composerPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NsgMessageBubbleTokens &&
        other.radiusOwn == radiusOwn &&
        other.radiusPeer == radiusPeer &&
        other.padding == padding &&
        other.maxWidthFraction == maxWidthFraction &&
        other.statusIconSize == statusIconSize &&
        other.interBubbleSpacing == interBubbleSpacing &&
        other.composerPadding == composerPadding;
  }

  @override
  int get hashCode => Object.hash(
    radiusOwn,
    radiusPeer,
    padding,
    maxWidthFraction,
    statusIconSize,
    interBubbleSpacing,
    composerPadding,
  );
}

/// Domain-specific tokens для room list tile (TASK22 Chunk 2).
@immutable
class NsgRoomTileTokens extends ThemeExtension<NsgRoomTileTokens> {
  const NsgRoomTileTokens({
    required this.avatarSize,
    required this.unreadBadgeSize,
    required this.contentPadding,
    required this.titleSubtitleSpacing,
  });

  /// Diameter аватара в `RoomSummaryTile`.
  final double avatarSize;

  /// Diameter unread-badge (round shape с counter inside).
  final double unreadBadgeSize;

  /// **TASK22 Phase2 Chunk 1**: padding для root-уровня tile (применяется
  /// к `ListTile.contentPadding`).
  final EdgeInsets contentPadding;

  /// **TASK22 Phase2 Chunk 1**: вертикальный gap между title и subtitle
  /// (использует `SizedBox(height: ...)` либо subtitle padding-top).
  final double titleSubtitleSpacing;

  static const NsgRoomTileTokens fallback = NsgRoomTileTokens(
    avatarSize: 44,
    unreadBadgeSize: 20,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    titleSubtitleSpacing: 4.0,
  );

  @override
  NsgRoomTileTokens copyWith({
    double? avatarSize,
    double? unreadBadgeSize,
    EdgeInsets? contentPadding,
    double? titleSubtitleSpacing,
  }) => NsgRoomTileTokens(
    avatarSize: avatarSize ?? this.avatarSize,
    unreadBadgeSize: unreadBadgeSize ?? this.unreadBadgeSize,
    contentPadding: contentPadding ?? this.contentPadding,
    titleSubtitleSpacing: titleSubtitleSpacing ?? this.titleSubtitleSpacing,
  );

  @override
  NsgRoomTileTokens lerp(ThemeExtension<NsgRoomTileTokens>? other, double t) {
    if (other is! NsgRoomTileTokens) return this;
    return NsgRoomTileTokens(
      avatarSize: ((1 - t) * avatarSize + t * other.avatarSize),
      unreadBadgeSize: ((1 - t) * unreadBadgeSize + t * other.unreadBadgeSize),
      contentPadding:
          EdgeInsets.lerp(contentPadding, other.contentPadding, t) ??
          contentPadding,
      titleSubtitleSpacing:
          lerpDouble(titleSubtitleSpacing, other.titleSubtitleSpacing, t) ??
          titleSubtitleSpacing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NsgRoomTileTokens &&
        other.avatarSize == avatarSize &&
        other.unreadBadgeSize == unreadBadgeSize &&
        other.contentPadding == contentPadding &&
        other.titleSubtitleSpacing == titleSubtitleSpacing;
  }

  @override
  int get hashCode =>
      Object.hash(avatarSize, unreadBadgeSize, contentPadding, titleSubtitleSpacing);
}

/// Locale-config для SDK (TASK22 Chunk 1 — фактически unused теперь
/// после ARB-migration, потому что host-app передаёт `NsgL10n.delegate`
/// в `MaterialApp.localizationsDelegates`). Оставлен для backwards-
/// compat `NsgMessenger.init(locale: NsgMessengerLocale...)` API.
class NsgMessengerLocale {
  const NsgMessengerLocale({this.locale = const Locale('ru')});

  final Locale locale;

  static const List<Locale> supported = [Locale('ru'), Locale('en')];

  /// Resolves the user's preferred locale from the system. Returns:
  ///   * The first system locale that matches a [supported] locale by
  ///     `languageCode` (e.g., system `en-US` → returns
  ///     `NsgMessengerLocale(locale: Locale('en'))`).
  ///   * Fallback to `Locale('ru')` (SDK's primary locale) if no
  ///     system locale matches.
  ///
  /// On Flutter: reads from `PlatformDispatcher.instance.locales` —
  /// the full preferred-locale list (typically [primary, secondary, ...]).
  /// Earlier entries have higher preference; first match wins.
  ///
  /// [platformLocales] — optional override for testing. When omitted,
  /// reads from `PlatformDispatcher.instance.locales`.
  ///
  /// **TASK22 followup (f)**: previously returned `Locale('ru')` always
  /// (stub). Now reads platform locale.
  static NsgMessengerLocale resolveFromSystem([
    List<Locale>? platformLocales,
  ]) {
    final locales = platformLocales ?? PlatformDispatcher.instance.locales;
    for (final systemLocale in locales) {
      for (final s in supported) {
        if (systemLocale.languageCode == s.languageCode) {
          return NsgMessengerLocale(locale: s);
        }
      }
    }
    return const NsgMessengerLocale(locale: Locale('ru'));
  }
}
