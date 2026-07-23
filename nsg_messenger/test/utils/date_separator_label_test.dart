import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n_en.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n_ru.dart';
import 'package:nsg_messenger/src/utils/relative_time.dart';

/// **TASK86**: чистая логика метки разделителя даты (без виджетов).
///
/// Классификация ([dateSeparatorKind]) считается по ЛОКАЛЬНОМУ дню — тесты
/// строят локальные `DateTime`, `now` фиксируем, чтобы «сегодня»/«вчера»
/// были детерминированы. Форматы (день недели/месяц/год) проверяем на
/// конкретных известных датах в ru+en.
void main() {
  // DateFormat для ru/en требует инициализированной symbol-data. В приложении
  // это делает `GlobalMaterialLocalizations.load`; в чистом тесте — вручную.
  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
  });

  // Четверг, 23 июля 2026, полдень — опорное «сейчас».
  final now = DateTime(2026, 7, 23, 12);
  final ru = NsgL10nRu();
  final en = NsgL10nEn();
  const localeRu = Locale('ru');
  const localeEn = Locale('en');

  group('dateSeparatorKind — классификация по локальному дню', () {
    test('сегодня — тот же день', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 23, 9), now: now),
        DateSeparatorKind.today,
      );
    });

    test('сообщение в 01:00 — это сегодня, а не вчера', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 23, 1), now: now),
        DateSeparatorKind.today,
      );
    });

    test('локальная полночь 00:00 — сегодня', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 23, 0, 0), now: now),
        DateSeparatorKind.today,
      );
    });

    test('вчера 23:59 — именно вчера (граница дня)', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 22, 23, 59), now: now),
        DateSeparatorKind.yesterday,
      );
    });

    test('будущее (clock skew) клампится к сегодня', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 24, 8), now: now),
        DateSeparatorKind.today,
      );
    });

    test('2 дня назад — день недели', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 21, 10), now: now),
        DateSeparatorKind.weekday,
      );
    });

    test('6 дней назад — ещё день недели', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 17, 10), now: now),
        DateSeparatorKind.weekday,
      );
    });

    test('7 дней назад — уже «день месяц» (этот год)', () {
      expect(
        dateSeparatorKind(DateTime(2026, 7, 16, 10), now: now),
        DateSeparatorKind.thisYear,
      );
    });

    test('прошлый год — «день месяц год»', () {
      expect(
        dateSeparatorKind(DateTime(2025, 12, 31, 10), now: now),
        DateSeparatorKind.older,
      );
    });
  });

  group('dateSeparatorLabel — RU', () {
    test('сегодня / вчера', () {
      expect(
        dateSeparatorLabel(DateTime(2026, 7, 23, 9),
            now: now, l10n: ru, locale: localeRu),
        'Сегодня',
      );
      expect(
        dateSeparatorLabel(DateTime(2026, 7, 22, 9),
            now: now, l10n: ru, locale: localeRu),
        'Вчера',
      );
    });

    test('день недели — с заглавной («Понедельник»)', () {
      // 2026-07-20 — понедельник, 3 дня назад.
      expect(
        dateSeparatorLabel(DateTime(2026, 7, 20, 9),
            now: now, l10n: ru, locale: localeRu),
        'Понедельник',
      );
    });

    test('этот год — «день месяц»', () {
      expect(
        dateSeparatorLabel(DateTime(2026, 2, 15, 9),
            now: now, l10n: ru, locale: localeRu),
        '15 февраля',
      );
    });

    test('старше — «день месяц год», без суффикса « г.»', () {
      expect(
        dateSeparatorLabel(DateTime(2025, 2, 15, 9),
            now: now, l10n: ru, locale: localeRu),
        '15 февраля 2025',
      );
    });
  });

  group('dateSeparatorLabel — EN', () {
    test('today / yesterday', () {
      expect(
        dateSeparatorLabel(DateTime(2026, 7, 23, 9),
            now: now, l10n: en, locale: localeEn),
        'Today',
      );
      expect(
        dateSeparatorLabel(DateTime(2026, 7, 22, 9),
            now: now, l10n: en, locale: localeEn),
        'Yesterday',
      );
    });

    test('weekday — full name («Monday»)', () {
      expect(
        dateSeparatorLabel(DateTime(2026, 7, 20, 9),
            now: now, l10n: en, locale: localeEn),
        'Monday',
      );
    });

    test('this year — «d MMMM»', () {
      expect(
        dateSeparatorLabel(DateTime(2026, 2, 15, 9),
            now: now, l10n: en, locale: localeEn),
        '15 February',
      );
    });

    test('older — «d MMMM y»', () {
      expect(
        dateSeparatorLabel(DateTime(2025, 2, 15, 9),
            now: now, l10n: en, locale: localeEn),
        '15 February 2025',
      );
    });
  });
}
