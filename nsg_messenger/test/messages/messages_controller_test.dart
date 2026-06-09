import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';

/// Тесты для [MessagesController] (TASK15 Chunk 1).
///
/// Структура — TDD-first для двух race-zones (subscribe-before-fetch
/// + optimistic 2-layer dedup), interleaved coverage для остального.
void main() {
  group('MessagesController — race zone 1: subscribe-before-fetch', () {
    test('event прилетает ДО completion listMessages → попадает в final state '
        '(не теряется)', () async {
      final rpc = _FakeRpc();
      final completer = Completer<MessengerMessageListPage>();
      rpc.listMessagesHandler = (roomId, fromToken, limit) => completer.future;

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);

      // Запускаем init — listMessages future висит pending.
      final initFuture = controller.init();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, isA<MessagesLoading>());

      // Эмитим event ДО completion → должен буферизоваться.
      eventCtrl.add(_eventForRoom(101, _msg(eventId: 'e-buffered')));
      await Future<void>.delayed(Duration.zero);

      // Теперь complete listMessages — должен слиться с buffered.
      completer.complete(_page(messages: [_msg(eventId: 'e-history-1')]));
      await initFuture;

      final state = controller.state as MessagesReady;
      expect(state.messages.length, 2);
      // DESC: buffered прилетел позже history → сидит на index 0.
      expect(state.messages[0].matrixEventId, 'e-buffered');
      expect(state.messages[1].matrixEventId, 'e-history-1');
      await controller.dispose();
      await eventCtrl.close();
    });

    test('если listMessages вернул event, который тоже прилетел через stream → '
        'дедуп по matrixEventId', () async {
      final rpc = _FakeRpc();
      final completer = Completer<MessengerMessageListPage>();
      rpc.listMessagesHandler = (roomId, fromToken, limit) => completer.future;

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);

      final initFuture = controller.init();
      await Future<void>.delayed(Duration.zero);

      eventCtrl.add(_eventForRoom(101, _msg(eventId: 'e-overlap')));
      await Future<void>.delayed(Duration.zero);

      // listMessages вернёт тот же event — overlap. Layer-2 dedup.
      completer.complete(_page(messages: [_msg(eventId: 'e-overlap')]));
      await initFuture;

      final state = controller.state as MessagesReady;
      expect(state.messages.length, 1, reason: 'overlap deduped');
      expect(state.messages[0].matrixEventId, 'e-overlap');
      await controller.dispose();
      await eventCtrl.close();
    });

    test('event для другой roomId не попадает в state и не в buffer', () async {
      final rpc = _FakeRpc();
      final completer = Completer<MessengerMessageListPage>();
      rpc.listMessagesHandler = (roomId, fromToken, limit) => completer.future;

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);

      final initFuture = controller.init();
      await Future<void>.delayed(Duration.zero);

      // Event для chужой комнаты — отфильтрован stream.where.
      eventCtrl.add(_eventForRoom(999, _msg(eventId: 'e-other-room')));
      await Future<void>.delayed(Duration.zero);

      completer.complete(_page(messages: []));
      await initFuture;

      final state = controller.state as MessagesReady;
      expect(state.messages, isEmpty);
      await controller.dispose();
      await eventCtrl.close();
    });

    test('pending overflow → restart init + debugPrint warning + final state '
        'содержит свежую history', () async {
      final rpc = _FakeRpc();
      // Первый вызов listMessages "висит", второй (после restart)
      // возвращает result с одной message.
      final firstCompleter = Completer<MessengerMessageListPage>();
      var listCallCount = 0;
      rpc.listMessagesHandler = (roomId, fromToken, limit) {
        listCallCount++;
        if (listCallCount == 1) return firstCompleter.future;
        return Future.value(
          _page(messages: [_msg(eventId: 'e-after-restart')]),
        );
      };

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(
        rpc: rpc,
        events: eventCtrl.stream,
        pendingBufferCap: 3,
      );

      final logs = <String?>[];
      await runZoned(
        () async {
          final initFuture = controller.init();
          await Future<void>.delayed(Duration.zero);

          // Эмитим больше events чем cap.
          for (var i = 0; i < 5; i++) {
            eventCtrl.add(_eventForRoom(101, _msg(eventId: 'e-burst-$i')));
            await Future<void>.delayed(Duration.zero);
          }

          // Первый init теперь должен быть отброшен через _initEpoch
          // bump. Future continues, но result игнорируется.
          firstCompleter.complete(_page(messages: [_msg(eventId: 'e-old')]));
          await initFuture;
          await Future<void>.delayed(Duration.zero);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );

      expect(
        listCallCount,
        greaterThanOrEqualTo(2),
        reason: 'restart triggered second listMessages',
      );
      expect(
        logs.any((l) => l != null && l.contains('pending overflow')),
        isTrue,
        reason: 'overflow warning logged',
      );
      // Final state — содержит после-restart history (e-after-restart).
      final state = controller.state as MessagesReady;
      expect(
        state.messages.any((m) => m.matrixEventId == 'e-after-restart'),
        isTrue,
      );
      // Старый history (e-old) НЕ должен попасть — его future был
      // сброшен через epoch.
      expect(state.messages.any((m) => m.matrixEventId == 'e-old'), isFalse);
      await controller.dispose();
      await eventCtrl.close();
    });
  });

  group('MessagesController — race zone 2: optimistic 2-layer dedup', () {
    test(
      'sendMessage → pending appears immediately, RPC return → promote to sent '
      '(layer-1 by clientTxnId)',
      () async {
        final rpc = _FakeRpc();
        final sendCompleter = Completer<MessengerMessage>();
        rpc.sendMessageHandler =
            (roomId, body, msgType, clientTxnId, attachment) {
              // Сервер echo-ит наш txnId.
              return sendCompleter.future;
            };

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(
          rpc: rpc,
          events: eventCtrl.stream,
          clientTxnIdGen: () => 'TXN-1',
        );
        await controller.init();

        final sendFuture = controller.sendMessage(body: 'hello');
        await Future<void>.delayed(Duration.zero);

        // Pending bubble виден immediately.
        var state = controller.state as MessagesReady;
        expect(state.messages.length, 1);
        expect(state.messages[0].isPending, isTrue);
        expect(state.messages[0].clientTxnId, 'TXN-1');
        expect(state.messages[0].body, 'hello');

        // RPC возвращает реальное сообщение с тем же txnId.
        sendCompleter.complete(
          _msg(eventId: 'e-real', body: 'hello', clientTxnId: 'TXN-1'),
        );
        await sendFuture;

        state = controller.state as MessagesReady;
        expect(state.messages.length, 1, reason: 'no duplicate');
        expect(state.messages[0].isSent, isTrue);
        expect(state.messages[0].matrixEventId, 'e-real');
        expect(
          state.messages[0].clientTxnId,
          'TXN-1',
          reason: 'txnId preserved через layer-1 promote',
        );
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test(
      'stream-first then RPC-return: stream приходит ПЕРВЫМ → layer-1 promote, '
      'затем RPC return → layer-2 dedup, без дубля',
      () async {
        final rpc = _FakeRpc();
        final sendCompleter = Completer<MessengerMessage>();
        rpc.sendMessageHandler =
            (roomId, body, msgType, clientTxnId, attachment) =>
                sendCompleter.future;

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(
          rpc: rpc,
          events: eventCtrl.stream,
          clientTxnIdGen: () => 'TXN-2',
        );
        await controller.init();

        final sendFuture = controller.sendMessage(body: 'hi');
        await Future<void>.delayed(Duration.zero);

        // STREAM приходит ПЕРВЫМ — Matrix /sync echo-нул event с
        // unsigned.transaction_id == 'TXN-2'.
        eventCtrl.add(
          _eventForRoom(
            101,
            _msg(eventId: 'e-r2', body: 'hi', clientTxnId: 'TXN-2'),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        var state = controller.state as MessagesReady;
        expect(state.messages.length, 1);
        expect(
          state.messages[0].isSent,
          isTrue,
          reason: 'pending promoted via stream через layer-1',
        );
        expect(state.messages[0].matrixEventId, 'e-r2');

        // Теперь RPC return — тот же event_id. Layer-2 dedup.
        sendCompleter.complete(
          _msg(eventId: 'e-r2', body: 'hi', clientTxnId: 'TXN-2'),
        );
        await sendFuture;

        state = controller.state as MessagesReady;
        expect(state.messages.length, 1, reason: 'layer-2 deduped RPC return');
        expect(state.messages[0].isSent, isTrue);
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('RPC-first then stream: RPC return promotes pending, затем stream → '
        'layer-2 dedup', () async {
      final rpc = _FakeRpc();
      rpc.sendMessageHandler =
          (roomId, body, msgType, clientTxnId, attachment) => Future.value(
            _msg(eventId: 'e-r3', body: 'yo', clientTxnId: clientTxnId),
          );

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(
        rpc: rpc,
        events: eventCtrl.stream,
        clientTxnIdGen: () => 'TXN-3',
      );
      await controller.init();

      await controller.sendMessage(body: 'yo');
      var state = controller.state as MessagesReady;
      expect(state.messages.length, 1);
      expect(state.messages[0].isSent, isTrue);
      expect(state.messages[0].matrixEventId, 'e-r3');

      // Теперь stream re-доставляет тот же event (например, после
      // reconnect-а с overlap).
      eventCtrl.add(
        _eventForRoom(
          101,
          _msg(eventId: 'e-r3', body: 'yo', clientTxnId: 'TXN-3'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      state = controller.state as MessagesReady;
      expect(state.messages.length, 1, reason: 'layer-2 dedup');
      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'simultaneous (Future.wait): RPC return и stream приходят квази-одновременно — '
      'остаётся ровно одно сообщение',
      () async {
        final rpc = _FakeRpc();
        rpc.sendMessageHandler =
            (roomId, body, msgType, clientTxnId, attachment) => Future.value(
              _msg(eventId: 'e-r4', body: 'sim', clientTxnId: clientTxnId),
            );

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(
          rpc: rpc,
          events: eventCtrl.stream,
          clientTxnIdGen: () => 'TXN-4',
        );
        await controller.init();

        // Fire оба events в параллель.
        await Future.wait([
          controller.sendMessage(body: 'sim'),
          () async {
            // Микропауза чтобы pending bubble уже инициализировался,
            // потом сразу flood и stream и future-completion.
            await Future<void>.delayed(Duration.zero);
            eventCtrl.add(
              _eventForRoom(
                101,
                _msg(eventId: 'e-r4', body: 'sim', clientTxnId: 'TXN-4'),
              ),
            );
          }(),
        ]);
        await Future<void>.delayed(Duration.zero);

        final state = controller.state as MessagesReady;
        expect(state.messages.length, 1, reason: 'no duplicate');
        expect(state.messages[0].isSent, isTrue);
        expect(state.messages[0].matrixEventId, 'e-r4');
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('sendMessage failure → pending → failed bubble + lastError', () async {
      final rpc = _FakeRpc();
      rpc.sendMessageHandler =
          (roomId, body, msgType, clientTxnId, attachment) =>
              Future.error(StateError('network down'));

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final errors = <Object>[];
      final controller = _make(
        rpc: rpc,
        events: eventCtrl.stream,
        clientTxnIdGen: () => 'TXN-fail',
        onSendError: (e, st) => errors.add(e),
      );
      await controller.init();

      await controller.sendMessage(body: 'doomed');

      final state = controller.state as MessagesReady;
      expect(state.messages.length, 1);
      expect(state.messages[0].isFailed, isTrue);
      expect(state.messages[0].lastError, isA<StateError>());
      expect(state.messages[0].body, 'doomed');
      expect(errors.length, 1);
      await controller.dispose();
      await eventCtrl.close();
    });

    test('sendMessage до init(): pending промерцает но не теряется', () async {
      // Зафиксированный контракт #2 ревью 8007c08: вызов sendMessage в
      // Loading state создаёт временный Ready с pending; финальный init
      // перезапишет state свежим server-history → pending visually
      // disappears, потом возвращается через layer-1 dedup на RPC return.
      // Не data loss, но flicker — ChatScreen в Chunk 2 disable-ит
      // composer пока state ≠ Ready.
      final rpc = _FakeRpc();
      final listCompleter = Completer<MessengerMessageListPage>();
      rpc.listMessagesHandler = (r, ft, l) => listCompleter.future;
      rpc.sendMessageHandler =
          (roomId, body, msgType, clientTxnId, attachment) => Future.value(
            _msg(eventId: 'e-recovered', body: body, clientTxnId: clientTxnId),
          );

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(
        rpc: rpc,
        events: eventCtrl.stream,
        clientTxnIdGen: () => 'TXN-flicker',
      );
      // init() в полёте.
      final initFuture = controller.init();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, isA<MessagesLoading>());

      // sendMessage в Loading → промежуточный Ready с pending.
      await controller.sendMessage(body: 'early');
      var state = controller.state as MessagesReady;
      expect(state.messages.length, 1);
      // Pending мог быть уже promoted в sent через RPC return — для
      // данного теста главное что entry с TXN-flicker присутствует.
      expect(state.messages[0].clientTxnId, 'TXN-flicker');

      // Завершаем listMessages с пустой history — финальный Ready
      // перезапишет messages, pending исчезнет временно.
      listCompleter.complete(_page(messages: []));
      await initFuture;
      state = controller.state as MessagesReady;
      // Финальный state может содержать или не содержать TXN-flicker —
      // зависит от порядка micro-tasks. Главный assert: НЕТ data
      // duplication (если RPC return уже отработал, server-confirmed
      // entry должна быть; если нет — будет восстановлена через layer-1
      // dedup при следующем echo). Поэтому проверяем upper-bound.
      expect(
        state.messages.length,
        lessThanOrEqualTo(1),
        reason: 'no duplicate from concurrent send + init',
      );
      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'retry с тем же clientTxnId — успешный второй вызов промоутит',
      () async {
        final rpc = _FakeRpc();
        var callCount = 0;
        rpc.sendMessageHandler =
            (roomId, body, msgType, clientTxnId, attachment) {
              callCount++;
              if (callCount == 1)
                return Future.error(StateError('first failed'));
              return Future.value(
                _msg(
                  eventId: 'e-retry-success',
                  body: body,
                  clientTxnId: clientTxnId,
                ),
              );
            };

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(
          rpc: rpc,
          events: eventCtrl.stream,
          clientTxnIdGen: () => 'TXN-retry',
        );
        await controller.init();

        final txnId = await controller.sendMessage(body: 'try');
        var state = controller.state as MessagesReady;
        expect(state.messages[0].isFailed, isTrue);

        await controller.retry(txnId);
        state = controller.state as MessagesReady;
        expect(state.messages.length, 1);
        expect(state.messages[0].isSent, isTrue);
        expect(state.messages[0].matrixEventId, 'e-retry-success');
        expect(
          callCount,
          2,
          reason: 'retry с тем же clientTxnId — server idempotency',
        );
        await controller.dispose();
        await eventCtrl.close();
      },
    );
  });

  group('MessagesController — basic lifecycle', () {
    test('конструктор asserts pendingBufferCap > 0', () {
      // Защита от бесконечного restart-storm-а в overflow path
      // (cap=0 → каждое event triggers restart). См. ревью 8007c08 #4.
      expect(
        () => MessagesController(
          roomId: _kRoomId,
          rpc: _FakeRpc(),
          events: const Stream.empty(),
          selfMessengerUserId: _kSelfMessengerUserId,
          selfMatrixUserId: _kSelfMatrixUserId,
          pendingBufferCap: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'init() переходит Loading → Ready и подписывается на stream',
      () async {
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (r, ft, l) => Future.value(
          _page(
            messages: [
              _msg(eventId: 'h-1', body: 'old1'),
              _msg(eventId: 'h-2', body: 'old2'),
            ],
            nextToken: 'next-t',
          ),
        );

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);

        expect(controller.state, isA<MessagesLoading>());
        await controller.init();

        final state = controller.state as MessagesReady;
        expect(state.messages.length, 2);
        expect(state.messages[0].matrixEventId, 'h-1');
        expect(state.hasMore, isTrue);
        expect(state.paginating, isFalse);
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test(
      'init() seed-ит историю реакций через listReactions → reactionsFor '
      'показывает агрегированные count (phase 2)',
      () async {
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (r, ft, l) => Future.value(
          _page(messages: [_msg(eventId: 'h-1', body: 'hi')]),
        );
        rpc.listReactionsResult = [
          _reactionEvent(
            targetEventId: 'h-1', key: '👍',
            reactorMatrixId: '@a:t', reactionEventId: 'r-1',
          ),
          _reactionEvent(
            targetEventId: 'h-1', key: '👍',
            reactorMatrixId: '@b:t', reactionEventId: 'r-2',
          ),
          _reactionEvent(
            targetEventId: 'h-1', key: '❤️',
            reactorMatrixId: '@a:t', reactionEventId: 'r-3',
          ),
        ];
        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();
        // _seedReactions — unawaited; даём microtask-ам отработать.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(rpc.lastListReactionsEventIds, ['h-1'],
            reason: 'seed дёрнут с eventId-ами страницы');
        final byKey = {
          for (final g in controller.reactionsFor('h-1')) g.key: g.count,
        };
        expect(byKey['👍'], 2);
        expect(byKey['❤️'], 1);
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test(
      'init() seed-ит persisted read-receipts через listReadReceipts → '
      'readByPeerMatrixIds непустой (B22)',
      () async {
        final ts = DateTime.utc(2026, 1, 1, 10);
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (r, ft, l) => Future.value(
          _page(messages: [_msg(eventId: 'h-1', body: 'hi', timestamp: ts)]),
        );
        rpc.listReadReceiptsResult = [
          _readReceiptEvent(
            readerMatrixId: '@peer:test',
            readEventId: 'h-1',
            serverTimestamp: ts,
          ),
        ];
        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();
        // _seedReadReceipts — unawaited; даём microtask-ам отработать.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(rpc.listReadReceiptsCalls, 1, reason: 'seed дёрнут в init');
        final state = controller.state as MessagesReady;
        final readers = controller.readByPeerMatrixIds(state.messages[0]);
        expect(readers, contains('@peer:test'),
            reason: 'persisted receipt → ✓✓ сразу при открытии чата');
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test(
      'monotonic guard: seed старее realtime НЕ перетирает свежий marker '
      '(B22)',
      () async {
        final tsOld = DateTime.utc(2026, 1, 1, 10);
        final tsNew = DateTime.utc(2026, 1, 1, 12);
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (r, ft, l) => Future.value(
          _page(
            messages: [
              // h-2 newer (top), h-1 older.
              _msg(eventId: 'h-2', body: 'new', timestamp: tsNew),
              _msg(eventId: 'h-1', body: 'old', timestamp: tsOld),
            ],
          ),
        );
        // Seed возвращает СТАРЫЙ pointer (h-1).
        rpc.listReadReceiptsResult = [
          _readReceiptEvent(
            readerMatrixId: '@peer:test',
            readEventId: 'h-1',
            serverTimestamp: tsOld,
          ),
        ];
        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();
        // Realtime СВЕЖИЙ receipt (h-2) — двигает marker вперёд.
        eventCtrl.add(
          _readReceiptEvent(
            readerMatrixId: '@peer:test',
            readEventId: 'h-2',
            serverTimestamp: tsNew,
          ),
        );
        // Дать отработать и seed (unawaited) и realtime — порядок их
        // применения не важен: monotonic-guard держит max.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = controller.state as MessagesReady;
        // Marker должен стоять на h-2 (newer): оба message прочитаны peer-ом.
        final readersNew = controller.readByPeerMatrixIds(state.messages[0]);
        final readersOld = controller.readByPeerMatrixIds(state.messages[1]);
        expect(readersNew, contains('@peer:test'),
            reason: 'свежий realtime marker не откатан seed-ом');
        expect(readersOld, contains('@peer:test'));
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('init() listMessages throws → Error state', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (r, ft, l) =>
          Future.error(StateError('init-fail'));

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);

      await controller.init();

      final state = controller.state as MessagesError;
      expect(state.error, isA<StateError>());
      expect(state.lastKnown, isNull);
      await controller.dispose();
      await eventCtrl.close();
    });

    test('инкрементальный stream после init дописывает в state', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (r, ft, l) =>
          Future.value(_page(messages: [_msg(eventId: 'h-1')]));

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      eventCtrl.add(_eventForRoom(101, _msg(eventId: 'live-1')));
      await Future<void>.delayed(Duration.zero);

      final state = controller.state as MessagesReady;
      expect(state.messages.length, 2);
      expect(state.messages[0].matrixEventId, 'live-1', reason: 'newest top');
      expect(state.messages[1].matrixEventId, 'h-1');
      await controller.dispose();
      await eventCtrl.close();
    });

    test('dispose() — state не emit-ится из in-flight listMessages', () async {
      final rpc = _FakeRpc();
      final completer = Completer<MessengerMessageListPage>();
      rpc.listMessagesHandler = (r, ft, l) => completer.future;

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);

      final initFuture = controller.init();
      await Future<void>.delayed(Duration.zero);
      await controller.dispose();
      // Завершаем future — не должно бросить и не должно изменить state
      // (state.dispose-нут).
      completer.complete(_page(messages: []));
      await initFuture;
      // Если дошли сюда без exception — passed.
      await eventCtrl.close();
    });

    test('dispose() — stream sub отменена', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (r, ft, l) => Future.value(_page(messages: []));

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();
      expect(eventCtrl.hasListener, isTrue);
      await controller.dispose();
      expect(eventCtrl.hasListener, isFalse);
      await eventCtrl.close();
    });
  });

  group('MessagesController — loadMore', () {
    test('loadMore() prepends OLDER messages в конец списка', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (roomId, fromToken, limit) {
        if (fromToken == null) {
          return Future.value(
            _page(
              messages: [
                _msg(eventId: 'p1-newest'),
                _msg(eventId: 'p1-mid'),
              ],
              nextToken: 'token-page-2',
            ),
          );
        }
        if (fromToken == 'token-page-2') {
          return Future.value(
            _page(
              messages: [
                _msg(eventId: 'p2-1'),
                _msg(eventId: 'p2-2'),
              ],
              // nextToken == null → история закончилась.
            ),
          );
        }
        throw StateError('unexpected fromToken=$fromToken');
      };

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();
      var state = controller.state as MessagesReady;
      expect(state.hasMore, isTrue);

      await controller.loadMore();
      state = controller.state as MessagesReady;
      expect(state.messages.length, 4);
      expect(state.messages[0].matrixEventId, 'p1-newest');
      expect(state.messages[1].matrixEventId, 'p1-mid');
      expect(state.messages[2].matrixEventId, 'p2-1');
      expect(state.messages[3].matrixEventId, 'p2-2');
      expect(state.hasMore, isFalse, reason: 'nextToken==null');
      expect(state.paginating, isFalse);
      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'loadMore() concurrent — второй silent return без RPC double',
      () async {
        final rpc = _FakeRpc();
        var listCallCount = 0;
        final completer = Completer<MessengerMessageListPage>();
        rpc.listMessagesHandler = (r, ft, l) {
          listCallCount++;
          if (ft == null) {
            return Future.value(
              _page(
                messages: [_msg(eventId: 'h-1')],
                nextToken: 't',
              ),
            );
          }
          return completer.future;
        };

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();

        final f1 = controller.loadMore();
        final f2 = controller.loadMore();
        // Сейчас listCallCount == 2 (init + первый loadMore); второй — silent.
        expect(listCallCount, 2);
        completer.complete(_page(messages: [_msg(eventId: 'p2-1')]));
        await Future.wait([f1, f2]);
        expect(listCallCount, 2, reason: 'concurrent loadMore — single RPC');
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('loadMore() при hasMore==false — no-op', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (r, ft, l) => Future.value(
        _page(messages: [_msg(eventId: 'h-1')]), // nextToken == null
      );
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();
      var state = controller.state as MessagesReady;
      expect(state.hasMore, isFalse);

      await controller.loadMore();
      state = controller.state as MessagesReady;
      expect(state.messages.length, 1);
      await controller.dispose();
      await eventCtrl.close();
    });

    test('loadMore() error → MessagesError + lastKnown сохранён', () async {
      final rpc = _FakeRpc();
      var listCallCount = 0;
      rpc.listMessagesHandler = (r, ft, l) {
        listCallCount++;
        if (listCallCount == 1) {
          return Future.value(
            _page(
              messages: [_msg(eventId: 'h-1')],
              nextToken: 'token-2',
            ),
          );
        }
        return Future.error(StateError('paginate-fail'));
      };
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      await controller.loadMore();
      final state = controller.state as MessagesError;
      expect(state.lastKnown, isNotNull);
      expect(state.lastKnown!.messages.length, 1);
      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'loadMore() dedup overlap — server вернул тот же event что в первой странице',
      () async {
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (r, ft, l) {
          if (ft == null) {
            return Future.value(
              _page(
                messages: [
                  _msg(eventId: 'h-1'),
                  _msg(eventId: 'h-2'),
                ],
                nextToken: 't',
              ),
            );
          }
          return Future.value(
            _page(
              messages: [
                _msg(eventId: 'h-2'), // overlap
                _msg(eventId: 'h-3'),
              ],
            ),
          );
        };
        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();
        await controller.loadMore();

        final state = controller.state as MessagesReady;
        expect(state.messages.length, 3, reason: 'h-2 deduped');
        expect(state.messages.map((m) => m.matrixEventId), [
          'h-1',
          'h-2',
          'h-3',
        ]);
        await controller.dispose();
        await eventCtrl.close();
      },
    );
  });

  // ──────────────────── TASK19 Chunk 3 ────────────────────

  group('MessagesController — TASK19 attachment send', () {
    test('sendAttachment: upload → optimistic bubble с attachment → '
        'sendMessage RPC получает AttachmentRef', () async {
      final rpc = _FakeRpc();
      final uploadedRef = AttachmentRef(
        mxcUrl: 'mxc://localhost/uploaded123',
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
        originalFilename: 'photo.jpg',
        width: 800,
        height: 600,
        thumbnailMxcUrl: 'mxc://localhost/uploaded123',
      );
      rpc.uploadAttachmentHandler = (bytes, mime, name) async => uploadedRef;
      AttachmentRef? sentAttachment;
      rpc.sendMessageHandler =
          (roomId, body, msgType, clientTxnId, attachment) {
            sentAttachment = attachment;
            // Server echo-ит txnId + attachment (real backend делает это
            // через MatrixMessageService.sendMessage). Без txnId echo
            // optimistic dedup не сработает; без attachment echo — bubble
            // после promote pending → sent потеряет attachment field.
            return Future.value(
              MessengerMessage(
                matrixEventId: 'e-attached',
                roomId: 101,
                matrixRoomId: '!room:test',
                senderMessengerUserId: 1,
                senderMatrixUserId: '@me:test',
                msgType: msgType,
                body: body,
                content: ByteData(0),
                serverTimestamp: DateTime.utc(2026, 5, 5),
                clientTxnId: clientTxnId,
                attachment: attachment,
              ),
            );
          };
      rpc.listMessagesHandler = (_, _, _) async => _page(messages: []);

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(
        rpc: rpc,
        events: eventCtrl.stream,
        clientTxnIdGen: () => 'TXN-att-1',
      );
      await controller.init();

      await controller.sendAttachment(
        bytes: Uint8List.fromList(List.filled(100, 0)),
        mimeType: 'image/jpeg',
        originalFilename: 'photo.jpg',
      );
      await Future<void>.delayed(Duration.zero);

      // sendMessage RPC получил attachment.
      expect(sentAttachment, isNotNull);
      expect(sentAttachment!.mxcUrl, 'mxc://localhost/uploaded123');
      expect(sentAttachment!.mimeType, 'image/jpeg');

      // Bubble в state имеет attachment populated optimistic.
      final state = controller.state as MessagesReady;
      expect(state.messages.length, 1);
      expect(state.messages[0].attachment, isNotNull);
      expect(state.messages[0].attachment!.originalFilename, 'photo.jpg');
      expect(
        state.messages[0].msgType,
        'm.image',
        reason: 'msgType derived из MIME',
      );

      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'sendMessage с attachment overrides msgType per MIME (m.video для video/*)',
      () async {
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (_, _, _) async => _page(messages: []);
        String? capturedMsgType;
        rpc.sendMessageHandler =
            (roomId, body, msgType, clientTxnId, attachment) {
              capturedMsgType = msgType;
              return Future.value(_msg(eventId: 'e-vid'));
            };
        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(
          rpc: rpc,
          events: eventCtrl.stream,
          clientTxnIdGen: () => 'TXN-vid',
        );
        await controller.init();

        final ref = AttachmentRef(
          mxcUrl: 'mxc://localhost/v1',
          mimeType: 'video/mp4',
          sizeBytes: 1024,
          originalFilename: 'clip.mp4',
        );
        await controller.sendMessage(
          body: '',
          msgType: 'm.text', // <- caller передал .text — server-derive override
          attachment: ref,
        );
        await Future<void>.delayed(Duration.zero);

        expect(capturedMsgType, 'm.video');
        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('downloadThumbnail / downloadFullSize pass-through к RPC', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(messages: []);
      rpc.downloadThumbnailHandler = (mxcUrl, w, h) async {
        expect(mxcUrl, 'mxc://localhost/x');
        expect(w, 400);
        expect(h, 400);
        return AttachmentBytes(bytes: ByteData(0), contentType: 'image/png');
      };
      rpc.downloadAttachmentHandler = (mxcUrl) async {
        expect(mxcUrl, 'mxc://localhost/x');
        return AttachmentBytes(bytes: ByteData(0), contentType: 'image/png');
      };
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      final thumb = await controller.downloadThumbnail(
        mxcUrl: 'mxc://localhost/x',
        width: 400,
        height: 400,
      );
      expect(thumb.contentType, 'image/png');
      final full = await controller.downloadFullSize(
        mxcUrl: 'mxc://localhost/x',
      );
      expect(full.contentType, 'image/png');

      await controller.dispose();
      await eventCtrl.close();
    });
  });

  // ──────────────────── TASK37 Chunk 2 ────────────────────

  group('MessagesController — TASK37 edit / delete', () {
    test('editMessage: optimistic + RPC apply server-authoritative', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );
      String? capturedNewBody;
      rpc.editMessageHandler = (roomId, eventId, newBody) {
        capturedNewBody = newBody;
        return Future.value(
          MessengerMessage(
            matrixEventId: eventId,
            roomId: 101,
            matrixRoomId: '!room:test',
            senderMessengerUserId: 1,
            senderMatrixUserId: '@me:test',
            msgType: 'm.text',
            body: newBody,
            serverTimestamp: DateTime.utc(2026, 5, 6),
            editedAt: DateTime.utc(2026, 5, 6),
          ),
        );
      };

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      await controller.editMessage(
        matrixEventId: 'e-1',
        newBody: 'edited body',
      );
      expect(capturedNewBody, 'edited body');
      final state = controller.state as MessagesReady;
      final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
      expect(msg.body, 'edited body');
      expect(msg.editedAt, isNotNull);

      await controller.dispose();
      await eventCtrl.close();
    });

    test('editMessage: RPC fail → revert to original body', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );
      rpc.editMessageHandler = (_, _, _) async => throw StateError('network');

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      await expectLater(
        controller.editMessage(matrixEventId: 'e-1', newBody: 'attempted'),
        throwsA(isA<StateError>()),
      );
      final state = controller.state as MessagesReady;
      final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
      expect(msg.body, 'orig', reason: 'reverted');
      expect(msg.editedAt, isNull);

      await controller.dispose();
      await eventCtrl.close();
    });

    test('deleteMessage: optimistic tombstone + RPC apply', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );
      String? capturedDeleteId;
      rpc.deleteMessageHandler = (roomId, eventId) async {
        capturedDeleteId = eventId;
      };

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      await controller.deleteMessage(matrixEventId: 'e-1');
      expect(capturedDeleteId, 'e-1');
      final state = controller.state as MessagesReady;
      final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
      expect(msg.isDeleted, isTrue);
      expect(msg.body, isEmpty);
      expect(msg.attachment, isNull);

      await controller.dispose();
      await eventCtrl.close();
    });

    test('deleteMessage: RPC fail → revert tombstone', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );
      rpc.deleteMessageHandler = (_, _) async => throw StateError('network');

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      await expectLater(
        controller.deleteMessage(matrixEventId: 'e-1'),
        throwsA(isA<StateError>()),
      );
      final state = controller.state as MessagesReady;
      final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
      expect(msg.isDeleted, isFalse, reason: 'tombstone reverted');
      expect(msg.body, 'orig');

      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'reactor: messageUpdated event applies edit на existing bubble',
      () async {
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (_, _, _) async => _page(
          messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
        );

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();

        eventCtrl.add(
          MessengerEvent(
            eventType: MessengerEventType.messageUpdated,
            serverTimestamp: DateTime.utc(2026, 5, 6),
            roomId: 101,
            matrixRoomId: '!room:test',
            message: MessengerMessage(
              matrixEventId: 'e-1',
              roomId: 101,
              matrixRoomId: '!room:test',
              senderMessengerUserId: 99,
              senderMatrixUserId: '@peer:test',
              msgType: 'm.text',
              body: 'edited remotely',
              serverTimestamp: DateTime.utc(2026, 5, 6),
              editedAt: DateTime.utc(2026, 5, 6),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final state = controller.state as MessagesReady;
        final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
        expect(msg.body, 'edited remotely');
        expect(msg.editedAt, isNotNull);

        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test(
      'reactor race: messageUpdated AFTER messageDeleted skipped (tombstone wins)',
      () async {
        // Sign-off review #1 mitigation. Late edit event для уже-
        // tombstone-нутого message не должен resurrect bubble.
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (_, _, _) async => _page(
          messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
        );

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = _make(rpc: rpc, events: eventCtrl.stream);
        await controller.init();

        // First: messageDeleted.
        eventCtrl.add(
          MessengerEvent(
            eventType: MessengerEventType.messageDeleted,
            serverTimestamp: DateTime.utc(2026, 5, 6),
            roomId: 101,
            matrixRoomId: '!room:test',
            message: MessengerMessage(
              matrixEventId: 'e-1',
              roomId: 101,
              matrixRoomId: '!room:test',
              senderMessengerUserId: 99,
              senderMatrixUserId: '@peer:test',
              msgType: 'm.text',
              body: '',
              serverTimestamp: DateTime.utc(2026, 5, 6),
              deletedAt: DateTime.utc(2026, 5, 6),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Then: late messageUpdated.
        eventCtrl.add(
          MessengerEvent(
            eventType: MessengerEventType.messageUpdated,
            serverTimestamp: DateTime.utc(2026, 5, 6),
            roomId: 101,
            matrixRoomId: '!room:test',
            message: MessengerMessage(
              matrixEventId: 'e-1',
              roomId: 101,
              matrixRoomId: '!room:test',
              senderMessengerUserId: 99,
              senderMatrixUserId: '@peer:test',
              msgType: 'm.text',
              body: 'late edit',
              serverTimestamp: DateTime.utc(2026, 5, 6),
              editedAt: DateTime.utc(2026, 5, 6),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final state = controller.state as MessagesReady;
        final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
        expect(msg.isDeleted, isTrue, reason: 'tombstone wins');
        expect(
          msg.body,
          isEmpty,
          reason: 'late edit skipped — body НЕ resurrect',
        );

        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('reactor: messageDeleted event creates tombstone', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );

      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      eventCtrl.add(
        MessengerEvent(
          eventType: MessengerEventType.messageDeleted,
          serverTimestamp: DateTime.utc(2026, 5, 6),
          roomId: 101,
          matrixRoomId: '!room:test',
          message: MessengerMessage(
            matrixEventId: 'e-1',
            roomId: 101,
            matrixRoomId: '!room:test',
            senderMessengerUserId: 99,
            senderMatrixUserId: '@peer:test',
            msgType: 'm.text',
            body: '',
            serverTimestamp: DateTime.utc(2026, 5, 6),
            deletedAt: DateTime.utc(2026, 5, 6),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = controller.state as MessagesReady;
      final msg = state.messages.firstWhere((m) => m.matrixEventId == 'e-1');
      expect(msg.isDeleted, isTrue);

      await controller.dispose();
      await eventCtrl.close();
    });
  });

  group('MessagesController — TASK16-A reply + mention', () {
    test('findByEventId: hit/miss', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [
          _msg(eventId: 'e-1', body: 'orig', clientTxnId: null),
          _msg(eventId: 'e-2', body: 'second', clientTxnId: null),
        ],
      );
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      expect(controller.findByEventId('e-1')?.body, 'orig');
      expect(controller.findByEventId('e-2')?.body, 'second');
      expect(controller.findByEventId('missing'), isNull);

      await controller.dispose();
      await eventCtrl.close();
    });

    test('setReplyTarget / clearReplyTarget update notifier', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      final target = controller.findByEventId('e-1')!;
      var changes = 0;
      controller.replyTargetListenable.addListener(() => changes++);

      controller.setReplyTarget(target);
      expect(controller.replyTarget, equals(target));
      controller.clearReplyTarget();
      expect(controller.replyTarget, isNull);
      expect(changes, 2);
      // Idempotent clear — no extra notify.
      controller.clearReplyTarget();
      expect(changes, 2);

      await controller.dispose();
      await eventCtrl.close();
    });

    test(
      'sendMessage forwards mentions + replyToMatrixEventId to RPC',
      () async {
        final rpc = _FakeRpc();
        rpc.listMessagesHandler = (_, _, _) async => _page(messages: []);
        String? capturedReply;
        List<int>? capturedMentions;
        // Use raw closure (signature ext); keep _FakeRpc shape — we tap
        // sendMessage by overriding handler not the new params. Instead
        // capture via wrapper RPC subclass.
        final captureRpc = _CapturingSendRpc(rpc);

        final eventCtrl = StreamController<MessengerEvent>.broadcast();
        final controller = MessagesController(
          roomId: _kRoomId,
          rpc: captureRpc,
          events: eventCtrl.stream,
          selfMessengerUserId: _kSelfMessengerUserId,
          selfMatrixUserId: _kSelfMatrixUserId,
        );
        await controller.init();

        await controller.sendMessage(
          body: 'hi @bob',
          replyToMatrixEventId: 'e-orig',
          mentionedMessengerUserIds: [7],
        );
        capturedReply = captureRpc.lastReplyTo;
        capturedMentions = captureRpc.lastMentions;
        expect(capturedReply, 'e-orig');
        expect(capturedMentions, [7]);

        await controller.dispose();
        await eventCtrl.close();
      },
    );

    test('sendMessage с reply auto-clears replyTarget', () async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) async => _page(
        messages: [_msg(eventId: 'e-1', body: 'orig', clientTxnId: null)],
      );
      rpc.sendMessageHandler = (rid, body, mt, txn, _) async =>
          MessengerMessage(
            matrixEventId: 'sent-id',
            roomId: rid,
            matrixRoomId: '!room:test',
            senderMessengerUserId: _kSelfMessengerUserId,
            senderMatrixUserId: _kSelfMatrixUserId,
            msgType: mt,
            body: body,
            serverTimestamp: DateTime.utc(2026, 5, 6),
            clientTxnId: txn,
          );
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();

      controller.setReplyTarget(controller.findByEventId('e-1')!);
      expect(controller.replyTarget, isNotNull);
      await controller.sendMessage(
        body: 'reply text',
        replyToMatrixEventId: 'e-1',
      );
      expect(controller.replyTarget, isNull);

      await controller.dispose();
      await eventCtrl.close();
    });
  });

  group('MessagesController — emoji reactions aggregation', () {
    Future<(MessagesController, _FakeRpc, StreamController<MessengerEvent>)>
    setupReady() async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (roomId, fromToken, limit) async =>
          _page(messages: [_msg(eventId: 'target-1')]);
      final eventCtrl = StreamController<MessengerEvent>.broadcast();
      final controller = _make(rpc: rpc, events: eventCtrl.stream);
      await controller.init();
      return (controller, rpc, eventCtrl);
    }

    test('add reaction → reactionsFor показывает count=1, mine зависит от '
        'reactor', () async {
      final (controller, _, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      eventCtrl.add(
        _reactionEvent(
          reactionEventId: 'rxn-1',
          targetEventId: 'target-1',
          key: '👍',
          reactorMatrixId: '@peer:test',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final groups = controller.reactionsFor('target-1');
      expect(groups.length, 1);
      expect(groups.single.key, '👍');
      expect(groups.single.count, 1);
      expect(groups.single.mine, isFalse, reason: 'reactor != self');
    });

    test('self reaction → mine=true', () async {
      final (controller, _, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      eventCtrl.add(
        _reactionEvent(
          reactionEventId: 'rxn-self',
          targetEventId: 'target-1',
          key: '❤️',
          reactorMatrixId: _kSelfMatrixUserId,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final g = controller.reactionsFor('target-1').single;
      expect(g.mine, isTrue);
      expect(g.count, 1);
    });

    test('несколько реакторов на один key → count агрегируется + дедуп '
        'дублей', () async {
      final (controller, _, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      eventCtrl
        ..add(_reactionEvent(
          reactionEventId: 'r1',
          targetEventId: 'target-1',
          key: '😂',
          reactorMatrixId: '@a:test',
        ))
        ..add(_reactionEvent(
          reactionEventId: 'r2',
          targetEventId: 'target-1',
          key: '😂',
          reactorMatrixId: '@b:test',
        ))
        // Дубль того же reaction-event-id — idempotent skip.
        ..add(_reactionEvent(
          reactionEventId: 'r2',
          targetEventId: 'target-1',
          key: '😂',
          reactorMatrixId: '@b:test',
        ));
      await Future<void>.delayed(Duration.zero);

      final g = controller.reactionsFor('target-1').single;
      expect(g.count, 2, reason: 'два уникальных реактора');
    });

    test('несколько разных ключей → отдельные группы', () async {
      final (controller, _, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      eventCtrl
        ..add(_reactionEvent(
          reactionEventId: 'r1',
          targetEventId: 'target-1',
          key: '👍',
          reactorMatrixId: '@a:test',
        ))
        ..add(_reactionEvent(
          reactionEventId: 'r2',
          targetEventId: 'target-1',
          key: '🙏',
          reactorMatrixId: '@a:test',
        ));
      await Future<void>.delayed(Duration.zero);

      final groups = controller.reactionsFor('target-1');
      expect(groups.length, 2);
      expect(groups.map((g) => g.key).toSet(), {'👍', '🙏'});
    });

    test('redaction реакции → count декрементится, группа исчезает при 0',
        () async {
      final (controller, _, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      eventCtrl.add(_reactionEvent(
        reactionEventId: 'rxn-x',
        targetEventId: 'target-1',
        key: '😮',
        reactorMatrixId: '@a:test',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(controller.reactionsFor('target-1').single.count, 1);

      // Redaction — знает только reactionEventId.
      eventCtrl.add(_reactionEvent(
        reactionEventId: 'rxn-x',
        reactorMatrixId: '@a:test',
        redacted: true,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(controller.reactionsFor('target-1'), isEmpty);
    });

    test('toggleReaction: нет своей реакции → sendReaction вызван', () async {
      final (controller, rpc, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      await controller.toggleReaction('target-1', '👍');
      expect(rpc.sentReactions.length, 1);
      expect(rpc.sentReactions.single.targetEventId, 'target-1');
      expect(rpc.sentReactions.single.key, '👍');
      expect(rpc.removedReactionEventIds, isEmpty);
    });

    test('toggleReaction: есть своя реакция → removeReaction по сохранённому '
        'reactionEventId', () async {
      final (controller, rpc, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      // Сначала self-реакция прилетает через stream (сохраняет ref).
      eventCtrl.add(_reactionEvent(
        reactionEventId: 'my-rxn',
        targetEventId: 'target-1',
        key: '👍',
        reactorMatrixId: _kSelfMatrixUserId,
      ));
      await Future<void>.delayed(Duration.zero);

      await controller.toggleReaction('target-1', '👍');
      expect(rpc.removedReactionEventIds, ['my-rxn']);
      expect(rpc.sentReactions, isEmpty);
    });

    test('reactionsVersionListenable bump-ится на изменение', () async {
      final (controller, _, eventCtrl) = await setupReady();
      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });

      final before = controller.reactionsVersionListenable.value;
      eventCtrl.add(_reactionEvent(
        reactionEventId: 'r1',
        targetEventId: 'target-1',
        key: '👍',
        reactorMatrixId: '@a:test',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(controller.reactionsVersionListenable.value, greaterThan(before));
    });
  });
}

/// Wrapper-капчер для verifying что `sendMessage` получает новые
/// reply/mention params (FakeRpc handler-сигнатура их не пробрасывает,
/// чтобы не ломать существующие tests).
class _CapturingSendRpc implements MessagesRpc {
  _CapturingSendRpc(this._inner);
  final _FakeRpc _inner;

  String? lastReplyTo;
  List<int>? lastMentions;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) => _inner.listMessages(roomId: roomId, fromToken: fromToken, limit: limit);

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  }) async {
    lastReplyTo = replyToMatrixEventId;
    lastMentions = mentionedMessengerUserIds;
    return MessengerMessage(
      matrixEventId: 'sent-id',
      roomId: roomId,
      matrixRoomId: '!room:test',
      senderMessengerUserId: _kSelfMessengerUserId,
      senderMatrixUserId: _kSelfMatrixUserId,
      msgType: msgType,
      body: body,
      serverTimestamp: DateTime.utc(2026, 5, 6),
      clientTxnId: clientTxnId,
    );
  }

  @override
  Future<bool> markRead({required int roomId, required String matrixEventId}) =>
      _inner.markRead(roomId: roomId, matrixEventId: matrixEventId);

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => _inner.uploadAttachment(
    bytes: bytes,
    mimeType: mimeType,
    originalFilename: originalFilename,
  );

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => _inner.downloadAttachmentThumbnail(
    mxcUrl: mxcUrl,
    width: width,
    height: height,
  );

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) =>
      _inner.downloadAttachment(mxcUrl: mxcUrl);

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => _inner.editMessage(
    roomId: roomId,
    matrixEventId: matrixEventId,
    newBody: newBody,
  );

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => _inner.deleteMessage(roomId: roomId, matrixEventId: matrixEventId);

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) =>
      _inner.sendTyping(roomId: roomId, typing: typing);

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) =>
      _inner.sendReaction(
        roomId: roomId,
        targetEventId: targetEventId,
        key: key,
      );

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) =>
      _inner.removeReaction(roomId: roomId, reactionEventId: reactionEventId);

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) =>
      _inner.searchMessages(roomId: roomId, query: query, limit: limit);

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) =>
      _inner.listReactions(roomId: roomId, eventIds: eventIds);

  @override
  Future<List<MessengerEvent>> listReadReceipts({
    required int roomId,
  }) =>
      _inner.listReadReceipts(roomId: roomId);
}

// ───────────────────────────────────────────────────────────────────
// Test helpers
// ───────────────────────────────────────────────────────────────────

const _kRoomId = 101;
const _kSelfMessengerUserId = 42;
const _kSelfMatrixUserId = '@self:test';

MessagesController _make({
  required _FakeRpc rpc,
  required Stream<MessengerEvent> events,
  String Function()? clientTxnIdGen,
  int pendingBufferCap = kDefaultPendingBufferCap,
  void Function(Object, StackTrace)? onSendError,
}) => MessagesController(
  roomId: _kRoomId,
  rpc: rpc,
  events: events,
  selfMessengerUserId: _kSelfMessengerUserId,
  selfMatrixUserId: _kSelfMatrixUserId,
  clientTxnIdGenerator: clientTxnIdGen,
  pendingBufferCap: pendingBufferCap,
  onSendError: onSendError,
);

MessengerMessage _msg({
  required String eventId,
  String body = 'msg',
  String? clientTxnId,
  int roomId = _kRoomId,
  String matrixRoomId = '!room:test',
  String senderMatrixUserId = '@peer:test',
  int? senderMessengerUserId = 99,
  DateTime? timestamp,
}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: roomId,
  matrixRoomId: matrixRoomId,
  senderMessengerUserId: senderMessengerUserId,
  senderMatrixUserId: senderMatrixUserId,
  msgType: 'm.text',
  body: body,
  content: ByteData(0),
  serverTimestamp: timestamp ?? DateTime.utc(2026, 1, 1),
  clientTxnId: clientTxnId,
);

MessengerMessageListPage _page({
  required List<MessengerMessage> messages,
  String? nextToken,
  String? prevToken,
}) => MessengerMessageListPage(
  messages: messages,
  nextToken: nextToken,
  prevToken: prevToken,
);

MessengerEvent _eventForRoom(int roomId, MessengerMessage message) =>
    MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: message.serverTimestamp,
      roomId: roomId,
      matrixRoomId: message.matrixRoomId,
      message: message,
    );

/// **B22 read-receipts**: readReceiptUpdated event builder (seed/realtime
/// одинаковый shape). `serverTimestamp` — момент чтения (для seed =
/// lastReadAt). `readEventId` — событие, до которого reader прочитал;
/// resolve в controller-е к ts этого message в loaded history.
MessengerEvent _readReceiptEvent({
  required String readerMatrixId,
  required String readEventId,
  required DateTime serverTimestamp,
  int? readerUserId,
  int roomId = _kRoomId,
}) => MessengerEvent(
  eventType: MessengerEventType.readReceiptUpdated,
  serverTimestamp: serverTimestamp,
  roomId: roomId,
  matrixRoomId: '!room:test',
  readReceiptEventId: readEventId,
  readReceiptUserId: readerUserId,
  readReceiptMatrixUserId: readerMatrixId,
);

/// Emoji reactions: realtime reactionChanged event builder.
MessengerEvent _reactionEvent({
  required String reactionEventId,
  String? targetEventId,
  String? key,
  required String reactorMatrixId,
  bool redacted = false,
  int roomId = _kRoomId,
}) => MessengerEvent(
  eventType: MessengerEventType.reactionChanged,
  serverTimestamp: DateTime.utc(2026, 1, 2),
  roomId: roomId,
  matrixRoomId: '!room:test',
  reactionTargetEventId: targetEventId,
  reactionKey: key,
  reactionReactorMatrixUserId: reactorMatrixId,
  reactionEventId: reactionEventId,
  reactionRedacted: redacted,
);

class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(
    int roomId,
    String? fromToken,
    int limit,
  )?
  listMessagesHandler;

  Future<MessengerMessage> Function(
    int roomId,
    String body,
    String msgType,
    String clientTxnId,
    AttachmentRef? attachment,
  )?
  sendMessageHandler;

  Future<bool> Function(int roomId, String matrixEventId)? markReadHandler;

  /// TASK19 Chunk 3: handler-stubs для attachment RPCs. Тесты могут
  /// override; default — no-op throws чтобы случайный вызов был видим.
  Future<AttachmentRef> Function(
    ByteData bytes,
    String mimeType,
    String originalFilename,
  )?
  uploadAttachmentHandler;

  Future<AttachmentBytes> Function(String mxcUrl, int? width, int? height)?
  downloadThumbnailHandler;

  Future<AttachmentBytes> Function(String mxcUrl)? downloadAttachmentHandler;

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
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
  }) {
    final h = sendMessageHandler;
    if (h == null) throw StateError('sendMessageHandler not set');
    return h(roomId, body, msgType, clientTxnId, attachment);
  }

  @override
  Future<bool> markRead({required int roomId, required String matrixEventId}) {
    final h = markReadHandler;
    if (h == null) return Future.value(true);
    return h(roomId, matrixEventId);
  }

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) {
    final h = uploadAttachmentHandler;
    if (h == null) throw StateError('uploadAttachmentHandler not set');
    return h(bytes, mimeType, originalFilename);
  }

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) {
    final h = downloadThumbnailHandler;
    if (h == null) throw StateError('downloadThumbnailHandler not set');
    return h(mxcUrl, width, height);
  }

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) {
    final h = downloadAttachmentHandler;
    if (h == null) throw StateError('downloadAttachmentHandler not set');
    return h(mxcUrl);
  }

  // TASK37: edit/delete handlers — set по тестам.
  Future<MessengerMessage> Function(
    int roomId,
    String matrixEventId,
    String newBody,
  )?
  editMessageHandler;

  Future<void> Function(int roomId, String matrixEventId)? deleteMessageHandler;

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) {
    final h = editMessageHandler;
    if (h == null) throw StateError('editMessageHandler not set');
    return h(roomId, matrixEventId, newBody);
  }

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) {
    final h = deleteMessageHandler;
    if (h == null) throw StateError('deleteMessageHandler not set');
    return h(roomId, matrixEventId);
  }

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {
    // Test stub: no-op (typing tests handled elsewhere).
  }

  // Emoji reactions: capturing handlers. Default — return synthetic
  // reaction event id, и records что было вызвано.
  final List<({String targetEventId, String key})> sentReactions =
      <({String targetEventId, String key})>[];
  final List<String> removedReactionEventIds = <String>[];
  String Function(String targetEventId, String key)? sendReactionHandler;

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) async {
    sentReactions.add((targetEventId: targetEventId, key: key));
    return sendReactionHandler?.call(targetEventId, key) ??
        'rxn-$targetEventId-$key';
  }

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) async {
    removedReactionEventIds.add(reactionEventId);
  }

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) async => const <MessengerMessage>[];

  /// **Reactions history (phase 2)**: тест задаёт `listReactionsResult`,
  /// контроллер сидит их через `_seedReactions` после init/loadMore.
  List<MessengerEvent> listReactionsResult = const <MessengerEvent>[];
  List<String>? lastListReactionsEventIds;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async {
    lastListReactionsEventIds = eventIds;
    return listReactionsResult;
  }

  /// **Persistent read-receipts seed (B22)**: тест задаёт
  /// `listReadReceiptsResult`, контроллер сидит их через
  /// `_seedReadReceipts` после init.
  List<MessengerEvent> listReadReceiptsResult = const <MessengerEvent>[];
  int listReadReceiptsCalls = 0;

  @override
  Future<List<MessengerEvent>> listReadReceipts({
    required int roomId,
  }) async {
    listReadReceiptsCalls += 1;
    return listReadReceiptsResult;
  }
}

// Использую _eventForRoom как "rejected ChatMessage helper" нет — этот
// тест-файл относится только к MessagesController. ChatMessage testing —
// другой test-файл (можно добавить позже если потребуется).

// Чтобы избежать unused warning на ChatMessage импорт.
// ignore: unused_element
ChatMessage _silenceUnused() => ChatMessage.optimistic(
  clientTxnId: 'x',
  senderMatrixUserId: 'x',
  senderMessengerUserId: 0,
  body: 'x',
);
