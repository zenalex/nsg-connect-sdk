import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
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
  VoidCallback? onChanged,
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
      onChanged: onChanged,
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
    this.onChanged,
  });

  final RoomDetails room;
  final RoomParticipant target;
  final RoomMemberRole callerRole;
  final int callerMessengerUserId;
  final NsgMessengerRooms rooms;

  /// **B21 fix**: вызывается ПОСЛЕ успешного mutating-RPC (kick / ban /
  /// promote / demote). Sheet к этому моменту уже `pop()`-нут (snappy
  /// UX сохранён), поэтому callback завязан на State экрана-родителя
  /// (`ParticipantsScreen._refresh`), а не на context sheet-а. Без
  /// него экран держал stale `_detailsFuture` из initState и
  /// kick/ban «не отображались» (intern QA #6/#7).
  final VoidCallback? onChanged;

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
                final ok = await _runWithErrorReport(
                  context,
                  'promote:${newRole.name}',
                  () => rooms.setRoomMemberRole(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                    newRole: newRole,
                  ),
                );
                if (ok) onChanged?.call();
              },
            ),
          if (canDemote)
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text(l.roomAdminDemoteAction),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                final ok = await _runWithErrorReport(
                  context,
                  'demote',
                  () => rooms.setRoomMemberRole(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                    newRole: RoomMemberRole.member,
                  ),
                );
                if (ok) onChanged?.call();
              },
            ),
          // **Write-ban (2026-07-13)**: запретить/разрешить писать —
          // участник остаётся читателем (мягче kick/ban). Guard-ы те же,
          // что kick/ban + owner-target отбивается сервером.
          if (canKickBan && target.role != RoomMemberRole.owner)
            target.writeBannedUntil == null
                ? ListTile(
                    leading: const Icon(Icons.speaker_notes_off_outlined),
                    title: Text(l.roomAdminWriteBanAction),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      // Длительность выбираем на живом контексте до pop.
                      final seconds = await _pickWriteBanDuration(context);
                      if (seconds == _durationCancelled) return;
                      if (!context.mounted) return;
                      navigator.pop();
                      final ok = await _runWithErrorReport(
                        context,
                        'writeBan',
                        () => rooms.setWriteBan(
                          roomId: room.id,
                          targetMessengerUserId: target.messengerUserId,
                          banned: true,
                          untilSeconds: seconds,
                        ),
                      );
                      if (ok) onChanged?.call();
                    },
                  )
                : ListTile(
                    leading: const Icon(Icons.speaker_notes_outlined),
                    title: Text(l.roomAdminWriteUnbanAction),
                    subtitle: Text(
                      target.writeBannedUntil!.year >= 9000
                          ? l.roomAdminWriteBanForever
                          : l.roomAdminWriteBannedUntil(
                              formatWriteBanUntil(
                                target.writeBannedUntil!.toLocal(),
                              ),
                            ),
                    ),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      final ok = await _runWithErrorReport(
                        context,
                        'writeUnban',
                        () => rooms.setWriteBan(
                          roomId: room.id,
                          targetMessengerUserId: target.messengerUserId,
                          banned: false,
                        ),
                      );
                      if (ok) onChanged?.call();
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
                // #6: confirm показываем на ЖИВОМ контексте sheet (ДО pop).
                // Раньше pop() шёл первым → showDialog на pop-нутом контексте
                // не подтверждался → confirmed=null → kickUser НЕ вызывался,
                // участник оставался даже после F5. (promote работал, т.к. у
                // него нет confirm-диалога.) pop — только после подтверждения.
                final confirmed = await _showConfirm(
                  context,
                  title: l.roomAdminKickConfirmTitle(displayName),
                  body: l.roomAdminKickConfirmBody(displayName),
                  destructive: true,
                  confirmLabel: l.roomAdminKickAction,
                );
                if (confirmed != true) return;
                if (!context.mounted) return; // sheet ещё открыт → проходит
                navigator.pop();
                final ok = await _runWithErrorReport(
                  context,
                  'kick',
                  () => rooms.kickUser(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                  ),
                );
                if (ok) onChanged?.call();
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
                // #7: см. kick выше — confirm на ЖИВОМ контексте до pop,
                // иначе banUser не вызывался (RPC за гейтом confirmed=null).
                final confirmed = await _showConfirm(
                  context,
                  title: l.roomAdminBanConfirmTitle(displayName),
                  body: l.roomAdminBanConfirmBody(displayName),
                  destructive: true,
                  confirmLabel: l.roomAdminBanAction,
                );
                if (confirmed != true) return;
                if (!context.mounted) return; // sheet ещё открыт → проходит
                navigator.pop();
                final ok = await _runWithErrorReport(
                  context,
                  'ban',
                  () => rooms.banUser(
                    roomId: room.id,
                    targetMessengerUserId: target.messengerUserId,
                  ),
                );
                if (ok) onChanged?.call();
              },
            ),
        ],
      ),
    );
  }
}

/// «до 13.07.2026 21:40» — компактный локальный формат для write-ban
/// (без intl-скелетонов: RU/EN оба читают dd.MM.yyyy HH:mm однозначно).
String formatWriteBanUntil(DateTime local) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Сентинел «пользователь передумал» для [_pickWriteBanDuration]
/// (null — валидный ответ «навсегда»).
const int _durationCancelled = -1;

/// Выбор длительности write-ban: 1 час / 1 день / 7 дней / навсегда.
/// Возвращает секунды, null = навсегда, [_durationCancelled] = отмена.
Future<int?> _pickWriteBanDuration(BuildContext context) async {
  final l = NsgL10n.of(context);
  final result = await showDialog<Object>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l.roomAdminWriteBanDurationTitle),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop(3600),
          child: Text(l.roomAdminWriteBanHour),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop(86400),
          child: Text(l.roomAdminWriteBanDay),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop(7 * 86400),
          child: Text(l.roomAdminWriteBanWeek),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop('forever'),
          child: Text(l.roomAdminWriteBanForever),
        ),
      ],
    ),
  );
  if (result == null) return _durationCancelled;
  if (result == 'forever') return null;
  return result as int;
}

/// **TASK29 Chunk 2**: typed-exception mapping для admin RPC failures.
/// Caller передаёт closure → если throw, делаем snackbar с specific i18n.
/// Used от ParticipantActionSheet AND BannedUsersScreen unban path.
/// Возвращает `true` если action отработал без ошибки (caller тогда
/// триггерит refresh). На typed-exception — snackbar + `false`.
///
/// **Контракт context**: к моменту вызова sheet обычно уже `pop()`-нут,
/// поэтому `context` может быть defunct. `ScaffoldMessenger.maybeOf` /
/// `NsgL10n.of` резолвятся синхронно ДО `await action()` — захватываем
/// messenger заранее, до того как RPC завершится и context устареет.
///
/// [actionName] — только для трекера: через этот хелпер проходят все шесть
/// действий листа с одним общим снеком, и без тега отчёт сводится к
/// «админ-действие упало».
Future<bool> _runWithErrorReport(
  BuildContext context,
  String actionName,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = NsgL10n.of(context);
  try {
    await action();
    return true;
  } catch (e, st) {
    // Репортим только немапнутое: «нет прав» и «последний владелец» —
    // штатные отказы, mapAdminError объясняет их словами. Слать их в трекер
    // = топить настоящие баги в шуме.
    if (!isExpectedAdminError(e)) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'room.action': actionName},
      );
    }
    final msg = mapAdminError(e, l);
    messenger?.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
    return false;
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

/// Известный админ-отказ, который [mapAdminError] умеет объяснить словами
/// («нет прав», «последний владелец») — штатный ответ сервера, а не баг:
/// в трекер такие не шлём, иначе он забьётся шумом. Репортить стоит только
/// то, что упало в fallback `roomAdminGenericError`.
///
/// Живёт рядом с [mapAdminError] намеренно: добавляешь маппинг — добавь
/// сюда, иначе новый понятный отказ поедет в трекер как «неизвестный».
bool isExpectedAdminError(Object error) =>
    error is LastOwnerCannotDemoteException ||
    error is InsufficientPowerException;

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
