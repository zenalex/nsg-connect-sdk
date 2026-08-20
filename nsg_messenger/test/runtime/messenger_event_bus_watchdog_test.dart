import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

/// **Issue #84 — сторож живости.**
///
/// Владелец: клиент открыт, чат открыт, новые сообщения не приходят и
/// статусы не обновляются; фокус и сворачивание не помогают; отправка из
/// этого же клиента при этом работает. То есть HTTP жив, а стрим мёртв —
/// и клиент об этом не догадывается.
///
/// Разбор показал два способа замолчать навсегда, и оба здесь и заперты:
///
///   1. **Сигнал проглочен.** `_scheduleReconnect` выходит молча (в фоне,
///      без слушателей, при уже висящем таймере), не оставляя после себя
///      ничего, что попробует снова.
///   2. **Сигнала не было.** Подписка «жива», но не приносит ничего —
///      половинчато закрытый сокет не даёт ни ошибки, ни закрытия.
///
/// Общая часть обоих: восстановление не должно зависеть от внешнего
/// события. Пока приложение активно — соединение чинит себя само.
void main() {
  // Сторож спрашивает у фреймворка, действительно ли приложение в фоне, —
  // значит фреймворк должен быть поднят и иметь мнение.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  Future<void> pump([int ms = 30]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  MessengerEvent message() => MessengerEvent(
    eventType: MessengerEventType.messageCreated,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: 1,
    matrixRoomId: '!r:localhost',
  );

  MessengerEvent heartbeat() => MessengerEvent(
    eventType: MessengerEventType.heartbeat,
    serverTimestamp: DateTime.now().toUtc(),
  );

  /// Фабрика, отдающая по контроллеру на вызов (последний переиспользуется),
  /// со счётчиком вызовов — по нему и видно, поднялась ли подписка заново.
  ({
    Stream<MessengerEvent> Function() factory,
    List<StreamController<MessengerEvent>> controllers,
    int Function() calls,
  })
  queueFactory(int slots) {
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

    return (factory: factory, controllers: controllers, calls: () => idx);
  }

  test(
    'сценарий #84: стрим закрылся, сигнал проглочен фоном, а `resumed` так и '
    'не пришёл — соединение поднялось само, без участия человека',
    () async {
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final q = queueFactory(3);
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: q.factory,
        sessionStateStream: stateCtl.stream,
        reconnectBackoff: const [Duration(milliseconds: 1)],
        watchdogPeriod: const Duration(milliseconds: 10),
        jitterRng: Random(0),
      );
      final sub = bus.events.listen((_) {});
      await pump();
      expect(q.calls(), 1, reason: 'первая подписка встала');

      // Окно свернули — подписка закрывается намеренно.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      bus.onAppLifecycleChanged(AppLifecycleState.paused);
      await pump();

      // Сервер закрывает стрим (рестарт контейнера при деплое). Сигнал
      // приходит, когда мы в фоне, и `_scheduleReconnect` глотает его
      // молча, рассчитывая на resume.
      await q.controllers[0].close();
      await pump(40);
      final callsWhileBackgrounded = q.calls();
      expect(
        callsWhileBackgrounded,
        1,
        reason: 'в фоне подписку не поднимаем — это осознанно',
      );

      // Окно развернули. Система знает, что приложение больше не в фоне, а
      // вот парного `resumed` шина НЕ получает — ровно это владелец и
      // описал: «просто возврат из фона не помогает (фокус), минимизация
      // тоже». Единственный, кто продолжает считать нас фоном, — наш
      // собственный флаг.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await pump(60);

      expect(
        q.calls(),
        greaterThan(callsWhileBackgrounded),
        reason: 'протухший флаг фона не может быть приговором навсегда',
      );

      await sub.cancel();
      await bus.dispose();
      for (final c in q.controllers) {
        if (!c.isClosed) await c.close();
      }
      await stateCtl.close();
    },
  );

  test(
    'приложение действительно в фоне — сторож молчит и стрим не поднимает',
    () async {
      // Обратная сторона: гасить подписку в фоне на телефоне правильно —
      // это батарея, а сообщения в это время доставляет пуш. Сторож имеет
      // право снимать флаг, только если система ЯВНО говорит, что фон
      // закончился.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final q = queueFactory(3);
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: q.factory,
        sessionStateStream: stateCtl.stream,
        reconnectBackoff: const [Duration(milliseconds: 1)],
        watchdogPeriod: const Duration(milliseconds: 10),
        jitterRng: Random(0),
      );
      final sub = bus.events.listen((_) {});
      await pump();

      bus.onAppLifecycleChanged(AppLifecycleState.paused);
      await pump();
      await q.controllers[0].close();
      await pump(80);

      expect(
        q.calls(),
        1,
        reason: 'в настоящем фоне подписку поднимать нельзя',
      );

      await sub.cancel();
      await bus.dispose();
      for (final c in q.controllers) {
        if (!c.isClosed) await c.close();
      }
      await stateCtl.close();
    },
  );

  test(
    'подписка жива, но замолчала после ударов сердца — сторож пересоздаёт её',
    () async {
      // Тот самый «выглядит здоровым, а мёртв»: ни ошибки, ни закрытия,
      // состояние healthy, баннера нет. Без сердцебиения это неотличимо от
      // выходных, поэтому улика — пропавшие удары.
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final q = queueFactory(3);
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: q.factory,
        sessionStateStream: stateCtl.stream,
        reconnectBackoff: const [Duration(milliseconds: 1)],
        watchdogPeriod: const Duration(milliseconds: 10),
        silenceTimeout: const Duration(milliseconds: 60),
        jitterRng: Random(0),
      );
      final sub = bus.events.listen((_) {});
      await pump();
      expect(q.calls(), 1);

      // Сервер бьётся — соединение доказанно живое.
      q.controllers[0].add(heartbeat());
      await pump(10);
      expect(
        bus.connectionState,
        MessengerConnectionState.healthy,
        reason: 'удар сердца — доказательство жизни, а не повод к тревоге',
      );
      expect(q.calls(), 1, reason: 'живое соединение рвать нельзя');

      // Сокет умирает молча: контроллер НЕ закрываем и ошибку НЕ шлём.
      await pump(120);

      expect(
        q.calls(),
        greaterThanOrEqualTo(2),
        reason: 'пропавшее сердцебиение — улика, подписку надо пересоздать',
      );

      await sub.cancel();
      await bus.dispose();
      for (final c in q.controllers) {
        if (!c.isClosed) await c.close();
      }
      await stateCtl.close();
    },
  );

  test('старый сервер без сердцебиения: тишина — не улика, живую подписку '
      'не трогаем', () async {
    // Обратная сторона: пока сервер не научился биться (или клиент
    // подключён к старой сборке), молчание совершенно законно — в чатах
    // просто никто не пишет. Рвать по нему подписку значило бы менять
    // молчащий клиент на клиент, который рвёт связь каждые две минуты.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final q = queueFactory(3);
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: q.factory,
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      watchdogPeriod: const Duration(milliseconds: 10),
      silenceTimeout: const Duration(milliseconds: 60),
      jitterRng: Random(0),
    );
    final sub = bus.events.listen((_) {});
    await pump();

    // Обычное сообщение (не удар) — и дальше тишина сильно дольше порога.
    q.controllers[0].add(message());
    await pump(150);

    expect(
      q.calls(),
      1,
      reason: 'без сердцебиения тишина ничего не доказывает',
    );
    expect(bus.connectionState, MessengerConnectionState.healthy);

    await sub.cancel();
    await bus.dispose();
    for (final c in q.controllers) {
      if (!c.isClosed) await c.close();
    }
    await stateCtl.close();
  });

  test('удар сердца не доходит до потребителей', () async {
    // Для реакторов кэша и экранов это событие без содержимого: пропустив
    // его дальше, мы платили бы перерисовкой раз в минуту у каждого
    // открытого чата.
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final seen = <MessengerEventType>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      watchdogPeriod: const Duration(milliseconds: 10),
      jitterRng: Random(0),
    );
    final sub = bus.events.listen((e) => seen.add(e.eventType));
    await pump();

    upstream.add(heartbeat());
    upstream.add(message());
    await pump();

    expect(seen, [MessengerEventType.messageCreated]);

    await sub.cancel();
    await bus.dispose();
    await upstream.close();
    await stateCtl.close();
  });

  test(
    'отмена мёртвой подписки бросила — подъём всё равно происходит',
    () async {
      // Serverpod в `onCancel` пишет в сокет команду «закрой поток»; если
      // сокета уже нет — летит StateError. Раньше он уносил с собой весь
      // путь восстановления: падал ровно тот код, который и должен был
      // вылечить мёртвое соединение.
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      var calls = 0;
      final live = StreamController<MessengerEvent>.broadcast();
      late StreamController<MessengerEvent> dead;
      Stream<MessengerEvent> factory() {
        calls++;
        if (calls == 1) {
          // Подписка мёртвого транспорта: отмена бросает ровно так, как
          // это делает serverpod, когда сокета под потоком уже нет.
          dead = StreamController<MessengerEvent>(
            onCancel: () => throw StateError(
              'Message posted when web socket connection is closed',
            ),
          );
          return dead.stream;
        }
        return live.stream;
      }

      final errors = <Object>[];
      final bus = MessengerEventBus.attachWithFactory(
        streamFactory: factory,
        sessionStateStream: stateCtl.stream,
        reconnectBackoff: const [Duration(milliseconds: 1)],
        watchdogPeriod: const Duration(milliseconds: 10),
        silenceTimeout: const Duration(milliseconds: 60),
        onError: (e, _) => errors.add(e),
        jitterRng: Random(0),
      );
      final sub = bus.events.listen((_) {});
      await pump();
      expect(calls, 1);

      // Сердце било, потом замолчало — сторож пойдёт пересоздавать
      // подписку, и на прощании со старой получит бросок.
      dead.add(heartbeat());
      await pump(120);

      expect(
        calls,
        greaterThanOrEqualTo(2),
        reason: 'бросок на прощании не должен отменять новую подписку',
      );
      expect(
        errors.whereType<StateError>(),
        isNotEmpty,
        reason: 'ошибку глотаем молча только для потребителей, но не для лога',
      );

      await sub.cancel();
      await bus.dispose();
      await live.close();
      await stateCtl.close();
    },
  );
}
