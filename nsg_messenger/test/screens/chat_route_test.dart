import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/screens/chat_route.dart';

/// **Issue #41**: единое имя маршрута чата — на нём держится дедуп открытых
/// чатов. Формат раньше был продублирован по местам открытия; тест
/// фиксирует его как контракт.
void main() {
  test('chatRouteName — стабильный формат', () {
    expect(chatRouteName(1), 'chat/1');
    expect(chatRouteName(4242), 'chat/4242');
    expect(chatRouteName(1), isNot(chatRouteName(2)));
  });

  testWidgets('isChatRouteOnTop — только верхний маршрут, стек не трогается', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: key, home: const Text('root')),
    );
    final navigator = key.currentState!;

    void push(String name, String label) {
      navigator.push(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) => Text(label),
        ),
      );
    }

    expect(isChatRouteOnTop(navigator, 7), isFalse);

    push(chatRouteName(7), 'chat 7');
    await tester.pumpAndSettle();
    expect(isChatRouteOnTop(navigator, 7), isTrue);
    expect(isChatRouteOnTop(navigator, 8), isFalse);

    // Накрыли другим экраном — чат 7 всё ещё в стеке, но уже НЕ сверху.
    // Это осознанная граница: открыть его заново поверх текущего законно.
    push('other', 'other screen');
    await tester.pumpAndSettle();
    expect(isChatRouteOnTop(navigator, 7), isFalse);

    // popUntil использован как «заглянуть», а не «закрыть»: стек цел.
    await tester.pumpAndSettle();
    expect(find.text('other screen'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('chat 7'), findsOneWidget);
  });

  test(
    'threadRouteName — комната И корень, иначе два обсуждения слипнутся',
    () {
      // Тредов в комнате много. Если бы имя было только по комнате, дедуп
      // счёл бы открытым уже открытое ЧУЖОЕ обсуждение и не пустил бы в нужное.
      expect(threadRouteName(13, r'$root'), r'thread/13/$root');
      expect(threadRouteName(13, r'$a'), isNot(threadRouteName(13, r'$b')));
      expect(threadRouteName(13, r'$a'), isNot(threadRouteName(14, r'$a')));
      // С маршрутом чата той же комнаты тоже не должно совпадать.
      expect(threadRouteName(13, r'$a'), isNot(chatRouteName(13)));
    },
  );

  testWidgets(
    'openThreadRoute — повторный тап по открытому треду не плодит копию',
    (tester) async {
      // Инцидент 2026-08-05: тап по уведомлению теперь ведёт в тред. Если
      // человек нажмёт ещё раз, находясь в нём же, сверху не должен лечь
      // второй такой же экран.
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: key, home: const Text('root')),
      );
      final navigator = key.currentState!;
      navigator.push(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: threadRouteName(13, r'$root')),
          builder: (_) => const Text('тред 13'),
        ),
      );
      await tester.pumpAndSettle();

      await openThreadRoute(navigator, roomId: 13, threadRootEventId: r'$root');
      await tester.pumpAndSettle();

      // Экран остался один и тот же — второго не появилось.
      expect(find.text('тред 13'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('root'), findsOneWidget);
    },
  );
}
