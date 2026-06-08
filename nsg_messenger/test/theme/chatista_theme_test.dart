import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

void main() {
  group('ChatistaTheme — glass presets: SnackBar/inverse slots (#4)', () {
    // Регрессия на «белую плашку с невидимым текстом»: ColorScheme.dark() не
    // вычисляет inverseSurface/onInverseSurface, и M3 SnackBar падал в
    // fallback — фон = (почти белый) onSurface, текст = (прозрачный) surface.
    final presets = <String, NsgMessengerTheme Function()>{
      'glassSunset': () => ChatistaTheme.glassSunset(),
      'glassOceanic': () => ChatistaTheme.glassOceanic(),
      'glassAurora': () => ChatistaTheme.glassAurora(),
      'glassEmber': () => ChatistaTheme.glassEmber(),
    };
    for (final entry in presets.entries) {
      test('${entry.key}: SnackBar-слоты контрастны (текст не невидим)', () {
        final cs = entry.value().colorScheme!;
        // Фон плашки не совпадает с (почти белым) onSurface.
        expect(cs.inverseSurface, isNot(cs.onSurface));
        // Текст плашки не прозрачный и не равен (transparent) surface.
        expect(cs.onInverseSurface.a, greaterThan(0));
        expect(cs.onInverseSurface, isNot(cs.surface));
      });
    }
  });

  group('ChatistaTheme — Crema preset (design source-of-truth)', () {
    test('light Crema primary = #B8704A (accent.light from design-system.jsx)',
        () {
      final theme = ChatistaTheme.crema(brightness: Brightness.light);
      expect(theme.colorScheme!.primary, const Color(0xFFB8704A));
      expect(theme.colorScheme!.brightness, Brightness.light);
    });

    test('dark Crema primary = #D89971 (accent.dark)', () {
      final theme = ChatistaTheme.crema(brightness: Brightness.dark);
      expect(theme.colorScheme!.primary, const Color(0xFFD89971));
      expect(theme.colorScheme!.brightness, Brightness.dark);
    });

    test('light bg surface = #FFFEFB, container = #F6F2EC (warm cream)', () {
      final theme = ChatistaTheme.crema(brightness: Brightness.light);
      expect(theme.colorScheme!.surface, const Color(0xFFFFFEFB));
      expect(theme.colorScheme!.surfaceContainer, const Color(0xFFF6F2EC));
    });

    test('online indicator surfaced as tertiary (warm green)', () {
      final light = ChatistaTheme.crema(brightness: Brightness.light);
      final dark = ChatistaTheme.crema(brightness: Brightness.dark);
      expect(light.colorScheme!.tertiary, const Color(0xFF5C9E5C));
      expect(dark.colorScheme!.tertiary, const Color(0xFF7BB87B));
    });

    test('bubble shape = soft 22px radius, 6px tail, peer-tail BL '
        '(Telegram-convention flip vs SDK fallback TL)', () {
      final theme = ChatistaTheme.crema();
      final b = theme.bubbleTokens!;
      // Own — tail bottom-right (matches SDK convention).
      expect(b.radiusOwn.topLeft, const Radius.circular(22));
      expect(b.radiusOwn.topRight, const Radius.circular(22));
      expect(b.radiusOwn.bottomLeft, const Radius.circular(22));
      expect(b.radiusOwn.bottomRight, const Radius.circular(6),
          reason: 'own tail bottom-right');
      // Peer — tail bottom-LEFT (design flip from SDK fallback's TL).
      expect(b.radiusPeer.topLeft, const Radius.circular(22));
      expect(b.radiusPeer.topRight, const Radius.circular(22));
      expect(b.radiusPeer.bottomLeft, const Radius.circular(6),
          reason: 'peer tail bottom-left (design convention)');
      expect(b.radiusPeer.bottomRight, const Radius.circular(22));
    });

    test('room tile = 50px avatar + 14px vertical padding (designer roomy)',
        () {
      final theme = ChatistaTheme.crema();
      final r = theme.roomTileTokens!;
      expect(r.avatarSize, 50);
      expect(r.contentPadding, const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14,
      ));
    });

    test('textTheme stays null — inherits host MaterialApp font choices', () {
      final theme = ChatistaTheme.crema();
      expect(theme.textTheme, isNull);
    });
  });

  group('ChatistaTheme — alternative accents', () {
    test('matcha light = #6B8E5A (green tea)', () {
      expect(ChatistaTheme.matcha(brightness: Brightness.light)
          .colorScheme!.primary, const Color(0xFF6B8E5A));
    });

    test('cobalt light = #3D5BB8 (deep blue)', () {
      expect(ChatistaTheme.cobalt(brightness: Brightness.light)
          .colorScheme!.primary, const Color(0xFF3D5BB8));
    });

    test('rose light = #B85878 (warm pink)', () {
      expect(ChatistaTheme.rose(brightness: Brightness.light)
          .colorScheme!.primary, const Color(0xFFB85878));
    });

    test('ink light = #2A2620 (monochrome dark)', () {
      expect(ChatistaTheme.ink(brightness: Brightness.light)
          .colorScheme!.primary, const Color(0xFF2A2620));
    });

    test('all accents share bubble/tile tokens (only color varies)', () {
      final crema = ChatistaTheme.crema();
      final matcha = ChatistaTheme.matcha();
      // Same bubble tokens — design rule: brand varies palette, not shape.
      expect(matcha.bubbleTokens!.radiusOwn, crema.bubbleTokens!.radiusOwn);
      expect(matcha.bubbleTokens!.radiusPeer, crema.bubbleTokens!.radiusPeer);
      expect(matcha.roomTileTokens!.avatarSize, crema.roomTileTokens!.avatarSize);
    });
  });

  group('ChatistaTheme — Glass presets (translucent over wallpaper)', () {
    test('glassSunset accent = #E89A55 (amber)', () {
      final theme = ChatistaTheme.glassSunset();
      expect(theme.colorScheme!.primary, const Color(0xFFE89A55));
      expect(theme.colorScheme!.brightness, Brightness.dark);
    });

    test('glassOceanic accent = #5BB8A8 (mint)', () {
      expect(ChatistaTheme.glassOceanic().colorScheme!.primary,
          const Color(0xFF5BB8A8));
    });

    test('glassAurora accent = #A65BD8 (violet)', () {
      expect(ChatistaTheme.glassAurora().colorScheme!.primary,
          const Color(0xFFA65BD8));
    });

    test('glassEmber accent = #E0682E (orange-red)', () {
      expect(ChatistaTheme.glassEmber().colorScheme!.primary,
          const Color(0xFFE0682E));
    });

    test('Glass surface is transparent — wallpaper shows through', () {
      final theme = ChatistaTheme.glassSunset();
      expect(theme.colorScheme!.surface, const Color(0x00000000));
      // surfaceContainerLowest also fully transparent — host scaffolds.
      expect(theme.colorScheme!.surfaceContainerLowest,
          const Color(0x00000000));
    });

    test('Glass surfaceContainer = rgba(255,255,255,0.10) white-alpha glass',
        () {
      final theme = ChatistaTheme.glassSunset();
      expect(theme.colorScheme!.surfaceContainer.toARGB32().toRadixString(16),
          equals('1affffff'));
    });

    test('Glass tertiary = #8DE89E (mint online indicator)', () {
      final theme = ChatistaTheme.glassSunset();
      expect(theme.colorScheme!.tertiary, const Color(0xFF8DE89E));
    });

    test('Glass bubble tokens inherit soft 22/6 shape (same as Crema)', () {
      final glass = ChatistaTheme.glassSunset();
      final crema = ChatistaTheme.crema();
      expect(glass.bubbleTokens!.radiusOwn, crema.bubbleTokens!.radiusOwn);
      expect(glass.bubbleTokens!.radiusPeer, crema.bubbleTokens!.radiusPeer);
    });

    test('Glass room tile = same designer-roomy density as Crema', () {
      final glass = ChatistaTheme.glassSunset();
      final crema = ChatistaTheme.crema();
      expect(glass.roomTileTokens!.avatarSize, crema.roomTileTokens!.avatarSize);
      expect(glass.roomTileTokens!.contentPadding,
          crema.roomTileTokens!.contentPadding);
    });
  });

  group('ChatistaTheme — applyTo composes with host ThemeData', () {
    test('applyTo overrides host colorScheme with Crema palette', () {
      final hostTheme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      );
      final composite = ChatistaTheme.crema().applyTo(hostTheme);
      expect(composite.colorScheme.primary, const Color(0xFFB8704A));
    });

    test('applyTo preserves host textTheme since Chatista textTheme is null',
        () {
      final hostTheme = ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'CustomHostFont'),
        ),
      );
      final composite = ChatistaTheme.crema().applyTo(hostTheme);
      expect(composite.textTheme.bodyMedium?.fontFamily, 'CustomHostFont');
    });

    test('applyTo adds bubble + room tile extensions on top of host', () {
      final hostTheme = ThemeData();
      final composite = ChatistaTheme.crema().applyTo(hostTheme);
      expect(composite.extension<NsgMessageBubbleTokens>(), isNotNull);
      expect(composite.extension<NsgRoomTileTokens>(), isNotNull);
    });
  });
}
