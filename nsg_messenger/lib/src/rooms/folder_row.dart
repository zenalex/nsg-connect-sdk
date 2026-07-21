import 'package:flutter/material.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../utils/relative_time.dart';
import 'chat_folder.dart';

/// TASK44 фаза 1.5 — строка-папка в основном списке чатов SDK
/// (`ChatsListScreen`). Рендерится как обычный [ListTile]-ряд в стиле
/// [RoomSummaryTile], но для продуктовой папки: иконка-папка (или аватар
/// продукта, если резолвится), имя продукта, превью+время самого свежего
/// чата папки, бейдж суммарного unread. Тап проваливает в drill-in экран
/// папки ([FolderChatsScreen]).
///
/// Stateless: агрегаты берутся из [ChatFolder] (построен SDK-функцией
/// `buildFolders`). Цвета — из `ColorScheme` (не хардкод).
class FolderRow extends StatelessWidget {
  const FolderRow({super.key, required this.folder, this.onTap});

  final ChatFolder folder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final cs = Theme.of(context).colorScheme;
    // Имя зависит от вида папки: у продуктовой — имя/ключ продукта, у
    // агрегатных и пользовательских продуктовых полей нет вовсе (раньше
    // они отрисовывались как «Продукт 0»).
    final name = switch (folder.kind) {
      ChatFolderKind.saved => l.savedChatsTitle,
      ChatFolderKind.support => l.chatsListFolderSupport,
      ChatFolderKind.custom => folder.customName ?? l.chatsListFolderCustom,
      _ =>
        folder.productDisplayName ??
            folder.productKey ??
            l.chatsListFolderProductFallback(folder.productId ?? 0),
    };
    final avatarUrl = folder.productAvatarUrl;

    return ListTile(
      onTap: onTap,
      leading: _FolderAvatar(
        url: avatarUrl,
        background: cs,
        icon: _iconFor(folder.kind),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        folder.lastMessagePreview ??
            l.chatsListFolderRoomCount(folder.roomCount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _FolderMeta(folder: folder),
    );
  }
}

/// Иконка строки-папки по её виду. «Избранное» — закладка (тот же символ,
/// что у Telegram Saved Messages), «Поддержка» — наушники, прочие — папка.
IconData _iconFor(ChatFolderKind kind) => switch (kind) {
  ChatFolderKind.saved => Icons.bookmark_rounded,
  ChatFolderKind.support => Icons.support_agent_rounded,
  _ => Icons.folder_rounded,
};

/// Аватар строки-папки: иконка на приглушённом фоне (fallback), либо
/// сетевой аватар продукта, если [url] задан.
class _FolderAvatar extends StatelessWidget {
  const _FolderAvatar({
    required this.url,
    required this.background,
    this.icon = Icons.folder_rounded,
  });

  final String? url;
  final ColorScheme background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url!));
    }
    return CircleAvatar(
      backgroundColor: background.primaryContainer,
      child: Icon(icon, color: background.onPrimaryContainer),
    );
  }
}

class _FolderMeta extends StatelessWidget {
  const _FolderMeta({required this.folder});

  final ChatFolder folder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final ts = folder.lastMessageAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ts != null)
          RelativeTimeText(
            timestamp: ts,
            lang: lang,
            shortEn: false,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        if (folder.unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              constraints: const BoxConstraints(minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                folder.unreadCount > 99 ? '99+' : '${folder.unreadCount}',
                style: TextStyle(fontSize: 11, color: cs.onPrimary),
              ),
            ),
          ),
      ],
    );
  }
}
