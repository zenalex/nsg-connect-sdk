/// **Перенос монитора между папками** (TASK94).
///
/// Просьба владельца: сложить сертификаты в папку и выдавать права один
/// раз. До этого папка задавалась ТОЛЬКО при создании — перенести уже
/// заведённый монитор было нельзя вовсе, и ошибка в выборе папки лечилась
/// пересозданием.
///
/// Проверяем путь целиком: карточка монитора → «Переместить в папку» →
/// выбор → вызов ушёл на сервер с нужной папкой.
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

/// Куда уходил перенос — записываем, а не молчим: тест про то, что вызов
/// СЛУЧИЛСЯ и с правильной папкой.
final moved = <({int id, int? folderId})>[];

NsgMessengerPulse _fake(List<PulseTlsProbe> probes) =>
    NsgMessengerPulse.withRpcs(
      statusStreamRpc: () => const Stream<PulseEvent>.empty(),
      listFoldersRpc: () async => [
        PulseFolder(
          id: 7,
          tenantId: 1,
          name: 'Сертификаты',
          sortOrder: 0,
          createdAt: _now,
        ),
      ],
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
      moveMonitorRpc: ({required int id, int? folderId}) async {
        moved.add((id: id, folderId: folderId));
        return _probeMonitor();
      },
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
  setUp(moved.clear);

  testWidgets('владелец переносит монитор в папку', (t) async {
    await _pump(t, [_probe(notAfter: _now.add(const Duration(days: 30)))]);

    await t.tap(find.text('Сертификат nsgsoft.ru:8896'));
    await t.pumpAndSettle();

    await t.tap(find.text('Переместить в папку'));
    await t.pumpAndSettle();

    // Именно пункт ДИАЛОГА: то же имя есть у папки в дереве позади.
    await t.tap(
      find.descendant(
        of: find.byType(SimpleDialogOption),
        matching: find.text('Сертификаты'),
      ),
    );
    await t.pumpAndSettle();

    expect(moved, hasLength(1));
    expect(moved.single.folderId, 7, reason: 'выбранная папка, а не корень');
    expect(moved.single.id, 10);
  });

  testWidgets('в корень переносится тоже — folderId null', (t) async {
    await _pump(t, [_probe(notAfter: _now.add(const Duration(days: 30)))]);
    await t.tap(find.text('Сертификат nsgsoft.ru:8896'));
    await t.pumpAndSettle();
    await t.tap(find.text('Переместить в папку'));
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(SimpleDialogOption),
        matching: find.text('Корень'),
      ),
    );
    await t.pumpAndSettle();

    // Монитор и так в корне — переносить нечего, и вызова быть не должно:
    // лишний UPDATE переписал бы `folderId` тем же значением и оставил в
    // журнале запись о переносе, которого не было.
    expect(moved, isEmpty);
  });
}
