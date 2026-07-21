import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **issue #26 + #48** — рантайм-выключатель эффектов стекла.
///
/// Сторожим три инварианта:
///  * при выключенных эффектах `BackdropFilter`-узла в дереве НЕТ
///    (sigma 0 недостаточно — узел сохраняет фиксированную цену
///    readback-а, ~20 мс/кадр на PowerVR GE8320) — issue #26;
///  * при выключенных эффектах под child лежит почти непрозрачная
///    подложка `kGlassOffBackplate` — иначе полупрозрачный тинт
///    вызывающего превращает панель в «дырку» — issue #48;
///  * при ВКЛЮЧЁННЫХ эффектах подложки нет — on-режим не должен
///    дорожать лишним слоем.
void main() {
  setUp(() => GlassEffects.instance.resetForTest());
  tearDown(() => GlassEffects.instance.resetForTest());

  group('GlassEffects: резолвер режимов', () {
    test('auto + способное устройство → включено', () {
      GlassEffects.instance.configureDevice(strongBlurCapable: true);
      expect(GlassEffects.instance.enabled, isTrue);
    });

    test('auto + слабое устройство → выключено', () {
      GlassEffects.instance.configureDevice(strongBlurCapable: false);
      expect(GlassEffects.instance.enabled, isFalse);
    });

    test('ручной on перекрывает слабое устройство', () {
      GlassEffects.instance.configureDevice(strongBlurCapable: false);
      GlassEffects.instance.setMode(GlassEffectsMode.on);
      expect(GlassEffects.instance.enabled, isTrue);
    });

    test('ручной off перекрывает способное устройство', () {
      GlassEffects.instance.configureDevice(strongBlurCapable: true);
      GlassEffects.instance.setMode(GlassEffectsMode.off);
      expect(GlassEffects.instance.enabled, isFalse);
    });

    test('возврат в auto заново читает способность устройства', () {
      GlassEffects.instance.configureDevice(strongBlurCapable: false);
      GlassEffects.instance.setMode(GlassEffectsMode.on);
      GlassEffects.instance.setMode(GlassEffectsMode.auto);
      expect(GlassEffects.instance.enabled, isFalse);
    });

    test('id персистенса стабильны и разбираются обратно', () {
      for (final m in GlassEffectsMode.values) {
        expect(GlassEffectsMode.fromIdOrAuto(m.id), m);
      }
      expect(GlassEffectsMode.fromIdOrAuto(null), GlassEffectsMode.auto);
      expect(GlassEffectsMode.fromIdOrAuto('мусор'), GlassEffectsMode.auto);
    });
  });

  group('GlassBackdrop', () {
    Widget host() => const MaterialApp(
      home: GlassBackdrop(designSigma: 28, child: Text('содержимое')),
    );

    // Ищем именно подложку off-режима, а не любой ColoredBox: MaterialApp
    // и сам может красить фоны, поэтому фильтруем по её цвету.
    final backplate = find.descendant(
      of: find.byType(GlassBackdrop),
      matching: find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == kGlassOffBackplate,
      ),
    );

    testWidgets('эффекты включены → BackdropFilter есть, подложки нет', (
      tester,
    ) async {
      GlassEffects.instance.setMode(GlassEffectsMode.on);
      await tester.pumpWidget(host());
      expect(find.byType(BackdropFilter), findsOneWidget);
      // Инвариант issue #48: on-режим не дорожает лишним слоем заливки.
      expect(backplate, findsNothing);
      expect(find.text('содержимое'), findsOneWidget);
    });

    testWidgets('эффекты выключены → узла НЕТ, под child — подложка', (
      tester,
    ) async {
      GlassEffects.instance.setMode(GlassEffectsMode.off);
      await tester.pumpWidget(host());
      expect(find.byType(BackdropFilter), findsNothing);
      // Инвариант issue #48: панель не «дырка» — под child лежит почти
      // непрозрачная заливка, и child живёт именно ВНУТРИ неё.
      expect(backplate, findsOneWidget);
      expect(
        find.descendant(of: backplate, matching: find.text('содержимое')),
        findsOneWidget,
      );
    });

    test('подложка off-режима почти непрозрачна, но не глухая', () {
      // Сторожим сам смысл issue #48: сквозь панель не должен читаться
      // контент (альфа заметно выше полупрозрачных тинтов ~0.12), но и
      // полная непрозрачность не нужна — обои чуть угадываются.
      expect(kGlassOffBackplate.a, greaterThanOrEqualTo(0.85));
      expect(kGlassOffBackplate.a, lessThan(1.0));
    });

    testWidgets('переключение на лету перестраивает поверхность', (
      tester,
    ) async {
      GlassEffects.instance.setMode(GlassEffectsMode.on);
      await tester.pumpWidget(host());
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(backplate, findsNothing);

      GlassEffects.instance.setMode(GlassEffectsMode.off);
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(backplate, findsOneWidget);
    });

    testWidgets('авто-детект слабого устройства (#26) даёт тот же фолбэк', (
      tester,
    ) async {
      // Off — не только ручной выключатель: auto-режим на слабом
      // устройстве обязан приводить к той же подложке (#48 общий).
      GlassEffects.instance.configureDevice(strongBlurCapable: false);
      await tester.pumpWidget(host());
      expect(find.byType(BackdropFilter), findsNothing);
      expect(backplate, findsOneWidget);
    });
  });
}
