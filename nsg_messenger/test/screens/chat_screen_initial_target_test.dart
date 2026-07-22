import 'dart:async';

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

/// **Issue #41 / #53**: позиционирование чата на целевое сообщение
/// ([ChatScreen.initialTargetEventId]).
///
///   * первый build с целью — одноразовый прыжок после Ready (issue #41);
///   * **issue #53**: у KEEP-ALIVE экрана (панель рабочего набора) цель
///     меняется «на лету» — didUpdateWidget обязан перезапустить прыжок
///     для НОВОЙ цели и не перезапускать для той же самой.
///
/// Наблюдаемый исход прыжка к недостижимой цели — снекбар «не удалось
/// перейти» (история исчерпана): он доказывает, что попытка была.
const _room = 1;

MessengerMessage _msg(String eventId, {String body = 'hi'}) =>
    MessengerMessage(
      matrixEventId: eventId,
      roomId: _room,
      matrixRoomId: '!r:t',
      senderMessengerUserId: 2, // peer (self=42)
      senderMatrixUserId: '@peer:t',
      msgType: 'm.text',
      body: body,
      serverTimestamp: DateTime.utc(2026, 1, 1, 12),
      senderDisplayName: 'Peer',
    );

class _FakeRpc implements MessagesRpc {
  List<MessengerMessage> page = [];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: page);

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const [];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _tooFar = 'Сообщение слишком далеко в истории — не удалось перейти.';

void main() {
  setUpAll(registerTimeagoLocales);

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

  Future<MessagesController> makeController(WidgetTester tester) async {
    final rpc = _FakeRpc()..page = [_msg('e1'), _msg('e2', body: 'older')];
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: _room,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    return controller;
  }

  Future<void> pumpChat(
    WidgetTester tester,
    MessagesController controller, {
    String? target,
  }) async {
    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: _room,
          controllerOverride: controller,
          initialTargetEventId: target,
        ),
      ),
    );
    await tester.pump(); // init
    await tester.pump(); // Ready
  }

  testWidgets('первый build с недостижимой целью → попытка прыжка (снекбар)', (
    tester,
  ) async {
    final controller = await makeController(tester);
    await pumpChat(tester, controller, target: r'$missing');
    await tester.pumpAndSettle();

    // История без цели и без следующих страниц → понятный отказ. Он же —
    // доказательство, что initState-путь прыжка (issue #41) сработал.
    expect(find.text(_tooFar), findsOneWidget);
  });

  testWidgets('issue #53: смена цели «на лету» перезапускает прыжок', (
    tester,
  ) async {
    final controller = await makeController(tester);
    // Открыт без цели (обычное открытие чата).
    await pumpChat(tester, controller);
    expect(find.text(_tooFar), findsNothing);

    // Тап по уведомлению уже открытого чата: тот же keep-alive экран
    // получает новую цель (rebuild с новым initialTargetEventId).
    await pumpChat(tester, controller, target: r'$missing');
    await tester.pumpAndSettle();

    expect(find.text(_tooFar), findsOneWidget,
        reason: 'didUpdateWidget обязан снять защёлку и прыгнуть заново');
  });

  testWidgets('та же цель повторно — прыжок НЕ перезапускается', (
    tester,
  ) async {
    final controller = await makeController(tester);
    await pumpChat(tester, controller, target: r'$missing');
    await tester.pumpAndSettle();
    expect(find.text(_tooFar), findsOneWidget);

    // Ждём, пока снекбар уйдёт сам (3с + анимации).
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text(_tooFar), findsNothing);

    // Rebuild с ТОЙ ЖЕ целью (обычный ре-билд панели: смена active и т.п.)
    // — повторного прыжка (и снекбара) быть не должно, иначе каждый ре-билд
    // отбрасывал бы пользователя к старой цели.
    await pumpChat(tester, controller, target: r'$missing');
    await tester.pumpAndSettle();
    expect(find.text(_tooFar), findsNothing);
  });
}
