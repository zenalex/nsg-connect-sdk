/// **issue #151 — экран управления наборами.**
///
/// Проверяется то, из-за чего такой экран обычно и не работает:
///
///   * **отказ политики показывается словами сервера.** Потолки живут там, и
///     своя копия текста разъехалась бы молча — человек читал бы вежливую
///     неправду вроде «слишком большой файл», когда дело в имени;
///   * **удаление спрашивает.** Набор уносит стикеры с собой;
///   * **имя стикера предлагается из имени файла** — обычный случай не должен
///     требовать печатать.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/stickers/nsg_messenger_stickers.dart';
import 'package:nsg_messenger/src/stickers/sticker_packs_screen.dart';

void main() {
  StickerPack pack(String name, {int id = 3}) => StickerPack(
    id: id,
    tenantId: 1,
    ownerMessengerUserId: 1,
    name: name,
    createdAt: DateTime.utc(2026, 8, 29),
    updatedAt: DateTime.utc(2026, 8, 29),
  );

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

  Widget host(NsgMessengerStickers stickers, {StickerFilePicker? pickFile}) =>
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: StickerPacksScreen(stickers: stickers, pickFile: pickFile),
      );

  testWidgets('пусто — подсказка и создание набора', (tester) async {
    final created = <String>[];
    var packs = <StickerPackView>[];
    await tester.pumpWidget(
      host(
        NsgMessengerStickers.withRpcs(
          listPacksRpc: () async => packs,
          createPackRpc: ({required String name}) async {
            created.add(name);
            packs = [StickerPackView(pack: pack(name), stickers: const [])];
            return pack(name);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New pack'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'New pack'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Личное  ');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(created, ['Личное'], reason: 'пробелы по краям — не часть имени');
    expect(find.text('Личное'), findsOneWidget, reason: 'список перечитан');
  });

  testWidgets('отказ политики показывается словами сервера', (tester) async {
    // Своего текста здесь быть не должно: правило живёт на сервере, и
    // «не получилось» вместо причины заставляет человека гадать.
    await tester.pumpWidget(
      host(
        NsgMessengerStickers.withRpcs(
          listPacksRpc: () async => const <StickerPackView>[],
          createPackRpc: ({required String name}) async =>
              throw StickerRejectedException(
                reason: 'tooManyPacks',
                detail: 'больше 5 наборов на человека не заводим',
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'New pack'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'шестой');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('больше 5 наборов на человека не заводим'),
      findsOneWidget,
    );
    expect(find.text('Something went wrong. Try again'), findsNothing);
  });

  testWidgets('удаление набора спрашивает; отмена ничего не удаляет', (
    tester,
  ) async {
    final deleted = <int>[];
    await tester.pumpWidget(
      host(
        NsgMessengerStickers.withRpcs(
          listPacksRpc: () async => [
            StickerPackView(
              pack: pack('Личное'),
              stickers: [sticker(11, 'cat')],
            ),
          ],
          deletePackRpc: ({required int packId}) async => deleted.add(packId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete pack'));
    await tester.pumpAndSettle();

    // Про стикеры сказано прямо: они уходят вместе с набором.
    expect(find.textContaining('Личное'), findsWidgets);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete pack'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(deleted, [3]);
  });

  testWidgets('добавление: имя предлагается из имени файла', (tester) async {
    ({int packId, String alias, String mime})? added;
    await tester.pumpWidget(
      host(
        NsgMessengerStickers.withRpcs(
          listPacksRpc: () async => [
            StickerPackView(pack: pack('Личное'), stickers: const []),
          ],
          addStickerRpc:
              ({
                required int packId,
                required ByteData bytes,
                required String mimeType,
                required String alias,
              }) async {
                added = (packId: packId, alias: alias, mime: mimeType);
                return sticker(11, alias);
              },
        ),
        pickFile: () async => PickedAttachment(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          originalFilename: 'Cat Face.PNG',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'cat_face',
      reason: 'человек уже назвал картинку — печатать заново незачем',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(added?.packId, 3);
    expect(added?.alias, 'cat_face');
    expect(added?.mime, 'image/png');
  });

  testWidgets('список не загрузился — отказ и «Повторить»', (tester) async {
    var attempt = 0;
    await tester.pumpWidget(
      host(
        NsgMessengerStickers.withRpcs(
          listPacksRpc: () async {
            attempt += 1;
            if (attempt == 1) throw StateError('нет сети');
            return [StickerPackView(pack: pack('Личное'), stickers: const [])];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load stickers'), findsOneWidget);
    await tester.tap(find.byKey(kStickerPacksRetryKey));
    await tester.pumpAndSettle();
    expect(find.text('Личное'), findsOneWidget);
  });
}
