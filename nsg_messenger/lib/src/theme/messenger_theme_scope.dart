import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
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

  /// Оборачивает [child] в scope с ТЕКУЩЕЙ темой из [MessengerRuntime].
  /// Удобно для внутренних `Navigator.push` SDK: pushed-роут создаётся в
  /// host-Navigator и НЕ наследует scope родителя, поэтому каждый
  /// SDK-экран, открываемый push-ем, надо обернуть заново — иначе он
  /// возьмёт host-локаль (en) вместо SDK-локали.
  static Widget wrap(Widget child) =>
      MessengerThemeScope(theme: MessengerRuntime.instance.theme, child: child);

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    if (!theme.isEmpty) {
      result = Theme(data: theme.applyTo(Theme.of(context)), child: result);
    }
    // Локаль SDK применяется НЕЗАВИСИМО от host-app: `NsgMessenger.init(
    // locale: ru)` должен давать русский интерфейс мессенджера даже когда
    // хост-приложение резолвит системную/браузерную локаль в en (частый
    // случай на web/desktop). Раньше SDK только ХРАНИЛ locale, но экраны
    // читали `NsgL10n.of(context)` из host-Localizations → английский
    // фолбэк. Оборачиваем поддерево SDK в Localizations.override со своей
    // локалью + всеми нужными делегатами (NsgL10n + Global* для Material/
    // Cupertino/Widgets — даты, тултипы, стандартные кнопки).
    final locale = MessengerRuntime.instance.locale.locale;
    result = Localizations.override(
      context: context,
      locale: locale,
      delegates: const [
        NsgL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: result,
    );
    return result;
  }
}
