import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show ParticipantKind;

import '../i18n/generated/nsg_l10n.dart';

/// **TASK77 довесок A**: явная маркировка «этот собеседник — программа».
///
/// Анти-имперсонация: пользователь всегда должен видеть, что говорит с ботом,
/// а не с человеком — поэтому плашка не отключается настройкой и рисуется на
/// ВСЕХ поверхностях, где встречается имя бота (сообщения, список участников,
/// шапка чата, список чатов).
///
/// Единый виджет, а не копия разметки в каждом экране: раньше плашка
/// существовала только в пузыре сообщения ([MessageBubble]), и любое
/// расхождение стилей на новой поверхности читалось бы как разные сущности.
///
/// [kind] — `RoomParticipant.participantKind` / `RoomSummary.directPeerKind`.
/// Ботом считаем не только `bot`, но и `integration`/`aiAgent`: для
/// пользователя это всё «не человек», а различие между ними — наша внутренняя
/// таксономия. `system` (@nsg-system) НЕ помечаем — служебные сообщения
/// платформы рисуются своим стилем, а не как реплика собеседника; трактовка
/// совпадает с `MessageBubble._senderIsBot`, чтобы поверхности не расходились.
/// `null` (обычный пользователь или старый сервер без поля) → ничего не
/// рисуем.
class NsgBotBadge extends StatelessWidget {
  const NsgBotBadge({super.key, required this.kind, this.compact = false});

  final ParticipantKind? kind;

  /// `true` — только иконка робота, без текстовой плашки: для тесных строк
  /// (список чатов), где имя и превью уже борются за место.
  final bool compact;

  /// Является ли [kind] «не человеком» — общая точка решения, чтобы
  /// поверхности не размножали свои варианты этой проверки.
  static bool isNonHuman(ParticipantKind? kind) =>
      kind == ParticipantKind.bot ||
      kind == ParticipantKind.integration ||
      kind == ParticipantKind.aiAgent;

  @override
  Widget build(BuildContext context) {
    if (!isNonHuman(kind)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // Цвет — вторичный акцент темы: плашка должна читаться, но не спорить с
    // именем собеседника (она уточнение, а не главный элемент строки).
    final color = theme.colorScheme.primary;
    final icon = Icon(Icons.smart_toy_outlined, size: 13, color: color);
    if (compact) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              // Тот же l10n-ключ, что в экране команды поддержки и в пузыре:
              // одно слово для одного смысла на всех поверхностях.
              NsgL10n.of(context).supportTeamBotBadge,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
