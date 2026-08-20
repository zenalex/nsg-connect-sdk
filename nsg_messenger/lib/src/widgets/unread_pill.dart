/// **Пилюля «сколько непрочитано»** (issue #113).
///
/// Тот же значок, что в строке чата, но для списков задач и обращений.
/// Общий виджет, а не копия на экран: две копии разъедутся по размеру и
/// цвету, а стоять они будут в соседних списках одного приложения.
///
/// Ноль не рисуется вовсе — пустой кружок читается как значок, и список
/// прочитанных задач выглядел бы засыпанным метками.
library;

import 'package:flutter/material.dart';

class UnreadPill extends StatelessWidget {
  const UnreadPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        // Тот же порог, что у бейджа строки чата: трёхзначное число ломает
        // ширину хвоста, а точность там уже не нужна.
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Хвост строки списка: непрочитанное + значок стадии.
///
/// Порядок не случаен: непрочитанное стоит ПЕРЕД стадией, потому что оно
/// про «сейчас», и глаз должен цеплять его первым. Стадия отвечает на другой
/// вопрос — «что с задачей», — и без счётчика её приходилось открывать,
/// чтобы узнать, есть ли там новое.
class UnreadThenStage extends StatelessWidget {
  const UnreadThenStage({
    super.key,
    required this.unreadCount,
    required this.stage,
  });

  final int unreadCount;
  final Widget stage;

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) return stage;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UnreadPill(count: unreadCount),
        const SizedBox(width: 8),
        stage,
      ],
    );
  }
}
