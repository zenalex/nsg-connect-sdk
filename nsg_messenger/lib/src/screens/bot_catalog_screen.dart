import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../bots/nsg_messenger_bot_catalog.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../widgets/nsg_avatar_image.dart';
import '../widgets/nsg_bot_badge.dart';
import 'bot_card_screen.dart';
import 'bot_common_widgets.dart';

/// **TASK77 итер.3**: мини-каталог «Добавить бота» — открывается из настроек
/// чата владельцем/админом (пункт рядом с «Интеграциями»).
///
/// До итер.3 существующего бота в чат мог добавить только платформенный
/// админ; здесь это делает сам владелец чата. Поэтому каталог обязан дать
/// ему то, чего у админа и так было в голове: **что бот читает**. Режим
/// чтения показан крупно у каждой записи (`BotReadModeLine(prominent)`) —
/// «читает ВСЕ сообщения» должно настораживать ДО подключения, а не
/// выясняться потом.
class BotCatalogScreen extends StatefulWidget {
  const BotCatalogScreen({
    super.key,
    required this.roomId,
    @visibleForTesting this.catalogOverride,
  });

  /// Чат, куда подключаем (нужен и серверу — для гейта и метки `inRoom`).
  final int roomId;

  final NsgMessengerBotCatalog? catalogOverride;

  @override
  State<BotCatalogScreen> createState() => _BotCatalogScreenState();
}

class _BotCatalogScreenState extends State<BotCatalogScreen> {
  late final NsgMessengerBotCatalog _catalog =
      widget.catalogOverride ?? MessengerRuntime.instance.botCatalog;

  late Future<List<AvailableBot>> _botsFuture;

  /// botId, по которым сейчас идёт подключение — блокируем повторный тап
  /// (сервер идемпотентен, но двойной снекбар «подключён» сбивает с толку).
  final Set<int> _connecting = <int>{};

  @override
  void initState() {
    super.initState();
    _botsFuture = _load();
  }

  Future<List<AvailableBot>> _load() =>
      _catalog.listAvailableBots(roomId: widget.roomId);

  Future<void> _refresh() async {
    // Блочная форма, а не `=> _botsFuture = _load()`: стрелка вернула бы
    // Future, и setState справедливо ругается «асинхронная работа внутри
    // setState» (поймано widget-тестом).
    setState(() {
      _botsFuture = _load();
    });
    await _botsFuture;
  }

  Future<void> _connect(AvailableBot bot) async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _connecting.add(bot.botId));
    try {
      await _catalog.addBotToMyRoom(botId: bot.botId, roomId: widget.roomId);
    } catch (_) {
      if (mounted) setState(() => _connecting.remove(bot.botId));
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    messenger?.showSnackBar(
      SnackBar(content: Text(l.botCatalogConnected(bot.name))),
    );
    if (!mounted) return;
    setState(() => _connecting.remove(bot.botId));
    await _refresh();
  }

  Future<void> _openCard(AvailableBot bot) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BotCardScreen(
          botMessengerUserId: bot.messengerUserId,
          roomId: widget.roomId,
          initialBot: bot,
          catalogOverride: widget.catalogOverride,
        ),
      ),
    );
    // Из карточки можно и подключить, и отключить бота — состав чата мог
    // измениться, перечитываем.
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.botCatalogTitle)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AvailableBot>>(
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
                    child: Text(l.botCatalogLoadFailed),
                  ),
                ],
              );
            }
            final bots = snap.data ?? const <AvailableBot>[];
            if (bots.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l.botCatalogEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: bots.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      l.botCatalogIntro,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  );
                }
                final bot = bots[index - 1];
                return _BotCatalogTile(
                  bot: bot,
                  busy: _connecting.contains(bot.botId),
                  onConnect: () => _connect(bot),
                  onOpen: () => _openCard(bot),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BotCatalogTile extends StatelessWidget {
  const _BotCatalogTile({
    required this.bot,
    required this.busy,
    required this.onConnect,
    required this.onOpen,
  });

  final AvailableBot bot;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final description = bot.description?.trim();
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NsgAvatarImage(
              mxcUrl: bot.avatarUrl,
              fallbackName: bot.name,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bot.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const NsgBotBadge(
                        kind: ParticipantKind.bot,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description == null || description.isEmpty
                        ? l.botCatalogNoDescription
                        : description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                      fontStyle: (description == null || description.isEmpty)
                          ? FontStyle.italic
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Крупный режим чтения — то, ради чего каталог вообще
                  // показывает больше, чем имя.
                  BotReadModeLine.readsAll(
                    readsAll: NsgMessengerBotCatalog.readsAllMessages(bot),
                    prominent: true,
                  ),
                  if (bot.commands.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      l.botsAdminCommandsLabel(
                        bot.commands.map((c) => '/${c.command}').join(', '),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: bot.inRoom
                        ? Text(
                            l.botsAdminAlreadyInRoom,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          )
                        : FilledButton.tonal(
                            onPressed: busy ? null : onConnect,
                            child: Text(l.botCatalogConnect),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
