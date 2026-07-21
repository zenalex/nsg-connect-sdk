import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/contact_card/contact_card_view.dart';

/// **TASK52 итер.1**: рендер визитки — автоконтраст, hex-парсинг,
/// шаблоны (gradient / monogram), пресеты начертания.
void main() {
  ContactCardInfo info({
    String template = 'gradient',
    String? gradientStart = '#E89A55',
    String? gradientEnd = '#1F1A15',
    String? nameColor,
    String? nameFontStyle,
    String? displayName = 'Алексей Зенков',
    String? jobTitle,
    String? company,
  }) => ContactCardInfo(
    ownerMessengerUserId: 1,
    displayName: displayName,
    template: template,
    gradientStart: gradientStart,
    gradientEnd: gradientEnd,
    nameColor: nameColor,
    nameFontStyle: nameFontStyle,
    jobTitle: jobTitle,
    company: company,
    hasHiddenFields: false,
    updatedAt: DateTime.utc(2026, 7, 13),
  );

  group('contrastOn / parseHex', () {
    test('тёмный фон → тёплый белый, светлый → чернильный', () {
      expect(
        ContactCardView.contrastOn(const Color(0xFF1F1A15)),
        const Color(0xF5FFFCF8),
      );
      expect(
        ContactCardView.contrastOn(const Color(0xFFFFFCF8)),
        const Color(0xFF1A0F1A),
      );
    });

    test('parseHex: валидный/мусор/null', () {
      expect(
        ContactCardView.parseHex('#E89A55', Colors.black),
        const Color(0xFFE89A55),
      );
      expect(ContactCardView.parseHex('red', Colors.black), Colors.black);
      expect(ContactCardView.parseHex(null, Colors.black), Colors.black);
      expect(ContactCardView.parseHex('#ZZZZZZ', Colors.black), Colors.black);
    });
  });

  group('nameStyle', () {
    test('пресеты отличаются начертанием', () {
      final classic = ContactCardView.nameStyle('classic', 30, Colors.white);
      final bold = ContactCardView.nameStyle('bold', 30, Colors.white);
      final airy = ContactCardView.nameStyle('airy', 30, Colors.white);
      final mono = ContactCardView.nameStyle('mono', 30, Colors.white);
      expect(classic.fontWeight, FontWeight.w600);
      expect(bold.fontWeight, FontWeight.w800);
      expect(airy.letterSpacing, greaterThan(1));
      expect(mono.fontFamily, 'monospace');
      // Неизвестный пресет (forward-compat) → classic.
      expect(
        ContactCardView.nameStyle('fancy-future', 30, Colors.white).fontWeight,
        FontWeight.w600,
      );
    });
  });

  group('рендер', () {
    testWidgets('gradient: имя + должность·компания', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: ContactCardView(
                card: info(jobTitle: 'Инженер', company: 'НСГ'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Алексей Зенков'), findsOneWidget);
      expect(find.text('Инженер · НСГ'), findsOneWidget);
    });

    testWidgets('monogram: инициалы из имени', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: ContactCardView(card: info(template: 'monogram')),
            ),
          ),
        ),
      );
      expect(find.text('АЗ'), findsOneWidget, reason: 'инициалы');
      expect(find.text('Алексей Зенков'), findsOneWidget);
    });

    testWidgets('tile-размер компактнее и без должности', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: ContactCardView(
                card: info(jobTitle: 'Инженер'),
                size: ContactCardSize.tile,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Алексей Зенков'), findsOneWidget);
      expect(find.text('Инженер'), findsNothing);
    });

    testWidgets('photo без runtime деградирует в градиент (не падает)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: ContactCardView(
                card: info(template: 'photo')
                  ..backgroundMxc = 'mxc://srv/abc',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Алексей Зенков'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
