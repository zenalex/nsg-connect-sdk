import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';
import 'package:nsg_messenger/src/screens/pulse_members_screen.dart';

import '../test_helpers.dart';

/// **TASK79 п.9**: состав участников и скрытие кнопок по роли.
///
/// Это не дублирование серверных гейтов, а проверка второго обещания UI:
/// пользователь не должен видеть кнопку, которая ему всё равно откажет.
/// Сам отказ покрыт интеграционно на сервере.
void main() {
  PulseMemberView member({
    required int id,
    required String role,
    String? name,
    bool inherited = false,
  }) => PulseMemberView(
    messengerUserId: id,
    displayName: name ?? 'user$id',
    role: role,
    inherited: inherited,
    inheritedFromFolderId: inherited ? 7 : null,
  );

  /// Fake-обёртка Пульса: реальные RPC не нужны, экран берёт только
  /// `listMembers`/`setMember`/`removeMember`.
  NsgMessengerPulse fakePulse({
    required List<PulseMemberView> members,
    void Function(int muid, String role)? onSet,
    void Function(int muid)? onRemove,
  }) => NsgMessengerPulse.withRpcs(
    statusStreamRpc: () => const Stream<PulseEvent>.empty(),
    listFoldersRpc: () async => const [],
    createFolderRpc: ({required String name, int? parentId}) =>
        throw UnimplementedError(),
    renameFolderRpc: ({required int id, required String name}) =>
        throw UnimplementedError(),
    deleteFolderRpc: ({required int id}) => throw UnimplementedError(),
    listMonitorsRpc: () async => const [],
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
    deleteMonitorRpc: ({required int id}) => throw UnimplementedError(),
    listRulesRpc: () async => const [],
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
    listIncidentsRpc: ({required int monitorId, required int limit}) async =>
        const [],
    ackIncidentRpc: ({required int incidentId}) => throw UnimplementedError(),
    listMyAccessRpc: () async => const [],
    listMembersRpc: ({int? folderId, int? monitorId}) async => members,
    setMemberRpc:
        ({
          int? folderId,
          int? monitorId,
          required int messengerUserId,
          required String role,
        }) async => onSet?.call(messengerUserId, role),
    removeMemberRpc:
        ({int? folderId, int? monitorId, required int messengerUserId}) async =>
            onRemove?.call(messengerUserId),
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<PulseMemberView> members,
    required bool canManage,
  }) async {
    await tester.pumpWidget(
      wrapL10n(
        PulseMembersScreen(
          pulse: fakePulse(members: members),
          monitorId: 1,
          title: 'Прод API',
          canManage: canManage,
        ),
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('owner видит кнопку добавления и меню участника', (tester) async {
    await pumpScreen(
      tester,
      members: [
        member(id: 1, role: 'owner'),
        member(id: 2, role: 'viewer'),
      ],
      canManage: true,
    );

    expect(find.text('Добавить участника'), findsOneWidget);
    expect(
      find.byIcon(Icons.more_vert),
      findsNWidgets(2),
      reason: 'меню у каждого прямого участника',
    );
  });

  testWidgets('не-владелец видит список, но не может им управлять', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      members: [
        member(id: 1, role: 'owner'),
        member(id: 2, role: 'viewer'),
      ],
      canManage: false,
    );

    expect(find.text('user1'), findsOneWidget);
    expect(find.text('user2'), findsOneWidget);
    expect(
      find.text('Добавить участника'),
      findsNothing,
      reason: 'состав меняет только владелец',
    );
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('унаследованное членство read-only даже у владельца', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      members: [
        member(id: 1, role: 'owner'),
        member(id: 2, role: 'viewer', inherited: true),
      ],
      canManage: true,
    );

    // Убирать участника надо в папке-предке: кнопка «удалить» здесь молча
    // не сработала бы, а это худший вид неработающей кнопки.
    expect(find.textContaining('Унаследовано от папки'), findsOneWidget);
    expect(
      find.byIcon(Icons.more_vert),
      findsOneWidget,
      reason: 'меню только у прямого участника',
    );
  });

  testWidgets('пустой список показывает пустое состояние', (tester) async {
    await pumpScreen(tester, members: const [], canManage: true);
    expect(find.text('Участников пока нет'), findsOneWidget);
  });

  testWidgets('отзыв доступа уходит на сервер после подтверждения', (
    tester,
  ) async {
    int? removed;
    await tester.pumpWidget(
      wrapL10n(
        PulseMembersScreen(
          pulse: fakePulse(
            members: [
              member(id: 1, role: 'owner'),
              member(id: 2, role: 'viewer'),
            ],
            onRemove: (muid) => removed = muid,
          ),
          monitorId: 1,
          canManage: true,
        ),
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отозвать доступ').last);
    await tester.pumpAndSettle();

    expect(removed, isNull, reason: 'без подтверждения ничего не уходит');

    await tester.tap(find.widgetWithText(FilledButton, 'Отозвать доступ'));
    await tester.pumpAndSettle();
    expect(removed, 2);
  });
}
