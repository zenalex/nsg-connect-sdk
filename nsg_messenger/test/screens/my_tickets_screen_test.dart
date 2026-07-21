import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/screens/my_tickets_screen.dart';
import 'package:nsg_messenger/src/support/my_tickets_rpc.dart';

/// **issue #19**: widget-тесты бейджа гранулярного статуса на экране
/// «Мои обращения». Проверяют, что `stage` (new/in_progress/accepted/rejected)
/// рендерится понятной русской подписью. RPC подменяется fake-ом (без
/// Serverpod-клиента), навигация в чат заглушена через `onOpenRoom`.
void main() {
  final now = DateTime.utc(2026, 7, 8);

  TicketView ticket(int id, {required String stage, String status = 'open'}) =>
      TicketView(
        id: id,
        kind: 'bug',
        status: status,
        stage: stage,
        roomId: 100 + id,
        createdAt: now,
        updatedAt: now,
      );

  Future<void> pump(WidgetTester tester, List<TicketView> tickets) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyTicketsScreen(
          rpcOverride: _FakeRpc(tickets),
          onOpenRoom: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('каждый stage рендерит свою подпись', (tester) async {
    await pump(tester, [
      ticket(1, stage: 'new'),
      ticket(2, stage: 'in_progress'),
      ticket(3, stage: 'accepted', status: 'closed'),
      ticket(4, stage: 'rejected', status: 'closed'),
    ]);

    expect(find.text('Новое'), findsOneWidget);
    expect(find.text('В работе'), findsOneWidget);
    expect(find.text('Принято'), findsOneWidget);
    expect(find.text('Отклонено'), findsOneWidget);
  });

  testWidgets('неизвестный stage → безопасный дефолт «Новое»', (tester) async {
    await pump(tester, [ticket(1, stage: 'something_new_from_server')]);
    expect(find.text('Новое'), findsOneWidget);
  });
}

class _FakeRpc implements MyTicketsRpc {
  _FakeRpc(this.list);

  final List<TicketView> list;

  @override
  Future<List<TicketView>> listMyTickets() async => list;
}
