import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../pulse/nsg_messenger_pulse.dart';
import '../theme/overlay_surface.dart';
import '../widgets/nsg_avatar_image.dart';

/// **TASK79 п.9**: состав участников папки или монитора — по образцу
/// управления составом комнаты ([ParticipantsScreen]).
///
/// Экран открывается для РОВНО ОДНОГО объекта: либо `folderId`, либо
/// `monitorId` (как `createRule` и серверный `setMember`).
///
/// Строки с `inherited` — членство, пришедшее от папки-предка. Они
/// показаны, но не редактируются здесь: жест «убрать» на унаследованной
/// строке молча ничего бы не сделал (сервер удаляет членство ТОГО объекта,
/// на котором оно заведено), а это худший вид неработающей кнопки — тот,
/// что выглядит сработавшим.
class PulseMembersScreen extends StatefulWidget {
  const PulseMembersScreen({
    super.key,
    required this.pulse,
    this.folderId,
    this.monitorId,
    this.title,
    required this.canManage,
  }) : assert(
         (folderId == null) != (monitorId == null),
         'Ровно один из folderId/monitorId',
       );

  final NsgMessengerPulse pulse;
  final int? folderId;
  final int? monitorId;
  final String? title;

  /// Caller — `owner` объекта. Кнопки состава рисуем только ему; сервер
  /// всё равно проверяет права сам, это подсказка интерфейсу.
  final bool canManage;

  @override
  State<PulseMembersScreen> createState() => _PulseMembersScreenState();
}

class _PulseMembersScreenState extends State<PulseMembersScreen> {
  late Future<List<PulseMemberView>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.pulse.listMembers(
      folderId: widget.folderId,
      monitorId: widget.monitorId,
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(text)));
  }

  /// Общая обёртка мутаций: типизированный отказ сервера показываем
  /// человеку, а неожиданное — ещё и в трекер.
  Future<bool> _run(String action, Future<void> Function() body) async {
    final l = NsgL10n.of(context);
    try {
      await body();
      return true;
    } on LastOwnerCannotDemoteException {
      // Штатный отказ по правилу — не инцидент, в трекер не шлём.
      _snack(l.pulseLastOwnerError);
      return false;
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'pulse.action': action},
      );
      _snack(l.pulseActionFailed);
      return false;
    }
  }

  Future<void> _addMember() async {
    final picked = await Navigator.of(context).push<RoomParticipant>(
      MaterialPageRoute(builder: (_) => const _PulseUserPickerScreen()),
    );
    if (picked == null || !mounted) return;
    final role = await _pickRole(initial: PulseClientRoles.viewer);
    if (role == null || !mounted) return;
    final ok = await _run(
      'setMember',
      () => widget.pulse.setMember(
        folderId: widget.folderId,
        monitorId: widget.monitorId,
        messengerUserId: picked.messengerUserId,
        role: role,
      ),
    );
    if (ok && mounted) setState(_reload);
  }

  Future<void> _changeRole(PulseMemberView member) async {
    final role = await _pickRole(initial: member.role);
    if (role == null || role == member.role || !mounted) return;
    final ok = await _run(
      'setMemberRole',
      () => widget.pulse.setMember(
        folderId: widget.folderId,
        monitorId: widget.monitorId,
        messengerUserId: member.messengerUserId,
        role: role,
      ),
    );
    if (ok && mounted) setState(_reload);
  }

  Future<void> _remove(PulseMemberView member) async {
    final l = NsgL10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pulseRemoveMember),
        content: Text(_nameOf(member)),
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
            child: Text(l.pulseRemoveMember),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _run(
      'removeMember',
      () => widget.pulse.removeMember(
        folderId: widget.folderId,
        monitorId: widget.monitorId,
        messengerUserId: member.messengerUserId,
      ),
    );
    if (ok && mounted) setState(_reload);
  }

  Future<String?> _pickRole({required String initial}) {
    final l = NsgL10n.of(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.pulseRoleLabel),
        children: [
          for (final role in const [
            PulseClientRoles.viewer,
            PulseClientRoles.admin,
            PulseClientRoles.owner,
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(role),
              child: Row(
                children: [
                  Icon(
                    _roleIcon(role),
                    size: 20,
                    color: role == initial
                        ? Theme.of(ctx).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(roleLabel(l, role)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static IconData _roleIcon(String role) => switch (role) {
    PulseClientRoles.owner => Icons.workspace_premium,
    PulseClientRoles.admin => Icons.shield_outlined,
    _ => Icons.visibility_outlined,
  };

  static String _nameOf(PulseMemberView m) {
    final name = m.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = m.username?.trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return '#${m.messengerUserId}';
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final title = widget.title == null
        ? l.pulseMembers
        : l.pulseMembersOf(widget.title!);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l.pulseAddMember),
            )
          : null,
      body: FutureBuilder<List<PulseMemberView>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _centered(
              context,
              snap.error is MessengerNotAuthenticatedException
                  ? Icons.lock_outline
                  : Icons.error_outline,
              snap.error is MessengerNotAuthenticatedException
                  ? l.pulseNoAccess
                  : l.pulseLoadFailed,
            );
          }
          final members = snap.data ?? const <PulseMemberView>[];
          if (members.isEmpty) {
            return _centered(context, Icons.people_outline, l.pulseNoMembers);
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: members.length,
            itemBuilder: (context, i) => _memberTile(context, l, members[i]),
          );
        },
      ),
    );
  }

  Widget _memberTile(BuildContext context, NsgL10n l, PulseMemberView m) {
    final theme = Theme.of(context);
    final username = m.username?.trim();
    // Унаследованное членство редактируется в папке-предке, а не здесь.
    final editable = widget.canManage && !m.inherited;
    return ListTile(
      leading: NsgAvatarImage(
        mxcUrl: m.avatarUrl,
        fallbackName: _nameOf(m),
        size: 40,
      ),
      title: Text(_nameOf(m), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        m.inherited
            ? '${roleLabel(l, m.role)} · ${l.pulseRoleInherited}'
            : (username != null && username.isNotEmpty
                  ? '@$username'
                  : roleLabel(l, m.role)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _roleIcon(m.role),
            size: 18,
            color: m.inherited
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : theme.colorScheme.primary,
          ),
          if (editable)
            PopupMenuButton<_MemberAction>(
              // Иконка задана явно (а не дефолтом): по ней экран находят
              // виджет-тесты, и она совпадает с меню участников комнаты.
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => switch (action) {
                _MemberAction.changeRole => _changeRole(m),
                _MemberAction.remove => _remove(m),
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: _MemberAction.changeRole,
                  child: Text(l.pulseRoleLabel),
                ),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: Text(
                    l.pulseRemoveMember,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ),
              ],
            ),
        ],
      ),
      onTap: m.inherited && widget.canManage
          ? () => _snack(l.pulseMemberInheritedHint)
          : null,
    );
  }

  static Widget _centered(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

enum _MemberAction { changeRole, remove }

/// Локализованное имя роли. Публичная — её же использует дерево Пульса,
/// чтобы подписи ролей нигде не разъехались.
String roleLabel(NsgL10n l, String role) => switch (role) {
  PulseClientRoles.owner => l.pulseRoleOwner,
  PulseClientRoles.admin => l.pulseRoleAdmin,
  PulseClientRoles.viewer => l.pulseRoleViewer,
  _ => role,
};

/// Выбор пользователя тенанта: знакомые контакты + поиск с дебаунсом.
/// Тот же путь, что у «Добавить участников» в группу — переиспользуем
/// `rooms.listKnownContacts()`/`rooms.searchUsers()`, чтобы не заводить
/// второй, расходящийся источник людей.
class _PulseUserPickerScreen extends StatefulWidget {
  const _PulseUserPickerScreen();

  @override
  State<_PulseUserPickerScreen> createState() => _PulseUserPickerScreenState();
}

class _PulseUserPickerScreenState extends State<_PulseUserPickerScreen> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  List<RoomParticipant> _contacts = const [];
  List<RoomParticipant> _results = const [];
  bool _loading = true;
  bool _searched = false;

  bool get _showingContacts => _queryCtrl.text.trim().length < 2;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await MessengerRuntime.instance.rooms
          .listKnownContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      // Контакты — удобство, не обязательное условие: поиск работает и без них.
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _queryCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _loading = true);
    try {
      final found = await MessengerRuntime.instance.rooms.searchUsers(query: q);
      if (!mounted) return;
      setState(() {
        _results = found;
        _searched = true;
        _loading = false;
      });
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'pulse.action': 'searchUsers'},
      );
      if (mounted) {
        setState(() {
          _results = const [];
          _searched = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final list = _showingContacts ? _contacts : _results;
    return Scaffold(
      appBar: AppBar(title: Text(l.pulsePickMember)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryCtrl,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.pulseMemberSearchHint,
                border: const OutlineInputBorder(),
                fillColor: kOverlaySurface,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _searched || _showingContacts
                            ? l.pulseMemberSearchEmpty
                            : '',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final u = list[i];
                      final name = u.displayName?.trim().isNotEmpty == true
                          ? u.displayName!
                          : u.matrixUserId;
                      return ListTile(
                        leading: NsgAvatarImage(
                          mxcUrl: u.avatarUrl,
                          fallbackName: name,
                          size: 40,
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          u.username != null && u.username!.isNotEmpty
                              ? '@${u.username}'
                              : u.matrixUserId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => Navigator.of(context).pop(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
