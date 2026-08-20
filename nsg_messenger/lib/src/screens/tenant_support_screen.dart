import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_platform_admin.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import 'user_picker_screen.dart';

/// **Поддержка на уровне тенанта.**
///
/// Одни и те же операторы ведут поддержку всех продуктов заказчика, а
/// вписывать их приходилось в каждую команду продукта заново. Люди из
/// этого списка числятся в команде КАЖДОГО продукта тенанта, пока состоят
/// здесь: убрали отсюда — исчезли во всех сразу, появился новый продукт —
/// получил их автоматически.
///
/// Экран платформенный (открывается из «Платформы» у тенанта), поэтому
/// действия идут через [NsgMessengerPlatformAdmin]: сервер гейтит их
/// email-allowlist-ом платформенных админов.
class TenantSupportScreen extends StatefulWidget {
  const TenantSupportScreen({
    super.key,
    required this.tenantExternalKey,
    required this.tenantName,
    this.admin,
  });

  final String tenantExternalKey;
  final String tenantName;

  /// Админка, которой пользоваться. Передаёт родитель (дерево
  /// «Платформы»), чтобы экран не лез в рантайм за своей копией — иначе
  /// при подмене (и в тестах) он смотрел бы не туда. `null` — открыли
  /// экран напрямую, берём рантаймовую.
  final NsgMessengerPlatformAdmin? admin;

  @override
  State<TenantSupportScreen> createState() => _TenantSupportScreenState();
}

class _TenantSupportScreenState extends State<TenantSupportScreen> {
  late final NsgMessengerPlatformAdmin _admin;
  List<TenantSupportMemberView>? _members;

  @override
  void initState() {
    super.initState();
    _admin = widget.admin ?? MessengerRuntime.instance.platformAdmin;
    _load();
  }

  Future<void> _load() async {
    final list = await _admin.listTenantSupport(
      tenantExternalKey: widget.tenantExternalKey,
    );
    if (!mounted) return;
    setState(() => _members = list);
  }

  /// Добавляем ВЫБОРОМ из людей мессенджера, а не вводом email: набирать
  /// адрес того, кто и так есть в списке, — лишняя работа с шансом
  /// опечататься (тот же приём, что при смене владельца команды).
  Future<void> _add() async {
    final l = NsgL10n.of(context);
    final picked = await pickMessengerUser(
      context,
      title: l.platformAdminTenantSupportAdd,
    );
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.addTenantSupportMember(
        tenantExternalKey: widget.tenantExternalKey,
        messengerUserId: picked.messengerUserId,
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.platformAdminActionFailed)),
      );
      return;
    }
    await _load();
  }

  /// Удаление с подтверждением, которое называет ПОСЛЕДСТВИЕ: человек
  /// исчезает не из одной команды, а из всех продуктов тенанта.
  Future<void> _remove(TenantSupportMemberView m) async {
    final l = NsgL10n.of(context);
    final name = m.displayName ?? '#${m.messengerUserId}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.platformAdminTenantSupportRemove),
        content: Text(l.platformAdminTenantSupportRemoveConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.platformAdminTenantSupportRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.removeTenantSupportMember(
        tenantExternalKey: widget.tenantExternalKey,
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
        title: Text(l.platformAdminTenantSupport),
        // Тенант в подзаголовке: экран открывается из дерева платформы, и
        // без него не видно, чью поддержку правишь.
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
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l.platformAdminTenantSupportAdd,
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
                    l.platformAdminTenantSupportHint,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l.platformAdminTenantSupportEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                for (final m in members)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(m.displayName ?? '#${m.messengerUserId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      tooltip: l.platformAdminTenantSupportRemove,
                      onPressed: () => _remove(m),
                    ),
                  ),
              ],
            ),
    );
  }
}
