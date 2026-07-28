/// **Читаемость подсветки в сообщениях** (жалоба: «на мобильных в зоне
/// подсветки плохо читается текст»).
///
/// Корень был системный: подложки строились от цвета ТЕКСТА
/// (`textColor.withValues(alpha: …)`), то есть тянули фон К тексту. Чем
/// плотнее плашка — тем меньше контраста; просьба «уменьшить прозрачность»
/// в лоб сделала бы хуже.
///
/// Здесь контраст проверяется числом (WCAG), а не на глаз: 4.5:1 — порог
/// для обычного текста, 3:1 — для крупного и вторичного.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/theme/highlight_surface.dart';

void main() {
  group('contrastRatio — сама метрика', () {
    test('чёрный на белом — максимум 21:1', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.1));
    });

    test('цвет сам с собой — 1:1', () {
      expect(contrastRatio(Colors.teal, Colors.teal), closeTo(1, 0.001));
    });

    test('симметрична', () {
      final a = contrastRatio(Colors.black, Colors.white);
      final b = contrastRatio(Colors.white, Colors.black);
      expect(a, closeTo(b, 0.0001));
    });
  });

  group('подложка не тянет фон к тексту', () {
    // Ровно та регрессия, из-за которой всё началось: старая формула
    // `textColor.withValues(alpha: X)` в ТЁМНОЙ теме давала светлую
    // плашку под светлым текстом.
    test('тёмная тема: контраст ЛУЧШЕ старой формулы', () {
      const bubble = Color(0xFF1F1F1F);
      const text = Color(0xFFE6E6E6);

      final oldPlate = Color.alphaBlend(
        text.withValues(alpha: 0.12),
        bubble,
      );
      final newPlate = highlightSurface(bubble, Brightness.dark);

      expect(
        contrastRatio(text, newPlate),
        greaterThan(contrastRatio(text, oldPlate)),
        reason: 'плашка должна уходить ОТ цвета текста, а не к нему',
      );
    });

    test('светлая тема: контраст не хуже старой формулы', () {
      const bubble = Color(0xFFEDEDED);
      const text = Color(0xFF1A1A1A);
      final oldPlate = Color.alphaBlend(text.withValues(alpha: 0.12), bubble);
      final newPlate = highlightSurface(bubble, Brightness.light);
      expect(
        contrastRatio(text, newPlate),
        greaterThanOrEqualTo(contrastRatio(text, oldPlate) - 0.2),
      );
    });
  });

  group('пороги читаемости на всех четырёх поверхностях', () {
    // Пузыри из реальной палитры: свой (тонированный) и чужой, обе темы.
    const cases = <(String, Color, Color, Brightness)>[
      ('светлая/чужой', Color(0xFFE7E0EC), Color(0xFF1D1B20), Brightness.light),
      ('светлая/свой', Color(0xFFEADDFF), Color(0xFF21005D), Brightness.light),
      ('тёмная/чужой', Color(0xFF36343B), Color(0xFFE6E0E9), Brightness.dark),
      ('тёмная/свой', Color(0xFF4F378B), Color(0xFFEADDFF), Brightness.dark),
    ];

    for (final (name, bubble, text, brightness) in cases) {
      test('$name: код и найденное — не ниже 4.5:1', () {
        final plate = highlightSurface(bubble, brightness);
        expect(
          contrastRatio(onHighlight(text), plate),
          greaterThanOrEqualTo(4.5),
          reason: 'основной текст на плашке',
        );
      });

      test('$name: цитата — не ниже 4.5:1, вторичная строка не ниже 3:1', () {
        final plate = highlightSurface(
          bubble,
          brightness,
          strength: HighlightStrength.subtle,
        );
        expect(contrastRatio(onHighlight(text), plate), greaterThanOrEqualTo(4.5));
        // Вторичный текст полупрозрачен — накладываем его на плашку,
        // иначе меряли бы несуществующий цвет.
        final secondary = Color.alphaBlend(
          onHighlight(text, secondary: true),
          plate,
        );
        expect(contrastRatio(secondary, plate), greaterThanOrEqualTo(3.0));
      });
    }
  });

  test('подложка непрозрачна: плашку кладут на разные фоны', () {
    // Полупрозрачная подложка поверх неизвестного фона — и есть источник
    // непредсказуемого контраста, от которого уходим.
    final plate = highlightSurface(const Color(0xFF36343B), Brightness.dark);
    expect(plate.a, 1.0);
  });

  test('strong заметнее, чем subtle', () {
    const bubble = Color(0xFFE7E0EC);
    final strong = highlightSurface(bubble, Brightness.light);
    final subtle = highlightSurface(
      bubble,
      Brightness.light,
      strength: HighlightStrength.subtle,
    );
    expect(
      contrastRatio(strong, bubble),
      greaterThan(contrastRatio(subtle, bubble)),
    );
  });
}
