/// **issue #151 — стикеры в композере.**
///
/// Кнопка вставки до этой задачи была только на десктопе (issue #85: на
/// мобильном эмодзи даёт системная клавиатура, и своя кнопка вела бы к более
/// бедному набору). Со стикерами правило меняется ровно в одном месте:
/// стикеры системная клавиатура не даёт, поэтому на мобильном кнопка
/// появляется — но открывает ТОЛЬКО стикеры.
///
/// Здесь проверяется это и то, что без подключённых стикеров всё остаётся
/// как было: лишней кнопки на мобильном не возникает.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/insert_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';
import 'package:nsg_messenger/src/stickers/sticker_picker_panel.dart';

import '../test_helpers.dart';

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

  StickerPackView pack(List<Sticker> stickers) => StickerPackView(
    pack: StickerPack(
      id: 3,
      tenantId: 1,
      ownerMessengerUserId: 1,
      name: 'Личное',
      createdAt: DateTime.utc(2026, 8, 29),
      updatedAt: DateTime.utc(2026, 8, 29),
    ),
    stickers: stickers,
  );

  Future<AttachmentBytes> noThumb({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => throw StateError('картинка недоступна');
  Future<AttachmentBytes> noFull({required String mxcUrl}) async =>
      throw StateError('картинка недоступна');

  Widget composer({
    List<Sticker>? sent,
    bool withStickers = true,
    VoidCallback? onManage,
  }) => wrapL10n(
    Column(
      children: [
        const Spacer(),
        MessageComposer(
          enabled: true,
          onSend: (b, {mentionedMessengerUserIds, albumId}) async {},
          loadStickerPacks: withStickers
              ? () async => [
                  pack([sticker(11, 'cat')]),
                ]
              : null,
          onSendSticker: withStickers
              ? (s) async {
                  sent?.add(s);
                }
              : null,
          onManageStickers: onManage,
          albumThumbnailRpc: noThumb,
          albumFullSizeRpc: noFull,
        ),
      ],
    ),
  );

  testWidgets(
    'на мобильном кнопка появляется ради стикеров и открывает только их',
    (tester) async {
      final sent = <Sticker>[];
      await tester.pumpWidget(composer(sent: sent));

      expect(
        find.byKey(kComposerEmojiButtonKey),
        findsOneWidget,
        reason: 'стикеры системная клавиатура не даёт — иначе их не достать',
      );

      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(kInsertPickerTabsKey),
        findsNothing,
        reason: 'вкладка эмодзи рядом с системной клавиатурой — худшая копия',
      );
      await tester.tap(find.text('cat'));
      await tester.pumpAndSettle();

      expect(sent.single.id, 11, reason: 'стикер уходит сразу, без вставки');
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets(
    'на мобильном без стикеров кнопки по-прежнему нет',
    (tester) async {
      await tester.pumpWidget(composer(withStickers: false));
      expect(find.byKey(kComposerEmojiButtonKey), findsNothing);
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets(
    'на десктопе — вкладки: эмодзи и стикеры в одной панели',
    (tester) async {
      final sent = <Sticker>[];
      await tester.pumpWidget(composer(sent: sent));
      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(kInsertPickerTabsKey), findsOneWidget);
      expect(find.text('😀'), findsOneWidget, reason: 'эмодзи открыты первыми');

      await tester.tap(find.byKey(kInsertPickerStickerTabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('cat'));
      await tester.pumpAndSettle();

      expect(sent.single.id, 11);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    '«Мои стикеры» открываются ПОСЛЕ закрытия панели',
    (tester) async {
      // Экран управления нельзя пушить под закрывающимся листом: переход
      // должен случиться, когда лист уже ушёл. Поэтому «управление» едет
      // результатом листа, а не колбэком изнутри.
      var opened = 0;
      await tester.pumpWidget(composer(onManage: () => opened += 1));
      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kInsertPickerStickerTabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kStickerPickerManageKey));
      await tester.pumpAndSettle();

      expect(opened, 1);
      expect(
        find.byKey(kInsertPickerTabsKey),
        findsNothing,
        reason: 'лист закрылся до перехода',
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'эмодзи из той же панели по-прежнему вставляется в текст',
    (tester) async {
      // Вкладки не должны сломать путь #85: эмодзи всё так же попадает в
      // поле, а не улетает сообщением.
      final sent = <Sticker>[];
      await tester.pumpWidget(composer(sent: sent));
      await tester.enterText(find.byType(TextField), 'привет мир');
      final ctl = tester.widget<TextField>(find.byType(TextField)).controller!;
      ctl.selection = const TextSelection.collapsed(offset: 6);
      await tester.pump();

      await tester.tap(find.byKey(kComposerEmojiButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀'));
      await tester.pumpAndSettle();

      expect(ctl.text, 'привет😀 мир');
      expect(sent, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
