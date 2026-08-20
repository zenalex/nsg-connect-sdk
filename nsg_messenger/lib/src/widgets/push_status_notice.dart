import 'package:flutter/material.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../push/push_token_status.dart';

/// **Issue #86**: два способа показать человеку, что уведомления до него
/// не доедут — и почему.
///
/// До этого отказ был невидим: провайдер писал `debugPrint` под
/// `kDebugMode` и замолкал, сервер рапортовал `sent` в мёртвую
/// регистрацию, человек две недели гадал. Оба виджета читают
/// `MessengerRuntime.pushStatus` — состояние, а не лог.
///
/// Разделение по назойливости намеренное:
///   * [PushStatusNotice] — в настройках уведомлений. Туда приходят
///     специально, поэтому говорит про ЛЮБУЮ поломку, включая
///     невыданное разрешение, и не прячется.
///   * [PushStatusBanner] — над списком чатов. Показывается ТОЛЬКО
///     когда разрешение выдано, а токен не пришёл: этого человек не
///     выбирал, он ждёт уведомлений и не получает. Отказавшемуся от
///     уведомлений баннер не показывается вовсе — его выбор уважаем,
///     а факт остаётся видимым в настройках.

/// Текст причины для текущего состояния. `null` — сообщать не о чем
/// (`pending` / `ready` / `unsupported`).
String? _reasonText(NsgL10n? l10n, PushTokenStatus status) {
  switch (status) {
    case PushTokenStatus.permissionDenied:
      return l10n?.pushStatusPermissionDenied ??
          'This app is not allowed to show notifications.';
    case PushTokenStatus.tokenUnavailable:
      return l10n?.pushStatusTokenUnavailable ??
          'Permission is granted, but the device did not register with '
              'the delivery service.';
    case PushTokenStatus.pending:
    case PushTokenStatus.ready:
    case PushTokenStatus.unsupported:
      return null;
  }
}

/// Подписка на статус пушей с подменой для тестов — общая для обоих
/// виджетов ниже.
class _PushStatusScope extends StatelessWidget {
  const _PushStatusScope({
    required this.builder,
    this.statusOverride,
    this.initialStatusOverride,
  });

  final Widget Function(BuildContext context, PushTokenStatus status) builder;
  final Stream<PushTokenStatus>? statusOverride;
  final PushTokenStatus? initialStatusOverride;

  @override
  Widget build(BuildContext context) {
    final stream = statusOverride ?? MessengerRuntime.instance.pushStatusStream;
    final initial =
        initialStatusOverride ??
        (statusOverride != null
            ? PushTokenStatus.pending
            : MessengerRuntime.instance.pushStatus);
    return StreamBuilder<PushTokenStatus>(
      stream: stream,
      initialData: initial,
      builder: (context, snap) =>
          builder(context, snap.data ?? PushTokenStatus.pending),
    );
  }
}

/// **Issue #86**: карточка «уведомления не подключены» с причиной и
/// переходом в системные настройки. Встроена наверх экрана настроек
/// уведомлений — единственного места, куда человек идёт с вопросом
/// «почему мне ничего не приходит». Всё в порядке (`ready`) — карточки
/// нет: подтверждать исправность нечем и незачем.
class PushStatusNotice extends StatelessWidget {
  const PushStatusNotice({
    super.key,
    this.onOpenSettings,
    this.statusOverride,
    this.initialStatusOverride,
  });

  /// Открыть системные настройки приложения. Живёт в host-app: SDK не
  /// тащит ради одной кнопки нативный плагин (`permission_handler` есть
  /// у хоста). `null` — кнопки нет, текст с причиной остаётся.
  final VoidCallback? onOpenSettings;

  /// Подменить поток статуса вместо рантайма. Не помечено
  /// `@visibleForTesting`, хотя нужно ровно для тестов: сквозь него
  /// пробрасывает свой тестовый шов `NotificationSettingsScreen`, а
  /// анализатор считает такой проброс нарушением аннотации.
  final Stream<PushTokenStatus>? statusOverride;

  /// Значение до первого emit-а (см. [statusOverride]).
  final PushTokenStatus? initialStatusOverride;

  @override
  Widget build(BuildContext context) {
    return _PushStatusScope(
      statusOverride: statusOverride,
      initialStatusOverride: initialStatusOverride,
      builder: (context, status) {
        final l10n = Localizations.of<NsgL10n>(context, NsgL10n);
        final reason = _reasonText(l10n, status);
        if (reason == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Card(
          key: const Key('pushStatusNotice'),
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          color: scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: scheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n?.pushStatusNotConnectedTitle ??
                            'Notifications are not connected',
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
                if (onOpenSettings != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      key: const Key('pushStatusOpenSettings'),
                      onPressed: onOpenSettings,
                      child: Text(
                        l10n?.pushStatusOpenSystemSettings ?? 'Open settings',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// **Issue #86**: слим-баннер над списком чатов — в той же полосе, где
/// живёт `MessengerConnectionBanner`, чтобы приложение сообщало о
/// поломке доставки там же, где о пропаже сети.
///
/// Показывается ТОЛЬКО при [PushTokenStatus.tokenUnavailable] — молчащая
/// поломка, которую человек не выбирал (разрешение он выдал, значит
/// уведомлений ждёт). Невыданное разрешение баннером не преследуем: это
/// осознанный отказ, о нём написано в настройках уведомлений.
///
/// Скрывается крестиком — на весь сеанс приложения (флаг статический,
/// переживает пересоздание виджета при уходе с экрана и обратно).
class PushStatusBanner extends StatefulWidget {
  const PushStatusBanner({
    super.key,
    this.onOpenSettings,
    @visibleForTesting this.statusOverride,
    @visibleForTesting this.initialStatusOverride,
  });

  /// Тап по баннеру открывает системные настройки (см.
  /// [PushStatusNotice.onOpenSettings]). `null` — баннер только сообщает.
  final VoidCallback? onOpenSettings;

  /// Visible-for-testing: подменить поток статуса вместо рантайма.
  final Stream<PushTokenStatus>? statusOverride;

  /// Visible-for-testing: значение до первого emit-а.
  final PushTokenStatus? initialStatusOverride;

  /// Скрыт ли баннер на этот сеанс. Статика, а не state виджета: иначе
  /// «скрыл» отменялось бы при первом же уходе со списка чатов и обратно.
  static bool _dismissedForSession = false;

  /// Visible-for-testing: вернуть баннер (сбросить крестик).
  @visibleForTesting
  static void resetDismissal() => _dismissedForSession = false;

  @override
  State<PushStatusBanner> createState() => _PushStatusBannerState();
}

class _PushStatusBannerState extends State<PushStatusBanner> {
  @override
  Widget build(BuildContext context) {
    if (PushStatusBanner._dismissedForSession) return const SizedBox.shrink();
    return _PushStatusScope(
      statusOverride: widget.statusOverride,
      initialStatusOverride: widget.initialStatusOverride,
      builder: (context, status) {
        if (status != PushTokenStatus.tokenUnavailable) {
          return const SizedBox.shrink();
        }
        final l10n = Localizations.of<NsgL10n>(context, NsgL10n);
        final scheme = Theme.of(context).colorScheme;
        final fg = scheme.onErrorContainer;
        return Material(
          color: scheme.errorContainer,
          child: InkWell(
            onTap: widget.onOpenSettings,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                key: const Key('pushStatusBanner'),
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 16, color: fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.pushStatusBannerText ??
                            'Notifications are not connected',
                        style: TextStyle(color: fg, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      key: const Key('pushStatusBannerDismiss'),
                      icon: Icon(Icons.close, size: 16, color: fg),
                      tooltip: l10n?.pushStatusBannerDismiss ?? 'Hide',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        PushStatusBanner._dismissedForSession = true;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
