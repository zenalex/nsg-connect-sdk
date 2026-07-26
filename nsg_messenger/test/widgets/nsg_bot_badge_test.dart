import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show ParticipantKind;
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/widgets/nsg_bot_badge.dart';

/// **TASK77 довесок A**: плашка «этот собеседник — программа».
/// Анти-имперсонация — маркировка не должна пропадать ни на одной
/// поверхности, поэтому виджет один и покрыт отдельно.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(body: child),
  );

  group('NsgBotBadge.isNonHuman', () {
    test('bot / integration / aiAgent — «не человек»', () {
      // Для пользователя это всё программа; различие — наша таксономия.
      expect(NsgBotBadge.isNonHuman(ParticipantKind.bot), isTrue);
      expect(NsgBotBadge.isNonHuman(ParticipantKind.integration), isTrue);
      expect(NsgBotBadge.isNonHuman(ParticipantKind.aiAgent), isTrue);
    });

    test('user, system и null — не помечаем', () {
      expect(NsgBotBadge.isNonHuman(ParticipantKind.user), isFalse);
      // `system` (@nsg-system) намеренно НЕ помечаем: служебные сообщения
      // платформы рисуются отдельным стилем, а не как реплика собеседника —
      // та же трактовка, что в MessageBubble._senderIsBot.
      expect(NsgBotBadge.isNonHuman(ParticipantKind.system), isFalse);
      // null = старый сервер без поля: молчим, а не рисуем ложную плашку.
      expect(NsgBotBadge.isNonHuman(null), isFalse);
    });
  });

  testWidgets('бот → иконка + текстовая плашка «Бот»', (tester) async {
    await tester.pumpWidget(
      wrap(const NsgBotBadge(kind: ParticipantKind.bot)),
    );
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    expect(find.text('Бот'), findsOneWidget);
  });

  testWidgets('compact → только иконка (тесная строка списка)', (tester) async {
    await tester.pumpWidget(
      wrap(const NsgBotBadge(kind: ParticipantKind.bot, compact: true)),
    );
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    expect(find.text('Бот'), findsNothing);
  });

  testWidgets('обычный пользователь → ничего не рисуется', (tester) async {
    await tester.pumpWidget(
      wrap(const NsgBotBadge(kind: ParticipantKind.user)),
    );
    expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
    expect(find.text('Бот'), findsNothing);
  });

  testWidgets('kind == null (старый сервер) → ничего не рисуется', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const NsgBotBadge(kind: null)));
    expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
  });
}
