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

/// **TASK20 Chunk 4-prep**: widget test для lifecycle observer-а
/// `ChatScreen` — на `didChangeAppLifecycleState(resumed)` re-шлёт
/// `setPresence(currentRoomId: widget.roomId, foreground: true)`
/// чтобы перезаписать `null` от bus's lifecycle handler.
void main() {
  testWidgets(
    'ChatScreen на resumed lifecycle re-fires setPresence(currentRoomId)',
    (tester) async {
      final calls = <({int? currentRoomId, bool foreground})>[];
      final upstream = StreamController<MessengerEvent>.broadcast();
      final stateCtl = StreamController<MessengerSessionState>.broadcast();
      final eventBus = MessengerEventBus.attachWithFactory(
        streamFactory: () => upstream.stream,
        sessionStateStream: stateCtl.stream,
      );

      // In-memory controller — bypass MessengerRuntime.
      final controller = MessagesController(
        roomId: 42,
        rpc: _StubRpc(),
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
            roomId: 42,
            controllerOverride: controller,
            setPresenceOverride:
                ({int? currentRoomId, required bool foreground}) async {
                  calls.add((
                    currentRoomId: currentRoomId,
                    foreground: foreground,
                  ));
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial fire на initState — currentRoomId=42, foreground=true.
      expect(calls, hasLength(1));
      expect(calls.first.currentRoomId, 42);
      expect(calls.first.foreground, isTrue);

      // Simulate `resumed` lifecycle event directly via observer
      // (`tester.binding.handleAppLifecycleStateChanged` enforces strict
      // transition assertion which doesn't reflect real-device behavior
      // on backgrounded → foreground; bypass via direct observer call).
      final stateObj = tester.state(find.byType(ChatScreen));
      // ignore: avoid_dynamic_calls
      (stateObj as dynamic).didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      );
      await tester.pump();

      // ChatScreen на resumed re-шлёт setPresence(roomId=42).
      expect(
        calls,
        hasLength(2),
        reason: 'paused → resumed should trigger one extra fire',
      );
      expect(calls.last.currentRoomId, 42);
      expect(calls.last.foreground, isTrue);
    },
  );

  testWidgets('ChatScreen.dispose clears currentRoomId (null)', (tester) async {
    final calls = <({int? currentRoomId, bool foreground})>[];
    final upstream = StreamController<MessengerEvent>.broadcast();
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final eventBus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final controller = MessagesController(
      roomId: 99,
      rpc: _StubRpc(),
      events: eventBus.events,
      selfMessengerUserId: 1,
      selfMatrixUserId: '@alice:test',
    );
    addTearDown(() async {
      await upstream.close();
      await stateCtl.close();
    });

    await tester.pumpWidget(
      wrapL10n(
        ChatScreen(
          roomId: 99,
          controllerOverride: controller,
          setPresenceOverride:
              ({int? currentRoomId, required bool foreground}) async {
                calls.add((
                  currentRoomId: currentRoomId,
                  foreground: foreground,
                ));
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(calls.first.currentRoomId, 99);

    // Replace widget tree → ChatScreen disposes.
    await tester.pumpWidget(wrapL10n(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    // Dispose fires setPresence(currentRoomId: null) для clearing
    // server-side presence cache.
    expect(calls.last.currentRoomId, isNull);
    expect(calls.last.foreground, isTrue);
  });
}

/// Минимальный stub RPC для in-memory MessagesController в тесте.
class _StubRpc implements MessagesRpc {
  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: const []);

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
}
