/// **issue #79 — плашка не должна утонуть в обоях.**
///
/// В стеклянных темах `surface` полностью ПРОЗРАЧЕН: виджет, честно
/// покрашенный в него, показывает сквозь себя цветные пятна обоев, и
/// текст на нём читается как повезёт. На пузырях сообщений это уже
/// ловили; плашка уведомления — тот же случай, только висит она поверх
/// произвольного места экрана, то есть фон под ней вообще любой.
///
/// Поэтому здесь проверяется не «красиво», а измеримое: подложка
/// непрозрачна, и текст на ней проходит порог читаемости.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/theme/highlight_surface.dart';

final _themes = <String, NsgMessengerTheme>{
  'sunset': ChatistaTheme.glassSunset(),
  'oceanic': ChatistaTheme.glassOceanic(),
  'aurora': ChatistaTheme.glassAurora(),
  'ember': ChatistaTheme.glassEmber(),
  'crema (светлая)': ChatistaTheme.crema(),
};

/// Подложка плашки так, как её считает `MessageBannerHost`.
Color _plate(NsgMessengerTheme theme) => inkedSurface(
  highlightSurface(theme.colorScheme!.surface, theme.colorScheme!.brightness),
  theme.bubbleTokens?.bubbleInk,
);

void main() {
  for (final entry in _themes.entries) {
    final name = entry.key;
    final theme = entry.value;
    final plate = _plate(theme);
    final onPlate = theme.colorScheme!.onSurface;

    test('$name: подложка непрозрачна', () {
      // Прозрачная плашка — это не «стильно», а «текст поверх обоев».
      expect(plate.a, 1.0, reason: 'сквозь плашку не должно быть видно обои');
    });

    test('$name: заголовок читается', () {
      expect(
        contrastRatio(onPlate, plate),
        greaterThanOrEqualTo(4.5),
        reason: 'имя чата — главное, что человек читает в плашке',
      );
    });

    test('$name: текст сообщения читается', () {
      // Вторая строка приглушена — но не настолько, чтобы исчезнуть.
      expect(
        contrastRatio(onHighlight(onPlate, secondary: true), plate),
        greaterThanOrEqualTo(3.0),
        reason: 'превью сообщения',
      );
    });
  }

  test('прозрачная тема без чернил всё равно даёт непрозрачную плашку', () {
    // Негативный свидетель: если убрать `highlightSurface`/`inkedSurface`
    // и красить плашку прямо в `surface`, этот тест падает.
    final glass = ChatistaTheme.glassSunset();
    expect(
      glass.colorScheme!.surface.a,
      lessThan(1.0),
      reason: 'иначе тест ничего не проверяет — тема и так непрозрачна',
    );
    expect(_plate(glass).a, 1.0);
  });
}
