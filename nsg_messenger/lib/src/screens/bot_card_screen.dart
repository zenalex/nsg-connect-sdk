import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../bots/nsg_messenger_bot_catalog.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../rooms/room_picker_sheet.dart';
import '../widgets/nsg_avatar_image.dart';
import '../widgets/nsg_bot_badge.dart';
import 'bot_common_widgets.dart';

/// **TASK77 итер.3**: карточка бота — «кто это и можно ли ему доверять».
///
/// Открывается тапом по боту: из списка участников, из шапки 1:1-чата и из
/// каталога «Добавить бота». Показывает описание, владельца, объявленные
/// команды и — **крупно** — режим чтения: это единственное место, где
/// человек, не заводивший этого бота, вообще может узнать, читает ли
/// программа всю переписку его группы.
///
/// Действия доступны по роли: «добавить в чат…» — только для чатов, где
/// caller владелец/админ (список отдаёт сервер, `listMyAdminRooms`);
/// «отключить от этого чата» — только когда карточка открыта из чата,
/// бот в нём состоит и caller там админ. Кнопки не показываются, если
/// права нет: пикер с чатами, половина которых ответит отказом, — это
/// враньё про права пользователя.
class BotCardScreen extends StatefulWidget {
  const BotCardScreen({
    super.key,
    required this.botMessengerUserId,
    this.roomId,
    this.initialBot,
    this.catalogOverride,
  });

  /// `Bot.messengerUserId` — то, как бота знает список участников и автор
  /// сообщения.
  final int botMessengerUserId;

  /// Чат, из которого открыли карточку (для `inRoom` и «отключить»).
  final int? roomId;

  /// Уже загруженная запись (каталог её только что получил) — чтобы не
  /// делать второй RPC ради того же самого. Всё равно перезапрашиваем
  /// при действиях, меняющих состав чата.
  final AvailableBot? initialBot;

  /// Подмена фасада. Не `@visibleForTesting`: его прокидывает ещё и
  /// [BotCatalogScreen], открывая карточку — иначе тест каталога терял бы
  /// инъекцию на первом же переходе.
  final NsgMessengerBotCatalog? catalogOverride;

  @override
  State<BotCardScreen> createState() => _BotCardScreenState();
}

class _BotCardScreenState extends State<BotCardScreen> {
  late final NsgMessengerBotCatalog _catalog =
      widget.catalogOverride ?? MessengerRuntime.instance.botCatalog;

  late Future<AvailableBot?> _botFuture;

  /// Чаты, где caller админ. Нужны и пикеру «добавить в чат…», и решению
  /// «показывать ли „отключить“» — грузим один раз лениво.
  Future<List<RoomSummary>>? _adminRoomsFuture;

  @override
  void initState() {
    super.initState();
    _botFuture = widget.initialBot != null
        ? Future<AvailableBot?>.value(widget.initialBot)
        : _load();
    _adminRoomsFuture = _catalog.listMyAdminRooms();
  }

  Future<AvailableBot?> _load() => _catalog.getBotCard(
    botMessengerUserId: widget.botMessengerUserId,
    roomId: widget.roomId,
  );

  Future<void> _refresh() async {
    setState(() {
      _botFuture = _load();
      _adminRoomsFuture = _catalog.listMyAdminRooms();
    });
    await _botFuture;
  }

  Future<void> _addToRoom(AvailableBot bot) async {
    final l = NsgL10n.of(context);
    final room = await showRoomPicker(
      context: context,
      title: l.botCardPickRoomTitle,
      searchHint: l.forwardSearchHint,
      emptyText: l.botCardNoAdminRooms,
      errorText: l.botCatalogLoadFailed,
      // Только чаты, где caller вправе подключать бота — гейт тот же, что
      // на сервере, а не «все мои чаты».
      roomsLoader: () => _catalog.listMyAdminRooms(),
    );
    if (room == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _catalog.addBotToMyRoom(botId: bot.botId, roomId: room.id);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.botCardAddedToRoom(room.name ?? '#${room.id}')),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _removeFromRoom(AvailableBot bot) async {
    final l = NsgL10n.of(context);
    final roomId = widget.roomId;
    if (roomId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.botCardRemoveConfirmTitle),
        content: Text(l.botCardRemoveConfirmBody(bot.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.botCardRemoveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _catalog.removeBotFromMyRoom(botId: bot.botId, roomId: roomId);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.botsAdminActionFailed)));
      return;
    }
    messenger?.showSnackBar(SnackBar(content: Text(l.botCardRemoved)));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.botCardTitle)),
      body: FutureBuilder<AvailableBot?>(
        future: _botFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bot = snap.data;
          if (snap.hasError || bot == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snap.hasError
                      ? l.botCatalogLoadFailed
                      : l.botCardUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _BotCardBody(
            bot: bot,
            roomId: widget.roomId,
            adminRoomsFuture: _adminRoomsFuture,
            onAddToRoom: () => _addToRoom(bot),
            onRemoveFromRoom: () => _removeFromRoom(bot),
          );
        },
      ),
    );
  }
}

class _BotCardBody extends StatelessWidget {
  const _BotCardBody({
    required this.bot,
    required this.roomId,
    required this.adminRoomsFuture,
    required this.onAddToRoom,
    required this.onRemoveFromRoom,
  });

  final AvailableBot bot;
  final int? roomId;
  final Future<List<RoomSummary>>? adminRoomsFuture;
  final VoidCallback onAddToRoom;
  final VoidCallback onRemoveFromRoom;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final description = bot.description?.trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NsgAvatarImage(
              mxcUrl: bot.avatarUrl,
              fallbackName: bot.name,
              size: 56,
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
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Анти-имперсонация: «это программа» видно всегда и
                      // не отключается (довесок A).
                      const NsgBotBadge(kind: ParticipantKind.bot),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.botCardOwner(bot.ownerDisplayName ?? bot.ownerEmail),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          description == null || description.isEmpty
              ? l.botCatalogNoDescription
              : description,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: (description == null || description.isEmpty)
                ? FontStyle.italic
                : null,
          ),
        ),
        const SizedBox(height: 20),
        // Главный trust-сигнал — крупно, тем же виджетом, что в админке и
        // «Моих ботах» (третьей формулировки режима в SDK нет).
        BotReadModeLine.readsAll(
          readsAll: NsgMessengerBotCatalog.readsAllMessages(bot),
          prominent: true,
        ),
        const SizedBox(height: 20),
        if (bot.commands.isEmpty)
          Text(
            l.botsAdminNoCommands,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else ...[
          Text(l.botCardCommandsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final c in bot.commands)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '/${c.command}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 24),
        // Кнопки — по правам. Пока список админских чатов не пришёл, не
        // показываем ничего: мигнувшая и исчезнувшая кнопка хуже, чем
        // появившаяся с задержкой.
        FutureBuilder<List<RoomSummary>>(
          future: adminRoomsFuture,
          builder: (context, snap) {
            final rooms = snap.data;
            if (rooms == null) return const SizedBox.shrink();
            final canManageThisRoom =
                roomId != null && rooms.any((r) => r.id == roomId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (rooms.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: onAddToRoom,
                    icon: const Icon(Icons.add),
                    label: Text(l.botCardAddToRoom),
                  ),
                if (canManageThisRoom && bot.inRoom) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRemoveFromRoom,
                    icon: const Icon(Icons.link_off),
                    label: Text(l.botCardRemoveFromRoom),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
