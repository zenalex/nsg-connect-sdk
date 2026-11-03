import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_drop_target.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';

/// #225: файл, брошенный в окно, прикреплялся во ВСЕ открытые чаты — они
/// живут друг под другом (keep-alive), и у скрытых та же геометрия.
void main() {
  /// Имитация броска так, как его шлёт нативная часть `desktop_drop`.
  Future<void> drop(WidgetTester tester, Offset at, String path) async {
    const codec = StandardMethodCodec();
    Future<void> send(String method, Object args) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'desktop_drop',
          codec.encodeMethodCall(MethodCall(method, args)),
          (_) {},
        );
    await send('entered', [at.dx, at.dy]);
    await send('updated', [at.dx, at.dy]);
    await send('performOperation', [path]);
    await tester.pump();
  }

  testWidgets('файл попадает только в видимый чат, не в скрытые под ним', (
    tester,
  ) async {
    if (!attachmentDropSupported) return; // только desktop.
    final dir = Directory.systemTemp.createTempSync('drop225');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}${Platform.pathSeparator}a.txt')
      ..writeAsStringSync('hello');

    final got = <int, List<AttachmentCandidate>>{};
    AttachmentDropSink sinkFor(int i) =>
        AttachmentDropSink()..onFiles = (files) async => got[i] = files;
    final sinks = [sinkFor(0), sinkFor(1), sinkFor(2)];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: IndexedStack(
          index: 1,
          children: [
            for (var i = 0; i < 3; i++)
              AttachmentDropTarget(
                sink: sinks[i],
                child: SizedBox.expand(child: Text('chat $i')),
              ),
          ],
        ),
      ),
    );

    await tester.runAsync(() async {
      await drop(tester, const Offset(100, 100), file.path);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(got.keys, [1]);
    expect(got[1]!.single.name, 'a.txt');
  });
}
