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

/// Widget-тесты для [ChatScreen] (TASK15 Chunk 2).
///
/// **Важно**: НЕ используем `pumpAndSettle()` — `CircularProgressIndicator`
/// (Loading) и `LinearProgressIndicator` (paginating) имеют бесконечные
/// анимации, settle никогда не происходит. Везде явный `pump()` с
/// нужным числом кадров для распространения state-changes.
void main() {
  setUpAll(registerTimeagoLocales);

  // Wrap-helper из test_helpers.dart но передаём child как-есть
  // (тесты ChatScreen рендерят полноэкранную Scaffold-структуру —
  // не нужно оборачивать ещё одним Scaffold-ом из wrapL10n).
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

  testWidgets('Loading → spinner; composer disabled', (tester) async {
    final rpc = _FakeRpc();
    final completer = Completer<MessengerMessageListPage>();
    rpc.listMessagesHandler = (_, _, _) => completer.future;
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
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.enabled, isFalse, reason: 'composer disabled in Loading');

    // Cleanup БЕЗ pumpAndSettle (spinner-anim never settles).
    completer.complete(_page([]));
    await tester.pump(); // future microtask
    await tester.pump(); // rebuild
    // Cleanup: unmount widget; controller/stream-cleanup делаем
    // через addTearDown, чтобы test body завершился сразу же.
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Ready empty → empty-state text; composer enabled', (
    tester,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) => Future.value(_page([]));
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
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No messages yet'), findsOneWidget);
    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.enabled, isTrue);
    // Cleanup: unmount widget; controller/stream-cleanup делаем
    // через addTearDown, чтобы test body завершился сразу же.
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Ready with history → bubbles render; reverse listview', (
    tester,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) => Future.value(
      _page([
        _msg(eventId: 'h-1', body: 'newest'),
        _msg(eventId: 'h-2', body: 'older'),
      ]),
    );
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
    await tester.pump();
    await tester.pump();

    expect(find.text('newest'), findsOneWidget);
    expect(find.text('older'), findsOneWidget);
    final lv = tester.widget<ListView>(find.byType(ListView));
    expect(lv.reverse, isTrue);
    // Cleanup: unmount widget; controller/stream-cleanup делаем
    // через addTearDown, чтобы test body завершился сразу же.
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('send из composer → optimistic pending bubble visible → sent', (
    tester,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) => Future.value(_page([]));
    final sendCompleter = Completer<MessengerMessage>();
    rpc.sendMessageHandler = (_, body, _, txnId) => sendCompleter.future;
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 1,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: '@self:t',
      clientTxnIdGenerator: () => 'TXN-w',
    );

    await tester.pumpWidget(
      wrap(ChatScreen(roomId: 1, controllerOverride: controller)),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'из composer');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(
      find.text('из composer'),
      findsOneWidget,
      reason: 'pending bubble visible',
    );
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
      reason: 'pending status spinner',
    );

    sendCompleter.complete(
      _msg(eventId: 'e-real', body: 'из composer', clientTxnId: 'TXN-w'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Cleanup: unmount widget; controller/stream-cleanup делаем
    // через addTearDown, чтобы test body завершился сразу же.
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Error без lastKnown → error-empty состояние', (tester) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.error(StateError('init-fail'));
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
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Failed to load messages'), findsOneWidget);
    // Cleanup: unmount widget; controller/stream-cleanup делаем
    // через addTearDown, чтобы test body завершился сразу же.
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // ─── TASK18: auto-markRead behavior ───────────────────────────────

  testWidgets('first Ready → markRead fire IMMEDIATELY (no debounce delay)', (
    tester,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) => Future.value(
      _page([
        _msg(eventId: 'newest', body: 'newest msg'),
        _msg(eventId: 'older', body: 'older msg'),
      ]),
    );
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
    await tester.pump(); // mount + init starts
    await tester.pump(); // listMessages future resolves → Ready

    // First Ready triggers markRead immediately, без 500ms wait.
    // Дополнительный pump для микротасков controller.markRead RPC.
    await tester.pump();
    expect(rpc.markReadCalls, [
      'newest',
    ], reason: 'fire-immediately on first Ready (Q3 contract)');

    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('subsequent message arrivals → markRead debounced 500ms', (
    tester,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(_page([_msg(eventId: 'first', body: 'first msg')]));
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
    await tester.pump();
    await tester.pump();
    await tester.pump();
    // First Ready → immediate markRead('first').
    expect(rpc.markReadCalls, ['first']);

    // Burst из 3 новых событий через stream — должны coalesce в
    // один markRead с newest event.
    eventCtrl.add(_eventForRoom(1, _msg(eventId: 'm2', body: 'second')));
    await tester.pump();
    eventCtrl.add(_eventForRoom(1, _msg(eventId: 'm3', body: 'third')));
    await tester.pump();
    eventCtrl.add(_eventForRoom(1, _msg(eventId: 'm4', body: 'fourth')));
    await tester.pump();

    // Up to 500ms ничего не должно произойти кроме первого
    // immediate-markRead-а.
    await tester.pump(const Duration(milliseconds: 200));
    expect(rpc.markReadCalls, [
      'first',
    ], reason: 'debounce — 200ms < 500ms, ещё не fire');

    // После 500ms — fire с newest (m4).
    await tester.pump(const Duration(milliseconds: 400));
    expect(rpc.markReadCalls, [
      'first',
      'm4',
    ], reason: 'burst coalesced в один markRead с newest');

    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dedup: тот же newest event не дёргает markRead повторно', (
    tester,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(_page([_msg(eventId: 'only', body: 'only msg')]));
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
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(rpc.markReadCalls, ['only']);

    // State-listener fires on каждое state change. Симулируем:
    // tap retry on imaginary failed (нечего retry-ить тут, но
    // sendMessage с тем же body — не newest event change).
    // Просто ждём 1 сек — никаких новых markRead.
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      rpc.markReadCalls,
      ['only'],
      reason: 'dedup — newest не изменился, нет нового markRead',
    );

    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'dispose during pending debounce timer → markRead не вызывается',
    (tester) async {
      final rpc = _FakeRpc();
      rpc.listMessagesHandler = (_, _, _) =>
          Future.value(_page([_msg(eventId: 'first', body: 'first')]));
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
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(rpc.markReadCalls, ['first']);

      // Новое сообщение — стартует 500ms debounce.
      eventCtrl.add(_eventForRoom(1, _msg(eventId: 'second', body: 'sec')));
      await tester.pump();

      // Unmount widget ДО 500ms — timer должен cancel-нуться.
      await tester.pumpWidget(const SizedBox.shrink());
      // Wait past debounce window.
      await tester.pump(const Duration(milliseconds: 600));

      expect(rpc.markReadCalls, [
        'first',
      ], reason: 'pending debounce cancelled by widget dispose');

      addTearDown(() async {
        await controller.dispose();
        await eventCtrl.close();
      });
    },
  );

  testWidgets('empty state — no markRead (no eventId to mark)', (tester) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) => Future.value(_page([]));
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
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(rpc.markReadCalls, isEmpty);

    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

MessengerEvent _eventForRoom(int roomId, MessengerMessage msg) =>
    MessengerEvent(
      eventType: MessengerEventType.messageCreated,
      serverTimestamp: msg.serverTimestamp,
      roomId: roomId,
      matrixRoomId: msg.matrixRoomId,
      message: msg,
    );

// ─── Helpers ───

MessengerMessage _msg({
  required String eventId,
  String body = 'msg',
  String? clientTxnId,
  int roomId = 1,
}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: roomId,
  matrixRoomId: '!r:t',
  senderMessengerUserId: 42,
  senderMatrixUserId: '@self:t',
  msgType: 'm.text',
  body: body,
  content: ByteData(0),
  serverTimestamp: DateTime.utc(2026, 1, 1),
  clientTxnId: clientTxnId,
);

MessengerMessageListPage _page(List<MessengerMessage> ms) =>
    MessengerMessageListPage(messages: ms);

class _FakeRpc implements MessagesRpc {
  @override
  Future<TaskLink> createTaskFromMessage({
    required int roomId,
    required String matrixEventId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;
  Future<MessengerMessage> Function(int, String, String, String)?
  sendMessageHandler;
  Future<bool> Function(int, String)? markReadHandler;
  final markReadCalls = <String>[];

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
  }) {
    final h = listMessagesHandler;
    if (h == null) throw StateError('listMessagesHandler not set');
    return h(roomId, fromToken, limit);
  }

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
  }) {
    final h = sendMessageHandler;
    if (h == null) throw StateError('sendMessageHandler not set');
    return h(roomId, body, msgType, clientTxnId);
  }

  @override
  Future<bool> markRead({required int roomId, required String matrixEventId}) {
    markReadCalls.add(matrixEventId);
    final h = markReadHandler;
    if (h == null) return Future.value(true);
    return h(roomId, matrixEventId);
  }

  // TASK19 Chunk 3: stub-ы для attachment RPCs. ChatScreen tests не
  // exercising attachment flow; throws чтобы случайный вызов был видим.
  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => throw UnimplementedError('upload not exercised in chat_screen tests');

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => throw UnimplementedError('thumb not exercised in chat_screen tests');

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) =>
      throw UnimplementedError('full not exercised in chat_screen tests');

  // TASK37: stubs для edit/delete RPCs. ChatScreen tests не exercising
  // edit/delete flow; throws чтобы случайный вызов был видим.
  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => throw UnimplementedError('edit not exercised in chat_screen tests');

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => throw UnimplementedError('delete not exercised in chat_screen tests');

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {
    // No-op: typing not exercised in chat_screen tests.
  }

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

  // #35 pin — заглушки (эти тесты pin не покрывают).
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
  Future<List<MessengerMessage>> listPinnedMessages({required int roomId}) async =>
      const <MessengerMessage>[];
}
