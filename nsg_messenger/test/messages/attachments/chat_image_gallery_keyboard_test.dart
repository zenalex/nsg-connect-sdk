import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:photo_view/photo_view.dart';

import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_bubble.dart';
import 'package:nsg_messenger/src/messages/attachments/chat_image_gallery.dart';
import 'package:nsg_messenger/src/messages/attachments/image_actions.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// Issue #54 п.4 — клавиатура полноэкранного просмотрщика на десктопе:
/// Escape закрывает, ←/→ листают; открытие с тапнутой картинки, а не с
/// первой; одиночная картинка без элементов листания; в набор попадают
/// только показываемые картинки (файлы/аудио/видео — нет).
final Uint8List _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, //
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, //
  0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, //
  0x0D, 0x0A, 0x2D, 0xB4, //
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, //
  0xAE, 0x42, 0x60, 0x82,
]);

/// Прокрутить кадры вручную: [WidgetTester.pumpAndSettle] здесь не годится
/// — спиннер загрузки картинки (CircularProgressIndicator) анимируется
/// бесконечно, и settle никогда не наступает. Нам достаточно доиграть
/// переход маршрута (300мс) и анимацию листания (200мс).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  Future<AttachmentBytes> noopThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => AttachmentBytes(
    bytes: ByteData.sublistView(_tinyPng),
    contentType: 'image/png',
  );

  Future<AttachmentBytes> noopFull({required String mxcUrl}) async =>
      AttachmentBytes(
        bytes: ByteData.sublistView(_tinyPng),
        contentType: 'image/png',
      );

  AttachmentRef img(int i) => AttachmentRef(
    mxcUrl: 'mxc://server/$i',
    mimeType: 'image/png',
    sizeBytes: 10,
    originalFilename: '$i.png',
    thumbnailMxcUrl: 'mxc://server/$i',
  );

  // Фейковые действия — без реальных плагинов share/clipboard.
  final actions = ImageActions(
    loadBytes: (_) async => Uint8List.fromList([1]),
    copyImageBytes: (_) async {},
    platformOverride: TargetPlatform.windows,
    isWebOverride: false,
  );

  /// Пушит галерею поверх стартового экрана — так проверяется РЕАЛЬНОЕ
  /// закрытие по Escape (pop открывает лежащий под ней экран).
  Future<void> pumpPushedGallery(
    WidgetTester tester, {
    required List<AttachmentRef> images,
    required int initialIndex,
    ImageActions? actionsOverride,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatImageGallery(
                    images: images,
                    initialIndex: initialIndex,
                    thumbnailRpc: noopThumb,
                    fullSizeRpc: noopFull,
                    actions: actionsOverride ?? actions,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await _settle(tester);
    tester.takeException(); // async-декод картинки здесь не важен
  }

  testWidgets('Escape закрывает просмотрщик', (tester) async {
    await pumpPushedGallery(tester, images: [img(1), img(2)], initialIndex: 0);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);

    // Галереи нет, под ней снова стартовый экран.
    expect(find.text('1 / 2'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('←/→ листают картинки', (tester) async {
    await pumpPushedGallery(
      tester,
      images: [img(1), img(2), img(3)],
      initialIndex: 0,
    );
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text('3 / 3'), findsOneWidget);

    // На последней → вправо некуда, индикатор не меняется (не срывается
    // в переполнение).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('открытие с тапнутой картинки, а не с первой', (tester) async {
    await pumpPushedGallery(
      tester,
      images: [img(1), img(2), img(3), img(4)],
      initialIndex: 2,
    );
    expect(find.text('3 / 4'), findsOneWidget);

    // И листание продолжается именно отсюда.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(find.text('2 / 4'), findsOneWidget);
  });

  testWidgets('одиночная картинка — без индикатора и без листания', (
    tester,
  ) async {
    await pumpPushedGallery(tester, images: [img(1)], initialIndex: 0);

    // Индикатор «N / total» скрыт при total == 1.
    expect(find.textContaining(' / '), findsNothing);

    // Стрелки — no-op, экран остаётся открытым (клавиша не «съедена»,
    // но и упасть/уйти в никуда не должно).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(find.byType(ChatImageGallery), findsOneWidget);

    // Escape при этом работает и для одиночной.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(find.byType(ChatImageGallery), findsNothing);
  });

  testWidgets(
    'fallback-просмотрщик (host без галереи) тоже закрывается по Escape',
    (tester) async {
      // onOpenImage не передан → AttachmentBubble открывает свой одиночный
      // полноэкранный просмотр. Он тоже обязан слушать Escape.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: NsgL10n.localizationsDelegates,
          supportedLocales: NsgL10n.supportedLocales,
          home: Scaffold(
            body: AttachmentBubble(
              attachment: img(1),
              thumbnailRpc: noopThumb,
              fullSizeRpc: noopFull,
              textColor: Colors.black,
            ),
          ),
        ),
      );
      await _settle(tester);
      tester.takeException();

      await tester.tap(find.byType(Image).first);
      await _settle(tester);
      tester.takeException();
      expect(find.byType(PhotoView), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byType(PhotoView), findsNothing);
    },
  );

  group('кнопки листания', () {
    // Тот же фейк, но с мобильной платформой — там кнопок быть не должно.
    final mobileActions = ImageActions(
      loadBytes: (_) async => Uint8List.fromList([1]),
      shareFiles: (_) async {},
      writeTempFile: (name, _) async => '/tmp/$name',
      platformOverride: TargetPlatform.iOS,
      isWebOverride: false,
    );

    testWidgets('desktop → стрелки видны и листают', (tester) async {
      await pumpPushedGallery(
        tester,
        images: [img(1), img(2), img(3)],
        initialIndex: 1,
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await _settle(tester);
      expect(find.text('3 / 3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await _settle(tester);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('mobile → стрелок нет (там свайп)', (tester) async {
      await pumpPushedGallery(
        tester,
        images: [img(1), img(2), img(3)],
        initialIndex: 0,
        actionsOverride: mobileActions,
      );

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      // Индикатор при этом остаётся — он полезен на любой платформе.
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('на краях набора соответствующая стрелка неактивна', (
      tester,
    ) async {
      await pumpPushedGallery(
        tester,
        images: [img(1), img(2)],
        initialIndex: 0,
      );

      IconButton buttonFor(IconData icon) => tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
      );

      // Первая картинка: назад — некуда.
      expect(buttonFor(Icons.chevron_left).onPressed, isNull);
      expect(buttonFor(Icons.chevron_right).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await _settle(tester);

      // Последняя картинка: зеркально.
      expect(buttonFor(Icons.chevron_left).onPressed, isNotNull);
      expect(buttonFor(Icons.chevron_right).onPressed, isNull);
    });

    testWidgets('одна картинка → стрелок нет вовсе', (tester) async {
      await pumpPushedGallery(tester, images: [img(1)], initialIndex: 0);

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });

  group('collectChatImages', () {
    ChatMessage msg(String id, AttachmentRef? att) => ChatMessage(
      clientTxnId: id,
      matrixEventId: id,
      senderMatrixUserId: '@a:s',
      senderMessengerUserId: 1,
      body: '',
      msgType: 'm.image',
      serverTimestamp: DateTime(2026, 1, 1),
      status: ChatMessageStatus.sent,
      attachment: att,
    );

    AttachmentRef att(String mxc, String mime, {String? thumb}) =>
        AttachmentRef(
          mxcUrl: mxc,
          mimeType: mime,
          sizeBytes: 10,
          originalFilename: 'f',
          thumbnailMxcUrl: thumb,
        );

    test('файлы, аудио и видео в набор не попадают', () {
      final images = collectChatImages([
        msg('1', att('mxc://s/pdf', 'application/pdf')),
        msg('2', att('mxc://s/aud', 'audio/ogg')),
        msg('3', att('mxc://s/vid', 'video/mp4')),
        msg('4', att('mxc://s/img', 'image/png', thumb: 'mxc://s/img-t')),
        msg('5', null), // текстовое сообщение
      ]);

      expect(images.map((a) => a.mxcUrl), ['mxc://s/img']);
    });

    test('картинка без превью (HEIC) не попадает — её нечем показать', () {
      final images = collectChatImages([
        msg('1', att('mxc://s/heic', 'image/heic')),
      ]);
      expect(images, isEmpty);
    });

    test('порядок хронологический — лента DESC разворачивается', () {
      // Лента приходит новые→старые; в просмотрщике ждём старые→новые.
      final images = collectChatImages([
        msg('new', att('mxc://s/new', 'image/png', thumb: 'mxc://s/new-t')),
        msg('old', att('mxc://s/old', 'image/png', thumb: 'mxc://s/old-t')),
      ]);
      expect(images.map((a) => a.mxcUrl), ['mxc://s/old', 'mxc://s/new']);
    });
  });
}
