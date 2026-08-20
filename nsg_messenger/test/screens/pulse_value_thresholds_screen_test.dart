/// **Экран порогов по значению** (issue #116).
///
/// Число, присланное в beat, само по себе бесполезно: ценность в правиле,
/// которое превращает его в статус. Здесь проверяется то, что делает это
/// правило заводимым без ошибок — и то, что экран не притворяется
/// настроенным, когда настроено ничего.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_value_thresholds_screen.dart';

final _saved = <String>[];
final _removed = <String>[];

PulseValueThreshold _t({
  required String name,
  double? warnBelow,
  double? errorBelow,
  double? warnAbove,
  double? errorAbove,
}) => PulseValueThreshold(
  id: 1,
  monitorId: 7,
  name: name,
  warnBelow: warnBelow,
  errorBelow: errorBelow,
  warnAbove: warnAbove,
  errorAbove: errorAbove,
  createdAt: DateTime.utc(2026, 8, 12),
);

NsgMessengerPulse _fake(List<PulseValueThreshold> thresholds) =>
    NsgMessengerPulse.withRpcs(
      statusStreamRpc: () => const Stream<PulseEvent>.empty(),
      listFoldersRpc: () async => const <PulseFolder>[],
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
      listTlsProbesRpc: () async => const <PulseTlsProbe>[],
      listProbeAllowlistRpc: () async => const <PulseProbeAllowlistEntry>[],
      addProbeAllowlistRpc:
          ({
            required String address,
            int? prefixLength,
            required int port,
            String? note,
          }) => throw UnimplementedError(),
      removeProbeAllowlistRpc: ({required int id}) => throw UnimplementedError(),
      getTlsProbeRpc: ({required int monitorId}) => throw UnimplementedError(),
      runProbeNowRpc: ({required int monitorId}) => throw UnimplementedError(),
      listValueThresholdsRpc: ({required int monitorId}) async => thresholds,
      setValueThresholdRpc:
          ({
            required int monitorId,
            required String name,
            double? warnBelow,
            double? errorBelow,
            double? warnAbove,
            double? errorAbove,
          }) async {
            _saved.add('$name w<$warnBelow e<$errorBelow w>$warnAbove e>$errorAbove');
            return _t(name: name);
          },
      removeValueThresholdRpc:
          ({required int monitorId, required String name}) async =>
              _removed.add(name),
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
      listMyAccessRpc: () async => const <PulseAccessEntry>[],
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
  WidgetTester t, {
  List<PulseValueThreshold> thresholds = const [],
  Map<String, num> lastValues = const {},
}) async {
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: PulseValueThresholdsScreen(
        pulse: _fake(thresholds),
        monitorId: 7,
        monitorName: 'Серверная',
        lastValues: lastValues,
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    _saved.clear();
    _removed.clear();
  });

  testWidgets('присланное число видно и без порога', (t) async {
    // Число без правила — приглашение это правило завести, а не пустая
    // строка: человек должен видеть, что данные уже идут.
    await _pump(t, lastValues: {'temp_c': 22.4});
    expect(find.text('temp_c'), findsOneWidget);
    expect(find.text('22.4'), findsOneWidget);
    expect(find.textContaining('порога нет'), findsOneWidget);
  });

  testWidgets('порог без числа тоже показан — имя могли написать с ошибкой',
      (t) async {
    // Порог на `tempc`, а датчик шлёт `temp_c`: молча спрятать такую строку
    // значит оставить человека с правилом, которое никогда не сработает.
    await _pump(
      t,
      thresholds: [_t(name: 'tempc', errorAbove: 30)],
      lastValues: {'temp_c': 22},
    );
    expect(find.text('tempc'), findsOneWidget);
    expect(find.text('temp_c'), findsOneWidget);
  });

  testWidgets('порог без единой границы завести нельзя', (t) async {
    // Иначе на экране появится «порог настроен» там, где не настроено
    // ничего, и молчание будет выглядеть исправностью.
    await _pump(t, lastValues: {'temp_c': 22});
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'temp_c');
    await t.pumpAndSettle();

    final create = find.widgetWithText(FilledButton, 'Создать');
    expect(t.widget<FilledButton>(create).onPressed, isNull);
    expect(_saved, isEmpty);
  });

  testWidgets('границы уходят на сервер как есть', (t) async {
    await _pump(t, lastValues: {'temp_c': 22});
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'temp_c');
    // Поля идут в порядке «красный ниже, жёлтый ниже, жёлтый выше, красный
    // выше» — от худшего снизу к худшему сверху.
    await t.enterText(find.byType(TextField).at(3), '27');
    await t.enterText(find.byType(TextField).at(4), '35');
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Создать'));
    await t.pumpAndSettle();

    expect(_saved.single, contains('temp_c'));
    expect(_saved.single, contains('w>27.0'));
    expect(_saved.single, contains('e>35.0'));
  });
}
