import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_bots_admin.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../rooms/room_picker_sheet.dart';
import 'bot_common_widgets.dart';

/// **TASK36 (admin panel для ботов)**: экран управления ботами tenant-а.
/// Закрывает DoD «создать бота через admin panel и получить access token» —
/// до него единственным путём был curl к `botAdmin`-эндпоинту.
///
/// Виден только тем, чей email в серверном `BOT_ADMIN_EMAILS`: хост-
/// приложение прячет вход по `NsgMessenger.botsAdmin.isBotAdmin()`, но это
/// лишь UX — авторизацию решает сервер на каждом методе, экран без прав
/// просто не получит данных.
///
/// Состав: список ботов (имя, capabilities, владелец) + ⋯-меню:
///   * **Ротация токена** — новый credential, старый отзывается немедленно
///     (ответ на утечку; бот, его комнаты и история постов сохраняются);
///   * **Добавить в чат** — picker по чатам админа (бот должен быть в
///     комнате, чтобы постить);
///   * **Вкл/выкл** — kill-switch;
///   * **Журнал** — аудит: кто завёл/ротировал/выключал + `capability_denied`
///     (сигнал, что бот ломится за не выданным grant-ом).
///
/// Токен показывается ОДИН раз — при создании и при ротации. В списке его
/// нет намеренно: экран не должен быть местом, где credential можно
/// подсмотреть через плечо.
///
/// Room-scoped self-service (владелец группы заводит бота в СВОЮ комнату) —
/// это другой экран, `IntegrationsScreen` (TASK58/59); здесь tenant-wide
/// админский путь.
class BotsAdminScreen extends StatefulWidget {
  const BotsAdminScreen({
    super.key,
    this.tenantExternalKey,
    @visibleForTesting this.adminOverride,
  });

  /// Tenant, чьих ботов показываем. По умолчанию — серверный дефолт
  /// (`nsg`), совпадает с сигнатурами `botAdmin.*`.
  final String? tenantExternalKey;

  /// Visible-for-testing — позволяет widget-тестам подменить
  /// `MessengerRuntime.instance.botsAdmin` на in-memory fake.
  final NsgMessengerBotsAdmin? adminOverride;

  @override
  State<BotsAdminScreen> createState() => _BotsAdminScreenState();
}

class _BotsAdminScreenState extends State<BotsAdminScreen> {
  late final NsgMessengerBotsAdmin _admin;
  late final String _tenant;
  late Future<List<Bot>> _botsFuture;

  @override
  void initState() {
    super.initState();
    _admin = widget.adminOverride ?? MessengerRuntime.instance.botsAdmin;
    _tenant = widget.tenantExternalKey ?? NsgMessengerBotsAdmin.kDefaultTenant;
    _botsFuture = _admin.listBots(tenantExternalKey: _tenant);
  }

  Future<void> _refresh() async {
    setState(() {
      _botsFuture = _admin.listBots(tenantExternalKey: _tenant);
    });
    await _botsFuture;
  }

  Future<void> _create() async {
    final l = NsgL10n.of(context);
    // Общий диалог с «Моими ботами» (#49); админка спрашивает email
    // владельца И показывает переключатель видимости — админ заводит бота
    // «за владельца», и осознанный выбор публичности принимается прямо
    // здесь (дефолт ВЫКЛ), а не откладывается на отдельный заход владельца
    // в «Мои боты».
    final result = await showDialog<BotCreateRequest>(
      context: context,
      builder: (ctx) => BotCreateDialog(l: l, showDiscoverable: true),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Bot created;
    try {
      created = await _admin.createBot(
        tenantExternalKey: _tenant,
        name: result.name,
        ownerEmail: result.ownerEmail!,
        capabilities: result.capabilities.join(','),
        discoverable: result.discoverable,
      );
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    if (!mounted) return;
    await showBotTokenDialog(context, created.accessToken);
    await _refresh();
  }

  Future<void> _rotate(Bot bot) async {
    final l = NsgL10n.of(context);
    final confirmed = await confirmBotTokenRotation(context);
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Bot rotated;
    try {
      rotated = await _admin.rotateToken(botId: bot.id!);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    if (!mounted) return;
    await showBotTokenDialog(context, rotated.accessToken);
    await _refresh();
  }

  Future<void> _toggleEnabled(Bot bot) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.setEnabled(botId: bot.id!, enabled: !bot.enabled);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _addToRoom(Bot bot) async {
    final l = NsgL10n.of(context);
    // **issue #50 follow-up**: комнаты, где бот уже есть, показываем с
    // бейджем «уже добавлен» и не даём тапнуть — иначе повтор молча
    // съедался идемпотентным no-op-ом, а снекбар рапортовал «добавлен».
    final busyRoomIds = await _admin.listBotRoomIds(botId: bot.id!);
    if (!mounted) return;
    // Общее ядро «выбор чата» (forward / share-in) — свой пикер здесь
    // дублировал бы список/поиск и дрейфовал от канонического.
    final room = await showRoomPicker(
      context: context,
      title: l.botsAdminAddToRoomTitle,
      searchHint: l.forwardSearchHint,
      emptyText: l.botsAdminNoRooms,
      errorText: l.botsAdminLoadFailed,
      // **issue #50**: админский листинг — ВСЕ комнаты tenant-а. Дефолтный
      // loader пикера отдаёт комнаты самого админа, и целевой комнаты в
      // списке могло не быть (сервер же членства caller-а не требует).
      roomsLoader: () => _admin.listAllRooms(),
      disabledRoomIds: busyRoomIds,
      disabledBadge: l.botsAdminAlreadyInRoom,
    );
    if (room == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _admin.addToRoom(botId: bot.id!, roomId: room.id);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminAddedToRoom)));
  }

  Future<void> _showAudit(Bot bot) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BotAuditSheet(
        botName: bot.name,
        loader: () => _admin.listAuditEvents(botId: bot.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.botsAdminTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l.botsAdminCreate),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Bot>>(
          future: _botsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(l.botsAdminLoadFailed),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final bots = snap.data ?? const <Bot>[];
            if (bots.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: Center(
                      child: Text(
                        l.botsAdminEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: bots.length,
              itemBuilder: (context, i) => _BotAdminTile(
                bot: bots[i],
                onRotate: () => _rotate(bots[i]),
                onToggleEnabled: () => _toggleEnabled(bots[i]),
                onAddToRoom: () => _addToRoom(bots[i]),
                onShowAudit: () => _showAudit(bots[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Один бот в списке админки: имя (+ бейдж «выключен»), capabilities и
/// владелец в подзаголовке, ⋯-меню действий. Токен не показывается —
/// он виден только в момент выдачи.
class _BotAdminTile extends StatelessWidget {
  const _BotAdminTile({
    required this.bot,
    required this.onRotate,
    required this.onToggleEnabled,
    required this.onAddToRoom,
    required this.onShowAudit,
  });

  final Bot bot;
  final VoidCallback onRotate;
  final VoidCallback onToggleEnabled;
  final VoidCallback onAddToRoom;
  final VoidCallback onShowAudit;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final dimmed = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return ListTile(
      isThreeLine: true,
      leading: Icon(
        Icons.smart_toy_outlined,
        color: bot.enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              bot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: bot.enabled
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (!bot.enabled) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l.botsAdminDisabledBadge,
                style: theme.textTheme.labelSmall?.copyWith(color: dimmed),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bot.capabilities.isEmpty ? l.botsAdminNoCapabilities : bot.capabilities,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            bot.ownerEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: dimmed),
          ),
        ],
      ),
      trailing: PopupMenuButton<_BotAdminAction>(
        onSelected: (action) {
          switch (action) {
            case _BotAdminAction.rotate:
              onRotate();
            case _BotAdminAction.addToRoom:
              onAddToRoom();
            case _BotAdminAction.toggleEnabled:
              onToggleEnabled();
            case _BotAdminAction.audit:
              onShowAudit();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: _BotAdminAction.rotate,
            child: _menuRow(Icons.autorenew, l.botsAdminRotateToken),
          ),
          PopupMenuItem(
            value: _BotAdminAction.addToRoom,
            child: _menuRow(Icons.group_add_outlined, l.botsAdminAddToRoom),
          ),
          PopupMenuItem(
            value: _BotAdminAction.toggleEnabled,
            child: _menuRow(
              bot.enabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              bot.enabled ? l.botsAdminDisable : l.botsAdminEnable,
            ),
          ),
          PopupMenuItem(
            value: _BotAdminAction.audit,
            child: _menuRow(Icons.history, l.botsAdminAudit),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

enum _BotAdminAction { rotate, addToRoom, toggleEnabled, audit }
