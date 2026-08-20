import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/push/push_token_status.dart';
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
          ({
            required bool showMessagePreview,
            bool? sendReadReceipts,
            bool? discoverable,
            String? whoCanMessageMe,
            bool? showCardsOnCall,
            bool? presenceHidden,
          }) async {},
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
          ({
            required bool showMessagePreview,
            bool? sendReadReceipts,
            bool? discoverable,
            String? whoCanMessageMe,
            bool? showCardsOnCall,
            bool? presenceHidden,
          }) async {
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

  testWidgets(
    'TASK55 итер.3: toggle «показывать, когда я в сети» шлёт '
    'presenceHidden с инверсией',
    (tester) async {
      final sent = <bool?>[];
      final settings = NsgMessengerSettings.attachWithRpcs(
        // presenceHidden=false на сервере → toggle включён.
        getRpc: () async => NotificationSettings(
          showMessagePreview: true,
          presenceHidden: false,
        ),
        setRpc:
            ({
              required bool showMessagePreview,
              bool? sendReadReceipts,
              bool? discoverable,
              String? whoCanMessageMe,
              bool? showCardsOnCall,
              bool? presenceHidden,
            }) async {
              sent.add(presenceHidden);
            },
      );
      await tester.pumpWidget(
        wrapL10n(NotificationSettingsScreen(settingsOverride: settings)),
      );
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('presenceVisibleToggle'));
      await tester.scrollUntilVisible(toggle, 200);
      expect(
        tester.widget<SwitchListTile>(toggle).value,
        isTrue,
        reason: 'hidden=false → «показывать» включён',
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(sent, [true], reason: 'выключил показ → hidden=true');
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    },
  );

  testWidgets('toggle RPC fail → revert + snackbar', (tester) async {
    final settings = NsgMessengerSettings.attachWithRpcs(
      getRpc: () async => NotificationSettings(showMessagePreview: true),
      setRpc:
          ({
            required bool showMessagePreview,
            bool? sendReadReceipts,
            bool? discoverable,
            String? whoCanMessageMe,
            bool? showCardsOnCall,
            bool? presenceHidden,
          }) async => throw StateError('network'),
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

  /// **Issue #86**: экран настроек уведомлений — единственное место, куда
  /// человек приходит с вопросом «почему мне ничего не приходит». До
  /// issue #86 он находил здесь исправно настроенные тумблеры и ни слова
  /// о том, что пуш-токен так и не был получен.
  group('issue #86 — состояние доставки пушей на экране', () {
    NsgMessengerSettings buildSettings() => NsgMessengerSettings.attachWithRpcs(
      getRpc: () async => NotificationSettings(showMessagePreview: true),
      setRpc:
          ({
            required bool showMessagePreview,
            bool? sendReadReceipts,
            bool? discoverable,
            String? whoCanMessageMe,
            bool? showCardsOnCall,
            bool? presenceHidden,
          }) async {},
    );

    Future<void> pumpScreen(
      WidgetTester tester,
      PushTokenStatus status, {
      VoidCallback? onOpenSystemSettings,
    }) async {
      await tester.pumpWidget(
        wrapL10n(
          NotificationSettingsScreen(
            settingsOverride: buildSettings(),
            onOpenSystemSettings: onOpenSystemSettings,
            initialPushStatusOverride: status,
            pushStatusOverride: const Stream<PushTokenStatus>.empty(),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('токен не пришёл → экран говорит об этом первым делом', (
      tester,
    ) async {
      await pumpScreen(tester, PushTokenStatus.tokenUnavailable);
      expect(find.byKey(const Key('pushStatusNotice')), findsOneWidget);
      expect(find.text('Уведомления не подключены'), findsOneWidget);
    });

    testWidgets('разрешение не выдано → есть кнопка в системные настройки', (
      tester,
    ) async {
      var taps = 0;
      await pumpScreen(
        tester,
        PushTokenStatus.permissionDenied,
        onOpenSystemSettings: () => taps++,
      );
      await tester.tap(find.byKey(const Key('pushStatusOpenSettings')));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('пуши работают → экран как раньше, лишнего блока нет', (
      tester,
    ) async {
      await pumpScreen(tester, PushTokenStatus.ready);
      expect(find.byKey(const Key('pushStatusNotice')), findsNothing);
      expect(find.byType(SwitchListTile), findsWidgets);
    });
  });
}
