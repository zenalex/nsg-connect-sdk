import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **Свои команды пользователя** — этап 3 из
/// `DESIGN_TEAMS_AND_CONTACT_SHARING.md`.
///
/// Команда — это список людей БЕЗ переписки: собрал проектную группу —
/// участники увидели друг друга, и никакого чата для этого заводить не
/// пришлось.
///
/// Главное правило живёт на сервере: добавить в свою команду можно только
/// того, кого добавляющий уже знает (общая комната / общая команда /
/// ручной контакт). Клиент его НЕ повторяет и повторять не должен —
/// клиентская проверка защищает только наш собственный интерфейс, а
/// обойти её ничего не стоит. Здесь мы лишь умеем показать причину
/// отказа: [TeamPeerUnknownException] — не сбой, а «сначала
/// познакомьтесь».
///
/// Сигнатуры вынесены в typedef-ы, чтобы тесты подставляли фейки
/// ([NsgMessengerTeams.withRpcs]) — тот же приём, что у
/// `NsgMessengerBotsAdmin`.
typedef ListMyTeamsRpc = Future<List<TeamView>> Function();
typedef CreateMyTeamRpc =
    Future<TeamView> Function({required String name, String? description});
typedef DeleteMyTeamRpc = Future<void> Function({required int teamId});
typedef ListMyTeamMembersRpc =
    Future<List<TeamMemberView>> Function({required int teamId});
typedef AddMyTeamMemberRpc =
    Future<void> Function({required int teamId, required int messengerUserId});
typedef RemoveMyTeamMemberRpc =
    Future<void> Function({required int teamId, required int messengerUserId});
typedef LeaveMyTeamRpc = Future<void> Function({required int teamId});

class NsgMessengerTeams {
  NsgMessengerTeams._({
    required ListMyTeamsRpc listRpc,
    required CreateMyTeamRpc createRpc,
    required DeleteMyTeamRpc deleteRpc,
    required ListMyTeamMembersRpc membersRpc,
    required AddMyTeamMemberRpc addMemberRpc,
    required RemoveMyTeamMemberRpc removeMemberRpc,
    required LeaveMyTeamRpc leaveRpc,
  }) : _list = listRpc,
       _create = createRpc,
       _delete = deleteRpc,
       _members = membersRpc,
       _addMember = addMemberRpc,
       _removeMember = removeMemberRpc,
       _leave = leaveRpc;

  factory NsgMessengerTeams.attach(Client client) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return NsgMessengerTeams._(
      listRpc: () =>
          withAuthRetry(() => client.messenger.listMyTeams(), session()),
      createRpc: ({required String name, String? description}) => withAuthRetry(
        () =>
            client.messenger.createMyTeam(name: name, description: description),
        session(),
      ),
      deleteRpc: ({required int teamId}) => withAuthRetry(
        () => client.messenger.deleteMyTeam(teamId: teamId),
        session(),
      ),
      membersRpc: ({required int teamId}) => withAuthRetry(
        () => client.messenger.listMyTeamMembers(teamId: teamId),
        session(),
      ),
      addMemberRpc: ({required int teamId, required int messengerUserId}) =>
          withAuthRetry(
            () => client.messenger.addMyTeamMember(
              teamId: teamId,
              messengerUserId: messengerUserId,
            ),
            session(),
          ),
      removeMemberRpc: ({required int teamId, required int messengerUserId}) =>
          withAuthRetry(
            () => client.messenger.removeMyTeamMember(
              teamId: teamId,
              messengerUserId: messengerUserId,
            ),
            session(),
          ),
      leaveRpc: ({required int teamId}) => withAuthRetry(
        () => client.messenger.leaveMyTeam(teamId: teamId),
        session(),
      ),
    );
  }

  /// Конструктор для тестов: подставить фейковые RPC.
  factory NsgMessengerTeams.withRpcs({
    required ListMyTeamsRpc listRpc,
    required CreateMyTeamRpc createRpc,
    required DeleteMyTeamRpc deleteRpc,
    required ListMyTeamMembersRpc membersRpc,
    required AddMyTeamMemberRpc addMemberRpc,
    required RemoveMyTeamMemberRpc removeMemberRpc,
    required LeaveMyTeamRpc leaveRpc,
  }) => NsgMessengerTeams._(
    listRpc: listRpc,
    createRpc: createRpc,
    deleteRpc: deleteRpc,
    membersRpc: membersRpc,
    addMemberRpc: addMemberRpc,
    removeMemberRpc: removeMemberRpc,
    leaveRpc: leaveRpc,
  );

  final ListMyTeamsRpc _list;
  final CreateMyTeamRpc _create;
  final DeleteMyTeamRpc _delete;
  final ListMyTeamMembersRpc _members;
  final AddMyTeamMemberRpc _addMember;
  final RemoveMyTeamMemberRpc _removeMember;
  final LeaveMyTeamRpc _leave;

  /// Команды, в которых я состою: свои и оргкоманды тенанта.
  Future<List<TeamView>> list() => _list();

  /// Завести свою команду. Тёзки разрешены — «Проект» у меня и «Проект» у
  /// коллеги мешать друг другу не должны.
  Future<TeamView> create({required String name, String? description}) =>
      _create(name: name, description: description);

  /// Распустить свою команду. Переписку это не трогает: пропадает
  /// знакомство, а комнаты, сообщения и история остаются.
  Future<void> delete(int teamId) => _delete(teamId: teamId);

  Future<List<TeamMemberView>> members(int teamId) => _members(teamId: teamId);

  Future<void> addMember({required int teamId, required int messengerUserId}) =>
      _addMember(teamId: teamId, messengerUserId: messengerUserId);

  Future<void> removeMember({
    required int teamId,
    required int messengerUserId,
  }) => _removeMember(teamId: teamId, messengerUserId: messengerUserId);

  /// Выйти из команды. Разрешения владельца не требует: согласия при
  /// добавлении не спрашивали.
  Future<void> leave(int teamId) => _leave(teamId: teamId);
}
