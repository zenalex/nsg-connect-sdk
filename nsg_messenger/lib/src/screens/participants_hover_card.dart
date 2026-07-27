/// **issue #63**: список участников группы по наведению мыши на подпись
/// «N участников» в шапке чата.
///
/// Мотив пользователя: увидеть, кто в группе, не уходя с экрана переписки.
/// Раньше состав открывался только отдельным экраном (Настройки группы →
/// Участники) — три перехода ради одного взгляда.
///
/// Только мышь. На тач-платформах наведения не существует, и там способ
/// прежний — тап по шапке; `MouseRegion` там просто никогда не сработает,
/// поэтому отдельного гейта по платформе не делаем.
///
/// **Список в `RoomDetails` обрезан сервером** (`participantsPreviewSize`
/// = 30), а `totalParticipants` — настоящее число. Поэтому в карточке
/// честная строка «и ещё N»: молча показать 30 из 200 хуже, чем не
/// показать ничего — пользователь пересчитает и решит, что список врёт.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../widgets/nsg_bot_badge.dart';

/// Задержка перед закрытием при уходе курсора.
///
/// Без неё карточка захлопывается в момент, когда курсор идёт от подписи
/// К САМОЙ карточке (между ними неизбежный зазор) — доскроллить список
/// становится невозможно.
const kHoverCloseDelay = Duration(milliseconds: 180);

/// Обёртка-якорь: показывает [child], а по наведению — карточку состава.
class ParticipantsHoverCard extends StatefulWidget {
  const ParticipantsHoverCard({
    super.key,
    required this.child,
    required this.participants,
    required this.totalParticipants,
  });

  final Widget child;

  /// Превью состава с сервера (может быть короче [totalParticipants]).
  final List<RoomParticipant> participants;

  /// Настоящее число участников комнаты.
  final int totalParticipants;

  @override
  State<ParticipantsHoverCard> createState() => _ParticipantsHoverCardState();
}

class _ParticipantsHoverCardState extends State<ParticipantsHoverCard> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _open() {
    _closeTimer?.cancel();
    if (!_controller.isShowing) _controller.show();
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(kHoverCloseDelay, () {
      if (mounted && _controller.isShowing) _controller.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) return widget.child;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) => Positioned(
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 6),
            child: MouseRegion(
              // Курсор ушёл с подписи В карточку — она должна остаться:
              // иначе список нельзя прокрутить.
              onEnter: (_) => _open(),
              onExit: (_) => _scheduleClose(),
              child: _ParticipantsCard(
                participants: widget.participants,
                totalParticipants: widget.totalParticipants,
              ),
            ),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => _open(),
          onExit: (_) => _scheduleClose(),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({
    required this.participants,
    required this.totalParticipants,
  });

  final List<RoomParticipant> participants;
  final int totalParticipants;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final hidden = totalParticipants - participants.length;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 220,
          maxWidth: 300,
          maxHeight: 320,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: participants.length,
                itemBuilder: (context, i) {
                  final p = participants[i];
                  final name = (p.displayName ?? '').trim().isNotEmpty
                      ? p.displayName!.trim()
                      : p.matrixUserId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (NsgBotBadge.isNonHuman(p.participantKind)) ...[
                          const SizedBox(width: 6),
                          NsgBotBadge(kind: p.participantKind, compact: true),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (hidden > 0) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.participantsHoverMore(hidden),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
