import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../rooms/nsg_messenger_rooms.dart';
import '../rooms/participant_action_sheet.dart' show mapAdminError;

/// **TASK29 Chunk 2**: список заблокированных в комнате с возможностью
/// `Unban`. Lazy-loaded на open (NsgMessengerRooms не кэширует banned
/// list — rare-access + cross-device unban risk stale-data).
///
/// Authorization: caller `role >= admin`. ParticipantsScreen overflow
/// menu hides «Banned users» для member-caller; server enforce
/// `RoomAdminService.listBannedUsers` PL guard. Если caller потерял
/// admin role между navigation и lookup — server reject через
/// `InsufficientPowerException` → snackbar.
///
/// Optimistic unban: tile исчезает мгновенно, RPC летит в фоне; на
/// failure → tile re-appears + snackbar с typed-error i18n.
class BannedUsersScreen extends StatefulWidget {
  const BannedUsersScreen({
    super.key,
    required this.roomId,
    @visibleForTesting this.roomsOverride,
  });

  final int roomId;

  /// Visible-for-testing — позволяет widget-тестам подменить
  /// `MessengerRuntime.instance.rooms` на in-memory fake.
  final NsgMessengerRooms? roomsOverride;

  @override
  State<BannedUsersScreen> createState() => _BannedUsersScreenState();
}

class _BannedUsersScreenState extends State<BannedUsersScreen> {
  late final NsgMessengerRooms _rooms;
  Future<List<RoomParticipant>>? _future;

  /// Local-state list для optimistic unban remove. После initial fetch
  /// future-result копируется сюда; unban removes из `_visible` мгновенно;
  /// fail re-вставляет.
  List<RoomParticipant>? _visible;

  @override
  void initState() {
    super.initState();
    _rooms = widget.roomsOverride ?? MessengerRuntime.instance.rooms;
    _future = _load();
  }

  Future<List<RoomParticipant>> _load() async {
    final list = await _rooms.listBannedUsers(widget.roomId);
    if (mounted) {
      setState(() => _visible = List<RoomParticipant>.of(list));
    }
    return list;
  }

  Future<void> _unban(RoomParticipant target) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = NsgL10n.of(context);
    final snapshot = _visible;
    if (snapshot == null) return;
    // Optimistic remove.
    setState(() {
      _visible = snapshot
          .where((p) => p.messengerUserId != target.messengerUserId)
          .toList();
    });
    try {
      await _rooms.unbanUser(
        roomId: widget.roomId,
        targetMessengerUserId: target.messengerUserId,
      );
    } catch (e) {
      if (!mounted) return;
      // Revert.
      setState(() => _visible = snapshot);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(mapAdminError(e, l)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.bannedUsersTitle)),
      body: FutureBuilder<List<RoomParticipant>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _visible == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _visible == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final list = _visible ?? const <RoomParticipant>[];
          if (list.isEmpty) {
            return Center(
              child: Text(
                l.bannedUsersEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    Icons.block,
                    color: Theme.of(context).colorScheme.error,
                  ),
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
                trailing: TextButton(
                  onPressed: () => _unban(p),
                  child: Text(l.bannedUsersUnbanAction),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
