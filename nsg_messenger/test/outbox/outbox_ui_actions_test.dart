import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_action_sheet.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/messages/messages_state.dart';
import 'package:nsg_messenger/src/outbox/outbox_item.dart';
import 'package:nsg_messenger/src/outbox/outbox_sender.dart';

const _kRoomId = 101;
const _kSelfUid = 42;
const _kSelfMxid = '@self:test';

/// **OUTBOX**: UI-действия над строкой персистентной очереди — «повторить»
/// и «отменить отправку».
///
/// До этого их не было ни одного: `retryOutbox`/`discardOutbox` не звал
/// никто, кнопка «!» на баббле уходила в in-memory `retry` (мимо очереди),
/// а long-press на не-отправленном пузыре был запрещён вовсе. Файл из Share
/// Extension висел «в отправке» неделями — убрать его было нечем.
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('outbox_ui_actions_test');
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> openStore() async {
    final store = await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: 'ui_actions',
      userId: _kSelfUid,
    );
    return store!;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  // ─────────────────────────────────────────── controller ──

  test('retry() у строки очереди уходит в очередь, а не в send-RPC', () async {
    final store = await openStore();
    // Вложение БЕЗ картинки (файл из Share Extension) — худший случай:
    // localImageBytes нет, attachment нет, и старый `retry` отправлял
    // `_shootSendRpc(attachment: null)`, т.е. текст с именем файла.
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.attachment,
        body: 'contract.pdf',
        msgType: 'm.file',
        attachmentPath: '${tmp.path}/contract.pdf',
        mimeType: 'application/pdf',
        originalFilename: 'contract.pdf',
        status: OutboxStatus.failed,
        lastError: 'permanent',
        createdAt: 1,
      ),
    );
    final rpc = _FakeRpc();
    final outbox = _SpyOutbox(store: store, rpc: rpc);
    final events = StreamController<MessengerEvent>.broadcast();
    final c = MessagesController(
      roomId: _kRoomId,
      rpc: rpc,
      events: events.stream,
      selfMessengerUserId: _kSelfUid,
      selfMatrixUserId: _kSelfMxid,
      cache: store,
      outbox: outbox,
    );
    await c.init();
    await settle();
    final bubble = (c.state as MessagesReady).messages.firstWhere(
      (m) => m.clientTxnId == 'q1',
    );
    expect(bubble.isFailed, isTrue);

    await c.retry('q1');
    await settle();

    expect(outbox.retried, ['q1'], reason: 'ушло в очередь');
    expect(
      rpc.sentBodies,
      isEmpty,
      reason: 'мимо очереди ничего не отправлено (раньше улетал голый текст '
          '«contract.pdf» без вложения)',
    );
    await c.dispose();
    await events.close();
    await store.close();
  });

  test('retryAllFailed не отправляет строки очереди мимо неё', () async {
    final store = await openStore();
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.text,
        body: 'boom',
        status: OutboxStatus.failed,
        lastError: 'permanent',
        createdAt: 1,
      ),
    );
    final rpc = _FakeRpc();
    final outbox = _SpyOutbox(store: store, rpc: rpc);
    final events = StreamController<MessengerEvent>.broadcast();
    final c = MessagesController(
      roomId: _kRoomId,
      rpc: rpc,
      events: events.stream,
      selfMessengerUserId: _kSelfUid,
      selfMatrixUserId: _kSelfMxid,
      cache: store,
      outbox: outbox,
    );
    await c.init();
    await settle();

    // Зовётся ChatScreen-ом на возврате сети — тот же путь, что и кнопка.
    await c.retryAllFailed();
    await settle();

    expect(outbox.retried, ['q1']);
    expect(rpc.sentBodies, isEmpty);
    await c.dispose();
    await events.close();
    await store.close();
  });

  test('discardOutbox снимает баббл, строку и локальную копию файла',
      () async {
    final store = await openStore();
    final file = File('${tmp.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.attachment,
        body: 'photo.jpg',
        msgType: 'm.image',
        attachmentPath: file.path,
        mimeType: 'image/jpeg',
        originalFilename: 'photo.jpg',
        createdAt: 1,
      ),
    );
    final rpc = _FakeRpc();
    final events = StreamController<MessengerEvent>.broadcast();
    final c = MessagesController(
      roomId: _kRoomId,
      rpc: rpc,
      events: events.stream,
      selfMessengerUserId: _kSelfUid,
      selfMatrixUserId: _kSelfMxid,
      cache: store,
      // Настоящий sender (дренаж сам по себе не стартует — его будит
      // только kick), чтобы discard реально удалил файл и строку.
      outbox: OutboxSender(
        store: store,
        rpc: rpc,
        directoryResolver: () async => tmp,
      ),
    );
    await c.init();
    await settle();
    expect(
      (c.state as MessagesReady).messages.where((m) => m.clientTxnId == 'q1'),
      hasLength(1),
    );

    await c.discardOutbox('q1');
    await settle();

    expect(
      (c.state as MessagesReady).messages.where((m) => m.clientTxnId == 'q1'),
      isEmpty,
      reason: 'баббл снят через outboxRoomChanges',
    );
    expect(await store.allOutbox(), isEmpty, reason: 'строка удалена');
    expect(file.existsSync(), isFalse, reason: 'локальная копия удалена');
    await c.dispose();
    await events.close();
    await store.close();
  });

  test('isOutboxTxn: только для строк очереди и только при живом sender-е',
      () async {
    final store = await openStore();
    await store.enqueueOutbox(
      OutboxItem(
        clientTxnId: 'q1',
        userId: _kSelfUid,
        roomId: _kRoomId,
        kind: OutboxKind.text,
        body: 'queued',
        createdAt: 1,
      ),
    );
    final rpc = _FakeRpc();
    final events = StreamController<MessengerEvent>.broadcast();

    // Без sender-а: строка видна бабблом, но retry/discard были бы no-op —
    // значит и признак false (иначе UI показал бы мёртвые кнопки).
    final noSender = MessagesController(
      roomId: _kRoomId,
      rpc: rpc,
      events: events.stream,
      selfMessengerUserId: _kSelfUid,
      selfMatrixUserId: _kSelfMxid,
      cache: store,
    );
    await noSender.init();
    await settle();
    expect(noSender.isOutboxTxn('q1'), isFalse);
    await noSender.dispose();

    final c = MessagesController(
      roomId: _kRoomId,
      rpc: rpc,
      events: events.stream,
      selfMessengerUserId: _kSelfUid,
      selfMatrixUserId: _kSelfMxid,
      cache: store,
      outbox: _SpyOutbox(store: store, rpc: rpc),
    );
    await c.init();
    await settle();
    expect(c.isOutboxTxn('q1'), isTrue);
    expect(c.isOutboxTxn('unknown'), isFalse);
    expect(c.isOutboxTxn(null), isFalse);
    await c.dispose();
    await events.close();
    await store.close();
  });

  // ─────────────────────────────────────────────────── UI ──

  group('UI', () {
    late _SpyController controller;

    setUp(() {
      controller = _SpyController();
    });

    tearDown(() => controller.dispose());

    ChatMessage queued({
      String txnId = 'q1',
      ChatMessageStatus status = ChatMessageStatus.pending,
    }) => ChatMessage(
      clientTxnId: txnId,
      matrixEventId: null,
      senderMatrixUserId: _kSelfMxid,
      senderMessengerUserId: _kSelfUid,
      body: 'contract.pdf',
      msgType: 'm.file',
      serverTimestamp: DateTime.utc(2026, 1, 1),
      status: status,
    );

    Widget sheetApp(ChatMessage m) => MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showMessageActionSheet(
              context: ctx,
              message: m,
              isOwn: true,
              controller: controller,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    testWidgets('long-press по pending-бабблу очереди открывает шит', (
      tester,
    ) async {
      // Раньше гейт требовал `isSent` — зависший в очереди пузырь не
      // реагировал на long-press вообще.
      ChatMessage? pressed;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: NsgL10n.localizationsDelegates,
          supportedLocales: NsgL10n.supportedLocales,
          home: Scaffold(
            body: MessageBubble(
              message: queued(),
              isOwn: true,
              onRetry: (_) {},
              onLongPress: (m) => pressed = m,
            ),
          ),
        ),
      );
      await tester.longPress(find.text('contract.pdf'));
      // Не pumpAndSettle: у pending-баббла крутится индикатор отправки,
      // кадры не кончаются никогда.
      await tester.pump();
      expect(pressed?.clientTxnId, 'q1');
    });

    testWidgets('шит очереди: «Повторить» зовёт retryOutbox', (tester) async {
      controller.outboxTxns.add('q1');
      await tester.pumpWidget(sheetApp(queued()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Пункты «отправленного» сообщения для очереди не показываются.
      expect(find.text('Reply'), findsNothing);
      expect(find.text('Forward'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(controller.retriedOutbox, ['q1']);
      expect(controller.retriedInMemory, isEmpty);
    });

    testWidgets('шит очереди: «Отменить отправку» зовёт discardOutbox', (
      tester,
    ) async {
      controller.outboxTxns.add('q1');
      await tester.pumpWidget(sheetApp(queued()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel sending'));
      await tester.pumpAndSettle();
      expect(controller.discarded, ['q1']);
    });

    testWidgets('баббл без строки очереди: отмены нет, retry — in-memory', (
      tester,
    ) async {
      // In-memory failed (композер, экран открыт): очереди за ним нет,
      // «Отменить отправку» удалять нечего.
      await tester.pumpWidget(
        sheetApp(queued(status: ChatMessageStatus.failed)),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel sending'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(controller.retriedInMemory, ['q1']);
      expect(controller.retriedOutbox, isEmpty);
    });
  });
}

/// Записывает вызовы UI-операций, дренаж не запускает (нет `super`-вызова) —
/// поэтому «в RPC ничего не ушло» проверяется без гонки с фоновой отправкой.
class _SpyOutbox extends OutboxSender {
  _SpyOutbox({required super.store, required super.rpc});

  final List<String> retried = <String>[];
  final List<String> discarded = <String>[];

  @override
  Future<void> retry(String clientTxnId) async => retried.add(clientTxnId);

  @override
  Future<void> discard(String clientTxnId) async => discarded.add(clientTxnId);
}

/// Контроллер для шита: подменяет только outbox-операции, `retry` остаётся
/// настоящим (проверяем, что in-memory путь зовётся именно там, где надо).
class _SpyController extends MessagesController {
  _SpyController()
    : super(
        roomId: _kRoomId,
        rpc: _FakeRpc(),
        events: const Stream<MessengerEvent>.empty(),
        selfMessengerUserId: _kSelfUid,
        selfMatrixUserId: _kSelfMxid,
      );

  final Set<String> outboxTxns = <String>{};
  final List<String> retriedOutbox = <String>[];
  final List<String> retriedInMemory = <String>[];
  final List<String> discarded = <String>[];

  @override
  bool isOutboxTxn(String? clientTxnId) =>
      clientTxnId != null && outboxTxns.contains(clientTxnId);

  @override
  Future<void> retryOutbox(String clientTxnId) async =>
      retriedOutbox.add(clientTxnId);

  @override
  Future<void> discardOutbox(String clientTxnId) async =>
      discarded.add(clientTxnId);

  @override
  Future<void> retry(String clientTxnId) async {
    retriedInMemory.add(clientTxnId);
    await super.retry(clientTxnId);
  }
}

/// listMessages → пустая страница; sendMessage — записывает и падает, если
/// его позвали (тесты проверяют, что мимо очереди отправки НЕ происходит).
class _FakeRpc implements MessagesRpc {
  final List<String> sentBodies = <String>[];

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(
    messages: const [],
    nextToken: null,
    prevToken: null,
  );

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
  }) async {
    sentBodies.add(body);
    return MessengerMessage(
      matrixEventId: 'evt-$clientTxnId',
      roomId: roomId,
      matrixRoomId: '!r:test',
      senderMessengerUserId: _kSelfUid,
      senderMatrixUserId: _kSelfMxid,
      msgType: msgType,
      body: body,
      content: ByteData(0),
      serverTimestamp: DateTime.utc(2026, 1, 1),
      clientTxnId: clientTxnId,
    );
  }

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

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
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
