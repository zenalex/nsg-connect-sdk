/// **Непрочитанное в строке задачи** (issue #113).
///
/// Просьба оператора дословно: «наклейки на чатах и задачах есть, а чатов и
/// задач с непрочитанными сообщениями нет». Бейдж стадии отвечает на вопрос
/// «что с задачей», а не «есть ли там новое для меня» — и без второго ответа
/// задачи открывают по очереди, чтобы это выяснить.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/widgets/unread_pill.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('есть непрочитанное — число стоит ПЕРЕД стадией', (t) async {
    // Порядок не косметика: счётчик про «сейчас», и глаз должен цеплять его
    // первым. Стадия отвечает на другой вопрос и никуда не денется.
    await t.pumpWidget(
      _host(
        const UnreadThenStage(
          unreadCount: 3,
          stage: Text('В работе'),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(
      t.getTopLeft(find.text('3')).dx,
      lessThan(t.getTopLeft(find.text('В работе')).dx),
    );
  });

  testWidgets('нечего читать — пилюли нет вовсе', (t) async {
    // Пустой кружок читается как значок, и список прочитанных задач выглядел
    // бы засыпанным метками.
    await t.pumpWidget(
      _host(
        const UnreadThenStage(unreadCount: 0, stage: Text('Принято')),
      ),
    );
    expect(find.byType(UnreadPill), findsNothing);
    expect(find.text('Принято'), findsOneWidget);
  });

  testWidgets('сотня и больше — «99+», иначе хвост строки разъедется', (
    t,
  ) async {
    await t.pumpWidget(_host(const UnreadPill(count: 150)));
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('отрицательное не рисуем', (t) async {
    // Арифметика счётчиков на клиенте в минус уже заезжала (см. границу
    // прочитанного); «-2» в кружке было бы хуже отсутствия кружка.
    await t.pumpWidget(_host(const UnreadPill(count: -2)));
    expect(find.byType(Container), findsNothing);
  });
}
