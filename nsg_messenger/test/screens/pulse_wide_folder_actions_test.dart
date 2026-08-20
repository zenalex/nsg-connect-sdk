/// **Действия папки достижимы на широком экране** (TASK94, регрессия
/// двухпанельной раскладки).
///
/// Жалоба владельца 10.08.2026: «нет участников рядом с папкой, по крайней
/// мере на десктопе». Так и было: в левой панели строки папок — только тап,
/// а корневая папка справа рисовалась без шапки. В итоге у КОРНЕВОЙ папки на
/// десктопе не было ни одного действия — в том числе выдачи доступа, то есть
/// поделиться мониторингом было нельзя вообще.
///
/// Обычными юнитами это не ловится: беда не в логике, а в том, чего на
/// экране НЕТ. Поэтому живой виджет с подменённым фасадом.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_screen.dart';

PulseFolder _folder(int id, String name) => PulseFolder(
  id: id,
  tenantId: 1,
  name: name,
  sortOrder: 0,
  createdAt: DateTime.utc(2026, 8, 10),
);

NsgMessengerPulse _fakePulse() => NsgMessengerPulse.withRpcs(
  statusStreamRpc: () => const Stream<PulseEvent>.empty(),
  listFoldersRpc: () async => [_folder(1, 'Сертификаты')],
  createFolderRpc: ({required String name, int? parentId}) =>
      throw UnimplementedError(),
  renameFolderRpc: ({required int id, required String name}) =>
      throw UnimplementedError(),
  deleteFolderRpc: ({required int id}) => throw UnimplementedError(),
  listMonitorsRpc: () async => const <PulseMonitor>[],
  createMonitorRpc:
      ({
        required String name,
        int? folderId,
        required int periodSeconds,
        required int graceSeconds,
      }) => throw UnimplementedError(),
  rotateTokenRpc: ({required int id}) => throw UnimplementedError(),
  setPausedRpc: ({required int id, required bool paused}) =>
      throw UnimplementedError(),
  moveMonitorRpc: ({required int id, int? folderId}) =>
      throw UnimplementedError(),
  deleteMonitorRpc: ({required int id}) => throw UnimplementedError(),
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
      }) => throw UnimplementedError(),
  listProbeAllowlistRpc: () async =>
      const <PulseProbeAllowlistEntry>[],
  addProbeAllowlistRpc:
      ({
        required String address,
        int? prefixLength,
        required int port,
        String? note,
      }) => throw UnimplementedError(),
  removeProbeAllowlistRpc: ({required int id}) =>
      throw UnimplementedError(),
  listTlsProbesRpc: () async => const <PulseTlsProbe>[],
  getTlsProbeRpc: ({required int monitorId}) => throw UnimplementedError(),
  runProbeNowRpc: ({required int monitorId}) => throw UnimplementedError(),
  listValueThresholdsRpc: ({required int monitorId}) async =>
      const <PulseValueThreshold>[],
  setValueThresholdRpc:
      ({
        required int monitorId,
        required String name,
        double? warnBelow,
        double? errorBelow,
        double? warnAbove,
        double? errorAbove,
      }) => throw UnimplementedError(),
  removeValueThresholdRpc:
      ({required int monitorId, required String name}) =>
          throw UnimplementedError(),
  updateProbeTargetRpc:
      ({
        required int monitorId,
        String? connectHost,
        int? port,
        String? serverName,
      }) => throw UnimplementedError(),
  getExpiryReminderRpc: ({required int monitorId}) =>
      throw UnimplementedError(),
  setExpiryThresholdsRpc:
      ({required int monitorId, required String thresholdDays}) =>
          throw UnimplementedError(),
  listRulesRpc: () async => const <PulseAlertRule>[],
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
      }) => throw UnimplementedError(),
  deleteRuleRpc: ({required int id}) => throw UnimplementedError(),
  listIncidentsRpc: ({required int monitorId, int? limit}) async =>
      const <PulseIncident>[],
  ackIncidentRpc: ({required int incidentId}) =>
      throw UnimplementedError(),
  // Владелец папки: только у него в меню есть всё, включая участников.
  listMyAccessRpc: () async => [
    PulseAccessEntry(targetKind: 'folder', targetId: 1, role: 'owner'),
  ],
  listMembersRpc: ({int? folderId, int? monitorId}) async =>
      const <PulseMemberView>[],
  setMemberRpc:
      ({
        int? folderId,
        int? monitorId,
        required int messengerUserId,
        required String role,
      }) => throw UnimplementedError(),
  removeMemberRpc:
      ({int? folderId, int? monitorId, required int messengerUserId}) =>
          throw UnimplementedError(),
);

void main() {
  testWidgets('широкий экран: у корневой папки есть меню с участниками',
      (t) async {
    t.view.physicalSize = const Size(1200, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        locale: const Locale('ru'),
        home: PulseScreen(pulseOverride: _fakePulse()),
      ),
    );
    await t.pumpAndSettle();

    // Папка живёт в ЛЕВОЙ панели — выбираем её.
    await t.tap(find.text('Сертификаты').first);
    await t.pumpAndSettle();

    // Шапка справа обязана дать меню действий.
    final menu = find.byIcon(Icons.more_vert);
    expect(
      menu,
      findsWidgets,
      reason: 'без шапки у корневой папки не было ни одного действия',
    );

    await t.tap(menu.last);
    await t.pumpAndSettle();
    expect(
      find.text('Участники'),
      findsOneWidget,
      reason: 'выдать доступ к папке — то, ради чего меню и открывают',
    );
  });
}
