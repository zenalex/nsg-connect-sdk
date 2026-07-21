import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/screens/contact_profile_screen.dart';
import 'package:nsg_messenger/src/screens/support_team_screen.dart';
import 'package:nsg_messenger/src/support/support_team_rpc.dart';

import '../test_helpers.dart';

/// **#25**: тап по участнику команды поддержки больше не мёртвая цель —
/// открывает профиль этого человека ([ContactProfileScreen]) тем же путём
/// навигации по `messengerUserId`, что список участников комнаты и «Люди».
/// Свою строку не открываем (профиль «глазами себя» бессмыслен).
///
/// `selfMessengerUserIdOverride` подменяет `MessengerRuntime.instance
/// .session` — тест не требует полного init рантайма.
void main() {
  const selfId = 999;

  SupportTeamMemberView member(
    int id, {
    SupportTeamRole? role,
    bool bot = false,
  }) => SupportTeamMemberView(
    messengerUserId: id,
    displayName: 'U$id',
    role: role ?? SupportTeamRole.member,
    tier: 1,
    isBot: bot,
  );

  SupportTeamView view(
    List<SupportTeamMemberView> members, {
    bool owner = true,
  }) => SupportTeamView(
    teamId: 1,
    productExternalKey: 'titan_control',
    members: members,
    viewerIsOwner: owner,
    escalationTimeoutMinutes: 60,
  );

  Future<void> pumpScreen(WidgetTester tester, SupportTeamView v) async {
    await tester.pumpWidget(
      wrapL10n(
        SupportTeamScreen(
          productExternalKey: 'titan_control',
          rpcOverride: _FakeRpc(v),
          selfMessengerUserIdOverride: selfId,
        ),
      ),
    );
    // init() → Loading → Ready → список участников.
    await tester.pumpAndSettle();
  }

  testWidgets('тап по участнику (не по себе) открывает ContactProfileScreen', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      view([member(selfId, role: SupportTeamRole.owner), member(1)]),
    );

    expect(find.text('U1'), findsOneWidget);
    expect(find.byType(ContactProfileScreen), findsNothing);

    await tester.tap(find.text('U1'));
    await tester.pump(); // старт push-перехода
    await tester.pump(const Duration(seconds: 1)); // завершить переход

    expect(
      find.byType(ContactProfileScreen),
      findsOneWidget,
      reason: 'тап по участнику должен открыть его профиль',
    );
  });

  testWidgets('onTap задан у чужой строки и == null у своей', (tester) async {
    await pumpScreen(
      tester,
      view([member(selfId, role: SupportTeamRole.owner), member(1)]),
    );

    final other = tester.widget<ListTile>(find.widgetWithText(ListTile, 'U1'));
    expect(
      other.onTap,
      isNotNull,
      reason: 'строка участника — не мёртвая цель',
    );

    final self = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'U$selfId'),
    );
    expect(self.onTap, isNull, reason: 'свою строку не открываем');
  });

  testWidgets('тап по своей строке ничего не открывает', (tester) async {
    await pumpScreen(
      tester,
      view([member(selfId, role: SupportTeamRole.owner)]),
    );

    await tester.tap(find.text('U$selfId'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ContactProfileScreen), findsNothing);
  });
}

/// Минимальный fake: экрану для теста тапа нужен только `getSupportTeam`.
class _FakeRpc implements SupportTeamRpc {
  _FakeRpc(this._view);

  final SupportTeamView _view;

  @override
  Future<SupportTeamView> getSupportTeam({
    required String productExternalKey,
  }) async => _view;

  @override
  Future<SupportTeamView> addMember({
    required String productExternalKey,
    required String email,
    int tier = 1,
  }) => throw UnimplementedError();

  @override
  Future<SupportTeamView> removeMember({
    required String productExternalKey,
    required int targetMessengerUserId,
  }) => throw UnimplementedError();

  @override
  Future<SupportTeamView> setMemberTier({
    required String productExternalKey,
    required int targetMessengerUserId,
    required int tier,
  }) => throw UnimplementedError();

  @override
  Future<SupportTeamView> setTimeout({
    required String productExternalKey,
    required int minutes,
  }) => throw UnimplementedError();

  @override
  Future<SupportTeamView> createTeam({required String productExternalKey}) =>
      throw UnimplementedError();

  @override
  Future<SupportTeamView> setMemberRole({
    required String productExternalKey,
    required int targetMessengerUserId,
    required SupportTeamRole role,
  }) => throw UnimplementedError();
}
