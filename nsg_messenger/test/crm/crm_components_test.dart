import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/crm/crm_components.dart';
import 'package:nsg_messenger/src/theme/chatista_theme.dart';
import 'package:nsg_messenger/src/crm/crm_screen.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_controller.dart';
import 'package:nsg_messenger/src/crm/crm_proposal_card.dart';
import 'crm_screens_test.dart' as fixture;

void main() {
  testWidgets('today separates overdue and upcoming steps', (t) async {
    final now = DateTime.now();
    final endpoint = fixture.FakeCrm()
      ..deals = [
        fixture.deal().copyWith(
          nextStepAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        fixture.deal().copyWith(
          id: 2,
          nextStepAt: DateTime(
            now.year,
            now.month,
            now.day,
            23,
            59,
            59,
            999,
            999,
          ),
        ),
      ];
    final rpc = CrmRpc(endpoint, authRetry: false);
    final controller = CrmController(rpc: rpc, spaceId: 1, userId: 7);
    await t.pumpWidget(
      fixture.host(CrmScreen(rpc: rpc, controller: controller)),
    );
    await t.pumpAndSettle();
    expect(find.text('ПРОСРОЧЕНО · 1'), findsOneWidget);
    expect(find.text('СЕГОДНЯ · 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('proposal renders server confirmation copy once', (t) async {
    await t.pumpWidget(
      fixture.host(
        CrmProposalCard(
          proposalId: 1,
          eventId: 'test-event',
          body: 'Server title\nStage: old → new\nSERVER CONFIRMATION COPY',
          readStatus: (_) async => {'status': 'proposed'},
          reply: (_, event) async {},
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('SERVER CONFIRMATION COPY'), findsOneWidget);
    expect(
      find.text(
        'Ответьте «да» на это сообщение, чтобы применить, «нет» — чтобы отменить.',
      ),
      findsNothing,
    );
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('custom CRM header clears the phone system status bar', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetDevicePixelRatio);
    t.view.padding = const FakeViewPadding(top: 24);
    addTearDown(t.view.resetPadding);
    final rpc = CrmRpc(fixture.FakeCrm(), authRetry: false);
    final controller = CrmController(rpc: rpc, spaceId: 1, userId: 7);
    await t.pumpWidget(
      fixture.host(CrmScreen(rpc: rpc, controller: controller)),
    );
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.byType(CrmScreenHeader)).dy,
      greaterThanOrEqualTo(24),
    );
    await t.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('pill keeps a 44px hit target for a 34px visual', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: CrmPill(
              height: 34,
              onPressed: () => taps++,
              child: const Text('Готово'),
            ),
          ),
        ),
      ),
    );
    final rect = t.getRect(find.byType(CrmPill));
    expect(rect.height, 44);
    await t.tapAt(Offset(rect.center.dx, rect.top + 1));
    expect(taps, 1);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('glass and inverse surfaces use Chatista color tokens', (
    t,
  ) async {
    for (final theme in [ChatistaTheme.glassSunset(), ChatistaTheme.crema()]) {
      final data = theme.applyTo(ThemeData(useMaterial3: true));
      await t.pumpWidget(
        MaterialApp(
          theme: data,
          home: const Scaffold(
            body: Column(
              children: [
                CrmGlassCard(child: Text('Стекло')),
                CrmGlassCard(inverse: true, child: Text('Следующий шаг')),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final glass = t.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(CrmGlassCard).first,
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (glass.decoration as BoxDecoration).color,
        data.colorScheme.surfaceContainer,
      );
      final context = t.element(find.text('Следующий шаг'));
      expect(
        DefaultTextStyle.of(context).style.color,
        CrmGlassCard.ink(context),
      );
    }
  });

  testWidgets('stage bar has 6px segments and no labels', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 300, child: CrmStageBar(count: 5, current: 1)),
        ),
      ),
    );
    final bars = find.descendant(
      of: find.byType(CrmStageBar),
      matching: find.byType(Container),
    );
    expect(bars, findsNWidgets(5));
    for (final element in bars.evaluate()) {
      expect(t.getSize(find.byWidget(element.widget)).height, 6);
    }
    expect(find.byType(Text), findsNothing);
  });
}
