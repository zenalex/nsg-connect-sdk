import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// **TASK86** — разделители дат в ленте + «липкая» дата (виджет-уровень).
///
/// Даты берём в 2020-м — они всегда «старше» относительно любой даты
/// прогона, поэтому метки стабильны: `1 January 2020` / `2 January 2020`
/// (locale en), независимо от wall-clock теста.
void main() {
  setUpAll(registerTimeagoLocales);

  const stickyKey = Key('chatStickyDate');

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

  Future<
      ({MessagesController controller, StreamController<MessengerEvent> events})>
      openChat(
    WidgetTester tester, {
    required List<MessengerMessage> page,
  }) async {
    final rpc = _FakeRpc(page: page);
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    await tester.pumpWidget(
      wrap(ChatScreen(roomId: 1, controllerOverride: controller)),
    );
    await tester.pump(); // mount + init
    await tester.pump(); // listMessages → Ready
    await tester.pump(); // markRead microtasks
    return (controller: controller, events: eventCtrl);
  }

  /// DESC-страница: [perDay] сообщений на каждый из [days] (day[0] — самый
  /// свежий). Свежие сначала (index 0 — низ ленты).
  List<MessengerMessage> pageFor(List<DateTime> days, {int perDay = 1}) {
    final out = <MessengerMessage>[];
    var seq = 0;
    for (final day in days) {
      for (var i = 0; i < perDay; i++) {
        out.add(
          MessengerMessage(
            matrixEventId: 'e${seq++}',
            roomId: 1,
            matrixRoomId: '!r:t',
            senderMessengerUserId: 99,
            senderMatrixUserId: '@peer:t',
            msgType: 'm.text',
            body: 'msg on ${day.day} #$i',
            content: ByteData(0),
            // День убывает; внутри дня время тоже убывает.
            serverTimestamp: DateTime.utc(day.year, day.month, day.day, 12)
                .subtract(Duration(minutes: i)),
          ),
        );
      }
    }
    return out;
  }

  testWidgets('между двумя днями — по одному разделителю; внутри дня их нет',
      (tester) async {
    // День2 (2 сообщения) + День1 (2 сообщения) — всё влезает в 800x600.
    final h = await openChat(
      tester,
      page: pageFor(
        [DateTime(2020, 1, 2), DateTime(2020, 1, 1)],
        perDay: 2,
      ),
    );
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    // Ровно по одной плашке на день — доказывает, что между сообщениями
    // ОДНОГО дня разделителя нет (иначе было бы две «2 January 2020»).
    expect(find.text('2 January 2020'), findsOneWidget);
    expect(find.text('1 January 2020'), findsOneWidget);

    // В покое «липкой» плашки нет (день не посчитан — не скроллили).
    expect(find.byKey(stickyKey), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('один день — ровно один разделитель, «липкой» плашки в покое нет',
      (tester) async {
    final h = await openChat(
      tester,
      page: pageFor([DateTime(2020, 3, 5)], perDay: 3),
    );
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    expect(find.text('5 March 2020'), findsOneWidget);
    expect(find.byKey(stickyKey), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('пустая лента — без разделителей и без «липкой» плашки',
      (tester) async {
    final h = await openChat(tester, page: const []);
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    expect(find.byKey(stickyKey), findsNothing);
    // Нет ни одной date-плашки (проверяем по типовым текстам — их просто нет).
    expect(find.textContaining('2020'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      '«липкая» дата: появляется при скролле с датой верхней группы, '
      'гаснет в покое', (tester) async {
    // Два дня по 12 сообщений — лента заведомо длиннее вьюпорта, есть куда
    // скроллить, и верхний день сначала за кромкой.
    final h = await openChat(
      tester,
      page: pageFor(
        [DateTime(2020, 1, 2), DateTime(2020, 1, 1)],
        perDay: 12,
      ),
    );
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    // На дне ленты «липкой» плашки нет (не скроллили).
    expect(find.byKey(stickyKey), findsNothing);

    // Уходим в историю: reverse:true → палец вниз = старше. Доводим скролл
    // до покоя (иначе баллистика продолжала бы дёргать таймер бездействия).
    final listFinder = find.byType(ListView);
    for (var i = 0; i < 8; i++) {
      await tester.drag(listFinder, const Offset(0, 400));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Плашка появилась и показана (target opacity == 1), с датой верхней
    // (самой старой) группы — 1 January 2020.
    expect(find.byKey(stickyKey), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(stickyKey), matching: find.text('1 January 2020')),
      findsOneWidget,
      reason: 'наверху видна группа 2020-01-01 — её и показывает липкая дата',
    );
    final shownOpacity = tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(stickyKey),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(shownOpacity, 1.0, reason: 'при скролле плашка показана');

    // Покой: спустя таймер бездействия (>1.5с) плашка гаснется.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    final hiddenOpacity = tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(stickyKey),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(hiddenOpacity, 0.0, reason: 'в покое липкая дата прячется');

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// listMessages отдаёт заданную страницу БЕЗ nextToken (loadMore не мешает).
class _FakeRpc implements MessagesRpc {
  _FakeRpc({required this.page});

  final List<MessengerMessage> page;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: page);

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
