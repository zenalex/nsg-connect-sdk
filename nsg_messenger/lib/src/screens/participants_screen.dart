import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../rooms/nsg_messenger_rooms.dart';
import '../rooms/participant_action_sheet.dart';
import '../rooms/role_badge.dart';
import '../widgets/nsg_avatar_image.dart';
import 'banned_users_screen.dart';

/// **TASK29 Chunk 2**: список участников комнаты с role badges +
/// long-press → admin action sheet (kick/ban/promote/demote).
///
/// Lifecycle:
///   * `initState` — подгружает [RoomDetails] через `NsgMessenger.rooms.
///     get(roomId)`, чтобы получить participants + viewerRole.
///   * `getRoom` invalidate-ится через `roomMembershipUpdated` reactor
///     (TASK42 + TASK29 PL changes); auto-refresh не делаем — у user-а
///     может быть открытый sheet, нельзя rebuild-ить mid-action. На
///     pull-to-refresh / повторное open экран refetch свежие данные.
///
/// Admin overflow menu (AppBar) — «Banned users» visible только для
/// admin/owner caller. Server-side `listBannedUsers` тоже enforce-ит.
class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({
    super.key,
    required this.roomId,
    @visibleForTesting this.roomsOverride,
    @visibleForTesting this.selfMessengerUserIdOverride,
  });

  final int roomId;

  /// Visible-for-testing.
  final NsgMessengerRooms? roomsOverride;

  /// Visible-for-testing — bypass `MessengerRuntime.instance.session`
  /// для widget-тестов без full runtime init.
  final int? selfMessengerUserIdOverride;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  late final NsgMessengerRooms _rooms;
  late final int _selfMessengerUserId;
  late Future<RoomDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _rooms = widget.roomsOverride ?? MessengerRuntime.instance.rooms;
    _selfMessengerUserId =
        widget.selfMessengerUserIdOverride ??
        MessengerRuntime.instance.session.messengerUserId;
    _detailsFuture = _rooms.get(widget.roomId);
  }

  Future<void> _refresh() async {
    setState(() {
      _rooms.invalidate(roomId: widget.roomId);
      _detailsFuture = _rooms.get(widget.roomId);
    });
    await _detailsFuture;
  }

  Future<void> _onLongPress(RoomDetails details, RoomParticipant target) async {
    final callerRole = details.viewerRole;
    if (callerRole == RoomMemberRole.member) return; // no admin actions
    await showParticipantActionSheet(
      context: context,
      room: details,
      target: target,
      callerRole: callerRole,
      callerMessengerUserId: _selfMessengerUserId,
      rooms: _rooms,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.participantsTitle),
        actions: [
          FutureBuilder<RoomDetails>(
            future: _detailsFuture,
            builder: (context, snap) {
              final details = snap.data;
              if (details == null) return const SizedBox.shrink();
              if (details.viewerRole == RoomMemberRole.member) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (key) {
                  if (key == 'banned') {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            BannedUsersScreen(roomId: widget.roomId),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'banned',
                    child: Text(l.participantsBannedMenuItem),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<RoomDetails>(
        future: _detailsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final details = snap.data;
          if (details == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final showAdminButton =
              details.viewerRole == RoomMemberRole.admin ||
                  details.viewerRole == RoomMemberRole.owner;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: details.participants.length,
              itemBuilder: (context, i) {
                final p = details.participants[i];
                final isSelf = p.messengerUserId == _selfMessengerUserId;
                return ListTile(
                  leading: NsgAvatarImage(
                    mxcUrl: p.avatarUrl,
                    fallbackName: p.displayName ?? p.matrixUserId,
                    size: 40,
                  ),
                  title: Text(
                    p.displayName ?? p.matrixUserId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    p.matrixUserId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RoleBadge(role: p.role),
                      if (showAdminButton && !isSelf) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          tooltip: 'Действия',
                          onPressed: () => _onLongPress(details, p),
                        ),
                      ],
                    ],
                  ),
                  onLongPress: () => _onLongPress(details, p),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
