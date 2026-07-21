import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK60 (Connect Pulse — heartbeat-мониторинг)**: публичный API дашборда
/// мониторинга. Доступен через `NsgMessenger.pulse`; используется
/// [PulseScreen].
///
/// Тонкая обёртка над сгенерированными Serverpod-эндпоинтами `client.pulse.*`.
/// Каждый unary-RPC оборачивается в [withAuthRetry] для self-heal на серверный
/// auth-invalidation (тот же приём, что в [NsgMessengerRooms] /
/// [NsgMessengerIntegrations]) — [MessengerSessionManager] резолвится лениво
/// через singleton runtime, closures выполняются уже после `init()`.
///
/// Realtime-стрим [statusStream] пробрасывается «как есть»: это
/// streaming-эндпоинт (не Future), поэтому [withAuthRetry] к нему не
/// применяется — переподписку/backoff держит UI ([PulseScreen]).
///
/// Кэша нет: дашборд открывается редко (admin-экран), каждый `list*()` дёргает
/// сервер; realtime обновляет узлы точечно из `event.monitor`.
///
/// Сигнатуры RPC вынесены в typedef-ы для инъекции fake-ов в тестах
/// ([NsgMessengerPulse.withRpcs]) — так тесты не зависят от Serverpod-клиента и
/// runtime singleton-а.

// ── Realtime ────────────────────────────────────────────────────────────
typedef PulseStatusStreamRpc = Stream<PulseEvent> Function();

// ── Папки ───────────────────────────────────────────────────────────────
typedef ListPulseFoldersRpc = Future<List<PulseFolder>> Function();
typedef CreatePulseFolderRpc =
    Future<PulseFolder> Function({required String name, int? parentId});
typedef RenamePulseFolderRpc =
    Future<PulseFolder> Function({required int id, required String name});
typedef DeletePulseFolderRpc = Future<void> Function({required int id});

// ── Мониторы ────────────────────────────────────────────────────────────
typedef ListPulseMonitorsRpc = Future<List<PulseMonitor>> Function();
typedef CreatePulseMonitorRpc =
    Future<PulseMonitorCreated> Function({
      required String name,
      int? folderId,
      required int periodSeconds,
      required int graceSeconds,
    });
typedef RotatePulseTokenRpc =
    Future<PulseMonitorCreated> Function({required int id});
typedef SetPulsePausedRpc =
    Future<PulseMonitor> Function({required int id, required bool paused});
typedef DeletePulseMonitorRpc = Future<void> Function({required int id});

// ── Правила ─────────────────────────────────────────────────────────────
typedef ListPulseRulesRpc = Future<List<PulseAlertRule>> Function();
typedef CreatePulseRuleRpc =
    Future<PulseAlertRule> Function({
      int? scopeFolderId,
      int? scopeMonitorId,
      required int roomId,
      required String minSeverity,
      int? escalateAfterMinutes,
      String? level1UserIds,
      int? escalate2AfterMinutes,
      String? level2UserIds,
    });
typedef DeletePulseRuleRpc = Future<void> Function({required int id});

// ── Инциденты ───────────────────────────────────────────────────────────
typedef ListPulseIncidentsRpc =
    Future<List<PulseIncident>> Function({
      required int monitorId,
      required int limit,
    });
typedef AckPulseIncidentRpc =
    Future<PulseIncident> Function({required int incidentId});

class NsgMessengerPulse {
  NsgMessengerPulse._({
    required PulseStatusStreamRpc statusStreamRpc,
    required ListPulseFoldersRpc listFoldersRpc,
    required CreatePulseFolderRpc createFolderRpc,
    required RenamePulseFolderRpc renameFolderRpc,
    required DeletePulseFolderRpc deleteFolderRpc,
    required ListPulseMonitorsRpc listMonitorsRpc,
    required CreatePulseMonitorRpc createMonitorRpc,
    required RotatePulseTokenRpc rotateTokenRpc,
    required SetPulsePausedRpc setPausedRpc,
    required DeletePulseMonitorRpc deleteMonitorRpc,
    required ListPulseRulesRpc listRulesRpc,
    required CreatePulseRuleRpc createRuleRpc,
    required DeletePulseRuleRpc deleteRuleRpc,
    required ListPulseIncidentsRpc listIncidentsRpc,
    required AckPulseIncidentRpc ackIncidentRpc,
  }) : _statusStreamRpc = statusStreamRpc,
       _listFoldersRpc = listFoldersRpc,
       _createFolderRpc = createFolderRpc,
       _renameFolderRpc = renameFolderRpc,
       _deleteFolderRpc = deleteFolderRpc,
       _listMonitorsRpc = listMonitorsRpc,
       _createMonitorRpc = createMonitorRpc,
       _rotateTokenRpc = rotateTokenRpc,
       _setPausedRpc = setPausedRpc,
       _deleteMonitorRpc = deleteMonitorRpc,
       _listRulesRpc = listRulesRpc,
       _createRuleRpc = createRuleRpc,
       _deleteRuleRpc = deleteRuleRpc,
       _listIncidentsRpc = listIncidentsRpc,
       _ackIncidentRpc = ackIncidentRpc;

  final PulseStatusStreamRpc _statusStreamRpc;
  final ListPulseFoldersRpc _listFoldersRpc;
  final CreatePulseFolderRpc _createFolderRpc;
  final RenamePulseFolderRpc _renameFolderRpc;
  final DeletePulseFolderRpc _deleteFolderRpc;
  final ListPulseMonitorsRpc _listMonitorsRpc;
  final CreatePulseMonitorRpc _createMonitorRpc;
  final RotatePulseTokenRpc _rotateTokenRpc;
  final SetPulsePausedRpc _setPausedRpc;
  final DeletePulseMonitorRpc _deleteMonitorRpc;
  final ListPulseRulesRpc _listRulesRpc;
  final CreatePulseRuleRpc _createRuleRpc;
  final DeletePulseRuleRpc _deleteRuleRpc;
  final ListPulseIncidentsRpc _listIncidentsRpc;
  final AckPulseIncidentRpc _ackIncidentRpc;

  /// Дефолтный лимит истории инцидентов в detail-листе монитора.
  static const int kDefaultIncidentsLimit = 20;

  /// Production-фабрика. Привязывается к `client.pulse.*` методам; unary-RPC
  /// под [withAuthRetry]. `session()` резолвит session-manager лениво из
  /// runtime (closures выполняются после `init()`). Стрим не оборачиваем.
  static NsgMessengerPulse attach({required Client client}) {
    MessengerSessionManager session() =>
        MessengerRuntime.instance.sessionManager;
    return withRpcs(
      statusStreamRpc: () => client.pulse.statusStream(),
      listFoldersRpc: () =>
          withAuthRetry(() => client.pulse.listFolders(), session()),
      createFolderRpc: ({required String name, int? parentId}) => withAuthRetry(
        () => client.pulse.createFolder(name: name, parentId: parentId),
        session(),
      ),
      renameFolderRpc: ({required int id, required String name}) =>
          withAuthRetry(
            () => client.pulse.renameFolder(id: id, name: name),
            session(),
          ),
      deleteFolderRpc: ({required int id}) => withAuthRetry(
        () => client.pulse.deleteFolder(id: id),
        session(),
      ),
      listMonitorsRpc: () =>
          withAuthRetry(() => client.pulse.listMonitors(), session()),
      createMonitorRpc:
          ({
            required String name,
            int? folderId,
            required int periodSeconds,
            required int graceSeconds,
          }) => withAuthRetry(
            () => client.pulse.createMonitor(
              name: name,
              folderId: folderId,
              periodSeconds: periodSeconds,
              graceSeconds: graceSeconds,
            ),
            session(),
          ),
      rotateTokenRpc: ({required int id}) => withAuthRetry(
        () => client.pulse.rotateToken(id: id),
        session(),
      ),
      setPausedRpc: ({required int id, required bool paused}) => withAuthRetry(
        () => client.pulse.setPaused(id: id, paused: paused),
        session(),
      ),
      deleteMonitorRpc: ({required int id}) => withAuthRetry(
        () => client.pulse.deleteMonitor(id: id),
        session(),
      ),
      listRulesRpc: () =>
          withAuthRetry(() => client.pulse.listRules(), session()),
      createRuleRpc:
          ({
            int? scopeFolderId,
            int? scopeMonitorId,
            required int roomId,
            required String minSeverity,
            int? escalateAfterMinutes,
            String? level1UserIds,
            int? escalate2AfterMinutes,
            String? level2UserIds,
          }) => withAuthRetry(
            () => client.pulse.createRule(
              scopeFolderId: scopeFolderId,
              scopeMonitorId: scopeMonitorId,
              roomId: roomId,
              minSeverity: minSeverity,
              escalateAfterMinutes: escalateAfterMinutes,
              level1UserIds: level1UserIds,
              escalate2AfterMinutes: escalate2AfterMinutes,
              level2UserIds: level2UserIds,
            ),
            session(),
          ),
      deleteRuleRpc: ({required int id}) => withAuthRetry(
        () => client.pulse.deleteRule(id: id),
        session(),
      ),
      listIncidentsRpc: ({required int monitorId, required int limit}) =>
          withAuthRetry(
            () => client.pulse.listIncidents(
              monitorId: monitorId,
              limit: limit,
            ),
            session(),
          ),
      ackIncidentRpc: ({required int incidentId}) => withAuthRetry(
        () => client.pulse.ackIncident(incidentId: incidentId),
        session(),
      ),
    );
  }

  /// Test-фабрика: инъекция fake-RPC (без Serverpod-клиента / runtime).
  static NsgMessengerPulse withRpcs({
    required PulseStatusStreamRpc statusStreamRpc,
    required ListPulseFoldersRpc listFoldersRpc,
    required CreatePulseFolderRpc createFolderRpc,
    required RenamePulseFolderRpc renameFolderRpc,
    required DeletePulseFolderRpc deleteFolderRpc,
    required ListPulseMonitorsRpc listMonitorsRpc,
    required CreatePulseMonitorRpc createMonitorRpc,
    required RotatePulseTokenRpc rotateTokenRpc,
    required SetPulsePausedRpc setPausedRpc,
    required DeletePulseMonitorRpc deleteMonitorRpc,
    required ListPulseRulesRpc listRulesRpc,
    required CreatePulseRuleRpc createRuleRpc,
    required DeletePulseRuleRpc deleteRuleRpc,
    required ListPulseIncidentsRpc listIncidentsRpc,
    required AckPulseIncidentRpc ackIncidentRpc,
  }) => NsgMessengerPulse._(
    statusStreamRpc: statusStreamRpc,
    listFoldersRpc: listFoldersRpc,
    createFolderRpc: createFolderRpc,
    renameFolderRpc: renameFolderRpc,
    deleteFolderRpc: deleteFolderRpc,
    listMonitorsRpc: listMonitorsRpc,
    createMonitorRpc: createMonitorRpc,
    rotateTokenRpc: rotateTokenRpc,
    setPausedRpc: setPausedRpc,
    deleteMonitorRpc: deleteMonitorRpc,
    listRulesRpc: listRulesRpc,
    createRuleRpc: createRuleRpc,
    deleteRuleRpc: deleteRuleRpc,
    listIncidentsRpc: listIncidentsRpc,
    ackIncidentRpc: ackIncidentRpc,
  );

  // ───────────────────────────────────────────────────────────────────
  // Public API
  // ───────────────────────────────────────────────────────────────────

  /// Живой стрим событий дашборда (переходы статусов, инциденты). Стрим
  /// прокидывается «как есть»; переподписку с backoff-ом на ошибке держит UI.
  Stream<PulseEvent> statusStream() => _statusStreamRpc();

  // ── Папки ──────────────────────────────────────────────────────────
  Future<List<PulseFolder>> listFolders() => _listFoldersRpc();

  Future<PulseFolder> createFolder({required String name, int? parentId}) =>
      _createFolderRpc(name: name, parentId: parentId);

  Future<PulseFolder> renameFolder({required int id, required String name}) =>
      _renameFolderRpc(id: id, name: name);

  /// Удаляет только пустую папку (сервер бросает [ArgumentError] иначе).
  Future<void> deleteFolder({required int id}) => _deleteFolderRpc(id: id);

  // ── Мониторы ───────────────────────────────────────────────────────
  Future<List<PulseMonitor>> listMonitors() => _listMonitorsRpc();

  /// Создать монитор → beat-токен + готовый URL (в ответе; **показать один
  /// раз**, в БД хранится только хеш).
  Future<PulseMonitorCreated> createMonitor({
    required String name,
    int? folderId,
    int periodSeconds = 300,
    int graceSeconds = 120,
  }) => _createMonitorRpc(
    name: name,
    folderId: folderId,
    periodSeconds: periodSeconds,
    graceSeconds: graceSeconds,
  );

  /// Ротация beat-токена (тот же монитор; старый токен мёртв немедленно).
  Future<PulseMonitorCreated> rotateToken({required int id}) =>
      _rotateTokenRpc(id: id);

  /// Пауза/возобновление (обслуживание/деплой): свипер и алерты пропускают.
  Future<PulseMonitor> setPaused({required int id, required bool paused}) =>
      _setPausedRpc(id: id, paused: paused);

  Future<void> deleteMonitor({required int id}) => _deleteMonitorRpc(id: id);

  // ── Правила ────────────────────────────────────────────────────────
  Future<List<PulseAlertRule>> listRules() => _listRulesRpc();

  /// Создать правило: ровно один scope (папка ИЛИ монитор).
  Future<PulseAlertRule> createRule({
    int? scopeFolderId,
    int? scopeMonitorId,
    required int roomId,
    String minSeverity = 'warn',
    int? escalateAfterMinutes,
    String? level1UserIds,
    int? escalate2AfterMinutes,
    String? level2UserIds,
  }) => _createRuleRpc(
    scopeFolderId: scopeFolderId,
    scopeMonitorId: scopeMonitorId,
    roomId: roomId,
    minSeverity: minSeverity,
    escalateAfterMinutes: escalateAfterMinutes,
    level1UserIds: level1UserIds,
    escalate2AfterMinutes: escalate2AfterMinutes,
    level2UserIds: level2UserIds,
  );

  Future<void> deleteRule({required int id}) => _deleteRuleRpc(id: id);

  // ── Инциденты ──────────────────────────────────────────────────────
  Future<List<PulseIncident>> listIncidents({
    required int monitorId,
    int limit = kDefaultIncidentsLimit,
  }) => _listIncidentsRpc(monitorId: monitorId, limit: limit);

  /// «Взять в работу» — останавливает эскалацию инцидента.
  Future<PulseIncident> ackIncident({required int incidentId}) =>
      _ackIncidentRpc(incidentId: incidentId);
}
