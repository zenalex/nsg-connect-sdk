/// **Экран разрешённых целей** (TASK94 §2).
///
/// До него список правился только через API или прямо в базе: пилот завели
/// SQL-ом, и каждый следующий endpoint означал бы поход в psql.
///
/// Два случая, которые здесь важнее остальных: отказ сервера на запрещённый
/// адрес должен показывать ПРИЧИНУ (иначе человек ищет ошибку в своих руках),
/// а отсутствие прав — говорить «нет доступа», а не показывать пустой список,
/// который читается как «целей нет».
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_allowlist_screen.dart';

final _now = DateTime.utc(2026, 8, 10);

PulseProbeAllowlistEntry _entry(int id, String address, int port) =>
    PulseProbeAllowlistEntry(
      id: id,
      address: address,
      port: port,
      note: 'пилот',
      createdBy: 6,
      createdAt: _now,
    );

/// Что ушло на сервер — проверяем факт вызова, а не только отрисовку.
final removed = <int>[];
final added = <String>[];

NsgMessengerPulse _fake({
  required Future<List<PulseProbeAllowlistEntry>> Function() list,
  Future<PulseProbeAllowlistEntry> Function()? onAdd,
}) => NsgMessengerPulse.withRpcs(
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
  listProbeAllowlistRpc: list,
  addProbeAllowlistRpc:
      ({
        required String address,
        int? prefixLength,
        required int port,
        String? note,
      }) {
        added.add('$address:$port');
        return (onAdd ?? () async => _entry(2, address, port))();
      },
  removeProbeAllowlistRpc: ({required int id}) async => removed.add(id),
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

Future<void> _pump(WidgetTester t, NsgMessengerPulse pulse) async {
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: PulseAllowlistScreen(pulse: pulse),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    removed.clear();
    added.clear();
  });

  testWidgets('список показывает адрес, маску и порт', (t) async {
    await _pump(
      t,
      _fake(list: () async => [_entry(1, '78.37.191.63', 8896)]),
    );
    expect(find.text('78.37.191.63:8896'), findsOneWidget);
    expect(find.text('пилот'), findsOneWidget);
  });

  testWidgets('нет прав — «нет доступа», а не пустой список', (t) async {
    // Пустой список читается как «целей нет» и отправляет человека заводить
    // их заново; отказ должен быть отказом.
    await _pump(t, _fake(list: () async => throw Exception('denied')));
    expect(find.text('Разрешённых целей пока нет'), findsNothing);
    expect(find.textContaining('доступ'), findsWidgets);
  });

  testWidgets('удаление предупреждает, что мониторы не гаснут', (t) async {
    await _pump(
      t,
      _fake(list: () async => [_entry(1, '78.37.191.63', 8896)]),
    );
    await t.tap(find.byIcon(Icons.delete_outline));
    await t.pumpAndSettle();
    expect(find.textContaining('не гасятся'), findsOneWidget);

    await t.tap(find.text('Удалить'));
    await t.pumpAndSettle();
    expect(removed, [1]);
  });

  testWidgets('вставка списком: по штатному вызову на КАЖДУЮ цель', (t) async {
    // Запрос интегратора (issue #108): 13 пар «через штатный API с audit».
    // Пачкой одним вызовом нельзя — в журнале доступа должна остаться
    // запись на каждую строку, ровно как при ручном вводе.
    await _pump(t, _fake(list: () async => const <PulseProbeAllowlistEntry>[]));

    await t.tap(find.byIcon(Icons.playlist_add));
    await t.pumpAndSettle();
    await t.enterText(
      find.byType(TextField).first,
      '''
78.37.191.63:5077
78.37.191.63:8895
нежданчик
78.37.191.63:5077''',
    );
    await t.pumpAndSettle();

    // Разбор виден ДО отправки: две цели, одна битая строка, один дубль.
    expect(find.textContaining('Разобрано целей: 2'), findsOneWidget);
    expect(find.textContaining('Не разобрано строк: 1'), findsOneWidget);
    expect(find.text('нежданчик'), findsOneWidget);

    await t.tap(find.text('Создать'));
    await t.pumpAndSettle();

    expect(added, ['78.37.191.63:5077', '78.37.191.63:8895']);
  });

  testWidgets('вставка: отказ по одной цели не отменяет остальные', (t) async {
    // Список от заказчика почти всегда частично годен; заставлять его
    // вычищать ради одной строки — лишний круг переписки.
    var call = 0;
    await _pump(
      t,
      _fake(
        list: () async => const <PulseProbeAllowlistEntry>[],
        onAdd: () async {
          call++;
          if (call == 1) {
            throw ProbeTargetNotAllowedException(
              address: '127.0.0.1',
              reason: 'loopback',
            );
          }
          return _entry(9, '78.37.191.63', 8895);
        },
      ),
    );

    await t.tap(find.byIcon(Icons.playlist_add));
    await t.pumpAndSettle();
    await t.enterText(
      find.byType(TextField).first,
      '''
127.0.0.1:443
78.37.191.63:8895''',
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Создать'));
    await t.pumpAndSettle();

    expect(added, ['127.0.0.1:443', '78.37.191.63:8895']);
    expect(find.textContaining('Добавлено 1'), findsOneWidget);
    expect(find.textContaining('отклонено 1'), findsOneWidget);
  });

  testWidgets('запрещённый адрес — показываем ПРИЧИНУ отказа', (t) async {
    // Без причины человек ищет ошибку в своих руках, а она в том, что
    // `127.0.0.1` в список не попадёт никогда.
    await _pump(
      t,
      _fake(
        list: () async => const <PulseProbeAllowlistEntry>[],
        onAdd: () async => throw ProbeTargetNotAllowedException(
          address: '127.0.0.1',
          reason: 'loopback',
        ),
      ),
    );
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, '127.0.0.1');
    await t.pumpAndSettle();
    await t.tap(find.text('Создать'));
    await t.pumpAndSettle();

    expect(added, ['127.0.0.1:443']);
    expect(find.textContaining('loopback'), findsOneWidget);
  });
}
