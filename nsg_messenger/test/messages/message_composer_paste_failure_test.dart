import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

/// **Issue #83** — вставка скриншота из «Ножниц» молча ничего не делала.
///
/// Пользователь вырезал область (Win+Shift+S), жал Ctrl+V, ничего не
/// происходило — и он решил, что мессенджер требует обязательный
/// комментарий к фото. На деле картинка просто не прикреплялась: композер
/// выходил молча и при ошибке чтения буфера, и при пустом результате.
///
/// Предмет этих тестов — ГРАНИЦА между «сказать» и «промолчать»:
///   * картинка в буфере была, прочитать не смогли → человек должен узнать;
///   * в буфере обычный текст → ни звука (через тот же код проходит КАЖДЫЙ
///     Ctrl+V, и снекбар на каждую вставку текста был бы хуже исходной беды).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('pasteboard');

  /// Настоящий 1x1 PNG — чтобы вложение прошло весь путь до отправки.
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmM'
    'IQAAAABJRU5ErkJggg==',
  );

  final tempFiles = <File>[];

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    for (final f in tempFiles) {
      // Терпимо: чтение файла из буфера может ещё не отпустить дескриптор,
      // и падение уборки маскировало бы настоящую причину провала теста.
      try {
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    tempFiles.clear();
  });

  /// Подменяет нативный `pasteboard`. [onImage] — что вернуть (или бросить)
  /// на вызов `image`, [files] — что отдать на вызов `files`.
  void mockPasteboard({
    Object? Function()? onImage,
    List<String> files = const <String>[],
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'image':
              return onImage?.call();
            case 'files':
              return files;
            default:
              return null;
          }
        });
  }

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

  /// Ctrl+V по сфокусированному полю ввода.
  Future<void> pressCtrlV(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  /// Дождаться конца вставки: чередует управляемое время (таймеры композера)
  /// и реальное (дисковое I/O при чтении файла из буфера). Один вид времени
  /// по отдельности флоу не дотягивает.
  Future<void> settlePaste(
    WidgetTester tester, {
    bool Function()? until,
  }) async {
    if (until != null) {
      final elapsed = Stopwatch()..start();
      while (!until() && elapsed.elapsed < const Duration(seconds: 5)) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      await tester.pump();
      expect(
        until(),
        isTrue,
        reason: 'Paste did not complete within 5 seconds',
      );
      return;
    }
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
    }
    await tester.pump();
  }

  /// Текст ошибки берём из дерева, а не константой: локаль в тестах зависит
  /// от хоста, и жёсткая русская строка позеленела бы только на части машин.
  String pasteFailedText(WidgetTester tester) => NsgL10n.of(
    tester.element(find.byType(MessageComposer)),
  ).composerPasteImageFailed;

  testWidgets('картинка в буфере есть, прочитать не смогли — видимая ошибка', (
    tester,
  ) async {
    // Живой случай на Windows: CF_DIB в буфере есть (иначе плагин ответил бы
    // пустым успехом), но открыть буфер не вышло — его держит другое
    // приложение. До issue #83 это глоталось `catch (_) { return; }`.
    mockPasteboard(
      onImage: () =>
          throw PlatformException(code: '0', message: 'open clipboard failed'),
    );
    await tester.pumpWidget(composer());

    await pressCtrlV(tester);
    await settlePaste(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(pasteFailedText(tester)),
      findsOneWidget,
      reason: 'молчание здесь и породило диагноз «нужен комментарий к фото»',
    );
  });

  testWidgets('в буфере обычный текст — ни звука', (tester) async {
    // Ctrl+V с текстом идёт через ТОТ ЖЕ код: плагин отвечает «картинки нет»
    // (null), файлов в буфере тоже нет. Вставку делает сам TextField.
    mockPasteboard(onImage: () => null);
    await tester.pumpWidget(composer());

    await pressCtrlV(tester);
    await settlePaste(tester);
    await tester.pumpAndSettle();

    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'ругаться на каждую вставку текста хуже исходного бага',
    );
    expect(find.text(pasteFailedText(tester)), findsNothing);
  });

  testWidgets('нативного плагина буфера нет — тоже ни звука', (tester) async {
    // Канал не замокан вовсе → MissingPluginException. Это не «картинка
    // потерялась», а отсутствие нативной части в сборке; через этот путь
    // проходит каждый Ctrl+V, включая текстовый.
    await tester.pumpWidget(composer());

    await pressCtrlV(tester);
    await settlePaste(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('в буфере ссылка на файл-картинку — вложение прикрепляется', (
    tester,
  ) async {
    // Так копируют картинку в проводнике/Finder: Windows кладёт CF_HDROP,
    // CF_DIB не появляется вовсе, и `Pasteboard.image` честно отдаёт пустоту.
    // Раньше на этом всё и заканчивалось — молча.
    final tmp = File(
      '${Directory.systemTemp.path}/nsg_paste_hdrop_'
      '${DateTime.now().microsecondsSinceEpoch}.png',
    );
    tmp.writeAsBytesSync(pngBytes);
    tempFiles.add(tmp);
    mockPasteboard(onImage: () => null, files: [tmp.path]);

    final sent = <PickedAttachment>[];
    await tester.pumpWidget(
      composer(onSendAttachment: (p) async => sent.add(p)),
    );

    await pressCtrlV(tester);
    await settlePaste(
      tester,
      until: () => find.byIcon(Icons.send).evaluate().isNotEmpty,
    );
    await tester.pump();

    // Проверяем через отправку, а не через миниатюру: декод картинки в
    // виджете зависит от хоста, а попадание вложения в черновик — нет.
    expect(
      find.byIcon(Icons.send),
      findsOneWidget,
      reason: 'вложение в черновике включает кнопку «Отправить»',
    );
    await tester.tap(find.byIcon(Icons.send));
    await settlePaste(tester, until: () => sent.length == 1);

    expect(sent, hasLength(1));
    expect(sent.single.mimeType, 'image/png');
    expect(sent.single.bytes, pngBytes);
    expect(
      sent.single.originalFilename,
      endsWith('.png'),
      reason: 'у файла из проводника есть настоящее имя — его и берём',
    );
    expect(sent.single.originalFilename, contains('nsg_paste_hdrop_'));
    expect(find.byType(SnackBar), findsNothing);
  });

  // Отбор по расширению оставлял немую дыру ровно того же рода, из-за которой
  // и завели #83: человек копировал в проводнике pdf, жал Ctrl+V — и не
  // происходило НИЧЕГО. При этом тот же файл, брошенный в окно мышью,
  // прикреплялся штатно. Две двери в одну комнату вели себя по-разному.
  testWidgets('в буфере файл НЕ картинка — тоже прикрепляется', (tester) async {
    final tmp = File(
      '${Directory.systemTemp.path}/nsg_paste_doc_'
      '${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    tmp.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]); // «%PDF»
    tempFiles.add(tmp);
    mockPasteboard(onImage: () => null, files: [tmp.path]);

    final sent = <PickedAttachment>[];
    await tester.pumpWidget(
      composer(onSendAttachment: (p) async => sent.add(p)),
    );

    await pressCtrlV(tester);
    await settlePaste(
      tester,
      until: () => find.byIcon(Icons.send).evaluate().isNotEmpty,
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await settlePaste(tester, until: () => sent.length == 1);

    expect(sent, hasLength(1));
    expect(sent.single.mimeType, 'application/pdf');
    expect(sent.single.originalFilename, endsWith('.pdf'));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('в буфере несколько файлов — прикрепляются все', (tester) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final paths = <String>[];
    for (final ext in const ['png', 'txt', 'pdf']) {
      final f = File('${Directory.systemTemp.path}/nsg_paste_many_$stamp.$ext');
      f.writeAsBytesSync(ext == 'png' ? pngBytes : const [1, 2, 3]);
      tempFiles.add(f);
      paths.add(f.path);
    }
    mockPasteboard(onImage: () => null, files: paths);

    final sent = <PickedAttachment>[];
    await tester.pumpWidget(
      composer(onSendAttachment: (p) async => sent.add(p)),
    );

    await pressCtrlV(tester);
    // Кнопка появляется после чтения всей пачки, независимо от скорости диска.
    await settlePaste(
      tester,
      until: () => find.byIcon(Icons.send).evaluate().isNotEmpty,
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await settlePaste(tester, until: () => sent.length == 3);

    expect(sent, hasLength(3));
    expect(
      sent.map((p) => p.mimeType),
      containsAll(<String>['image/png', 'text/plain', 'application/pdf']),
    );
  });

  // Путь буфера обязан вести себя как перетаскивание и в отказе: слишком
  // большой файл не исчезает молча, его называют по имени.
  testWidgets('файл в буфере больше потолка — назван поимённо', (tester) async {
    final tmp = File(
      '${Directory.systemTemp.path}/nsg_paste_big_'
      '${DateTime.now().microsecondsSinceEpoch}.bin',
    );
    // Размер задаём `truncate`, а не записью байтов: отказ считается по
    // `stat`, до чтения, и гонять 50 МБ через память теста незачем.
    final raf = tmp.openSync(mode: FileMode.write);
    raf.truncateSync(kMaxAttachmentBytes + 1);
    raf.closeSync();
    tempFiles.add(tmp);
    mockPasteboard(onImage: () => null, files: [tmp.path]);

    await tester.pumpWidget(composer());
    await pressCtrlV(tester);
    await settlePaste(
      tester,
      until: () => find.byType(SnackBar).evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('nsg_paste_big_'), findsOneWidget);
  });
}
