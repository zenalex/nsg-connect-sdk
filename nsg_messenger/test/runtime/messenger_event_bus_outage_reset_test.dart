/// **issue #170 — отчёт о пропаже связи выписывался по протухшей отметке.**
///
/// В GlitchTip к 27.08.2026 накопилось 109 групп «Связь со стримом не
/// восстановилась за N с» — 40 % всех групп проекта. У ВСЕХ ста девяти в
/// тексте стояло «(1 попыток)», а заявленная пропажа доходила до 28 часов.
/// Одной попытки при заявленных часах не бывает: отсчёт начинается на первой
/// неудаче, и на ней же разница с началом равна нулю.
///
/// Причина — половинчатый сброс. Восстановление связи забывали в трёх местах,
/// и одно из них (подтверждение реконнекта для ТИХОГО аккаунта, где живого
/// события можно не дождаться) сбрасывало только счётчик попыток. Отметка
/// начала пропажи и флаг «уже отрапортовали» переживали восстановление.
///
/// Отсюда сразу две беды, и вторая дороже первой:
///
///   1. протухшая отметка → следующая единичная осечка мгновенно рапортует
///      «связь не восстановилась за 28 часов», засчитывая в пропажу время,
///      когда связь работала;
///   2. невзведённый обратно флаг → следующая НАСТОЯЩАЯ пропажа не
///      рапортуется вовсе. Ровно та, ради которой отчёт и заводился.
///
/// Оба теста ниже — на восстановление ЧЕРЕЗ ПОДТВЕРЖДЕНИЕ, без живого
/// события: восстановление событием проверялось и раньше, и оно как раз
/// работало. Дыра была в соседней ветке, которую тесты не трогали.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';
import 'package:nsg_messenger/src/runtime/stream_outage.dart';

void main() {
  Future<void> pump([int ms = 40]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// Шина, у которой каждая новая подписка получает свежий контроллер.
  ///
  /// [confirmAfter] — та самая ветка: подписка встала и прожила это время без
  /// единого события, значит транспорт здоров.
  ({
    MessengerEventBus bus,
    List<Object> reported,
    List<StreamController<MessengerEvent>> controllers,
  })
  makeBus({
    required Duration outageReportAfter,
    required Duration confirmAfter,
  }) {
    const slots = 6;
    final controllers = List.generate(
      slots,
      (_) => StreamController<MessengerEvent>.broadcast(),
    );
    var idx = 0;
    final reported = <Object>[];
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => controllers[idx < slots ? idx++ : slots - 1].stream,
      sessionStateStream:
          StreamController<MessengerSessionState>.broadcast().stream,
      reconnectBackoff: const [Duration(milliseconds: 1)],
      jitterRng: Random(0),
      disconnectedAfterFailures: 1,
      outageReportAfter: outageReportAfter,
      reconnectConfirmDelay: confirmAfter,
      onError: (e, _) => reported.add(e),
    );
    return (bus: bus, reported: reported, controllers: controllers);
  }

  test('после тихого восстановления единичная осечка молчит', () async {
    // Беда №1. Порог — 60 мс, и ко второй осечке с НАЧАЛА ПРОШЛОЙ пропажи
    // проходит заведомо больше. Если отметка пережила восстановление, отчёт
    // выпишется мгновенно и соврёт про длительность.
    final t = makeBus(
      outageReportAfter: const Duration(milliseconds: 60),
      confirmAfter: const Duration(milliseconds: 20),
    );
    final sub = t.bus.events.listen((_) {});
    await pump();

    t.controllers[0].addError(StateError('обрыв'), StackTrace.current);
    await pump(120); // реконнект + подтверждение + сверх порога

    expect(
      t.bus.connectionState,
      MessengerConnectionState.healthy,
      reason:
          'подтверждение реконнекта обязано было сработать — '
          'иначе тест проверяет не ту ветку',
    );
    expect(t.reported, isEmpty, reason: 'первая осечка порога не достигла');

    t.controllers[1].addError(StateError('новая осечка'), StackTrace.current);
    await pump();

    expect(
      t.reported,
      isEmpty,
      reason:
          'связь восстанавливалась — отсчёт пропажи начинается заново, '
          'а не продолжает прошлый',
    );
    await sub.cancel();
    await t.bus.dispose();
  });

  test('после тихого восстановления настоящая пропажа снова слышна', () async {
    // Беда №2, дорогая: флаг «уже отрапортовали» глушил ВСЕ следующие
    // пропажи до перезапуска приложения.
    final t = makeBus(
      outageReportAfter: Duration.zero,
      confirmAfter: const Duration(milliseconds: 20),
    );
    final sub = t.bus.events.listen((_) {});
    await pump();

    t.controllers[0].addError(StateError('пропажа 1'), StackTrace.current);
    await pump(120); // отчёт + реконнект + подтверждение
    expect(t.reported, hasLength(1));
    expect(t.bus.connectionState, MessengerConnectionState.healthy);

    t.controllers[1].addError(StateError('пропажа 2'), StackTrace.current);
    await pump();

    expect(
      t.reported,
      hasLength(2),
      reason: 'новая пропажа — новая новость, даже если прошлую уже сообщали',
    );
    await sub.cancel();
    await t.bus.dispose();
  });

  test(
    'в отчёте нет чисел — иначе каждая пропажа заводит свою группу',
    () async {
      final t = makeBus(
        outageReportAfter: Duration.zero,
        confirmAfter: const Duration(seconds: 30),
      );
      final sub = t.bus.events.listen((_) {});
      await pump();

      t.controllers[0].addError(
        StateError('канал закрылся'),
        StackTrace.current,
      );
      await pump();

      expect(t.reported, hasLength(1));
      final outage = t.reported.single;
      expect(outage, isA<StreamOutage>());
      expect(
        outage.toString(),
        isNot(matches(RegExp(r'\d'))),
        reason:
            'любая цифра в тексте — это новая группа в трекере на каждую '
            'пропажу; в причине («Bad state: канал закрылся») цифр нет',
      );
      expect(outage.toString(), contains('канал закрылся'));

      final tags = (outage as StreamOutage).tags;
      expect(
        tags.keys,
        containsAll(<String>['outage.seconds', 'outage.attempts']),
        reason: 'числа не пропали, а переехали туда, где по ним ищут',
      );
      expect(tags['outage.attempts'], '1');
      await sub.cancel();
      await t.bus.dispose();
    },
  );

  test('сброс пропажи живёт в одном месте', () {
    // Сторож против повторения #170: беда была не в логике сброса, а в том,
    // что его переписали в трёх местах и одно отстало. Пока присваивания
    // живут только в `_forgetOutage`, разойтись нечему.
    final src = File(
      'lib/src/runtime/messenger_event_bus.dart',
    ).readAsStringSync();
    for (final line in const [
      '_outageStartedAt = null;',
      '_outageReported = false;',
    ]) {
      // Только присваивание отдельной строкой: объявление поля
      // (`bool _outageReported = false;`) — не сброс.
      final assignment = RegExp(
        r'^\s*' + RegExp.escape(line) + r'\s*$',
        multiLine: true,
      );
      expect(
        assignment.allMatches(src).length,
        1,
        reason:
            'Сброс «$line» встречается не один раз. Так и появился #170: '
            'третье место сбрасывало половину полей, и отчёты о пропаже '
            'связи стали враньём. Сбрасывать — только через _forgetOutage().',
      );
    }
  });
}
