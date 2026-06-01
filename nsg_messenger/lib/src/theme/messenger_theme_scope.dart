import 'package:flutter/material.dart';

import 'nsg_messenger_theme.dart';

/// Wrap-widget для injection [NsgMessengerTheme] в SDK widgets
/// (TASK22 Chunk 2).
///
/// **Где host-app использует:**
///   * Автоматически — внутри SDK widget-factory методов (`NsgMessenger
///     .chatsListView()`, `openRoom()`, etc): если `NsgMessenger.init(
///     theme: ...)` передал не-empty theme, factory оборачивает root
///     widget в `MessengerThemeScope` автоматически.
///   * Вручную — host-app может сам wrap-нуть конкретное subtree:
///     `MessengerThemeScope(theme: brand, child: ChatScreen(...))`.
///     Полезно когда SDK widgets рендерятся внутри custom navigation
///     с разными темами (per-tab branding, etc).
///
/// **Поведение:**
///   * Читает parent's `Theme.of(context)` (host's `MaterialApp.theme`).
///   * Применяет [theme]'s overrides через `theme.applyTo(parent)` —
///     ColorScheme override, TextTheme merge, ThemeExtension extend.
///   * `Theme(data: composite, child: child)` — overlay для всех
///     descendants. SDK widgets читают `Theme.of(context)` стандартно,
///     получают composite.
///
/// **Empty theme** (`theme.isEmpty == true`) — scope returns child
/// без overlay (zero-overhead path). Используется default factory когда
/// host не задавал override.
class MessengerThemeScope extends StatelessWidget {
  const MessengerThemeScope({
    super.key,
    required this.theme,
    required this.child,
  });

  final NsgMessengerTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (theme.isEmpty) return child;
    final parent = Theme.of(context);
    return Theme(data: theme.applyTo(parent), child: child);
  }
}
