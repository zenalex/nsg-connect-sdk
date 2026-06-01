import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../i18n/generated/nsg_l10n.dart';
import '../theme/nsg_messenger_theme.dart';
import '../utils/relative_time.dart';

/// Один элемент списка чатов. Тестируется отдельно от
/// [ChatsListScreen] (см. ревью b89bfd9 подсказка b).
///
/// `onLongPress` (TASK42 Chunk 2): вызывается на long-press для
/// открытия `showRoomActionSheet` (mute/archive/leave). Tile сам
/// stateless — sheet строится parent-ом, тут только callback.
class RoomSummaryTile extends StatelessWidget {
  const RoomSummaryTile({
    super.key,
    required this.room,
    this.onTap,
    this.onLongPress,
  });

  final RoomSummary room;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // TASK22 Phase2 Chunk 1: domain tokens — host-app может override
    // через `NsgMessengerTheme.roomTileTokens`. Fallback на defaults.
    final tileTokens =
        Theme.of(context).extension<NsgRoomTileTokens>() ??
        NsgRoomTileTokens.fallback;
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: tileTokens.contentPadding,
      leading: _Avatar(
        name: room.name,
        url: room.avatarUrl,
        size: tileTokens.avatarSize,
      ),
      title: Text(
        room.name ?? NsgL10n.of(context).roomSummaryNoName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        // TASK22 Phase2 Chunk 1: title→subtitle spacing через top-padding
        // subtitle-а (ListTile сам управляет вертикалями между title/
        // leading/trailing, явный SizedBox внутрь title не вставить).
        padding: EdgeInsets.only(top: tileTokens.titleSubtitleSpacing),
        child: Text(
          // Material 3 ListTile сам приглушает subtitle через
          // bodyMedium/onSurfaceVariant; ручной override стиля убрали,
          // чтобы host-app `ListTileTheme.subtitleTextStyle` не
          // игнорировался (см. ревью 29ebbdf #3).
          room.lastMessagePreview ?? NsgL10n.of(context).roomSummaryNoMessages,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: _TrailingMeta(room: room, tokens: tileTokens),
    );
  }
}

/// Avatar с graceful fallback: при отсутствии URL или ошибке загрузки
/// показывает CircleAvatar с initials. Без этого UX «загружается» /
/// «ошибка» хуже чем сразу читаемые буквы (см. подсказка-Q5 ревью).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.url, required this.size});

  final String? name;
  final String? url;
  final double size;

  static String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isEmpty ? '?' : parts.first.characters.first;
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.characters.first
        : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    // `size` — diameter; `CircleAvatar.radius` — radius (size / 2).
    final radius = size / 2;
    final fallback = CircleAvatar(radius: radius, child: Text(initials));
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: u,
      imageBuilder: (_, img) =>
          CircleAvatar(radius: radius, backgroundImage: img),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
      fadeInDuration: const Duration(milliseconds: 80),
    );
  }
}

class _TrailingMeta extends StatelessWidget {
  const _TrailingMeta({required this.room, required this.tokens});

  final RoomSummary room;
  final NsgRoomTileTokens tokens;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final ts = room.lastMessageAt;
    // RelativeTimeText сам тикает раз в минуту — без него tile показывал
    // бы «только что» до следующего обновления списка чатов.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ts != null)
          RelativeTimeText(
            timestamp: ts,
            lang: lang,
            shortEn: false, // «5 minutes ago» — полная форма для room list
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (room.muted)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.notifications_off,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        // unreadCount badge — на TASK13 всегда 0 (TASK18 наполнит реально),
        // здесь UI готов: при unreadCount>0 показываем badge.
        if (room.unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              // TASK22 Phase2 Chunk 1: minHeight enforced из tokens —
              // single-digit badge получает baseline pill-shape. minWidth
              // НЕ выставляется (иначе ListTile trailing throws «consumes
              // entire width» — Column-cross-axis treats minWidth как
              // intrinsic). Text сам растягивает ширину при «99+».
              constraints: BoxConstraints(minHeight: tokens.unreadBadgeSize),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(tokens.unreadBadgeSize / 2),
              ),
              child: Text(
                room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Регистрирует RU-локаль в timeago. Зовётся один раз при старте SDK
/// (см. `MessengerRuntime.init`); идемпотентно при повторном вызове.
void registerTimeagoLocales() {
  timeago.setLocaleMessages('ru', timeago.RuMessages());
  // EN установлена дефолтом самим пакетом.
}
