import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../support/support_team_controller.dart';
import '../support/support_team_rpc.dart';
import '../support/support_team_state.dart';
import 'contact_profile_screen.dart';

/// **TASK43**: экран «Команда поддержки». Список операторов с ролями;
/// владелец может добавить оператора по email и удалить участника.
/// Доступ гейтится сервером: не-участник получает
/// [NotSupportTeamMemberException] → экран показывает «недоступно».
///
/// Открывается через `NsgMessenger.openSupportTeam(context,
/// productExternalKey: ...)`.
class SupportTeamScreen extends StatefulWidget {
  const SupportTeamScreen({
    super.key,
    required this.productExternalKey,
    @visibleForTesting this.rpcOverride,
    @visibleForTesting this.selfMessengerUserIdOverride,
  });

  final String productExternalKey;

  /// Visible-for-testing — подмена RPC без Serverpod-клиента.
  final SupportTeamRpc? rpcOverride;

  /// **#25**: visible-for-testing — bypass `MessengerRuntime.instance
  /// .session` для widget-тестов без полного init рантайма (тот же приём,
  /// что в [ParticipantsScreen.selfMessengerUserIdOverride]).
  final int? selfMessengerUserIdOverride;

  @override
  State<SupportTeamScreen> createState() => _SupportTeamScreenState();
}

class _SupportTeamScreenState extends State<SupportTeamScreen> {
  late final SupportTeamController _controller;
  late final int _selfMessengerUserId;
  final _emailCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selfMessengerUserId =
        widget.selfMessengerUserIdOverride ??
        MessengerRuntime.instance.session.messengerUserId;
    _controller = SupportTeamController(
      rpc:
          widget.rpcOverride ??
          ClientSupportTeamRpc(MessengerRuntime.instance.client),
      productExternalKey: widget.productExternalKey,
    );
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _add(NsgL10n l) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await _controller.addMember(_emailCtl.text);
    if (!mounted) return;
    if (ok) {
      _emailCtl.clear();
    } else if (_emailCtl.text.trim().isNotEmpty) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.supportTeamActionFailed)),
      );
    }
  }

  Future<void> _remove(NsgL10n l, SupportTeamMemberView m) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await _controller.removeMember(m.messengerUserId);
    if (!mounted) return;
    if (!ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.supportTeamActionFailed)),
      );
    }
  }

  /// **TASK48**: сменить тир участника (owner-only). Ошибку — снекбар.
  Future<void> _setTier(NsgL10n l, SupportTeamMemberView m, int tier) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await _controller.setMemberTier(m.messengerUserId, tier);
    if (!mounted) return;
    if (!ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.supportTeamActionFailed)),
      );
    }
  }

  /// **TASK76**: сменить роль участника (назначить/снять администратора).
  /// Guard последнего owner-а — на сервере; ошибку показываем снекбаром.
  Future<void> _setRole(
    NsgL10n l,
    SupportTeamMemberView m,
    SupportTeamRole role,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await _controller.setMemberRole(m.messengerUserId, role);
    if (!mounted) return;
    if (!ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.supportTeamActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.supportTeamTitle)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return switch (state) {
            SupportTeamLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SupportTeamUnavailable() => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.supportTeamUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SupportTeamReady(:final view, :final busy) => _buildReady(
              l,
              view,
              busy,
            ),
          };
        },
      ),
    );
  }

  Widget _buildReady(NsgL10n l, SupportTeamView view, bool busy) {
    return Column(
      children: [
        if (view.viewerIsOwner) _buildAddBar(l, busy),
        _buildTimeoutTile(l, view, busy),
        const Divider(height: 1),
        Expanded(
          child: view.members.isEmpty
              ? Center(child: Text(l.supportTeamEmpty))
              : ListView.separated(
                  itemCount: view.members.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _buildTile(l, view, view.members[i], busy),
                ),
        ),
      ],
    );
  }

  Widget _buildAddBar(NsgL10n l, bool busy) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _emailCtl,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: l.supportTeamAddHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: busy ? null : (_) => _add(l),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : () => _add(l),
            child: Text(l.supportTeamAddAction),
          ),
        ],
      ),
    );
  }

  /// **TASK48 iter2**: порог авто-эскалации команды (owner может править).
  Widget _buildTimeoutTile(NsgL10n l, SupportTeamView view, bool busy) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.timer_outlined),
      title: Text(l.supportTeamTimeoutLabel),
      subtitle: Text(
        '${view.escalationTimeoutMinutes} ${l.supportTeamMinutesShort}',
      ),
      trailing: view.viewerIsOwner
          ? IconButton(
              key: const Key('editTimeoutButton'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: busy ? null : () => _editTimeout(l, view),
            )
          : null,
    );
  }

  Future<void> _editTimeout(NsgL10n l, SupportTeamView view) async {
    final ctl = TextEditingController(
      text: view.escalationTimeoutMinutes.toString(),
    );
    final ml = MaterialLocalizations.of(context);
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.supportTeamTimeoutLabel),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: l.supportTeamMinutesShort),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ml.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(ctl.text.trim())),
            child: Text(ml.okButtonLabel),
          ),
        ],
      ),
    );
    if (minutes == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await _controller.setTimeout(minutes);
    if (!mounted) return;
    if (!ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.supportTeamActionFailed)),
      );
    }
  }

  /// **#25**: открыть профиль участника команды поддержки. Переиспользуем
  /// общий [ContactProfileScreen] и тот же путь навигации по
  /// `messengerUserId`, что список участников комнаты ([ParticipantsScreen])
  /// и экран «Люди» ([PeopleScreen]) — карточка (реальное имя / @username /
  /// визитка / метки) без изобретения нового API. Данные подтягивает сам
  /// экран профиля; отсутствие визитки он переживает (best-effort).
  void _openProfile(SupportTeamMemberView m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ContactProfileScreen(contactMessengerUserId: m.messengerUserId),
      ),
    );
  }

  Widget _buildTile(
    NsgL10n l,
    SupportTeamView view,
    SupportTeamMemberView m,
    bool busy,
  ) {
    final roleLabel = m.role == SupportTeamRole.owner
        ? l.supportTeamRoleOwner
        : l.supportTeamRoleMember;
    final isHuman = !m.isBot;
    final subtitle = <String>[
      roleLabel,
      if (m.isBot) l.supportTeamBotBadge,
      // TASK48: помечаем старших (тир ≥ 2); фронт-линия (тир 1) без бейджа.
      if (isHuman && m.tier >= 2) l.supportTeamTierEscalation,
      // **Приватность (#25)**: персональный email оператора виден ТОЛЬКО
      // владельцу команды (как audit), а не всем её членам. Полная
      // переработка работы с командами поддержки — отдельный таск.
      if (view.viewerIsOwner && m.email != null && m.email!.isNotEmpty)
        m.email!,
    ].join(' · ');
    final isSelf = m.messengerUserId == _selfMessengerUserId;
    // Owner может управлять всеми, кроме себя (последнего owner-а сервер
    // защищает LastOwnerCannotDemoteException — здесь просто прячем
    // управление у самого себя для ясности UX).
    final canManage = view.viewerIsOwner && !isSelf;
    return ListTile(
      leading: CircleAvatar(
        child: Icon(m.isBot ? Icons.smart_toy_outlined : Icons.person_outline),
      ),
      title: Text(m.displayName ?? '#${m.messengerUserId}'),
      subtitle: Text(subtitle),
      // **#25**: тап по участнику открывает его профиль контакта (кроме
      // своей строки — профиль «глазами себя» бессмыслен). Раньше строка
      // была мёртвой целью (нет onTap). Тот же путь навигации, что в
      // списке участников комнаты и «Люди».
      onTap: isSelf ? null : () => _openProfile(m),
      // **TASK48**: меню управления — смена тира (для людей) + удаление.
      trailing: canManage
          ? PopupMenuButton<_MemberAction>(
              key: Key('memberMenu_${m.messengerUserId}'),
              enabled: !busy,
              itemBuilder: (context) => [
                if (isHuman && m.tier != 1)
                  PopupMenuItem<_MemberAction>(
                    value: _MemberAction.makeFrontline,
                    child: Text(l.supportTeamMakeFrontline),
                  ),
                if (isHuman && m.tier < 2)
                  PopupMenuItem<_MemberAction>(
                    value: _MemberAction.makeEscalation,
                    child: Text(l.supportTeamMakeEscalation),
                  ),
                // **TASK76**: назначение других администраторов — только
                // для людей (бот owner-ом быть не может, сервер тоже
                // отклонит).
                if (isHuman && m.role != SupportTeamRole.owner)
                  PopupMenuItem<_MemberAction>(
                    value: _MemberAction.makeOwner,
                    child: Text(l.supportTeamMakeOwner),
                  ),
                if (isHuman && m.role == SupportTeamRole.owner)
                  PopupMenuItem<_MemberAction>(
                    value: _MemberAction.revokeOwner,
                    child: Text(l.supportTeamRevokeOwner),
                  ),
                PopupMenuItem<_MemberAction>(
                  value: _MemberAction.remove,
                  child: Text(l.supportTeamRemoveAction),
                ),
              ],
              onSelected: (a) {
                switch (a) {
                  case _MemberAction.makeFrontline:
                    _setTier(l, m, 1);
                  case _MemberAction.makeEscalation:
                    _setTier(l, m, 2);
                  case _MemberAction.makeOwner:
                    _setRole(l, m, SupportTeamRole.owner);
                  case _MemberAction.revokeOwner:
                    _setRole(l, m, SupportTeamRole.member);
                  case _MemberAction.remove:
                    _remove(l, m);
                }
              },
            )
          : null,
    );
  }
}

/// **TASK48/76**: действия owner-а над участником команды в
/// [SupportTeamScreen] (смена тира / роль админа / удаление).
enum _MemberAction {
  makeFrontline,
  makeEscalation,
  makeOwner,
  revokeOwner,
  remove,
}
