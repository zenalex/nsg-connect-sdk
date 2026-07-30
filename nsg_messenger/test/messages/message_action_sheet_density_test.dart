/// **issues #74 и #75 — меню действий сообщения.**
///
/// Со слов пользователя (#74): «нужно показывать внизу стрелочку, если всё
/// меню не показано сразу, т.к. если не знать, то не догадаешься о том,
/// что можно прокрутить меню». Со слов оператора поддержки (#75): «не
/// нужно такие большие пункты, уменьши расстояние между элементами
/// (особенно реакции). Тогда и всё меню влезет на экран».
///
/// Обе жалобы про одно: меню не помещается, и это никак не показано.
/// Здесь проверяется измеримое — что на типичном экране меню помещается
/// целиком, а на низком окне появляется подсказка о продолжении.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/message_action_sheet.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';

void main() {
  late MessagesController controller;

  setUp(() async {
    controller = MessagesController(
      roomId: 1,
      rpc: _FakeRpc(),
      events: const Stream<MessengerEvent>.empty(),
      selfMessengerUserId: 1,
      selfMatrixUserId: '@self:t',
    );
    await controller.init();
    addTearDown(controller.dispose);
  });

  ChatMessage msg() => ChatMessage(
    clientTxnId: null,
    matrixEventId: '\$ev1',
    senderMatrixUserId: '@a:t',
    senderMessengerUserId: 2,
    body: 'привет',
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
  );

  /// Полный набор пунктов — самый длинный шит, какой бывает: своё
  /// сообщение (Изменить/Удалить), можно закрепить, есть мультивыбор и
  /// упоминание.
  Widget app() => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showMessageActionSheet(
            context: ctx,
            message: msg(),
            isOwn: true,
            controller: controller,
            canPin: true,
            onSelectMessage: (_) {},
            onReplyWithMention: (_) {},
            onStartEdit: (_) {},
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  Future<void> openSheet(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder arrow() => find.byIcon(Icons.keyboard_arrow_down);

  bool arrowVisible(WidgetTester tester) =>
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(of: arrow(), matching: find.byType(AnimatedOpacity)),
          )
          .opacity >
      0;

  /// Сколько ещё можно прокрутить в шите. 0 — влезло целиком.
  double overflow(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .maxScrollExtent;

  testWidgets('на типичном телефоне полный набор помещается без прокрутки', (
    tester,
  ) async {
    // 360×800 — самый обычный Android. Именно про такой экран говорил
    // оператор: «тогда и всё меню влезет».
    await openSheet(tester, const Size(360, 800));
    expect(overflow(tester), 0, reason: 'меню должно влезать целиком');
    expect(arrowVisible(tester), isFalse, reason: 'нечего обещать');
  });

  testWidgets('на низком окне подсказка о продолжении появляется', (
    tester,
  ) async {
    // Невысокое окно на десктопе — исходный случай жалобы: нижние пункты
    // недостижимы, и об этом ничего не сказано.
    await openSheet(tester, const Size(900, 420));
    expect(overflow(tester), greaterThan(0), reason: 'иначе тест ни о чём');
    expect(arrowVisible(tester), isTrue);
  });

  testWidgets('подсказка исчезает, когда докрутили', (tester) async {
    await openSheet(tester, const Size(900, 420));
    await tester.drag(find.text('Reply'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(arrowVisible(tester), isFalse);
  });

  testWidgets('пункты стали плотнее', (tester) async {
    // Негативный свидетель на #75: без сжатия высота пункта — стандартные
    // 56 логических пикселей Material.
    await openSheet(tester, const Size(360, 800));
    final tile = tester.getSize(
      find.ancestor(of: find.text('Reply'), matching: find.byType(ListTile)),
    );
    expect(tile.height, lessThan(52));
  });

  testWidgets('ряд реакций не потерялся и остался нажимаемым', (tester) async {
    // Сжимали отступы и шрифт — сами реакции должны работать как раньше.
    await openSheet(tester, const Size(360, 800));
    for (final emoji in kQuickReactionEmojis) {
      expect(find.text(emoji), findsOneWidget);
    }
    await tester.tap(find.text('👍'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing, reason: 'шит закрылся');
  });
}

class _FakeRpc implements MessagesRpc {
  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: const []);

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const [];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const [];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const [];

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) async => '\$react1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
