import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart' show MessengerSessionState;
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';
import 'package:nsg_messenger/src/screens/chat_screen.dart';

import '../test_helpers.dart';

/// **TASK22-Phase2 Chunk 1-B**: тест, что `loadMoreThresholdPxOverride`
/// корректно меняет точку срабатывания pagination trigger в ChatScreen.
///
/// Кейс: dispatch-им ScrollUpdateNotification с такой `pixels`/`max`,
/// что distance to maxScrollExtent = 500. При default-threshold=200
/// (200 < 500) — loadMore НЕ должен сработать. При override=999
/// (999 > 500) — loadMore сработает.
void main() {
  testWidgets(
    'loadMoreThresholdPxOverride=999 triggers loadMore at distance=500 '
    '(вызовет, тогда как default=200 нет)',
    (tester) async {
      final upstream = StreamController<MessengerEvent>.broadcast();
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final eventBus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        sessionStateStream: stateCtl.stream,
      );
      final rpc = _CountingRpc();
      final controller = MessagesController(
        roomId: 7,
        rpc: rpc,
        events: eventBus.events,
        selfMessengerUserId: 1,
        selfMatrixUserId: '@alice:test',
      );
      addTearDown(() async {
        await controller.dispose();
        await upstream.close();
        await stateCtl.close();
      });

      await tester.pumpWidget(
        wrapL10n(
          ChatScreen(
            roomId: 7,
            controllerOverride: controller,
            loadMoreThresholdPxOverride: 999,
            setPresenceOverride:
                ({int? currentRoomId, required bool foreground}) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial listMessages вызов в init() — baseline.
      final initialCalls = rpc.listCalls;
      expect(
        initialCalls,
        greaterThanOrEqualTo(1),
        reason: 'controller.init() должен вызвать initial listMessages',
      );

      // Найти inner Scrollable у ListView.builder (не TextField composer).
      // У нас 1 ListView в _Loaded — его Scrollable.
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final scrollableEl = tester.element(
        find.descendant(of: listFinder, matching: find.byType(Scrollable)),
      );

      // pixels=500, maxScrollExtent=1000 → distance = 500.
      //   override=999: 500 >= (1000-999)=1 → fire.
      //   default=200: 500 >= (1000-200)=800 → NO fire.
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: 500,
        viewportDimension: 400,
        axisDirection: AxisDirection.up,
        devicePixelRatio: 1.0,
      );
      ScrollUpdateNotification(
        metrics: metrics,
        context: scrollableEl,
        scrollDelta: 1,
      ).dispatch(scrollableEl);
      // Pump для async loadMore.
      await tester.pumpAndSettle();

      expect(
        rpc.listCalls,
        greaterThan(initialCalls),
        reason:
            'override=999 → distance=500 уже трешхолд достиг. '
            'Без override (default=200) этот scroll loadMore бы не вызвал.',
      );
    },
  );

  testWidgets(
    'loadMoreThresholdPxOverride=50 НЕ триггерит loadMore при distance=500',
    (tester) async {
      final upstream = StreamController<MessengerEvent>.broadcast();
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final eventBus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        sessionStateStream: stateCtl.stream,
      );
      final rpc = _CountingRpc();
      final controller = MessagesController(
        roomId: 8,
        rpc: rpc,
        events: eventBus.events,
        selfMessengerUserId: 1,
        selfMatrixUserId: '@alice:test',
      );
      addTearDown(() async {
        await controller.dispose();
        await upstream.close();
        await stateCtl.close();
      });

      await tester.pumpWidget(
        wrapL10n(
          ChatScreen(
            roomId: 8,
            controllerOverride: controller,
            loadMoreThresholdPxOverride: 50,
            setPresenceOverride:
                ({int? currentRoomId, required bool foreground}) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCalls = rpc.listCalls;
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      final scrollableEl = tester.element(
        find.descendant(of: listFinder, matching: find.byType(Scrollable)),
      );

      // distance=500, threshold=50 → 500 >= (1000-50)=950? NO. loadMore skip.
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: 500,
        viewportDimension: 400,
        axisDirection: AxisDirection.up,
        devicePixelRatio: 1.0,
      );
      ScrollUpdateNotification(
        metrics: metrics,
        context: scrollableEl,
        scrollDelta: 1,
      ).dispatch(scrollableEl);
      await tester.pumpAndSettle();

      expect(
        rpc.listCalls,
        equals(initialCalls),
        reason: 'threshold=50 → distance=500 не достигает, loadMore skip',
      );
    },
  );
}

/// Stub RPC, считающий количество listMessages вызовов. Возвращает
/// page с одним messsage + nextToken (hasMore=true) чтобы controller
/// принял повторный loadMore.
class _CountingRpc implements MessagesRpc {
  int listCalls = 0;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async {
    listCalls++;
    return MessengerMessageListPage(
      messages: [
        MessengerMessage(
          matrixEventId: 'evt$listCalls',
          roomId: roomId,
          matrixRoomId: '!room:test',
          senderMessengerUserId: 2,
          senderMatrixUserId: '@bob:test',
          msgType: 'm.text',
          body: 'hi $listCalls',
          serverTimestamp: DateTime.utc(2026, 1, 1).add(
            Duration(seconds: listCalls),
          ),
        ),
      ],
      nextToken: 't$listCalls',
    );
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
  }) => throw UnimplementedError();

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

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
  Future<void> sendTyping({required int roomId, required bool typing}) async {
    // Stub: no-op.
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
  Future<List<MessengerEvent>> listReadReceipts({
    required int roomId,
  }) async => const <MessengerEvent>[];
}
