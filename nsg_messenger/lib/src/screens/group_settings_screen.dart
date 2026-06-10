import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../rooms/nsg_messenger_rooms.dart';
import '../widgets/nsg_avatar_image.dart';
import 'add_members_to_group_screen.dart';
import 'participants_screen.dart';

/// **B16-extension**: экран настроек группы. Открывается тапом по
/// названию group-чата (см. `ChatScreen._RoomTitle`).
///
/// Содержит:
///   * заголовок с аватаром + именем группы (tap → rename dialog для
///     admin/owner);
///   * блок «Участники (N)» → push [ParticipantsScreen];
///   * кнопка «Добавить участников» (admin/owner) → push
///     [AddMembersToGroupScreen].
///
/// Не блокирует UI на загрузку details: показывает spinner-ы там, где
/// данные ещё не пришли.
///
/// На pop с `true` родительский ChatScreen может invalidate room cache —
/// сейчас этим занимается [NsgMessengerRooms.inviteToRoom] internally,
/// поэтому экрану достаточно просто dismiss.
class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({
    super.key,
    required this.roomId,
    required this.onRequestRename,
  });

  final int roomId;

  /// Колбэк, открывающий rename-dialog. Реализован в SDK
  /// `_RenameRoomDialog` (в `chat_screen.dart`); прокидывается отсюда,
  /// чтобы не дублировать UI rename-у. Возвращает `bool?` —
  /// `true` если пользователь сохранил новое имя (мы перезагрузим
  /// details).
  final Future<bool?> Function(BuildContext context, String currentName)
  onRequestRename;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final NsgMessengerRooms _rooms;
  late Future<RoomDetails> _detailsFuture;

  /// **B16-ext (group avatar)**: pending-флаг для прогресса в Stack-FAB
  /// поверх аватара. Сбрасывается после success / error.
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    _rooms = MessengerRuntime.instance.rooms;
    _detailsFuture = _rooms.get(widget.roomId);
  }

  Future<void> _refresh() async {
    setState(() {
      _rooms.invalidate(roomId: widget.roomId);
      _detailsFuture = _rooms.get(widget.roomId);
    });
    await _detailsFuture;
  }

  Future<void> _openRename(RoomDetails details) async {
    final saved = await widget.onRequestRename(context, details.name ?? '');
    if (saved == true) {
      await _refresh();
    }
  }

  /// **B16-ext (group avatar)**: pick image → upload → refresh details.
  /// Best-effort: ошибки показываются snackbar-ом, текущий avatar
  /// остаётся прежним.
  Future<void> _pickAndUploadAvatar(RoomDetails details) async {
    if (_avatarUploading) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Не удалось открыть галерею: $e')),
      );
      return;
    }
    if (picked == null || !mounted) return;
    setState(() => _avatarUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? _guessMime(picked.name);
      await _rooms.setRoomAvatar(
        roomId: widget.roomId,
        bytes: ByteData.sublistView(bytes),
        mimeType: mime,
      );
      if (!mounted) return;
      // Server invalidate cache + UPDATE Room.avatarUrl сразу — refresh
      // подтянет свежий URL.
      await _refresh();
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Аватар группы обновлён')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Не удалось загрузить аватар: $e')),
      );
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  String _guessMime(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  Future<void> _openAddMembers() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMembersToGroupScreen(roomId: widget.roomId),
      ),
    );
    if (added == true) {
      await _refresh();
    }
  }

  /// **«Удалить группу»** для owner.
  ///
  /// С Pass-N atomic dissolveRoom RPC: один серверный вызов
  /// `_rooms.dissolveRoom(roomId)` — сервер сам kick-ает всех peer-ов
  /// и leave-ит self. Network blip посередине больше не оставляет
  /// группу в полу-удалённом состоянии: на partial failure сервер
  /// бросает `RoomDissolvePartialException`, UI показывает snackbar,
  /// owner может повторить (idempotent).
  ///
  ///   1. confirm dialog (destructive);
  ///   2. один RPC `dissolveRoom(roomId)` под progress snackbar-ом;
  ///   3. success → popUntil(isFirst) + success snackbar;
  ///   4. exception → snackbar с error.
  Future<void> _dissolveGroup(RoomDetails details) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text(l.groupDissolveConfirmTitle(details.name ?? '?')),
          content: Text(l.groupDissolveConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.groupDissolveAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.groupDissolveProgress),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      await _rooms.dissolveRoom(widget.roomId);
    } on RoomDissolvePartialException catch (ex) {
      if (!mounted) return;
      messenger?.hideCurrentSnackBar();
      // Typed partial: server успел kick-нуть `kicked` из `total` peer-ов,
      // owner остался в room. UI показывает локализованную статистику и
      // оставляет юзера на экране — повторный «Удалить группу» idempotent.
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l.groupDissolveFailed(ex.kicked, ex.total)),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(content: Text('$e'), duration: const Duration(seconds: 5)),
      );
      return;
    }

    if (!mounted) return;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(l.groupDissolveSuccess)));
    // Возвращаемся к корневому экрану (chat list). PopUntil isFirst
    // безопасно: даже если на стэке есть ChatScreen → GroupSettings,
    // оба слетят.
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки группы')),
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
          final isAdmin =
              details.viewerRole == RoomMemberRole.admin ||
              details.viewerRole == RoomMemberRole.owner;
          final isGroup = details.roomType == RoomType.group;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      NsgAvatarImage(
                        mxcUrl: details.avatarUrl,
                        fallbackName: details.name ?? '?',
                        size: 88,
                      ),
                      // B16-ext (group avatar): tap по камера-FAB →
                      // image picker → upload. Только для admin/owner
                      // group/team-чата (direct reject-ит сервер).
                      if (isAdmin && isGroup && !_avatarUploading)
                        Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => _pickAndUploadAvatar(details),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (_avatarUploading)
                        const Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: InkWell(
                      onTap: (isAdmin && isGroup)
                          ? () => _openRename(details)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                details.name ?? '—',
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isAdmin && isGroup) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _roomTypeLabel(details.roomType),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Участники'),
                  trailing: Text(
                    '${details.totalParticipants}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ParticipantsScreen(roomId: widget.roomId),
                      ),
                    );
                  },
                ),
                if (isAdmin && isGroup)
                  ListTile(
                    leading: Icon(
                      Icons.person_add_alt_1,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Добавить участников',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _openAddMembers,
                  ),
                if (details.viewerRole == RoomMemberRole.owner && isGroup) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      NsgL10n.of(context).groupDissolveAction,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _dissolveGroup(details),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _roomTypeLabel(RoomType type) {
    // Используем if-chain — `RoomType` имеет 9 значений, не все из них
    // в текущем UI используются (family / system / internal /
    // customerRoom — server-internal). Switch с required catch-all
    // выглядит хуже, чем targeted labels с дефолтом.
    if (type == RoomType.direct) return 'Личный чат';
    if (type == RoomType.group) return 'Группа';
    if (type == RoomType.productRoom) return 'Чат продукта';
    if (type == RoomType.support) return 'Поддержка';
    if (type == RoomType.team) return 'Команда';
    if (type == RoomType.family) return 'Семья';
    return type.name;
  }
}
