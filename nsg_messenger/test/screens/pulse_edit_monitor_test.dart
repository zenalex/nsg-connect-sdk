/// **issue #187**: правка имени, периода и допуска созданного монитора.
///
/// Жалоба через поддержку: «после создания монитора нет возможности внести
/// изменение… хотя бы изменить период». Здесь закреплено, кому кнопка
/// видна, что уходит на сервер и что диалог не падает на «нестандартном»
/// периоде, которого нет среди пресетов.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_screen.dart';

final _now = DateTime.now().toUtc();

PulseMonitor _monitor({
  required int id,
  required String name,
  String kind = 'heartbeat',
  int periodSeconds = 300,
  int graceSeconds = 120,
}) => PulseMonitor(
  id: id,
  tenantId: 1,
  name: name,
  kind: kind,
  periodSeconds: periodSeconds,
  graceSeconds: graceSeconds,
  status: 'ok',
  paused: false,
  createdBy: 1,
  createdAt: _now.subtract(const Duration(days: 1)),
);

var _monitors = <PulseMonitor>[];
var _roles = <int, String>{};
final updates =
    <({int id, String? name, int? periodSeconds, int? graceSeconds})>[];

NsgMessengerPulse _fake() => NsgMessengerPulse.withRpcs(
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
  listMonitorsRpc: () async => _monitors,
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
  listProbeAllowlistRpc: () async => const <PulseProbeAllowlistEntry>[],
  addProbeAllowlistRpc:
      ({
        required String address,
        int? prefixLength,
        required int port,
        String? note,
      }) => throw UnimplementedError(),
  removeProbeAllowlistRpc: ({required int id}) => throw UnimplementedError(),
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
  removeValueThresholdRpc: ({required int monitorId, required String name}) =>
      throw UnimplementedError(),
  updateProbeTargetRpc:
      ({
        required int monitorId,
        String? connectHost,
        int? port,
        String? serverName,
      }) => throw UnimplementedError(),
  updateMonitorRpc:
      ({
        required int id,
        String? name,
        int? periodSeconds,
        int? graceSeconds,
      }) async {
        updates.add((
          id: id,
          name: name,
          periodSeconds: periodSeconds,
          graceSeconds: graceSeconds,
        ));
        final m = _monitors.firstWhere((e) => e.id == id);
        return m.copyWith(
          name: name,
          periodSeconds: periodSeconds,
          graceSeconds: graceSeconds,
        );
      },
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
    for (final e in _roles.entries)
      PulseAccessEntry(targetKind: 'monitor', targetId: e.key, role: e.value),
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

Future<void> _pump(WidgetTester t) async {
  // Узкое окно: дерево рисует плитки мониторов напрямую, карточка — шторкой.
  t.view.physicalSize = const Size(500, 900);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: PulseScreen(pulseOverride: _fake()),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _openCard(WidgetTester t, String name) async {
  await t.tap(find.text(name));
  await t.pumpAndSettle();
}

Finder get _editButton => find.widgetWithText(OutlinedButton, 'Изменить');

Finder get _saveButton => find.widgetWithText(FilledButton, 'Сохранить');

void main() {
  setUp(() {
    updates.clear();
    _monitors = [_monitor(id: 10, name: 'Прод API')];
    _roles = {10: 'admin'};
  });

  // Главный сценарий из жалобы — «хотя бы изменить период».
  testWidgets('admin меняет период — на сервер уходит новый период', (t) async {
    await _pump(t);
    await _openCard(t, 'Прод API');
    await t.tap(_editButton);
    await t.pumpAndSettle();

    expect(find.text('Параметры монитора'), findsOneWidget);
    // Пока ничего не менял — сохранять нечего.
    expect(t.widget<FilledButton>(_saveButton).onPressed, isNull);

    await t.tap(find.byType(DropdownButtonFormField<int>));
    await t.pumpAndSettle();
    await t.tap(find.text('30 мин').last);
    await t.pumpAndSettle();
    await t.tap(_saveButton);
    await t.pumpAndSettle();

    expect(updates, hasLength(1));
    expect(updates.single.id, 10);
    expect(updates.single.periodSeconds, 1800);
    // Остальное ушло прежним — сервер не должен гадать, что менялось.
    expect(updates.single.name, 'Прод API');
    expect(updates.single.graceSeconds, 120);
  });

  testWidgets('имя и допуск тоже правятся', (t) async {
    await _pump(t);
    await _openCard(t, 'Прод API');
    await t.tap(_editButton);
    await t.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await t.enterText(fields.at(0), 'Прод API v2');
    await t.enterText(fields.at(1), '300');
    await t.pump();
    await t.tap(_saveButton);
    await t.pumpAndSettle();

    expect(updates.single.name, 'Прод API v2');
    expect(updates.single.graceSeconds, 300);
  });

  testWidgets('пустое имя и нечисловой допуск не сохраняются', (t) async {
    await _pump(t);
    await _openCard(t, 'Прод API');
    await t.tap(_editButton);
    await t.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await t.enterText(fields.at(0), '   ');
    await t.pump();
    expect(t.widget<FilledButton>(_saveButton).onPressed, isNull);

    await t.enterText(fields.at(0), 'Прод API');
    await t.enterText(fields.at(1), 'abc');
    await t.pump();
    expect(t.widget<FilledButton>(_saveButton).onPressed, isNull);
  });

  // Монитор, заведённый через API с периодом не из пресетов: выпадашка с таким
  // начальным значением без отдельного пункта падала бы на проверке.
  testWidgets('период не из пресетов — диалог открывается и его показывает', (
    t,
  ) async {
    _monitors = [_monitor(id: 10, name: 'Прод API', periodSeconds: 120)];
    await _pump(t);
    await _openCard(t, 'Прод API');
    await t.tap(_editButton);
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('120 s'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('viewer кнопку не видит', (t) async {
    _roles = {10: 'viewer'};
    await _pump(t);
    await _openCard(t, 'Прод API');
    expect(_editButton, findsNothing);
  });

  // Период системного монитора — расписание серверного воркера.
  testWidgets('монитору, который ведёт сервер, кнопку не показываем', (
    t,
  ) async {
    _monitors = [
      _monitor(id: 11, name: 'Доставка на устройства', kind: 'pushHealth'),
    ];
    _roles = {11: 'owner'};
    await _pump(t);
    await _openCard(t, 'Доставка на устройства');
    expect(_editButton, findsNothing);
  });
}
