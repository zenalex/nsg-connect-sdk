import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/support/support_team_controller.dart';
import 'package:nsg_messenger/src/support/support_team_rpc.dart';
import 'package:nsg_messenger/src/support/support_team_state.dart';

/// **TASK43**: тесты `SupportTeamController` (hand-written fake RPC, по
/// образцу `chats_list_controller_test.dart`):
///   * init → Loading → Ready;
///   * getSupportTeam бросил NotSupportTeamMemberException → Unavailable
///     (unavailable=true, host скрывает экран);
///   * временная ошибка → Unavailable(unavailable=false);
///   * addMember success → busy → Ready(new view);
///   * addMember пустой email → no-op false;
///   * removeMember success;
///   * add/remove failure → возврат в не-busy Ready, false.
void main() {
  SupportTeamView view({
    bool viewerIsOwner = true,
    List<SupportTeamMemberView> members = const [],
    int escalationTimeoutMinutes = 60,
  }) => SupportTeamView(
    teamId: 1,
    productExternalKey: 'titan_control',
    members: members,
    viewerIsOwner: viewerIsOwner,
    escalationTimeoutMinutes: escalationTimeoutMinutes,
  );

  SupportTeamMemberView member(
    int id, {
    SupportTeamRole? role,
    bool bot = false,
    int tier = 1,
  }) => SupportTeamMemberView(
    messengerUserId: id,
    displayName: 'U$id',
    role: role ?? SupportTeamRole.member,
    tier: tier,
    isBot: bot,
  );

  test('init → Loading → Ready', () async {
    final rpc = _FakeRpc(getResult: view(members: [member(1)]));
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    expect(c.state, isA<SupportTeamLoading>());

    await c.init();

    expect(c.state, isA<SupportTeamReady>());
    expect((c.state as SupportTeamReady).view.members.length, 1);
    expect(rpc.getCalls, 1);
    c.dispose();
  });

  test(
    'getSupportTeam NotSupportTeamMember → Unavailable(unavailable=true)',
    () async {
      final rpc = _FakeRpc(getError: NotSupportTeamMemberException());
      final c = SupportTeamController(
        rpc: rpc,
        productExternalKey: 'titan_control',
      );
      await c.init();

      expect(c.state, isA<SupportTeamUnavailable>());
      expect((c.state as SupportTeamUnavailable).unavailable, isTrue);
      c.dispose();
    },
  );

  test('временная ошибка → Unavailable(unavailable=false)', () async {
    final rpc = _FakeRpc(getError: StateError('network'));
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    expect(c.state, isA<SupportTeamUnavailable>());
    expect((c.state as SupportTeamUnavailable).unavailable, isFalse);
    c.dispose();
  });

  test('addMember success → Ready(new view)', () async {
    final rpc = _FakeRpc(
      getResult: view(members: [member(1, role: SupportTeamRole.owner)]),
      addResult: view(
        members: [
          member(1, role: SupportTeamRole.owner),
          member(2),
        ],
      ),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.addMember(' b@nsg.ru ');
    expect(ok, isTrue);
    expect(rpc.lastAddEmail, 'b@nsg.ru', reason: 'email trimmed');
    expect((c.state as SupportTeamReady).view.members.length, 2);
    expect((c.state as SupportTeamReady).busy, isFalse);
    c.dispose();
  });

  test('addMember пустой email → no-op false', () async {
    final rpc = _FakeRpc(getResult: view(members: [member(1)]));
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.addMember('   ');
    expect(ok, isFalse);
    expect(rpc.addCalls, 0);
    c.dispose();
  });

  test('addMember failure → возврат в не-busy Ready, false', () async {
    final rpc = _FakeRpc(
      getResult: view(members: [member(1, role: SupportTeamRole.owner)]),
      addError: PeerUnavailableException(),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.addMember('ghost@nsg.ru');
    expect(ok, isFalse);
    expect(c.state, isA<SupportTeamReady>());
    expect((c.state as SupportTeamReady).busy, isFalse);
    expect((c.state as SupportTeamReady).view.members.length, 1);
    c.dispose();
  });

  test('removeMember success', () async {
    final rpc = _FakeRpc(
      getResult: view(
        members: [
          member(1, role: SupportTeamRole.owner),
          member(2),
        ],
      ),
      removeResult: view(members: [member(1, role: SupportTeamRole.owner)]),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.removeMember(2);
    expect(ok, isTrue);
    expect(rpc.lastRemoveMuid, 2);
    expect((c.state as SupportTeamReady).view.members.length, 1);
    c.dispose();
  });

  test('setMemberTier success → RPC вызван + новый view с тиром 2', () async {
    final rpc = _FakeRpc(
      getResult: view(
        members: [
          member(1, role: SupportTeamRole.owner),
          member(2, tier: 1),
        ],
      ),
      addResult: view(
        members: [
          member(1, role: SupportTeamRole.owner),
          member(2, tier: 2),
        ],
      ),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.setMemberTier(2, 2);
    expect(ok, isTrue);
    expect(rpc.setTierCalls, 1);
    expect(rpc.lastTierMuid, 2);
    expect(rpc.lastTierValue, 2);
    final members = (c.state as SupportTeamReady).view.members;
    expect(members.firstWhere((m) => m.messengerUserId == 2).tier, 2);
    c.dispose();
  });

  test('setTimeout success → RPC вызван с минутами', () async {
    final rpc = _FakeRpc(
      getResult: view(members: [member(1, role: SupportTeamRole.owner)]),
      addResult: view(
        members: [member(1, role: SupportTeamRole.owner)],
        escalationTimeoutMinutes: 30,
      ),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.setTimeout(30);
    expect(ok, isTrue);
    expect(rpc.setTimeoutCalls, 1);
    expect(rpc.lastTimeoutMinutes, 30);
    expect((c.state as SupportTeamReady).view.escalationTimeoutMinutes, 30);
    c.dispose();
  });

  test('removeMember failure → возврат в не-busy Ready, false', () async {
    final rpc = _FakeRpc(
      getResult: view(
        members: [
          member(1, role: SupportTeamRole.owner),
          member(2),
        ],
      ),
      removeError: StateError('boom'),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.removeMember(2);
    expect(ok, isFalse);
    expect(c.state, isA<SupportTeamReady>());
    expect((c.state as SupportTeamReady).busy, isFalse);
    expect((c.state as SupportTeamReady).view.members.length, 2);
    c.dispose();
  });

  // ─────────────── TASK76: setMemberRole (назначение админов) ───────────────

  test('setMemberRole success → RPC вызван + новый view с owner-ролью', () async {
    final rpc = _FakeRpc(
      getResult: view(
        members: [member(1, role: SupportTeamRole.owner), member(2)],
      ),
      addResult: view(
        members: [
          member(1, role: SupportTeamRole.owner),
          member(2, role: SupportTeamRole.owner),
        ],
      ),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.setMemberRole(2, SupportTeamRole.owner);
    expect(ok, isTrue);
    expect(rpc.setRoleCalls, 1);
    expect(rpc.lastRoleMuid, 2);
    expect(rpc.lastRoleValue, SupportTeamRole.owner);
    final ready = c.state as SupportTeamReady;
    expect(ready.busy, isFalse);
    expect(
      ready.view.members.where((m) => m.role == SupportTeamRole.owner).length,
      2,
    );
    c.dispose();
  });

  test('setMemberRole failure (LastOwnerCannotDemote) → не-busy Ready, false',
      () async {
    final rpc = _FakeRpc(
      getResult: view(
        members: [member(1, role: SupportTeamRole.owner), member(2)],
      ),
      addError: LastOwnerCannotDemoteException(),
    );
    final c = SupportTeamController(
      rpc: rpc,
      productExternalKey: 'titan_control',
    );
    await c.init();

    final ok = await c.setMemberRole(1, SupportTeamRole.member);
    expect(ok, isFalse);
    final ready = c.state as SupportTeamReady;
    expect(ready.busy, isFalse);
    expect(
      ready.view.members.where((m) => m.role == SupportTeamRole.owner).length,
      1,
      reason: 'view не изменился — откат к прежнему состоянию',
    );
    c.dispose();
  });
}

class _FakeRpc implements SupportTeamRpc {
  _FakeRpc({
    this.getResult,
    this.getError,
    this.addResult,
    this.addError,
    this.removeResult,
    this.removeError,
  });

  final SupportTeamView? getResult;
  final Object? getError;
  final SupportTeamView? addResult;
  final Object? addError;
  final SupportTeamView? removeResult;
  final Object? removeError;

  int getCalls = 0;
  int addCalls = 0;
  int removeCalls = 0;
  int setTierCalls = 0;
  int setTimeoutCalls = 0;
  String? lastAddEmail;
  int? lastAddTier;
  int? lastRemoveMuid;
  int? lastTierMuid;
  int? lastTierValue;
  int? lastTimeoutMinutes;

  @override
  Future<SupportTeamView> getSupportTeam({
    required String productExternalKey,
  }) async {
    getCalls++;
    if (getError != null) throw getError!;
    return getResult!;
  }

  @override
  Future<SupportTeamView> addMember({
    required String productExternalKey,
    required String email,
    int tier = 1,
  }) async {
    addCalls++;
    lastAddEmail = email;
    lastAddTier = tier;
    if (addError != null) throw addError!;
    return addResult!;
  }

  @override
  Future<SupportTeamView> setMemberTier({
    required String productExternalKey,
    required int targetMessengerUserId,
    required int tier,
  }) async {
    setTierCalls++;
    lastTierMuid = targetMessengerUserId;
    lastTierValue = tier;
    if (addError != null) throw addError!;
    return addResult ?? getResult!;
  }

  @override
  Future<SupportTeamView> setTimeout({
    required String productExternalKey,
    required int minutes,
  }) async {
    setTimeoutCalls++;
    lastTimeoutMinutes = minutes;
    if (addError != null) throw addError!;
    return addResult ?? getResult!;
  }

  @override
  Future<SupportTeamView> removeMember({
    required String productExternalKey,
    required int targetMessengerUserId,
  }) async {
    removeCalls++;
    lastRemoveMuid = targetMessengerUserId;
    if (removeError != null) throw removeError!;
    return removeResult!;
  }

  // **TASK76**: createTeam / setMemberRole.
  int createTeamCalls = 0;
  int setRoleCalls = 0;
  int? lastRoleMuid;
  SupportTeamRole? lastRoleValue;

  @override
  Future<SupportTeamView> createTeam({
    required String productExternalKey,
  }) async {
    createTeamCalls++;
    if (getError != null) throw getError!;
    return getResult!;
  }

  @override
  Future<SupportTeamView> setMemberRole({
    required String productExternalKey,
    required int targetMessengerUserId,
    required SupportTeamRole role,
  }) async {
    setRoleCalls++;
    lastRoleMuid = targetMessengerUserId;
    lastRoleValue = role;
    if (addError != null) throw addError!;
    return addResult ?? getResult!;
  }
}
