import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

import '../test_helpers.dart';

/// **TASK36 (admin panel для ботов)**: widget-тесты [BotsAdminScreen] —
/// список/пустое состояние, one-time показ токена при создании и ротации,
/// confirm перед ротацией, журнал аудита.
///
/// Ключевой инвариант, который тут фиксируется: **токен виден только в
/// момент выдачи**. В списке ботов его быть не должно, хотя модель [Bot]
/// его несёт — иначе экран стал бы местом, где credential подсматривают
/// через плечо.
void main() {
  Bot bot({
    int id = 1,
    String name = 'DeployBot',
    String caps = 'send_messages',
    bool enabled = true,
    String token = 'bot_secret_token',
  }) => Bot(
    id: id,
    messengerUserId: 100 + id,
    tenantId: 1,
    name: name,
    ownerEmail: 'owner@test.local',
    accessToken: token,
    capabilities: caps,
    enabled: enabled,
    createdAt: DateTime.utc(2026, 7, 1),
  );

  BotAuditEvent event({
    String action = 'created',
    String? actorEmail = 'admin@test.local',
    String? details,
  }) => BotAuditEvent(
    id: 1,
    botId: 1,
    action: action,
    actorEmail: actorEmail,
    details: details,
    createdAt: DateTime.utc(2026, 7, 1),
  );

  /// Fake-админка: все RPC — заглушки, интересующие тест переопределяются.
  NsgMessengerBotsAdmin makeAdmin({
    Future<List<Bot>> Function()? onList,
    Future<Bot> Function(String name, String caps, bool discoverable)? onCreate,
    Future<Bot> Function(int botId)? onRotate,
    Future<Bot> Function(int botId, bool enabled)? onSetEnabled,
    Future<List<BotAuditEvent>> Function(int botId)? onAudit,
  }) => NsgMessengerBotsAdmin.withRpcs(
    isBotAdminRpc: () async => true,
    listBotsRpc: ({required String tenantExternalKey}) =>
        onList?.call() ?? Future.value(const <Bot>[]),
    createBotRpc:
        ({
          required String tenantExternalKey,
          String? productExternalKey,
          required String name,
          required String ownerEmail,
          required String capabilities,
          required bool discoverable,
        }) =>
            onCreate?.call(name, capabilities, discoverable) ??
            Future.value(bot()),
    rotateBotTokenRpc: ({required int botId}) =>
        onRotate?.call(botId) ?? Future.value(bot()),
    setBotEnabledRpc: ({required int botId, required bool enabled}) =>
        onSetEnabled?.call(botId, enabled) ?? Future.value(bot()),
    addBotToRoomRpc: ({required int botId, required int roomId}) async {},
    listAuditEventsRpc: ({required int botId, required int limit}) =>
        onAudit?.call(botId) ?? Future.value(const <BotAuditEvent>[]),
  );

  testWidgets('пустой список → empty-state', (tester) async {
    await tester.pumpWidget(
      wrapL10n(BotsAdminScreen(adminOverride: makeAdmin())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No bots yet'), findsOneWidget);
  });

  testWidgets('список: имя, capabilities и владелец видны, токен — нет', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [
              bot(name: 'DeployBot', caps: 'send_messages,manage_room'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DeployBot'), findsOneWidget);
    expect(find.text('send_messages,manage_room'), findsOneWidget);
    expect(find.text('owner@test.local'), findsOneWidget);
    expect(
      find.textContaining('bot_secret_token'),
      findsNothing,
      reason: 'токен виден только в момент выдачи, не в списке',
    );
  });

  testWidgets('выключенный бот помечен бейджем', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(onList: () async => [bot(enabled: false)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('disabled'), findsOneWidget);
  });

  testWidgets('создание: диалог → токен показан один раз; дефолт — скрытый', (
    tester,
  ) async {
    String? createdWithCaps;
    bool? createdDiscoverable;
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onCreate: (name, caps, discoverable) async {
              createdWithCaps = caps;
              createdDiscoverable = discoverable;
              return bot(name: name, token: 'bot_fresh_token');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'NewBot');
    await tester.enterText(find.byType(TextField).last, 'me@test.local');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('bot_fresh_token'), findsOneWidget);
    expect(find.textContaining('Shown once'), findsOneWidget);
    expect(
      createdWithCaps,
      'send_messages',
      reason: 'дефолтный грант диалога уходит на сервер CSV-строкой',
    );
    expect(
      createdDiscoverable,
      false,
      reason: 'по умолчанию тумблер выключен — бот создаётся скрытым (#49)',
    );
  });

  testWidgets('создание: включённый тумблер видимости → discoverable=true', (
    tester,
  ) async {
    bool? createdDiscoverable;
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onCreate: (name, caps, discoverable) async {
              createdDiscoverable = discoverable;
              return bot(name: name, token: 'bot_fresh_token');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'NewBot');
    await tester.enterText(find.byType(TextField).last, 'me@test.local');
    await tester.pumpAndSettle();
    // Админка показывает тот же переключатель, что и «Мои боты» (#49).
    // В админском диалоге больше полей (email + 4 гранта), тумблер уходит
    // под нижний край — доскролливаем его в вид перед тапом.
    expect(find.text('Visible in search'), findsOneWidget);
    await tester.ensureVisible(find.text('Visible in search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visible in search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(
      createdDiscoverable,
      true,
      reason: 'осознанно включённый тумблер доходит до RPC создания',
    );
  });

  testWidgets('создание disabled, пока не выбран ни один грант', (tester) async {
    await tester.pumpWidget(
      wrapL10n(BotsAdminScreen(adminOverride: makeAdmin())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'NewBot');
    await tester.enterText(find.byType(TextField).last, 'me@test.local');
    await tester.pumpAndSettle();

    // Снимаем единственный проставленный по умолчанию грант.
    await tester.tap(find.text('Send messages'));
    await tester.pumpAndSettle();

    final createBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );
    expect(createBtn.onPressed, isNull);
  });

  testWidgets('создание disabled при email без @', (tester) async {
    await tester.pumpWidget(
      wrapL10n(BotsAdminScreen(adminOverride: makeAdmin())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'NewBot');
    await tester.enterText(find.byType(TextField).last, 'not-an-email');
    await tester.pumpAndSettle();

    final createBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );
    expect(createBtn.onPressed, isNull);
  });

  testWidgets('ротация: confirm обязателен, отмена не зовёт RPC', (
    tester,
  ) async {
    var rotateCalls = 0;
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [bot()],
            onRotate: (_) async {
              rotateCalls++;
              return bot(token: 'bot_rotated_token');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rotate token').last);
    await tester.pumpAndSettle();

    // Предупреждение о простое бота — самое важное в этом диалоге.
    expect(find.textContaining('stops working immediately'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(rotateCalls, 0);
  });

  testWidgets('ротация: подтверждение → новый токен показан один раз', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [bot()],
            onRotate: (_) async => bot(token: 'bot_rotated_token'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rotate token').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rotate token'));
    await tester.pumpAndSettle();

    expect(find.text('bot_rotated_token'), findsOneWidget);
  });

  testWidgets('журнал: события с человекочитаемым действием', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [bot()],
            onAudit: (_) async => [
              event(action: 'token_rotated', details: 'revokedTokens=1'),
              event(
                action: 'capability_denied',
                actorEmail: null,
                details: 'capability=manage_room; reason=missing_capability',
              ),
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

    expect(find.text('Token rotated'), findsOneWidget);
    expect(find.text('Action denied'), findsOneWidget);
    // Отказ инициирован ботом — в журнале это видно вместо email админа.
    expect(find.textContaining('the bot itself'), findsOneWidget);
  });

  testWidgets('журнал: created без инициатора — «система», не «сам бот»', (
    tester,
  ) async {
    // Боты-подпорки (Pulse, входящие webhook-и) заводит платформа, человека
    // за событием нет. Списать это на «сам бот» было бы враньём.
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => [bot()],
            onAudit: (_) async => [event(action: 'created', actorEmail: null)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit log').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('system'), findsOneWidget);
    expect(find.textContaining('the bot itself'), findsNothing);
  });

  testWidgets('журнал: пустое состояние', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(onList: () async => [bot()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit log').last);
    await tester.pumpAndSettle();

    expect(find.text('No events yet'), findsOneWidget);
  });

  testWidgets('ошибка загрузки списка → error-state, не краш', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        BotsAdminScreen(
          adminOverride: makeAdmin(
            onList: () async => throw StateError('boom'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Failed to load bots'), findsOneWidget);
  });
}
