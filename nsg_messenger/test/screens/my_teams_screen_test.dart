import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/contacts/nsg_messenger_teams.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/my_teams_screen.dart';

import '../test_helpers.dart';

/// **Свои команды** — экран этапа 3 (`DESIGN_TEAMS_AND_CONTACT_SHARING`).
///
/// Главное, что здесь проверяется, — интерфейс не врёт про права и про
/// причину отказа:
///
///   * попытка добавить незнакомого объясняется («сначала познакомьтесь»),
///     а не показывается как общая ошибка: повторять её бессмысленно, и
///     человек должен понять, что делать;
///   * кнопок, на которые сервер ответит отказом, не рисуем — ни у
///     оргкоманды (её правит админ платформы), ни у чужой команды, ни на
///     владельце (без него командой некому распорядиться).
void main() {
  TeamView team({
    int id = 1,
    String name = 'Проект',
    TeamKind kind = TeamKind.private,
    TeamMemberRole? myRole = TeamMemberRole.owner,
    int memberCount = 2,
    String? description,
  }) => TeamView(
    id: id,
    name: name,
    description: description,
    kind: kind,
    memberCount: memberCount,
    myRole: myRole,
  );

  TeamMemberView member({
    int id = 10,
    String name = 'Аня',
    TeamMemberRole role = TeamMemberRole.member,
  }) => TeamMemberView(messengerUserId: id, displayName: name, role: role);

  /// Фейковый фасад: всё — заглушки, интересное тест переопределяет.
  NsgMessengerTeams fake({
    List<TeamView> teams = const [],
    List<TeamMemberView> members = const [],
    Future<void> Function(int teamId, int userId)? onAdd,
    Future<void> Function(int teamId, int userId)? onRemove,
    Future<void> Function(int teamId)? onLeave,
    Future<void> Function(int teamId)? onDelete,
    Future<TeamView> Function(String name, String? description)? onCreate,
  }) => NsgMessengerTeams.withRpcs(
    listRpc: () async => teams,
    createRpc: ({required String name, String? description}) =>
        onCreate?.call(name, description) ?? Future.value(team(name: name)),
    deleteRpc: ({required int teamId}) =>
        onDelete?.call(teamId) ?? Future.value(),
    membersRpc: ({required int teamId}) async => members,
    addMemberRpc: ({required int teamId, required int messengerUserId}) =>
        onAdd?.call(teamId, messengerUserId) ?? Future.value(),
    removeMemberRpc: ({required int teamId, required int messengerUserId}) =>
        onRemove?.call(teamId, messengerUserId) ?? Future.value(),
    leaveRpc: ({required int teamId}) =>
        onLeave?.call(teamId) ?? Future.value(),
  );

  Widget host(NsgMessengerTeams teams) =>
      wrapL10n(MyTeamsScreen(teams: teams), locale: const Locale('ru'));

  Widget hostMembers(NsgMessengerTeams teams, TeamView t) => wrapL10n(
    TeamMembersScreen(teams: teams, team: t),
    locale: const Locale('ru'),
  );

  // ── главное: отказ объясняет причину ──────────────────────────────

  testWidgets('отказ «незнакомый» объясняет причину, а сбой — нет', (
    tester,
  ) async {
    // Общий текст «не удалось» заставил бы жать кнопку повторно, хотя
    // повторять бессмысленно: надо сначала познакомиться. И наоборот —
    // выдавать настоящий сбой за правило тоже нельзя.
    await tester.pumpWidget(hostMembers(fake(members: [member()]), team()));
    await tester.pumpAndSettle();
    final l = NsgL10n.of(tester.element(find.byType(TeamMembersScreen)));

    expect(
      teamErrorText(l, TeamPeerUnknownException(messengerUserId: 42)),
      contains('Познакомьтесь'),
    );
    expect(
      teamErrorText(l, TeamAccessDeniedException(teamId: 1)),
      contains('владелец'),
    );
    expect(
      teamErrorText(l, StateError('boom')),
      isNot(contains('Познакомьтесь')),
      reason: 'настоящий сбой не выдаём за правило',
    );
  });

  testWidgets('отказ сервера показывается человеку, а не проглатывается', (
    tester,
  ) async {
    // Молчаливый отказ хуже любого текста: человек уверен, что убрал
    // участника, а тот на месте.
    await tester.pumpWidget(
      hostMembers(
        fake(
          members: [member(id: 10, name: 'Аня')],
          onRemove: (_, _) async => throw TeamAccessDeniedException(teamId: 1),
        ),
        team(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('myTeamsRemove_10')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Убрать из команды').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('владелец команды'), findsOneWidget);
  });

  // ── права: кнопок, на которые сервер откажет, не рисуем ───────────

  testWidgets('оргкоманду не распустить и не покинуть', (tester) async {
    // Справочник компании правит админ платформы. Кнопка «выйти» тут
    // означала бы обещание, которого сервер не выполнит.
    await tester.pumpWidget(
      host(
        fake(
          teams: [
            team(id: 7, name: 'Компания', kind: TeamKind.org, myRole: null),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Компания'), findsOneWidget);
    expect(find.textContaining('Команда компании'), findsOneWidget);
    expect(find.byKey(const Key('myTeamsDelete_7')), findsNothing);
    expect(find.byKey(const Key('myTeamsLeave_7')), findsNothing);
  });

  testWidgets('своя команда: у владельца — роспуск, у участника — выход', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        fake(
          teams: [
            team(id: 1, name: 'Моя'),
            team(id: 2, name: 'Чужая', myRole: TeamMemberRole.member),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('myTeamsDelete_1')), findsOneWidget);
    expect(find.byKey(const Key('myTeamsLeave_1')), findsNothing);
    expect(find.byKey(const Key('myTeamsLeave_2')), findsOneWidget);
    expect(
      find.byKey(const Key('myTeamsDelete_2')),
      findsNothing,
      reason: 'чужую команду не распустить',
    );
  });

  testWidgets('выход из чужой команды подтверждается и уходит на сервер', (
    tester,
  ) async {
    int? left;
    await tester.pumpWidget(
      host(
        fake(
          teams: [team(id: 2, name: 'Чужая', myRole: TeamMemberRole.member)],
          onLeave: (id) async => left = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('myTeamsLeave_2')));
    await tester.pumpAndSettle();
    // Подтверждение обязано называть последствие: пропадут люди.
    expect(find.textContaining('пропадут из вашего списка'), findsOneWidget);
    await tester.tap(find.text('Выйти из команды').last);
    await tester.pumpAndSettle();
    expect(left, 2);
  });

  testWidgets('состав: участнику правки не предлагают', (tester) async {
    final t = team(id: 1, myRole: TeamMemberRole.member);
    await tester.pumpWidget(
      hostMembers(fake(members: [member(id: 10, name: 'Аня')]), t),
    );
    await tester.pumpAndSettle();

    expect(find.text('Аня'), findsOneWidget);
    expect(find.byKey(const Key('myTeamsAddMemberButton')), findsNothing);
    expect(find.byKey(const Key('myTeamsRemove_10')), findsNothing);
  });

  testWidgets('состав: владельца из команды убрать нельзя', (tester) async {
    // Иначе командой стало бы некому ни распорядиться, ни распустить её.
    await tester.pumpWidget(
      hostMembers(
        fake(
          members: [
            member(id: 5, name: 'Я', role: TeamMemberRole.owner),
            member(id: 10, name: 'Аня'),
          ],
        ),
        team(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('myTeamsAddMemberButton')), findsOneWidget);
    expect(find.byKey(const Key('myTeamsRemove_10')), findsOneWidget);
    expect(find.byKey(const Key('myTeamsRemove_5')), findsNothing);
  });

  testWidgets('состав предупреждает о взаимной видимости ДО добавления', (
    tester,
  ) async {
    // Членство взаимно, и человек должен понимать это заранее, а не
    // обнаружить постфактум.
    await tester.pumpWidget(hostMembers(fake(members: [member()]), team()));
    await tester.pumpAndSettle();
    expect(find.textContaining('увидит весь состав'), findsOneWidget);
  });

  testWidgets('убрать участника: подтверждение объясняет последствие', (
    tester,
  ) async {
    (int, int)? removed;
    await tester.pumpWidget(
      hostMembers(
        fake(
          members: [member(id: 10, name: 'Аня')],
          onRemove: (t, u) async => removed = (t, u),
        ),
        team(id: 3),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('myTeamsRemove_10')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('если не знаком с ними по другой причине'),
      findsOneWidget,
      reason: 'иначе «убрал, а он не пропал» читается как баг',
    );
    await tester.tap(find.text('Убрать из команды').last);
    await tester.pumpAndSettle();
    expect(removed, (3, 10));
  });

  // ── создание ──────────────────────────────────────────────────────

  testWidgets('создание команды отправляет введённое имя', (tester) async {
    String? created;
    await tester.pumpWidget(
      host(
        fake(
          onCreate: (name, _) async {
            created = name;
            return team(name: name);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Команд пока нет'), findsOneWidget);
    await tester.tap(find.byKey(const Key('myTeamsCreateButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('myTeamsNameField')),
      'Ремонт офиса',
    );
    await tester.tap(find.byKey(const Key('myTeamsCreateConfirm')));
    await tester.pumpAndSettle();
    expect(created, 'Ремонт офиса');
  });

  testWidgets('подсказка называет правило «только знакомых»', (tester) async {
    // Без неё «почему нельзя добавить» выясняется только отказом.
    await tester.pumpWidget(host(fake()));
    await tester.pumpAndSettle();
    expect(find.textContaining('кого вы уже знаете'), findsOneWidget);
  });
}
