import 'package:flutter/material.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../runtime/messenger_connection_state.dart';

/// **TASK20 followup (a)**: small traffic-light indicator showing
/// WebSocket-transport health. Host-app embeds в `AppBar.actions:` (или
/// где угодно) — unobtrusive когда `healthy`, заметный когда сеть
/// нестабильна (VPN, weak signal, server restart).
///
/// Renders a circle (default 10 px diameter):
///   * green — [MessengerConnectionState.healthy].
///   * amber — [MessengerConnectionState.reconnecting].
///   * red — [MessengerConnectionState.disconnected].
///
/// Localised tooltip via [NsgL10n] (RU/EN). `onTap` — optional callback
/// (host-app может wire-ить к manual retry / diagnostics screen).
///
/// **Test-friendly**: `stateOverride` принимает custom stream — widget-
/// тесты могут не поднимать [MessengerRuntime].
class ConnectionStateIndicator extends StatelessWidget {
  const ConnectionStateIndicator({
    super.key,
    this.size = 10,
    this.onTap,
    this.healthyColor,
    this.reconnectingColor,
    this.disconnectedColor,
    @visibleForTesting this.stateOverride,
    @visibleForTesting this.initialStateOverride,
  });

  /// Диаметр круга в logical pixels. Default 10 — типичный AppBar-trailing
  /// dot.
  final double size;

  /// Callback на tap. Если null — widget не интерактивный (без
  /// InkResponse-а).
  final VoidCallback? onTap;

  /// Override default green (Material `Colors.green`).
  final Color? healthyColor;

  /// Override default amber (`Colors.amber`).
  final Color? reconnectingColor;

  /// Override default red (`Colors.red`).
  final Color? disconnectedColor;

  /// Visible-for-testing: подсунуть свой state-stream вместо
  /// [MessengerRuntime.instance.connectionStateStream]. Используется
  /// в widget-тестах.
  final Stream<MessengerConnectionState>? stateOverride;

  /// Visible-for-testing: initial-data для StreamBuilder-а до первого
  /// emit-а. Без override-а берётся из runtime singleton-а (или
  /// `healthy` если runtime не initialised — см. геттер
  /// [MessengerRuntime.connectionState]).
  final MessengerConnectionState? initialStateOverride;

  @override
  Widget build(BuildContext context) {
    final stream =
        stateOverride ?? MessengerRuntime.instance.connectionStateStream;
    final initial =
        initialStateOverride ??
        (stateOverride != null
            ? MessengerConnectionState.healthy
            : MessengerRuntime.instance.connectionState);

    return StreamBuilder<MessengerConnectionState>(
      stream: stream,
      initialData: initial,
      builder: (context, snap) {
        final state = snap.data ?? MessengerConnectionState.healthy;
        // i18n: fallback на hardcoded EN строки если NsgL10n не
        // installed в host-app-е (например widget-тест без MaterialApp.
        // localizationsDelegates) — лучше показать «Connected» по-
        // английски, чем упасть. `Localizations.of` напрямую (вместо
        // `NsgL10n.of`) потому что сгенерированный helper не nullable.
        final l10n = Localizations.of<NsgL10n>(context, NsgL10n);
        final color = switch (state) {
          MessengerConnectionState.healthy => healthyColor ?? Colors.green,
          MessengerConnectionState.reconnecting =>
            reconnectingColor ?? Colors.amber,
          MessengerConnectionState.disconnected =>
            disconnectedColor ?? Colors.red,
        };
        final tooltip = switch (state) {
          MessengerConnectionState.healthy =>
            l10n?.connectionStateHealthy ?? 'Connected',
          MessengerConnectionState.reconnecting =>
            l10n?.connectionStateReconnecting ?? 'Reconnecting…',
          MessengerConnectionState.disconnected =>
            l10n?.connectionStateDisconnected ?? 'Connection lost',
        };
        Widget circle = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
        if (onTap != null) {
          circle = InkResponse(onTap: onTap, radius: size * 1.5, child: circle);
        }
        return Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: circle,
          ),
        );
      },
    );
  }
}
