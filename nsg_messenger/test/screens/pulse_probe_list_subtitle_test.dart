/// **Подпись пробы в списке** (TASK94).
///
/// Найдено владельцем на скриншоте прода: у ЗЕЛЁНОЙ работающей пробы стояло
/// «сигналов ещё не было». Это heartbeat-текст, а пробе beat слать некому —
/// то есть исправный монитор был подписан так, будто он мёртв. Ровно тот род
/// вранья, против которого вся задача: мониторинг, которому перестают верить.
///
/// Плюс просьба владельца там же: в списке нужен СРОК сертификата — ради
/// него всё и заводится, а ходить за ним в карточку каждого монитора значит
/// не увидеть приближающийся срок, пока не откроешь именно тот монитор.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_screen.dart';

final _now = DateTime.now().toUtc();

PulseMonitor _probeMonitor() => PulseMonitor(
  id: 10,
  tenantId: 1,
  name: 'Сертификат nsgsoft.ru:8896',
  kind: 'tlsProbe',
  periodSeconds: 300,
  graceSeconds: 120,
  status: 'ok',
  paused: false,
  createdBy: 1,
  createdAt: _now.subtract(const Duration(days: 1)),
);

PulseTlsProbe _probe({DateTime? notAfter, DateTime? lastCheckAt}) =>
    PulseTlsProbe(
      id: 1,
      monitorId: 10,
      connectHost: '78.37.191.63',
      port: 8896,
      serverName: 'nsgsoft.ru',
      timeoutSeconds: 20,
      validationMode: 'publicPki',
      warnBeforeDays: 30,
      errorBeforeDays: 14,
      failureThreshold: 2,
      recoveryThreshold: 1,
      consecutiveFailures: 0,
      consecutiveSuccesses: 1,
      lastCheckAt: lastCheckAt,
      lastNotAfter: notAfter,
      createdAt: _now,
      updatedAt: _now,
    );

NsgMessengerPulse _fake(List<PulseTlsProbe> probes) =>
    NsgMessengerPulse.withRpcs(
      statusStreamRpc: () => const Stream<PulseEvent>.empty(),
      listFoldersRpc: () async => const <PulseFolder>[],
      createFolderRpc: ({required String name, int? parentId}) =>
          throw UnimplementedError(),
      renameFolderRpc: ({required int id, required String name}) =>
          throw UnimplementedError(),
      deleteFolderRpc: ({required int id}) => throw UnimplementedError(),
      listMonitorsRpc: () async => [_probeMonitor()],
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
      listTlsProbesRpc: () async => probes,
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
      ackIncidentRpc: ({required int incidentId}) => throw UnimplementedError(),
      listMyAccessRpc: () async => [
        PulseAccessEntry(targetKind: 'monitor', targetId: 10, role: 'owner'),
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

Future<void> _pump(WidgetTester t, List<PulseTlsProbe> probes) async {
  // Узкое окно: дерево рисует плитки мониторов напрямую.
  t.view.physicalSize = const Size(500, 900);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: PulseScreen(pulseOverride: _fake(probes)),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('проба показывает СРОК сертификата, а не «сигналов не было»',
      (t) async {
    await _pump(t, [
      _probe(
        notAfter: _now.add(const Duration(days: 89, hours: 12)),
        lastCheckAt: _now.subtract(const Duration(minutes: 2)),
      ),
    ]);

    expect(
      find.textContaining('89 дн.'),
      findsOneWidget,
      reason: 'ради срока мониторинг сертификатов и заводится',
    );
    expect(
      find.textContaining('сигнал'),
      findsNothing,
      reason: 'beat-а у пробы нет — эта подпись врала о живом мониторе',
    );
  });

  testWidgets('истёкший сертификат назван истёкшим, а не «-1 дн.»', (t) async {
    await _pump(t, [
      _probe(
        notAfter: _now.subtract(const Duration(days: 2)),
        lastCheckAt: _now,
      ),
    ]);
    expect(find.textContaining('истёк'), findsOneWidget);
  });

  testWidgets('пока сертификата не видели — говорим о проверках, не о сигналах',
      (t) async {
    await _pump(t, [_probe()]);
    expect(find.textContaining('проверок ещё не было'), findsOneWidget);
    expect(find.textContaining('сигнал'), findsNothing);
  });
}
