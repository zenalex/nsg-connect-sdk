import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **TASK20 followup (a)**: тесты auto-reconnect + connection-state
/// машины в [MessengerEventBus].
///
/// Стратегия: подсовываем `streamFactory` который выдаёт серию
/// streams (queue) и записываем сколько раз был вызван. Backoff
/// шортнен (1 мс) + RNG детерминистичный (`Random(0)`), чтобы тесты
/// шли быстро.
void main() {
  /// Helper: detect-only handshake — ждём пока завершатся все pending
  /// microtask-и и timer-ы. Дёргаем event-loop через `delayed`.
  Future<void> pumpAsync([int ms = 30]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// Удобный builder factory-возвращающего-стрим: каждая invocation
  /// pop-ит следующий controller из очереди (или re-uses last если очередь
  /// пустая). `factoryCalls` пробрасывается наружу.
  ({StreamFactory factory, List<StreamController<MessengerEvent>> controllers})
  makeQueueFactory(int slots) {
    final controllers = List.generate(
      slots,
      (_) => StreamController<MessengerEvent>.broadcast(),
    );
    var idx = 0;
    Stream<MessengerEvent> factory() {
      final ctl = controllers[idx < slots ? idx : slots - 1];
      idx++;
      return ctl.stream;
    }

    return (factory: factory, controllers: controllers);
  }

  /// Helper: дать bus event чтобы reset failure counter.
  MessengerEvent makeEvent() => MessengerEvent(
    eventType: MessengerEventType.messageCreated,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: 1,
    matrixRoomId: '!fake:localhost',
  );

  test(
    'happy path — нет error-ов, connection-state остаётся healthy',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final upstream = StreamController<MessengerEvent>.broadcast();
      final transitions = <MessengerConnectionState>[];
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        sessionStateStream: stateCtl.stream,
        reconnectBackoff: const [Duration(milliseconds: 1)],
        jitterRng: Random(0),
      );
      final sub2 = bus.connectionStateStream.listen(transitions.add);
      final sub = bus.events.listen((_) {});
      await pumpAsync();

      expect(bus.connectionState, MessengerConnectionState.healthy);
      expect(
        transitions,
        isEmpty,
        reason: 'без error-ов stream не emit-ит (initial — geter)',
      );

      await sub.cancel();
      await sub2.cancel();
      await bus.dispose();
      await upstream.close();
      await stateCtl.close();
    },
  );

  test(
    'single error → reconnecting → success → healthy '
    '(factory вызвана 2 раза, transitions: reconnecting → healthy)',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final q = makeQueueFactory(2);
      final transitions = <MessengerConnectionState>[];
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: q.factory,
        sessionStateStream: stateCtl.stream,
        reconnectBackoff: const [Duration(milliseconds: 1)],
        jitterRng: Random(0),
      );
      final sub2 = bus.connectionStateStream.listen(transitions.add);
      final sub = bus.events.listen((_) {});
      await pumpAsync();

      // 1й stream — добавляем error → bus должен switch reconnecting,
      // schedule retry, factory вызовется 2й раз.
      q.controllers[0].addError(StateError('blip'));
      await pumpAsync();

      expect(transitions, contains(MessengerConnectionState.reconnecting));
      expect(bus.connectionState, MessengerConnectionState.reconnecting);

      // 2й stream — emit event → bus reset failure counter, emit healthy.
      q.controllers[1].add(makeEvent());
      await pumpAsync();

      expect(transitions.last, MessengerConnectionState.healthy);
      expect(bus.connectionState, MessengerConnectionState.healthy);

      await sub.cancel();
      await sub2.cancel();
      await bus.dispose();
      for (final c in q.controllers) {
        await c.close();
      }
      await stateCtl.close();
    },
  );

  test('три consecutive error-а → disconnected '
      '(transitions: reconnecting → reconnecting → disconnected)', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final q = makeQueueFactory(5);
    final transitions = <MessengerConnectionState>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: q.factory,
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      disconnectedAfterFailures: 3,
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();

    // 3 failures подряд.
    q.controllers[0].addError(StateError('e1'));
    await pumpAsync();
    q.controllers[1].addError(StateError('e2'));
    await pumpAsync();
    q.controllers[2].addError(StateError('e3'));
    await pumpAsync();

    expect(bus.connectionState, MessengerConnectionState.disconnected);
    expect(
      transitions,
      [
        MessengerConnectionState.reconnecting, // failure 1
        // failure 2 — state не меняется (всё ещё reconnecting),
        // distinct() в _setConnectionState не emit-ит duplicate.
        MessengerConnectionState.disconnected, // failure 3
      ],
      reason:
          'промежуточная reconnecting → reconnecting дублирование '
          'фильтруется',
    );

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    for (final c in q.controllers) {
      await c.close();
    }
    await stateCtl.close();
  });

  test('recover из disconnected: после disconnected успешный event → healthy, '
      'counter сбрасывается', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final q = makeQueueFactory(5);
    final transitions = <MessengerConnectionState>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: q.factory,
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      disconnectedAfterFailures: 2, // ускоряем достижение disconnected
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();

    // 2 failures → disconnected.
    q.controllers[0].addError(StateError('e1'));
    await pumpAsync();
    q.controllers[1].addError(StateError('e2'));
    await pumpAsync();
    expect(bus.connectionState, MessengerConnectionState.disconnected);

    // Stream 2 (опять) выдаёт event — recover.
    q.controllers[2].add(makeEvent());
    await pumpAsync();

    expect(bus.connectionState, MessengerConnectionState.healthy);
    expect(transitions.last, MessengerConnectionState.healthy);

    // Подтверждаем что counter reset-нулся: ещё один error → reconnecting
    // (не disconnected).
    q.controllers[2].addError(StateError('e3'));
    await pumpAsync();
    expect(
      bus.connectionState,
      MessengerConnectionState.reconnecting,
      reason: 'после recovery counter == 0, новый failure == #1',
    );

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    for (final c in q.controllers) {
      await c.close();
    }
    await stateCtl.close();
  });

  test('factory throws synchronously → schedules reconnect', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var throwCount = 0;
    final extraStream = StreamController<MessengerEvent>.broadcast();
    final transitions = <MessengerConnectionState>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        if (throwCount < 1) {
          throwCount++;
          throw StateError('factory boom');
        }
        return extraStream.stream;
      },
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();

    // Первый throw → reconnecting.
    expect(transitions.contains(MessengerConnectionState.reconnecting), isTrue);

    // 2-я invocation возвращает живой stream — emit event → healthy.
    extraStream.add(makeEvent());
    await pumpAsync();
    expect(bus.connectionState, MessengerConnectionState.healthy);

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    await extraStream.close();
    await stateCtl.close();
  });

  test(
    'dispose: pending retry timer cancel-ится, factory больше не зовётся',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      var factoryCalls = 0;
      final upstreams = <StreamController<MessengerEvent>>[];
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: () {
          factoryCalls++;
          final c = StreamController<MessengerEvent>();
          upstreams.add(c);
          return c.stream;
        },
        sessionStateStream: stateCtl.stream,
        // Длинный backoff чтобы успеть dispose до retry-а.
        reconnectBackoff: const [Duration(seconds: 5)],
        jitterRng: Random(0),
      );
      final sub = bus.events.listen((_) {});
      await pumpAsync();
      expect(factoryCalls, 1);

      // Trigger error → schedule retry в 5s.
      upstreams[0].addError(StateError('blip'));
      await pumpAsync();
      expect(bus.connectionState, MessengerConnectionState.reconnecting);
      expect(factoryCalls, 1, reason: 'retry в queue, ещё не fire');

      // Dispose до retry — factory НЕ должна быть вызвана повторно.
      await sub.cancel();
      await bus.dispose();
      await pumpAsync(50);
      expect(factoryCalls, 1, reason: 'dispose cancel-нет pending retry timer');

      for (final c in upstreams) {
        await c.close();
      }
      await stateCtl.close();
    },
  );

  test('forceReconnect: healthy-fast-path (no-op если sub жив + healthy), '
      'иначе re-subscribes и reset counter', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var factoryCalls = 0;
    final upstreams = <StreamController<MessengerEvent>>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        final c = StreamController<MessengerEvent>();
        upstreams.add(c);
        return c.stream;
      },
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      disconnectedAfterFailures: 2,
      jitterRng: Random(0),
    );
    final sub = bus.events.listen((_) {});
    await pumpAsync();
    expect(factoryCalls, 1);

    // **Healthy-fast-path** (TASK20-followup-d / Windows-fix): на живом
    // sub + healthy state — forceReconnect должен быть no-op. Раньше
    // мы рвали сокет на каждый Alt+Tab (desktop) — это давало 500-600ms
    // окно потерь и WebSocketClosedException в логе.
    bus.forceReconnect();
    await pumpAsync();
    expect(
      factoryCalls,
      1,
      reason: 'forceReconnect на healthy + alive sub — no-op',
    );

    // Trigger disconnected: первая ошибка → reconnecting + retry.
    upstreams[0].addError(StateError('e1'));
    await pumpAsync();
    // Wait for retry timer (1ms backoff) to fire and create new sub.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await pumpAsync();
    // Вторая ошибка на новом sub → disconnected (после 2 неудач).
    upstreams[1].addError(StateError('e2'));
    await pumpAsync();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await pumpAsync();
    expect(bus.connectionState, MessengerConnectionState.disconnected);

    final beforeForce = factoryCalls;
    bus.forceReconnect();
    await pumpAsync();
    expect(
      factoryCalls,
      greaterThan(beforeForce),
      reason: 'forceReconnect из non-healthy state — пересоздаёт sub',
    );

    await sub.cancel();
    await bus.dispose();
    for (final c in upstreams) {
      if (!c.isClosed) await c.close();
    }
    await stateCtl.close();
  });

  test('reconnect confirm: успешная пере-подписка БЕЗ event → healthy после '
      'confirm-delay (тихий аккаунт, desktop-фикс баннера)', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final q = makeQueueFactory(3);
    final transitions = <MessengerConnectionState>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: q.factory,
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      // Короткая задержка подтверждения, чтобы не ждать реальные 2с.
      reconnectConfirmDelay: const Duration(milliseconds: 40),
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();

    // Blip → reconnecting; retry (1ms) → пере-подписка на controllers[1].
    // НИ ОДНОГО event-а (тихий аккаунт) — раньше баннер висел бы вечно.
    // Ждём > confirm-delay: sub жив → transport восстановлен → healthy.
    q.controllers[0].addError(StateError('blip'));
    await pumpAsync(120);
    expect(
      bus.connectionState,
      MessengerConnectionState.healthy,
      reason: 'sub прожил confirm-delay без ошибок → healthy без event-а',
    );
    expect(
      transitions,
      contains(MessengerConnectionState.reconnecting),
      reason: 'прошли через reconnecting (blip), потом confirm → healthy',
    );
    expect(transitions.last, MessengerConnectionState.healthy);

    // Counter сброшен confirm-ом: новый одиночный error → reconnecting.
    q.controllers[1].addError(StateError('again'));
    await pumpAsync();
    expect(
      bus.connectionState,
      MessengerConnectionState.reconnecting,
      reason: 'confirm сбросил _consecutiveFailures → следующий failure == #1',
    );

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    for (final c in q.controllers) {
      await c.close();
    }
    await stateCtl.close();
  });

  test('reconnect confirm: повторный failure ДО confirm-delay не даёт '
      'ложный healthy (confirm отменяется)', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final q = makeQueueFactory(4);
    final transitions = <MessengerConnectionState>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: q.factory,
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      // Длинная задержка: failure #2 придёт РАНЬШЕ подтверждения.
      reconnectConfirmDelay: const Duration(seconds: 5),
      disconnectedAfterFailures: 2,
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();

    // Ошибка 1 → reconnecting → пере-подписка controllers[1] + arm confirm(5s).
    q.controllers[0].addError(StateError('e1'));
    await pumpAsync();
    // Ошибка 2 задолго до 5с → confirm ПЕРВОЙ пере-подписки отменён,
    // counter дорос до 2 → disconnected (а не ложный healthy).
    q.controllers[1].addError(StateError('e2'));
    await pumpAsync();
    expect(bus.connectionState, MessengerConnectionState.disconnected);
    expect(
      transitions,
      isNot(contains(MessengerConnectionState.healthy)),
      reason: 'confirm первой пере-подписки не выстрелил раньше failure #2',
    );

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    for (final c in q.controllers) {
      await c.close();
    }
    await stateCtl.close();
  });
}

typedef StreamFactory = Stream<MessengerEvent> Function();
