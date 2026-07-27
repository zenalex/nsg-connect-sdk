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
    String? email,
  }) => SupportTeamMemberView(
    messengerUserId: id,
    displayName: 'U$id',
    role: role ?? SupportTeamRole.member,
    tier: 1,
    isBot: bot,
    email: email,
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

  /// **TASK73**: экран, ОТКРЫТЫЙ поверх другого — «Покинуть команду»
  /// закрывает его через `Navigator.pop`, и на root-роуте это не проверить.
  Future<void> pumpPushed(WidgetTester tester, _FakeRpc rpc) async {
    await tester.pumpWidget(
      wrapL10n(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<bool>(
                builder: (_) => SupportTeamScreen(
                  productExternalKey: 'titan_control',
                  rpcOverride: rpc,
                  selfMessengerUserIdOverride: selfId,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
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

  // ─────────────────────────────────────────────────────────────────
  // TASK73: приватность email
  // ─────────────────────────────────────────────────────────────────

  group('приватность email', () {
    testWidgets('владелец видит email участника', (tester) async {
      await pumpScreen(
        tester,
        view([
          member(selfId, role: SupportTeamRole.owner),
          member(1, email: 'op@nsg.ru'),
        ], owner: true),
      );

      expect(find.textContaining('op@nsg.ru'), findsOneWidget);
    });

    testWidgets('не-владелец email НЕ видит, даже если он приехал в view', (
      tester,
    ) async {
      // Сервер (TASK73) не-владельцу email уже не кладёт; здесь проверяем
      // ВТОРОЙ слой защиты — экран не рисует его, даже если поле пришло
      // (старый сервер, чужой бэкенд, подменённый ответ).
      await pumpScreen(
        tester,
        view([
          member(selfId),
          member(1, email: 'op@nsg.ru'),
        ], owner: false),
      );

      expect(find.text('U1'), findsOneWidget, reason: 'состав отрисован');
      expect(find.textContaining('op@nsg.ru'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // TASK73: «Покинуть команду»
  // ─────────────────────────────────────────────────────────────────

  group('покинуть команду', () {
    testWidgets('успех: подтверждение → RPC → экран закрывается', (
      tester,
    ) async {
      final rpc = _FakeRpc(view([member(selfId), member(1)], owner: false));
      await pumpPushed(tester, rpc);

      await tester.tap(find.byKey(const Key('leaveTeamTile')));
      await tester.pumpAndSettle();
      // Без подтверждения ничего не происходит — действие необратимое.
      expect(find.text('Leave the support team?'), findsOneWidget);
      expect(rpc.leaveCalls, 0);

      await tester.tap(find.byKey(const Key('confirmLeaveButton')));
      await tester.pumpAndSettle();

      expect(rpc.leaveCalls, 1);
      expect(
        find.byType(SupportTeamScreen),
        findsNothing,
        reason: 'после выхода экран закрывается, а не остаётся с ошибкой',
      );
      expect(find.text('unavailable-screen-marker'), findsNothing);
    });

    testWidgets('последний владелец: свой текст отказа, экран остаётся', (
      tester,
    ) async {
      final rpc = _FakeRpc(view([member(selfId, role: SupportTeamRole.owner)]))
        ..leaveError = LastOwnerCannotDemoteException();
      await pumpPushed(tester, rpc);

      await tester.tap(find.byKey(const Key('leaveTeamTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmLeaveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SupportTeamScreen), findsOneWidget);
      expect(
        find.textContaining('only owner of this team'),
        findsOneWidget,
        reason: 'отказ — инструкция «назначьте админа», а не «попробуйте ещё»',
      );
    });

    testWidgets('отмена в диалоге: RPC не дёргается', (tester) async {
      final rpc = _FakeRpc(view([member(selfId)], owner: false));
      await pumpPushed(tester, rpc);

      await tester.tap(find.byKey(const Key('leaveTeamTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(rpc.leaveCalls, 0);
      expect(find.byType(SupportTeamScreen), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // TASK73: ревью-фиксы UX (подтверждение удаления, retry, «нет юзера»)
  // ─────────────────────────────────────────────────────────────────

  group('удаление участника — с подтверждением', () {
    Future<void> openMemberMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('memberMenu_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
    }

    testWidgets('отмена → участник остаётся', (tester) async {
      final rpc = _FakeRpc(
        view([member(selfId, role: SupportTeamRole.owner), member(1)]),
      );
      await pumpPushed(tester, rpc);

      await openMemberMenu(tester);
      expect(find.text('Remove from the team?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(rpc.removeCalls, 0, reason: 'промах по меню не удаляет человека');
    });

    testWidgets('подтверждение → RPC вызван', (tester) async {
      final rpc = _FakeRpc(
        view([member(selfId, role: SupportTeamRole.owner), member(1)]),
      );
      await pumpPushed(tester, rpc);

      await openMemberMenu(tester);
      await tester.tap(find.byKey(const Key('confirmRemoveButton')));
      await tester.pumpAndSettle();

      expect(rpc.removeCalls, 1);
    });
  });

  testWidgets('временная ошибка загрузки → кнопка «Повторить» перезапрашивает', (
    tester,
  ) async {
    final rpc = _FakeRpc(view([member(1)]), getError: StateError('network'));
    await pumpPushed(tester, rpc);

    expect(rpc.getCalls, 1);
    final retry = find.byKey(const Key('retryLoadButton'));
    expect(retry, findsOneWidget, reason: 'сеть — не гейт, должен быть выход');

    rpc.getError = null;
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(rpc.getCalls, 2);
    expect(find.text('U1'), findsOneWidget, reason: 'состав загрузился');
  });

  testWidgets('гейт «не участник» → retry НЕ показываем', (tester) async {
    final rpc = _FakeRpc(
      view([member(1)]),
      getError: NotSupportTeamMemberException(),
    );
    await pumpPushed(tester, rpc);

    expect(find.byKey(const Key('retryLoadButton')), findsNothing);
  });

  testWidgets('добавление нерезолвимого email → «пусть сперва войдёт»', (
    tester,
  ) async {
    final rpc = _FakeRpc(view([member(selfId, role: SupportTeamRole.owner)]))
      ..addError = PeerUnavailableException();
    await pumpPushed(tester, rpc);

    await tester.enterText(find.byType(TextField), 'nobody@nsg.ru');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(rpc.addCalls, 1);
    expect(
      find.textContaining('sign in to the app at least once'),
      findsOneWidget,
      reason: 'повтор тут не поможет — совет должен быть другой',
    );
  });
}

/// Fake экрана: `getSupportTeam` + мутации, которые экран действительно
/// дёргает (add/remove/leave), с инъекцией ошибок.
class _FakeRpc implements SupportTeamRpc {
  _FakeRpc(this._view, {this.getError});

  final SupportTeamView _view;

  /// Ошибка первичной загрузки (проверка ветки retry).
  Object? getError;

  int getCalls = 0;
  int addCalls = 0;
  int removeCalls = 0;
  Object? addError;

  @override
  Future<SupportTeamView> getSupportTeam({
    required String productExternalKey,
  }) async {
    getCalls++;
    if (getError != null) throw getError!;
    return _view;
  }

  @override
  Future<SupportTeamView> addMember({
    required String productExternalKey,
    required String email,
    int tier = 1,
  }) async {
    addCalls++;
    if (addError != null) throw addError!;
    return _view;
  }

  @override
  Future<SupportTeamView> removeMember({
    required String productExternalKey,
    required int targetMessengerUserId,
  }) async {
    removeCalls++;
    return _view;
  }

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

  /// **TASK73**: «Покинуть команду». `leaveError` — чтобы проверить, что
  /// отказ «последний владелец» показывается своим текстом.
  int leaveCalls = 0;
  Object? leaveError;

  @override
  Future<void> leaveTeam({required String productExternalKey}) async {
    leaveCalls++;
    if (leaveError != null) throw leaveError!;
  }
}
