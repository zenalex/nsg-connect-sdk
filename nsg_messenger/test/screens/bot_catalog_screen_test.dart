import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/bots/nsg_messenger_bot_catalog.dart';
import 'package:nsg_messenger/src/screens/bot_card_screen.dart';
import 'package:nsg_messenger/src/screens/bot_catalog_screen.dart';

import '../test_helpers.dart';

/// **TASK77 итер.3**: каталог «Добавить бота» и карточка бота.
///
/// Что здесь защищается:
///   * **режим чтения виден в каталоге** — это единственная причина, по
///     которой каталог показывает больше, чем имя: владелец чата решает,
///     пускать ли чужую программу, и «читает ВСЕ сообщения» должно
///     настораживать ДО подключения;
///   * команды и описание видны там же;
///   * «Подключить» зовёт RPC ровно с (botId, roomId); уже подключённый бот
///     кнопки не имеет (иначе повтор молча съедается no-op-ом, а снекбар
///     рапортует «подключён»);
///   * в карточке кнопки — по роли: «добавить в чат…» нет, когда caller
///     нигде не админ; «отключить» — только когда он админ ЭТОГО чата и бот
///     в нём состоит.
void main() {
  AvailableBot availableBot({
    int botId = 1,
    String name = 'deploy-bot',
    String? description = 'Сообщает о деплоях',
    String readMode = NsgMessengerBotCatalog.readModeAddressed,
    List<BotCommand> commands = const <BotCommand>[],
    bool inRoom = false,
    String? ownerDisplayName,
  }) => AvailableBot(
    botId: botId,
    messengerUserId: 100 + botId,
    name: name,
    // avatarUrl намеренно null: NsgAvatarImage за картинкой полез бы в
    // MessengerRuntime.client, которого в widget-тесте нет.
    avatarUrl: null,
    description: description,
    ownerEmail: 'owner@test.local',
    ownerDisplayName: ownerDisplayName,
    commands: commands,
    readMode: readMode,
    discoverable: true,
    inRoom: inRoom,
  );

  RoomSummary room(int id, String name) => RoomSummary(
    id: id,
    name: name,
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
  );

  /// Fake каталога: все RPC — заглушки, интересующие тест переопределяются.
  NsgMessengerBotCatalog makeCatalog({
    Future<List<AvailableBot>> Function(int? roomId)? onList,
    Future<AvailableBot?> Function(int botMessengerUserId)? onCard,
    Future<List<RoomSummary>> Function()? onAdminRooms,
    Future<void> Function(int botId, int roomId)? onAdd,
    Future<void> Function(int botId, int roomId)? onRemove,
  }) => NsgMessengerBotCatalog.withRpcs(
    listAvailableBotsRpc: ({int? roomId}) =>
        onList?.call(roomId) ?? Future.value(const <AvailableBot>[]),
    getBotCardRpc: ({required int botMessengerUserId, int? roomId}) =>
        onCard?.call(botMessengerUserId) ?? Future.value(null),
    listMyAdminRoomsRpc: ({required int limit}) =>
        onAdminRooms?.call() ?? Future.value(const <RoomSummary>[]),
    addBotToMyRoomRpc: ({required int botId, required int roomId}) =>
        onAdd?.call(botId, roomId) ?? Future.value(),
    removeBotFromMyRoomRpc: ({required int botId, required int roomId}) =>
        onRemove?.call(botId, roomId) ?? Future.value(),
  );

  group('BotCatalogScreen', () {
    testWidgets('пустой каталог объясняет, почему он пуст', (tester) async {
      await tester.pumpWidget(
        wrapL10n(BotCatalogScreen(roomId: 5, catalogOverride: makeCatalog())),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No public bots yet'), findsOneWidget);
    });

    testWidgets('запись каталога показывает режим чтения, команды и описание',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCatalogScreen(
            roomId: 5,
            catalogOverride: makeCatalog(
              onList: (_) async => [
                availableBot(
                  commands: [
                    BotCommand(command: 'deploy', description: 'статус'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('deploy-bot'), findsOneWidget);
      expect(find.text('Сообщает о деплоях'), findsOneWidget);
      expect(
        find.textContaining('Reads only messages addressed to it'),
        findsOneWidget,
        reason: 'trust-сигнал обязан быть в каталоге, а не только в карточке',
      );
      expect(find.textContaining('/deploy'), findsOneWidget);
    });

    testWidgets('«читает ВСЕ сообщения» показано и подсвечено error-цветом',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCatalogScreen(
            roomId: 5,
            catalogOverride: makeCatalog(
              onList: (_) async => [
                availableBot(readMode: NsgMessengerBotCatalog.readModeAll),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = find.textContaining('Reads ALL messages');
      expect(finder, findsOneWidget);
      final context = tester.element(finder);
      final text = tester.widget<Text>(finder);
      expect(
        text.style?.color,
        Theme.of(context).colorScheme.error,
        reason: 'настораживающий режим должен выглядеть настораживающе',
      );
    });

    testWidgets('«Подключить» зовёт addBotToMyRoom с (botId, roomId)',
        (tester) async {
      (int, int)? seen;
      await tester.pumpWidget(
        wrapL10n(
          BotCatalogScreen(
            roomId: 42,
            catalogOverride: makeCatalog(
              onList: (_) async => [availableBot(botId: 7)],
              onAdd: (botId, roomId) async => seen = (botId, roomId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(seen, (7, 42));
    });

    testWidgets('бот уже в чате → кнопки подключения нет, стоит метка',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCatalogScreen(
            roomId: 5,
            catalogOverride: makeCatalog(
              onList: (_) async => [availableBot(inRoom: true)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect'), findsNothing);
      expect(find.text('Already added'), findsOneWidget);
    });

    testWidgets('ошибка загрузки → сообщение, не краш', (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCatalogScreen(
            roomId: 5,
            catalogOverride: makeCatalog(
              onList: (_) async => throw Exception('boom'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not load the bot catalog'),
        findsOneWidget,
      );
    });

    testWidgets('тап по записи открывает карточку бота', (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCatalogScreen(
            roomId: 5,
            catalogOverride: makeCatalog(
              onList: (_) async => [availableBot()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('deploy-bot'));
      await tester.pumpAndSettle();
      expect(find.byType(BotCardScreen), findsOneWidget);
    });
  });

  group('BotCardScreen', () {
    testWidgets('карточка: владелец, описание, команды и режим чтения крупно',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 101,
            catalogOverride: makeCatalog(
              onCard: (_) async => availableBot(
                ownerDisplayName: 'Бот-Мастер',
                readMode: NsgMessengerBotCatalog.readModeAll,
                commands: [
                  BotCommand(command: 'status', description: 'что нового'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Owner: Бот-Мастер'), findsOneWidget);
      expect(find.text('Сообщает о деплоях'), findsOneWidget);
      expect(find.text('/status'), findsOneWidget);
      expect(find.textContaining('Reads ALL messages'), findsOneWidget);
      expect(
        find.textContaining('The bot sees every message'),
        findsOneWidget,
        reason: 'в карточке режим показывается «крупно» — с пояснением',
      );
    });

    testWidgets('владелец без отображаемого имени → показываем email',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 101,
            catalogOverride: makeCatalog(onCard: (_) async => availableBot()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Owner: owner@test.local'), findsOneWidget);
    });

    testWidgets('бот не виден caller-у (null) → честное «недоступен»',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 999,
            catalogOverride: makeCatalog(onCard: (_) async => null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('not available'), findsOneWidget);
    });

    testWidgets('нет чатов, где caller админ → кнопок управления нет',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 101,
            roomId: 5,
            initialBot: availableBot(inRoom: true),
            catalogOverride: makeCatalog(
              onAdminRooms: () async => const <RoomSummary>[],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Add to a chat'), findsNothing);
      expect(
        find.text('Disconnect from this chat'),
        findsNothing,
        reason: 'кнопка, которая ответит отказом, — это враньё про права',
      );
    });

    testWidgets('caller админ этого чата и бот в нём → есть «отключить»',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 101,
            roomId: 5,
            initialBot: availableBot(inRoom: true),
            catalogOverride: makeCatalog(
              onAdminRooms: () async => [room(5, 'Моя группа')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Add to a chat'), findsOneWidget);
      expect(find.text('Disconnect from this chat'), findsOneWidget);
    });

    testWidgets('бот в чате есть, но caller там не админ → «отключить» скрыт',
        (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 101,
            roomId: 5,
            initialBot: availableBot(inRoom: true),
            // Админ в другом чате — значит «добавить в чат…» уместно, а
            // «отключить от ЭТОГО чата» — нет.
            catalogOverride: makeCatalog(
              onAdminRooms: () async => [room(9, 'Другая группа')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Add to a chat'), findsOneWidget);
      expect(find.text('Disconnect from this chat'), findsNothing);
    });

    testWidgets('«отключить» требует подтверждения и зовёт RPC с (botId, room)',
        (tester) async {
      (int, int)? seen;
      await tester.pumpWidget(
        wrapL10n(
          BotCardScreen(
            botMessengerUserId: 108,
            roomId: 5,
            initialBot: availableBot(botId: 8, inRoom: true),
            catalogOverride: makeCatalog(
              onAdminRooms: () async => [room(5, 'Моя группа')],
              onCard: (_) async => availableBot(botId: 8),
              onRemove: (botId, roomId) async => seen = (botId, roomId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disconnect from this chat'));
      await tester.pumpAndSettle();
      // Диалог открыт — RPC ещё не звали.
      expect(seen, isNull);
      await tester.tap(find.text('Disconnect').last);
      await tester.pumpAndSettle();
      expect(seen, (8, 5));
    });
  });
}
