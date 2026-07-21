import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK43**: RPC-абстракция экрана «Команда поддержки». Отдельный
/// интерфейс (а не прямой вызов client) — чтобы `SupportTeamController`
/// был unit-тестируем с hand-written fake (как `NsgMessengerRooms`).
abstract class SupportTeamRpc {
  /// Состав команды продукта. Бросает [NotSupportTeamMemberException],
  /// если caller не участник (SDK по этому гейтит доступ к экрану).
  Future<SupportTeamView> getSupportTeam({required String productExternalKey});

  /// Добавить оператора по email (owner-only). **TASK48**: [tier] — уровень
  /// (1 = фронт-линия, 2 = эскалация). Возвращает обновлённый view.
  Future<SupportTeamView> addMember({
    required String productExternalKey,
    required String email,
    int tier = 1,
  });

  /// Убрать оператора по messengerUserId (owner-only). Обновлённый view.
  Future<SupportTeamView> removeMember({
    required String productExternalKey,
    required int targetMessengerUserId,
  });

  /// **TASK48**: сменить тир участника (owner-only). Обновлённый view.
  Future<SupportTeamView> setMemberTier({
    required String productExternalKey,
    required int targetMessengerUserId,
    required int tier,
  });

  /// **TASK48 iter2**: порог авто-эскалации в минутах (owner-only).
  /// Обновлённый view.
  Future<SupportTeamView> setTimeout({
    required String productExternalKey,
    required int minutes,
  });

  /// **TASK76**: создать команду поддержки продукта — создатель становится
  /// owner («создатель канала = админ»). Идемпотентно для участника
  /// существующей команды. Throws [ProductNotFoundForCallerException] /
  /// [NotSupportTeamMemberException] (команда чужая).
  Future<SupportTeamView> createTeam({required String productExternalKey});

  /// **TASK76**: сменить роль участника `owner` ↔ `member` (owner-only,
  /// назначение других админов). Обновлённый view.
  Future<SupportTeamView> setMemberRole({
    required String productExternalKey,
    required int targetMessengerUserId,
    required SupportTeamRole role,
  });
}

/// Продакшн-реализация: ходит в generated Serverpod-client через
/// `withAuthRetry` (self-heal на token-rotation, как в остальном SDK).
class ClientSupportTeamRpc implements SupportTeamRpc {
  ClientSupportTeamRpc(this._client);

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<SupportTeamView> getSupportTeam({
    required String productExternalKey,
  }) => withAuthRetry(
    () => _client.messenger.getSupportTeam(
      productExternalKey: productExternalKey,
    ),
    _session,
  );

  @override
  Future<SupportTeamView> addMember({
    required String productExternalKey,
    required String email,
    int tier = 1,
  }) => withAuthRetry(
    () => _client.messenger.addSupportTeamMember(
      productExternalKey: productExternalKey,
      email: email,
      tier: tier,
    ),
    _session,
  );

  @override
  Future<SupportTeamView> removeMember({
    required String productExternalKey,
    required int targetMessengerUserId,
  }) => withAuthRetry(
    () => _client.messenger.removeSupportTeamMember(
      productExternalKey: productExternalKey,
      targetMessengerUserId: targetMessengerUserId,
    ),
    _session,
  );

  @override
  Future<SupportTeamView> setMemberTier({
    required String productExternalKey,
    required int targetMessengerUserId,
    required int tier,
  }) => withAuthRetry(
    () => _client.messenger.setSupportTeamMemberTier(
      productExternalKey: productExternalKey,
      targetMessengerUserId: targetMessengerUserId,
      tier: tier,
    ),
    _session,
  );

  @override
  Future<SupportTeamView> setTimeout({
    required String productExternalKey,
    required int minutes,
  }) => withAuthRetry(
    () => _client.messenger.setSupportTeamTimeout(
      productExternalKey: productExternalKey,
      minutes: minutes,
    ),
    _session,
  );

  @override
  Future<SupportTeamView> createTeam({
    required String productExternalKey,
  }) => withAuthRetry(
    () => _client.messenger.createSupportTeam(
      productExternalKey: productExternalKey,
    ),
    _session,
  );

  @override
  Future<SupportTeamView> setMemberRole({
    required String productExternalKey,
    required int targetMessengerUserId,
    required SupportTeamRole role,
  }) => withAuthRetry(
    () => _client.messenger.setSupportTeamMemberRole(
      productExternalKey: productExternalKey,
      targetMessengerUserId: targetMessengerUserId,
      role: role,
    ),
    _session,
  );
}
