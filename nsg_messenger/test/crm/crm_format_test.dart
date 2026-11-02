import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/crm/crm_format.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    testWidgets('calendar dates and exact money in $locale', (t) async {
      final clock = DateTime(2026, 10, 11, 19, 52);
      late BuildContext context;
      await t.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: NsgL10n.localizationsDelegates,
          supportedLocales: NsgL10n.supportedLocales,
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        crmDate(context, clock, now: clock),
        locale == 'ru' ? 'сегодня, 19:52' : 'today, 19:52',
      );
      expect(
        crmDate(context, DateTime(2026, 10, 10, 12), now: clock),
        locale == 'ru' ? 'вчера, 12:00' : 'yesterday, 12:00',
      );
      expect(
        crmDate(context, DateTime(2026, 10, 9, 12), now: clock, due: true),
        locale == 'ru' ? 'просрочено 2 дня' : '2 days overdue',
      );
      final total = CrmDecimal.parse('0.1001')! + CrmDecimal.parse('0.2002')!;
      expect(
        crmMoneyDecimal(context, total, 'RUB'),
        contains(locale == 'ru' ? '0,3003' : '0.3003'),
      );
      expect(
        crmMoney(context, '1250.50', 'RUB'),
        contains(locale == 'ru' ? '1\u00a0250,50' : '1,250.50'),
      );
      expect(
        crmMoney(context, '9007199254740993.01', 'EUR'),
        contains(
          locale == 'ru'
              ? '9\u00a0007\u00a0199\u00a0254\u00a0740\u00a0993,01'
              : '9,007,199,254,740,993.01',
        ),
      );
    });
  }
}
