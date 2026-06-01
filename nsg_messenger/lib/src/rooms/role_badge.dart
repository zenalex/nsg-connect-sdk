import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart' show RoomMemberRole;

import '../i18n/generated/nsg_l10n.dart';

/// **TASK29 Chunk 2**: small role badge для display рядом с participant
/// именем — owner crown / admin shield / member nothing.
///
/// Single source of truth — переиспользуется в:
///   * `ParticipantsScreen` participant tile (rightmost trailing).
///   * (optional Phase2) `MessageBubble` sender row (compact inline).
///
/// `member` — `SizedBox.shrink()` (no widget) — UI hides badge для
/// regular users; convention визуальной discoverability — admin/owner
/// специально выделены.
///
/// Theme integration: tint accent через `Theme.of(context).colorScheme.
/// primary` per TASK22 white-label strategy. Tooltip — i18n EN/RU.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.size = 16});

  final RoomMemberRole role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    switch (role) {
      case RoomMemberRole.owner:
        return Tooltip(
          message: l.roleBadgeOwner,
          child: Icon(
            Icons.workspace_premium,
            size: size,
            color: accent,
            semanticLabel: l.roleBadgeOwner,
          ),
        );
      case RoomMemberRole.admin:
        return Tooltip(
          message: l.roleBadgeAdmin,
          child: Icon(
            Icons.shield_outlined,
            size: size,
            color: accent,
            semanticLabel: l.roleBadgeAdmin,
          ),
        );
      case RoomMemberRole.member:
        return const SizedBox.shrink();
    }
  }
}
