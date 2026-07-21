import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show AttachmentRef, AttachmentBytes;
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/composer_album_edit.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

import '../test_helpers.dart';

/// Widget-тесты для album-edit-mode композера (редактирование альбома).
void main() {
  Widget wrap(Widget child) =>
      wrapL10n(Column(children: [const Spacer(), child]));

  AttachmentRef imageRef(String id) => AttachmentRef(
    mxcUrl: 'mxc://localhost/$id',
    mimeType: 'image/jpeg',
    sizeBytes: 100,
    originalFilename: '$id.jpg',
    thumbnailMxcUrl: 'mxc://localhost/$id',
  );

  ComposerAlbumEdit albumEdit({
    int imageCount = 2,
    String caption = 'подпись',
    String? captionEventId = 'cap-1',
  }) => ComposerAlbumEdit(
    albumId: 'album-1',
    images: [
      for (var i = 0; i < imageCount; i++)
        ComposerAlbumImage(
          attachment: imageRef('img$i'),
          matrixEventId: 'ev-img$i',
        ),
    ],
    captionBody: caption,
    captionEventId: captionEventId,
  );

  // Валидный 1x1 PNG — provider реально декодирует (пустой ByteData бы
  // бросил «Invalid image data» в async-зоне и уронил тест).
  final png1x1 = Uint8List.fromList(const [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, //
    1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, //
    65, 84, 120, 156, 99, 96, 0, 2, 0, 0, 5, 0, 1, 122, 94, 171, 63, 0, 0, //
    0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
  ]);
  Future<AttachmentBytes> thumbRpc({
    required String mxcUrl,
    int? width,
    int? height,
  }) async => AttachmentBytes(
    bytes: ByteData.sublistView(png1x1),
    contentType: 'image/png',
  );
  Future<AttachmentBytes> fullRpc({required String mxcUrl}) async =>
      AttachmentBytes(
        bytes: ByteData.sublistView(png1x1),
        contentType: 'image/png',
      );

  Widget composer({
    required ComposerAlbumEdit? album,
    void Function(ComposerAlbumEditResult)? onEditAlbum,
    VoidCallback? onCancelAlbumEdit,
  }) => MessageComposer(
    onSend: (b, {mentionedMessengerUserIds, albumId}) async {},
    onSendAttachment: (p, {albumId}) async {},
    albumEdit: album,
    onEditAlbum: onEditAlbum == null ? null : (r) async => onEditAlbum(r),
    onCancelAlbumEdit: onCancelAlbumEdit,
    albumThumbnailRpc: thumbRpc,
    albumFullSizeRpc: fullRpc,
  );

  testWidgets(
    'album-edit-mode → чип «Редактирование альбома» + подпись в поле',
    (tester) async {
      await tester.pumpWidget(wrap(composer(album: albumEdit())));
      await tester.pump();

      expect(find.text('Editing album'), findsOneWidget);
      // Подпись префилена в поле ввода.
      expect(find.text('подпись'), findsOneWidget);
      // Save-иконка (check), не send.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    },
  );

  testWidgets(
    'save без изменений → onEditAlbum НЕ вызван, вместо этого cancel',
    (tester) async {
      ComposerAlbumEditResult? result;
      var cancelled = 0;
      await tester.pumpWidget(
        wrap(
          composer(
            album: albumEdit(),
            onEditAlbum: (r) => result = r,
            onCancelAlbumEdit: () => cancelled++,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(result, isNull, reason: 'дифф пустой — RPC не нужен');
      expect(cancelled, 1, reason: 'выходим из режима через cancel');
    },
  );

  testWidgets('изменил подпись → save отдаёт результат с новой подписью', (
    tester,
  ) async {
    ComposerAlbumEditResult? result;
    await tester.pumpWidget(
      wrap(composer(album: albumEdit(), onEditAlbum: (r) => result = r)),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'новая подпись');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.albumId, 'album-1');
    expect(result!.newCaption, 'новая подпись');
    expect(result!.captionEventId, 'cap-1');
    expect(result!.removedImageEventIds, isEmpty);
    expect(result!.newAttachments, isEmpty);
    expect(result!.onlyCaptionChanged, isTrue);
  });

  testWidgets('крестик на существующей картинке → eventId в removed на save', (
    tester,
  ) async {
    ComposerAlbumEditResult? result;
    await tester.pumpWidget(
      wrap(
        composer(
          album: albumEdit(imageCount: 3),
          onEditAlbum: (r) => result = r,
        ),
      ),
    );
    await tester.pump();

    // 3 картинки → 3 крестика (все удаляемы, т.к. останется ≥1).
    expect(find.byIcon(Icons.close), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();

    // Одна убрана → осталось 2 крестика.
    expect(find.byIcon(Icons.close), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.removedImageEventIds, ['ev-img0']);
    expect(result!.onlyCaptionChanged, isFalse);
  });

  testWidgets('нельзя удалить последнюю картинку (крестик скрыт)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(composer(album: albumEdit(imageCount: 1))));
    await tester.pump();

    // 1 картинка — крестик не показывается (нельзя опустошить альбом).
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('очистка подписи → newCaption пустой на save', (tester) async {
    ComposerAlbumEditResult? result;
    await tester.pumpWidget(
      wrap(
        composer(
          album: albumEdit(imageCount: 2, caption: 'была'),
          onEditAlbum: (r) => result = r,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.newCaption, isEmpty);
    expect(result!.captionEventId, 'cap-1');
  });

  testWidgets('вложения-миниатюры существующих картинок отрисованы (Image)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(composer(album: albumEdit(imageCount: 2))));
    await tester.pump();
    // Две существующие картинки → ≥2 Image-виджета в strip-е.
    expect(find.byType(Image), findsAtLeastNWidgets(2));
  });

  test('ComposerAlbumEditResult.onlyCaptionChanged', () {
    const r = ComposerAlbumEditResult(
      albumId: 'a',
      removedImageEventIds: [],
      newAttachments: <PickedAttachment>[],
      newCaption: 'x',
      captionEventId: null,
    );
    expect(r.onlyCaptionChanged, isTrue);
    const r2 = ComposerAlbumEditResult(
      albumId: 'a',
      removedImageEventIds: ['e'],
      newAttachments: <PickedAttachment>[],
      newCaption: 'x',
      captionEventId: null,
    );
    expect(r2.onlyCaptionChanged, isFalse);
  });
}
