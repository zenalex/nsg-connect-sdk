/// **issue #129 — вложение оказывалось в чате, куда его не клали.**
///
/// Жалоба Кирилла 12.08: «прикреплённые файлы сохраняются с переключением
/// чатов». Два прошлых захода искали утечку состояния и не нашли: черновик
/// действительно живёт в `MessageComposer._pending`, а экраны чатов keyed
/// по комнате — состояние не переезжает.
///
/// Настоящая причина не в состоянии, а в СОБЫТИИ. На вебе вставка картинки
/// приходит `paste`-событием документа (`ClipboardImageListener` вешает
/// слушателя на `web.document`), и получает его КАЖДЫЙ живой композер — по
/// одному на каждую открытую комнату, и живыми они держатся намеренно
/// (черновик, прокрутка). Одно нажатие Ctrl+V клало картинку во все
/// открытые чаты разом.
///
/// Цена ошибки высокая: человек видит готовое вложение в чужом чате, и
/// одно нажатие «отправить» уводит файл постороннему. Отменить нельзя.
///
/// Здесь закрепляется правило отбора: вставку принимает композер ВИДИМОЙ
/// комнаты ([ActiveRoom]), остальные молчат.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

/// Картинка из буфера: содержимое не важно, важен факт вложения.
PickedAttachment _pasted() => PickedAttachment(
  bytes: Uint8List.fromList(const [1, 2, 3]),
  mimeType: 'image/png',
  originalFilename: 'clipboard.png',
);

void main() {
  tearDown(ActiveRoom.reset);

  /// Два композера рядом — как две открытые панели рабочего набора.
  Widget twoRooms({required int a, required int b}) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: MessageComposer(
              key: const ValueKey('a'),
              roomId: a,
              onSend: (body, {mentionedMessengerUserIds, albumId}) async {},
              onSendAttachment: (picked, {albumId}) async {},
            ),
          ),
          Expanded(
            child: MessageComposer(
              key: const ValueKey('b'),
              roomId: b,
              onSend: (body, {mentionedMessengerUserIds, albumId}) async {},
              onSendAttachment: (picked, {albumId}) async {},
            ),
          ),
        ],
      ),
    ),
  );

  /// Сколько вложений набралось у композера с данным ключом.
  int pendingOf(WidgetTester tester, String key) {
    final state = tester.state(find.byKey(ValueKey(key)));
    // ignore: avoid_dynamic_calls — приватный State, поле проверяем как есть.
    return (state as dynamic).pendingCountForTest as int;
  }

  testWidgets('вставку берёт только видимая комната', (tester) async {
    await tester.pumpWidget(twoRooms(a: 1, b: 2));
    ActiveRoom.claim(1);

    // Событие документа получают ОБА композера — так работает web-listener.
    for (final key in const ['a', 'b']) {
      final state = tester.state(find.byKey(ValueKey(key)));
      // ignore: avoid_dynamic_calls
      (state as dynamic).handlePastedImageForTest(_pasted());
    }
    await tester.pump();

    expect(pendingOf(tester, 'a'), 1, reason: 'комната на экране — её вставка');
    expect(pendingOf(tester, 'b'), 0, reason: 'соседний чат не при делах');
  });

  // Хост может не сообщить комнату (старый вызов) — тогда ведём себя как
  // раньше: лучше принять вставку, чем потерять её молча.
  testWidgets('без roomId вставка принимается', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: Scaffold(
          body: MessageComposer(
            key: const ValueKey('a'),
            onSend: (body, {mentionedMessengerUserIds, albumId}) async {},
            onSendAttachment: (picked, {albumId}) async {},
          ),
        ),
      ),
    );
    ActiveRoom.claim(99);

    final state = tester.state(find.byKey(const ValueKey('a')));
    // ignore: avoid_dynamic_calls
    (state as dynamic).handlePastedImageForTest(_pasted());
    await tester.pump();

    expect(pendingOf(tester, 'a'), 1);
  });

  // Никто не заявил видимую комнату (например, чат открыт единственным
  // маршрутом и заявка ещё не прошла) — вставка тоже не теряется.
  testWidgets('без активной комнаты вставка принимается', (tester) async {
    await tester.pumpWidget(twoRooms(a: 1, b: 2));

    final state = tester.state(find.byKey(const ValueKey('a')));
    // ignore: avoid_dynamic_calls
    (state as dynamic).handlePastedImageForTest(_pasted());
    await tester.pump();

    expect(pendingOf(tester, 'a'), 1);
  });
}
