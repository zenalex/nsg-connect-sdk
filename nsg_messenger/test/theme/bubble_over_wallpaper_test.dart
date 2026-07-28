/// **Читаемость сообщений поверх обоев.**
///
/// Жалоба: «подложка неравномерная, есть яркие зоны — вот там контраст
/// явно недостаточен. А это к тому же низ экрана, где как раз последние
/// сообщения».
///
/// Причина: в glass-темах пузырь полупрозрачный (свой — акцент под 33%,
/// чужой — белый под 18%) и лежит прямо на обоях. Над тёмной частью обоев
/// всё читалось, над светлым пятном — нет. Правка одной альфы тут не
/// помогает: контраст зависел от того, ЧТО оказалось под сообщением.
///
/// Поэтому проверяем главное свойство: после наложения на опорный тон
/// палитры пузырь непрозрачен, и контраст с текстом одинаков над любым
/// пятном обоев — включая самые светлые.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/theme/chatista_theme.dart';
import 'package:nsg_messenger/src/theme/highlight_surface.dart';
import 'package:nsg_messenger/src/theme/nsg_messenger_theme.dart';

/// Самые светлые пятна каждой палитры (`GlassBackground`, blend screen —
/// на пересечениях бывает и светлее, поэтому берём чистый белый как
/// заведомо худший случай).
const _brightSpots = <String, List<Color>>{
  'sunset': [Color(0xFFF0CFA0), Color(0xFFE89A55), Color(0xFFD45A78)],
  'oceanic': [Color(0xFFA8E0D0), Color(0xFF5BB8A8), Color(0xFF4A7FB8)],
  'aurora': [Color(0xFF5BD8A6), Color(0xFFA65BD8)],
  'ember': [Color(0xFFE0682E)],
};

void main() {
  _dateChipTests();
  final themes = <String, NsgMessengerTheme>{
    'sunset': ChatistaTheme.glassSunset(),
    'oceanic': ChatistaTheme.glassOceanic(),
    'aurora': ChatistaTheme.glassAurora(),
    'ember': ChatistaTheme.glassEmber(),
  };

  /// Итоговый цвет пузыря так, как его считает `MessageBubble`.
  Color bubble(NsgMessengerTheme theme, {required bool own}) {
    final scheme = theme.colorScheme!;
    final raw = own
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final ink = theme.bubbleTokens?.bubbleInk;
    return ink == null ? raw : Color.alphaBlend(raw, ink);
  }

  for (final entry in themes.entries) {
    final name = entry.key;
    final theme = entry.value;

    test('$name: пузырь непрозрачен — обои под ним ни на что не влияют', () {
      for (final own in [true, false]) {
        expect(
          bubble(theme, own: own).a,
          1.0,
          reason: 'own=$own: полупрозрачный пузырь пускает обои в контраст',
        );
      }
    });

    test('$name: текст читается над САМЫМИ СВЕТЛЫМИ пятнами обоев', () {
      final spots = [..._brightSpots[name]!, Colors.white];
      for (final own in [true, false]) {
        final b = bubble(theme, own: own);
        final scheme = theme.colorScheme!;
        final text = own ? scheme.onPrimaryContainer : scheme.onSurface;
        for (final spot in spots) {
          // Пузырь непрозрачен → пятно под ним не участвует; проверяем
          // это буквально, композитя пузырь поверх пятна.
          final effective = Color.alphaBlend(b, spot);
          expect(
            contrastRatio(text, effective),
            greaterThanOrEqualTo(4.5),
            reason: '$name own=$own над пятном '
                '#${spot.toARGB32().toRadixString(16)}',
          );
        }
      }
    });

    test('$name: прежняя (полупрозрачная) схема над светлым пятном '
        'порога НЕ добирала', () {
      // Фиксируем суть регрессии: без наложения на опорный тон контраст
      // над светлым пятном падал ниже порога — то есть чинить надо было
      // не альфу, а зависимость от фона.
      final raw = theme.colorScheme!.surfaceContainerHighest;
      final text = theme.colorScheme!.onSurface;
      final bright = _brightSpots[name]!.first;
      final old = Color.alphaBlend(raw, bright);
      expect(contrastRatio(text, old), lessThan(4.5));
    });
  }
}

/// Плашка даты — единственный текст, лежащий ПРЯМО НА ОБОЯХ.
///
/// Тень (предложение Энди) читаемость поднимает, но померить её нельзя,
/// поэтому порог держим фоном плашки: контраст обязан проходить и БЕЗ
/// тени, а тень остаётся запасом прочности.
void _dateChipTests() {
  const chipVeil = Color(0xA6000000); // black @ 0.65
  const chipText = Color(0xF2FFFFFF);

  test('плашка даты читается над самым светлым пятном обоев', () {
    for (final spot in [
      const Color(0xFFF0CFA0),
      const Color(0xFFA8E0D0),
      const Color(0xFF5BD8A6),
      Colors.white,
    ]) {
      final chip = Color.alphaBlend(chipVeil, spot);
      final text = Color.alphaBlend(chipText, chip);
      expect(
        contrastRatio(text, chip),
        greaterThanOrEqualTo(4.5),
        reason: 'над пятном #${spot.toARGB32().toRadixString(16)}',
      );
    }
  });

  test('прежняя плашка (28%) над светлым пятном порога НЕ добирала', () {
    const old = Color(0x47000000); // black @ 0.28
    final chip = Color.alphaBlend(old, const Color(0xFFF0CFA0));
    final text = Color.alphaBlend(chipText, chip);
    expect(contrastRatio(text, chip), lessThan(4.5));
  });
}
