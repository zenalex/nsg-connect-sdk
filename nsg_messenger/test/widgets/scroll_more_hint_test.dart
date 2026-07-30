/// **issue #74**: «нужно показывать внизу стрелочку, если всё меню не
/// показано сразу, т.к. если не знать, то не догадаешься о том, что можно
/// прокрутить меню».
///
/// Главное свойство подсказки — честность: она обязана появляться, когда
/// снизу есть что показать, и исчезать, когда нет. Постоянная стрелка
/// обманывала бы в другую сторону и была бы не лучше её отсутствия.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/widgets/scroll_more_hint.dart';

void main() {
  Finder arrow() => find.byIcon(Icons.keyboard_arrow_down);

  /// Виден ли индикатор человеку: он всегда в дереве, но при «докрутили»
  /// прозрачен — проверяем именно непрозрачность.
  bool arrowVisible(WidgetTester tester) {
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(of: arrow(), matching: find.byType(AnimatedOpacity)),
    );
    return opacity.opacity > 0;
  }

  Future<void> pumpList(
    WidgetTester tester, {
    required int items,
    double viewport = 200,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: viewport,
              child: ScrollMoreHint(
                builder: (context, controller) => SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [
                      for (var i = 0; i < items; i++)
                        SizedBox(height: 50, child: Text('пункт $i')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('содержимое не помещается → подсказка видна', (tester) async {
    await pumpList(tester, items: 10);
    expect(arrowVisible(tester), isTrue);
  });

  testWidgets('всё влезло → подсказки нет', (tester) async {
    // Иначе стрелка обещала бы то, чего нет.
    await pumpList(tester, items: 2);
    expect(arrowVisible(tester), isFalse);
  });

  testWidgets('докрутили до конца → подсказка исчезает', (tester) async {
    await pumpList(tester, items: 10);
    expect(arrowVisible(tester), isTrue);
    await tester.drag(find.text('пункт 1'), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(arrowVisible(tester), isFalse);
  });

  testWidgets('прокрутили назад → подсказка возвращается', (tester) async {
    await pumpList(tester, items: 10);
    await tester.drag(find.text('пункт 1'), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.drag(find.text('пункт 9'), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(arrowVisible(tester), isTrue);
  });

  testWidgets('тап по подсказке прокручивает', (tester) async {
    // Человек, который её заметил, скорее всего именно этого и хочет.
    await pumpList(tester, items: 10);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.pixels, 0);
    await tester.tap(arrow());
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0), reason: 'список уехал вниз');
  });

  testWidgets('пока подсказки нет, она не перехватывает нажатия', (
    tester,
  ) async {
    // Прозрачный слой поверх последнего пункта съедал бы тапы по нему.
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              child: ScrollMoreHint(
                builder: (context, controller) => SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 60,
                        child: TextButton(
                          onPressed: () => tapped = true,
                          child: const Text('последний пункт'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('последний пункт'));
    expect(tapped, isTrue);
  });
}
