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

/// **TASK46 (UI)**: widget-тесты кнопки «Позвонить» в [ChatScreen].
///
/// Покрывает:
///   * кнопка видна ТОЛЬКО для direct 1:1 (не для group/productRoom);
///   * тап → startCall(roomId, peerMessengerUserId) — peer резолвится
///     из participants (единственный, чей id ≠ self).
void main() {
  setUpAll(registerTimeagoLocales);

  const kSelf = 42;

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

  RoomParticipant participant(int id, String mxid, {String? displayName}) =>
      RoomParticipant(
        messengerUserId: id,
        matrixUserId: mxid,
        role: RoomMemberRole.member,
        displayName: displayName,
      );

  RoomDetails details({
    required RoomType roomType,
    List<RoomParticipant>? participants,
  }) => RoomDetails(
    id: 7,
    matrixRoomId: '!r:t',
    name: 'Peer',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: roomType,
    participants:
        participants ??
        [
          participant(kSelf, '@self:t'),
          participant(99, '@peer:t', displayName: 'Пётр'),
        ],
    totalParticipants: 2,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  Future<void> pumpChat(
    WidgetTester tester, {
    required RoomDetails roomDetails,
    StartCallOverride? startCall,
  }) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(MessengerMessageListPage(messages: const []));
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 7,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: kSelf,
      selfMatrixUserId: '@self:t',
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: 7,
          controllerOverride: controller,
          roomDetailsOverride: roomDetails,
          startCallOverride: startCall,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('direct 1:1 → кнопка «Позвонить» видна', (tester) async {
    await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.direct),
      startCall:
          ({
            required int roomId,
            int? peerMessengerUserId,
            String? peerDisplayName,
          }) async {},
    );
    expect(find.byKey(const Key('chatCallButton')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('group → кнопки «Позвонить» НЕТ', (tester) async {
    await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.group),
      startCall:
          ({
            required int roomId,
            int? peerMessengerUserId,
            String? peerDisplayName,
          }) async {},
    );
    expect(find.byKey(const Key('chatCallButton')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('productRoom → кнопки «Позвонить» НЕТ', (tester) async {
    await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.productRoom),
      startCall:
          ({
            required int roomId,
            int? peerMessengerUserId,
            String? peerDisplayName,
          }) async {},
    );
    expect(find.byKey(const Key('chatCallButton')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('тап → startCall(roomId=7, peerMessengerUserId=99)', (
    tester,
  ) async {
    int? calledRoom;
    int? calledPeer;
    String? calledName;
    var calls = 0;
    await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.direct),
      startCall:
          ({
            required int roomId,
            int? peerMessengerUserId,
            String? peerDisplayName,
          }) async {
            calls++;
            calledRoom = roomId;
            calledPeer = peerMessengerUserId;
            calledName = peerDisplayName;
          },
    );
    await tester.tap(find.byKey(const Key('chatCallButton')));
    await tester.pump();
    expect(calls, 1);
    expect(calledRoom, 7);
    expect(calledPeer, 99, reason: 'peer = участник, чей id ≠ self(42)');
    // Имя собеседника прокидывается в startCall (для overlay «Звоним <имя>»).
    expect(
      calledName,
      'Пётр',
      reason: 'peerDisplayName резолвится из participants',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;

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
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_FakeRpc: only load-path RPCs mocked (${invocation.memberName})',
  );

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
