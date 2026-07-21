import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/presence/last_seen_format.dart';

/// **TASK55 итер.1**: форматирование last seen (Telegram-стиль, ru).
void main() {
  late NsgL10n l;

  setUp(() async {
    l = await NsgL10n.delegate.load(const Locale('ru'));
  });

  final now = DateTime(2026, 7, 13, 15, 30);

  test('null → null (подпись не показывается)', () {
    expect(humanLastSeen(null, l, now: now), isNull);
  });

  test('<1 мин → «только что»', () {
    expect(
      humanLastSeen(now.subtract(const Duration(seconds: 30)), l, now: now),
      'был(а) в сети только что',
    );
  });

  test('<60 мин → «N мин назад»', () {
    expect(
      humanLastSeen(now.subtract(const Duration(minutes: 5)), l, now: now),
      'был(а) в сети 5 мин назад',
    );
  });

  test('сегодня → «сегодня в HH:MM»', () {
    expect(
      humanLastSeen(DateTime(2026, 7, 13, 9, 5), l, now: now),
      'был(а) в сети сегодня в 09:05',
    );
  });

  test('вчера → «вчера в HH:MM»', () {
    expect(
      humanLastSeen(DateTime(2026, 7, 12, 22, 41), l, now: now),
      'был(а) в сети вчера в 22:41',
    );
  });

  test('давно → дата DD.MM.YYYY', () {
    expect(
      humanLastSeen(DateTime(2026, 7, 1, 10, 0), l, now: now),
      'был(а) в сети 01.07.2026',
    );
  });
}
