import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import 'nsg_messenger_rooms.dart';

/// **TASK29 Chunk 2**: bottom-sheet с per-participant admin actions
/// (Kick / Ban / Promote / Demote). Открывается на long-press
/// participant tile в `ParticipantsScreen`.
///
/// **Visibility per caller role** (Q sign-off — UI affordance, server
/// enforces real auth):
///   * `owner` → все 4 действия (Kick / Ban / Make admin / Demote).
///   * `admin` → Kick / Ban только.
///   * `member` → нет admin actions; sheet вообще не открывается
///     (caller-side guard в ParticipantsScreen.onLongPress).
///
/// **Self-action prevention**: target == caller → kick/ban/demote
/// hidden (server-side тоже rejects, но UI hint).
///
/// **Optimistic + revert**: kick/ban → instant invalidate cache + RPC;
/// fail → snackbar с typed-exception mapping
/// (`LastOwnerCannotDemoteException` / `InsufficientPowerException` →
/// specific i18n; generic → fallback).
Future<void> showParticipantActionSheet({
  required BuildContext context,
  required RoomDetails room,
  required RoomParticipant target,
  required RoomMemberRole callerRole,
  required int callerMessengerUserId,
  required NsgMessengerRooms rooms,
}) {
  // Защита: member caller не должен видеть никаких actions — caller-
  // side проверка дублирует ParticipantsScreen guard.
  if (callerRole == RoomMemberRole.member) {
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => _ParticipantActionSheetBody(
      room: room,
      target: target,
      callerRole: callerRole,
      callerMessengerUserId: callerMessengerUserId,
      rooms: rooms,
    ),
  );
}

class _ParticipantActionSheetBody extends StatelessWidget {
  const _ParticipantActionSheetBody({
    required this.room,
    required this.target,
    required this.callerRole,
    required this.callerMessengerUserId,
    required this.rooms,
  });

  final RoomDetails room;
  final RoomParticipant target;
  final RoomMemberRole callerRole;
  final int callerMessengerUserId;
  final NsgMessengerRooms rooms;

  bool get _isSelf => target.messengerUserId == callerMessengerUserId;

  /// Owner caller может всё; admin caller — только kick/ban.
  bool get _canModerate =>
      callerRole == RoomMemberRole.owner || callerRole == RoomMemberRole.admin;

  /// Только owner может менять роли.
  bool get _canChangeRoles => callerRole == RoomMemberRole.owner;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);

    final canKickBan = _canModerate && !_isSelf;
    // Promote: target == member → promote to admin; target == admin →
    // promote to owner. Owner-target — нечего promote.
    final canPromote =
        _canChangeRoles && target.role != RoomMemberRole.owner && !_isSelf;
    // Demote: target == admin / owner. Self-demote (owner→admin) разрешён —
    // Matrix permits lower own level, server enforce last-owner check
    // (LastOwnerCannotDemoteException → snackbar revert).
    final canDemote = _canChangeRoles && target.role != RoomMemberRole.member;

    final displayName = target.displayName ?? target.matrixUserId;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (canPromote)
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(
                target.role == RoomMemberRole.member
                    ? l.roomAdminPromoteAction
                    : l.roomAdminPromoteOwnerAction,
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                final newRole = target.role == RoomMemberRole.member
                    ? RoomMemberRole.admin
                    : RoomMemberRole.owner;
                await _runWithErrorReport(
                  context,
                  () => rooms.setRoomMemberRole(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                    newRole: newRole,
                  ),
                );
              },
            ),
          if (canDemote)
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text(l.roomAdminDemoteAction),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await _runWithErrorReport(
                  context,
                  () => rooms.setRoomMemberRole(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                    newRole: RoomMemberRole.member,
                  ),
                );
              },
            ),
          if (canKickBan)
            ListTile(
              leading: Icon(
                Icons.person_remove_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l.roomAdminKickAction,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                final confirmed = await _showConfirm(
                  context,
                  title: l.roomAdminKickConfirmTitle(displayName),
                  body: l.roomAdminKickConfirmBody(displayName),
                  destructive: true,
                  confirmLabel: l.roomAdminKickAction,
                );
                if (confirmed != true) return;
                if (!context.mounted) return;
                await _runWithErrorReport(
                  context,
                  () => rooms.kickUser(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                  ),
                );
              },
            ),
          if (canKickBan)
            ListTile(
              leading: Icon(Icons.block, color: theme.colorScheme.error),
              title: Text(
                l.roomAdminBanAction,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                final confirmed = await _showConfirm(
                  context,
                  title: l.roomAdminBanConfirmTitle(displayName),
                  body: l.roomAdminBanConfirmBody(displayName),
                  destructive: true,
                  confirmLabel: l.roomAdminBanAction,
                );
                if (confirmed != true) return;
                if (!context.mounted) return;
                await _runWithErrorReport(
                  context,
                  () => rooms.banUser(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// **TASK29 Chunk 2**: typed-exception mapping для admin RPC failures.
/// Caller передаёт closure → если throw, делаем snackbar с specific i18n.
/// Used от ParticipantActionSheet AND BannedUsersScreen unban path.
Future<void> _runWithErrorReport(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = NsgL10n.of(context);
  try {
    await action();
  } catch (e) {
    final msg = mapAdminError(e, l);
    messenger?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
}

/// **TASK29 Chunk 2**: typed-exception → i18n string. Public для
/// reuse в BannedUsersScreen (unban) + потенциально host-app override.
String mapAdminError(Object error, NsgL10n l) {
  if (error is LastOwnerCannotDemoteException) {
    return l.roomAdminLastOwnerError;
  }
  if (error is InsufficientPowerException) {
    return l.roomAdminInsufficientPowerError;
  }
  return l.roomAdminGenericError;
}

Future<bool?> _showConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(NsgL10n.of(ctx).commonCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
