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

/// **Issue #95**: переход к сообщению, которое УЖЕ загружено, но лежит
/// далеко за пределами построенного окна `ListView.builder`.
///
/// Это общий путь всей навигации по ленте: закреплённые, поиск,
/// «Переслано от X» (#41), тап по уведомлению (#53). Ленивый список строит
/// только видимое плюс `cacheExtent`, а `Scrollable.ensureVisible` умеет
/// работать ТОЛЬКО по `BuildContext` — у непостроенного элемента его нет.
/// Старый код трактовал это как «сообщения нет» и уходил догружать историю,
/// хотя цель уже в списке.
///
/// Ключевой разделитель случаев: `hasMore == false` + цель ЕСТЬ в состоянии.
/// Догружать нечего, значит любой отказ здесь — ложный.
const _room = 1;

/// Сколько сообщений в ленте и куда прыгаем. 200 при высоте пузыря ~60px и
/// вьюпорте 600px — цель заведомо вне построенного окна (viewport +
/// cacheExtent ≈ 1100px ≈ 18 сообщений), но заведомо В состоянии.
const _total = 200;
const _targetIndex = 150;

MessengerMessage _msg(int i) => MessengerMessage(
  matrixEventId: 'e$i',
  roomId: _room,
  matrixRoomId: '!r:t',
  senderMessengerUserId: 2, // peer (self=42)
  senderMatrixUserId: '@peer:t',
  msgType: 'm.text',
  body: 'msg-$i',
  // index 0 — самое свежее (лента DESC), поэтому время убывает с индексом.
  // Шаг в часах — чтобы лента растянулась на ~8 дней и в ней жили
  // разделители дат: прыжок обязан переживать и их геометрию («липкая»
  // дата читает `localToGlobal` построенных плашек, issue #96).
  serverTimestamp: DateTime.utc(2026, 1, 9, 12).subtract(Duration(hours: i)),
  senderDisplayName: 'Peer',
);

class _FakeRpc implements MessagesRpc {
  List<MessengerMessage> page = [];
  List<MessengerMessage> pinned = const [];

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
  }) async => pinned;

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _tooFar = 'Сообщение слишком далеко в истории — не удалось перейти.';
const _failed = 'Не удалось перейти к сообщению.';

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

  Future<MessagesController> makeController(
    WidgetTester tester, {
    bool pinTarget = false,
  }) async {
    final rpc = _FakeRpc()
      ..page = [for (var i = 0; i < _total; i++) _msg(i)]
      ..pinned = pinTarget ? [_msg(_targetIndex)] : const [];
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

  testWidgets('цель далеко в загруженной истории — доезжаем, а не отказываем', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await makeController(tester);
    await pumpChat(tester, controller, target: 'e$_targetIndex');
    await tester.pumpAndSettle();

    // Догружать нечего (hasMore == false) — но и не нужно: сообщение уже
    // в состоянии. Любой отказ здесь — ложный.
    expect(find.text(_tooFar), findsNothing);
    expect(find.text(_failed), findsNothing);

    // Главное: цель реально на экране.
    expect(find.text('msg-$_targetIndex'), findsOneWidget);
  });

  testWidgets('цели нет в истории и догружать нечего — честный отказ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await makeController(tester);
    await pumpChat(tester, controller, target: r'$missing');
    await tester.pumpAndSettle();

    // Обратная сторона фикса: «нет в состоянии» по-прежнему обязано
    // отказывать вслух, иначе тап по закреплённому молча ничего не делает.
    expect(find.text(_tooFar), findsOneWidget);
  });

  testWidgets('тап по плашке закреплённого доводит ленту до сообщения', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await makeController(tester, pinTarget: true);
    await pumpChat(tester, controller);
    await tester.pumpAndSettle();

    // Плашка показывает тело закреплённого — до перехода это единственное
    // вхождение текста на экране (сам пузырь далеко вверху ленты).
    expect(find.text('msg-$_targetIndex'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.push_pin));
    await tester.pumpAndSettle();

    expect(find.text(_tooFar), findsNothing);
    expect(find.text(_failed), findsNothing);
    // Теперь текст встречается дважды: в плашке и в доехавшем пузыре.
    expect(
      find.text('msg-$_targetIndex'),
      findsNWidgets(2),
      reason: 'к пузырю так и не доехали — на экране осталась только плашка',
    );
  });
}
