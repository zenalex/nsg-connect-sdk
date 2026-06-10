import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// Тесты [NsgMessengerTheme] (TASK22 Chunk 2).
void main() {
  group('NsgMessengerTheme', () {
    test('empty: isEmpty == true', () {
      expect(NsgMessengerTheme.empty.isEmpty, isTrue);
    });

    test('non-empty if any field set', () {
      final t = NsgMessengerTheme(
        bubbleTokens: NsgMessageBubbleTokens.fallback,
      );
      expect(t.isEmpty, isFalse);
    });

    test('applyTo: ColorScheme override propagates', () {
      final parent = ThemeData.light();
      const customScheme = ColorScheme.dark(primary: Color(0xFFFF0000));
      const theme = NsgMessengerTheme(colorScheme: customScheme);
      final result = theme.applyTo(parent);
      expect(result.colorScheme, customScheme);
    });

    test('applyTo: ColorScheme не задан → parent сохранён', () {
      final parent = ThemeData.light();
      const theme = NsgMessengerTheme.empty;
      final result = theme.applyTo(parent);
      expect(result.colorScheme, parent.colorScheme);
    });

    // ── B20: brightness-coherent инъекция ────────────────────────────
    test('applyTo: dark colorScheme над light parent → brightness + textTheme '
        'становятся dark-coherent (B20)', () {
      final parent = ThemeData.light(); // brightness light, чёрный textTheme
      const darkScheme = ColorScheme.dark();
      const theme = NsgMessengerTheme(colorScheme: darkScheme);
      final result = theme.applyTo(parent);

      // brightness делегирует к colorScheme → dark.
      expect(result.brightness, Brightness.dark);
      // textTheme перекрашен в onSurface (светлый), а не остался
      // чёрным от light-parent → bare Text виден на тёмном фоне.
      expect(result.textTheme.bodyLarge?.color, darkScheme.onSurface);
      expect(result.textTheme.titleMedium?.color, darkScheme.onSurface);
    });

    test(
      'applyTo: light colorScheme над dark parent → light-coherent (обратный '
      'кейс B20 — фабрика инъектит init-light поверх dark ambient)',
      () {
        final parent = ThemeData.dark(); // brightness dark, белый textTheme
        const lightScheme = ColorScheme.light();
        const theme = NsgMessengerTheme(colorScheme: lightScheme);
        final result = theme.applyTo(parent);

        expect(result.brightness, Brightness.light);
        // Без фикса title остался бы белым (от dark-parent) → невидим на
        // светлом surface. После фикса — onSurface (тёмный).
        expect(result.textTheme.titleMedium?.color, lightScheme.onSurface);
      },
    );

    test('applyTo: host textTheme override побеждает recolor', () {
      final parent = ThemeData.light();
      const darkScheme = ColorScheme.dark();
      const override = TextTheme(
        titleMedium: TextStyle(color: Color(0xFF00FF00)),
      );
      const theme = NsgMessengerTheme(
        colorScheme: darkScheme,
        textTheme: override,
      );
      final result = theme.applyTo(parent);
      // Explicit host-цвет выигрывает у recolor-а в onSurface.
      expect(result.textTheme.titleMedium?.color, const Color(0xFF00FF00));
    });

    test('applyTo: bubble tokens добавляется в extensions', () {
      final parent = ThemeData.light();
      const customBubble = NsgMessageBubbleTokens(
        radiusOwn: BorderRadius.all(Radius.circular(8)),
        radiusPeer: BorderRadius.all(Radius.circular(8)),
        padding: EdgeInsets.all(10),
        maxWidthFraction: 0.9,
        statusIconSize: 12,
        interBubbleSpacing: 8,
        composerPadding: EdgeInsets.all(4),
      );
      const theme = NsgMessengerTheme(bubbleTokens: customBubble);
      final result = theme.applyTo(parent);
      final ext = result.extension<NsgMessageBubbleTokens>();
      expect(ext, isNotNull);
      expect(ext!.maxWidthFraction, 0.9);
      expect(ext.statusIconSize, 12);
    });

    test('applyTo: room-tile tokens добавляются', () {
      final parent = ThemeData.light();
      const customTile = NsgRoomTileTokens(
        avatarSize: 56,
        unreadBadgeSize: 24,
        contentPadding: EdgeInsets.all(12),
        titleSubtitleSpacing: 4,
      );
      const theme = NsgMessengerTheme(roomTileTokens: customTile);
      final result = theme.applyTo(parent);
      final ext = result.extension<NsgRoomTileTokens>();
      expect(ext, isNotNull);
      expect(ext!.avatarSize, 56);
    });

    test('applyTo: parent extensions сохраняются', () {
      final parent = ThemeData(
        extensions: const [
          NsgMessageBubbleTokens(
            radiusOwn: BorderRadius.zero,
            radiusPeer: BorderRadius.zero,
            padding: EdgeInsets.zero,
            maxWidthFraction: 0.5,
            statusIconSize: 10,
            interBubbleSpacing: 8,
            composerPadding: EdgeInsets.zero,
          ),
        ],
      );
      // Override roomTileTokens — parent's bubbleTokens должен остаться.
      const theme = NsgMessengerTheme(
        roomTileTokens: NsgRoomTileTokens.fallback,
      );
      final result = theme.applyTo(parent);
      expect(
        result.extension<NsgMessageBubbleTokens>(),
        isNotNull,
        reason: 'parent bubbleTokens сохранён',
      );
      expect(result.extension<NsgRoomTileTokens>(), isNotNull);
    });

    test('NsgMessageBubbleTokens.fallback совпадает с TASK15 hardcoded', () {
      final f = NsgMessageBubbleTokens.fallback;
      expect(f.maxWidthFraction, 0.78);
      expect(f.statusIconSize, 14);
      expect(
        f.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    });

    test('NsgMessageBubbleTokens.copyWith partial override', () {
      const original = NsgMessageBubbleTokens.fallback;
      final modified = original.copyWith(maxWidthFraction: 0.5);
      expect(modified.maxWidthFraction, 0.5);
      expect(modified.statusIconSize, original.statusIconSize);
      expect(modified.radiusOwn, original.radiusOwn);
    });

    test('NsgMessageBubbleTokens.lerp interpolates numeric fields', () {
      const a = NsgMessageBubbleTokens(
        radiusOwn: BorderRadius.zero,
        radiusPeer: BorderRadius.zero,
        padding: EdgeInsets.zero,
        maxWidthFraction: 0.5,
        statusIconSize: 10,
        interBubbleSpacing: 4,
        composerPadding: EdgeInsets.zero,
      );
      const b = NsgMessageBubbleTokens(
        radiusOwn: BorderRadius.zero,
        radiusPeer: BorderRadius.zero,
        padding: EdgeInsets.zero,
        maxWidthFraction: 1.0,
        statusIconSize: 20,
        interBubbleSpacing: 12,
        composerPadding: EdgeInsets.zero,
      );
      final mid = a.lerp(b, 0.5);
      expect(mid.maxWidthFraction, 0.75);
      expect(mid.statusIconSize, 15);
    });

    // ---------------------------------------------------------------
    // TASK22 Phase2 Chunk 1 — new fields (padding/spacing tokens).
    // ---------------------------------------------------------------
    test('NsgMessageBubbleTokens.fallback: new fields defaults', () {
      final f = NsgMessageBubbleTokens.fallback;
      expect(f.interBubbleSpacing, 8.0);
      expect(f.composerPadding, const EdgeInsets.fromLTRB(8, 4, 8, 8));
    });

    test('NsgRoomTileTokens.fallback: new fields defaults', () {
      final f = NsgRoomTileTokens.fallback;
      expect(
        f.contentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
      expect(f.titleSubtitleSpacing, 4.0);
    });

    test('NsgRoomTileTokens.copyWith: partial override of new fields', () {
      const original = NsgRoomTileTokens.fallback;
      final modified = original.copyWith(
        contentPadding: const EdgeInsets.all(24),
        titleSubtitleSpacing: 10,
      );
      expect(modified.contentPadding, const EdgeInsets.all(24));
      expect(modified.titleSubtitleSpacing, 10);
      // Untouched fields preserved.
      expect(modified.avatarSize, original.avatarSize);
      expect(modified.unreadBadgeSize, original.unreadBadgeSize);
    });

    test('NsgMessageBubbleTokens.copyWith: partial override of new fields', () {
      const original = NsgMessageBubbleTokens.fallback;
      final modified = original.copyWith(
        interBubbleSpacing: 16,
        composerPadding: const EdgeInsets.all(20),
      );
      expect(modified.interBubbleSpacing, 16);
      expect(modified.composerPadding, const EdgeInsets.all(20));
      expect(modified.padding, original.padding);
      expect(modified.maxWidthFraction, original.maxWidthFraction);
    });

    test('NsgRoomTileTokens.lerp interpolates new fields', () {
      const a = NsgRoomTileTokens(
        avatarSize: 40,
        unreadBadgeSize: 20,
        contentPadding: EdgeInsets.all(8),
        titleSubtitleSpacing: 2,
      );
      const b = NsgRoomTileTokens(
        avatarSize: 60,
        unreadBadgeSize: 30,
        contentPadding: EdgeInsets.all(16),
        titleSubtitleSpacing: 10,
      );
      final mid = a.lerp(b, 0.5);
      expect(mid.titleSubtitleSpacing, 6.0);
      expect(mid.contentPadding, const EdgeInsets.all(12));
    });

    test('NsgRoomTileTokens equality: distinguishes new fields', () {
      const base = NsgRoomTileTokens.fallback;
      // Same → equal.
      // ignore: prefer_const_constructors — runtime compare.
      final sameInstance = NsgRoomTileTokens(
        avatarSize: base.avatarSize,
        unreadBadgeSize: base.unreadBadgeSize,
        contentPadding: base.contentPadding,
        titleSubtitleSpacing: base.titleSubtitleSpacing,
      );
      expect(sameInstance, base);
      expect(sameInstance.hashCode, base.hashCode);
      // Differ on contentPadding → not equal.
      final differentPadding = base.copyWith(
        contentPadding: const EdgeInsets.all(99),
      );
      expect(differentPadding, isNot(base));
      // Differ on titleSubtitleSpacing → not equal.
      final differentSpacing = base.copyWith(titleSubtitleSpacing: 99);
      expect(differentSpacing, isNot(base));
    });

    test('NsgMessageBubbleTokens equality: distinguishes new fields', () {
      const base = NsgMessageBubbleTokens.fallback;
      final differentInter = base.copyWith(interBubbleSpacing: 99);
      expect(differentInter, isNot(base));
      final differentComposer = base.copyWith(
        composerPadding: const EdgeInsets.all(99),
      );
      expect(differentComposer, isNot(base));
    });
  });

  group('MessengerThemeScope', () {
    testWidgets('empty theme: child рендерится без overlay', (tester) async {
      const childKey = Key('child');
      await tester.pumpWidget(
        MaterialApp(
          home: MessengerThemeScope(
            theme: NsgMessengerTheme.empty,
            child: const Text('hi', key: childKey),
          ),
        ),
      );
      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets(
      'non-empty theme: child получает overlay через Theme.of(context)',
      (tester) async {
        const customScheme = ColorScheme.dark(primary: Color(0xFFFF0000));
        ColorScheme? capturedScheme;
        await tester.pumpWidget(
          MaterialApp(
            home: MessengerThemeScope(
              theme: const NsgMessengerTheme(colorScheme: customScheme),
              child: Builder(
                builder: (ctx) {
                  capturedScheme = Theme.of(ctx).colorScheme;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        expect(capturedScheme, customScheme);
      },
    );

    testWidgets('extensions доступны child-контексту', (tester) async {
      NsgMessageBubbleTokens? capturedTokens;
      const customBubble = NsgMessageBubbleTokens(
        radiusOwn: BorderRadius.all(Radius.circular(8)),
        radiusPeer: BorderRadius.all(Radius.circular(8)),
        padding: EdgeInsets.all(10),
        maxWidthFraction: 0.9,
        statusIconSize: 12,
        interBubbleSpacing: 8,
        composerPadding: EdgeInsets.all(4),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MessengerThemeScope(
            theme: const NsgMessengerTheme(bubbleTokens: customBubble),
            child: Builder(
              builder: (ctx) {
                capturedTokens = Theme.of(
                  ctx,
                ).extension<NsgMessageBubbleTokens>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(capturedTokens, isNotNull);
      expect(capturedTokens!.maxWidthFraction, 0.9);
    });
  });

  // TASK22 followup (f): NsgMessengerLocale.resolveFromSystem reads
  // PlatformDispatcher.instance.locales (or test override) and picks
  // the first match against `supported` by languageCode.
  group('NsgMessengerLocale.resolveFromSystem', () {
    test('system locale en-US first → returns Locale("en")', () {
      final result = NsgMessengerLocale.resolveFromSystem(const [
        Locale('en', 'US'),
      ]);
      expect(result.locale, const Locale('en'));
    });

    test('system locale ru-RU first → returns Locale("ru")', () {
      final result = NsgMessengerLocale.resolveFromSystem(const [
        Locale('ru', 'RU'),
      ]);
      expect(result.locale, const Locale('ru'));
    });

    test('first locale unsupported (de-DE), second en-US → returns en', () {
      final result = NsgMessengerLocale.resolveFromSystem(const [
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ]);
      expect(result.locale, const Locale('en'));
    });

    test('no matching locale (only de-DE) → fallback to Locale("ru")', () {
      final result = NsgMessengerLocale.resolveFromSystem(const [
        Locale('de', 'DE'),
      ]);
      expect(result.locale, const Locale('ru'));
    });

    test('empty list → fallback to Locale("ru")', () {
      final result = NsgMessengerLocale.resolveFromSystem(const []);
      expect(result.locale, const Locale('ru'));
    });
  });
}
