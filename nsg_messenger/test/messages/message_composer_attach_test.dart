import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/attachments/attachment_picker.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

/// TASK19 Chunk 3: composer attach button widget tests.
/// Picker integration через image_picker (платформенный) — за scope
/// unit-тестов; cover только UI surface (button visibility, spinner
/// state, callback wiring).
void main() {
  Widget pumpComposer({
    required Future<void> Function(String) onSend,
    Future<void> Function(PickedAttachment)? onSendAttachment,
    bool enabled = true,
  }) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageComposer(
        onSend: (b, {mentionedMessengerUserIds}) => onSend(b),
        enabled: enabled,
        onSendAttachment: onSendAttachment,
      ),
    ),
  );

  testWidgets('attach button скрыт когда onSendAttachment == null', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(onSend: (_) async {}));
    expect(find.byIcon(Icons.attach_file), findsNothing);
  });

  testWidgets('attach button виден когда onSendAttachment != null', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpComposer(onSend: (_) async {}, onSendAttachment: (_) async {}),
    );
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
  });

  testWidgets('attach button disabled когда enabled=false', (tester) async {
    await tester.pumpWidget(
      pumpComposer(
        onSend: (_) async {},
        onSendAttachment: (_) async {},
        enabled: false,
      ),
    );
    final btn = find.ancestor(
      of: find.byIcon(Icons.attach_file),
      matching: find.byType(IconButton),
    );
    expect(btn, findsOneWidget);
    final iconBtn = tester.widget<IconButton>(btn);
    expect(iconBtn.onPressed, isNull, reason: 'disabled when not enabled');
  });
}
