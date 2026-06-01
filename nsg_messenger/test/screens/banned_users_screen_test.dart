import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show InsufficientPowerException;
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';
import 'package:nsg_messenger/src/screens/banned_users_screen.dart';

import '../test_helpers.dart';

/// **TASK29 Chunk 2**: widget tests для [BannedUsersScreen] —
/// empty-state, list rendering, optimistic unban + revert.
void main() {
  RoomDetails stubRoom() => RoomDetails(
    id: 1,
    matrixRoomId: '!r:localhost',
    name: 'Test',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
    participants: const [],
    totalParticipants: 0,
    viewerRole: RoomMemberRole.owner,
  );

  RoomParticipant banned(int id, String name) => RoomParticipant(
    messengerUserId: id,
    matrixUserId: '@$name:localhost',
    displayName: name,
    role: RoomMemberRole.member,
  );

  NsgMessengerRooms makeRooms({
    required Future<List<RoomParticipant>> Function() onList,
    Future<void> Function(int, int)? onUnban,
  }) {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    return NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            productId,
            state,
            search,
            includeArchived,
            limit = 50,
            cursor,
          }) async => const [],
      getRpc: ({required int roomId}) async => stubRoom(),
      createDirectRpc: ({required int peerMessengerUserId}) async => stubRoom(),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => stubRoom(),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => stubRoom(),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => stubRoom(),
      muteRoomRpc:
          ({
            required int roomId,
            DateTime? mutedUntil,
            int? muteForSeconds,
          }) async {},
      unmuteRoomRpc: ({required int roomId}) async {},
      archiveRoomRpc: ({required int roomId}) async {},
      unarchiveRoomRpc: ({required int roomId}) async {},
      leaveRoomRpc: ({required int roomId}) async {},
      getAvailableProductsRpc: () async => const [],
      kickUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      banUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) async {},
      unbanUserRpc:
          ({required int roomId, required int targetMessengerUserId}) =>
              onUnban?.call(roomId, targetMessengerUserId) ?? Future.value(),
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) async {},
      listBannedUsersRpc: ({required int roomId}) => onList(),
      eventBus: bus,
    );
  }

  testWidgets('empty list → empty-state widget', (tester) async {
    final rooms = makeRooms(onList: () async => const []);
    await tester.pumpWidget(
      wrapL10n(BannedUsersScreen(roomId: 1, roomsOverride: rooms)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No banned users'), findsOneWidget);
  });

  testWidgets('non-empty → ListView с unban-button per tile', (tester) async {
    final rooms = makeRooms(
      onList: () async => [banned(2, 'bob'), banned(3, 'carol')],
    );
    await tester.pumpWidget(
      wrapL10n(BannedUsersScreen(roomId: 1, roomsOverride: rooms)),
    );
    await tester.pumpAndSettle();
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('carol'), findsOneWidget);
    expect(find.text('Unban'), findsNWidgets(2));
  });

  testWidgets('optimistic unban: tile исчезает мгновенно при success', (
    tester,
  ) async {
    final rooms = makeRooms(
      onList: () async => [banned(2, 'bob')],
      onUnban: (rid, tid) async {},
    );
    await tester.pumpWidget(
      wrapL10n(BannedUsersScreen(roomId: 1, roomsOverride: rooms)),
    );
    await tester.pumpAndSettle();
    expect(find.text('bob'), findsOneWidget);

    await tester.tap(find.text('Unban'));
    await tester.pumpAndSettle();
    expect(find.text('bob'), findsNothing);
    expect(find.text('No banned users'), findsOneWidget);
  });

  testWidgets('optimistic unban: revert + snackbar при RPC fail', (
    tester,
  ) async {
    final rooms = makeRooms(
      onList: () async => [banned(2, 'bob')],
      onUnban: (rid, tid) async => throw InsufficientPowerException(),
    );
    await tester.pumpWidget(
      wrapL10n(BannedUsersScreen(roomId: 1, roomsOverride: rooms)),
    );
    await tester.pumpAndSettle();
    expect(find.text('bob'), findsOneWidget);

    await tester.tap(find.text('Unban'));
    await tester.pump(); // optimistic remove
    // Revert + snackbar after RPC fail.
    await tester.pumpAndSettle();
    expect(find.text('bob'), findsOneWidget);
    expect(find.textContaining("don't have permission"), findsOneWidget);
  });
}
