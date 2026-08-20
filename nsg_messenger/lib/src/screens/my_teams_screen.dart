import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../contacts/nsg_messenger_teams.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../widgets/nsg_avatar_image.dart';
import 'user_picker_screen.dart';

// Chatista Glass токены — те же, что в «Людях»: экран открывается оттуда,
// и переход между ними не должен выглядеть переходом в другое приложение.
const _bg = Color(0xFF1F1A15);
const _fg = Color(0xF5FFFCF8);
const _fgMuted = Color(0xB8FFFCF8);
const _fgDim = Color(0x80FFFCF8);
const _card = Color(0x14FFFFFF);
const _border = Color(0x1FFFFFFF);
const _divider = Color(0x17FFFFFF);

/// **Свои команды пользователя** — этап 3 из
/// `DESIGN_TEAMS_AND_CONTACT_SHARING.md`.
///
/// Команда — список людей БЕЗ переписки: собрал проектную группу —
/// участники увидели друг друга, и заводить общий чат ради этого не
/// пришлось.
///
/// Экран показывает и оргкоманды тенанта — read-only. Скрывать их было бы
/// враньём: коллеги, которых человек видит «непонятно откуда», знакомы
/// именно по ним, и без строки «Команда компании» экран не объясняет
/// главного — откуда взялся список людей.
///
/// Правило «добавить можно только знакомого» здесь НЕ дублируется:
/// клиентская проверка защищает только наш собственный интерфейс. Пикер
/// по умолчанию предлагает знакомых (то есть тех, кого сервер пропустит),
/// а на попытку добавить постороннего показывается причина отказа.
class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key, this.teams});

  /// Фасад команд. Передаётся тестами; в бою берётся из рантайма.
  final NsgMessengerTeams? teams;

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  late final NsgMessengerTeams _teams;
  List<TeamView>? _list;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _teams = widget.teams ?? MessengerRuntime.instance.teams;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _list = null;
    });
    try {
      final list = await _teams.list();
      if (!mounted) return;
      setState(() => _list = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _create() async {
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (_) => const _NewTeamDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await _teams.create(name: result.$1, description: result.$2);
    } catch (e, st) {
      _report(e, st, 'create');
      return;
    }
    await _load();
  }

  Future<void> _delete(TeamView team) async {
    final l = NsgL10n.of(context);
    final ok = await _confirm(
      title: l.myTeamsDelete,
      text: l.myTeamsDeleteConfirm(team.name),
      action: l.myTeamsDelete,
    );
    if (ok != true || !mounted) return;
    try {
      await _teams.delete(team.id);
    } catch (e, st) {
      _report(e, st, 'delete');
      return;
    }
    await _load();
  }

  /// Выйти из чужой команды. Согласия при добавлении не спрашивают,
  /// поэтому и на выход разрешение владельца не требуется.
  Future<void> _leave(TeamView team) async {
    final l = NsgL10n.of(context);
    final ok = await _confirm(
      title: l.myTeamsLeave,
      text: l.myTeamsLeaveConfirm(team.name),
      action: l.myTeamsLeave,
    );
    if (ok != true || !mounted) return;
    try {
      await _teams.leave(team.id);
    } catch (e, st) {
      _report(e, st, 'leave');
      return;
    }
    await _load();
  }

  Future<bool?> _confirm({
    required String title,
    required String text,
    required String action,
  }) {
    final l = NsgL10n.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _report(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'teams.action': action},
    );
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(teamErrorText(NsgL10n.of(context), e))),
    );
  }

  Future<void> _open(TeamView team) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeamMembersScreen(teams: _teams, team: team),
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
    final list = _list;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _fgMuted),
        title: Text(
          l.myTeamsTitle,
          style: const TextStyle(
            color: _fg,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('myTeamsCreateButton'),
            tooltip: l.myTeamsCreate,
            icon: const Icon(Icons.group_add_outlined, color: _fgMuted),
            onPressed: _create,
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.myTeamsActionFailed,
                    style: const TextStyle(color: _fgMuted),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _load, child: Text(l.commonRetry)),
                ],
              ),
            )
          : list == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                    child: Text(
                      l.myTeamsHint,
                      style: const TextStyle(color: _fgDim, fontSize: 12.5),
                    ),
                  ),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        l.myTeamsEmpty,
                        style: const TextStyle(color: _fgDim, fontSize: 13.5),
                      ),
                    )
                  else
                    // Material, а не Container: ListTile рисует нажатие на
                    // ближайшем Material-предке, и цветной контейнер поверх
                    // него просто скрывал бы отклик на тап.
                    Material(
                      color: _card,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: _border, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < list.length; i++)
                            _teamRow(list[i], last: i == list.length - 1),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _teamRow(TeamView team, {required bool last}) {
    final l = NsgL10n.of(context);
    final isOwner = team.myRole == TeamMemberRole.owner;
    final isOrg = team.kind == TeamKind.org;
    final subtitle = [
      if (isOrg) l.myTeamsOrgBadge,
      if (team.description != null && team.description!.isNotEmpty)
        team.description!,
      l.myTeamsMembers(team.memberCount),
    ].join(' · ');
    return Column(
      children: [
        ListTile(
          leading: Icon(
            isOrg ? Icons.apartment_outlined : Icons.groups_outlined,
            color: _fgMuted,
          ),
          title: Text(
            team.name,
            style: const TextStyle(
              color: _fg,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: _fgDim, fontSize: 12.5),
          ),
          onTap: () => _open(team),
          // Оргкоманде кнопок не рисуем вовсе: её состав правит админ
          // платформы, и выйти из справочника компании по своей воле
          // нельзя — предложить и получить отказ было бы обманом.
          trailing: isOrg
              ? null
              : isOwner
              ? IconButton(
                  key: Key('myTeamsDelete_${team.id}'),
                  tooltip: l.myTeamsDelete,
                  icon: const Icon(Icons.delete_outline, color: _fgDim),
                  onPressed: () => _delete(team),
                )
              : IconButton(
                  key: Key('myTeamsLeave_${team.id}'),
                  tooltip: l.myTeamsLeave,
                  icon: const Icon(Icons.logout, color: _fgDim),
                  onPressed: () => _leave(team),
                ),
        ),
        if (!last)
          const SizedBox(height: 0.5, child: ColoredBox(color: _divider)),
      ],
    );
  }
}

/// Состав команды: список участников, для владельца — правка.
class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key, required this.teams, required this.team});

  final NsgMessengerTeams teams;
  final TeamView team;

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  List<TeamMemberView>? _members;

  bool get _canEdit =>
      widget.team.kind == TeamKind.private &&
      widget.team.myRole == TeamMemberRole.owner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.teams.members(widget.team.id);
    if (!mounted) return;
    setState(() => _members = list);
  }

  /// Добавляем ВЫБОРОМ из людей, а не вводом email: пикер по умолчанию
  /// показывает знакомых — ровно тех, кого пропустит серверный гейт.
  ///
  /// Поиском там при этом можно найти и постороннего. Прятать поиск мы не
  /// стали: правду про отказ должен говорить сервер, а человеку понятнее
  /// увидеть причину («сначала познакомьтесь»), чем не найти человека и
  /// решить, что тот вообще не зарегистрирован.
  Future<void> _add() async {
    final l = NsgL10n.of(context);
    final picked = await pickMessengerUser(context, title: l.myTeamsMemberAdd);
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.teams.addMember(
        teamId: widget.team.id,
        messengerUserId: picked.messengerUserId,
      );
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'teams.action': 'addMember'},
      );
      messenger?.showSnackBar(SnackBar(content: Text(teamErrorText(l, e))));
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
        title: Text(l.myTeamsMemberRemove),
        content: Text(l.myTeamsMemberRemoveConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.myTeamsMemberRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.teams.removeMember(
        teamId: widget.team.id,
        messengerUserId: m.messengerUserId,
      );
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'teams.action': 'removeMember'},
      );
      messenger?.showSnackBar(SnackBar(content: Text(teamErrorText(l, e))));
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final members = _members;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _fgMuted),
        title: Text(
          widget.team.name,
          style: const TextStyle(
            color: _fg,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_canEdit)
            IconButton(
              key: const Key('myTeamsAddMemberButton'),
              tooltip: l.myTeamsMemberAdd,
              icon: const Icon(Icons.person_add_alt_1, color: _fgMuted),
              onPressed: _add,
            ),
        ],
      ),
      body: members == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                  child: Text(
                    // Предупреждение обязательно и ДО добавления: членство
                    // взаимно, и человек должен понимать это заранее.
                    l.myTeamsMemberAddWarning,
                    style: const TextStyle(color: _fgDim, fontSize: 12.5),
                  ),
                ),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l.myTeamsMembersEmpty,
                      style: const TextStyle(color: _fgDim, fontSize: 13.5),
                    ),
                  )
                else
                  Material(
                    color: _card,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _border, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        for (final m in members)
                          ListTile(
                            leading: NsgAvatarImage(
                              mxcUrl: m.avatarUrl,
                              fallbackName:
                                  m.displayName ?? '#${m.messengerUserId}',
                              size: 40,
                            ),
                            title: Text(
                              m.displayName ?? '#${m.messengerUserId}',
                              style: const TextStyle(
                                color: _fg,
                                fontSize: 15.5,
                              ),
                            ),
                            // Владельца из состава не убрать: без него
                            // командой стало бы некому распорядиться.
                            trailing: _canEdit && m.role != TeamMemberRole.owner
                                ? IconButton(
                                    key: Key(
                                      'myTeamsRemove_${m.messengerUserId}',
                                    ),
                                    tooltip: l.myTeamsMemberRemove,
                                    icon: const Icon(
                                      Icons.person_remove_outlined,
                                      color: _fgDim,
                                    ),
                                    onPressed: () => _remove(m),
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Текст отказа для пользователя.
///
/// Главный случай — [TeamPeerUnknownException]: это не сбой, а правило.
/// Общий текст «не удалось» заставил бы человека жать кнопку повторно,
/// хотя повторять бессмысленно — надо сначала познакомиться.
String teamErrorText(NsgL10n l, Object error) {
  if (error is TeamPeerUnknownException) return l.myTeamsPeerUnknown;
  if (error is TeamAccessDeniedException) return l.myTeamsAccessDenied;
  return l.myTeamsActionFailed;
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
      title: Text(l.myTeamsCreate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('myTeamsNameField'),
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l.myTeamsName),
          ),
          TextField(
            controller: _description,
            decoration: InputDecoration(labelText: l.myTeamsDescription),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: const Key('myTeamsCreateConfirm'),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            final desc = _description.text.trim();
            Navigator.of(context).pop((name, desc.isEmpty ? null : desc));
          },
          child: Text(l.myTeamsCreate),
        ),
      ],
    );
  }
}
