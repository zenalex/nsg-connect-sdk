import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/rooms/chats_list_controller.dart';
import 'package:nsg_messenger/src/rooms/room_action_sheet.dart';
import 'package:nsg_messenger/src/runtime/messenger_event_bus.dart';

import '../test_helpers.dart';

/// **Меню действий комнаты на низком экране.**
///
/// Набор пунктов переменный: mute/archive/leave есть всегда, у support-комнат
/// добавляется «закрыть до ответа», а host-app досыпает свои через
/// `extraActions`. При этом `showModalBottomSheet` без `isScrollControlled`
/// отводит панели максимум 9/16 высоты экрана. На невысоком окне пункты
/// переставали помещаться: `Column` рвался с «BOTTOM OVERFLOWED BY N PIXELS»,
/// и до нижних пунктов («Выйти») было не добраться.
///
/// Тест держит именно это: на низком экране с полным набором пунктов панель
/// не ломается и последний пункт остаётся достижимым прокруткой.
void main() {
  RoomSummary buildRoom({RoomType roomType = RoomType.group}) => RoomSummary(
    id: 1,
    name: 'Test',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: roomType,
  );

  ChatsListController makeController() {
    final stateCtl = StreamController<MessengerSessionState>.broadcast();
    final upstream = StreamController<MessengerEvent>.broadcast();
    addTearDown(stateCtl.close);
    addTearDown(upstream.close);
    final bus = MessengerEventBus.attachWithFactory(
      streamFactory: () => upstream.stream,
      sessionStateStream: stateCtl.stream,
    );
    final rooms = NsgMessengerRooms.attachWithRpcs(
      listRpc:
          ({
            productId,
            state,
            search,
            includeArchived,
            limit = 50,
            cursor,
          }) async => const [],
      getRpc: ({required int roomId}) async => throw UnimplementedError(),
      createDirectRpc: ({required int peerMessengerUserId}) async =>
          throw UnimplementedError(),
      createGroupRpc:
          ({
            required String name,
            required List<int> memberMessengerUserIds,
            int? productId,
          }) async => throw UnimplementedError(),
      getOrCreateProductRoomRpc:
          ({
            required String productExternalKey,
            required String entityType,
            required String entityId,
            required RoomType roomType,
          }) async => throw UnimplementedError(),
      openSupportChatRpc:
          ({
            required String productExternalKey,
            required String contextId,
          }) async => throw UnimplementedError(),
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
          ({required int roomId, required int targetMessengerUserId}) async {},
      setRoomMemberRoleRpc:
          ({
            required int roomId,
            required int targetMessengerUserId,
            required RoomMemberRole newRole,
          }) async {},
      listBannedUsersRpc: ({required int roomId}) async => const [],
      eventBus: bus,
    );
    final controller = ChatsListController(
      rooms: rooms,
      events: upstream.stream,
      sessionStates: stateCtl.stream,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  /// Открывает панель на экране заданной высоты.
  Future<void> openSheet(
    WidgetTester tester, {
    required Size screen,
    required RoomSummary room,
    List<RoomActionEntry> extraActions = const [],
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showRoomActionSheet(
                context: context,
                room: room,
                controller: makeController(),
                extraActions: extraActions,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Полный набор: support-комната (даёт «закрыть до ответа») + host-овые
  /// пункты. Столько бывает у оператора поддержки в chatista.
  final crowded = [
    for (var i = 0; i < 4; i++)
      RoomActionEntry(
        icon: Icons.person_add,
        label: 'Host action $i',
        onTap: () {},
      ),
  ];

  testWidgets('низкий экран, много пунктов — панель не рвётся', (tester) async {
    await openSheet(
      tester,
      // 640 логических точек в высоту — панели достаётся 9/16, то есть 360.
      // Полный набор пунктов в такую высоту не влезает.
      screen: const Size(400, 640),
      room: buildRoom(roomType: RoomType.support),
      extraActions: crowded,
    );

    // Именно это и падало: RenderFlex overflow приходит исключением в тест.
    expect(tester.takeException(), isNull);
  });

  testWidgets('нижний пункт «Выйти» достижим прокруткой', (tester) async {
    await openSheet(
      tester,
      screen: const Size(400, 640),
      room: buildRoom(roomType: RoomType.support),
      extraActions: crowded,
    );

    // Смысл фикса не в отсутствии красной полосы, а в том, что до последнего
    // пункта можно добраться: обрезанный Column просто не отдавал его.
    final leave = find.text('Leave chat');
    await tester.scrollUntilVisible(leave, 80);
    expect(leave, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('на высоком экране лишней прокрутки не появляется', (
    tester,
  ) async {
    // Панель по-прежнему по высоте содержимого, а не во весь экран: обёртка
    // не должна сама по себе делать её прокручиваемой.
    await openSheet(tester, screen: const Size(400, 1600), room: buildRoom());

    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(state.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });
}
