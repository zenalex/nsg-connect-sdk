import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **TASK20 followup (a)**: widget-тесты [ConnectionStateIndicator].
/// Используем `stateOverride` чтобы не поднимать [MessengerRuntime].
void main() {
  /// Helper: smallest reasonable MaterialApp wrapper.
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  /// Helper: pull color of the rendered circle (the Container inside
  /// the Tooltip → Padding → InkResponse? → Container chain).
  Color? readCircleColor(WidgetTester tester) {
    final ctn = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ConnectionStateIndicator),
            matching: find.byType(Container),
          )
          .first,
    );
    final dec = ctn.decoration as BoxDecoration?;
    return dec?.color;
  }

  testWidgets('initial render → зелёный круг (healthy)', (tester) async {
    final ctl = StreamController<MessengerConnectionState>.broadcast();
    await tester.pumpWidget(
      wrap(
        ConnectionStateIndicator(
          stateOverride: ctl.stream,
          initialStateOverride: MessengerConnectionState.healthy,
        ),
      ),
    );
    expect(readCircleColor(tester), Colors.green);
    await ctl.close();
  });

  testWidgets('stream emit reconnecting → жёлтый круг (amber)', (tester) async {
    final ctl = StreamController<MessengerConnectionState>.broadcast();
    await tester.pumpWidget(
      wrap(
        ConnectionStateIndicator(
          stateOverride: ctl.stream,
          initialStateOverride: MessengerConnectionState.healthy,
        ),
      ),
    );
    ctl.add(MessengerConnectionState.reconnecting);
    await tester.pump();
    expect(readCircleColor(tester), Colors.amber);
    await ctl.close();
  });

  testWidgets('stream emit disconnected → красный круг', (tester) async {
    final ctl = StreamController<MessengerConnectionState>.broadcast();
    await tester.pumpWidget(
      wrap(
        ConnectionStateIndicator(
          stateOverride: ctl.stream,
          initialStateOverride: MessengerConnectionState.healthy,
        ),
      ),
    );
    ctl.add(MessengerConnectionState.disconnected);
    await tester.pump();
    expect(readCircleColor(tester), Colors.red);
    await ctl.close();
  });

  testWidgets('onTap callback срабатывает при наличии', (tester) async {
    final ctl = StreamController<MessengerConnectionState>.broadcast();
    var tapCount = 0;
    await tester.pumpWidget(
      wrap(
        ConnectionStateIndicator(
          stateOverride: ctl.stream,
          initialStateOverride: MessengerConnectionState.disconnected,
          onTap: () => tapCount++,
        ),
      ),
    );
    await tester.tap(find.byType(ConnectionStateIndicator));
    await tester.pump();
    expect(tapCount, 1);
    await ctl.close();
  });

  testWidgets('без onTap — нет InkResponse-а (статичная иконка)', (
    tester,
  ) async {
    final ctl = StreamController<MessengerConnectionState>.broadcast();
    await tester.pumpWidget(
      wrap(
        ConnectionStateIndicator(
          stateOverride: ctl.stream,
          initialStateOverride: MessengerConnectionState.healthy,
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(ConnectionStateIndicator),
        matching: find.byType(InkResponse),
      ),
      findsNothing,
    );
    await ctl.close();
  });
}
