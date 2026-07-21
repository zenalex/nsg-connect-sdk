import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/widgets/glass_background.dart';

/// **issue #26 (Android-лаги).** Фон приложения — самая дорогая вещь в
/// растеризации: полноэкранный `saveLayer` + 4 радиальных градиента с
/// `BlendMode.screen`, и лежит он под ВСЕМ приложением.
///
/// Замер на HONOR VNE-LX1 (Android 14, PowerVR GE8320): с фоном raster
/// 113.8 мс на кадр (8–9 fps), без фона — 5.35 мс (60 fps). На фон
/// приходилось 77–95% стоимости растеризации.
///
/// Фикс — изоляция фона в собственный слой (`RepaintBoundary`), чтобы GPU
/// растеризовал его один раз, а не заново на каждый кадр скролла. Тест
/// сторожит именно это: правка невидимая, потерять её при рефакторинге
/// легко, а цена потери — возврат к 8 fps на слабых устройствах.
void main() {
  testWidgets('фон изолирован в собственный слой (RepaintBoundary)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(children: [Positioned.fill(child: GlassBackground())]),
      ),
    );

    final boundary = find.descendant(
      of: find.byType(GlassBackground),
      matching: find.byType(RepaintBoundary),
    );
    expect(
      boundary,
      findsWidgets,
      reason:
          'без RepaintBoundary фон перерастеризуется каждый кадр — '
          'issue #26, падение до 8 fps на слабом Android',
    );
  });

  testWidgets('смена палитры перерисовывает фон (слой не залипает)', (
    tester,
  ) async {
    // С кэширующим слоем промах shouldRepaint означал бы «тема не сменилась».
    await tester.pumpWidget(
      const MaterialApp(home: GlassBackground(palette: GlassPalette.sunset)),
    );
    final before = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(GlassBackground),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    await tester.pumpWidget(
      const MaterialApp(home: GlassBackground(palette: GlassPalette.oceanic)),
    );
    final after = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(GlassBackground),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    expect(
      after.painter!.shouldRepaint(before.painter!),
      isTrue,
      reason: 'смена палитры обязана инвалидировать кэшированный слой',
    );
  });

  testWidgets('та же палитра — перерисовки НЕТ (иначе кэш бесполезен)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GlassBackground(palette: GlassPalette.sunset)),
    );
    final first = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(GlassBackground),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    await tester.pumpWidget(
      const MaterialApp(home: GlassBackground(palette: GlassPalette.sunset)),
    );
    final second = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(GlassBackground),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    expect(second.painter!.shouldRepaint(first.painter!), isFalse);
  });
}
