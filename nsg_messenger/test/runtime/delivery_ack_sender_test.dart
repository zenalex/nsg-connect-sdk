/// **issue #78 — подтверждение доставки с активного клиента.**
///
/// Сервер больше не гадает по presence, где сейчас человек: пуш уходит
/// тогда и только тогда, когда сообщение не принял ни один живой клиент.
/// Цена ошибки несимметрична — подтвердить лишнего значит съесть нужное
/// уведомление, поэтому подтверждает только окно на переднем плане и в
/// фокусе.
library;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/runtime/app_visibility.dart';
import 'package:nsg_messenger/src/runtime/delivery_ack_sender.dart';

void main() {
  late List<List<String>> sent;
  late AppLifecycleState lifecycle;

  DeliveryAckSender build({Duration? debounce}) => DeliveryAckSender(
    confirmDelivery: ({required List<String> matrixEventIds}) async {
      sent.add(matrixEventIds);
    },
    debounce: debounce ?? const Duration(milliseconds: 10),
    lifecycleProbe: () => lifecycle,
  );

  setUp(() {
    sent = [];
    lifecycle = AppLifecycleState.resumed;
  });

  test('активное окно подтверждает приём', () async {
    build().noteDelivered('\$e1');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sent, [
      ['\$e1'],
    ]);
  });

  test('очередь событий схлопывается в одну отправку', () async {
    final sender = build();
    for (final id in ['\$a', '\$b', '\$c']) {
      sender.noteDelivered(id);
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sent, hasLength(1));
    expect(sent.single, ['\$a', '\$b', '\$c']);
  });

  test('повтор одного события не задваивается', () async {
    final sender = build();
    sender.noteDelivered('\$a');
    sender.noteDelivered('\$a');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sent.single, ['\$a']);
  });

  group('неактивное окно не подтверждает', () {
    // Иначе уведомление съедалось бы ровно тогда, когда оно и нужно.
    for (final state in [
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.detached,
    ]) {
      test('$state', () async {
        lifecycle = state;
        build().noteDelivered('\$e1');
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(sent, isEmpty);
      });
    }
  });

  test('расфокусированный десктоп не подтверждает за человека', () async {
    // Окно видно, но человек ушёл в браузер — телефон должен зазвонить.
    final sender = build();
    lifecycle = AppLifecycleState.inactive;
    sender.noteDelivered('\$e1');
    lifecycle = AppLifecycleState.resumed;
    sender.noteDelivered('\$e2');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sent.single, ['\$e2'], reason: 'принято только то, что увидели');
  });

  test('большая пачка уходит не дожидаясь дебаунса', () async {
    final sender = build(debounce: const Duration(seconds: 30));
    for (var i = 0; i < DeliveryAckSender.maxBatch; i++) {
      sender.noteDelivered('\$e$i');
    }
    await Future<void>.delayed(Duration.zero);
    expect(sent.single, hasLength(DeliveryAckSender.maxBatch));
  });

  test('сбой RPC не роняет клиента — пуш просто придёт', () async {
    Object? reported;
    final sender = DeliveryAckSender(
      confirmDelivery: ({required List<String> matrixEventIds}) async =>
          throw StateError('нет сети'),
      debounce: const Duration(milliseconds: 10),
      lifecycleProbe: () => lifecycle,
      onError: (e, _) => reported = e,
    );
    sender.noteDelivered('\$e1');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(reported, isA<StateError>());
  });

  test('после dispose ничего не отправляется', () async {
    final sender = build();
    sender.dispose();
    sender.noteDelivered('\$e1');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(sent, isEmpty);
  });

  group('окно спрятано в трей', () {
    // Flutter это сменой состояния НЕ считает — приложение остаётся
    // `resumed`. Подтвердив доставку из трея, клиент оставил бы человека,
    // отошедшего от компьютера, без уведомления на телефоне.
    tearDown(AppVisibility.reset);

    DeliveryAckSender platformSender() => DeliveryAckSender(
      confirmDelivery: ({required List<String> matrixEventIds}) async {
        sent.add(matrixEventIds);
      },
      debounce: const Duration(milliseconds: 10),
    );

    test('спрятанное окно не подтверждает', () async {
      AppVisibility.setHidden(true);
      platformSender().noteDelivered('\$e1');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(sent, isEmpty);
    });

    test('вернули окно — подтверждает снова', () async {
      AppVisibility.setHidden(true);
      AppVisibility.setHidden(false);
      platformSender().noteDelivered('\$e1');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(sent, [
        ['\$e1'],
      ]);
    });
  });

  test('без RPC (тесты, старый хост) — тихий no-op', () async {
    final sender = DeliveryAckSender(
      confirmDelivery: null,
      lifecycleProbe: () => lifecycle,
    );
    sender.noteDelivered('\$e1');
    sender.flushNow();
    expect(sent, isEmpty);
  });
}
