import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

/// Плагин записи без устройства: пишет на `start` фиктивный m4a по пути
/// композера и отдаёт его же из `stop`. `permission` можно задержать —
/// так ведёт себя системный запрос доступа к микрофону.
class _FakeRecord extends Fake
    with MockPlatformInterfaceMixin
    implements RecordPlatform {
  Completer<bool>? permission;
  final calls = <String>[];
  String? _path;

  @override
  Future<void> create(String recorderId) async => calls.add('create');

  @override
  Stream<RecordState> onStateChanged(String recorderId) => const Stream.empty();

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) {
    calls.add('hasPermission');
    return permission?.future ?? Future.value(true);
  }

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    calls.add('start');
    File(path).writeAsBytesSync(List<int>.filled(64, 7));
    _path = path;
  }

  @override
  Future<String?> stop(String recorderId) async {
    calls.add('stop');
    return _path;
  }

  @override
  Future<void> dispose(String recorderId) async => calls.add('dispose');
}

class _FakePaths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePaths(this.dir);
  final String dir;

  @override
  Future<String?> getTemporaryPath() async => dir;
}

/// #4182: голосовое на iPhone «падало без ошибки». Две причины:
///  1. встроенный `tooltip` у кнопки микрофона на касании сам ловит
///     long-press и выигрывает арену жестов — запись не начиналась вовсе,
///     вместо неё всплывала подсказка «Удерживайте для записи»;
///  2. как только запись начиналась, кнопку подменяли другой («стоп»), и
///     отпускание пальца терялось вместе с размонтированным детектором.
void main() {
  late _FakeRecord record;
  late Directory tmp;

  setUp(() {
    record = _FakeRecord();
    RecordPlatform.instance = record;
    tmp = Directory.systemTemp.createTempSync('nsg_voice_test');
    PathProviderPlatform.instance = _FakePaths(tmp.path);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Widget composer(List<PickedAttachment> sent) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        onSend: (_, {mentionedMessengerUserIds, albumId}) async {},
        onSendAttachment: (p, {albumId}) async => sent.add(p),
      ),
    ),
  );

  testWidgets('удержание микрофона пишет, отпускание отправляет голосовое', (
    tester,
  ) async {
    final sent = <PickedAttachment>[];
    await tester.pumpWidget(composer(sent));

    final hold = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.mic_none)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();

    expect(record.calls, contains('start'));
    // Идёт запись — на месте микрофона «стоп», подсказка не всплывала.
    expect(find.byIcon(Icons.stop_circle), findsOneWidget);
    expect(find.text('Hold to record'), findsNothing);

    // Минимальная длина записи меряется по настоящим часам.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await hold.up();
    // Отправка читает файл настоящим вводом-выводом: чередуем реальный
    // цикл событий и кадры, пока цепочка stop → read → send не дойдёт.
    for (var i = 0; i < 10 && sent.isEmpty; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();

    expect(record.calls, containsAllInOrder(['start', 'stop', 'dispose']));
    expect(sent, hasLength(1));
    expect(sent.single.mimeType, 'audio/mp4');
    expect(sent.single.bytes, hasLength(64));
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets(
    'палец отпущен, пока шёл запрос доступа: запись не остаётся висеть',
    (tester) async {
      final sent = <PickedAttachment>[];
      record.permission = Completer<bool>();
      await tester.pumpWidget(composer(sent));

      final hold = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.mic_none)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      // Системный запрос доступа ещё открыт — человек отпускает палец,
      // чтобы нажать «Разрешить».
      await hold.up();
      await tester.pump();
      expect(record.calls, isNot(contains('stop')));

      record.permission!.complete(true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(record.calls, containsAllInOrder(['start', 'stop', 'dispose']));
      expect(sent, isEmpty);
      expect(find.byIcon(Icons.stop_circle), findsNothing);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    },
  );

  testWidgets('короткий тап по микрофону подсказывает удерживать', (
    tester,
  ) async {
    await tester.pumpWidget(composer([]));
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    expect(find.text('Hold to record'), findsOneWidget);
    expect(record.calls, isEmpty);
  });
}
