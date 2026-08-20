/// Перетаскивание файлов в чат (просьба пользователей, 2026-08-03).
///
/// Нативный бросок плагином здесь не воспроизвести, и не надо: проверяется
/// то, что принадлежит нам — как композер принимает брошенное и как держится
/// подписка на цель броска.
///
/// Подписка — не формальность. Композер пересоздаётся при перестройке ленты,
/// и новый успевает подписаться раньше, чем размонтируется старый. Слепое
/// обнуление в `dispose` убило бы живую подписку, и перетаскивание молча
/// переставало бы работать после любой перерисовки — беда, которую заметили
/// бы нескоро.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_drop_target.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

AttachmentCandidate _file(String name, int size) =>
    AttachmentCandidate(name: name, size: size, bytes: Uint8List(size));

void main() {
  late AttachmentDropSink sink;

  setUp(() => sink = AttachmentDropSink());

  Widget app({bool enabled = true, Key? composerKey}) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    locale: const Locale('ru'),
    home: Scaffold(
      body: MessageComposer(
        key: composerKey,
        enabled: enabled,
        dropSink: sink,
        onSend: (body, {mentionedMessengerUserIds, albumId}) async {},
        onSendAttachment: (picked, {albumId}) async {},
      ),
    ),
  );

  testWidgets('композер подписывается на цель броска', (tester) async {
    expect(sink.ready, isFalse, reason: 'до сборки подписки нет');
    await tester.pumpWidget(app());
    expect(sink.ready, isTrue);
  });

  testWidgets('брошенный файл попадает в черновик', (tester) async {
    await tester.pumpWidget(app());
    await sink.onFiles!([_file('отчёт.pdf', 1024)]);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pendingAttachment_отчёт.pdf')),
      findsOneWidget,
    );
  });

  testWidgets('несколько файлов за один бросок', (tester) async {
    await tester.pumpWidget(app());
    await sink.onFiles!([_file('a.png', 10), _file('b.png', 10)]);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pendingAttachment_a.png')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pendingAttachment_b.png')),
      findsOneWidget,
    );
  });

  testWidgets('слишком большой файл не исчезает молча', (tester) async {
    // Ровно та беда, что была со вставкой из буфера (issue #83): человек
    // видел, что бросил файл, а тот не появлялся, и никто не сказал почему.
    await tester.pumpWidget(app());
    await sink.onFiles!([_file('кино.mkv', kMaxAttachmentBytes + 1)]);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pendingAttachment_кино.mkv')),
      findsNothing,
    );
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('в выключенный композер не роняем', (tester) async {
    // Чат только для чтения / идёт отправка — брошенное игнорируем, но не
    // падаем: бросок мимо цели не должен ломать экран.
    await tester.pumpWidget(app(enabled: false));
    await sink.onFiles!([_file('a.png', 10)]);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pendingAttachment_a.png')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('подписка снимается вместе с композером', (tester) async {
    await tester.pumpWidget(app());
    expect(sink.ready, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    expect(sink.ready, isFalse, reason: 'композера нет — принимать некому');
  });

  testWidgets('пересборка композера НЕ обрывает подписку', (tester) async {
    // Новый композер подписывается раньше, чем размонтируется старый.
    // `dispose` старого обязан снять только СВОЮ подписку.
    await tester.pumpWidget(app(composerKey: const ValueKey('a')));
    await tester.pumpWidget(app(composerKey: const ValueKey('b')));
    await tester.pumpAndSettle();

    expect(sink.ready, isTrue, reason: 'после перерисовки бросок обязан жить');

    await sink.onFiles!([_file('после.png', 10)]);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pendingAttachment_после.png')),
      findsOneWidget,
    );
  });
}
