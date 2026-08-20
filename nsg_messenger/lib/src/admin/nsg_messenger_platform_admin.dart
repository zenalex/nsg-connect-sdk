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

/// Завести tenant (провижн без доступа к прод-базе).
typedef CreateTenantRpc =
    Future<ConnectTenantStatus> Function({
      required String externalKey,
      required String name,
    });

/// Продукты тенанта (второй уровень дерева «тенант → продукт → команда»).
typedef ListProductsRpc =
    Future<List<ProductAdminView>> Function({
      required String tenantExternalKey,
    });

/// Завести команду поддержки продукта и назначить владельца по email.
typedef ProvisionSupportTeamRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required String productExternalKey,
      String? ownerEmail,
      int? ownerMessengerUserId,
    });

/// Завести продукт внутри tenant-а.
typedef CreateProductRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required String externalKey,
      required String displayName,
    });

/// Удалить продукт (только пустой — гейт на сервере).
typedef DeleteProductRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required String productExternalKey,
    });

/// Список поддержки тенанта — люди, наследуемые в команды всех его
/// продуктов.
typedef ListTenantSupportRpc =
    Future<List<TenantSupportMemberView>> Function({
      required String tenantExternalKey,
    });
typedef AddTenantSupportRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required int messengerUserId,
      int? tier,
    });
typedef RemoveTenantSupportRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required int messengerUserId,
    });
typedef ListTenantsRpc = Future<List<ConnectTenantStatus>> Function();

/// **issue #120**: здоровье доставки уведомлений по продуктам.
typedef ListDeliveryHealthRpc =
    Future<List<ProductDeliveryHealth>> Function();
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

// ── оргкоманды тенанта (этап 2 DESIGN_TEAMS_AND_CONTACT_SHARING) ──────
// Справочник компании: положили новичка в «Компанию» — он видит коллег,
// не зная ни одного email. Здесь, за платформенным гейтом, потому что
// право положить человека в команду равно праву раздавать знакомства.
typedef ListTeamsRpc =
    Future<List<TeamView>> Function({required String tenantExternalKey});
typedef CreateTeamRpc =
    Future<TeamView> Function({
      required String tenantExternalKey,
      required String name,
      String? description,
    });
typedef DeleteTeamRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required int teamId,
    });
typedef ListTeamMembersRpc =
    Future<List<TeamMemberView>> Function({
      required String tenantExternalKey,
      required int teamId,
    });
typedef AddTeamMemberRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required int teamId,
      required int messengerUserId,
    });
typedef RemoveTeamMemberRpc =
    Future<void> Function({
      required String tenantExternalKey,
      required int teamId,
      required int messengerUserId,
    });

class NsgMessengerPlatformAdmin {
  NsgMessengerPlatformAdmin._({
    required IsPlatformAdminRpc isPlatformAdminRpc,
    required ListTenantsRpc listTenantsRpc,
    required ListDeliveryHealthRpc listDeliveryHealthRpc,
    required CreateTenantRpc createTenantRpc,
    required CreateProductRpc createProductRpc,
    required DeleteProductRpc deleteProductRpc,
    required ListTenantSupportRpc listTenantSupportRpc,
    required AddTenantSupportRpc addTenantSupportRpc,
    required RemoveTenantSupportRpc removeTenantSupportRpc,
    required ListProductsRpc listProductsRpc,
    required ProvisionSupportTeamRpc provisionSupportTeamRpc,
    required EnableAndGenerateRpc enableAndGenerateRpc,
    required RotateTenantSecretRpc rotateSecretRpc,
    required DisableTenantRpc disableRpc,
    required TenantStatusRpc statusRpc,
    required ListTenantAuditEventsRpc listAuditEventsRpc,
    required ListTeamsRpc listTeamsRpc,
    required CreateTeamRpc createTeamRpc,
    required DeleteTeamRpc deleteTeamRpc,
    required ListTeamMembersRpc listTeamMembersRpc,
    required AddTeamMemberRpc addTeamMemberRpc,
    required RemoveTeamMemberRpc removeTeamMemberRpc,
  }) : _listProductsRpc = listProductsRpc,
       _listTeamsRpc = listTeamsRpc,
       _createTeamRpc = createTeamRpc,
       _deleteTeamRpc = deleteTeamRpc,
       _listTeamMembersRpc = listTeamMembersRpc,
       _addTeamMemberRpc = addTeamMemberRpc,
       _removeTeamMemberRpc = removeTeamMemberRpc,
       _provisionSupportTeamRpc = provisionSupportTeamRpc,
       _createTenantRpc = createTenantRpc,
       _createProductRpc = createProductRpc,
       _deleteProductRpc = deleteProductRpc,
       _listTenantSupportRpc = listTenantSupportRpc,
       _addTenantSupportRpc = addTenantSupportRpc,
       _removeTenantSupportRpc = removeTenantSupportRpc,
       _isPlatformAdminRpc = isPlatformAdminRpc,
       _listTenantsRpc = listTenantsRpc,
       _listDeliveryHealthRpc = listDeliveryHealthRpc,
       _enableAndGenerateRpc = enableAndGenerateRpc,
       _rotateSecretRpc = rotateSecretRpc,
       _disableRpc = disableRpc,
       _statusRpc = statusRpc,
       _listAuditEventsRpc = listAuditEventsRpc;

  final IsPlatformAdminRpc _isPlatformAdminRpc;
  final ListTenantsRpc _listTenantsRpc;
  final ListDeliveryHealthRpc _listDeliveryHealthRpc;
  final CreateTenantRpc _createTenantRpc;
  final ListProductsRpc _listProductsRpc;
  final ProvisionSupportTeamRpc _provisionSupportTeamRpc;
  final CreateProductRpc _createProductRpc;
  final DeleteProductRpc _deleteProductRpc;
  final ListTeamsRpc _listTeamsRpc;
  final CreateTeamRpc _createTeamRpc;
  final DeleteTeamRpc _deleteTeamRpc;
  final ListTeamMembersRpc _listTeamMembersRpc;
  final AddTeamMemberRpc _addTeamMemberRpc;
  final RemoveTeamMemberRpc _removeTeamMemberRpc;
  final ListTenantSupportRpc _listTenantSupportRpc;
  final AddTenantSupportRpc _addTenantSupportRpc;
  final RemoveTenantSupportRpc _removeTenantSupportRpc;
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
      listDeliveryHealthRpc: () => withAuthRetry(
        () => client.connectTenantAdmin.listDeliveryHealth(),
        session(),
      ),
      listProductsRpc: ({required String tenantExternalKey}) => withAuthRetry(
        () => client.connectTenantAdmin.listProducts(
          tenantExternalKey: tenantExternalKey,
        ),
        session(),
      ),
      provisionSupportTeamRpc:
          ({
            required String tenantExternalKey,
            required String productExternalKey,
            String? ownerEmail,
            int? ownerMessengerUserId,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.provisionSupportTeam(
              tenantExternalKey: tenantExternalKey,
              productExternalKey: productExternalKey,
              ownerEmail: ownerEmail,
              ownerMessengerUserId: ownerMessengerUserId,
            ),
            session(),
          ),
      createTenantRpc: ({required String externalKey, required String name}) =>
          withAuthRetry(
            () => client.connectTenantAdmin.createTenant(
              externalKey: externalKey,
              name: name,
            ),
            session(),
          ),
      createProductRpc:
          ({
            required String tenantExternalKey,
            required String externalKey,
            required String displayName,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.createProduct(
              tenantExternalKey: tenantExternalKey,
              externalKey: externalKey,
              displayName: displayName,
            ),
            session(),
          ),
      deleteProductRpc:
          ({
            required String tenantExternalKey,
            required String productExternalKey,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.deleteProduct(
              tenantExternalKey: tenantExternalKey,
              productExternalKey: productExternalKey,
            ),
            session(),
          ),
      listTenantSupportRpc: ({required String tenantExternalKey}) =>
          withAuthRetry(
            () => client.connectTenantAdmin.listTenantSupport(
              tenantExternalKey: tenantExternalKey,
            ),
            session(),
          ),
      addTenantSupportRpc:
          ({
            required String tenantExternalKey,
            required int messengerUserId,
            int? tier,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.addTenantSupportMember(
              tenantExternalKey: tenantExternalKey,
              messengerUserId: messengerUserId,
              tier: tier,
            ),
            session(),
          ),
      removeTenantSupportRpc:
          ({required String tenantExternalKey, required int messengerUserId}) =>
              withAuthRetry(
                () => client.connectTenantAdmin.removeTenantSupportMember(
                  tenantExternalKey: tenantExternalKey,
                  messengerUserId: messengerUserId,
                ),
                session(),
              ),
      listTeamsRpc: ({required String tenantExternalKey}) => withAuthRetry(
        () => client.connectTenantAdmin.listTeams(
          tenantExternalKey: tenantExternalKey,
        ),
        session(),
      ),
      createTeamRpc:
          ({
            required String tenantExternalKey,
            required String name,
            String? description,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.createTeam(
              tenantExternalKey: tenantExternalKey,
              name: name,
              description: description,
            ),
            session(),
          ),
      deleteTeamRpc:
          ({required String tenantExternalKey, required int teamId}) =>
              withAuthRetry(
                () => client.connectTenantAdmin.deleteTeam(
                  tenantExternalKey: tenantExternalKey,
                  teamId: teamId,
                ),
                session(),
              ),
      listTeamMembersRpc:
          ({required String tenantExternalKey, required int teamId}) =>
              withAuthRetry(
                () => client.connectTenantAdmin.listTeamMembers(
                  tenantExternalKey: tenantExternalKey,
                  teamId: teamId,
                ),
                session(),
              ),
      addTeamMemberRpc:
          ({
            required String tenantExternalKey,
            required int teamId,
            required int messengerUserId,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.addTeamMember(
              tenantExternalKey: tenantExternalKey,
              teamId: teamId,
              messengerUserId: messengerUserId,
            ),
            session(),
          ),
      removeTeamMemberRpc:
          ({
            required String tenantExternalKey,
            required int teamId,
            required int messengerUserId,
          }) => withAuthRetry(
            () => client.connectTenantAdmin.removeTeamMember(
              tenantExternalKey: tenantExternalKey,
              teamId: teamId,
              messengerUserId: messengerUserId,
            ),
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
    required ListDeliveryHealthRpc listDeliveryHealthRpc,
    // Необязательные: тест, который провижн не трогает, объявлять их не
    // должен, а уже выпущенные наружу вызовы `withRpcs` обязаны
    // компилироваться после обновления SDK.
    CreateTenantRpc? createTenantRpc,
    CreateProductRpc? createProductRpc,
    DeleteProductRpc? deleteProductRpc,
    ListTenantSupportRpc? listTenantSupportRpc,
    AddTenantSupportRpc? addTenantSupportRpc,
    RemoveTenantSupportRpc? removeTenantSupportRpc,
    ListProductsRpc? listProductsRpc,
    ProvisionSupportTeamRpc? provisionSupportTeamRpc,
    ListTeamsRpc? listTeamsRpc,
    CreateTeamRpc? createTeamRpc,
    DeleteTeamRpc? deleteTeamRpc,
    ListTeamMembersRpc? listTeamMembersRpc,
    AddTeamMemberRpc? addTeamMemberRpc,
    RemoveTeamMemberRpc? removeTeamMemberRpc,
    required EnableAndGenerateRpc enableAndGenerateRpc,
    required RotateTenantSecretRpc rotateSecretRpc,
    required DisableTenantRpc disableRpc,
    required TenantStatusRpc statusRpc,
    required ListTenantAuditEventsRpc listAuditEventsRpc,
  }) => NsgMessengerPlatformAdmin._(
    isPlatformAdminRpc: isPlatformAdminRpc,
    listTenantsRpc: listTenantsRpc,
    listDeliveryHealthRpc: listDeliveryHealthRpc,
    createTenantRpc:
        createTenantRpc ??
        ({required String externalKey, required String name}) =>
            throw UnimplementedError('createTenantRpc не задан'),
    createProductRpc:
        createProductRpc ??
        ({
          required String tenantExternalKey,
          required String externalKey,
          required String displayName,
        }) => throw UnimplementedError('createProductRpc не задан'),
    deleteProductRpc:
        deleteProductRpc ??
        ({
          required String tenantExternalKey,
          required String productExternalKey,
        }) => throw UnimplementedError('deleteProductRpc не задан'),
    listTenantSupportRpc:
        listTenantSupportRpc ??
        ({required String tenantExternalKey}) async =>
            const <TenantSupportMemberView>[],
    addTenantSupportRpc:
        addTenantSupportRpc ??
        ({
          required String tenantExternalKey,
          required int messengerUserId,
          int? tier,
        }) => throw UnimplementedError('addTenantSupportRpc не задан'),
    removeTenantSupportRpc:
        removeTenantSupportRpc ??
        ({required String tenantExternalKey, required int messengerUserId}) =>
            throw UnimplementedError('removeTenantSupportRpc не задан'),
    listProductsRpc:
        listProductsRpc ??
        ({required String tenantExternalKey}) async =>
            const <ProductAdminView>[],
    provisionSupportTeamRpc:
        provisionSupportTeamRpc ??
        ({
          required String tenantExternalKey,
          required String productExternalKey,
          String? ownerEmail,
          int? ownerMessengerUserId,
        }) => throw UnimplementedError('provisionSupportTeamRpc не задан'),
    listTeamsRpc:
        listTeamsRpc ??
        ({required String tenantExternalKey}) async => const <TeamView>[],
    createTeamRpc:
        createTeamRpc ??
        ({
          required String tenantExternalKey,
          required String name,
          String? description,
        }) => throw UnimplementedError('createTeamRpc не задан'),
    deleteTeamRpc:
        deleteTeamRpc ??
        ({required String tenantExternalKey, required int teamId}) =>
            throw UnimplementedError('deleteTeamRpc не задан'),
    listTeamMembersRpc:
        listTeamMembersRpc ??
        ({required String tenantExternalKey, required int teamId}) async =>
            const <TeamMemberView>[],
    addTeamMemberRpc:
        addTeamMemberRpc ??
        ({
          required String tenantExternalKey,
          required int teamId,
          required int messengerUserId,
        }) => throw UnimplementedError('addTeamMemberRpc не задан'),
    removeTeamMemberRpc:
        removeTeamMemberRpc ??
        ({
          required String tenantExternalKey,
          required int teamId,
          required int messengerUserId,
        }) => throw UnimplementedError('removeTeamMemberRpc не задан'),
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

  /// **issue #120**: здоровье доставки уведомлений по продуктам.
  ///
  /// Деградация та же, что у [listTenants]: старый сервер или сбой — пусто,
  /// а не исключение. Пустой список экран покажет как «нет данных»; врать
  /// зелёным на сбое запроса нельзя, признак ради того и заводится.
  Future<List<ProductDeliveryHealth>> listDeliveryHealth() async {
    try {
      return await _listDeliveryHealthRpc();
    } on Object {
      return const <ProductDeliveryHealth>[];
    }
  }

  /// Включить issued-token-режим tenant-а и выдать первый serviceSecret.
  /// Возвращённый плейнтекст `cst_…` — **показать один раз** и забыть:
  /// сервер хранит только sha256, повторно не отдаст. На уже включённом
  /// tenant-е сервер делает ротацию (живой секрет не затирается без grace).
  /// Ошибки НЕ глотаются — молча потерять результат генерации секрета
  /// хуже, чем показать ошибку.
  /// Завести tenant. До этого tenant-ы создавались только SQL-ом на
  /// проде — «Платформа» умела лишь включать issued-token у уже
  /// существующего. Возвращает статус нового tenant-а (issued-token у него
  /// ВЫКЛЮЧЕН: создание и включение — разные шаги).
  Future<ConnectTenantStatus> createTenant({
    required String externalKey,
    required String name,
  }) => _createTenantRpc(externalKey: externalKey, name: name);

  /// Завести продукт внутри tenant-а. Его `externalKey` — тот самый
  /// `productExternalKey`, который клиент шлёт в `MessengerAuthContext`.
  Future<void> createProduct({
    required String tenantExternalKey,
    required String externalKey,
    required String displayName,
  }) => _createProductRpc(
    tenantExternalKey: tenantExternalKey,
    externalKey: externalKey,
    displayName: displayName,
  );

  /// **Удалить продукт.** Бросает `ProductInUseException`, если на продукте
  /// есть живое (комнаты, обращения, боты, идентичности, устройства,
  /// вебхуки): ссылки на продукт стоят как `SET NULL`, и молчаливое
  /// удаление осиротило бы переписку, а не убрало её.
  Future<void> deleteProduct({
    required String tenantExternalKey,
    required String productExternalKey,
  }) => _deleteProductRpc(
    tenantExternalKey: tenantExternalKey,
    productExternalKey: productExternalKey,
  );

  /// **Поддержка тенанта** — люди, которые числятся в команде каждого его
  /// продукта. Сбой деградирует в пустой список: экран покажет «никого»,
  /// а доступ всё равно решает сервер.
  Future<List<TenantSupportMemberView>> listTenantSupport({
    required String tenantExternalKey,
  }) async {
    try {
      return await _listTenantSupportRpc(tenantExternalKey: tenantExternalKey);
    } catch (_) {
      return const <TenantSupportMemberView>[];
    }
  }

  Future<void> addTenantSupportMember({
    required String tenantExternalKey,
    required int messengerUserId,
    int? tier,
  }) => _addTenantSupportRpc(
    tenantExternalKey: tenantExternalKey,
    messengerUserId: messengerUserId,
    tier: tier,
  );

  /// Убрать из поддержки тенанта — человек исчезнет из команд ВСЕХ его
  /// продуктов сразу.
  Future<void> removeTenantSupportMember({
    required String tenantExternalKey,
    required int messengerUserId,
  }) => _removeTenantSupportRpc(
    tenantExternalKey: tenantExternalKey,
    messengerUserId: messengerUserId,
  );

  // ── оргкоманды тенанта ─────────────────────────────────────────────

  /// Команды тенанта. Сбой деградирует в пустой список — решать доступ
  /// всё равно серверу, а экрану нужно что-то показать.
  Future<List<TeamView>> listTeams({required String tenantExternalKey}) async {
    try {
      return await _listTeamsRpc(tenantExternalKey: tenantExternalKey);
    } catch (_) {
      return const <TeamView>[];
    }
  }

  /// Завести оргкоманду. Бросает — тёзка в этом тенанте запрещена, и
  /// экран обязан сказать об этом, а не проглотить.
  Future<TeamView> createTeam({
    required String tenantExternalKey,
    required String name,
    String? description,
  }) => _createTeamRpc(
    tenantExternalKey: tenantExternalKey,
    name: name,
    description: description,
  );

  /// Распустить команду. Переписку не трогает: пропадает знакомство, а
  /// комнаты и история остаются.
  Future<void> deleteTeam({
    required String tenantExternalKey,
    required int teamId,
  }) => _deleteTeamRpc(tenantExternalKey: tenantExternalKey, teamId: teamId);

  Future<List<TeamMemberView>> listTeamMembers({
    required String tenantExternalKey,
    required int teamId,
  }) async {
    try {
      return await _listTeamMembersRpc(
        tenantExternalKey: tenantExternalKey,
        teamId: teamId,
      );
    } catch (_) {
      return const <TeamMemberView>[];
    }
  }

  Future<void> addTeamMember({
    required String tenantExternalKey,
    required int teamId,
    required int messengerUserId,
  }) => _addTeamMemberRpc(
    tenantExternalKey: tenantExternalKey,
    teamId: teamId,
    messengerUserId: messengerUserId,
  );

  /// Убрать из команды. Человек исчезнет из списка людей у остальных —
  /// если не остался знакомым по другой причине (общий чат, ручной
  /// контакт, другая общая команда).
  Future<void> removeTeamMember({
    required String tenantExternalKey,
    required int teamId,
    required int messengerUserId,
  }) => _removeTeamMemberRpc(
    tenantExternalKey: tenantExternalKey,
    teamId: teamId,
    messengerUserId: messengerUserId,
  );

  /// Продукты тенанта. Сбой деградирует в пустой список — как listTenants:
  /// экран покажет «продуктов нет» вместо «что-то пошло не так», а решать
  /// доступ всё равно серверу.
  Future<List<ProductAdminView>> listProducts({
    required String tenantExternalKey,
  }) async {
    try {
      return await _listProductsRpc(tenantExternalKey: tenantExternalKey);
    } catch (_) {
      return const <ProductAdminView>[];
    }
  }

  /// Завести команду поддержки продукта, назначив владельца по email.
  /// Ошибку НЕ глотаем: экран обязан сказать, почему не вышло.
  /// [ownerEmail] пуст — владельцем становится сам вызывающий: спрашивать
  /// «чей email» у того, кто прямо сейчас заводит поддержку, незачем.
  Future<void> provisionSupportTeam({
    required String tenantExternalKey,
    required String productExternalKey,
    String? ownerEmail,
    int? ownerMessengerUserId,
  }) => _provisionSupportTeamRpc(
    tenantExternalKey: tenantExternalKey,
    productExternalKey: productExternalKey,
    ownerEmail: ownerEmail,
    ownerMessengerUserId: ownerMessengerUserId,
  );

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
