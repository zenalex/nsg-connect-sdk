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
typedef MovePulseMonitorRpc =
    Future<PulseMonitor> Function({required int id, int? folderId});
typedef DeletePulseMonitorRpc = Future<void> Function({required int id});

// ── TLS-пробы (TASK94) ──────────────────────────────────────────────────
typedef CreatePulseTlsProbeRpc =
    Future<PulseTlsProbe> Function({
      required String name,
      required String connectHost,
      required int port,
      required String serverName,
      int? folderId,
      required int periodSeconds,
      required int graceSeconds,
      required int timeoutSeconds,
      required String validationMode,
      String? expectedThumbprint,
      String? certificateSetKey,
      required int warnBeforeDays,
      required int errorBeforeDays,
    });
// ── Allowlist проб (TASK94 §2) ──────────────────────────────────────────
typedef ListPulseProbeAllowlistRpc =
    Future<List<PulseProbeAllowlistEntry>> Function();
typedef AddPulseProbeAllowlistRpc =
    Future<PulseProbeAllowlistEntry> Function({
      required String address,
      int? prefixLength,
      required int port,
      String? note,
    });
typedef RemovePulseProbeAllowlistRpc = Future<void> Function({required int id});

typedef ListPulseTlsProbesRpc = Future<List<PulseTlsProbe>> Function();
typedef GetPulseTlsProbeRpc =
    Future<PulseTlsProbe?> Function({required int monitorId});
typedef RunPulseProbeNowRpc =
    Future<PulseTlsProbe> Function({required int monitorId});

/// **issue #108**: правка цели пробы — адрес, порт, имя в SNI. Каждое поле
/// необязательно: не переданное остаётся прежним.
typedef UpdatePulseProbeTargetRpc =
    Future<PulseTlsProbe> Function({
      required int monitorId,
      String? connectHost,
      int? port,
      String? serverName,
    });

// ── Пороги по значению (issue #116) ─────────────────────────────────────
typedef ListPulseValueThresholdsRpc =
    Future<List<PulseValueThreshold>> Function({required int monitorId});
typedef SetPulseValueThresholdRpc =
    Future<PulseValueThreshold> Function({
      required int monitorId,
      required String name,
      double? warnBelow,
      double? errorBelow,
      double? warnAbove,
      double? errorAbove,
    });
typedef RemovePulseValueThresholdRpc =
    Future<void> Function({required int monitorId, required String name});

// ── Рубежи напоминаний (TASK94 MR2) ─────────────────────────────────────
typedef GetPulseExpiryReminderRpc =
    Future<PulseExpiryReminder?> Function({required int monitorId});
typedef SetPulseExpiryThresholdsRpc =
    Future<PulseExpiryReminder> Function({
      required int monitorId,
      required String thresholdDays,
    });

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

// ── Доступ и участники (TASK79) ─────────────────────────────────────────
typedef ListPulseMyAccessRpc = Future<List<PulseAccessEntry>> Function();
typedef ListPulseMembersRpc =
    Future<List<PulseMemberView>> Function({int? folderId, int? monitorId});
typedef SetPulseMemberRpc =
    Future<void> Function({
      int? folderId,
      int? monitorId,
      required int messengerUserId,
      required String role,
    });
typedef RemovePulseMemberRpc =
    Future<void> Function({
      int? folderId,
      int? monitorId,
      required int messengerUserId,
    });

/// **issue #142**: тип адресного события «твои права изменились».
///
/// Контракт с сервером — `pulseEventAccessChanged` в
/// `nsg_connect_server/src/business/pulse_access_service.dart`. Событие
/// приходит БЕЗ монитора (менялись права, а не он) и только своему
/// адресату; клиент по нему перечитывает дерево папок и мониторов, потому
/// что точечно обновлять нечего — могли открыть целую папку, а могли
/// отобрать.
const String pulseEventAccessChanged = 'access.changed';

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
    required MovePulseMonitorRpc moveMonitorRpc,
    required DeletePulseMonitorRpc deleteMonitorRpc,
    required CreatePulseTlsProbeRpc createTlsProbeRpc,
    required ListPulseTlsProbesRpc listTlsProbesRpc,
    required ListPulseProbeAllowlistRpc listProbeAllowlistRpc,
    required AddPulseProbeAllowlistRpc addProbeAllowlistRpc,
    required RemovePulseProbeAllowlistRpc removeProbeAllowlistRpc,
    required GetPulseTlsProbeRpc getTlsProbeRpc,
    required RunPulseProbeNowRpc runProbeNowRpc,
    required UpdatePulseProbeTargetRpc updateProbeTargetRpc,
    required ListPulseValueThresholdsRpc listValueThresholdsRpc,
    required SetPulseValueThresholdRpc setValueThresholdRpc,
    required RemovePulseValueThresholdRpc removeValueThresholdRpc,
    required GetPulseExpiryReminderRpc getExpiryReminderRpc,
    required SetPulseExpiryThresholdsRpc setExpiryThresholdsRpc,
    required ListPulseRulesRpc listRulesRpc,
    required CreatePulseRuleRpc createRuleRpc,
    required DeletePulseRuleRpc deleteRuleRpc,
    required ListPulseIncidentsRpc listIncidentsRpc,
    required AckPulseIncidentRpc ackIncidentRpc,
    required ListPulseMyAccessRpc listMyAccessRpc,
    required ListPulseMembersRpc listMembersRpc,
    required SetPulseMemberRpc setMemberRpc,
    required RemovePulseMemberRpc removeMemberRpc,
  }) : _statusStreamRpc = statusStreamRpc,
       _listFoldersRpc = listFoldersRpc,
       _createFolderRpc = createFolderRpc,
       _renameFolderRpc = renameFolderRpc,
       _deleteFolderRpc = deleteFolderRpc,
       _listMonitorsRpc = listMonitorsRpc,
       _createMonitorRpc = createMonitorRpc,
       _rotateTokenRpc = rotateTokenRpc,
       _setPausedRpc = setPausedRpc,
       _moveMonitorRpc = moveMonitorRpc,
       _deleteMonitorRpc = deleteMonitorRpc,
       _createTlsProbeRpc = createTlsProbeRpc,
       _listTlsProbesRpc = listTlsProbesRpc,
       _listProbeAllowlistRpc = listProbeAllowlistRpc,
       _addProbeAllowlistRpc = addProbeAllowlistRpc,
       _removeProbeAllowlistRpc = removeProbeAllowlistRpc,
       _getTlsProbeRpc = getTlsProbeRpc,
       _runProbeNowRpc = runProbeNowRpc,
       _updateProbeTargetRpc = updateProbeTargetRpc,
       _listValueThresholdsRpc = listValueThresholdsRpc,
       _setValueThresholdRpc = setValueThresholdRpc,
       _removeValueThresholdRpc = removeValueThresholdRpc,
       _getExpiryReminderRpc = getExpiryReminderRpc,
       _setExpiryThresholdsRpc = setExpiryThresholdsRpc,
       _listRulesRpc = listRulesRpc,
       _createRuleRpc = createRuleRpc,
       _deleteRuleRpc = deleteRuleRpc,
       _listIncidentsRpc = listIncidentsRpc,
       _ackIncidentRpc = ackIncidentRpc,
       _listMyAccessRpc = listMyAccessRpc,
       _listMembersRpc = listMembersRpc,
       _setMemberRpc = setMemberRpc,
       _removeMemberRpc = removeMemberRpc;

  final PulseStatusStreamRpc _statusStreamRpc;
  final ListPulseFoldersRpc _listFoldersRpc;
  final CreatePulseFolderRpc _createFolderRpc;
  final RenamePulseFolderRpc _renameFolderRpc;
  final DeletePulseFolderRpc _deleteFolderRpc;
  final ListPulseMonitorsRpc _listMonitorsRpc;
  final CreatePulseMonitorRpc _createMonitorRpc;
  final RotatePulseTokenRpc _rotateTokenRpc;
  final SetPulsePausedRpc _setPausedRpc;
  final MovePulseMonitorRpc _moveMonitorRpc;
  final DeletePulseMonitorRpc _deleteMonitorRpc;
  final CreatePulseTlsProbeRpc _createTlsProbeRpc;
  final ListPulseTlsProbesRpc _listTlsProbesRpc;
  final ListPulseProbeAllowlistRpc _listProbeAllowlistRpc;
  final AddPulseProbeAllowlistRpc _addProbeAllowlistRpc;
  final RemovePulseProbeAllowlistRpc _removeProbeAllowlistRpc;
  final GetPulseTlsProbeRpc _getTlsProbeRpc;
  final RunPulseProbeNowRpc _runProbeNowRpc;
  final UpdatePulseProbeTargetRpc _updateProbeTargetRpc;
  final ListPulseValueThresholdsRpc _listValueThresholdsRpc;
  final SetPulseValueThresholdRpc _setValueThresholdRpc;
  final RemovePulseValueThresholdRpc _removeValueThresholdRpc;
  final GetPulseExpiryReminderRpc _getExpiryReminderRpc;
  final SetPulseExpiryThresholdsRpc _setExpiryThresholdsRpc;
  final ListPulseRulesRpc _listRulesRpc;
  final CreatePulseRuleRpc _createRuleRpc;
  final DeletePulseRuleRpc _deleteRuleRpc;
  final ListPulseIncidentsRpc _listIncidentsRpc;
  final AckPulseIncidentRpc _ackIncidentRpc;
  final ListPulseMyAccessRpc _listMyAccessRpc;
  final ListPulseMembersRpc _listMembersRpc;
  final SetPulseMemberRpc _setMemberRpc;
  final RemovePulseMemberRpc _removeMemberRpc;

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
      deleteFolderRpc: ({required int id}) =>
          withAuthRetry(() => client.pulse.deleteFolder(id: id), session()),
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
      rotateTokenRpc: ({required int id}) =>
          withAuthRetry(() => client.pulse.rotateToken(id: id), session()),
      setPausedRpc: ({required int id, required bool paused}) => withAuthRetry(
        () => client.pulse.setPaused(id: id, paused: paused),
        session(),
      ),
      moveMonitorRpc: ({required int id, int? folderId}) => withAuthRetry(
        () => client.pulse.moveMonitor(id: id, folderId: folderId),
        session(),
      ),
      deleteMonitorRpc: ({required int id}) =>
          withAuthRetry(() => client.pulse.deleteMonitor(id: id), session()),
      createTlsProbeRpc:
          ({
            required String name,
            required String connectHost,
            required int port,
            required String serverName,
            int? folderId,
            required int periodSeconds,
            required int graceSeconds,
            required int timeoutSeconds,
            required String validationMode,
            String? expectedThumbprint,
            String? certificateSetKey,
            required int warnBeforeDays,
            required int errorBeforeDays,
          }) => withAuthRetry(
            () => client.pulse.createTlsProbeMonitor(
              name: name,
              connectHost: connectHost,
              port: port,
              serverName: serverName,
              folderId: folderId,
              periodSeconds: periodSeconds,
              graceSeconds: graceSeconds,
              timeoutSeconds: timeoutSeconds,
              // Пороги подтверждения формой пока не задаются: два подряд
              // сетевых отказа до `down` и один успех на выход — то, что
              // просил интегратор по умолчанию. Правится в БД, а когда
              // понадобится в UI — поле уже есть.
              failureThreshold: 2,
              recoveryThreshold: 1,
              validationMode: validationMode,
              expectedThumbprint: expectedThumbprint,
              certificateSetKey: certificateSetKey,
              warnBeforeDays: warnBeforeDays,
              errorBeforeDays: errorBeforeDays,
            ),
            session(),
          ),
      listTlsProbesRpc: () =>
          withAuthRetry(() => client.pulse.listTlsProbes(), session()),
      listProbeAllowlistRpc: () =>
          withAuthRetry(() => client.pulse.listProbeAllowlist(), session()),
      addProbeAllowlistRpc:
          ({
            required String address,
            int? prefixLength,
            required int port,
            String? note,
          }) => withAuthRetry(
            () => client.pulse.addProbeAllowlistEntry(
              address: address,
              prefixLength: prefixLength,
              port: port,
              note: note,
            ),
            session(),
          ),
      removeProbeAllowlistRpc: ({required int id}) => withAuthRetry(
        () => client.pulse.removeProbeAllowlistEntry(id: id),
        session(),
      ),
      getTlsProbeRpc: ({required int monitorId}) => withAuthRetry(
        () => client.pulse.getTlsProbe(monitorId: monitorId),
        session(),
      ),
      runProbeNowRpc: ({required int monitorId}) => withAuthRetry(
        () => client.pulse.runProbeNow(monitorId: monitorId),
        session(),
      ),
      updateProbeTargetRpc:
          ({
            required int monitorId,
            String? connectHost,
            int? port,
            String? serverName,
          }) => withAuthRetry(
            () => client.pulse.updateTlsProbeTarget(
              monitorId: monitorId,
              connectHost: connectHost,
              port: port,
              serverName: serverName,
            ),
            session(),
          ),
      listValueThresholdsRpc: ({required int monitorId}) => withAuthRetry(
        () => client.pulse.listValueThresholds(monitorId: monitorId),
        session(),
      ),
      setValueThresholdRpc:
          ({
            required int monitorId,
            required String name,
            double? warnBelow,
            double? errorBelow,
            double? warnAbove,
            double? errorAbove,
          }) => withAuthRetry(
            () => client.pulse.setValueThreshold(
              monitorId: monitorId,
              name: name,
              warnBelow: warnBelow,
              errorBelow: errorBelow,
              warnAbove: warnAbove,
              errorAbove: errorAbove,
            ),
            session(),
          ),
      removeValueThresholdRpc: ({required int monitorId, required String name}) =>
          withAuthRetry(
            () => client.pulse.removeValueThreshold(
              monitorId: monitorId,
              name: name,
            ),
            session(),
          ),
      getExpiryReminderRpc: ({required int monitorId}) => withAuthRetry(
        () => client.pulse.getExpiryReminder(monitorId: monitorId),
        session(),
      ),
      setExpiryThresholdsRpc:
          ({required int monitorId, required String thresholdDays}) =>
              withAuthRetry(
                () => client.pulse.setExpiryThresholds(
                  monitorId: monitorId,
                  thresholdDays: thresholdDays,
                ),
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
      deleteRuleRpc: ({required int id}) =>
          withAuthRetry(() => client.pulse.deleteRule(id: id), session()),
      listIncidentsRpc: ({required int monitorId, required int limit}) =>
          withAuthRetry(
            () =>
                client.pulse.listIncidents(monitorId: monitorId, limit: limit),
            session(),
          ),
      ackIncidentRpc: ({required int incidentId}) => withAuthRetry(
        () => client.pulse.ackIncident(incidentId: incidentId),
        session(),
      ),
      listMyAccessRpc: () =>
          withAuthRetry(() => client.pulse.listMyAccess(), session()),
      listMembersRpc: ({int? folderId, int? monitorId}) => withAuthRetry(
        () =>
            client.pulse.listMembers(folderId: folderId, monitorId: monitorId),
        session(),
      ),
      setMemberRpc:
          ({
            int? folderId,
            int? monitorId,
            required int messengerUserId,
            required String role,
          }) => withAuthRetry(
            () => client.pulse.setMember(
              folderId: folderId,
              monitorId: monitorId,
              messengerUserId: messengerUserId,
              role: role,
            ),
            session(),
          ),
      removeMemberRpc:
          ({int? folderId, int? monitorId, required int messengerUserId}) =>
              withAuthRetry(
                () => client.pulse.removeMember(
                  folderId: folderId,
                  monitorId: monitorId,
                  messengerUserId: messengerUserId,
                ),
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
    required MovePulseMonitorRpc moveMonitorRpc,
    required DeletePulseMonitorRpc deleteMonitorRpc,
    required CreatePulseTlsProbeRpc createTlsProbeRpc,
    required ListPulseTlsProbesRpc listTlsProbesRpc,
    required ListPulseProbeAllowlistRpc listProbeAllowlistRpc,
    required AddPulseProbeAllowlistRpc addProbeAllowlistRpc,
    required RemovePulseProbeAllowlistRpc removeProbeAllowlistRpc,
    required GetPulseTlsProbeRpc getTlsProbeRpc,
    required RunPulseProbeNowRpc runProbeNowRpc,
    required UpdatePulseProbeTargetRpc updateProbeTargetRpc,
    required ListPulseValueThresholdsRpc listValueThresholdsRpc,
    required SetPulseValueThresholdRpc setValueThresholdRpc,
    required RemovePulseValueThresholdRpc removeValueThresholdRpc,
    required GetPulseExpiryReminderRpc getExpiryReminderRpc,
    required SetPulseExpiryThresholdsRpc setExpiryThresholdsRpc,
    required ListPulseRulesRpc listRulesRpc,
    required CreatePulseRuleRpc createRuleRpc,
    required DeletePulseRuleRpc deleteRuleRpc,
    required ListPulseIncidentsRpc listIncidentsRpc,
    required AckPulseIncidentRpc ackIncidentRpc,
    required ListPulseMyAccessRpc listMyAccessRpc,
    required ListPulseMembersRpc listMembersRpc,
    required SetPulseMemberRpc setMemberRpc,
    required RemovePulseMemberRpc removeMemberRpc,
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
    moveMonitorRpc: moveMonitorRpc,
    deleteMonitorRpc: deleteMonitorRpc,
    createTlsProbeRpc: createTlsProbeRpc,
    listTlsProbesRpc: listTlsProbesRpc,
    listProbeAllowlistRpc: listProbeAllowlistRpc,
    addProbeAllowlistRpc: addProbeAllowlistRpc,
    removeProbeAllowlistRpc: removeProbeAllowlistRpc,
    getTlsProbeRpc: getTlsProbeRpc,
    runProbeNowRpc: runProbeNowRpc,
    updateProbeTargetRpc: updateProbeTargetRpc,
    listValueThresholdsRpc: listValueThresholdsRpc,
    setValueThresholdRpc: setValueThresholdRpc,
    removeValueThresholdRpc: removeValueThresholdRpc,
    getExpiryReminderRpc: getExpiryReminderRpc,
    setExpiryThresholdsRpc: setExpiryThresholdsRpc,
    listRulesRpc: listRulesRpc,
    createRuleRpc: createRuleRpc,
    deleteRuleRpc: deleteRuleRpc,
    listIncidentsRpc: listIncidentsRpc,
    ackIncidentRpc: ackIncidentRpc,
    listMyAccessRpc: listMyAccessRpc,
    listMembersRpc: listMembersRpc,
    setMemberRpc: setMemberRpc,
    removeMemberRpc: removeMemberRpc,
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
  /// **TASK94**: перенести монитор в папку; `folderId == null` — в корень.
  Future<PulseMonitor> moveMonitor({required int id, int? folderId}) =>
      _moveMonitorRpc(id: id, folderId: folderId);

  /// **TASK94**: завести монитор-пробу. Токена у него нет — сервер сам
  /// ходит на цель и проверяет сертификат.
  Future<PulseTlsProbe> createTlsProbeMonitor({
    required String name,
    required String connectHost,
    required int port,
    required String serverName,
    int? folderId,
    int periodSeconds = 300,
    int graceSeconds = 120,
    int timeoutSeconds = 10,
    String validationMode = 'publicPki',
    String? expectedThumbprint,
    String? certificateSetKey,
    int warnBeforeDays = 30,
    int errorBeforeDays = 14,
  }) => _createTlsProbeRpc(
    name: name,
    connectHost: connectHost,
    port: port,
    serverName: serverName,
    folderId: folderId,
    periodSeconds: periodSeconds,
    graceSeconds: graceSeconds,
    timeoutSeconds: timeoutSeconds,
    validationMode: validationMode,
    expectedThumbprint: expectedThumbprint,
    certificateSetKey: certificateSetKey,
    warnBeforeDays: warnBeforeDays,
    errorBeforeDays: errorBeforeDays,
  );

  /// **TASK94 §2**: куда пробам вообще разрешено ходить. Правит только
  /// супер-админ платформы — список говорит, куда вправе ходить НАШ сервер,
  /// а не что видит арендатор.
  Future<List<PulseProbeAllowlistEntry>> listProbeAllowlist() =>
      _listProbeAllowlistRpc();

  Future<PulseProbeAllowlistEntry> addProbeAllowlistEntry({
    required String address,
    int? prefixLength,
    required int port,
    String? note,
  }) => _addProbeAllowlistRpc(
    address: address,
    prefixLength: prefixLength,
    port: port,
    note: note,
  );

  Future<void> removeProbeAllowlistEntry({required int id}) =>
      _removeProbeAllowlistRpc(id: id);

  /// Пробы всех видимых мониторов — одним запросом, для списка.
  Future<List<PulseTlsProbe>> listTlsProbes() => _listTlsProbesRpc();

  /// Цель и последние наблюдения пробы. `null` — монитор не проба.
  Future<PulseTlsProbe?> getTlsProbe({required int monitorId}) =>
      _getTlsProbeRpc(monitorId: monitorId);

  /// Проверить прямо сейчас, не дожидаясь периода.
  Future<PulseTlsProbe> runProbeNow({required int monitorId}) =>
      _runProbeNowRpc(monitorId: monitorId);

  /// **issue #108**: перевести пробу на другую цель. Монитор, его история
  /// инцидентов и участники остаются; наблюдения прежней цели сбрасываются
  /// на сервере, и проверка запускается сразу.
  Future<PulseTlsProbe> updateProbeTarget({
    required int monitorId,
    String? connectHost,
    int? port,
    String? serverName,
  }) => _updateProbeTargetRpc(
    monitorId: monitorId,
    connectHost: connectHost,
    port: port,
    serverName: serverName,
  );

  /// **issue #116**: пороги по значению у монитора.
  Future<List<PulseValueThreshold>> listValueThresholds({
    required int monitorId,
  }) => _listValueThresholdsRpc(monitorId: monitorId);

  /// Задать порог. Хотя бы одна граница обязательна — иначе это правило,
  /// которое никогда не сработает.
  Future<PulseValueThreshold> setValueThreshold({
    required int monitorId,
    required String name,
    double? warnBelow,
    double? errorBelow,
    double? warnAbove,
    double? errorAbove,
  }) => _setValueThresholdRpc(
    monitorId: monitorId,
    name: name,
    warnBelow: warnBelow,
    errorBelow: errorBelow,
    warnAbove: warnAbove,
    errorAbove: errorAbove,
  );

  /// Убрать порог. Число продолжит приходить и показываться.
  Future<void> removeValueThreshold({
    required int monitorId,
    required String name,
  }) => _removeValueThresholdRpc(monitorId: monitorId, name: name);

  /// **TASK94 MR2**: состояние напоминаний монитора (набор рубежей, срок,
  /// последний пройденный рубеж). `null` — наблюдений ещё не было.
  Future<PulseExpiryReminder?> getExpiryReminder({required int monitorId}) =>
      _getExpiryReminderRpc(monitorId: monitorId);

  /// Набор рубежей: `30,14,7,1` (ACME) или `90,60,30,14,7,1`
  /// (коммерческие). Пустая строка — не напоминать.
  Future<PulseExpiryReminder> setExpiryThresholds({
    required int monitorId,
    required String thresholdDays,
  }) => _setExpiryThresholdsRpc(
    monitorId: monitorId,
    thresholdDays: thresholdDays,
  );

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

  // ── Доступ и участники (TASK79) ────────────────────────────────────

  /// Эффективные роли текущего пользователя на всех доступных объектах.
  /// По ним UI прячет кнопки; сервер всё равно проверяет права сам —
  /// это подсказка интерфейсу, а не гейт.
  Future<List<PulseAccessEntry>> listMyAccess() => _listMyAccessRpc();

  /// Состав участников папки ИЛИ монитора (ровно один из аргументов).
  /// Строки с `inherited == true` пришли от папки-предка и здесь
  /// read-only — убирать участника надо там, где его добавили.
  Future<List<PulseMemberView>> listMembers({int? folderId, int? monitorId}) =>
      _listMembersRpc(folderId: folderId, monitorId: monitorId);

  /// Добавить участника или сменить ему роль (upsert). Доступно `owner`-у.
  Future<void> setMember({
    int? folderId,
    int? monitorId,
    required int messengerUserId,
    required String role,
  }) => _setMemberRpc(
    folderId: folderId,
    monitorId: monitorId,
    messengerUserId: messengerUserId,
    role: role,
  );

  /// Отозвать доступ. Доступно `owner`-у; последнего владельца сервер
  /// снять не даст ([LastOwnerCannotDemoteException]).
  Future<void> removeMember({
    int? folderId,
    int? monitorId,
    required int messengerUserId,
  }) => _removeMemberRpc(
    folderId: folderId,
    monitorId: monitorId,
    messengerUserId: messengerUserId,
  );
}

/// Роли мониторинга на стороне клиента — зеркало серверных `PulseRoles`.
///
/// Строки, а не enum: сервер хранит роль строкой и может добавить новую
/// без пересборки клиентов. Незнакомую роль трактуем как «прав нет»
/// (fail-closed): показать кнопку, которую сервер всё равно отклонит,
/// хуже, чем не показать.
class PulseClientRoles {
  const PulseClientRoles._();

  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String viewer = 'viewer';

  static int rank(String? role) => switch (role) {
    owner => 3,
    admin => 2,
    viewer => 1,
    _ => 0,
  };

  static bool atLeast(String? role, String required) =>
      rank(role) > 0 && rank(role) >= rank(required);
}

/// Карта «объект → моя роль», построенная из [NsgMessengerPulse.listMyAccess].
/// Живёт рядом с API, а не в экране: тем же ответом пользуются и дерево, и
/// detail-лист монитора, и экран участников.
class PulseAccessMap {
  const PulseAccessMap(this._folders, this._monitors);

  const PulseAccessMap.empty() : _folders = const {}, _monitors = const {};

  factory PulseAccessMap.fromEntries(List<PulseAccessEntry> entries) {
    final folders = <int, String>{};
    final monitors = <int, String>{};
    for (final e in entries) {
      final target = e.targetKind == 'folder' ? folders : monitors;
      final prev = target[e.targetId];
      if (prev == null ||
          PulseClientRoles.rank(e.role) > PulseClientRoles.rank(prev)) {
        target[e.targetId] = e.role;
      }
    }
    return PulseAccessMap(folders, monitors);
  }

  final Map<int, String> _folders;
  final Map<int, String> _monitors;

  /// null = роли нет. Для папки это ещё и «папка показана лишь как путь
  /// к доступному монитору» — управление ею скрыто.
  String? folderRole(int? folderId) =>
      folderId == null ? null : _folders[folderId];

  String? monitorRole(int? monitorId) =>
      monitorId == null ? null : _monitors[monitorId];

  bool folderAtLeast(int? folderId, String role) =>
      PulseClientRoles.atLeast(folderRole(folderId), role);

  bool monitorAtLeast(int? monitorId, String role) =>
      PulseClientRoles.atLeast(monitorRole(monitorId), role);
}
