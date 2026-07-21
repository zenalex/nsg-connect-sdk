import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/forward_picker_sheet.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

/// Пересылка (forward): пикер чата — показывает комнаты, фильтрует по имени,
/// возвращает выбранную комнату.
RoomSummary _room(int id, String name, {RoomType type = RoomType.direct}) =>
    RoomSummary(
      id: id,
      name: name,
      unreadCount: 0,
      archived: false,
      muted: false,
      roomType: type,
    );

void main() {
  setUpAll(registerTimeagoLocales);

  testWidgets('показывает комнаты, фильтрует, возвращает выбранную', (
    tester,
  ) async {
    final rooms = [
      _room(1, 'Alice'),
      _room(2, 'Bob team', type: RoomType.group),
    ];
    RoomSummary? picked;

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await showForwardPicker(
                context: context,
                roomsLoader: () async => rooms,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Обе комнаты видны.
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob team'), findsOneWidget);

    // Фильтр по имени.
    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsNothing);
    expect(find.text('Bob team'), findsOneWidget);

    // Выбор → возврат комнаты + закрытие листа.
    await tester.tap(find.text('Bob team'));
    await tester.pumpAndSettle();
    expect(picked?.id, 2);
  });

  testWidgets('пустой список → «No chats to forward to»', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showForwardPicker(
              context: context,
              roomsLoader: () async => const <RoomSummary>[],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('No chats to forward to'), findsOneWidget);
  });

  testWidgets('F1: мультивыбор — выбор двух чатов → список из двух', (
    tester,
  ) async {
    final rooms = [
      _room(1, 'Alice'),
      _room(2, 'Bob team', type: RoomType.group),
      _room(3, 'Carol'),
    ];
    List<RoomSummary>? picked;

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await showForwardPickerMulti(
                context: context,
                roomsLoader: () async => rooms,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Кнопка подтверждения дизейблена без выбора.
    final confirm = find.widgetWithText(FilledButton, 'Forward (0)');
    expect(confirm, findsOneWidget);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    // Отмечаем два чата.
    await tester.tap(find.text('Alice'));
    await tester.tap(find.text('Carol'));
    await tester.pumpAndSettle();

    // Лейбл кнопки отражает счётчик и стала активной.
    final confirm2 = find.widgetWithText(FilledButton, 'Forward (2)');
    expect(confirm2, findsOneWidget);
    await tester.tap(confirm2);
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.map((r) => r.id).toSet(), {1, 3});
  });
}
