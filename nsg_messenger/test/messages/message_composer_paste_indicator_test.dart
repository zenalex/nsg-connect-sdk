import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

/// **Issue #54 п.3** — индикация чтения буфера при Ctrl+V.
///
/// До фикса между нажатием и появлением миниатюры не рисовалось ничего
/// («просто некоторое время висим»). Теперь показывается тот же спиннер,
/// что и на upload-е, — но с задержкой, чтобы не мигать, когда в буфере
/// не картинка и чтение возвращается мгновенно.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('pasteboard');

  /// Настоящий 1x1 PNG — чтобы миниатюра в черновике реально декодилась,
  /// а не падала в error-builder.
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmM'
    'IQAAAABJRU5ErkJggg==',
  );

  /// Подменяет нативный `pasteboard`: [image] — что вернуть на
  /// `image`-вызов, [delay] — насколько «задумается» платформа.
  ///
  /// Контракт канала платформозависим: на Windows плагин ждёт ПУТЬ
  /// к временному файлу (и сам его удаляет после чтения), на остальных —
  /// сами байты. Поэтому мок подстраивается под хост, иначе тест
  /// проходил бы только на части машин.
  void mockPasteboard({Uint8List? image, Duration delay = Duration.zero}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'image') return null;
          if (delay > Duration.zero) await Future<void>.delayed(delay);
          if (image == null) return null;
          if (!Platform.isWindows) return image;
          final f = File(
            '${Directory.systemTemp.path}/nsg_paste_test_'
            '${DateTime.now().microsecondsSinceEpoch}.png',
          );
          await f.writeAsBytes(image);
          return f.path;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget composer({
    Future<void> Function(PickedAttachment)? onSendAttachment,
  }) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        onSend: (b, {mentionedMessengerUserIds, albumId}) async {},
        onSendAttachment: (p, {albumId}) async =>
            onSendAttachment?.call(p) ?? Future<void>.value(),
      ),
    ),
  );

  /// Дождаться конца вставки: чередует управляемое время (задержка
  /// method-канала, таймер индикации) и реальное (дисковое I/O плагина
  /// на Windows). Один вид времени по отдельности флоу не дотягивает.
  Future<void> settlePaste(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    await tester.pump();
  }

  /// Ctrl+V по сфокусированному полю ввода.
  Future<void> pressCtrlV(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  // Спиннер именно НА КНОПКЕ-СКРЕПКЕ: миниатюра в ленте черновика может
  // рисовать свой индикатор, пока декодится картинка, — он к индикации
  // вставки отношения не имеет.
  final spinner = find.descendant(
    of: find.byType(IconButton),
    matching: find.byType(CircularProgressIndicator),
  );

  testWidgets('долгое чтение буфера показывает спиннер вместо скрепки', (
    tester,
  ) async {
    mockPasteboard(image: pngBytes, delay: const Duration(milliseconds: 600));
    await tester.pumpWidget(composer());
    expect(spinner, findsNothing);

    await pressCtrlV(tester);
    // До порога (150 мс) индикации ещё нет — не мигаем на быстром буфере.
    await tester.pump(const Duration(milliseconds: 50));
    expect(spinner, findsNothing, reason: 'до порога индикация не зажигается');

    // После порога — спиннер на месте скрепки.
    await tester.pump(const Duration(milliseconds: 200));
    expect(spinner, findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsNothing);

    // Досчитываем до конца «долгого» ответа плагина. Явные pump-ы,
    // а не pumpAndSettle: спиннер анимируется бесконечно, «устаканиться»
    // кадры не могут, пока он на экране. Управляемое и реальное время
    // чередуем: задержка канала живёт в управляемом, а чтение временного
    // файла на Windows — настоящее дисковое I/O.
    await settlePaste(tester);
    expect(spinner, findsNothing);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    // Сюда сознательно НЕ добавлена проверка миниатюры: на Windows плагин
    // отдаёт путь к временному файлу и читает его реальным дисковым I/O,
    // который не завершается под управляемым временем тестера — вышло бы
    // хост-зависимо. Попадание вложения в черновик покрыто отдельно
    // (message_composer_attach_test), здесь предмет теста — индикация.
  });

  testWidgets('в буфере НЕ картинка — индикация не появляется вовсе', (
    tester,
  ) async {
    mockPasteboard(image: null); // текст в буфере → image == null
    await tester.pumpWidget(composer());

    await pressCtrlV(tester);
    // Ни одного кадра со спиннером: таймер порога не успевает сработать.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(spinner, findsNothing, reason: 'мигание при пустом буфере');
    }
    await tester.pumpAndSettle();
    expect(spinner, findsNothing);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    // Черновик пуст — вкладывать было нечего.
    final memImages = tester
        .widgetList<Image>(find.byType(Image))
        .where((i) => i.image is MemoryImage);
    expect(memImages, isEmpty);
  });

  testWidgets('индикация снимается и когда чтение упало с ошибкой', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          throw PlatformException(code: 'boom');
        });
    await tester.pumpWidget(composer());

    await pressCtrlV(tester);
    await tester.pump(const Duration(milliseconds: 250));
    expect(spinner, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(spinner, findsNothing, reason: 'finally снимает индикацию');
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });

  testWidgets('во время вставки скрепка недоступна (нет параллельного пика)', (
    tester,
  ) async {
    mockPasteboard(image: pngBytes, delay: const Duration(milliseconds: 600));
    await tester.pumpWidget(composer());
    await pressCtrlV(tester);
    await tester.pump(const Duration(milliseconds: 250));

    final btn = tester.widget<IconButton>(
      find.ancestor(of: spinner, matching: find.byType(IconButton)),
    );
    expect(btn.onPressed, isNull);
    // Даём вставке доиграть, иначе тест завершится с висящим таймером.
    await settlePaste(tester);
  });
}
