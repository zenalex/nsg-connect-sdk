import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../rooms/chats_list_controller.dart';
import '../rooms/room_action_sheet.dart';
import '../rooms/room_summary_tile.dart';
import 'chat_screen.dart';

/// TASK44 фаза 1.5 — drill-in экран папки продукта (`ChatsListScreen`
/// пушит его при тапе по строке-папке [FolderRow]). AppBar = имя папки +
/// стрелка «назад»; список — `controller.roomsInFolder(folderKey)` (только
/// чаты этого продукта). Внутри support-комнаты (`RoomType.support`)
/// выносятся секцией «Поддержка» вверху — как в фазе 1.
///
/// Реактивен: слушает тот же [ChatsListController], что и родительский
/// экран, поэтому realtime-refresh обновляет и содержимое папки. Если
/// комнаты папки исчезли (realtime) — показывает empty-state.
class FolderChatsScreen extends StatelessWidget {
  const FolderChatsScreen({
    super.key,
    required this.controller,
    required this.folderKey,
    required this.folderName,
  });

  final ChatsListController controller;

  /// [ChatFolder.selectionKey] папки (напр. `product:10`).
  final String folderKey;

  /// Готовое человекочитаемое имя папки для AppBar (резолвит caller).
  final String folderName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final rooms = controller.roomsInFolder(folderKey);
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                NsgL10n.of(context).chatsListEmpty,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          final rows = _buildRows(context, rooms);
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) => rows[i],
          );
        },
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context, List<RoomSummary> rooms) {
    RoomSummaryTile tile(RoomSummary r) => RoomSummaryTile(
      room: r,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: r.id))),
      onLongPress: () => showRoomActionSheet(
        context: context,
        room: r,
        controller: controller,
      ),
    );

    final support = <RoomSummary>[];
    final others = <RoomSummary>[];
    for (final r in rooms) {
      (r.roomType == RoomType.support ? support : others).add(r);
    }
    // Нет support-комнат → плоский список без лишнего заголовка.
    if (support.isEmpty) return [for (final r in others) tile(r)];

    final l = NsgL10n.of(context);
    return [
      _SectionHeader(label: l.chatsListFolderSupportSection),
      for (final r in support) tile(r),
      if (others.isNotEmpty) ...[
        _SectionHeader(label: l.chatsListFolderOtherSection),
        for (final r in others) tile(r),
      ],
    ];
  }
}

/// Заголовок секции внутри папки (support / прочие).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
