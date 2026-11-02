/// **issue #151 — стикер в ленте рисуется стикером, а не картинкой.**
///
/// Решение (вариант «В» из обсуждения): свой `msgType: nsg.sticker` плюс
/// разметка в content-е — по образцу `nsg.status_card`, который так живёт с
/// TASK58. Стандартный `m.sticker` в Matrix это отдельный ТИП СОБЫТИЯ, а
/// весь наш путь построен вокруг `m.room.message`: новый тип означал бы
/// ветку в отправке, в разборе `/sync` и в ленте разом.
///
/// Здесь проверяется то, ради чего свой тип и заводился: пузырь у стикера
/// снимается. Если бы стикер ехал обычным вложением, он приезжал бы в
/// пузыре с фоном, подписью и действиями «сохранить/переслать» — то есть
/// перестал бы быть стикером ровно там, где он виден.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/messages/sticker_data.dart';

import '../test_helpers.dart';

void main() {
  group('StickerData.tryParse', () {
    test('обычная разметка', () {
      final d = StickerData.tryParse({
        'nsg.sticker': {'alias': 'cat', 'packId': 7},
      });
      expect(d, isNotNull);
      expect(d!.alias, 'cat');
      expect(d.packId, 7);
    });

    test('без набора — всё равно стикер', () {
      // Набор могли удалить, а сообщение осталось. Рисовать это не мешает.
      final d = StickerData.tryParse({
        'nsg.sticker': {'alias': 'shrug'},
      });
      expect(d?.alias, 'shrug');
      expect(d?.packId, isNull);
    });

    test('битое и чужое — null, а не падение', () {
      // Лента не должна падать из-за одного кривого сообщения: без разметки
      // оно отрисуется обычным вложением.
      expect(StickerData.tryParse(null), isNull);
      expect(StickerData.tryParse({}), isNull);
      expect(StickerData.tryParse({'nsg.sticker': 'не объект'}), isNull);
      expect(
        StickerData.tryParse({'nsg.sticker': <String, dynamic>{}}),
        isNull,
      );
      expect(
        StickerData.tryParse({
          'nsg.sticker': {'alias': '   '},
        }),
        isNull,
        reason: 'стикер без имени не бывает',
      );
      expect(
        StickerData.tryParse({
          'nsg.sticker': {'alias': 'cat', 'packId': 'семь'},
        })?.packId,
        isNull,
        reason: 'чужой тип в packId не должен ронять разбор',
      );
    });

    test('имя без двоеточий и с обрезанными пробелами', () {
      expect(
        StickerData.tryParse({
          'nsg.sticker': {'alias': '  cat  '},
        })?.alias,
        'cat',
      );
    });
  });

  group('ChatMessage', () {
    ChatMessage sticker({String alias = 'cat'}) => ChatMessage.optimistic(
      clientTxnId: 'txn',
      senderMatrixUserId: '@a:t',
      senderMessengerUserId: 1,
      body: ':$alias:',
      msgType: kStickerMsgType,
      attachment: AttachmentRef(
        mxcUrl: 'mxc://localhost/s1',
        mimeType: 'image/webp',
        sizeBytes: 4,
        originalFilename: '$alias.webp',
      ),
      sticker: StickerData(alias: alias, packId: 3),
    );

    test('стикер переживает копирование пузыря', () {
      // Retry, пометка «не отправилось», привязка загруженной картинки —
      // каждый из этих путей строит НОВЫЙ ChatMessage, и потеря разметки
      // превратила бы стикер обратно в картинку прямо в ленте.
      final m = sticker();
      expect(m.retrying().sticker?.alias, 'cat');
      expect(m.failed(StateError('нет сети')).sticker?.alias, 'cat');
      expect(
        m
            .withUploadedAttachment(
              AttachmentRef(
                mxcUrl: 'mxc://localhost/s2',
                mimeType: 'image/webp',
                sizeBytes: 8,
                originalFilename: 'cat.webp',
              ),
            )
            .sticker
            ?.alias,
        'cat',
      );
    });

    test('запасной текст — имя со двоеточиями', () {
      // Его увидят там, где разметку читать некому: чужой Matrix-клиент,
      // старая сборка, строка превью в списке чатов, текст пуша.
      expect(sticker(alias: 'shrug').body, ':shrug:');
    });
  });

  testWidgets('у стикера нет фона пузыря, у обычного сообщения — есть', (
    tester,
  ) async {
    // Ради этого свой тип и заводился. Проверяем не «красиво», а факт:
    // контейнер пузыря у стикера прозрачен и без отступов.
    // Картинку не отдаём: проверяем оформление пузыря, а не декодирование.
    // `StickerBubble` на отказ рисует запасную подпись — и это тоже часть
    // договора: пустого места в ленте быть не должно.
    Future<AttachmentBytes> thumb({
      required String mxcUrl,
      int? width,
      int? height,
    }) async => throw StateError('картинка недоступна');
    Future<AttachmentBytes> full({required String mxcUrl}) async =>
        throw StateError('картинка недоступна');

    Future<Decoration?> decorationOf(ChatMessage m) async {
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: m,
            isOwn: true,
            onRetry: (_) {},
            thumbnailRpc: thumb,
            fullSizeRpc: full,
          ),
        ),
      );
      await tester.pump();
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .toList();
      return containers.isEmpty ? null : containers.first.decoration;
    }

    final stickerDecoration = await decorationOf(
      ChatMessage.optimistic(
        clientTxnId: 'txn-s',
        senderMatrixUserId: '@a:t',
        senderMessengerUserId: 1,
        body: ':cat:',
        msgType: kStickerMsgType,
        attachment: AttachmentRef(
          mxcUrl: 'mxc://localhost/s1',
          mimeType: 'image/webp',
          sizeBytes: 4,
          originalFilename: 'cat.webp',
        ),
        sticker: const StickerData(alias: 'cat'),
      ),
    );
    expect(
      (stickerDecoration! as BoxDecoration).color,
      Colors.transparent,
      reason: 'стикер в пузыре с фоном перестаёт быть стикером',
    );

    final textDecoration = await decorationOf(
      ChatMessage.optimistic(
        clientTxnId: 'txn-t',
        senderMatrixUserId: '@a:t',
        senderMessengerUserId: 1,
        body: 'просто текст',
        msgType: 'm.text',
      ),
    );
    expect(
      (textDecoration! as BoxDecoration).color,
      isNot(Colors.transparent),
      reason: 'а обычное сообщение фон терять не должно',
    );
  });
}
