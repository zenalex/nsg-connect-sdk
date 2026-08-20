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

  /// Добавить оператора ВЫБОРОМ из списка людей (email — для внешних).
  Future<SupportTeamView> addMemberById({
    required String productExternalKey,
    required int messengerUserId,
    int tier,
  });

  /// **TASK76**: сменить роль участника `owner` ↔ `member` (owner-only,
  /// назначение других админов). Обновлённый view.
  Future<SupportTeamView> setMemberRole({
    required String productExternalKey,
    required int targetMessengerUserId,
    required SupportTeamRole role,
  });

  /// **TASK73**: выйти из команды самому. Owner-ом быть не нужно. View не
  /// возвращается — после выхода caller уже не участник. Throws
  /// [LastOwnerCannotDemoteException] (последний владелец: сперва назначьте
  /// другого администратора) / [NotSupportTeamMemberException].
  Future<void> leaveTeam({required String productExternalKey});
}

/// Продакшн-реализация: ходит в generated Serverpod-client через
/// `withAuthRetry` (self-heal на token-rotation, как в остальном SDK).
class ClientSupportTeamRpc implements SupportTeamRpc {
  /// [tenantExternalKey] — тенант продукта. Нужен, когда команда живёт в
  /// ЧУЖОМ тенанте (платформенная админка смотрит продукт заказчика):
  /// ключ продукта уникален только внутри тенанта, и без тенанта сервер
  /// не может отличить `titan112_operator` в `titan` от такого же ключа в
  /// `titan112` — на проде это отдавало состав чужой команды. Живёт в
  /// конструкторе, а не в каждом методе: на всё время экрана тенант один.
  ClientSupportTeamRpc(this._client, {String? tenantExternalKey})
    : _tenantExternalKey = tenantExternalKey;

  final Client _client;
  final String? _tenantExternalKey;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<SupportTeamView> getSupportTeam({
    required String productExternalKey,
  }) => withAuthRetry(
    () => _client.messenger.getSupportTeam(
      productExternalKey: productExternalKey,
      tenantExternalKey: _tenantExternalKey,
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
      tenantExternalKey: _tenantExternalKey,
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
      tenantExternalKey: _tenantExternalKey,
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
      tenantExternalKey: _tenantExternalKey,
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
      tenantExternalKey: _tenantExternalKey,
    ),
    _session,
  );

  @override
  @override
  Future<SupportTeamView> addMemberById({
    required String productExternalKey,
    required int messengerUserId,
    int tier = 1,
  }) => withAuthRetry(
    () => _client.messenger.addSupportTeamMemberById(
      productExternalKey: productExternalKey,
      messengerUserId: messengerUserId,
      tier: tier,
    ),
    MessengerRuntime.instance.sessionManager,
  );

  @override
  Future<SupportTeamView> createTeam({required String productExternalKey}) =>
      withAuthRetry(
        // Self-service создание команды — всегда в СВОЁМ тенанте, поэтому
        // тенант здесь не передаётся (и серверный метод его не принимает).
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
      tenantExternalKey: _tenantExternalKey,
    ),
    _session,
  );

  @override
  Future<void> leaveTeam({required String productExternalKey}) => withAuthRetry(
    () => _client.messenger.leaveSupportTeam(
      productExternalKey: productExternalKey,
      tenantExternalKey: _tenantExternalKey,
    ),
    _session,
  );
}
