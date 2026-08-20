/// **Квитанция на корень треда** (issue #112).
///
/// Лента треда всегда заканчивается якорем (сервер дописывает его в конец
/// последней страницы), а у задачи БЕЗ ответов он там единственный — то
/// есть «новейшее сообщение треда», которое [ThreadScreen] и помечает
/// прочитанным. Отправленная при этом квитанция несла `thread_id`, равный
/// самому событию, и Matrix отвечал `400 is not related to thread`.
///
/// Цена отказа непропорциональна: сервер на нём прекращает весь markRead,
/// поэтому счётчик комнаты не обнуляется вообще. На проде так набежало 40
/// непрочитанных в чате поддержки, который читают каждый день, — а лента
/// при открытии вставала по этому счётчику далеко в истории.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

void main() {
  MessagesController make({String? threadRoot}) => MessagesController(
    roomId: 7,
    rpc: _FakeRpc(),
    events: const Stream<MessengerEvent>.empty(),
    selfMessengerUserId: 1,
    selfMatrixUserId: '@self:l',
    threadRootEventId: threadRoot,
  );

  test('корень треда помечается БЕЗ thread_id', () async {
    final c = make(threadRoot: r'$root');
    addTearDown(c.dispose);
    expect(c.receiptThreadRootFor(r'$root'), isNull);
  });

  test('реплика треда несёт корень — иначе в треде не «прочитано»', () async {
    // Обратная половина: убрать thread_id совсем нельзя, тогда прочтение
    // засчитается основной ленте, а галочка в треде не посинеет.
    final c = make(threadRoot: r'$root');
    addTearDown(c.dispose);
    expect(c.receiptThreadRootFor(r'$reply'), r'$root');
  });

  test('вне треда корня нет', () async {
    final c = make();
    addTearDown(c.dispose);
    expect(c.receiptThreadRootFor(r'$any'), isNull);
  });

  test('markRead отправляет то же, что решил receiptThreadRootFor', () async {
    // Связка проверяется отдельно: правило можно посчитать верно и всё
    // равно послать в RPC старое поле.
    final rpc = _FakeRpc();
    final c = MessagesController(
      roomId: 7,
      rpc: rpc,
      events: const Stream<MessengerEvent>.empty(),
      selfMessengerUserId: 1,
      selfMatrixUserId: '@self:l',
      threadRootEventId: r'$root',
    );
    addTearDown(c.dispose);

    await c.markRead(r'$root');
    await c.markRead(r'$reply');

    expect(rpc.calls, [
      (event: r'$root', root: null),
      (event: r'$reply', root: r'$root'),
    ]);
  });
}

class _FakeRpc implements MessagesRpc {
  final calls = <({String event, String? root})>[];

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async {
    calls.add((event: matrixEventId, root: threadRootEventId));
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeRpc: ${invocation.memberName}');
}
