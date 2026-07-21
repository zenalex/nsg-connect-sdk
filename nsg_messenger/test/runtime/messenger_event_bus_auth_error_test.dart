import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **Session-recovery fix (a1)**: тесты маршрутизации ТИПИЗИРОВАННОГО
/// auth-invalidation на `userEventStream` в self-heal (а НЕ в transport-
/// reconnect).
///
/// Корневой баг: `MessengerNotAuthenticatedException` приезжает как
/// сериализованный exception в stream `onError`. До фикса bus трактовал
/// это как transport-blip и реконнектил вечно (dead wall «нет соединения»),
/// НИКОГДА не маршрутя auth-ошибку в session manager. После фикса —
/// `onStreamAuthError` дёргается ровно один раз, а transport-машина
/// (reconnecting/disconnected + retry timer) НЕ трогается.
void main() {
  Future<void> pumpAsync([int ms = 30]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  MessengerEvent makeEvent() => MessengerEvent(
    eventType: MessengerEventType.messageCreated,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: 1,
    matrixRoomId: '!fake:localhost',
  );

  test('типизированный auth-invalidation в stream onError → onStreamAuthError '
      'ровно 1 раз, connectionState НЕ уходит в reconnecting/disconnected, '
      'retry-таймер НЕ ставится', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final transitions = <MessengerConnectionState>[];
    var authErrorCalls = 0;
    var factoryCalls = 0;

    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        return upstream.stream;
      },
      sessionStateStream: stateCtl.stream,
      onStreamAuthError: () async {
        authErrorCalls++;
      },
      // Короткий backoff — если БЫ (ошибочно) запланировался reconnect,
      // он бы успел выстрелить в пределах pumpAsync и увеличить
      // factoryCalls. Это негативный контроль.
      reconnectBackoff: const [Duration(milliseconds: 1)],
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();
    expect(factoryCalls, 1, reason: 'начальная подписка');

    // Типизированный auth-invalidation (как с сервера через /sync channel).
    upstream.addError(MessengerNotAuthenticatedException(hint: 'stale'));
    await pumpAsync();

    // (1) self-heal вызван ровно один раз.
    expect(authErrorCalls, 1, reason: 'onStreamAuthError дёрнут один раз');
    // (2) НЕ transport: connectionState остался healthy, никаких
    // reconnecting/disconnected transitions.
    expect(
      bus.connectionState,
      MessengerConnectionState.healthy,
      reason: 'auth-invalidation — не transport failure',
    );
    expect(
      transitions,
      isEmpty,
      reason: 'нет reconnecting/disconnected на auth-invalidation',
    );
    // (3) retry-таймер НЕ поставлен → фабрика больше НЕ звалась (иначе
    // reconnect пересоздал бы sub при 1ms backoff).
    expect(
      factoryCalls,
      1,
      reason: 'auth-invalidation НЕ планирует transport-reconnect',
    );

    // Драйвит session manager: успешный self-heal → active →
    // _listenToSessionState переподпишет underlying (factory зовётся снова).
    stateCtl.add(MessengerSessionState.active);
    await pumpAsync();
    expect(
      factoryCalls,
      2,
      reason: 'session active → re-subscribe с новым токеном',
    );

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test('типизированный auth-invalidation при СИНХРОННОМ throw фабрики → '
      'onStreamAuthError, без transport-reconnect', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final live = StreamController<MessengerEvent>.broadcast();
    final transitions = <MessengerConnectionState>[];
    var authErrorCalls = 0;
    var factoryCalls = 0;

    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        factoryCalls++;
        // Первая подписка — фабрика синхронно бросает auth-invalidation.
        if (factoryCalls == 1) {
          throw InvalidTokenException(reason: 'boom');
        }
        return live.stream;
      },
      sessionStateStream: stateCtl.stream,
      onStreamAuthError: () async {
        authErrorCalls++;
      },
      reconnectBackoff: const [Duration(milliseconds: 1)],
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();

    expect(authErrorCalls, 1, reason: 'sync-throw auth → self-heal');
    expect(
      bus.connectionState,
      MessengerConnectionState.healthy,
      reason: 'sync auth-throw — не transport',
    );
    expect(transitions, isEmpty);
    expect(
      factoryCalls,
      1,
      reason: 'нет reconnect-а на auth-invalidation (фабрика не re-called)',
    );

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    await live.close();
    await stateCtl.close();
  });

  test('обычный transport-error ВСЁ ЕЩЁ идёт через reconnect '
      '(reconnecting), onStreamAuthError НЕ вызывается', () async {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    var authErrorCalls = 0;
    final upstreams = <StreamController<MessengerEvent>>[];
    final transitions = <MessengerConnectionState>[];

    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () {
        final c = StreamController<MessengerEvent>.broadcast();
        upstreams.add(c);
        return c.stream;
      },
      sessionStateStream: stateCtl.stream,
      onStreamAuthError: () async {
        authErrorCalls++;
      },
      reconnectBackoff: const [Duration(milliseconds: 1)],
      jitterRng: Random(0),
    );
    final sub2 = bus.connectionStateStream.listen(transitions.add);
    final sub = bus.events.listen((_) {});
    await pumpAsync();
    expect(upstreams.length, 1);

    // Обычная transport-ошибка (НЕ auth-invalidation).
    upstreams[0].addError(StateError('transport blip'));
    await pumpAsync();

    // (1) self-heal НЕ вызван — transport axis отдельный.
    expect(authErrorCalls, 0, reason: 'transport error ≠ auth-invalidation');
    // (2) transport-машина отработала: reconnecting + retry пересоздал sub.
    expect(transitions, contains(MessengerConnectionState.reconnecting));
    expect(
      upstreams.length,
      greaterThan(1),
      reason: 'transport reconnect пересоздаёт underlying sub',
    );

    // Recover: новый sub выдаёт event → healthy.
    upstreams.last.add(makeEvent());
    await pumpAsync();
    expect(bus.connectionState, MessengerConnectionState.healthy);

    await sub.cancel();
    await sub2.cancel();
    await bus.dispose();
    for (final c in upstreams) {
      if (!c.isClosed) await c.close();
    }
    await stateCtl.close();
  });
}
