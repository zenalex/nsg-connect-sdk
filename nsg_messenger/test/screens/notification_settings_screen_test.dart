import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/screens/notification_settings_screen.dart';
import 'package:nsg_messenger/src/settings/nsg_messenger_settings.dart';

import '../test_helpers.dart';

/// **TASK20-Phase2 Chunk 4**: widget tests для [NotificationSettingsScreen].
void main() {
  testWidgets('initial load → Switch отражает фактическое значение', (
    tester,
  ) async {
    final settings = NsgMessengerSettings.attachWithRpcs(
      getRpc: () async => NotificationSettings(showMessagePreview: false),
      setRpc:
          ({required bool showMessagePreview, bool? sendReadReceipts}) async {},
    );
    await tester.pumpWidget(
      wrapL10n(NotificationSettingsScreen(settingsOverride: settings)),
    );
    await tester.pumpAndSettle();
    final tile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile).first,
    );
    expect(tile.value, isFalse);
  });

  testWidgets('toggle → optimistic update + RPC called', (tester) async {
    final calls = <bool>[];
    final settings = NsgMessengerSettings.attachWithRpcs(
      getRpc: () async => NotificationSettings(showMessagePreview: true),
      setRpc:
          ({required bool showMessagePreview, bool? sendReadReceipts}) async {
            calls.add(showMessagePreview);
          },
    );
    await tester.pumpWidget(
      wrapL10n(NotificationSettingsScreen(settingsOverride: settings)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(calls, [false]);
    final tile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile).first,
    );
    expect(tile.value, isFalse);
  });

  testWidgets('toggle RPC fail → revert + snackbar', (tester) async {
    final settings = NsgMessengerSettings.attachWithRpcs(
      getRpc: () async => NotificationSettings(showMessagePreview: true),
      setRpc:
          ({required bool showMessagePreview, bool? sendReadReceipts}) async =>
              throw StateError('network'),
    );
    await tester.pumpWidget(
      wrapL10n(NotificationSettingsScreen(settingsOverride: settings)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump(); // optimistic update fired
    await tester.pumpAndSettle(); // RPC throws → revert
    final tile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile).first,
    );
    expect(tile.value, isTrue, reason: 'reverted to original');
    expect(find.textContaining("Couldn't save"), findsOneWidget);
  });
}
