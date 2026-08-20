/// **Очередь стартовой загрузки скрытых панелей** — issue #141.
///
/// Замер на проде показал: восемь вызовов от одного человека в одну секунду,
/// каждый ~2,2 с, причём вызов с двумя запросами занял почти столько же,
/// сколько вызов с пятнадцатью. Время определялось не работой, а тем, что
/// всё пришло разом. Очередь разводит скрытые панели по одной; активная не
/// ждёт никого.
///
/// Проверяется здесь то, ради чего очередь заведена: параллельных загрузок
/// нет, показанная панель не ждёт чужих, а упавшая не останавливает
/// остальных.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/screens/pane_load_queue.dart';

void main() {
  setUp(PaneLoadQueue.resetForTesting);
  tearDown(PaneLoadQueue.resetForTesting);

  test('скрытые панели грузятся ПО ОДНОЙ, а не разом', () async {
    // Ровно то, чего не хватало на проде: пять панелей стартовали
    // одновременно, и каждая получила время всех остальных.
    var inFlight = 0;
    var maxInFlight = 0;
    final done = <String>[];

    Future<void> load(String name) async {
      inFlight++;
      if (inFlight > maxInFlight) maxInFlight = inFlight;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      inFlight--;
      done.add(name);
    }

    for (final n in ['a', 'b', 'c']) {
      PaneLoadQueue.enqueue(n, () => load(n));
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(maxInFlight, 1, reason: 'две загрузки разом — это и есть залп');
    expect(done, ['a', 'b', 'c'], reason: 'порядок постановки сохраняется');
  });

  test('показанная панель грузится СРАЗУ, не дожидаясь очереди', () async {
    // Иначе человек, переключившийся на ещё не загруженную панель, ждал бы
    // чужие истории — то есть мы обменяли бы один вид ожидания на другой.
    final started = <String>[];
    final gate = Completer<void>();

    PaneLoadQueue.enqueue('первая', () async {
      started.add('первая');
      await gate.future; // держим очередь
    });
    PaneLoadQueue.enqueue('вторая', () async => started.add('вторая'));
    PaneLoadQueue.enqueue('третья', () async => started.add('третья'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(started, ['первая'], reason: 'очередь занята первой');

    PaneLoadQueue.promote('третья');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(started, [
      'первая',
      'третья',
    ], reason: 'показанная панель не ждёт «вторую», стоявшую перед ней');

    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(started, containsAll(['вторая']));
  });

  test('панель не грузится дважды', () async {
    // Панель могла стать активной уже во время своей загрузки. Повторный
    // запуск стоил бы второй порции запросов ровно там, где мы их экономим.
    var runs = 0;
    PaneLoadQueue.enqueue('a', () async {
      runs++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await Future<void>.delayed(const Duration(milliseconds: 2));
    PaneLoadQueue.promote('a'); // уже началась
    PaneLoadQueue.enqueue('a', () async => runs++); // и повторная постановка
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(runs, 1);
  });

  test('упавшая загрузка не останавливает остальные', () async {
    // Одна непоказанная история — беда куда меньшая, чем вставшая очередь:
    // та лишила бы истории все панели сразу.
    final done = <String>[];
    PaneLoadQueue.enqueue('плохая', () async => throw StateError('нет сети'));
    PaneLoadQueue.enqueue('хорошая', () async => done.add('хорошая'));
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(done, ['хорошая']);
  });

  test('снятая панель не грузится — её уже нет в дереве', () async {
    final done = <String>[];
    final gate = Completer<void>();
    PaneLoadQueue.enqueue('держит', () => gate.future);
    PaneLoadQueue.enqueue('ушла', () async => done.add('ушла'));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    PaneLoadQueue.cancel('ушла');
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(done, isEmpty);
    expect(PaneLoadQueue.pendingCount, 0);
  });

  test('promote для незнакомой панели безвреден', () {
    // Активная панель в очередь не ставится вовсе, а `didUpdateWidget`
    // зовёт promote на каждой смене активности — он обязан молчать.
    expect(() => PaneLoadQueue.promote('никогда-не-ставили'), returnsNormally);
  });
}
