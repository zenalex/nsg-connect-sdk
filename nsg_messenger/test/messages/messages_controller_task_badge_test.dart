import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';

/// **TASK87**: realtime-значок задачи. `MessagesController._onEvent` на
/// `taskBadgeUpdated` находит сообщение-носитель по `taskBadgeEventId` и
/// обновляет его значок (`taskStage`/`taskThreadRootEventId`/`taskUrl`), не
/// дожидаясь перезахода. Нет сообщения в памяти → no-op. Значок — состояние:
/// последнее событие побеждает (регистрация → сразу смена стадии).
void main() {
  const kRoom = 7;

  MessengerMessage seededMsg(String eventId) => MessengerMessage(
    matrixEventId: eventId,
    roomId: kRoom,
    matrixRoomId: '!r:t',
    senderMessengerUserId: 99,
    senderMatrixUserId: '@bot:t',
    msgType: 'm.text',
    body: 'завёл заявку #64',
    content: ByteData(0),
    serverTimestamp: DateTime.utc(2026, 1, 1),
  );

  MessengerEvent badgeEvent({
    required String carrierEventId,
    String? stage,
    String? threadRoot,
    String? url,
    int roomId = kRoom,
  }) => MessengerEvent(
    eventType: MessengerEventType.taskBadgeUpdated,
    serverTimestamp: DateTime.utc(2026, 1, 2),
    roomId: roomId,
    matrixRoomId: '!r:t',
    taskBadgeEventId: carrierEventId,
    taskStage: stage,
    taskThreadRootEventId: threadRoot,
    taskUrl: url,
  );

  Future<(MessagesController, StreamController<MessengerEvent>)> boot(
    List<MessengerMessage> seed,
  ) async {
    final rpc = _FakeRpc()
      ..listMessagesHandler = (_, _, _) =>
          Future.value(MessengerMessageListPage(messages: seed));
    final events = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: kRoom,
      rpc: rpc,
      events: events.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    await controller.init();
    return (controller, events);
  }

  test('taskBadgeUpdated обновляет значок сообщения-носителя в ленте', () async {
    final (controller, events) = await boot([seededMsg(r'$carrier')]);
    addTearDown(() async {
      await controller.dispose();
      await events.close();
    });

    // До события — значка нет.
    var msg = (controller.state as MessagesReady).messages.single;
    expect(msg.hasTaskBadge, isFalse);

    events.add(
      badgeEvent(
        carrierEventId: r'$carrier',
        stage: 'in_progress',
        threadRoot: r'$anchor',
        url: 'https://x/64',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    msg = (controller.state as MessagesReady).messages.single;
    expect(msg.hasTaskBadge, isTrue);
    expect(msg.taskStage, 'in_progress');
    expect(msg.taskThreadRootEventId, r'$anchor');
    expect(msg.taskUrl, 'https://x/64');
    // Остальное сообщение не тронуто.
    expect(msg.body, 'завёл заявку #64');
    expect(msg.matrixEventId, r'$carrier');
  });

  test('нет сообщения-носителя в памяти → no-op (не падает, ничего не меняет)',
      () async {
    final (controller, events) = await boot([seededMsg(r'$other')]);
    addTearDown(() async {
      await controller.dispose();
      await events.close();
    });

    events.add(
      badgeEvent(carrierEventId: r'$missing', stage: 'new', url: 'https://x/1'),
    );
    await Future<void>.delayed(Duration.zero);

    final msg = (controller.state as MessagesReady).messages.single;
    expect(msg.matrixEventId, r'$other');
    expect(msg.hasTaskBadge, isFalse);
  });

  test('перекраска new→accepted: последнее событие побеждает', () async {
    final (controller, events) = await boot([seededMsg(r'$carrier')]);
    addTearDown(() async {
      await controller.dispose();
      await events.close();
    });

    events.add(
      badgeEvent(carrierEventId: r'$carrier', stage: 'new', url: 'https://x/1'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      (controller.state as MessagesReady).messages.single.taskStage,
      'new',
    );

    events.add(
      badgeEvent(
        carrierEventId: r'$carrier',
        stage: 'accepted',
        url: 'https://x/1',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      (controller.state as MessagesReady).messages.single.taskStage,
      'accepted',
    );
  });

  test('событие для другой комнаты игнорируется', () async {
    final (controller, events) = await boot([seededMsg(r'$carrier')]);
    addTearDown(() async {
      await controller.dispose();
      await events.close();
    });

    events.add(
      badgeEvent(
        carrierEventId: r'$carrier',
        stage: 'accepted',
        url: 'https://x/1',
        roomId: 999, // чужая комната
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      (controller.state as MessagesReady).messages.single.hasTaskBadge,
      isFalse,
    );
  });
}

/// Компактный fake: замокан только load-путь (`listMessages`); остальное —
/// `noSuchMethod` (в этих тестах не вызывается).
class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) {
    final h = listMessagesHandler;
    if (h == null) throw StateError('listMessagesHandler not set');
    return h(roomId, fromToken, limit);
  }

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async => true;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'only load-path RPCs mocked (${invocation.memberName})',
  );
}
