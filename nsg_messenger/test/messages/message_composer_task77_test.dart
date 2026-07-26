import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';

/// **TASK77 итер.1**: «/»-typeahead команд ботов в композере.
///
/// Механика — тот же оверлей, что у @-упоминаний (TASK16-A), поэтому здесь
/// проверяется ровно то, что у команд СВОЁ: узкий триггер (только «/» в
/// начале ввода), префиксная фильтрация, подстановка БЕЗ отправки и
/// отсутствие пустого попапа, когда подсказывать нечего.
void main() {
  final sendCalls = <String>[];

  Widget pumpComposer({
    List<RoomBotCommands>? botCommands,
    List<RoomParticipant>? participants,
  }) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      // Композер прижат к низу, как в реальном чате: оверлей подсказки
      // всплывает НАД полем, и в тесте с композером у верхней кромки он
      // оказался бы за пределами экрана (тап по пункту не доехал бы).
      body: Column(
        children: [
          const Spacer(),
          MessageComposer(
            onSend: (body, {mentionedMessengerUserIds, albumId}) async {
              sendCalls.add(body);
            },
            botCommands: botCommands,
            participants: participants,
          ),
        ],
      ),
    ),
  );

  RoomBotCommands bot(
    String name,
    Map<String, String> commands, {
    int id = 1,
  }) => RoomBotCommands(
    botMessengerUserId: id,
    botName: name,
    commands: [
      for (final e in commands.entries)
        BotCommand(command: e.key, description: e.value),
    ],
  );

  List<RoomBotCommands> deployBot() => [
    bot('deploy-bot', {
      'deploy': 'выкатить релиз',
      'status': 'статус сервисов',
      'rollback': 'откатить',
    }),
  ];

  /// Тап в поле + ввод текста (мышечная память mention-тестов: без фокуса
  /// подсказка не показывается намеренно).
  Future<void> type(WidgetTester tester, String text) async {
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  setUp(sendCalls.clear);

  testWidgets('«/» в начале ввода открывает оверлей со всеми командами', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(botCommands: deployBot()));
    await type(tester, '/');

    expect(find.byKey(kCommandTypeaheadPopupKey), findsOneWidget);
    expect(find.text('/deploy'), findsOneWidget);
    expect(find.text('/status'), findsOneWidget);
    expect(find.text('/rollback'), findsOneWidget);
    // Описание — вторая строка пункта; имя бота — контекст справа.
    expect(find.text('выкатить релиз'), findsOneWidget);
    expect(find.text('deploy-bot'), findsWidgets);
    // Заголовок объясняет, что это команды ботов, а не автодополнение текста.
    expect(find.text('Bot commands'), findsOneWidget);
  });

  testWidgets('фильтрация по префиксу: «/de» оставляет только /deploy', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(botCommands: deployBot()));
    await type(tester, '/de');

    expect(find.text('/deploy'), findsOneWidget);
    expect(find.text('/status'), findsNothing);
    expect(find.text('/rollback'), findsNothing);
  });

  testWidgets('фильтр — ПРЕФИКС, а не подстрока: «/loa» ничего не находит '
      'в /rollback (и оверлея нет)', (tester) async {
    await tester.pumpWidget(pumpComposer(botCommands: deployBot()));
    await type(tester, '/loa');

    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);
  });

  testWidgets('«/» ВНУТРИ текста не открывает оверлей (обычная переписка: '
      '«а/б», «км/ч», ссылки)', (tester) async {
    await tester.pumpWidget(pumpComposer(botCommands: deployBot()));

    for (final text in ['а/б', 'скорость км/', 'см. http://x/deploy']) {
      await type(tester, text);
      expect(
        find.byKey(kCommandTypeaheadPopupKey),
        findsNothing,
        reason: 'текст «$text» не должен открывать подсказку команд',
      );
    }
  });

  testWidgets('дописанные аргументы гасят подсказку: «/deploy prod»', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(botCommands: deployBot()));
    await type(tester, '/deploy prod');

    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);
  });

  testWidgets('тап по пункту подставляет «/команда » и НЕ отправляет', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(botCommands: deployBot()));
    await type(tester, '/de');

    await tester.tap(find.text('/deploy'));
    await tester.pumpAndSettle();

    // В поле — команда с пробелом, курсор в конце: пользователь дописывает
    // аргументы и отправляет сам.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '/deploy ');
    expect(field.controller!.selection.baseOffset, '/deploy '.length);
    expect(sendCalls, isEmpty, reason: 'выбор команды не отправляет сообщение');
    // Оверлей закрылся.
    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);
  });

  testWidgets('в комнате нет ботов → оверлея нет (молча, без пустого попапа)', (
    tester,
  ) async {
    await tester.pumpWidget(pumpComposer(botCommands: const []));
    await type(tester, '/');
    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);

    // И при вовсе не переданном списке (host-app не подключил фичу).
    await tester.pumpWidget(pumpComposer());
    await type(tester, '/');
    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);
  });

  testWidgets('бот есть, но команд не объявил → оверлея нет', (tester) async {
    await tester.pumpWidget(
      pumpComposer(botCommands: [bot('silent-bot', const {})]),
    );
    await type(tester, '/');
    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);
  });

  testWidgets('несколько ботов: видно, чья команда', (tester) async {
    await tester.pumpWidget(
      pumpComposer(
        botCommands: [
          bot('deploy-bot', {'deploy': 'выкатить'}, id: 1),
          bot('duty-bot', {'duty': 'кто дежурит'}, id: 2),
        ],
      ),
    );
    await type(tester, '/');

    expect(find.text('/deploy'), findsOneWidget);
    expect(find.text('/duty'), findsOneWidget);
    expect(find.text('deploy-bot'), findsOneWidget);
    expect(find.text('duty-bot'), findsOneWidget);
  });

  testWidgets('@-подсказка не сломана: «@» открывает mention-оверлей, а не '
      'command-оверлей', (tester) async {
    await tester.pumpWidget(
      pumpComposer(
        botCommands: deployBot(),
        participants: [
          RoomParticipant(
            messengerUserId: 5,
            matrixUserId: '@bob:localhost',
            displayName: 'Bob',
            role: RoomMemberRole.member,
          ),
        ],
      ),
    );
    await type(tester, '@Bo');

    expect(find.byKey(kMentionTypeaheadPopupKey), findsOneWidget);
    expect(find.byKey(kCommandTypeaheadPopupKey), findsNothing);
    expect(find.text('Bob'), findsOneWidget);
  });
}
