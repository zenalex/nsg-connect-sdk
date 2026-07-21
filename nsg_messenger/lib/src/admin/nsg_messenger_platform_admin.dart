import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK78 п.3 (админка секретов тенантов)**: публичный API платформенной
/// админки — управление issued-token-режимом tenant-ов: включение,
/// генерация/ротация/отзыв serviceSecret, статусы, аудит. Доступен через
/// `NsgMessenger.platformAdmin`; используется `PlatformAdminScreen`.
///
/// Гейт — серверный: каждый метод `client.connectTenantAdmin.*` требует,
/// чтобы email caller-а был в env `PLATFORM_ADMIN_EMAILS`. [isPlatformAdmin]
/// нужен только чтобы НЕ показывать пункт меню тому, кому все методы всё
/// равно откажут — это UX, а не авторизация (её решает сервер).
///
/// **Секрет** из [enableAndGenerate]/[rotateSecret] возвращается сервером
/// РОВНО ОДИН РАЗ (в БД только sha256) — обвязка его не хранит и не
/// логирует, только пробрасывает вызывающему на разовый показ.
///
/// Тонкая обёртка над сгенерированными Serverpod-эндпоинтами; каждый RPC
/// под [withAuthRetry] (self-heal на серверный auth-invalidation) — тот же
/// приём, что в [NsgMessengerBotsAdmin]. Сигнатуры вынесены в typedef-ы для
/// инъекции fake-ов в тестах ([NsgMessengerPlatformAdmin.withRpcs]).
typedef IsPlatformAdminRpc = Future<bool> Function();
typedef ListTenantsRpc = Future<List<ConnectTenantStatus>> Function();
typedef EnableAndGenerateRpc =
    Future<String> Function({required String tenantExternalKey});
typedef RotateTenantSecretRpc =
    Future<String> Function({
      required String tenantExternalKey,
      int? graceSeconds,
    });
typedef DisableTenantRpc =
    Future<void> Function({required String tenantExternalKey});
typedef TenantStatusRpc =
    Future<ConnectTenantStatus> Function({required String tenantExternalKey});
typedef ListTenantAuditEventsRpc =
    Future<List<ConnectKeyAuditEvent>> Function({
      required String tenantExternalKey,
      required int limit,
    });

class NsgMessengerPlatformAdmin {
  NsgMessengerPlatformAdmin._({
    required IsPlatformAdminRpc isPlatformAdminRpc,
    required ListTenantsRpc listTenantsRpc,
    required EnableAndGenerateRpc enableAndGenerateRpc,
    required RotateTenantSecretRpc rotateSecretRpc,
    required DisableTenantRpc disableRpc,
    required TenantStatusRpc statusRpc,
    required ListTenantAuditEventsRpc listAuditEventsRpc,
  }) : _isPlatformAdminRpc = isPlatformAdminRpc,
       _listTenantsRpc = listTenantsRpc,
       _enableAndGenerateRpc = enableAndGenerateRpc,
       _rotateSecretRpc = rotateSecretRpc,
       _disableRpc = disableRpc,
       _statusRpc = statusRpc,
       _listAuditEventsRpc = listAuditEventsRpc;

  final IsPlatformAdminRpc _isPlatformAdminRpc;
  final ListTenantsRpc _listTenantsRpc;
  final EnableAndGenerateRpc _enableAndGenerateRpc;
  final RotateTenantSecretRpc _rotateSecretRpc;
  final DisableTenantRpc _disableRpc;
  final TenantStatusRpc _statusRpc;
  final ListTenantAuditEventsRpc _listAuditEventsRpc;

  /// Дефолтный grace ротации, минуты (= серверный
  /// `ConnectTenantAdminService.defaultRotationGrace`).
  static const int kDefaultGraceMinutes = 5;

  /// Потолок grace, минуты (24 часа) — сервер всё равно обрежет сверху
  /// (`maxRotationGrace`), клиентская константа только для валидации формы.
  static const int kMaxGraceMinutes = 1440;

  /// Production-фабрика: привязка к `client.connectTenantAdmin.*`, каждый
  /// под [withAuthRetry]. `session()` резолвит session-manager лениво из
  /// runtime (closures выполняются после `init()`).
  static NsgMessengerPlatformAdmin attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return withRpcs(
      isPlatformAdminRpc: () => withAuthRetry(
        () => client.connectTenantAdmin.isPlatformAdmin(),
        session(),
      ),
      listTenantsRpc: () => withAuthRetry(
        () => client.connectTenantAdmin.listTenants(),
        session(),
      ),
      enableAndGenerateRpc: ({required String tenantExternalKey}) =>
          withAuthRetry(
            () => client.connectTenantAdmin.enableAndGenerate(
              tenantExternalKey: tenantExternalKey,
            ),
            session(),
          ),
      rotateSecretRpc:
          ({required String tenantExternalKey, int? graceSeconds}) =>
              withAuthRetry(
                () => client.connectTenantAdmin.rotateSecret(
                  tenantExternalKey: tenantExternalKey,
                  graceSeconds: graceSeconds,
                ),
                session(),
              ),
      disableRpc: ({required String tenantExternalKey}) => withAuthRetry(
        () => client.connectTenantAdmin.disable(
          tenantExternalKey: tenantExternalKey,
        ),
        session(),
      ),
      statusRpc: ({required String tenantExternalKey}) => withAuthRetry(
        () => client.connectTenantAdmin.status(
          tenantExternalKey: tenantExternalKey,
        ),
        session(),
      ),
      listAuditEventsRpc:
          ({required String tenantExternalKey, required int limit}) =>
              withAuthRetry(
                () => client.connectTenantAdmin.listAuditEvents(
                  tenantExternalKey: tenantExternalKey,
                  limit: limit,
                ),
                session(),
              ),
    );
  }

  /// Test-фабрика: инъекция fake-RPC (без Serverpod-клиента / runtime).
  static NsgMessengerPlatformAdmin withRpcs({
    required IsPlatformAdminRpc isPlatformAdminRpc,
    required ListTenantsRpc listTenantsRpc,
    required EnableAndGenerateRpc enableAndGenerateRpc,
    required RotateTenantSecretRpc rotateSecretRpc,
    required DisableTenantRpc disableRpc,
    required TenantStatusRpc statusRpc,
    required ListTenantAuditEventsRpc listAuditEventsRpc,
  }) => NsgMessengerPlatformAdmin._(
    isPlatformAdminRpc: isPlatformAdminRpc,
    listTenantsRpc: listTenantsRpc,
    enableAndGenerateRpc: enableAndGenerateRpc,
    rotateSecretRpc: rotateSecretRpc,
    disableRpc: disableRpc,
    statusRpc: statusRpc,
    listAuditEventsRpc: listAuditEventsRpc,
  );

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Доступна ли caller-у платформенная админка (email в
  /// `PLATFORM_ADMIN_EMAILS`). Только для скрытия пункта меню —
  /// авторизацию решает сервер на каждом методе. Ошибку не бросает:
  /// старый сервер без RPC / сбой сети → `false` (недоступность админки —
  /// норма для 99% пользователей, не ошибка экрана).
  Future<bool> isPlatformAdmin() async {
    try {
      return await _isPlatformAdminRpc();
    } catch (_) {
      return false;
    }
  }

  /// Статусы issued-token-режима всех tenant-ов (без секретов). На старом
  /// сервере (RPC ещё нет) или при сбое — пусто, не исключение: экран
  /// показывает пустое состояние вместо краша, деградация как у
  /// [NsgMessengerBotsAdmin.listBotRoomIds].
  Future<List<ConnectTenantStatus>> listTenants() async {
    try {
      return await _listTenantsRpc();
    } on Object {
      return const <ConnectTenantStatus>[];
    }
  }

  /// Включить issued-token-режим tenant-а и выдать первый serviceSecret.
  /// Возвращённый плейнтекст `cst_…` — **показать один раз** и забыть:
  /// сервер хранит только sha256, повторно не отдаст. На уже включённом
  /// tenant-е сервер делает ротацию (живой секрет не затирается без grace).
  /// Ошибки НЕ глотаются — молча потерять результат генерации секрета
  /// хуже, чем показать ошибку.
  Future<String> enableAndGenerate({required String tenantExternalKey}) =>
      _enableAndGenerateRpc(tenantExternalKey: tenantExternalKey);

  /// Ротация без простоя: старый секрет живёт ещё [graceMinutes] (дефолт
  /// [kDefaultGraceMinutes], сервер обрежет всё сверх [kMaxGraceMinutes]).
  /// Возвращённый новый плейнтекст — **показать один раз**.
  Future<String> rotateSecret({
    required String tenantExternalKey,
    int graceMinutes = kDefaultGraceMinutes,
  }) => _rotateSecretRpc(
    tenantExternalKey: tenantExternalKey,
    graceSeconds: graceMinutes * 60,
  );

  /// Kill-switch: снимает флаг и обнуляет ОБА хэша (текущий и grace) —
  /// продукт теряет выдачу токенов со следующего запроса.
  Future<void> disable({required String tenantExternalKey}) =>
      _disableRpc(tenantExternalKey: tenantExternalKey);

  /// Статус одного tenant-а (включён / секрет задан / grace до N).
  Future<ConnectTenantStatus> status({required String tenantExternalKey}) =>
      _statusRpc(tenantExternalKey: tenantExternalKey);

  /// Журнал операций с ключами tenant-а, свежие сверху. Секретов не
  /// содержит по контракту сервера.
  Future<List<ConnectKeyAuditEvent>> listAuditEvents({
    required String tenantExternalKey,
    int limit = 50,
  }) => _listAuditEventsRpc(tenantExternalKey: tenantExternalKey, limit: limit);
}
