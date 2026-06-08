import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

import '../test_helpers.dart';

/// **TASK29 Chunk 2**: widget tests для [showParticipantActionSheet] —
/// role-based visibility + optimistic + revert flow.
void main() {
  RoomDetails buildRoom({required RoomMemberRole viewerRole}) => RoomDetails(
    id: 1,
    matrixRoomId: '!r:localhost',
    name: 'Test',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
    participants: const [],
    totalParticipants: 0,
    viewerRole: viewerRole,
  );

  RoomParticipant buildTarget({
    int id = 99,
    RoomMemberRole role = RoomMemberRole.member,
    String name = 'bob',
  }) => RoomParticipant(
    messengerUserId: id,
    matrixUserId: '@$name:localhost',
    displayName: name,
    role: role,
  );

  /// Build minimal NsgMessengerRooms с captured RPC calls.
  NsgMessengerRooms makeRooms({
    Future<void> Function(int, int, RoomMemberRole)? onSetRole,
    Future<void> Function(int, int)? onKick,
    Future<void> Function(int, int)? onBan,
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
      getRpc: ({required int roomId}) async =>
          buildRoom(viewerRole: RoomMemberRole.owner),
      createDirectRpc: ({required int peerMessengerUserId}) async =>
          buildRoom(viewerRole: RoomMemberRole.owner),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => buildRoom(viewerRole: RoomMemberRole.owner),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => buildRoom(viewerRole: RoomMemberRole.owner),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => buildRoom(viewerRole: RoomMemberRole.owner),
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
          }) => onKick?.call(roomId, targetMessengerUserId) ?? Future.value(),
      banUserRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            String? reason,
          }) => onBan?.call(roomId, targetMessengerUserId) ?? Future.value(),
      unbanUserRpc:
          ({required int roomId, required int targetMessengerUserId}) async {},
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) =>
              onSetRole?.call(roomId, targetMessengerUserId, newRole) ??
              Future.value(),
      listBannedUsersRpc: ({required int roomId}) async => const [],
      eventBus: bus,
    );
  }

  testWidgets('owner caller → promote/kick/ban visible (member-target)', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final target = buildTarget();
    final rooms = makeRooms();

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: target,
                callerRole: RoomMemberRole.owner,
                callerMessengerUserId: 1,
                rooms: rooms,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Promote to admin'), findsOneWidget);
    expect(find.text('Kick from room'), findsOneWidget);
    expect(find.text('Ban from room'), findsOneWidget);
    expect(find.text('Demote to member'), findsNothing);
  });

  testWidgets('admin caller → 2 actions only (kick/ban; no promote/demote)', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.admin);
    final target = buildTarget();
    final rooms = makeRooms();
    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: target,
                callerRole: RoomMemberRole.admin,
                callerMessengerUserId: 1,
                rooms: rooms,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Kick from room'), findsOneWidget);
    expect(find.text('Ban from room'), findsOneWidget);
    expect(find.text('Promote to admin'), findsNothing);
    expect(find.text('Demote to member'), findsNothing);
  });

  testWidgets(
    'member caller → sheet skip (returns Future.value, no sheet open)',
    (tester) async {
      final room = buildRoom(viewerRole: RoomMemberRole.member);
      final target = buildTarget();
      final rooms = makeRooms();
      await tester.pumpWidget(
        wrapL10n(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showParticipantActionSheet(
                  context: context,
                  room: room,
                  target: target,
                  callerRole: RoomMemberRole.member,
                  callerMessengerUserId: 1,
                  rooms: rooms,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Kick from room'), findsNothing);
      expect(find.text('Promote to admin'), findsNothing);
    },
  );

  testWidgets('self-target (owner caller) → kick/ban hidden', (tester) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final selfTarget = buildTarget(id: 1, name: 'alice');
    final rooms = makeRooms();
    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: selfTarget,
                callerRole: RoomMemberRole.owner,
                callerMessengerUserId: 1,
                rooms: rooms,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Kick from room'), findsNothing);
    expect(find.text('Ban from room'), findsNothing);
  });

  testWidgets('promote action calls setRoomMemberRole RPC (no confirm)', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final target = buildTarget();
    var capturedRole = RoomMemberRole.member;
    var calls = 0;
    final rooms = makeRooms(
      onSetRole: (rid, tid, newRole) async {
        capturedRole = newRole;
        calls++;
      },
    );

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: target,
                callerRole: RoomMemberRole.owner,
                callerMessengerUserId: 1,
                rooms: rooms,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Promote — no confirm dialog (kick/ban require confirm; promote
    // не destructive, голый RPC). Verify wire-through.
    await tester.tap(find.text('Promote to admin'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(capturedRole, RoomMemberRole.admin);
  });

  // ── #6/#7 fix: confirm → RPC. Раньше pop() шёл ДО confirm → диалог на
  // мёртвом контексте → confirmed=null → kick/ban RPC не вызывался вовсе.
  testWidgets('kick: confirm → kickUser RPC вызывается (на success)', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final target = buildTarget();
    var kickCalls = 0;
    var onChangedCalls = 0;
    final rooms = makeRooms(onKick: (rid, tid) async => kickCalls++);

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: target,
                callerRole: RoomMemberRole.owner,
                callerMessengerUserId: 1,
                rooms: rooms,
                onChanged: () => onChangedCalls++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kick from room')); // пункт меню
    await tester.pumpAndSettle(); // confirm-диалог
    // Кнопка подтверждения (FilledButton) имеет тот же текст, что и пункт
    // меню — таргетим по типу, чтобы не попасть в ListTile.
    await tester.tap(find.widgetWithText(FilledButton, 'Kick from room'));
    await tester.pumpAndSettle();
    expect(kickCalls, 1, reason: 'после confirm kickUser обязан вызваться');
    expect(onChangedCalls, 1);
  });

  testWidgets('ban: confirm → banUser RPC вызывается (на success)', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final target = buildTarget();
    var banCalls = 0;
    final rooms = makeRooms(onBan: (rid, tid) async => banCalls++);

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: target,
                callerRole: RoomMemberRole.owner,
                callerMessengerUserId: 1,
                rooms: rooms,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ban from room'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ban from room'));
    await tester.pumpAndSettle();
    expect(banCalls, 1, reason: 'после confirm banUser обязан вызваться');
  });

  // ── B21 fix: onChanged callback ──────────────────────────────────
  testWidgets('onChanged вызывается ПОСЛЕ успешного promote RPC', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final target = buildTarget();
    var onChangedCalls = 0;
    var rpcCalls = 0;
    final rooms = makeRooms(
      onSetRole: (rid, tid, newRole) async {
        rpcCalls++;
        // onChanged НЕ должен сработать до завершения RPC.
        expect(onChangedCalls, 0);
      },
    );

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showParticipantActionSheet(
                context: context,
                room: room,
                target: target,
                callerRole: RoomMemberRole.owner,
                callerMessengerUserId: 1,
                rooms: rooms,
                onChanged: () => onChangedCalls++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Promote to admin'));
    await tester.pumpAndSettle();
    expect(rpcCalls, 1);
    expect(onChangedCalls, 1, reason: 'onChanged должен сработать раз');
  });

  testWidgets('onChanged НЕ вызывается если RPC бросил exception', (
    tester,
  ) async {
    final room = buildRoom(viewerRole: RoomMemberRole.owner);
    final target = buildTarget();
    var onChangedCalls = 0;
    final rooms = makeRooms(
      onSetRole: (rid, tid, newRole) async {
        throw StateError('rpc boom');
      },
    );

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showParticipantActionSheet(
                  context: context,
                  room: room,
                  target: target,
                  callerRole: RoomMemberRole.owner,
                  callerMessengerUserId: 1,
                  rooms: rooms,
                  onChanged: () => onChangedCalls++,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Promote to admin'));
    await tester.pumpAndSettle();
    expect(onChangedCalls, 0,
        reason: 'на ошибке RPC refresh не триггерим');
  });
}
