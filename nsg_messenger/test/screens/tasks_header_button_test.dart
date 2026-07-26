import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart' show RoomTaskStats;
import 'package:nsg_messenger/src/screens/tasks_header_button.dart';

import '../test_helpers.dart';

/// **TASK88**: иконка задач в шапке комнаты. Видна только когда у комнаты есть
/// задачи (`total > 0`); при активных (`active > 0`) — бейдж с числом; нет
/// данных / нет задач → иконки нет (не пустой список по тапу).
void main() {
  Widget button(RoomTaskStats? stats, {VoidCallback? onTap}) => wrapL10n(
    TasksHeaderButton(stats: stats, onTap: onTap ?? () {}),
  );

  testWidgets('нет данных (null) → иконки нет', (tester) async {
    await tester.pumpWidget(button(null));
    expect(find.byKey(const Key('roomTasksButton')), findsNothing);
  });

  testWidgets('total == 0 → иконки нет', (tester) async {
    await tester.pumpWidget(button(RoomTaskStats(active: 0, total: 0)));
    expect(find.byKey(const Key('roomTasksButton')), findsNothing);
  });

  testWidgets('total > 0, active == 0 → иконка есть, бейджа с числом нет', (
    tester,
  ) async {
    await tester.pumpWidget(button(RoomTaskStats(active: 0, total: 3)));
    expect(find.byKey(const Key('roomTasksButton')), findsOneWidget);
    // Бейдж-число скрыт при active == 0.
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isFalse);
  });

  testWidgets('active > 0 → иконка + бейдж с числом активных', (tester) async {
    await tester.pumpWidget(button(RoomTaskStats(active: 2, total: 5)));
    expect(find.byKey(const Key('roomTasksButton')), findsOneWidget);
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('тап зовёт onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      button(RoomTaskStats(active: 1, total: 1), onTap: () => taps++),
    );
    await tester.tap(find.byKey(const Key('roomTasksButton')));
    await tester.pump();
    expect(taps, 1);
  });
}
