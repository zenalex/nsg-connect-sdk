import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/tasks_screen.dart';
import 'package:nsg_messenger/src/support/my_tasks_rpc.dart';

/// **TASK84 итерация 1**: widget-тесты экрана «Задачи». RPC подменяется fake-ом
/// (без Serverpod-клиента), навигация — через `onOpenRoom`/`onOpenThread`.
/// Проверяют:
///   * вкладка «Все» грузится с фильтром `all`; переключение на «Я инициатор»
///     зовёт RPC с фильтром `initiator` (и только при показе вкладки);
///   * строка показывает стадию понятной подписью (палитра/лейбл TASK83);
///   * тап по задаче с тредом → тред; без треда → комната;
///   * пустое состояние — своё на каждую вкладку.
void main() {
  final now = DateTime.utc(2026, 7, 23);

  TicketView task(
    int id, {
    required String stage,
    String kind = 'bug',
    String? title,
    String? threadRootEventId,
  }) => TicketView(
    id: id,
    kind: kind,
    status: 'open',
    stage: stage,
    roomId: 100 + id,
    title: title,
    threadRootEventId: threadRootEventId,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> pump(
    WidgetTester tester,
    _FakeRpc rpc, {
    void Function(BuildContext, int)? onOpenRoom,
    void Function(BuildContext, TicketView)? onOpenThread,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          NsgL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: NsgL10n.supportedLocales,
        home: TasksScreen(
          rpcOverride: rpc,
          onOpenRoom: onOpenRoom ?? (_, _) {},
          onOpenThread: onOpenThread,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('вкладка «Все» зовёт filter=all; переключение зовёт '
      'filter=initiator', (tester) async {
    final rpc = _FakeRpc({
      'all': [task(1, stage: 'in_progress', title: 'Комната A')],
      'initiator': [task(2, stage: 'new', title: 'Комната B')],
    });
    await pump(tester, rpc);

    // Начальная вкладка загрузила только «Все».
    expect(rpc.calls, ['all']);
    expect(find.text('Комната A'), findsOneWidget);

    // Переключаемся на «Я инициатор» → грузится initiator-выборка.
    await tester.tap(find.text('Я инициатор'));
    await tester.pumpAndSettle();

    expect(rpc.calls, containsAll(<String>['all', 'initiator']));
    expect(find.text('Комната B'), findsOneWidget);
  });

  testWidgets('строка показывает подпись стадии (TASK83)', (tester) async {
    final rpc = _FakeRpc({
      'all': [
        task(1, stage: 'in_progress', title: 'Комната'),
        task(2, stage: 'accepted', title: 'Комната 2'),
      ],
    });
    await pump(tester, rpc);

    expect(find.text('В работе'), findsOneWidget);
    expect(find.text('Принята'), findsOneWidget);
  });

  testWidgets('тап по задаче с тредом → тред, не комната', (tester) async {
    TicketView? openedThread;
    var openedRooms = 0;
    final rpc = _FakeRpc({
      'all': [
        task(
          1,
          stage: 'in_progress',
          title: 'Комната',
          threadRootEventId: 'anchor-event',
        ),
      ],
    });
    await pump(
      tester,
      rpc,
      onOpenRoom: (_, _) => openedRooms++,
      onOpenThread: (_, t) => openedThread = t,
    );

    await tester.tap(find.byKey(const Key('taskTile_1')));
    await tester.pumpAndSettle();

    expect(openedThread?.threadRootEventId, 'anchor-event');
    expect(openedRooms, 0, reason: 'в общий поток комнаты не проваливаемся');
  });

  testWidgets('тап по задаче без треда → комната', (tester) async {
    var openedThread = 0;
    int? openedRoomId;
    final rpc = _FakeRpc({
      'all': [task(3, stage: 'new', title: 'Комната')],
    });
    await pump(
      tester,
      rpc,
      onOpenRoom: (_, id) => openedRoomId = id,
      onOpenThread: (_, _) => openedThread++,
    );

    await tester.tap(find.byKey(const Key('taskTile_3')));
    await tester.pumpAndSettle();

    expect(openedRoomId, 103, reason: 'roomId = 100 + id');
    expect(openedThread, 0);
  });

  testWidgets('пустое состояние своё на каждую вкладку', (tester) async {
    final rpc = _FakeRpc({'all': const [], 'initiator': const []});
    await pump(tester, rpc);

    // Вкладка «Все» — своё пустое состояние.
    expect(find.text('В ваших комнатах пока нет задач.'), findsOneWidget);

    await tester.tap(find.text('Я инициатор'));
    await tester.pumpAndSettle();

    expect(find.text('Вы ещё не заводили задач.'), findsOneWidget);
  });
}

/// Fake RPC: отдаёт заранее заданный список под каждый фильтр и ЗАПОМИНАЕТ, с
/// какими фильтрами его звали (проверка «вкладка → нужный filter»).
class _FakeRpc implements MyTasksRpc {
  _FakeRpc(this._byFilter);

  final Map<String, List<TicketView>> _byFilter;
  final List<String> calls = [];

  @override
  Future<List<TicketView>> listMyTasks(String filter) async {
    calls.add(filter);
    return _byFilter[filter] ?? const [];
  }
}
