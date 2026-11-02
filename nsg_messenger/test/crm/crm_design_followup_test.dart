import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/crm/crm_components.dart';
import 'package:nsg_messenger/src/crm/crm_controller.dart';
import 'package:nsg_messenger/src/crm/crm_detail_screen.dart';
import 'package:nsg_messenger/src/crm/crm_format.dart';
import 'package:nsg_messenger/src/crm/crm_forms.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_screen.dart';
import 'package:nsg_messenger/src/crm/crm_state.dart';
import 'package:nsg_messenger/src/theme/chatista_theme.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'crm_screens_test.dart' as fixture;
import 'crm_theme_preview_test.dart' as preview;

void main() {
  for (final inset in [0.0, 300.0]) {
    testWidgets('quick touch scrolls above pinned actions; keyboard=$inset', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      final controller = CrmController(
        rpc: CrmRpc(fixture.FakeCrm(), authRetry: false),
        spaceId: 1,
        userId: 7,
      );
      await t.pumpWidget(
        fixture.host(
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () => crmQuickActivity(
                ctx,
                controller,
                fixture.deal(),
                agentRoomId: 77,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      t.view.viewInsets = FakeViewPadding(bottom: inset);
      await t.pumpAndSettle();
      final actions = find.byKey(const ValueKey('crm-activity-actions'));
      final scroll = find.byKey(const ValueKey('crm-activity-scroll'));
      final before = t.getRect(actions);
      expect(before.bottom, lessThanOrEqualTo(844 - inset));
      expect(t.getRect(scroll).bottom, lessThanOrEqualTo(before.top));
      await t.drag(scroll, const Offset(0, -400));
      await t.pumpAndSettle();
      expect(t.getRect(actions), before);
      final due = find.byKey(const ValueKey('crm-activity-due'));
      final next = find.byKey(const ValueKey('crm-activity-next-step'));
      await t.ensureVisible(due);
      await t.pumpAndSettle();
      expect(t.getRect(due).bottom, lessThanOrEqualTo(before.top));
      expect(t.getRect(next).bottom, lessThanOrEqualTo(before.top));
      expect(
        t.getSize(find.widgetWithText(CrmPill, 'Сохранить')).height,
        greaterThanOrEqualTo(56),
      );
      expect(t.takeException(), isNull);
      Navigator.of(t.element(find.text('Open'))).pop();
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }

  for (final compact in [false, true]) {
    testWidgets('deal amount flush right; compact=$compact', (t) async {
      final deal = fixture.deal().copyWith(
        nextStepAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await t.pumpWidget(
        fixture.host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: CrmDealTile(deal: deal, compact: compact, onOpen: () {}),
            ),
          ),
        ),
      );
      final ctx = t.element(find.byType(CrmDealTile));
      final amount = find.text(crmMoney(ctx, deal.amount, deal.currency));
      expect(
        t.getRect(amount).right,
        closeTo(
          t.getRect(find.byType(CrmGlassCard)).right - (compact ? 12 : 14),
          .1,
        ),
      );
      if (compact) {
        final due = find.text(crmDate(ctx, deal.nextStepAt!, due: true));
        final text = t.widget<Text>(due);
        expect(text.softWrap, isFalse);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(
          t.getRect(due).center.dy,
          closeTo(t.getRect(amount).center.dy, 1),
        );
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('column total flush right', (t) async {
    final deal = fixture.deal();
    await t.pumpWidget(
      fixture.host(
        CrmKanban(
          stages: const [CrmStageInfo(1, 'Контакт', CrmStageKind.open, 1)],
          deals: [deal],
          onOpen: (_) {},
          onMove: (_, stage) async {},
          canWrite: false,
        ),
      ),
    );
    final ctx = t.element(find.byType(CrmKanban));
    final amount = find.text(crmMoney(ctx, deal.amount, deal.currency)).first;
    expect(
      t.getRect(amount).right,
      closeTo(t.getRect(find.byType(CrmGlassCard).first).right - 14, .1),
    );
  });

  testWidgets('next step date flush right; deal metadata values bold', (
    t,
  ) async {
    final deal = fixture.deal().copyWith(ownerDisplayName: 'Тестовый менеджер');
    final endpoint = preview.PreviewEndpoint()..deals = [deal];
    await t.pumpWidget(
      fixture.host(
        CrmDealScreen(
          id: 1,
          rpc: CrmRpc(endpoint, authRetry: false),
          space: preview.previewSpace,
        ),
      ),
    );
    await t.pumpAndSettle();
    final ctx = t.element(find.byType(CrmDealScreen));
    final date = find.text(crmDate(ctx, deal.nextStepAt!, due: true));
    final row = find.ancestor(
      of: find.text('СЛЕДУЮЩИЙ ШАГ'),
      matching: find.byType(Row),
    );
    expect(t.getRect(date).right, closeTo(t.getRect(row).right, .1));
    final metadata = t.widget<Text>(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.textSpan?.toPlainText().startsWith('Сумма ') ?? false),
      ),
    );
    final spans = (metadata.textSpan! as TextSpan).children!.cast<TextSpan>();
    for (final value in [
      crmMoney(ctx, deal.amount, deal.currency),
      'Тестовый менеджер',
    ]) {
      expect(
        spans.singleWhere((s) => s.text == value).style?.fontWeight,
        FontWeight.w700,
      );
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'alert pill contrast >=4.5 over bright wallpaper and light theme',
    (t) async {
      for (final theme in [
        ChatistaTheme.glassSunset(),
        ChatistaTheme.glassOceanic(),
        ChatistaTheme.glassAurora(),
        ChatistaTheme.glassEmber(),
        ChatistaTheme.crema(),
      ]) {
        await t.pumpWidget(
          MaterialApp(
            theme: theme.applyTo(ThemeData()),
            home: const Scaffold(
              body: CrmPill(
                tone: CrmPillTone.alert,
                child: Text('Просрочено 2'),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final ctx = t.element(find.byType(CrmPill));
        final foreground = crmAlertForeground(ctx).computeLuminance();
        final background = Color.alphaBlend(
          crmAlertBackground(ctx),
          Colors.white,
        ).computeLuminance();
        final contrast =
            (math.max(foreground, background) + .05) /
            (math.min(foreground, background) + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    },
  );
}
