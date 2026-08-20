/// **Что из транспорта попадает в трекер ошибок.**
///
/// Найдено 08.08.2026 при разборе GlitchTip: `WebSocketConnectException` —
/// 1936 событий, самая громкая группа проекта. Причина не в поломке: КАЖДЫЙ
/// обрыв сокета уезжал как ошибка, хотя обрыв транзиентен по природе (телефон
/// уснул, сеть переключилась, крышку закрыли) и шина сама его лечит
/// переподключением. Настоящие ошибки при этом тонули, а заведённая в тот же
/// день телеметрия медленных вызовов утонула бы следом.
///
/// Правило теперь такое: молчим, пока это моргание, и сообщаем один раз,
/// когда признаём, что связи нет.
library;

import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

void main() {
  Future<void> pump([int ms = 40]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  MessengerEvent event() => MessengerEvent(
    eventType: MessengerEventType.messageCreated,
    serverTimestamp: DateTime.now().toUtc(),
    roomId: 1,
    matrixRoomId: '!r:localhost',
  );

  /// Шина, у которой каждая новая подписка получает свежий контроллер, а
  /// ошибки-отчёты копятся в [reported].
  ({
    MessengerEventBus bus,
    List<Object> reported,
    List<StreamController<MessengerEvent>> controllers,
    StreamController<MessengerSessionState> state,
  })
  makeBus({
    required int slots,
    int? disconnectedAfter,
    Duration? outageReportAfter,
  }) {
    final controllers = List.generate(
      slots,
      (_) => StreamController<MessengerEvent>.broadcast(),
    );
    var idx = 0;
    final reported = <Object>[];
    final state = StreamController<MessengerSessionState>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => controllers[idx < slots ? idx++ : slots - 1].stream,
      sessionStateStream: state.stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      jitterRng: Random(0),
      disconnectedAfterFailures: disconnectedAfter,
      // **issue #118**: в тестах порог длительности почти нулевой — иначе
      // пришлось бы ждать две минуты. Само правило «по длительности, а не по
      // числу попыток» проверяется отдельным тестом ниже.
      outageReportAfter: outageReportAfter ?? Duration.zero,
      onError: (e, _) => reported.add(e),
    );
    return (
      bus: bus,
      reported: reported,
      controllers: controllers,
      state: state,
    );
  }

  test('одиночное моргание в трекер не уезжает', () async {
    // Самый частый случай: связь моргнула и тут же вернулась. Раньше это
    // была ошибка в GlitchTip; теперь — рабочий момент.
    final t = makeBus(
      slots: 4,
      disconnectedAfter: 3,
      outageReportAfter: const Duration(seconds: 5),
    );
    final sub = t.bus.events.listen((_) {});
    await pump();

    t.controllers[0].addError(StateError('обрыв'), StackTrace.current);
    await pump();

    expect(t.reported, isEmpty);
    await sub.cancel();
    await t.bus.dispose();
  });

  test('рестарт сервера: серия неудач за секунду — молчим (issue #118)',
      () async {
    // Прежний порог считался в попытках: третья наступала через полторы
    // секунды, а столько длится ЛЮБОЙ наш деплой. В сутки набегало полторы
    // сотни «связь моргнула» — по событию на каждого подключённого клиента
    // на каждую выкатку, и настоящие поломки в этом тонули.
    //
    // Порог теперь по длительности, поэтому серия быстрых неудач молчит.
    final t = makeBus(
      slots: 8,
      disconnectedAfter: 2,
      outageReportAfter: const Duration(seconds: 5),
    );
    final sub = t.bus.events.listen((_) {});
    await pump();

    for (var i = 0; i < 4; i++) {
      t.controllers[i].addError(StateError('рестарт $i'), StackTrace.current);
      await pump();
    }

    expect(
      t.reported,
      isEmpty,
      reason: 'связь лежит секунду — это ещё не новость для трекера',
    );
    // Человеку при этом уже сказано: состояние баннера не ждёт порога.
    expect(t.bus.connectionState, MessengerConnectionState.disconnected);
    await sub.cancel();
    await t.bus.dispose();
  });

  test('сообщаем один раз, когда признали, что связи нет', () async {
    final t = makeBus(slots: 6, disconnectedAfter: 2);
    final sub = t.bus.events.listen((_) {});
    await pump();

    t.controllers[0].addError(StateError('обрыв 1'), StackTrace.current);
    await pump();
    t.controllers[1].addError(StateError('обрыв 2'), StackTrace.current);
    await pump();

    expect(t.reported, hasLength(1));
    expect(t.bus.connectionState, MessengerConnectionState.disconnected);
    await sub.cancel();
    await t.bus.dispose();
  });

  test('дальнейшие неудачи не повторяют отчёт', () async {
    // Строго на границе, а не «>= порога»: иначе шум вернулся бы в новом
    // виде — по событию на каждую попытку переподключения.
    final t = makeBus(slots: 8, disconnectedAfter: 2);
    final sub = t.bus.events.listen((_) {});
    await pump();

    for (var i = 0; i < 4; i++) {
      t.controllers[i].addError(StateError('обрыв $i'), StackTrace.current);
      await pump();
    }

    expect(t.reported, hasLength(1));
    await sub.cancel();
    await t.bus.dispose();
  });

  test('после восстановления следующий обрыв снова виден', () async {
    // Счётчик обнуляется живым событием — иначе первая же долгая пропажа
    // связи навсегда выключила бы отчётность.
    final t = makeBus(slots: 8, disconnectedAfter: 2);
    final sub = t.bus.events.listen((_) {});
    await pump();

    t.controllers[0].addError(StateError('a1'), StackTrace.current);
    await pump();
    t.controllers[1].addError(StateError('a2'), StackTrace.current);
    await pump();
    expect(t.reported, hasLength(1));

    // Связь вернулась: пришло живое событие.
    t.controllers[2].add(event());
    await pump();
    expect(t.bus.connectionState, MessengerConnectionState.healthy);

    t.controllers[2].addError(StateError('b1'), StackTrace.current);
    await pump();
    t.controllers[3].addError(StateError('b2'), StackTrace.current);
    await pump();

    expect(t.reported, hasLength(2), reason: 'новая пропажа — новая новость');
    await sub.cancel();
    await t.bus.dispose();
  });

  test('в отчёте нет артефакта dart:io с портом 0', () async {
    // Иначе разбор начинается с погони за несуществующим адресом
    // «https://host:0/v1/websocket#» — я на неё сегодня и потратил время.
    final t = makeBus(slots: 4, disconnectedAfter: 1);
    final sub = t.bus.events.listen((_) {});
    await pump();

    t.controllers[0].addError(
      StateError(
        "Connection to 'https://api.chatista.me:0/v1/websocket#' was not "
        'upgraded to websocket',
      ),
      StackTrace.current,
    );
    await pump();

    expect(t.reported, hasLength(1));
    final text = t.reported.single.toString();
    expect(text, contains('wss://api.chatista.me/v1/websocket'));
    expect(text, isNot(contains(':0/')));
    await sub.cancel();
    await t.bus.dispose();
  });
}
