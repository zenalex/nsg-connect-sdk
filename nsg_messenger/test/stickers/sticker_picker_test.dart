/// **issue #151 — панель выбора стикера и вкладки панели вставки.**
///
/// Проверяем то, из-за чего пикер бывает бесполезен:
///
///   * **пустое и сломанное — разные вещи.** Сеть отвалилась — человек должен
///     увидеть отказ и кнопку «Повторить», а не «стикеров нет»;
///   * **вкладка стикеров появляется только когда есть чем её наполнить.**
///     Пустая вкладка хуже отсутствующей;
///   * **тап возвращает стикер вызывающей стороне** — панель ничего не
///     отправляет сама.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/insert_picker.dart';
import 'package:nsg_messenger/src/stickers/sticker_picker_panel.dart';

void main() {
  Sticker sticker(int id, String alias) => Sticker(
    id: id,
    packId: 3,
    mxcUrl: 'mxc://localhost/$alias',
    mimeType: 'image/webp',
    sizeBytes: 2048,
    alias: alias,
    position: 0,
    createdAt: DateTime.utc(2026, 8, 29),
  );

  StickerPackView pack(String name, List<Sticker> stickers) => StickerPackView(
    pack: StickerPack(
      id: 3,
      tenantId: 1,
      ownerMessengerUserId: 1,
      name: name,
      createdAt: DateTime.utc(2026, 8, 29),
      updatedAt: DateTime.utc(2026, 8, 29),
    ),
    stickers: stickers,
  );

  // Картинок в тестах нет: панель проверяем по подписям и по тому, что
  // возвращает тап. `StickerPickerPanel` на отказ рисует имя — это и есть
  // договор «пустого места быть не должно».
  Future<AttachmentBytes> noThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => throw StateError('картинка недоступна');
  Future<AttachmentBytes> noFull({required String mxcUrl}) async =>
      throw StateError('картинка недоступна');

  Widget host({
    required StickerPacksLoader loadPacks,
    required void Function(Sticker) onPick,
    VoidCallback? onManage,
  }) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: StickerPickerPanel(
        loadPacks: loadPacks,
        onPick: onPick,
        onManage: onManage,
        thumbnailRpc: noThumb,
        fullSizeRpc: noFull,
      ),
    ),
  );

  testWidgets('наборы показываются заголовками, тап возвращает стикер', (
    tester,
  ) async {
    Sticker? picked;
    await tester.pumpWidget(
      host(
        loadPacks: () async => [
          pack('Личное', [sticker(11, 'cat'), sticker(12, 'shrug')]),
        ],
        onPick: (s) => picked = s,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Личное'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);

    await tester.tap(find.text('shrug'));
    expect(picked?.id, 12);
  });

  testWidgets('сеть отвалилась — отказ и «Повторить», а не «стикеров нет»', (
    tester,
  ) async {
    var attempt = 0;
    await tester.pumpWidget(
      host(
        loadPacks: () async {
          attempt += 1;
          if (attempt == 1) throw StateError('нет сети');
          return [
            pack('Личное', [sticker(11, 'cat')]),
          ];
        },
        onPick: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load stickers'), findsOneWidget);
    expect(find.text('You have no stickers yet'), findsNothing);

    await tester.tap(find.byKey(kStickerPickerRetryKey));
    await tester.pumpAndSettle();
    expect(find.text('cat'), findsOneWidget);
  });

  testWidgets('пустые наборы не показываются', (tester) async {
    // Набор без картинок — это не «выбери из пустого места»: показывать
    // заголовок, под которым ничего нет, незачем.
    await tester.pumpWidget(
      host(loadPacks: () async => [pack('Пустой', const [])], onPick: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пустой'), findsNothing);
    expect(find.text('You have no stickers yet'), findsOneWidget);
  });

  testWidgets('на пустой панели есть выход к управлению наборами', (
    tester,
  ) async {
    // Иначе пустая панель — тупик: «стикеров нет» и ни одной кнопки, откуда
    // им взяться. Строка нужна и на полной панели — следующий набор тоже
    // откуда-то заводят.
    var opened = 0;
    await tester.pumpWidget(
      host(
        loadPacks: () async => const <StickerPackView>[],
        onPick: (_) {},
        onManage: () => opened += 1,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kStickerPickerManageKey));
    expect(opened, 1);
  });

  testWidgets('без перехода от хоста строки управления нет', (tester) async {
    await tester.pumpWidget(
      host(loadPacks: () async => const <StickerPackView>[], onPick: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kStickerPickerManageKey), findsNothing);
  });

  group('панель вставки', () {
    Widget sheetHost({
      StickerPacksLoader? loadPacks,
      bool withEmoji = true,
      void Function(ComposerInsertion?)? onResult,
    }) => MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final r = await showComposerInsertPicker(
                  context,
                  withEmoji: withEmoji,
                  loadStickerPacks: loadPacks,
                  thumbnailRpc: loadPacks == null ? null : noThumb,
                  fullSizeRpc: loadPacks == null ? null : noFull,
                );
                onResult?.call(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    testWidgets('без стикеров — прежний лист эмодзи, без вкладок', (
      tester,
    ) async {
      ComposerInsertion? result;
      await tester.pumpWidget(sheetHost(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(kInsertPickerTabsKey), findsNothing);
      expect(find.text('Choose an emoji'), findsOneWidget);

      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle();
      expect((result! as EmojiInsertion).emoji, '😀');
    });

    testWidgets('со стикерами — две вкладки, стикер возвращается', (
      tester,
    ) async {
      ComposerInsertion? result;
      await tester.pumpWidget(
        sheetHost(
          loadPacks: () async => [
            pack('Личное', [sticker(11, 'cat')]),
          ],
          onResult: (r) => result = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(kInsertPickerTabsKey), findsOneWidget);
      // Эмодзи открыты первой: на десктопе за панелью идут прежде всего
      // за ними.
      expect(find.text('😀'), findsOneWidget);

      await tester.tap(find.byKey(kInsertPickerStickerTabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('cat'));
      await tester.pumpAndSettle();

      expect((result! as StickerInsertion).sticker.id, 11);
    });

    testWidgets('мобильный (эмодзи с клавиатуры) — только стикеры', (
      tester,
    ) async {
      await tester.pumpWidget(
        sheetHost(
          withEmoji: false,
          loadPacks: () async => [
            pack('Личное', [sticker(11, 'cat')]),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(kInsertPickerTabsKey), findsNothing);
      expect(find.text('😀'), findsNothing);
      expect(find.text('cat'), findsOneWidget);
    });
  });
}
