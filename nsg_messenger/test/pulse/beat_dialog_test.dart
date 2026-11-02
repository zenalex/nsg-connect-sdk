/// **Диалог с адресом для heartbeat отдаёт РАБОЧУЮ инструкцию** (issue #143).
///
/// 15.08.2026 сервер перестал принимать `POST /beat/<токен>`: адрес с
/// секретом оседал в логах прокси и в истории команд. Но отдавать эту форму
/// в `beatUrl` он не перестал — и диалог честно показывал её вместе с
/// готовым `curl`. Две недели каждый, кто заводил монитор, копировал сниппет,
/// получал `401 token_in_path_not_accepted` и терял единственный показ
/// токена: второй раз он не показывается, только ротация.
///
/// Отсюда три проверки ниже: токен виден отдельным полем, в адресе его нет,
/// а в сниппете он уходит заголовком.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/pulse_screen.dart';

const _beatUrl = 'https://hooks.example.test/beat';
const _token = 'plt_secret123';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showPulseBeatDialog(context, beatUrl: _beatUrl, token: _token),
            child: const Text('открыть'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
}

/// Тексты всех полей диалога — по ним и судим, что человек скопирует.
///
/// `CopyableField` рисует значение `SelectableText`-ом, подписи — обычным
/// `Text`; собираем и то, и другое.
List<String> _texts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text))) t.data ?? '',
  for (final t in tester.widgetList<SelectableText>(
    find.byType(SelectableText),
  ))
    t.data ?? '',
];

void main() {
  testWidgets('адрес показан без токена', (tester) async {
    await _open(tester);
    final url = _texts(tester).firstWhere((t) => t.startsWith('https://'));
    expect(url, _beatUrl);
    expect(
      url,
      isNot(contains(_token)),
      reason: 'адрес с токеном сервер отвергает — 401 token_in_path',
    );
  });

  testWidgets('токен показан отдельным полем', (tester) async {
    await _open(tester);
    // Показ один-единственный: в БД лежит только хеш, повторно узнать токен
    // нельзя — можно лишь ротировать.
    expect(_texts(tester), contains(_token));
  });

  testWidgets('в сниппете токен уходит заголовком', (tester) async {
    await _open(tester);
    final curl = _texts(tester).firstWhere((t) => t.startsWith('curl'));
    expect(curl, contains("-H 'X-Pulse-Token: $_token'"));
    // Без -X POST сниппет уходит GET-ом и молча не работает.
    expect(curl, contains('-X POST'));
    expect(curl, contains(_beatUrl));
    expect(
      curl,
      isNot(contains('$_beatUrl/$_token')),
      reason: 'токен в пути — ровно та форма, которую сервер больше не берёт',
    );
  });
}
