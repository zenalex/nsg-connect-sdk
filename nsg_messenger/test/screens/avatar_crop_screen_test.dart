/// **Обрезка аватара** (issue #102).
///
/// Запрос владельца: «при работе с аватарами хотелось бы стандартный
/// мини-редактор иметь (обрезки, положения, что там обычно)». До этого
/// картинка уходила на сервер как есть и обрезалась по центру автоматически.
///
/// Проверяется то, что ломается молча: определение типа по содержимому
/// (соврать здесь — получить отказ загрузки на ровном месте) и то, что отказ
/// в редакторе ничего не загружает.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nsg_messenger/src/screens/avatar_crop_screen.dart';

import '../test_helpers.dart';

Uint8List _png() {
  final im = img.Image(width: 8, height: 8);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      im.setPixelRgb(x, y, x * 30, y * 30, 100);
    }
  }
  return Uint8List.fromList(img.encodePng(im));
}

Uint8List _jpeg() {
  final im = img.Image(width: 8, height: 8);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      im.setPixelRgb(x, y, x * 30, y * 30, 100);
    }
  }
  return Uint8List.fromList(img.encodeJpg(im));
}

void main() {
  group('mimeOfImageBytes', () {
    // Тип берётся по СОДЕРЖИМОМУ, а не по имени файла: имя врёт дважды —
    // пикер отдаёт временный файл со своим расширением, а поворот в
    // редакторе перекодирует кадр в PNG независимо от исходного формата.
    // Сервер по типу выбирает и лимит размера, и ветку обработки.

    test('PNG узнаётся', () {
      expect(mimeOfImageBytes(_png()), 'image/png');
    });

    test('JPEG узнаётся и НЕ выдаётся за PNG', () {
      // crop_your_image сохраняет входной формат (jpeg→jpeg), так что
      // жёстко зашитый 'image/png' был бы враньём.
      expect(mimeOfImageBytes(_jpeg()), 'image/jpeg');
    });

    test('мусор не роняет, а даёт png', () {
      // Битый файл человек вправе выбрать. Падать на определении типа —
      // худшее, что можно сделать: загрузка ещё даже не началась.
      expect(mimeOfImageBytes(Uint8List.fromList([1, 2, 3, 4])), 'image/png');
    });
  });

  group('AvatarCropScreen', () {
    testWidgets('открывается и показывает кнопки обрезки и поворота', (
      tester,
    ) async {
      await tester.pumpWidget(wrapL10n(AvatarCropScreen(bytes: _png())));
      await tester.pump();

      expect(find.byKey(const Key('avatarCropDone')), findsOneWidget);
      expect(find.byKey(const Key('avatarCropRotate')), findsOneWidget);
    });

    testWidgets('отказ возвращает null — грузить нечего', (tester) async {
      // Иначе «передумал» превращается в загруженный аватар.
      CroppedAvatar? result;
      var popped = false;

      await tester.pumpWidget(
        wrapL10n(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showAvatarCropper(context, bytes: _png());
                popped = true;
              },
              child: const Text('открыть'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('открыть'));
      await tester.pumpAndSettle();

      // Уходим назад, как по системной кнопке «назад».
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pop();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(result, isNull);
    });
  });
}
