import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

import '../test_helpers.dart';

/// **Issue #49**: widget-тесты [MyBotsScreen] — по образцу
/// bots_admin_screen_test: объясняющее пустое состояние, one-time показ
/// токена, диалог создания БЕЗ email-поля и С переключателем видимости,
/// человекочитаемый лимит, комнаты бота с отзывом.
///
/// Инвариант тот же, что в админке: **токен виден только в момент
/// выдачи** — в списке его нет, хотя модель [Bot] его несёт.
void main() {
  Bot bot({
    int id = 1,
    String name = 'MyBot',
    String caps = 'send_messages',
    bool enabled = true,
    bool discoverable = false,
    String token = 'bot_secret_token',
    // TASK77 итер.2: `null` = бот эпохи до итер.2 → grandfathered read_all.
    String? readMode,
    // TASK77 итер.3: описание для каталога/карточки.
    String? description,
  }) => Bot(
    id: id,
    messengerUserId: 100 + id,
    tenantId: 1,
    name: name,
    ownerEmail: 'me@test.local',
    accessToken: token,
    capabilities: caps,
    enabled: enabled,
    discoverable: discoverable,
    readMode: readMode,
    description: description,
    createdAt: DateTime.utc(2026, 7, 20),
  );

  RoomSummary room(int id, String name) => RoomSummary(
    id: id,
    name: name,
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  /// Fake «Мои боты»: все RPC — заглушки, интересующие тест
  /// переопределяются.
  NsgMessengerMyBots makeMyBots({
    Future<List<Bot>> Function()? onList,
    Future<Bot> Function(String name, String caps, bool discoverable)?
        onCreate,
    Future<Bot> Function(int botId)? onRotate,
    Future<Bot> Function(int botId, bool discoverable)? onSetDiscoverable,
    // TASK77 итер.2: смена режима чтения. TASK77 итер.3: ответ несёт ещё и
    // число подписок, к которым privacy mode не применяется.
    Future<BotReadModeResult> Function(int botId, String readMode)?
    onSetReadMode,
    // TASK77 итер.3: описание бота для каталога/карточки.
    Future<Bot> Function(int botId, String description)? onSetDescription,
    Future<List<RoomSummary>> Function(int botId)? onListRooms,
    Future<void> Function(int botId, int roomId)? onRemoveFromRoom,
    Future<List<BotAuditEvent>> Function(int botId)? onAudit,
  }) => NsgMessengerMyBots.withRpcs(
    listRpc: () => onList?.call() ?? Future.value(const <Bot>[]),
    createRpc:
        ({
          required String name,
          required String capabilities,
          required bool discoverable,
          required String readMode,
        }) =>
            onCreate?.call(name, capabilities, discoverable) ??
            Future.value(bot()),
    rotateTokenRpc: ({required int botId}) =>
        onRotate?.call(botId) ?? Future.value(bot()),
    setEnabledRpc: ({required int botId, required bool enabled}) async =>
        bot(enabled: enabled),
    setDiscoverableRpc: ({required int botId, required bool discoverable}) =>
        onSetDiscoverable?.call(botId, discoverable) ??
        Future.value(bot(discoverable: discoverable)),
    setReadModeRpc: ({required int botId, required String readMode}) =>
        onSetReadMode?.call(botId, readMode) ??
        Future.value(
          BotReadModeResult(
            bot: bot(readMode: readMode),
            unboundSubscriptionCount: 0,
          ),
        ),
    setDescriptionRpc:
        ({required int botId, required String description}) =>
            onSetDescription?.call(botId, description) ??
            Future.value(bot(description: description)),
    listRoomsRpc: ({required int botId}) =>
        onListRooms?.call(botId) ?? Future.value(const <RoomSummary>[]),
    removeFromRoomRpc: ({required int botId, required int roomId}) =>
        onRemoveFromRoom?.call(botId, roomId) ?? Future.value(),
    listAuditEventsRpc: ({required int botId, required int limit}) =>
        onAudit?.call(botId) ?? Future.value(const <BotAuditEvent>[]),
  );

  testWidgets('пустое состояние объясняет, что такое бот', (tester) async {
    await tester.pumpWidget(
      wrapL10n(MyBotsScreen(myBotsOverride: makeMyBots())),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A bot is a program'),
      findsOneWidget,
      reason: 'экран виден всем — пустое состояние должно объяснять',
    );
  });

  testWidgets('список: имя и capabilities видны, токен — нет; '
      'discoverable-бот помечен бейджем', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [
              bot(name: 'PublicBot', discoverable: true),
              bot(id: 2, name: 'HiddenBot', enabled: false),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PublicBot'), findsOneWidget);
    expect(find.text('HiddenBot'), findsOneWidget);
    expect(find.text('in search'), findsOneWidget);
    expect(find.text('disabled'), findsOneWidget);
    expect(
      find.textContaining('bot_secret_token'),
      findsNothing,
      reason: 'токен виден только в момент выдачи, не в списке',
    );
  });

  // **TASK77 итер.2**: владелец должен видеть, что его бот читает, ДО того
  // как позовёт его в чужой чат.
  testWidgets('режим чтения виден в тайле: grandfathered → «читает ВСЕ», '
      'read_addressed → «только обращения»', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [
              bot(name: 'LegacyBot'),
              bot(id: 2, name: 'PrivateBot', readMode: 'read_addressed'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reads ALL messages'), findsOneWidget);
    expect(find.text('Reads only messages addressed to it'), findsOneWidget);
  });

  // **TASK77 итер.3 (закрытие follow-up-а итер.2)**: приватность на
  // push-пути работает только у подписок, привязанных к боту. Если сервер
  // сообщил о непривязанных, владелец обязан узнать это в момент
  // переключения — молчание означало бы «включил приватность», которой нет.
  testWidgets('сужение режима + непривязанные подписки → предупреждение, '
      'что приватность подействует не полностью', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [bot(name: 'LegacyBot')],
            onSetReadMode: (botId, readMode) async => BotReadModeResult(
              bot: bot(id: botId, readMode: readMode),
              unboundSubscriptionCount: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Limit reading to messages addressed to it').last,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Privacy will not apply everywhere'),
      findsOneWidget,
      reason: 'умолчать про подписки, обходящие режим, нельзя',
    );
    expect(find.textContaining('2 event subscriptions'), findsOneWidget);
  });

  testWidgets('расширение до read_all: предупреждения о подписках нет — '
      'при «читает всё» фильтровать всё равно нечего', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [bot(id: 2, readMode: 'read_addressed')],
            onSetReadMode: (botId, readMode) async => BotReadModeResult(
              bot: bot(id: botId, readMode: readMode),
              unboundSubscriptionCount: 5,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow reading all messages').last);
    await tester.pumpAndSettle();
    // confirm «бот будет читать всё»
    await tester.tap(find.text('Allow reading all messages').last);
    await tester.pumpAndSettle();

    expect(find.text('Privacy will not apply everywhere'), findsNothing);
  });

  // **TASK77 итер.3**: описание — тот самый текст, который прочитают в
  // каталоге ботов, решая, пускать ли программу в свою группу.
  testWidgets('описание: отсутствие видно в тайле, диалог сохраняет текст',
      (tester) async {
    (int, String)? seen;
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [bot(id: 3)],
            onSetDescription: (botId, description) async {
              seen = (botId, description);
              return bot(id: botId, description: description);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No description'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit description').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Watches CI');
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    expect(seen, (3, 'Watches CI'));
  });

  testWidgets('создание: режим чтения по умолчанию — «только обращения» '
      '(privacy by default)', (tester) async {
    await tester.pumpWidget(
      wrapL10n(MyBotsScreen(myBotsOverride: makeMyBots())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();

    expect(find.text('What the bot reads'), findsOneWidget);
    // Выбран приватный режим: иконка «включённого» radio — ровно одна, и
    // стоит она у «только обращения» (проверяем по тексту рядом).
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    final checkedTile = find.ancestor(
      of: find.byIcon(Icons.radio_button_checked),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(
        of: checkedTile,
        matching: find.text('Reads only messages addressed to it'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('создание: без email-поля, с переключателем видимости; '
      'токен показан один раз', (tester) async {
    (String, String, bool)? created;
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onCreate: (name, caps, discoverable) async {
              created = (name, caps, discoverable);
              return bot(name: name, token: 'bot_fresh_token');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();

    expect(
      find.byType(TextField),
      findsOneWidget,
      reason: 'email владельца не спрашиваем — владелец всегда caller',
    );
    expect(find.text('Visible in search'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'NewBot');
    await tester.pumpAndSettle();
    // Делаем бота публичным — флаг должен дойти до RPC.
    await tester.tap(find.text('Visible in search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(created, ('NewBot', 'send_messages', true));
    expect(find.text('bot_fresh_token'), findsOneWidget);
    expect(find.textContaining('Shown once'), findsOneWidget);
  });

  testWidgets('лимит: BotLimitExceededException → человекочитаемый снекбар',
      (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onCreate: (_, _, _) async =>
                throw BotLimitExceededException(limit: 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'OneTooMany');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bot limit reached (10)'), findsOneWidget);
    expect(
      find.textContaining('Shown once'),
      findsNothing,
      reason: 'токен-диалога при отказе быть не должно',
    );
  });

  testWidgets('ротация: confirm → новый токен показан один раз', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
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
    expect(find.textContaining('stops working immediately'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Rotate token'));
    await tester.pumpAndSettle();

    expect(find.text('bot_rotated_token'), findsOneWidget);
  });

  testWidgets('видимость: пункт меню зовёт setDiscoverable с инверсией', (
    tester,
  ) async {
    (int, bool)? seen;
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [bot(discoverable: false)],
            onSetDiscoverable: (botId, discoverable) async {
              seen = (botId, discoverable);
              return bot(discoverable: discoverable);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show in search').last);
    await tester.pumpAndSettle();

    expect(seen, (1, true));
  });

  testWidgets('комнаты бота: список + отзыв с confirm', (tester) async {
    (int, int)? removed;
    var rooms = <RoomSummary>[room(27, 'проект NEXUS'), room(28, 'support')];
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [bot()],
            onListRooms: (_) async => rooms,
            onRemoveFromRoom: (botId, roomId) async {
              removed = (botId, roomId);
              rooms = rooms.where((r) => r.id != roomId).toList();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Bot's chats").last);
    await tester.pumpAndSettle();

    expect(find.text('проект NEXUS'), findsOneWidget);
    expect(find.text('support'), findsOneWidget);

    // Отзыв: у каждой строки своя кнопка; берём первую (NEXUS).
    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();
    expect(find.text('Remove bot from this chat?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(removed, (1, 27));
    expect(
      find.text('проект NEXUS'),
      findsNothing,
      reason: 'после отзыва список перезагружается без комнаты',
    );
    expect(find.text('support'), findsOneWidget);
  });

  testWidgets('комнаты бота: пустое состояние', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(onList: () async => [bot()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Bot's chats").last);
    await tester.pumpAndSettle();

    expect(find.text('The bot is not in any chats yet'), findsOneWidget);
  });

  testWidgets('журнал: новые действия #49 — человекочитаемые ярлыки', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => [bot()],
            onAudit: (_) async => [
              BotAuditEvent(
                id: 1,
                botId: 1,
                action: 'removed_from_room',
                actorEmail: 'me@test.local',
                details: 'roomId=27',
                createdAt: DateTime.utc(2026, 7, 20),
              ),
              BotAuditEvent(
                id: 2,
                botId: 1,
                action: 'discoverable_enabled',
                actorEmail: 'me@test.local',
                createdAt: DateTime.utc(2026, 7, 20),
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

    expect(find.text('Removed from a chat'), findsOneWidget);
    expect(find.text('Made visible in search'), findsOneWidget);
  });

  testWidgets('ошибка загрузки списка → error-state, не краш', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        MyBotsScreen(
          myBotsOverride: makeMyBots(
            onList: () async => throw StateError('boom'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Failed to load bots'), findsOneWidget);
  });
}
