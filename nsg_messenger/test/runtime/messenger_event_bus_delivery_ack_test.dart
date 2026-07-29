/// **issue #78**: шина событий — единственное место, где видно КАЖДОЕ
/// пришедшее сообщение, поэтому подтверждение доставки живёт там же.
/// Здесь проверяется стык: что дошло до шины — то и подтверждается,
/// ровно один раз.
library;

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/delivery_ack_sender.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

void main() {
  var counter = 0;
  MessengerEvent message({String? eventId}) {
    counter++;
    return MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: DateTime.now().toUtc(),
      roomId: 1,
      matrixRoomId: '!r:t',
      message: MessengerMessage(
        matrixEventId: eventId ?? '\$ev-$counter',
        roomId: 1,
        matrixRoomId: '!r:t',
        senderMatrixUserId: '@bob:t',
        msgType: 'm.text',
        body: 'привет',
        serverTimestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Не-сообщение: подтверждать нечего, ожидания по нему сервер не
  /// заводил.
  MessengerEvent typing() => MessengerEvent(
    eventType: MessengerEventType.typingChanged,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: 1,
    matrixRoomId: '!r:t',
  );

  Future<
    ({
      MessengerEventBus bus,
      StreamController<MessengerEvent> upstream,
      StreamSubscription<MessengerEvent> sub,
      List<String> confirmed,
      Future<void> Function() close,
    })
  >
  boot({AppLifecycleState lifecycle = AppLifecycleState.resumed}) async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final confirmed = <String>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
      deliveryAckSender: DeliveryAckSender(
        confirmDelivery: ({required List<String> matrixEventIds}) async {
          confirmed.addAll(matrixEventIds);
        },
        debounce: const Duration(milliseconds: 10),
        lifecycleProbe: () => lifecycle,
      ),
    );
    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    return (
      bus: bus,
      upstream: upstream,
      sub: sub,
      confirmed: confirmed,
      close: () async {
        await sub.cancel();
        await bus.dispose();
        await upstream.close();
        await stateCtl.close();
      },
    );
  }

  test('пришедшее сообщение подтверждается', () async {
    final h = await boot();
    h.upstream.add(message(eventId: '\$one'));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(h.confirmed, ['\$one']);
    await h.close();
  });

  test('дубль от сервера подтверждается один раз', () async {
    // После реконнекта сервер может пере-доставить уже виденное
    // событие; подтверждение стоит ПОСЛЕ дедупа.
    final h = await boot();
    h.upstream
      ..add(message(eventId: '\$dup'))
      ..add(message(eventId: '\$dup'));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(h.confirmed, ['\$dup']);
    await h.close();
  });

  test('не-сообщения не подтверждаются', () async {
    final h = await boot();
    h.upstream.add(typing());
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(h.confirmed, isEmpty);
    await h.close();
  });

  test('свёрнутое приложение не подтверждает', () async {
    final h = await boot(lifecycle: AppLifecycleState.hidden);
    h.upstream.add(message(eventId: '\$bg'));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(h.confirmed, isEmpty, reason: 'человек не видел — нужен пуш');
    await h.close();
  });
}
