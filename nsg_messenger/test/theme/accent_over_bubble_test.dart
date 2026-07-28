/// **Акцент поверх акцента.**
///
/// Жалоба владельца: «с белым текстом всё ок, читается везде, а вот с
/// оранжевым — проблема. Получается оранжевый на оранжевом в углах».
/// К жалобе приложен скриншот: ссылка в чужом пузыре над нижним (самым
/// светлым) пятном обоев — оранжевая по оранжевому.
///
/// Причина: в glass-темах `primary` — ЭТО цвет обоев. У sunset акцент
/// `#E89A55` буквально равен нижнему левому пятну подложки, у ember —
/// `#E0682E` тоже. Свой пузырь — тот же акцент под 33%. А ссылки,
/// упоминания, имя автора и шапка цитаты красились чистым `primary`.
///
/// Чинить сменой одного цвета нельзя: акцент обязан оставаться акцентом.
/// Поэтому [readableAccent] сохраняет ОТТЕНОК и двигает светлоту к цвету
/// текста — ровно настолько, чтобы взять порог контраста. Здесь
/// проверяем оба свойства: читается И остаётся тем же цветом.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/messages/message_composer.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/theme/highlight_surface.dart';

final _glass = <String, NsgMessengerTheme>{
  'sunset': ChatistaTheme.glassSunset(),
  'oceanic': ChatistaTheme.glassOceanic(),
  'aurora': ChatistaTheme.glassAurora(),
  'ember': ChatistaTheme.glassEmber(),
};

/// Цвет пузыря так, как его считает `MessageBubble`.
Color _bubble(NsgMessengerTheme theme, {required bool own}) {
  final scheme = theme.colorScheme!;
  final raw = own ? scheme.primaryContainer : scheme.surfaceContainerHighest;
  final ink = theme.bubbleTokens?.bubbleInk;
  return ink == null ? raw : Color.alphaBlend(raw, ink);
}

Color _text(NsgMessengerTheme theme, {required bool own}) =>
    own ? theme.colorScheme!.onPrimaryContainer : theme.colorScheme!.onSurface;

void main() {
  setUpAll(registerTimeagoLocales);

  for (final entry in _glass.entries) {
    final name = entry.key;
    final theme = entry.value;
    final accent = theme.colorScheme!.primary;

    for (final own in [true, false]) {
      final where = '$name own=$own';
      final bubble = _bubble(theme, own: own);
      final text = _text(theme, own: own);

      test('$where: сырой акцент порога НЕ добирал', () {
        // Свидетель регрессии: без правки ссылка/упоминание/имя автора
        // красились ровно этим цветом.
        expect(contrastRatio(accent, bubble), lessThan(4.5));
      });

      test('$where: подогнанный акцент читается', () {
        final fixed = readableAccent(accent, bubble, toward: text);
        expect(
          contrastRatio(Color.alphaBlend(fixed, bubble), bubble),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$where: остаётся тем же цветом — оттенок сохранён', () {
        // Иначе «читается» было бы куплено ценой потери смысла: ссылка,
        // перекрашенная в цвет текста, перестаёт выглядеть ссылкой.
        final fixed = readableAccent(accent, bubble, toward: text);
        final hue = HSLColor.fromColor(fixed).hue;
        final want = HSLColor.fromColor(accent).hue;
        expect((hue - want).abs(), lessThan(10), reason: 'оттенок уехал');
        expect(
          HSLColor.fromColor(fixed).saturation,
          greaterThan(0.2),
          reason: 'акцент выцвел до почти-серого',
        );
      });
    }
  }

  test('акцент, который и так читается, не трогаем', () {
    const accent = Color(0xFFE89A55);
    const nearBlack = Color(0xFF14110E);
    expect(
      readableAccent(accent, nearBlack, toward: Colors.white),
      accent,
      reason: 'подгонять нечего — лишний сдвиг цвета был бы произволом',
    );
  });

  test('фон, на котором не читается ничто → отдаём цвет текста', () {
    // Белый текст на белом фоне: ни один подмес не возьмёт порог. Тогда
    // хотя бы не выдумываем цвет, а сливаемся с соседними строками.
    expect(
      readableAccent(Colors.white, Colors.white, toward: Colors.white),
      Colors.white,
    );
  });

  test('светлая тема: акцент уходит В ТЁМНУЮ, а не в светлую', () {
    // Направление подгонки задаёт цвет текста, а не константа: на кремовом
    // пузыре осветлять акцент значило бы гробить контраст.
    final light = ChatistaTheme.crema();
    final scheme = light.colorScheme!;
    final fixed = readableAccent(
      scheme.primary,
      scheme.surfaceContainerHighest,
      toward: scheme.onSurface,
    );
    expect(
      HSLColor.fromColor(fixed).lightness,
      lessThan(HSLColor.fromColor(scheme.primary).lightness),
    );
    expect(
      contrastRatio(fixed, scheme.surfaceContainerHighest),
      greaterThanOrEqualTo(4.5),
    );
  });

  group('inkedSurface', () {
    test('без опорного тона (обычные темы) — ничего не меняем', () {
      const plate = Color(0x33FFFFFF);
      expect(inkedSurface(plate, null), plate);
    });

    test('с опорным тоном полупрозрачная плашка становится непрозрачной', () {
      final plate = inkedSurface(
        const Color(0x33FFFFFF),
        const Color(0xFF2A1428),
      );
      expect(plate.a, 1.0, reason: 'иначе контраст снова зависит от обоев');
    });
  });

  _linkInBubbleTest();
  _replyChipTest();
}

/// Проверка сквозной проводки: не «функция умеет», а «в пузыре ссылка
/// действительно нарисована подогнанным цветом».
void _linkInBubbleTest() {
  final theme = ChatistaTheme.glassSunset();

  Widget app({required bool own}) => MaterialApp(
    theme: theme.applyTo(ThemeData.dark()),
    locale: const Locale('ru'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: MessageBubble(
        message: ChatMessage(
          clientTxnId: 'txn-1',
          matrixEventId: 'evt-1',
          senderMatrixUserId: '@peer:localhost',
          senderMessengerUserId: null,
          body: 'Unhandled Exception: 500 ||| https://test.example.me/Api/Make',
          msgType: 'm.text',
          serverTimestamp: DateTime.utc(2026, 1, 1),
          status: ChatMessageStatus.sent,
        ),
        isOwn: own,
        onRetry: (_) {},
      ),
    ),
  );

  /// Фактический фон пузыря — берём из отрисованной декорации, а не
  /// пересчитываем формулой: тест должен ловить и расхождение формул.
  Color paintedBubble(WidgetTester tester, {required bool own}) {
    final tokens = theme.bubbleTokens!;
    final radius = own ? tokens.radiusOwn : tokens.radiusPeer;
    final box = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(MessageBubble),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.borderRadius == radius && d.color != null);
    return box.color!;
  }

  /// Цвет кликабельного span-а — то, чем ссылка реально нарисована.
  Color paintedLink(WidgetTester tester) {
    for (final rich in tester.widgetList<RichText>(
      find.descendant(
        of: find.byType(MessageBubble),
        matching: find.byType(RichText),
      ),
    )) {
      Color? found;
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer is TapGestureRecognizer) {
          found = span.style?.color;
          return false;
        }
        return true;
      });
      if (found != null) return found!;
    }
    fail('кликабельная ссылка в пузыре не найдена');
  }

  for (final own in [true, false]) {
    testWidgets('sunset own=$own: ссылка в пузыре читается', (tester) async {
      await tester.pumpWidget(app(own: own));
      await tester.pump();

      final bubble = paintedBubble(tester, own: own);
      final link = paintedLink(tester);

      expect(
        contrastRatio(Color.alphaBlend(link, bubble), bubble),
        greaterThanOrEqualTo(4.5),
        reason: 'ровно этот случай на скриншоте владельца',
      );
      expect(
        link,
        isNot(theme.colorScheme!.primary),
        reason: 'сырой акцент здесь порога не берёт — значит, не он',
      );
    });
  }
}

/// Чип «Ответ на …» висит в самом низу экрана — там же, где на скриншоте
/// владельца светилось нижнее пятно обоев.
void _replyChipTest() {
  final theme = ChatistaTheme.glassSunset();

  testWidgets('sunset: чип ответа над обоями непрозрачен и читается', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.applyTo(ThemeData.dark()),
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: Scaffold(
          body: MessageComposer(
            onSend:
                (
                  String body, {
                  List<int>? mentionedMessengerUserIds,
                  String? albumId,
                }) async {},
            replyTarget: ChatMessage(
              clientTxnId: 'txn-r',
              matrixEventId: 'evt-r',
              senderMatrixUserId: '@peer:localhost',
              senderMessengerUserId: null,
              body: 'исходное сообщение',
              msgType: 'm.text',
              serverTimestamp: DateTime.utc(2026, 1, 1),
              status: ChatMessageStatus.sent,
            ),
            replyTargetSenderName: 'Андрей',
          ),
        ),
      ),
    );
    await tester.pump();

    // Чип — единственный контейнер с акцентной чертой слева.
    final chip = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border is Border && d.color != null);
    final plate = chip.color!;
    final accent = (chip.border! as Border).left.color;

    expect(plate.a, 1.0, reason: 'иначе цвет чипа задают обои под ним');
    expect(
      contrastRatio(Color.alphaBlend(accent, plate), plate),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      accent,
      isNot(theme.colorScheme!.primary),
      reason: 'сырой акцент на этой плашке порога не берёт',
    );
  });
}
