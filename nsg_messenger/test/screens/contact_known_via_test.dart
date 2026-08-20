import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/contact_profile_screen.dart';

/// **Откуда человек знаком** — строка в карточке
/// (§6 DESIGN_TEAMS_AND_CONTACT_SHARING).
///
/// Смысл строки: объяснить, почему человек НЕ пропал из списка людей
/// после исключения из команды. Значит она обязана называть все
/// действующие источники — и обязана исчезать, когда их нет.
void main() {
  ContactProfileView profile({
    List<String> teams = const [],
    bool room = false,
    bool manual = false,
  }) => ContactProfileView(
    contactMessengerUserId: 1,
    displayName: 'Коллега',
    labelIds: const [],
    knownViaTeamNames: teams,
    knownViaSharedRoom: room,
    knownViaManualContact: manual,
  );

  Widget host(ContactProfileView p) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: ListView(children: [KnownViaLine(profile: p)]),
    ),
  );

  testWidgets('названы ВСЕ источники, а не первый попавшийся', (tester) async {
    // Одна причина из трёх объяснением не будет: человек остаётся видимым
    // по любой из них.
    await tester.pumpWidget(
      host(profile(teams: ['Компания', 'Разработка'], room: true)),
    );
    await tester.pumpAndSettle();

    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(text, contains('Компания'));
    expect(text, contains('Разработка'));
    expect(text, contains('общий чат'));
  });

  testWidgets('главный случай: команды не стало, чат объясняет остальное', (
    tester,
  ) async {
    await tester.pumpWidget(host(profile(room: true)));
    await tester.pumpAndSettle();

    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(
      text,
      contains('общий чат'),
      reason: 'вот почему человек не пропал после исключения из команды',
    );
  });

  testWidgets('источников нет — строки нет', (tester) async {
    // Пустое «Знакомы:» ничего не сообщает, а место занимает.
    await tester.pumpWidget(host(profile()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Знакомы'), findsNothing);
  });
}
