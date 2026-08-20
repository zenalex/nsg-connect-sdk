/// **Шторка, которую всегда можно закрыть** (issue #101).
///
/// Жалоба: «Мониторинг → пункт, где много событий. Значок сворачивания
/// залезает под островок — не учитывается safe area. Диалог не закрыть».
///
/// Механика: `isScrollControlled: true` не ограничивает высоту, шторка растёт
/// по содержимому до самого верха, а ручку перетаскивания фреймворк рисует
/// ПОВЕРХ контента — вне `SafeArea`. Дорастя до верха, ручка уходит под
/// вырез, и закрыть нечем: тапнуть мимо шторки тоже некуда.
///
/// Проверяется арифметика: она и решает, останется ли видимой полоска
/// подложки. Без теста это воспроизводится только на конкретном айфоне.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/widgets/nsg_modal_sheet.dart';

void main() {
  group('sheetMaxHeight', () {
    test('оставляет полоску подложки под вырезом', () {
      // iPhone с Dynamic Island: 852 высота, 59 верхняя небезопасная зона.
      final h = sheetMaxHeight(screenHeight: 852, topInset: 59);
      expect(h, 852 - 59 - 24);
      expect(
        h,
        lessThan(852 - 59),
        reason: 'иначе ручка окажется вплотную к острову',
      );
    });

    test('на экране без выреза полоска всё равно остаётся', () {
      // Тап «мимо шторки» — единственный способ закрыть, когда содержимое
      // длиннее экрана; полоска нужна и там, где выреза нет.
      final h = sheetMaxHeight(screenHeight: 800, topInset: 0);
      expect(h, 800 - 24);
      expect(h, lessThan(800));
    });

    test('крошечный экран не даёт отрицательную высоту', () {
      // Складной в сложенном виде, узкое окно на десктопе, клавиатура в
      // ландшафте. Отрицательная высота уронила бы раскладку — пусть лучше
      // шторка залезет выше, чем приложение упадёт.
      final h = sheetMaxHeight(screenHeight: 60, topInset: 59);
      expect(h, greaterThan(0));
      expect(h, 30);
    });

    test('чем больше вырез, тем ниже потолок', () {
      final small = sheetMaxHeight(screenHeight: 852, topInset: 20);
      final big = sheetMaxHeight(screenHeight: 852, topInset: 59);
      expect(big, lessThan(small));
    });
  });

  group('showNsgModalSheet', () {
    testWidgets('шторка не занимает экран целиком — подложка видна', (
      tester,
    ) async {
      // Размер задаём ВСЕМУ окну, а не вложенным MediaQuery: шторка рисуется
      // в оверлее навигатора и вложенную подмену не видит. На этом я сперва
      // и споткнулся — тест «падал» на верном коде.
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 59);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showNsgModalSheet<void>(
                    context: context,
                    // Содержимое заведомо длиннее экрана — ровно случай из
                    // жалобы (длинный список инцидентов).
                    builder: (_) => SingleChildScrollView(
                      key: const Key('sheetContent'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          60,
                          (i) => SizedBox(height: 40, child: Text('строка $i')),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('открыть'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('открыть'));
      await tester.pumpAndSettle();

      final sheet = tester.getRect(find.byKey(const Key('sheetContent')));
      expect(
        sheet.top,
        greaterThan(59),
        reason:
            'верх шторки обязан быть НИЖЕ небезопасной зоны — иначе ручка '
            'уедет под остров и закрыть будет нечем',
      );
    });
  });
}
