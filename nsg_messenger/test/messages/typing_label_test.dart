import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n_en.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n_ru.dart';
import 'package:nsg_messenger/src/messages/typing_label.dart';

/// Формулировка индикатора «кто готовит сообщение».
///
/// Повод: бот поддержки — агент, он думает минутами и всё это время
/// честно шлёт `m.typing`. Механика индикатора при этом верна, врало
/// СЛОВО — владелец увидел «печатает 10 минут» и решил, что бот завис.
/// Поэтому тесты здесь не про верстку, а про то, какой ГЛАГОЛ выбран.
void main() {
  final ru = NsgL10nRu();
  final en = NsgL10nEn();

  group('один печатающий', () {
    test('человек — прежнее «печатает…»', () {
      expect(
        typingIndicatorLabel(ru, count: 1, botCount: 0, names: const ['Маша']),
        'Маша печатает…',
      );
    });

    test('бот — другой глагол, без слова «печатает»', () {
      final label = typingIndicatorLabel(
        ru,
        count: 1,
        botCount: 1,
        names: const ['Помощник'],
      );
      expect(label, 'Помощник анализирует…');
      expect(
        label.contains('печата'),
        isFalse,
        reason: 'ровно этого слова про бота быть не должно — это и был баг',
      );
    });

    test('EN: у бота свой глагол', () {
      expect(
        typingIndicatorLabel(en, count: 1, botCount: 1, names: const ['Bot']),
        'Bot is thinking…',
      );
      expect(
        typingIndicatorLabel(en, count: 1, botCount: 0, names: const ['Bob']),
        'Bob is typing…',
      );
    });
  });

  group('несколько печатающих', () {
    test('только люди, двое — прежняя пара с именами', () {
      expect(
        typingIndicatorLabel(
          ru,
          count: 2,
          botCount: 0,
          names: const ['Маша', 'Петя'],
        ),
        'Маша и Петя печатают…',
      );
    });

    test('только люди, трое — прежний счётчик', () {
      expect(
        typingIndicatorLabel(ru, count: 3, botCount: 0),
        '3 участников печатают…',
      );
    });

    test('человек И бот — нейтральный глагол, не врём ни про кого', () {
      final label = typingIndicatorLabel(
        ru,
        count: 2,
        botCount: 1,
        names: const ['Маша', 'Помощник'],
      );
      expect(label, '2 участника готовят ответ…');
      expect(
        label.contains('печата'),
        isFalse,
        reason: '«печатают» соврало бы про бота',
      );
      expect(
        label.contains('анализир'),
        isFalse,
        reason: '«анализируют» соврало бы про человека',
      );
    });

    test('двое ботов — тот же нейтральный глагол (имён не перечисляем)', () {
      expect(
        typingIndicatorLabel(
          ru,
          count: 2,
          botCount: 2,
          names: const ['Бот А', 'Бот Б'],
        ),
        '2 участника готовят ответ…',
      );
    });

    test('EN mixed', () {
      expect(
        typingIndicatorLabel(en, count: 3, botCount: 1),
        '3 participants are preparing a reply…',
      );
    });
  });

  group('вырожденные случаи', () {
    test('никто не печатает — пустая строка (индикатор прячут)', () {
      expect(typingIndicatorLabel(ru, count: 0, botCount: 0), '');
    });

    test('имя неизвестно — счётная формулировка, а не пустое имя', () {
      expect(
        typingIndicatorLabel(ru, count: 1, botCount: 0),
        '1 участников печатают…',
      );
    });

    test('botCount=0 — ровно прежнее поведение (старый сервер без поля)', () {
      expect(
        typingIndicatorLabel(ru, count: 1, botCount: 0, names: const ['Бот']),
        'Бот печатает…',
      );
    });
  });
}
