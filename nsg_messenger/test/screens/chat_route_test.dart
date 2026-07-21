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
}
