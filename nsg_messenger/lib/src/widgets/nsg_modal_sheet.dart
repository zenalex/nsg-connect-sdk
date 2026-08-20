/// **Модальная шторка, которую всегда можно закрыть** (issue #101).
///
/// Жалоба: «Мониторинг → выбираю пункт, где много событий. Значок сворачивания
/// залезает под островок — не учитывается safe area. Диалог не закрыть».
///
/// Механика такая. `showModalBottomSheet(isScrollControlled: true)` не
/// ограничивает высоту: шторка растёт по содержимому и при длинном списке
/// доходит до самого верха экрана. Ручку перетаскивания (`showDragHandle`)
/// рисует сам фреймворк ПОВЕРХ содержимого — то есть вне `SafeArea`, которым
/// обёрнут только контент. Дорастя до верха, ручка оказывается под вырезом или
/// островом, и человек остаётся без обоих штатных способов закрыть: по ручке
/// не попасть, а тапнуть «мимо шторки» некуда — она заняла весь экран.
///
/// **Это не дефект Pulse.** На 08.08.2026 в SDK 29 вызовов
/// `showModalBottomSheet`, и высоту не ограничивает НИ ОДИН — в Pulse просто
/// заметили первыми, потому что там список инцидентов длинный. Поэтому
/// лечение общее: помощник, оставляющий полоску сверху.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Сколько экрана шторке отдавать НЕЛЬЗЯ.
///
/// Возвращает максимальную высоту: экран минус верхняя небезопасная зона
/// (статус-бар, вырез, остров) минус [gap] — видимая полоска подложки.
///
/// Полоска нужна не для красоты: это единственная область, тапом по которой
/// шторка закрывается, когда содержимое длиннее экрана. Без неё остаётся
/// только ручка, а она как раз и уезжает под остров.
///
/// Чистая функция: вся арифметика тут, и проверять её надо без устройства с
/// вырезом — иначе баг воспроизводится только на конкретном айфоне.
double sheetMaxHeight({
  required double screenHeight,
  required double topInset,
  double gap = 24,
}) {
  final available = screenHeight - topInset - gap;
  // Экран может быть крошечным (складной в сложенном виде, окно на десктопе,
  // клавиатура в ландшафте). Отдать отрицательную высоту — уронить раскладку,
  // поэтому не опускаемся ниже половины экрана: пусть лучше шторка залезет
  // выше, чем приложение упадёт.
  return math.max(available, screenHeight / 2);
}

/// Модальная шторка с гарантированно достижимой ручкой.
///
/// Обёртка над `showModalBottomSheet` с единственным отличием — ограничением
/// высоты. Всё остальное намеренно как у оригинала: подменять поведение
/// фреймворка целиком мы не хотим, нам нужна одна конкретная гарантия.
Future<T?> showNsgModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,

  /// Сквозной: `null` — как решит тема, ровно как у самого
  /// `showModalBottomSheet`. Своего умолчания не навязываем — иначе перевод
  /// существующего вызова на помощник молча дорисовал бы ему ручку.
  bool? showDragHandle,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  double gap = 24,
}) {
  final media = MediaQuery.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: showDragHandle,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    shape: shape,
    constraints: BoxConstraints(
      maxHeight: sheetMaxHeight(
        screenHeight: media.size.height,
        topInset: media.padding.top,
        gap: gap,
      ),
    ),
    builder: builder,
  );
}
