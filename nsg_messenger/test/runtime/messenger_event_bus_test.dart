import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// Тесты [MessengerEventBus]: lazy lifecycle, fan-out на нескольких
/// listener-ов, re-subscribe при `refreshing → active`, dispose.
void main() {
  // Helper — собрать MessengerEvent для msg-create. Use incremental
  // counter to ensure unique matrixEventId per call (microseconds-clock
  // одного теста на быстрой машине может выдавать одинаковый
  // timestamp двум подряд событиям).
  var eventCounter = 0;
  MessengerEvent makeEvent({int roomId = 1, String body = 'hi'}) {
    eventCounter++;
    return MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: DateTime.now().toUtc(),
      roomId: roomId,
      matrixRoomId: '!fake:localhost',
      message: MessengerMessage(
        matrixEventId: '\$ev-$eventCounter',
        roomId: roomId,
        matrixRoomId: '!fake:localhost',
        senderMatrixUserId: '@bob:localhost',
        msgType: 'm.text',
        body: body,
        serverTimestamp: DateTime.now().toUtc(),
      ),
    );
  }

  test('lazy: без listener-ов factory не вызывается', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var factoryCalls = 0;
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        return const Stream<MessengerEvent>.empty();
      },
      sessionStateStream: stateCtl.stream,
    );
    // Ждём микротаски — bus listens на state-stream сразу.
    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 0, reason: 'factory не должна вызваться без listener');
    await bus.dispose();
    await stateCtl.close();
  });

  test('первый listener triggers underlying subscription', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    var factoryCalls = 0;
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        return upstream.stream;
      },
      sessionStateStream: stateCtl.stream,
    );

    final received = <MessengerEvent>[];
    final sub = bus.events.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 1);

    upstream.add(makeEvent(roomId: 5, body: 'hello'));
    await Future<void>.delayed(Duration.zero);
    expect(received.length, 1);
    expect(received.first.roomId, 5);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('fan-out: один upstream event → все listeners получают', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final receivedA = <MessengerEvent>[];
    final receivedB = <MessengerEvent>[];
    final subA = bus.events.listen(receivedA.add);
    final subB = bus.events.listen(receivedB.add);
    await Future<void>.delayed(Duration.zero);

    upstream.add(makeEvent(body: 'x'));
    await Future<void>.delayed(Duration.zero);
    expect(receivedA.length, 1);
    expect(receivedB.length, 1);

    await subA.cancel();
    await subB.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('последний cancel → underlying cancelled (lazy)', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var factoryCalls = 0;
    final upstreams = <StreamController<MessengerEvent>>[];
    // Production-семантика: каждый вызов `client.messenger.userEventStream()`
    // создаёт новую серверную подписку. Здесь — новый StreamController
    // на каждый factory-call.
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        final c = StreamController<MessengerEvent>();
        upstreams.add(c);
        return c.stream;
      },
      sessionStateStream: stateCtl.stream,
    );

    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 1);
    expect(upstreams.first.hasListener, isTrue);

    await sub.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(upstreams.first.hasListener, isFalse);

    // Вторая подписка — re-subscribe (factory вызывается ещё раз).
    final sub2 = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 2);
    expect(upstreams.last.hasListener, isTrue);

    await sub2.cancel();
    await bus.dispose();
    for (final u in upstreams) {
      await u.close();
    }
    await stateCtl.close();
  });

  test('re-subscribe при refreshing → active с активным listener-ом', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var factoryCalls = 0;
    StreamController<MessengerEvent>? currentUpstream;
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        currentUpstream = StreamController<MessengerEvent>.broadcast();
        return currentUpstream!.stream;
      },
      sessionStateStream: stateCtl.stream,
    );

    final received = <MessengerEvent>[];
    final sub = bus.events.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 1);

    // Эмулируем proactive refresh: refreshing → active.
    stateCtl.add(MessengerSessionState.refreshing);
    await Future<void>.delayed(Duration.zero);
    // Underlying cancelled
    stateCtl.add(MessengerSessionState.active);
    await Future<void>.delayed(Duration.zero);
    expect(
      factoryCalls,
      2,
      reason: 'после active с активным listener — re-subscribe',
    );

    // Новый upstream должен дойти listener-у.
    currentUpstream!.add(makeEvent(body: 'after-refresh'));
    await Future<void>.delayed(Duration.zero);
    expect(received.length, 1);
    expect(received.first.message?.body, 'after-refresh');

    await sub.cancel();
    await bus.dispose();
    await currentUpstream!.close();
    await stateCtl.close();
  });

  test('expired без listener-ов → re-subscribe не происходит', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var factoryCalls = 0;
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        return const Stream<MessengerEvent>.empty();
      },
      sessionStateStream: stateCtl.stream,
    );
    stateCtl.add(MessengerSessionState.expired);
    stateCtl.add(MessengerSessionState.active);
    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 0, reason: 'нет listener-ов → нет re-subscribe');

    await bus.dispose();
    await stateCtl.close();
  });

  test(
    'upstream onError → onError callback fires, listeners НЕ видят error '
    '(TASK20 followup (a): bus swallows transport errors, переключается '
    'в reconnecting)',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final upstream = StreamController<MessengerEvent>.broadcast();
      Object? capturedByCallback;
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        sessionStateStream: stateCtl.stream,
        onError: (e, _) => capturedByCallback = e,
        // Очень короткий backoff чтобы тест не висел.
        reconnectBackoff: const [Duration(milliseconds: 1)],
      );

      Object? capturedByListener;
      final sub = bus.events.listen(
        (_) {},
        onError: (Object e) => capturedByListener = e,
      );
      await Future<void>.delayed(Duration.zero);

      upstream.addError(StateError('fake stream error'));
      await Future<void>.delayed(Duration.zero);
      // Callback всё ещё видит error (для ErrorReporter / log).
      expect(capturedByCallback, isA<StateError>());
      // Но listener-ы НЕ — transport layer handles silently.
      expect(
        capturedByListener,
        isNull,
        reason:
            'TASK20 followup (a): transport errors не пробрасываются consumers — '
            'они triggers reconnect, а не UI error state.',
      );

      await sub.cancel();
      await bus.dispose();
      await upstream.close();
      await stateCtl.close();
    },
  );

  test('dispose: idempotent, последующий events геттер не падает', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    await bus.dispose();
    await bus.dispose(); // idempotent
    await upstream.close();
    await stateCtl.close();
  });

  test('dedup по matrixEventId — повторный event отбрасывается', () async {
    // Закрытие TASK17 plan Q3: после reconnect-а на rotated token
    // upstream может пере-доставить уже виденные события. Bus
    // отбрасывает дубли по `message.matrixEventId`.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final received = <String?>[];
    final sub = bus.events.listen(
      (e) => received.add(e.message?.matrixEventId),
    );
    await Future<void>.delayed(Duration.zero);

    final ev1 = makeEvent(roomId: 1, body: 'one');
    upstream.add(ev1);
    upstream.add(ev1); // дубль с тем же matrixEventId
    final ev2 = makeEvent(roomId: 1, body: 'two');
    upstream.add(ev2);
    await Future<void>.delayed(Duration.zero);

    expect(received.length, 2, reason: 'дубль отброшен');
    expect(received.first, ev1.message!.matrixEventId);
    expect(received.last, ev2.message!.matrixEventId);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('events без matrixEventId НЕ дедуплицируются', () async {
    // State-events (membership / metadata) на TASK17 без надёжного
    // eventId-маркера; пропускаем без проверки. См. TASK17 Q3.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final received = <int?>[];
    final sub = bus.events.listen((e) => received.add(e.roomId));
    await Future<void>.delayed(Duration.zero);

    // Event без `message` — у него нет matrixEventId, dedup не применяется.
    final stateEv = MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: DateTime.now().toUtc(),
      roomId: 5,
      matrixRoomId: '!fake:localhost',
    );
    upstream.add(stateEv);
    upstream.add(stateEv);
    await Future<void>.delayed(Duration.zero);

    expect(received, [5, 5], reason: 'оба прошли (нет eventId для dedup)');

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  // ─── TASK20 Chunk 2: onAppLifecycleChanged ────────────────────────

  test('paused: cancel underlying sub + setPresence(foreground=false); '
      'listeners остаются', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final presenceCalls = <bool>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      setPresence: ({int? currentRoomId, required bool foreground}) async {
        presenceCalls.add(foreground);
      },
      sessionStateStream: stateCtl.stream,
    );

    final received = <String?>[];
    final sub = bus.events.listen((e) => received.add(e.message?.body));
    await Future<void>.delayed(Duration.zero);
    expect(upstream.hasListener, isTrue, reason: 'underlying sub active');

    bus.onAppLifecycleChanged(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);

    expect(
      upstream.hasListener,
      isFalse,
      reason: 'underlying sub cancelled при paused',
    );
    expect(presenceCalls, [false], reason: 'setPresence(foreground=false)');
    expect(bus.hasListeners, isTrue, reason: 'listener остаётся живым');

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('detached + hidden — same as paused', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final presenceCalls = <bool>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      setPresence: ({int? currentRoomId, required bool foreground}) async {
        presenceCalls.add(foreground);
      },
      sessionStateStream: stateCtl.stream,
    );
    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    bus.onAppLifecycleChanged(AppLifecycleState.detached);
    await Future<void>.delayed(Duration.zero);
    expect(upstream.hasListener, isFalse);
    expect(presenceCalls, [false]);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test(
    'inactive: no-op (no cancel, no setPresence) — короткое interruption',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final upstream = StreamController<MessengerEvent>.broadcast();
      final presenceCalls = <bool>[];
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        setPresence: ({int? currentRoomId, required bool foreground}) async {
          presenceCalls.add(foreground);
        },
        sessionStateStream: stateCtl.stream,
      );
      final sub = bus.events.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      bus.onAppLifecycleChanged(AppLifecycleState.inactive);
      await Future<void>.delayed(Duration.zero);
      expect(upstream.hasListener, isTrue, reason: 'inactive не cancel-ит sub');
      expect(presenceCalls, isEmpty, reason: 'no presence on inactive');

      await sub.cancel();
      await bus.dispose();
      await upstream.close();
      await stateCtl.close();
    },
  );

  test('paused → resumed: re-attach sub + setPresence(foreground=true) если '
      'есть listeners', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final presenceCalls = <bool>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      setPresence: ({int? currentRoomId, required bool foreground}) async {
        presenceCalls.add(foreground);
      },
      sessionStateStream: stateCtl.stream,
    );
    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    bus.onAppLifecycleChanged(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(upstream.hasListener, isFalse);
    bus.onAppLifecycleChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(upstream.hasListener, isTrue, reason: 're-attached');
    expect(presenceCalls, [false, true]);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test(
    'paused → resumed без listeners: НЕ re-attach (lazy preserved)',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final upstream = StreamController<MessengerEvent>.broadcast();
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        setPresence: ({int? currentRoomId, required bool foreground}) async {},
        sessionStateStream: stateCtl.stream,
      );
      final sub = bus.events.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      // Listener отписался ДО paused.
      await sub.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(
        upstream.hasListener,
        isFalse,
        reason: 'lazy stop on no-listeners',
      );

      bus.onAppLifecycleChanged(AppLifecycleState.paused);
      bus.onAppLifecycleChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(
        upstream.hasListener,
        isFalse,
        reason: 'resume без listeners — НЕ re-attach',
      );

      await bus.dispose();
      await upstream.close();
      await stateCtl.close();
    },
  );

  test('rapid paused→paused→resumed→resumed: idempotent', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final presenceCalls = <bool>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      setPresence: ({int? currentRoomId, required bool foreground}) async {
        presenceCalls.add(foreground);
      },
      sessionStateStream: stateCtl.stream,
    );
    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    // Двойной paused — второй no-op.
    bus.onAppLifecycleChanged(AppLifecycleState.paused);
    bus.onAppLifecycleChanged(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(presenceCalls, [false], reason: 'один paused emit');

    // Двойной resumed — второй no-op.
    bus.onAppLifecycleChanged(AppLifecycleState.resumed);
    bus.onAppLifecycleChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(presenceCalls, [false, true], reason: 'один resumed emit');

    expect(upstream.hasListener, isTrue);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test(
    'session.active во время bg НЕ re-attach (preserve battery suppression)',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final upstream = StreamController<MessengerEvent>.broadcast();
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        setPresence: ({int? currentRoomId, required bool foreground}) async {},
        sessionStateStream: stateCtl.stream,
      );
      final sub = bus.events.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      bus.onAppLifecycleChanged(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(upstream.hasListener, isFalse);

      // session refresh во время bg → state идёт refreshing → active.
      stateCtl.add(MessengerSessionState.refreshing);
      stateCtl.add(MessengerSessionState.active);
      await Future<void>.delayed(Duration.zero);

      expect(upstream.hasListener, isFalse, reason: 'не re-attach пока в bg');

      bus.onAppLifecycleChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(upstream.hasListener, isTrue);

      await sub.cancel();
      await bus.dispose();
      await upstream.close();
      await stateCtl.close();
    },
  );

  test('setPresence failure не throw-ит — fire-and-forget swallow', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final errors = <Object>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      setPresence: ({int? currentRoomId, required bool foreground}) async =>
          throw StateError('network down'),
      sessionStateStream: stateCtl.stream,
      onError: (e, st) => errors.add(e),
    );
    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    expect(
      () => bus.onAppLifecycleChanged(AppLifecycleState.paused),
      returnsNormally,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(errors.length, 1);
    expect(
      upstream.hasListener,
      isFalse,
      reason: 'underlying всё равно cancelled',
    );

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('null setPresence callback (тесты) — no-op', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      // setPresence: null — без аргумента.
      sessionStateStream: stateCtl.stream,
    );
    final sub = bus.events.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    expect(
      () => bus.onAppLifecycleChanged(AppLifecycleState.paused),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      upstream.hasListener,
      isFalse,
      reason: 'cancel всё равно отрабатывает',
    );

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('roomStream фильтрует events по roomId', () async {
    // Закрытие TASK17 Q2: один long-poll, локальная фильтрация.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final receivedFor5 = <String?>[];
    final sub = bus
        .roomStream(5)
        .listen((e) => receivedFor5.add(e.message?.body));
    await Future<void>.delayed(Duration.zero);

    upstream.add(makeEvent(roomId: 5, body: 'in room 5'));
    upstream.add(makeEvent(roomId: 7, body: 'in room 7'));
    upstream.add(makeEvent(roomId: 5, body: 'another in 5'));
    await Future<void>.delayed(Duration.zero);

    expect(receivedFor5, ['in room 5', 'another in 5']);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });
}
