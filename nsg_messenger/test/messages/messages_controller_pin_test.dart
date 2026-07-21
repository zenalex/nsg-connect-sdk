import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

/// **Issue #35 — закрепление сообщений.** Тесты плашки закреплённых в
/// [MessagesController]: seed при открытии, pin/unpin (RPC + reload),
/// realtime `pinnedMessagesChanged` (reload + дедуп эха).
void main() {
  const roomId = 7;

  MessengerMessage msg(String eventId, {String body = 'body'}) =>
      MessengerMessage(
        matrixEventId: eventId,
        roomId: roomId,
        matrixRoomId: '!r:test',
        senderMessengerUserId: 99,
        senderMatrixUserId: '@peer:test',
        msgType: 'm.text',
        body: body,
        serverTimestamp: DateTime.utc(2026, 1, 1),
      );

  MessagesController make(_PinFakeRpc rpc, Stream<MessengerEvent> events) =>
      MessagesController(
        roomId: roomId,
        rpc: rpc,
        events: events,
        selfMessengerUserId: 42,
        selfMatrixUserId: '@self:test',
      );

  test('init seeds закреплённые → pinnedMessages + isPinned', () async {
    final rpc = _PinFakeRpc()..pinnedResult = [msg('\$a'), msg('\$b')];
    final ctrl = make(rpc, const Stream.empty());
    await ctrl.init();
    // loadPinned — unawaited в init; дать микротаскам отработать.
    await Future<void>.delayed(Duration.zero);

    expect(rpc.listPinnedCalls, greaterThanOrEqualTo(1));
    expect(ctrl.pinnedMessages.map((m) => m.matrixEventId), ['\$a', '\$b']);
    expect(ctrl.isPinned('\$a'), isTrue);
    expect(ctrl.isPinned('\$b'), isTrue);
    expect(ctrl.isPinned('\$zzz'), isFalse);
    await ctrl.dispose();
  });

  test('pinMessage → RPC вызван + плашка перечитана', () async {
    final rpc = _PinFakeRpc();
    final ctrl = make(rpc, const Stream.empty());
    await ctrl.init();
    await Future<void>.delayed(Duration.zero);

    // После pin сервер вернёт закреплённое → listPinnedMessages его отдаст.
    rpc.pinnedResult = [msg('\$pinned')];
    await ctrl.pinMessage('\$pinned');

    expect(rpc.pinnedCalls, ['\$pinned']);
    expect(ctrl.isPinned('\$pinned'), isTrue);
    expect(ctrl.pinnedMessages.single.matrixEventId, '\$pinned');
    await ctrl.dispose();
  });

  test('unpinMessage → RPC вызван + плашка перечитана (пусто)', () async {
    final rpc = _PinFakeRpc()..pinnedResult = [msg('\$x')];
    final ctrl = make(rpc, const Stream.empty());
    await ctrl.init();
    await Future<void>.delayed(Duration.zero);
    expect(ctrl.isPinned('\$x'), isTrue);

    rpc.pinnedResult = const <MessengerMessage>[]; // после unpin — пусто
    await ctrl.unpinMessage('\$x');

    expect(rpc.unpinnedCalls, ['\$x']);
    expect(ctrl.pinnedMessages, isEmpty);
    expect(ctrl.isPinned('\$x'), isFalse);
    await ctrl.dispose();
  });

  test('pinnedMessagesChanged с НОВЫМ набором → reload плашки', () async {
    final rpc = _PinFakeRpc();
    final events = StreamController<MessengerEvent>.broadcast();
    final ctrl = make(rpc, events.stream);
    await ctrl.init();
    await Future<void>.delayed(Duration.zero);
    final callsAfterInit = rpc.listPinnedCalls;

    // Другое устройство закрепило — сервер потом отдаст это через list.
    rpc.pinnedResult = [msg('\$new')];
    events.add(
      MessengerEvent(
        eventType: MessengerEventType.pinnedMessagesChanged,
        serverTimestamp: DateTime.utc(2026, 1, 2),
        roomId: roomId,
        matrixRoomId: '!r:test',
        pinnedEventIds: ['\$new'],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(rpc.listPinnedCalls, greaterThan(callsAfterInit));
    expect(ctrl.isPinned('\$new'), isTrue);
    await ctrl.dispose();
    await events.close();
  });

  test('pinnedMessagesChanged с ТЕМ ЖЕ набором (эхо) → без лишнего reload',
      () async {
    final rpc = _PinFakeRpc()..pinnedResult = [msg('\$a')];
    final events = StreamController<MessengerEvent>.broadcast();
    final ctrl = make(rpc, events.stream);
    await ctrl.init();
    await Future<void>.delayed(Duration.zero);
    final callsAfterInit = rpc.listPinnedCalls;

    // Эхо собственного pin: набор совпадает с уже загруженным → no-op.
    events.add(
      MessengerEvent(
        eventType: MessengerEventType.pinnedMessagesChanged,
        serverTimestamp: DateTime.utc(2026, 1, 2),
        roomId: roomId,
        matrixRoomId: '!r:test',
        pinnedEventIds: ['\$a'],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(rpc.listPinnedCalls, callsAfterInit, reason: 'эхо не должно reload-ить');
    await ctrl.dispose();
    await events.close();
  });

  test('событие другой комнаты игнорируется', () async {
    final rpc = _PinFakeRpc();
    final events = StreamController<MessengerEvent>.broadcast();
    final ctrl = make(rpc, events.stream);
    await ctrl.init();
    await Future<void>.delayed(Duration.zero);
    final callsAfterInit = rpc.listPinnedCalls;

    events.add(
      MessengerEvent(
        eventType: MessengerEventType.pinnedMessagesChanged,
        serverTimestamp: DateTime.utc(2026, 1, 2),
        roomId: roomId + 1, // чужая комната
        matrixRoomId: '!other:test',
        pinnedEventIds: ['\$x'],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(rpc.listPinnedCalls, callsAfterInit);
    await ctrl.dispose();
    await events.close();
  });
}

/// Fake [MessagesRpc] — noSuchMethod для неиспользуемых методов; явно
/// реализованы вызываемые в init + pin/unpin с захватом.
class _PinFakeRpc implements MessagesRpc {
  List<MessengerMessage> pinnedResult = const <MessengerMessage>[];
  int listPinnedCalls = 0;
  final List<String> pinnedCalls = <String>[];
  final List<String> unpinnedCalls = <String>[];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(
    messages: const <MessengerMessage>[],
    nextToken: null,
    prevToken: null,
  );

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({required int roomId}) async {
    listPinnedCalls += 1;
    return pinnedResult;
  }

  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async {
    pinnedCalls.add(matrixEventId);
    return pinnedResult.map((m) => m.matrixEventId).toList(growable: false);
  }

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async {
    unpinnedCalls.add(matrixEventId);
    return pinnedResult.map((m) => m.matrixEventId).toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
