/// **Редактор фото перед отправкой** (issue #103).
///
/// Жалоба владельца: «вставил с айфона, как отредактировать непонятно» — до
/// этого точки «поправить фото до отправки» в продукте не было вовсе.
///
/// Проверяется арифметика координат: именно из-за неё штрих ложится мимо
/// того места, куда человек ткнул. Ошибка тут не падает и не видна в коде —
/// она видна только получателю сообщения, уже поздно.
///
/// Слой 3-4 добавил стрелку, рамку и подпись. У них своя цена ошибки:
/// инструмент выбирают ОДИН раз, а жест повторяют десятки раз, и если жест
/// уходит не тому инструменту — человек портит фото, а не поправляет его.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nsg_messenger/src/screens/photo_edit_screen.dart';

import '../test_helpers.dart';

Uint8List _png(int w, int h) {
  final im = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      im.setPixelRgb(x, y, x % 256, y % 256, 120);
    }
  }
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  /// Открывает редактор и ждёт декодирования: до него вместо холста висит
  /// индикатор, и жесту уходить некуда.
  ///
  /// `runAsync` тут обязателен. `ui.instantiateImageCodec` работает в движке,
  /// на настоящем времени, а в тесте время поддельное — сколько ни пампуй,
  /// codec не завершится никогда, и холст не появится.
  Future<void> openEditor(WidgetTester tester, {int w = 40, int h = 30}) async {
    await tester.pumpWidget(wrapL10n(PhotoEditScreen(bytes: _png(w, h))));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('photoEditCanvas')),
      findsOneWidget,
      reason: 'картинка не декодировалась — проверять нечего',
    );
  }

  group('fittedImageRect', () {
    test('широкая картинка получает поля сверху и снизу', () {
      // 200x100 в коробке 200x200 → лента по центру, поля по 50.
      final r = fittedImageRect(
        image: const Size(200, 100),
        box: const Size(200, 200),
      );
      expect(r, const Rect.fromLTWH(0, 50, 200, 100));
    });

    test('высокая картинка получает поля слева и справа', () {
      final r = fittedImageRect(
        image: const Size(100, 200),
        box: const Size(200, 200),
      );
      expect(r, const Rect.fromLTWH(50, 0, 100, 200));
    });

    test('вырожденный размер не роняет и не делит на ноль', () {
      // Картинка ещё не декодировалась — размеров нет.
      final r = fittedImageRect(image: Size.zero, box: const Size(200, 200));
      expect(r, const Rect.fromLTWH(0, 0, 200, 200));
    });
  });

  group('toImageSpace', () {
    const image = Size(200, 100);
    const box = Size(200, 200);

    test('центр коробки — центр картинки', () {
      expect(
        toImageSpace(const Offset(100, 100), image: image, box: box),
        const Offset(0.5, 0.5),
      );
    });

    test('угол картинки, а не коробки', () {
      // Верхний левый угол САМОЙ картинки лежит на y=50 из-за полей.
      expect(
        toImageSpace(const Offset(0, 50), image: image, box: box),
        Offset.zero,
      );
    });

    test('касание по полю не рисует', () {
      // Иначе вдоль рамки появлялась бы линия, которую человек не проводил:
      // палец соскользнул с картинки, а штрих продолжился по краю.
      expect(
        toImageSpace(const Offset(100, 10), image: image, box: box),
        isNull,
      );
      expect(
        toImageSpace(const Offset(100, 190), image: image, box: box),
        isNull,
      );
    });

    test('нормировка не зависит от размера коробки', () {
      // Один и тот же жест на телефоне и на десктопе обязан дать одну точку
      // картинки — иначе штрих «переезжает» при повороте экрана.
      final onSmall = toImageSpace(
        const Offset(50, 50),
        image: const Size(100, 100),
        box: const Size(100, 100),
      );
      final onBig = toImageSpace(
        const Offset(200, 200),
        image: const Size(100, 100),
        box: const Size(400, 400),
      );
      expect(onSmall, onBig);
    });
  });

  group('PhotoEditScreen', () {
    testWidgets('открывается: кисть, отмена и переключение в обрезку', (
      tester,
    ) async {
      await tester.pumpWidget(wrapL10n(PhotoEditScreen(bytes: _png(40, 30))));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('photoEditDone')), findsOneWidget);
      expect(find.byKey(const Key('photoEditUndo')), findsOneWidget);
      expect(find.byKey(const Key('photoEditModeToggle')), findsOneWidget);
    });

    testWidgets('отмена штриха выключена, пока рисовать нечего', (
      tester,
    ) async {
      // Активная кнопка, которая ничего не делает, — это обещание, которое
      // интерфейс не выполняет.
      await tester.pumpWidget(wrapL10n(PhotoEditScreen(bytes: _png(40, 30))));
      await tester.pump();
      await tester.pump();

      final undo = tester.widget<IconButton>(
        find.byKey(const Key('photoEditUndo')),
      );
      expect(undo.onPressed, isNull);
    });

    testWidgets('уход без правок возвращает null', (tester) async {
      EditedPhoto? result;
      var done = false;
      await tester.pumpWidget(
        wrapL10n(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showPhotoEditor(context, bytes: _png(40, 30));
                done = true;
              },
              child: const Text('открыть'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('открыть'));
      // Не pumpAndSettle: пока картинка декодируется, крутится индикатор
      // прогресса, и «успокоиться» экран не может по построению.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(done, isTrue);
      expect(result, isNull);
    });

    testWidgets('инструмент переключается и виден выбранный', (tester) async {
      await openEditor(tester);

      Color? colorOf(PhotoTool t) => tester
          .widget<IconButton>(find.byKey(Key('photoEditTool_${t.name}')))
          .color;

      // Кисть — умолчание: чаще всего надо просто обвести место.
      expect(colorOf(PhotoTool.brush), Colors.white);
      expect(colorOf(PhotoTool.arrow), Colors.white38);

      await tester.tap(find.byKey(const Key('photoEditTool_arrow')));
      await tester.pump();

      expect(colorOf(PhotoTool.arrow), Colors.white);
      expect(colorOf(PhotoTool.brush), Colors.white38);
    });

    testWidgets('стрелка рисуется протяжкой и отменяется', (tester) async {
      await openEditor(tester, w: 40, h: 40);

      await tester.tap(find.byKey(const Key('photoEditTool_arrow')));
      await tester.pump();

      await tester.timedDrag(
        find.byKey(const Key('photoEditCanvas')),
        const Offset(40, 40),
        const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('photoEditUndo')))
            .onPressed,
        isNotNull,
        reason: 'протяжка дала пометку',
      );

      await tester.tap(find.byKey(const Key('photoEditUndo')));
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('photoEditUndo')))
            .onPressed,
        isNull,
        reason: 'отмена снимает пометку любого вида, не только штрих',
      );
    });

    testWidgets('подпись ставится тапом и спрашивает текст', (tester) async {
      await openEditor(tester, w: 40, h: 40);

      await tester.tap(find.byKey(const Key('photoEditTool_text')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('photoEditCanvas')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('photoEditTextField')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('photoEditTextField')),
        'сюда',
      );
      await tester.tap(find.byKey(const Key('photoEditTextOk')));
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('photoEditUndo')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('пустая подпись не оставляет пометки', (tester) async {
      // Иначе на фото появляется невидимая пометка: человек её не видит, но
      // отменять ему потом придётся вслепую.
      await openEditor(tester, w: 40, h: 40);

      await tester.tap(find.byKey(const Key('photoEditTool_text')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('photoEditCanvas')));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('photoEditTextOk')));
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('photoEditUndo')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('текстовым инструментом протяжка не рисует линию', (
      tester,
    ) async {
      // Палец на фото дрожит, и тап нередко приезжает как микро-протяжка.
      // Рисуй она кистью — каждая подпись сопровождалась бы закорючкой.
      await openEditor(tester, w: 40, h: 40);

      await tester.tap(find.byKey(const Key('photoEditTool_text')));
      await tester.pump();

      await tester.timedDrag(
        find.byKey(const Key('photoEditCanvas')),
        const Offset(30, 30),
        const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(find.byKey(const Key('photoEditTextField')), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('photoEditUndo')))
            .onPressed,
        isNull,
      );
    });
  });

  group('flattenAnnotations', () {
    /// Цвет пикселя сведённой картинки.
    Future<img.Pixel> pixelAt(Uint8List png, int x, int y) async {
      final decoded = img.decodePng(png)!;
      return decoded.getPixel(x, y);
    }

    /// Однотонная картинка: на ней видно ЛЮБУЮ пометку.
    Uint8List plain(int w, int h) {
      final im = img.Image(width: w, height: h);
      img.fill(im, color: img.ColorRgb8(0, 0, 0));
      return Uint8List.fromList(img.encodePng(im));
    }

    Future<ui.Image> decode(Uint8List bytes) async {
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    }

    testWidgets('пометка попадает в пиксели, а не только на экран', (
      tester,
    ) async {
      // Самая дорогая ошибка редактора: человек видит стрелку, отправляет —
      // а получателю приходит чистое фото. Ловится только по пикселям.
      late Uint8List out;
      await tester.runAsync(() async {
        final image = await decode(plain(100, 100));
        out = await flattenAnnotations(
          image: image,
          annotations: [
            const BrushStroke(
              points: [Offset(0.1, 0.5), Offset(0.9, 0.5)],
              color: Color(0xFFFF0000),
              width: 0.1,
            ),
          ],
        );
      });

      final onLine = await pixelAt(out, 50, 50);
      final offLine = await pixelAt(out, 50, 5);
      expect(onLine.r, greaterThan(200), reason: 'по штриху лежит красное');
      expect(offLine.r, lessThan(50), reason: 'мимо штриха фон не тронут');
    });

    testWidgets('координаты пометки не переворачиваются на неквадратной', (
      tester,
    ) async {
      // Нормировка 0..1 умножается на ширину и высоту раздельно; перепутать
      // их местами на квадратной картинке невозможно, на любой другой —
      // запросто, и пометка уезжает в другой конец фото.
      late Uint8List out;
      await tester.runAsync(() async {
        final image = await decode(plain(200, 50));
        out = await flattenAnnotations(
          image: image,
          annotations: [
            const ShapeAnnotation(
              kind: ShapeKind.rect,
              from: Offset(0.05, 0.2),
              to: Offset(0.25, 0.8),
              color: Color(0xFF00FF00),
              width: 0.08,
            ),
          ],
        );
      });

      // Рамка нарисована в левой четверти — там зелёное есть.
      var greenLeft = false;
      var greenRight = false;
      for (var x = 0; x < 200; x++) {
        for (var y = 0; y < 50; y++) {
          final px = await pixelAt(out, x, y);
          if (px.g > 200) {
            if (x < 60) greenLeft = true;
            if (x > 140) greenRight = true;
          }
        }
      }
      expect(greenLeft, isTrue);
      expect(greenRight, isFalse, reason: 'рамка не расползлась по ширине');
    });

    testWidgets('подпись оставляет след', (tester) async {
      // TextPainter молча рисует пустоту, если шрифт не нашёлся или размер
      // сосчитан нулём, — а исключения при этом нет.
      late Uint8List out;
      await tester.runAsync(() async {
        final image = await decode(plain(120, 120));
        out = await flattenAnnotations(
          image: image,
          annotations: [
            const TextAnnotation(
              text: 'X',
              at: Offset(0.3, 0.3),
              color: Color(0xFFFFFFFF),
              size: 0.3,
            ),
          ],
        );
      });

      final decoded = img.decodePng(out)!;
      var lit = 0;
      for (var x = 0; x < 120; x++) {
        for (var y = 0; y < 120; y++) {
          if (decoded.getPixel(x, y).r > 128) lit++;
        }
      }
      expect(lit, greaterThan(0), reason: 'буква не нарисовалась вовсе');
    });

    testWidgets('без пометок картинка остаётся собой', (tester) async {
      // Неквадратная и двухцветная нарочно: на однотонном квадрате этот тест
      // прошёл бы и при перепутанных сторонах, и при потерянной подложке.
      final source = img.Image(width: 80, height: 40);
      img.fill(source, color: img.ColorRgb8(255, 0, 0));
      img.fillRect(
        source,
        x1: 40,
        y1: 0,
        x2: 79,
        y2: 39,
        color: img.ColorRgb8(0, 0, 255),
      );

      late Uint8List out;
      await tester.runAsync(() async {
        final image = await decode(Uint8List.fromList(img.encodePng(source)));
        out = await flattenAnnotations(image: image, annotations: const []);
      });

      final decoded = img.decodePng(out)!;
      expect(decoded.width, 80);
      expect(decoded.height, 40);
      expect(decoded.getPixel(10, 20).r, greaterThan(200));
      expect(decoded.getPixel(70, 20).b, greaterThan(200));
    });
  });

  group('arrowHead', () {
    test('наконечник сидит у острия, а не у хвоста', () {
      final h = arrowHead(from: Offset.zero, to: const Offset(1, 0), size: 0.2);

      expect(h, hasLength(2));
      for (final p in h) {
        expect(
          (p - const Offset(1, 0)).distance,
          closeTo(0.2, 1e-9),
          reason: 'обе стороны наконечника длиной size от острия',
        );
        expect(p.dx, lessThan(1), reason: 'смотрят назад вдоль стрелки');
      }
      expect(h[0].dy, closeTo(-h[1].dy, 1e-9), reason: 'симметрично оси');
    });

    test('наконечник поворачивается вместе со стрелкой', () {
      // Иначе стрелка вниз рисовалась бы с горизонтальным оперением.
      final right = arrowHead(
        from: Offset.zero,
        to: const Offset(1, 0),
        size: 0.2,
      );
      final down = arrowHead(
        from: Offset.zero,
        to: const Offset(0, 1),
        size: 0.2,
      );

      // Поворот на 90°: (x, y) → (-y, x), с переносом острия (1,0) → (0,1).
      for (var i = 0; i < 2; i++) {
        expect(down[i].dx, closeTo(-right[i].dy, 1e-9));
        expect(down[i].dy - 1, closeTo(right[i].dx - 1, 1e-9));
      }
    });

    test('у короткой стрелки наконечник не длиннее её самой', () {
      // Иначе оперение вылезает за начало протяжки и выглядит кляксой.
      final h = arrowHead(
        from: Offset.zero,
        to: const Offset(0.05, 0),
        size: 0.2,
      );

      for (final p in h) {
        expect((p - const Offset(0.05, 0)).distance, closeTo(0.05, 1e-9));
      }
    });

    test('протяжка в точку наконечника не даёт', () {
      // Направления нет: угол вычислять не по чему, рисовать нечего.
      expect(arrowHead(from: Offset.zero, to: Offset.zero, size: 0.2), isEmpty);
    });
  });
}
