import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/support/my_tickets_controller.dart';
import 'package:nsg_messenger/src/support/my_tickets_rpc.dart';
import 'package:nsg_messenger/src/support/my_tickets_state.dart';

/// **TASK57 фаза 1**: unit-тесты [MyTicketsController] с hand-written fake RPC.
void main() {
  final now = DateTime.utc(2026, 7, 8);
  TicketView ticket(
    int id, {
    String status = 'open',
    String stage = 'new',
    String kind = 'bug',
  }) => TicketView(
    id: id,
    kind: kind,
    status: status,
    stage: stage,
    roomId: 100 + id,
    createdAt: now,
    updatedAt: now,
  );

  test('init: успех → Ready со списком тикетов', () async {
    final c = MyTicketsController(
      rpc: _FakeRpc(
        list: [
          ticket(1),
          ticket(2, status: 'closed'),
        ],
      ),
    );
    await c.init();
    final s = c.state;
    expect(s, isA<MyTicketsReady>());
    expect((s as MyTicketsReady).tickets.length, 2);
  });

  test('init: пустой список → Ready(empty)', () async {
    final c = MyTicketsController(rpc: _FakeRpc(list: const []));
    await c.init();
    expect((c.state as MyTicketsReady).tickets, isEmpty);
  });

  test('init: ошибка → Unavailable', () async {
    final c = MyTicketsController(rpc: _FakeRpc(error: StateError('boom')));
    await c.init();
    expect(c.state, isA<MyTicketsUnavailable>());
  });

  test('refresh перечитывает список', () async {
    final rpc = _FakeRpc(list: [ticket(1)]);
    final c = MyTicketsController(rpc: rpc);
    await c.init();
    rpc.list = [ticket(1), ticket(2)];
    await c.refresh();
    expect((c.state as MyTicketsReady).tickets.length, 2);
  });
}

class _FakeRpc implements MyTicketsRpc {
  _FakeRpc({this.list = const [], this.error});

  List<TicketView> list;
  final Object? error;

  @override
  Future<List<TicketView>> listMyTickets() async {
    if (error != null) throw error!;
    return list;
  }
}
