import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/runtime/messenger_connection_state.dart';
import 'package:nsg_messenger/src/widgets/messenger_connection_banner.dart';

/// **TASK47 iter1**: баннер «нет сети». healthy → скрыт; reconnecting/
/// disconnected → виден.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(body: child),
  );

  const bannerKey = Key('messengerConnectionBanner');

  testWidgets('healthy → баннера нет', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MessengerConnectionBanner(
          initialStateOverride: MessengerConnectionState.healthy,
          stateOverride: Stream<MessengerConnectionState>.empty(),
        ),
      ),
    );
    expect(find.byKey(bannerKey), findsNothing);
  });

  testWidgets('disconnected → баннер виден', (tester) async {
    final ctrl = StreamController<MessengerConnectionState>.broadcast();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      wrap(
        MessengerConnectionBanner(
          initialStateOverride: MessengerConnectionState.disconnected,
          stateOverride: ctrl.stream,
        ),
      ),
    );
    expect(find.byKey(bannerKey), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reconnecting → баннер виден, затем healthy → скрыт', (
    tester,
  ) async {
    final ctrl = StreamController<MessengerConnectionState>.broadcast();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      wrap(
        MessengerConnectionBanner(
          initialStateOverride: MessengerConnectionState.reconnecting,
          stateOverride: ctrl.stream,
        ),
      ),
    );
    expect(find.byKey(bannerKey), findsOneWidget);

    ctrl.add(MessengerConnectionState.healthy);
    await tester.pump();
    expect(find.byKey(bannerKey), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
