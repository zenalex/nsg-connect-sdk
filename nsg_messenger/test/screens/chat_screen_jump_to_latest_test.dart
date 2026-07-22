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

/// **Issue #59** — плавающая кнопка «к последнему сообщению».
///
/// Контракт:
///   * внизу ленты / при короткой истории кнопки нет (не тапабельна);
///   * ушли в историю дальше ~1.5 экрана — появляется; возврат к низу
///     скрывает её, причём с гистерезисом (между порогами показа и
///     скрытия состояние НЕ меняется — кнопка не мигает на границе);
///   * тап возвращает к самому свежему сообщению и прячет кнопку;
///   * пока юзер в истории, чужие входящие копятся в бейдж на кнопке;
///     свои — нет; возврат вниз сбрасывает счёт.
///
/// Пороговые тесты — синтетические ScrollUpdateNotification (как в
/// chat_screen_threshold_test.dart): viewport=400 → показ при
/// pixels > 600 (1.5 вьюпорта), скрытие при pixels < 200 (0.5).
/// maxScrollExtent=1000 — до loadMore-порога (200 от верха) не достаём.
///
/// **Важно**: до Ready — только `pump()` (у Loading-спиннера бесконечная
/// анимация, pumpAndSettle не наступит).
void main() {
  setUpAll(registerTimeagoLocales);

  const jumpKey = Key('chatJumpToLatestButton');
  final jumpButton = find.byKey(jumpKey);

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

  /// Открывает чат c [messageCount] сообщениями `msg 0..N-1` (DESC,
  /// `msg 0` — самое свежее, дно ленты) и доводит до Ready.
  Future<
    ({MessagesController controller, StreamController<MessengerEvent> events})
  >
  openChat(WidgetTester tester, {int messageCount = 1}) async {
    final rpc = _FakeRpc(messageCount: messageCount);
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
    await tester.pump(); // listMessages резолвится → Ready
    await tester.pump(); // микротаски markRead
    return (controller: controller, events: eventCtrl);
  }

  testWidgets(
    'короткая история, юзер внизу — кнопка не показывается (не тапабельна)',
    (tester) async {
      final h = await openChat(tester, messageCount: 3);
      addTearDown(() async {
        await h.controller.dispose();
        await h.events.close();
      });

      // Виджет в дереве живёт всегда (ради анимации появления), но скрыт
      // и закрыт IgnorePointer-ом — hitTestable его не находит.
      expect(jumpButton, findsOneWidget);
      expect(
        jumpButton.hitTestable(),
        findsNothing,
        reason: 'скроллить некуда — кнопке нечего предлагать',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('появляется за порогом ~1.5 экрана, живёт в зоне гистерезиса, '
      'скрывается у низа', (tester) async {
    final h = await openChat(tester);
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    final scrollableEl = _listScrollable(tester);

    // 700 > 600 (1.5 × viewport 400) → показать.
    _dispatchScroll(scrollableEl, pixels: 700);
    await tester.pumpAndSettle();
    expect(jumpButton.hitTestable(), findsOneWidget);

    // 300 — между порогом скрытия (200) и показа (600): гистерезис,
    // кнопка НЕ прячется (иначе мигала бы на границе показа).
    _dispatchScroll(scrollableEl, pixels: 300);
    await tester.pumpAndSettle();
    expect(
      jumpButton.hitTestable(),
      findsOneWidget,
      reason: 'в зоне гистерезиса состояние не меняется',
    );

    // 100 < 200 → скрыть.
    _dispatchScroll(scrollableEl, pixels: 100);
    await tester.pumpAndSettle();
    expect(jumpButton.hitTestable(), findsNothing);

    // И обратно: 300 из скрытого состояния НЕ показывает (порог 600).
    _dispatchScroll(scrollableEl, pixels: 300);
    await tester.pumpAndSettle();
    expect(
      jumpButton.hitTestable(),
      findsNothing,
      reason: 'до порога показа не дотянули — гистерезис в обе стороны',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('бейдж: чужие входящие в истории копятся, свои — нет, '
      'возврат вниз сбрасывает', (tester) async {
    final h = await openChat(tester);
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    final scrollableEl = _listScrollable(tester);
    _dispatchScroll(scrollableEl, pixels: 700);
    await tester.pumpAndSettle();
    expect(jumpButton.hitTestable(), findsOneWidget);
    // Пока ничего не пришло — бейджа нет.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsNothing,
    );

    // Чужое сообщение под кромкой экрана → бейдж «1».
    h.events.add(_eventForRoom(1, _peerMsg(eventId: 'peer-1')));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
      reason: 'юзер в истории — новое чужое сообщение он не видел',
    );

    // Своё (echo с другого устройства) счёт не увеличивает.
    h.events.add(_eventForRoom(1, _ownMsg(eventId: 'own-1')));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
      reason: 'своё сообщение «непрочитанным» для автора не считается',
    );

    // Ещё одно чужое → «2».
    h.events.add(_eventForRoom(1, _peerMsg(eventId: 'peer-2')));
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );

    // Вернулись к низу — счёт обнулён; повторный уход начинает с нуля.
    _dispatchScroll(scrollableEl, pixels: 0);
    await tester.pumpAndSettle();
    _dispatchScroll(scrollableEl, pixels: 700);
    await tester.pumpAndSettle();
    expect(jumpButton.hitTestable(), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsNothing,
      reason: 'всё видено при возврате вниз — бейдж стартует заново',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('реальный скролл вглубь показывает кнопку; тап возвращает к '
      'последнему сообщению и прячет её', (tester) async {
    final h = await openChat(tester, messageCount: 60);
    addTearDown(() async {
      await h.controller.dispose();
      await h.events.close();
    });

    // Дно ленты — самое свежее сообщение.
    expect(find.text('msg 0').hitTestable(), findsOneWidget);
    expect(jumpButton.hitTestable(), findsNothing);

    // Уходим в историю: reverse:true → палец вниз = старше.
    final listFinder = find.byType(ListView);
    for (var i = 0; i < 4; i++) {
      await tester.drag(listFinder, const Offset(0, 500));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(
      jumpButton.hitTestable(),
      findsOneWidget,
      reason: 'уехали дальше порога — кнопка-спасательный круг видна',
    );
    expect(
      find.text('msg 0').hitTestable(),
      findsNothing,
      reason: 'свежие сообщения остались под нижней кромкой',
    );

    await tester.tap(jumpButton);
    await tester.pumpAndSettle();

    expect(
      find.text('msg 0').hitTestable(),
      findsOneWidget,
      reason: 'тап вернул к самому свежему сообщению',
    );
    expect(
      jumpButton.hitTestable(),
      findsNothing,
      reason: 'внизу кнопка не нужна',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Element _listScrollable(WidgetTester tester) {
  final listFinder = find.byType(ListView);
  expect(listFinder, findsOneWidget);
  return tester.element(
    find.descendant(of: listFinder, matching: find.byType(Scrollable)),
  );
}

void _dispatchScroll(Element scrollableEl, {required double pixels}) {
  ScrollUpdateNotification(
    metrics: FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: pixels,
      viewportDimension: 400,
      axisDirection: AxisDirection.up,
      devicePixelRatio: 1.0,
    ),
    context: scrollableEl,
    scrollDelta: 1,
  ).dispatch(scrollableEl);
}

// ─── Helpers ───

MessengerEvent _eventForRoom(int roomId, MessengerMessage msg) =>
    MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: msg.serverTimestamp,
      roomId: roomId,
      matrixRoomId: msg.matrixRoomId,
      message: msg,
    );

MessengerMessage _peerMsg({required String eventId, String body = 'peer'}) =>
    MessengerMessage(
      matrixEventId: eventId,
      roomId: 1,
      matrixRoomId: '!r:t',
      senderMessengerUserId: 99,
      senderMatrixUserId: '@peer:t',
      msgType: 'm.text',
      body: body,
      content: ByteData(0),
      serverTimestamp: DateTime.utc(2026, 1, 2),
    );

MessengerMessage _ownMsg({required String eventId}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: 1,
  matrixRoomId: '!r:t',
  senderMessengerUserId: 42,
  senderMatrixUserId: '@self:t',
  msgType: 'm.text',
  body: 'own',
  content: ByteData(0),
  serverTimestamp: DateTime.utc(2026, 1, 2),
);

/// listMessages отдаёт [messageCount] текстовых сообщений `msg 0..N-1`
/// (DESC: `msg 0` — newest) БЕЗ nextToken — loadMore при скролле вглубь
/// не мешает тестам. markRead — no-op success.
class _FakeRpc implements MessagesRpc {
  _FakeRpc({required this.messageCount});

  final int messageCount;

  // **TASK82**: лента треда в этом сьюте не используется — фейку
  // достаточно удовлетворить интерфейс.
  @override
  Future<MessengerMessageListPage> listThreadMessages({
    required int roomId,
    required String threadRootEventId,
    String? fromToken,
    int limit = 50,
  }) => throw UnimplementedError();

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async {
    final base = DateTime.utc(2026, 1, 1, 12);
    return MessengerMessageListPage(
      messages: [
        for (var i = 0; i < messageCount; i++)
          MessengerMessage(
            matrixEventId: 'e$i',
            roomId: roomId,
            matrixRoomId: '!r:t',
            senderMessengerUserId: 99,
            senderMatrixUserId: '@peer:t',
            msgType: 'm.text',
            body: 'msg $i',
            content: ByteData(0),
            serverTimestamp: base.subtract(Duration(seconds: i)),
          ),
      ],
    );
  }

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<TaskLink> createTaskFromMessage({
    required int roomId,
    required String matrixEventId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
    // TASK82: тред задачи — фейку достаточно принять параметр.
    String? threadId,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) =>
      throw UnimplementedError();

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => throw UnimplementedError();

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) async => 'reaction-event';

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) async {}

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) async => const <MessengerMessage>[];

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];
}
