/// **Экран не оставляет человека в тупике** — issue #135.
///
/// 13.08.2026 экран мониторинга перестал открываться и не открывался,
/// сколько ни пробуй; помог только перезапуск приложения. Человек при этом
/// видел `SocketException ... statusCode = -1` — сообщение, из которого
/// нельзя ни понять, что связи нет, ни что-либо сделать.
///
/// Обновление жестом под сообщением было и раньше, но на десктопе жеста нет
/// вовсе, а на телефоне о нём не догадываются, глядя на ошибку. Проверяется
/// здесь выход: причина словами и видимая кнопка.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_screen.dart';

final _now = DateTime.now().toUtc();

PulseMonitor _monitor() => PulseMonitor(
  id: 10,
  tenantId: 1,
  name: 'Монитор',
  kind: 'heartbeat',
  periodSeconds: 300,
  graceSeconds: 120,
  status: 'ok',
  paused: false,
  createdBy: 1,
  createdAt: _now,
);

NsgMessengerPulse _fake(Future<List<PulseMonitor>> Function() listMonitors) =>
    NsgMessengerPulse.withRpcs(
      statusStreamRpc: () => const Stream<PulseEvent>.empty(),
      listFoldersRpc: () async => const <PulseFolder>[],
      createFolderRpc: ({required String name, int? parentId}) =>
          throw UnimplementedError(),
      renameFolderRpc: ({required int id, required String name}) =>
          throw UnimplementedError(),
      deleteFolderRpc: ({required int id}) => throw UnimplementedError(),
      listMonitorsRpc: listMonitors,
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

Future<void> _pump(
  WidgetTester t,
  Future<List<PulseMonitor>> Function() listMonitors,
) async {
  t.view.physicalSize = const Size(500, 900);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: PulseScreen(pulseOverride: _fake(listMonitors)),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('мёртвая связь: причина словами и кнопка, а не исключение', (
    t,
  ) async {
    await _pump(t, () async => throw TimeoutException('20 c'));

    expect(
      find.text('Нет связи с сервером'),
      findsOneWidget,
      reason: 'человеку нужна причина, а не тип исключения',
    );
    expect(
      find.textContaining('TimeoutException'),
      findsNothing,
      reason: 'сделать с этим текстом человек ничего не может',
    );
    expect(
      find.widgetWithText(FilledButton, 'Повторить'),
      findsOneWidget,
      reason: 'без кнопки единственный выход — перезапуск приложения',
    );
  });

  testWidgets('кнопка действительно повторяет запрос', (t) async {
    // Кнопка, которая ничего не делает, хуже её отсутствия: она обещает
    // выход и не даёт его.
    var calls = 0;
    await _pump(t, () async {
      calls++;
      if (calls == 1) throw TimeoutException('первая попытка');
      return [_monitor()];
    });
    expect(calls, 1);

    await t.tap(find.widgetWithText(FilledButton, 'Повторить'));
    await t.pumpAndSettle();

    expect(calls, 2);
    expect(
      find.text('Нет связи с сервером'),
      findsNothing,
      reason: 'связь вернулась — экран обязан показать содержимое',
    );
    expect(find.text('Монитор'), findsOneWidget);
  });

  testWidgets('НЕтранспортный отказ: подробность остаётся', (t) async {
    // У предметной ошибки текст называет причину и помогает поддержке —
    // прятать его значило бы лечить симптом вместо беды.
    await _pump(t, () async => throw StateError('сервер вернул ерунду'));

    expect(find.text('Не удалось загрузить мониторинг'), findsOneWidget);
    expect(find.textContaining('сервер вернул ерунду'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Повторить'), findsOneWidget);
  });
}
