import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// issue #43 — контракт непрозрачной подложки для всплывашек.
///
/// Смысл констант в одном: они должны оставаться НЕПРОЗРАЧНЫМИ. Если
/// кто-нибудь «подгонит под стекло» и уронит alpha, попапы снова начнут
/// просвечивать — а заметить это можно только глазами на девайсе. Тест
/// закрывает именно эту дыру.
void main() {
  group('kOverlaySurface / kOverlaySheetSurface', () {
    test('перекрывают контент под собой (alpha ≥ 0.95)', () {
      expect(kOverlaySurface.a, greaterThanOrEqualTo(0.95));
      expect(kOverlaySheetSurface.a, greaterThanOrEqualTo(0.95));
    });

    test('оттенок общий — обе выведены из kOverlayBaseInk', () {
      expect(kOverlayBaseInk.a, 1.0, reason: 'база должна быть непрозрачной');
      for (final c in [kOverlaySurface, kOverlaySheetSurface]) {
        expect(c.r, kOverlayBaseInk.r);
        expect(c.g, kOverlayBaseInk.g);
        expect(c.b, kOverlayBaseInk.b);
      }
    });

    test('лист чуть прозрачнее попапа — иерархия не перевёрнута', () {
      expect(kOverlaySheetSurface.a, lessThan(kOverlaySurface.a));
    });
  });

  group('Glass-палитры: подложка не совпадает с прозрачными слотами темы', () {
    final glass = <String, ColorScheme>{
      'sunset': ChatistaTheme.glassSunset().colorScheme!,
      'oceanic': ChatistaTheme.glassOceanic().colorScheme!,
      'aurora': ChatistaTheme.glassAurora().colorScheme!,
      'ember': ChatistaTheme.glassEmber().colorScheme!,
    };

    glass.forEach((name, cs) {
      test('$name: surface прозрачный, kOverlaySurface — нет', () {
        // Предпосылка бага: именно из-за этого нуля Material без `color`
        // рисовался без подложки.
        expect(cs.surface.a, 0.0);
        expect(kOverlaySurface.a, greaterThan(0.9));
        expect(kOverlaySurface, isNot(cs.surface));
      });

      test('$name: surfaceContainer* тоже не годятся как фон всплывашки', () {
        // M3 берёт эти слоты для PopupMenu/меню — они полупрозрачные,
        // поэтому «просто взять слот из ColorScheme» проблему не решает.
        expect(cs.surfaceContainer.a, lessThan(0.5));
        expect(cs.surfaceContainerHighest.a, lessThan(0.5));
      });
    });
  });
}
