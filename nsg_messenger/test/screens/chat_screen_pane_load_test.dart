/// **Скрытая панель не грузится вместе со всеми** — issue #141.
///
/// Замер на проде 14.08.2026: восемь вызовов от ОДНОГО человека в одну
/// секунду, каждый ~2,2 с. Причём вызов с двумя запросами занял почти
/// столько же, сколько вызов с пятнадцатью, — время определялось не работой,
/// а тем, что всё пришло разом: сервер однопоточный, и каждый вызов
/// отчитывался о полном времени очереди.
///
/// Приходило восемь потому, что рабочая область держит панели комнат в
/// дереве постоянно (скрытые — `Offstage`), а `initState` грузил историю
/// безусловно, без гейта по видимости.
///
/// Здесь проверяется сам гейт: скрытая панель ждёт своей очереди, показанная
/// не ждёт никого. Что очередь при этом разводит загрузки по одной —
/// проверено в `pane_load_queue_test.dart`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/screens/chat_screen.dart';
import 'package:nsg_messenger/src/screens/pane_load_queue.dart';

void main() {
  setUp(() {
    PaneLoadQueue.resetForTesting();
    _CountingRpc.resetGlobal();
  });
  tearDown(PaneLoadQueue.resetForTesting);

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: child,
  );

  ({_CountingRpc rpc, MessagesController controller}) build(int roomId) {
    final rpc = _CountingRpc();
    final controller = MessagesController(
      roomId: roomId,
      rpc: rpc,
      events: const Stream<MessengerEvent>.empty(),
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    return (rpc: rpc, controller: controller);
  }

  /// Занять очередь и вернуть «отпускатель». Без этого проверки были бы о
  /// случайности: одинокая скрытая панель грузится сразу — очередь РАЗВОДИТ
  /// загрузки, а не откладывает их. Разница видна только когда очередь
  /// занята кем-то ещё, то есть ровно в том случае, ради которого она есть.
  Completer<void> blockQueue() {
    final gate = Completer<void>();
    PaneLoadQueue.enqueue('чужая-панель', () => gate.future);
    return gate;
  }

  testWidgets('активная панель не ждёт занятой очереди', (tester) async {
    // Главное свойство: человек ждёт только свою панель. Пока чужие истории
    // грузятся, его собственная уже пошла.
    final gate = blockQueue();
    final b = build(1);
    await tester.pumpWidget(
      wrap(
        ChatScreen(roomId: 1, active: true, controllerOverride: b.controller),
      ),
    );
    await tester.pump();

    expect(b.rpc.listMessagesCalls, 1);
    gate.complete();
  });

  testWidgets('скрытая панель ждёт очереди и грузится после неё', (
    tester,
  ) async {
    // Ровно та правка: пять скрытых панелей больше не стартуют залпом.
    final gate = blockQueue();
    final b = build(2);
    await tester.pumpWidget(
      wrap(
        ChatScreen(roomId: 2, active: false, controllerOverride: b.controller),
      ),
    );
    await tester.pump();

    expect(
      b.rpc.listMessagesCalls,
      0,
      reason: 'очередь занята — скрытая панель обязана подождать',
    );

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(
      b.rpc.listMessagesCalls,
      1,
      reason: 'очередь освободилась — панель обязана догрузиться сама',
    );
  });

  testWidgets('панель, ставшая активной, не ждёт очереди', (tester) async {
    // Человек переключился раньше, чем до панели дошла очередь. Держать его
    // за чужой загрузкой — обмен одного ожидания на другое.
    final gate = blockQueue();
    final b = build(3);
    Widget screen(bool active) => wrap(
      ChatScreen(roomId: 3, active: active, controllerOverride: b.controller),
    );

    await tester.pumpWidget(screen(false));
    await tester.pump();
    expect(b.rpc.listMessagesCalls, 0);

    await tester.pumpWidget(screen(true));
    await tester.pump();
    expect(b.rpc.listMessagesCalls, 1);
    gate.complete();
  });

  testWidgets('пересозданная панель той же комнаты не остаётся без истории', (
    tester,
  ) async {
    // Ключом очереди была комната — и это оставляло дыру: рабочая область
    // могла построить новую панель до того, как избавится от старой, новая
    // отсеклась бы как дубль, а `dispose` старой снял бы отметку. Панель
    // осталась бы пустой навсегда, и заметил бы это только человек.
    final gate = blockQueue();
    final first = build(9);
    final second = build(9);

    await tester.pumpWidget(
      wrap(
        ChatScreen(
          key: const ValueKey('первая'),
          roomId: 9,
          active: false,
          controllerOverride: first.controller,
        ),
      ),
    );
    await tester.pump();
    // Подменяем панель той же комнаты — прежняя уходит из дерева.
    await tester.pumpWidget(
      wrap(
        ChatScreen(
          key: const ValueKey('вторая'),
          roomId: 9,
          active: false,
          controllerOverride: second.controller,
        ),
      ),
    );
    await tester.pump();

    gate.complete();
    await tester.pump();
    await tester.pump();

    expect(
      second.rpc.listMessagesCalls,
      1,
      reason:
          'живая панель обязана догрузиться, даже если её комната уже '
          'была в очереди от прежней',
    );
  });

  testWidgets('шесть скрытых панелей разом — одновременная загрузка ОДНА', (
    tester,
  ) async {
    // **Сценарий, которого не хватало, и он же поймал первую редакцию.**
    // Прежние проверки держали очередь искусственным блокировщиком, а очередь
    // с честной загрузкой вела себя верно. На проде блокировщика нет: шесть
    // панелей ставятся разом, и первая редакция отпускала очередь за
    // микротаск, потому что стартовая загрузка была `void` и ничего не
    // дожидалась. Сериализовались запуски, а не работа — замер на живом
    // приложении показал три полных набора в одну секунду.
    _CountingRpc.delay = const Duration(milliseconds: 20);
    final rpcs = <_CountingRpc>[];
    final panes = <Widget>[];
    for (var i = 0; i < 6; i++) {
      final b = build(100 + i);
      rpcs.add(b.rpc);
      panes.add(
        ChatScreen(
          roomId: 100 + i,
          active: false,
          controllerOverride: b.controller,
        ),
      );
    }

    // `IndexedStack` — та самая конструкция, что на устройстве: `ChatPager`
    // держит в ней все чаты набора и строит КАЖДЫЙ, видим он или нет.
    // Отсюда и залп: шесть панелей монтируются разом при каждом входе.
    await tester.pumpWidget(wrap(IndexedStack(index: 0, children: panes)));
    // Прокачиваем время: загрузки должны пройти ОДНА ЗА ДРУГОЙ.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    final maxInFlight = rpcs.fold<int>(
      0,
      (m, r) => r.maxInFlight > m ? r.maxInFlight : m,
    );
    final total = rpcs.fold<int>(0, (m, r) => m + r.listMessagesCalls);
    expect(
      _CountingRpc.globalMaxInFlight,
      1,
      reason:
          'две загрузки разом — это и есть залп, ради которого всё делалось',
    );
    expect(maxInFlight, lessThanOrEqualTo(1));
    expect(total, 6, reason: 'все панели обязаны догрузиться, а не потеряться');
  });

  testWidgets('повторная активация не грузит второй раз', (tester) async {
    // Панель переживает скрытие и показ много раз за сессию; каждый возврат
    // стоил бы новой порции запросов там, где мы их экономим.
    final b = build(4);
    Widget screen(bool active) => wrap(
      ChatScreen(roomId: 4, active: active, controllerOverride: b.controller),
    );

    await tester.pumpWidget(screen(true));
    await tester.pump();
    await tester.pumpWidget(screen(false));
    await tester.pump();
    await tester.pumpWidget(screen(true));
    await tester.pump();

    expect(b.rpc.listMessagesCalls, 1);
  });
}

/// Считает обращения за историей. Остальной интерфейс не нужен: экран в
/// этих проверках до него не доходит, а `noSuchMethod` избавляет от сорока
/// заглушек, каждая из которых была бы просто шумом.
class _CountingRpc implements MessagesRpc {
  int listMessagesCalls = 0;
  int maxInFlight = 0;

  /// Одновременность считаем ГЛОБАЛЬНО: панели разные, а очередь одна, и
  /// смысл её в том, чтобы работа не шла параллельно МЕЖДУ панелями.
  /// Пер-объектный счётчик этого не увидел бы вовсе.
  static int inFlight = 0;
  static int globalMaxInFlight = 0;

  /// Сколько длится один запрос. По умолчанию мгновенно: таймер, оставшийся
  /// после теста, роняет `testWidgets` («pending timers»), а большинству
  /// проверок длительность не нужна. Включает её только та, где меряется
  /// ОДНОВРЕМЕННОСТЬ, — без длительности она ненаблюдаема.
  static Duration delay = Duration.zero;

  static void resetGlobal() {
    inFlight = 0;
    globalMaxInFlight = 0;
    delay = Duration.zero;
  }

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async {
    listMessagesCalls++;
    inFlight++;
    if (inFlight > globalMaxInFlight) globalMaxInFlight = inFlight;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    // Работа должна ЗАНИМАТЬ время — иначе параллельность ненаблюдаема.
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    inFlight--;
    return MessengerMessageListPage(messages: const []);
  }

  /// Контроллер на старте ещё и подтягивает квитанции с закреплёнными —
  /// best-effort, но брошенное исключение framework теста считает
  /// неожиданным и валит прогон. Отвечаем пустотой: проверкам они не нужны.
  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const [];

  /// Экран на старте спрашивает ещё и про интеграцию задач (иконка в
  /// шапке). Отвечаем «нет» — иконки не будет, а проверкам она не нужна.
  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  /// Остальные сорок членов интерфейса в этих проверках не участвуют:
  /// заглушка на каждый была бы шумом, а падение здесь означает, что экран
  /// пошёл дорогой, которой на старте быть не должно, — и это стоит увидеть.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
