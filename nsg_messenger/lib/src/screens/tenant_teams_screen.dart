import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_platform_admin.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import 'user_picker_screen.dart';

/// **Оргкоманды тенанта — справочник компании**
/// (этап 2 из `DESIGN_TEAMS_AND_CONTACT_SHARING.md`).
///
/// Решает исходную боль: новый человек в тенанте видит пустой список
/// людей и найти кого-то может, только сходив к коллеге за адресом.
/// Положили новичка в «Компанию» — он видит коллег, не зная ни одного
/// email, и никакой переписки для этого создавать не надо.
///
/// Экран платформенный: право положить человека в команду равно праву
/// раздавать знакомства, поэтому оргструктуру заводит владелец платформы,
/// а сервер гейтит каждый вызов email-allowlist-ом.
class TenantTeamsScreen extends StatefulWidget {
  const TenantTeamsScreen({
    super.key,
    required this.tenantExternalKey,
    required this.tenantName,
    this.admin,
  });

  final String tenantExternalKey;
  final String tenantName;

  /// Админка, которой пользоваться. Передаёт родитель (дерево
  /// «Платформы»), чтобы экран не лез в рантайм за своей копией — иначе
  /// при подмене (и в тестах) он смотрел бы не туда.
  final NsgMessengerPlatformAdmin? admin;

  @override
  State<TenantTeamsScreen> createState() => _TenantTeamsScreenState();
}

class _TenantTeamsScreenState extends State<TenantTeamsScreen> {
  late final NsgMessengerPlatformAdmin _admin;
  List<TeamView>? _teams;

  @override
  void initState() {
    super.initState();
    _admin = widget.admin ?? MessengerRuntime.instance.platformAdmin;
    _load();
  }

  Future<void> _load() async {
    final list = await _admin.listTeams(
      tenantExternalKey: widget.tenantExternalKey,
    );
    if (!mounted) return;
    setState(() => _teams = list);
  }

  Future<void> _create() async {
    final l = NsgL10n.of(context);
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => const _NewTeamDialog(),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.createTeam(
        tenantExternalKey: widget.tenantExternalKey,
        name: result.$1,
        description: result.$2,
      );
    } catch (e) {
      // Тёзку показываем ОТДЕЛЬНОЙ причиной: общий отказ заставил бы
      // админа гадать, а справочник с двумя «Разработками» бесполезен.
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('TeamNameTaken')
                ? l.platformAdminTeamNameTaken
                : l.platformAdminActionFailed,
          ),
        ),
      );
      return;
    }
    await _load();
  }

  /// Удаление с подтверждением, которое называет ПОСЛЕДСТВИЕ: люди
  /// перестанут видеть друг друга, но переписка останется. Без этого
  /// «распустить» читается как «стереть чаты».
  Future<void> _delete(TeamView team) async {
    final l = NsgL10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.platformAdminTeamDelete),
        content: Text(l.platformAdminTeamDeleteConfirm(team.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.platformAdminTeamDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.deleteTeam(
        tenantExternalKey: widget.tenantExternalKey,
        teamId: team.id,
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.platformAdminActionFailed)),
      );
      return;
    }
    await _load();
  }

  Future<void> _openTeam(TeamView team) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TeamMembersScreen(
          admin: _admin,
          tenantExternalKey: widget.tenantExternalKey,
          team: team,
        ),
      ),
    );
    if (!mounted) return;
    // Перечитываем список, а не просто перерисовываем: в строке команды
    // показан РАЗМЕР состава, а на открытом экране его как раз и меняли.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final teams = _teams;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.platformAdminTeams),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.tenantName} (${widget.tenantExternalKey})',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: l.platformAdminTeamCreate,
            onPressed: _create,
          ),
        ],
      ),
      body: teams == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.platformAdminTeamsHint,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (teams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l.platformAdminTeamsEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                for (final t in teams)
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(t.name),
                    subtitle: Text(
                      t.description == null || t.description!.isEmpty
                          ? l.platformAdminTeamMembers(t.memberCount)
                          : '${t.description}\n'
                                '${l.platformAdminTeamMembers(t.memberCount)}',
                    ),
                    isThreeLine:
                        t.description != null && t.description!.isNotEmpty,
                    onTap: () => _openTeam(t),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l.platformAdminTeamDelete,
                      onPressed: () => _delete(t),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Состав одной команды.
class _TeamMembersScreen extends StatefulWidget {
  const _TeamMembersScreen({
    required this.admin,
    required this.tenantExternalKey,
    required this.team,
  });

  final NsgMessengerPlatformAdmin admin;
  final String tenantExternalKey;
  final TeamView team;

  @override
  State<_TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<_TeamMembersScreen> {
  List<TeamMemberView>? _members;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.admin.listTeamMembers(
      tenantExternalKey: widget.tenantExternalKey,
      teamId: widget.team.id,
    );
    if (!mounted) return;
    setState(() => _members = list);
  }

  /// Добавляем ВЫБОРОМ из людей мессенджера, а не вводом email: набирать
  /// адрес того, кто и так есть в списке, — лишняя работа с шансом
  /// опечататься.
  Future<void> _add() async {
    final l = NsgL10n.of(context);
    final picked = await pickMessengerUser(
      context,
      title: l.platformAdminTeamMemberAdd,
    );
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.admin.addTeamMember(
        tenantExternalKey: widget.tenantExternalKey,
        teamId: widget.team.id,
        messengerUserId: picked.messengerUserId,
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('TeamFull')
                ? l.platformAdminTeamFull
                : l.platformAdminActionFailed,
          ),
        ),
      );
      return;
    }
    await _load();
  }

  Future<void> _remove(TeamMemberView m) async {
    final l = NsgL10n.of(context);
    final name = m.displayName ?? '#${m.messengerUserId}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.platformAdminTeamMemberRemove),
        content: Text(l.platformAdminTeamMemberRemoveConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.platformAdminTeamMemberRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.admin.removeTeamMember(
        tenantExternalKey: widget.tenantExternalKey,
        teamId: widget.team.id,
        messengerUserId: m.messengerUserId,
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.platformAdminActionFailed)),
      );
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final members = _members;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l.platformAdminTeamMemberAdd,
            onPressed: _add,
          ),
        ],
      ),
      body: members == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    // Предупреждение обязательно: добавление в команду —
                    // взаимный жест, и админ должен это понимать ДО, а не
                    // после.
                    l.platformAdminTeamMemberAddWarning,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l.platformAdminTeamMembersEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                for (final m in members)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(m.displayName ?? '#${m.messengerUserId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      tooltip: l.platformAdminTeamMemberRemove,
                      onPressed: () => _remove(m),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _NewTeamDialog extends StatefulWidget {
  const _NewTeamDialog();

  @override
  State<_NewTeamDialog> createState() => _NewTeamDialogState();
}

class _NewTeamDialogState extends State<_NewTeamDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return AlertDialog(
      title: Text(l.platformAdminTeamCreate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l.platformAdminTeamName),
          ),
          TextField(
            controller: _description,
            decoration: InputDecoration(
              labelText: l.platformAdminTeamDescription,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            final desc = _description.text.trim();
            Navigator.of(context).pop((name, desc.isEmpty ? null : desc));
          },
          child: Text(l.platformAdminTeamCreate),
        ),
      ],
    );
  }
}
