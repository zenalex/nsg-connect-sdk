import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../bots/nsg_messenger_my_bots.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import 'bot_common_widgets.dart';

/// **Issue #49 (открытая платформа ботов)**: экран «Мои боты» — полный
/// self-service ОБЫЧНОГО пользователя: создать бота из профиля, получить
/// токен (виден ОДИН раз), ротировать его, вкл/выкл, управлять
/// видимостью в поиске, видеть комнаты бота и отзывать его из любой.
///
/// Виден ВСЕМ (пункт в настройках без гейта): пустое состояние объясняет,
/// что такое бот. Авторизацию решает сервер — `myBots.*` отдаёт только
/// ботов caller-а (по `ownerEmail`).
///
/// Отличие от [BotsAdminScreen] (TASK36): там tenant-wide админка за
/// BOT_ADMIN_EMAILS; общие механики (one-time токен, диалог создания,
/// журнал) — переиспользуются из bot_common_widgets, не копируются.
class MyBotsScreen extends StatefulWidget {
  const MyBotsScreen({super.key, @visibleForTesting this.myBotsOverride});

  /// Visible-for-testing — позволяет widget-тестам подменить
  /// `MessengerRuntime.instance.myBots` на in-memory fake.
  final NsgMessengerMyBots? myBotsOverride;

  @override
  State<MyBotsScreen> createState() => _MyBotsScreenState();
}

class _MyBotsScreenState extends State<MyBotsScreen> {
  late final NsgMessengerMyBots _myBots;
  late Future<List<Bot>> _botsFuture;

  @override
  void initState() {
    super.initState();
    _myBots = widget.myBotsOverride ?? MessengerRuntime.instance.myBots;
    _botsFuture = _myBots.list();
  }

  Future<void> _refresh() async {
    setState(() {
      _botsFuture = _myBots.list();
    });
    await _botsFuture;
  }

  Future<void> _create() async {
    final l = NsgL10n.of(context);
    // Общий диалог с админкой; email владельца не спрашиваем (владелец —
    // всегда caller, сервер игнорирует любые другие варианты), зато
    // показываем переключатель видимости (дефолт ВЫКЛ).
    final result = await showDialog<BotCreateRequest>(
      context: context,
      builder: (ctx) =>
          BotCreateDialog(l: l, askOwnerEmail: false, showDiscoverable: true),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Bot created;
    try {
      created = await _myBots.create(
        name: result.name,
        capabilities: result.capabilities.join(','),
        discoverable: result.discoverable,
      );
    } on BotLimitExceededException catch (e) {
      // Лимит — не сбой, а правило: показываем число и что делать.
      messenger?.showSnackBar(
        SnackBar(content: Text(l.myBotsLimitReached(e.limit))),
      );
      return;
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
      rotated = await _myBots.rotateToken(botId: bot.id!);
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
      await _myBots.setEnabled(botId: bot.id!, enabled: !bot.enabled);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _toggleDiscoverable(Bot bot) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _myBots.setDiscoverable(
        botId: bot.id!,
        discoverable: !bot.discoverable,
      );
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _showRooms(Bot bot) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BotRoomsSheet(myBots: _myBots, bot: bot),
    );
  }

  Future<void> _showAudit(Bot bot) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BotAuditSheet(
        botName: bot.name,
        loader: () => _myBots.listAuditEvents(botId: bot.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.myBotsTitle)),
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
              // Экран виден всем — пустое состояние объясняет, что такое
              // бот, а не просто говорит «пусто».
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.myBotsEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: bots.length,
              itemBuilder: (context, i) => _MyBotTile(
                bot: bots[i],
                onRotate: () => _rotate(bots[i]),
                onToggleEnabled: () => _toggleEnabled(bots[i]),
                onToggleDiscoverable: () => _toggleDiscoverable(bots[i]),
                onShowRooms: () => _showRooms(bots[i]),
                onShowAudit: () => _showAudit(bots[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Один бот владельца: имя + бейджи («выключен», «в поиске»),
/// capabilities в подзаголовке, ⋯-меню действий. Владельца в подзаголовке
/// нет (в отличие от админки) — здесь все боты свои. Токен не
/// показывается — он виден только в момент выдачи.
class _MyBotTile extends StatelessWidget {
  const _MyBotTile({
    required this.bot,
    required this.onRotate,
    required this.onToggleEnabled,
    required this.onToggleDiscoverable,
    required this.onShowRooms,
    required this.onShowAudit,
  });

  final Bot bot;
  final VoidCallback onRotate;
  final VoidCallback onToggleEnabled;
  final VoidCallback onToggleDiscoverable;
  final VoidCallback onShowRooms;
  final VoidCallback onShowAudit;

  Widget _badge(BuildContext context, String text, {Color? color}) {
    final theme = Theme.of(context);
    final dimmed = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: color ?? dimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return ListTile(
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
            _badge(context, l.botsAdminDisabledBadge),
          ],
          if (bot.discoverable) ...[
            const SizedBox(width: 8),
            // «в поиске» — публичность заметна с первого взгляда: это
            // единственное свойство, которое открывает бота чужим людям.
            _badge(
              context,
              l.myBotsPublicBadge,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
      subtitle: Text(
        bot.capabilities.isEmpty ? l.botsAdminNoCapabilities : bot.capabilities,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: PopupMenuButton<_MyBotAction>(
        onSelected: (action) {
          switch (action) {
            case _MyBotAction.rotate:
              onRotate();
            case _MyBotAction.rooms:
              onShowRooms();
            case _MyBotAction.toggleEnabled:
              onToggleEnabled();
            case _MyBotAction.toggleDiscoverable:
              onToggleDiscoverable();
            case _MyBotAction.audit:
              onShowAudit();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: _MyBotAction.rotate,
            child: _menuRow(Icons.autorenew, l.botsAdminRotateToken),
          ),
          PopupMenuItem(
            value: _MyBotAction.rooms,
            child: _menuRow(Icons.forum_outlined, l.myBotsRooms),
          ),
          PopupMenuItem(
            value: _MyBotAction.toggleEnabled,
            child: _menuRow(
              bot.enabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              bot.enabled ? l.botsAdminDisable : l.botsAdminEnable,
            ),
          ),
          PopupMenuItem(
            value: _MyBotAction.toggleDiscoverable,
            child: _menuRow(
              bot.discoverable
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              bot.discoverable ? l.myBotsMakeHidden : l.myBotsMakeDiscoverable,
            ),
          ),
          PopupMenuItem(
            value: _MyBotAction.audit,
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

enum _MyBotAction { rotate, rooms, toggleEnabled, toggleDiscoverable, audit }

/// Комнаты бота + отзыв. Добавление чужого discoverable-бота свободно
/// (решение постановщика #49) — этот список и есть контроль владельца
/// постфактум: видно, куда бота позвали, из любой комнаты можно отозвать.
class _BotRoomsSheet extends StatefulWidget {
  const _BotRoomsSheet({required this.myBots, required this.bot});

  final NsgMessengerMyBots myBots;
  final Bot bot;

  @override
  State<_BotRoomsSheet> createState() => _BotRoomsSheetState();
}

class _BotRoomsSheetState extends State<_BotRoomsSheet> {
  late Future<List<RoomSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.myBots.listRooms(botId: widget.bot.id!);
  }

  Future<void> _revoke(RoomSummary room) async {
    final l = NsgL10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.myBotsRevokeConfirmTitle),
        content: Text(l.myBotsRevokeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.myBotsRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.myBots.removeFromRoom(
        botId: widget.bot.id!,
        roomId: room.id,
      );
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(l.myBotsRevoked)));
    if (!mounted) return;
    setState(() {
      _future = widget.myBots.listRooms(botId: widget.bot.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l.myBotsRoomsTitle(widget.bot.name),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: FutureBuilder<List<RoomSummary>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text(l.botsAdminLoadFailed)),
                    );
                  }
                  final rooms = snap.data ?? const <RoomSummary>[];
                  if (rooms.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l.myBotsRoomsEmpty)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (context, i) {
                      final room = rooms[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.forum_outlined, size: 20),
                        title: Text(
                          room.name ?? '#${room.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: TextButton(
                          onPressed: () => _revoke(room),
                          child: Text(
                            l.myBotsRevoke,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
