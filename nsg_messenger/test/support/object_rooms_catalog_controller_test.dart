import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/support/object_rooms_catalog_controller.dart';
import 'package:nsg_messenger/src/support/object_rooms_catalog_rpc.dart';
import 'package:nsg_messenger/src/support/object_rooms_catalog_state.dart';

/// **TASK45 фаза 1 п.5**: unit-тесты [ObjectRoomsCatalogController] с
/// hand-written fake RPC (как SupportTeamController).
void main() {
  ProductObjectRoom room(int id, {bool member = false}) => ProductObjectRoom(
    roomId: id,
    matrixRoomId: '!$id:t',
    name: 'Объект $id',
    viewerIsMember: member,
    participantsPreview: const [],
    totalParticipants: 2,
  );

  test('init: успех → Ready со списком', () async {
    final rpc = _FakeRpc(list: [room(1), room(2)]);
    final c = ObjectRoomsCatalogController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();
    final s = c.state;
    expect(s, isA<ObjectRoomsCatalogReady>());
    expect((s as ObjectRoomsCatalogReady).rooms.length, 2);
  });

  test('init: не член команды → Unavailable(unavailable=true)', () async {
    final rpc = _FakeRpc(listError: NotSupportTeamMemberException());
    final c = ObjectRoomsCatalogController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();
    final s = c.state;
    expect(s, isA<ObjectRoomsCatalogUnavailable>());
    expect((s as ObjectRoomsCatalogUnavailable).unavailable, isTrue);
  });

  test(
    'join: успех → viewerIsMember обновился (перезагрузка каталога)',
    () async {
      final rpc = _FakeRpc(list: [room(1, member: false)]);
      final c = ObjectRoomsCatalogController(
        rpc: rpc,
        productExternalKey: 'titan_control',
      );
      await c.init();
      // После join RPC вернёт список с member=true.
      rpc.list = [room(1, member: true)];
      final details = await c.join(1);
      expect(details, isNotNull);
      expect(rpc.joinCalls, [1]);
      final s = c.state as ObjectRoomsCatalogReady;
      expect(s.rooms.single.viewerIsMember, isTrue);
      expect(s.busyRoomId, isNull);
    },
  );

  test('join: ошибка → null, busy сброшен, список без изменений', () async {
    final rpc = _FakeRpc(
      list: [room(1, member: false)],
      joinError: StateError('x'),
    );
    final c = ObjectRoomsCatalogController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();
    final details = await c.join(1);
    expect(details, isNull);
    final s = c.state as ObjectRoomsCatalogReady;
    expect(s.rooms.single.viewerIsMember, isFalse);
    expect(s.busyRoomId, isNull);
  });

  test('leave: успех → перезагрузка каталога', () async {
    final rpc = _FakeRpc(list: [room(1, member: true)]);
    final c = ObjectRoomsCatalogController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();
    rpc.list = [room(1, member: false)];
    final ok = await c.leave(1);
    expect(ok, isTrue);
    expect(rpc.leaveCalls, [1]);
    final s = c.state as ObjectRoomsCatalogReady;
    expect(s.rooms.single.viewerIsMember, isFalse);
  });
}

class _FakeRpc implements ObjectRoomsCatalogRpc {
  _FakeRpc({this.list = const [], this.listError, this.joinError});

  List<ProductObjectRoom> list;
  final Object? listError;
  final Object? joinError;
  final joinCalls = <int>[];
  final leaveCalls = <int>[];

  @override
  Future<List<ProductObjectRoom>> listProductObjectRooms({
    required String productExternalKey,
  }) async {
    final e = listError;
    if (e != null) throw e;
    return list;
  }

  @override
  Future<RoomDetails> joinProductRoom({required int roomId}) async {
    joinCalls.add(roomId);
    final e = joinError;
    if (e != null) throw e;
    return RoomDetails(
      id: roomId,
      matrixRoomId: '!$roomId:t',
      unreadCount: 0,
      archived: false,
      muted: false,
      roomType: RoomType.productRoom,
      participants: const [],
      totalParticipants: 1,
      viewerRole: RoomMemberRole.member,
      canEscalateSupport: false,
    );
  }

  @override
  Future<void> leaveProductRoom({required int roomId}) async {
    leaveCalls.add(roomId);
  }
}
