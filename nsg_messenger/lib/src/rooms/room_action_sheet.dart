import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import 'chats_list_controller.dart';

/// Описание дополнительного host-app action-а для [showRoomActionSheet].
///
/// Host-app (например chatista) может добавить свои пункты в общий
/// action-sheet (mute/archive/leave) без связывания SDK с app-specific
/// навигацией. Пример: «Добавить пользователя» → открыть экран поиска.
class RoomActionEntry {
  const RoomActionEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Вызывается ПОСЛЕ закрытия sheet-а (sheet pop-нется до `onTap`,
  /// чтобы host мог открыть свой dialog/route на viewport-level).
  final VoidCallback onTap;
}

/// Bottom-sheet с per-room actions (mute / archive / leave).
/// Открывается на long-press `RoomSummaryTile` из `ChatsListScreen`.
///
/// Pattern: stateless function-обёртка вокруг `showModalBottomSheet`,
/// чтобы host-app мог вызывать без знания внутренних widget-ов.
/// Возвращает `Future<void>` который завершается когда sheet закрыт
/// (любое action или dismiss).
///
/// Optimistic update: action-callbacks вызывают
/// `controller.muteRoom/archiveRoom/leaveRoom` — они мгновенно
/// меняют local state, RPC летит асинхронно. Если RPC падает —
/// snackbar через [showRoomActionFailedSnack].
///
/// [extraActions] — опциональные host-app пункты (e.g. «Добавить
/// пользователя» в chatista), рендерятся над leave-action-ом.
Future<void> showRoomActionSheet({
  required BuildContext context,
  required RoomSummary room,
  required ChatsListController controller,
  List<RoomActionEntry> extraActions = const <RoomActionEntry>[],
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => _RoomActionSheetBody(
      room: room,
      controller: controller,
      extraActions: extraActions,
    ),
  );
}

/// Snackbar показывается при revert после optimistic-update fail.
/// Inlined в `RoomActionSheetBody._runWithError` + используется
/// `ChatsListScreen` для unified error reporting (TASK42 Chunk 2).
void showRoomActionFailedSnack(BuildContext context) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(NsgL10n.of(context).roomActionFailedSnack),
      duration: const Duration(seconds: 3),
    ),
  );
}

class _RoomActionSheetBody extends StatelessWidget {
  const _RoomActionSheetBody({
    required this.room,
    required this.controller,
    this.extraActions = const <RoomActionEntry>[],
  });

  final RoomSummary room;
  final ChatsListController controller;
  final List<RoomActionEntry> extraActions;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              l.roomActionSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (room.muted)
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(l.roomActionUnmute),
              onTap: () =>
                  _runOptimistic(context, () => controller.unmuteRoom(room.id)),
            )
          else
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: Text(l.roomActionMute),
              onTap: () async {
                final navigator = Navigator.of(context);
                // #17/#28: закрываем main sheet, затем duration-sheet показываем
                // на navigator.context — это живой root-контекст, переживающий
                // pop. Так RPC доходит (фикс #17: раньше pop шёл до показа и
                // showModalBottomSheet падал на мёртвом контексте), и нет «панели
                // поверх панели» (фикс регрессии #28: main sheet уже закрыт).
                navigator.pop();
                await _showMuteDurationSheet(navigator.context, room, controller);
              },
            ),
          if (room.archived)
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: Text(l.roomActionUnarchive),
              onTap: () => _runOptimistic(
                context,
                () => controller.unarchiveRoom(room.id),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l.roomActionArchive),
              onTap: () => _runOptimistic(
                context,
                () => controller.archiveRoom(room.id),
              ),
            ),
          for (final entry in extraActions)
            ListTile(
              leading: Icon(entry.icon),
              title: Text(entry.label),
              onTap: () {
                Navigator.of(context).pop(); // закрываем sheet перед
                // host-app навигацией (route/dialog на viewport-level).
                entry.onTap();
              },
            ),
          ListTile(
            leading: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l.roomActionLeave,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              // #17: confirm на ЖИВОМ контексте ДО pop. Раньше pop() шёл первым
              // → showDialog на мёртвом контексте → confirmed=false → leaveRoom
              // не вызывался (тот же дефект, что был у kick/ban). pop — после
              // подтверждения.
              final confirmed = await _showLeaveConfirmDialog(context);
              if (!confirmed) return;
              if (!context.mounted) return;
              navigator.pop();
              await _runOptimisticDirect(
                context,
                () => controller.leaveRoom(room.id),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Закрывает sheet + запускает RPC. Если RPC падает — snackbar.
  /// Используется для actions, которые НЕ открывают secondary UI.
  Future<void> _runOptimistic(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await _runOptimisticDirect(context, action);
  }

  /// Без закрытия sheet (assume already closed). Чисто RPC + error
  /// snackbar. `ScaffoldMessenger` выловлен ДО async gap (sheet
  /// сейчас pop-нется, но root-scaffold messenger жив весь lifetime
  /// `ChatsListScreen`).
  static Future<void> _runOptimisticDirect(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    try {
      await action();
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.roomActionFailedSnack),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Secondary sheet — выбор длительности mute. Открывается из главного
/// action-sheet после tap «Mute». Опции — фиксированные durations
/// (1h/8h/1d/1w/forever), все mapятся в `mutedUntil` либо
/// `kMuteForever`.
Future<void> _showMuteDurationSheet(
  BuildContext context,
  RoomSummary room,
  ChatsListController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l = NsgL10n.of(ctx);
      Future<void> mute(Duration? duration) async {
        Navigator.of(ctx).pop();
        await _RoomActionSheetBody._runOptimisticDirect(
          context,
          () => controller.muteRoom(room.id, duration: duration),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l.roomActionMuteUntilTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: Text(l.roomActionMuteFor1Hour),
              onTap: () => mute(const Duration(hours: 1)),
            ),
            ListTile(
              title: Text(l.roomActionMuteFor8Hours),
              onTap: () => mute(const Duration(hours: 8)),
            ),
            ListTile(
              title: Text(l.roomActionMuteFor1Day),
              onTap: () => mute(const Duration(days: 1)),
            ),
            ListTile(
              title: Text(l.roomActionMuteFor1Week),
              onTap: () => mute(const Duration(days: 7)),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: Text(l.roomActionMuteForever),
              onTap: () => mute(null), // null = kMuteForever sentinel.
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> _showLeaveConfirmDialog(BuildContext context) async {
  final l = NsgL10n.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.roomActionLeaveConfirmTitle),
      content: Text(l.roomActionLeaveConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.roomActionLeave),
        ),
      ],
    ),
  );
  return result ?? false;
}
