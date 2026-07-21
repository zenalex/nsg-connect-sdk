import 'package:flutter/material.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../runtime/messenger_connection_state.dart';

/// **TASK47**: слим-баннер «нет сети» на базе
/// [MessengerRuntime.connectionStateStream]. Более заметная альтернатива
/// точке [ConnectionStateIndicator] — host-app кладёт его В КОЛОНКУ НАД
/// контентом (chats-list / chat), чтобы пользователь видел, что приложение
/// оффлайн (а не «сломалось»).
///
/// Поведение:
///   * `healthy` → `SizedBox.shrink()` (баннера нет);
///   * `reconnecting` → янтарный «Переподключение…»;
///   * `disconnected` → красный «Нет подключения к сети».
///
/// Переиспользует l10n-строки индикатора (`connectionStateReconnecting`
/// / `connectionStateDisconnected`); при отсутствии `NsgL10n` в host-app-е
/// падает на EN-строки (как [ConnectionStateIndicator]).
class MessengerConnectionBanner extends StatelessWidget {
  const MessengerConnectionBanner({
    super.key,
    @visibleForTesting this.stateOverride,
    @visibleForTesting this.initialStateOverride,
  });

  /// Visible-for-testing: подсунуть свой state-stream вместо runtime.
  final Stream<MessengerConnectionState>? stateOverride;

  /// Visible-for-testing: initial-data до первого emit-а.
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
        if (state == MessengerConnectionState.healthy) {
          return const SizedBox.shrink();
        }
        final l10n = Localizations.of<NsgL10n>(context, NsgL10n);
        final isDown = state == MessengerConnectionState.disconnected;
        final scheme = Theme.of(context).colorScheme;
        final bg = isDown ? scheme.errorContainer : Colors.amber.shade100;
        final fg = isDown ? scheme.onErrorContainer : Colors.black87;
        final text = isDown
            ? (l10n?.connectionStateDisconnected ?? 'No network connection')
            : (l10n?.connectionStateReconnecting ?? 'Reconnecting…');
        return Material(
          color: bg,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              key: const Key('messengerConnectionBanner'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDown ? Icons.cloud_off : Icons.sync,
                    size: 16,
                    color: fg,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(color: fg, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
