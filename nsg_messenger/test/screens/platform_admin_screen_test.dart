import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

import '../test_helpers.dart';

/// **TASK78 п.3**: widget-тесты [PlatformAdminScreen] — список/пустое
/// состояние, one-time показ секрета (включая защиту от тапа мимо
/// диалога), grace-диалог ротации, confirm перед kill-switch, журнал.
///
/// Ключевой инвариант: **секрет виден только в момент выдачи** и диалог
/// с ним нельзя закрыть случайным тапом мимо — потерянный секрет не
/// восстановить (в БД только sha256).
void main() {
  ConnectTenantStatus tenant({
    String key = 'nsg',
    String name = 'NSG',
    bool enabled = true,
    bool hasSecret = true,
    DateTime? graceUntil,
  }) => ConnectTenantStatus(
    tenantExternalKey: key,
    tenantName: name,
    enabled: enabled,
    hasSecret: hasSecret,
    graceActiveUntil: graceUntil,
  );

  ConnectKeyAuditEvent event({
    String action = 'enabled_and_generated',
    String? actorEmail = 'admin@test.local',
    String? details,
  }) => ConnectKeyAuditEvent(
    id: 1,
    tenantId: 1,
    action: action,
    actorEmail: actorEmail,
    details: details,
    createdAt: DateTime.utc(2026, 7, 1),
  );

  /// Fake-админка: интересующие тест RPC переопределяются.
  NsgMessengerPlatformAdmin makeAdmin({
    Future<List<ConnectTenantStatus>> Function()? onList,
    Future<String> Function(String key)? onEnable,
    Future<String> Function(String key, int? graceSeconds)? onRotate,
    Future<void> Function(String key)? onDisable,
    Future<List<ConnectKeyAuditEvent>> Function(String key)? onAudit,
  }) => NsgMessengerPlatformAdmin.withRpcs(
    isPlatformAdminRpc: () async => true,
    listTenantsRpc: () =>
        onList?.call() ?? Future.value(const <ConnectTenantStatus>[]),
    enableAndGenerateRpc: ({required String tenantExternalKey}) =>
        onEnable?.call(tenantExternalKey) ?? Future.value('cst_default'),
    rotateSecretRpc: ({required String tenantExternalKey, int? graceSeconds}) =>
        onRotate?.call(tenantExternalKey, graceSeconds) ??
        Future.value('cst_default'),
    disableRpc: ({required String tenantExternalKey}) =>
        onDisable?.call(tenantExternalKey) ?? Future.value(),
    statusRpc: ({required String tenantExternalKey}) =>
        throw UnimplementedError(),
    listAuditEventsRpc:
        ({required String tenantExternalKey, required int limit}) =>
            onAudit?.call(tenantExternalKey) ??
            Future.value(const <ConnectKeyAuditEvent>[]),
  );

  testWidgets('пустой список → empty-state (и «нет доступа» тоже он — '
      'обвязка деградирует отказ в пусто)', (tester) async {
    await tester.pumpWidget(
      wrapL10n(PlatformAdminScreen(adminOverride: makeAdmin())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No tenants'), findsOneWidget);
  });

  testWidgets('список: имя, externalKey, статус и grace-строка видны', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        PlatformAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [
              tenant(
                key: 'titan112',
                name: 'Титан 112',
                graceUntil: DateTime.utc(2027, 1, 1, 12),
              ),
              tenant(key: 'off-t', name: 'Off', enabled: false, hasSecret: false),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Титан 112'), findsOneWidget);
    expect(find.text('titan112'), findsOneWidget);
    expect(find.textContaining('enabled · secret set'), findsOneWidget);
    expect(find.textContaining('previous secret valid until'), findsOneWidget);
    expect(find.textContaining('disabled · no secret'), findsOneWidget);
  });

  testWidgets('включение: секрет показан один раз + предупреждение; '
      'тап мимо диалога его НЕ закрывает', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        PlatformAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [
              tenant(key: 'fresh', enabled: false, hasSecret: false),
            ],
            onEnable: (key) async => 'cst_secret_once',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable & generate secret'));
    await tester.pumpAndSettle();

    expect(find.text('cst_secret_once'), findsOneWidget);
    expect(find.textContaining('shown ONCE'), findsOneWidget);

    // Случайный тап мимо диалога не должен терять секрет
    // (barrierDismissible: false).
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('cst_secret_once'), findsOneWidget);

    // Явное закрытие кнопкой — работает.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('cst_secret_once'), findsNothing);
  });

  testWidgets('ротация: диалог grace (дефолт 5 минут) → RPC получает '
      'секунды; новый секрет показан', (tester) async {
    int? seenGraceSeconds;
    await tester.pumpWidget(
      wrapL10n(
        PlatformAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [tenant()],
            onRotate: (key, graceSeconds) async {
              seenGraceSeconds = graceSeconds;
              return 'cst_rotated';
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rotate secret').last);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextField, '5'),
      findsOneWidget,
      reason: 'дефолтный grace — 5 минут',
    );
    await tester.enterText(find.byType(TextField), '30');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rotate secret'));
    await tester.pumpAndSettle();

    expect(seenGraceSeconds, 1800, reason: 'минуты диалога → секунды RPC');
    expect(find.text('cst_rotated'), findsOneWidget);
  });

  testWidgets('ротация: grace выше потолка (1440) блокирует кнопку', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        PlatformAdminScreen(adminOverride: makeAdmin(onList: () async => [tenant()])),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rotate secret').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2000');
    await tester.pumpAndSettle();

    final rotateBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Rotate secret'),
    );
    expect(rotateBtn.onPressed, isNull);
  });

  testWidgets('выключение: confirm обязателен, отмена не зовёт RPC', (
    tester,
  ) async {
    var disableCalls = 0;
    await tester.pumpWidget(
      wrapL10n(
        PlatformAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [tenant()],
            onDisable: (key) async {
              disableCalls++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disable').last);
    await tester.pumpAndSettle();

    // Предупреждение о kill-switch — самое важное в этом диалоге.
    expect(find.textContaining('loses access immediately'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(disableCalls, 0);

    // Подтверждение — RPC вызван.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disable').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Disable'));
    await tester.pumpAndSettle();
    expect(disableCalls, 1);
  });

  testWidgets('журнал: события с человекочитаемым действием; инициатор '
      'без email — «system»', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        PlatformAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [tenant()],
            onAudit: (key) async => [
              event(action: 'secret_rotated', details: 'grace=300s'),
              event(action: 'disabled', actorEmail: null),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit log').last);
    await tester.pumpAndSettle();

    expect(find.text('Secret rotated'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.textContaining('admin@test.local'), findsOneWidget);
    expect(find.textContaining('system'), findsOneWidget);
    expect(find.textContaining('grace=300s'), findsOneWidget);
  });
}
