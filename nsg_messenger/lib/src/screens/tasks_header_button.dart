import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart' show RoomTaskStats;

import '../i18n/generated/nsg_l10n.dart';

/// **TASK88**: иконка задач в шапке комнаты. Видна ТОЛЬКО когда у комнаты есть
/// задачи ([RoomTaskStats.total] > 0); при активных ([RoomTaskStats.active] > 0)
/// — бейдж с числом активных (стиль как unread). Тап → список задач комнаты.
///
/// [stats] == null (ещё не загрузились / best-effort сбой) → ничего не рисуем
/// (иконки нет, а не пустой список по тапу — см. DoD TASK88). Вынесен из
/// `ChatScreen` отдельным виджетом ради изолированного widget-теста.
class TasksHeaderButton extends StatelessWidget {
  const TasksHeaderButton({super.key, required this.stats, required this.onTap});

  /// Сводка по задачам комнаты (`active`/`total`). null → иконки нет.
  final RoomTaskStats? stats;

  /// Тап по иконке → открыть отфильтрованный по комнате список задач.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    // Нет данных / нет задач → иконки нет (не пустой список по тапу).
    if (s == null || s.total <= 0) return const SizedBox.shrink();
    final l = NsgL10n.of(context);
    final active = s.active;
    return IconButton(
      key: const Key('roomTasksButton'),
      tooltip: l.tasksScreenTitle,
      onPressed: onTap,
      icon: Badge(
        // Бейдж с числом только при активных задачах; иначе просто иконка.
        isLabelVisible: active > 0,
        label: Text('$active', key: const Key('roomTasksBadge')),
        child: const Icon(Icons.checklist),
      ),
    );
  }
}
