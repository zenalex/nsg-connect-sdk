/// **issue #57**: разбивка длинного текста вместо молчаливой обрезки.
///
/// Главное свойство, которое защищаем: **ничего не теряется**. Инцидент
/// постановщика — вставил длинный текст, он молча обрезался, и заметить
/// потерю почти невозможно.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/message_splitter.dart';

void main() {
  group('splitMessageBody', () {
    test('короткий текст не трогаем', () {
      expect(splitMessageBody('привет', limit: 100), ['привет']);
    });

    test('пустой текст — ноль частей (отправлять нечего)', () {
      expect(splitMessageBody('   \n  ', limit: 100), isEmpty);
    });

    test('НИЧЕГО НЕ ТЕРЯЕТСЯ: склейка частей даёт исходные слова', () {
      final text = List.generate(200, (i) => 'слово$i').join(' ');
      final parts = splitMessageBody(text, limit: 100);
      expect(parts.length, greaterThan(1));
      for (final p in parts) {
        expect(p.length, lessThanOrEqualTo(100));
      }
      expect(parts.join(' ').split(RegExp(r'\s+')),
          text.split(RegExp(r'\s+')));
    });

    test('рез по абзацу, когда абзац влезает целиком', () {
      final a = 'A' * 40;
      final b = 'B' * 40;
      final parts = splitMessageBody('$a\n\n$b', limit: 60);
      expect(parts, [a, b]);
    });

    test('рез по слову, а не посреди слова', () {
      final text = '${'раз два три четыре пять ' * 10}конец';
      final parts = splitMessageBody(text, limit: 50);
      for (final p in parts) {
        expect(p.startsWith(' '), isFalse);
        expect(p.trim(), p);
      }
      // Ни одно слово не разорвано: все куски — целые слова исходника.
      final words = text.split(' ').toSet();
      for (final p in parts) {
        for (final w in p.split(RegExp(r'\s+'))) {
          expect(words.contains(w), isTrue, reason: 'разорвано слово: $w');
        }
      }
    });

    test('сверхдлинное слово режется жёстко — иначе не отправить вовсе', () {
      final token = 'x' * 250; // base64/ссылка без пробелов
      final parts = splitMessageBody(token, limit: 100);
      expect(parts.length, 3);
      expect(parts.join(), token);
    });

    test('код-блок не рвётся молча: закрывается и переоткрывается', () {
      final code = List.generate(40, (i) => 'line $i;').join('\n');
      final parts = splitMessageBody('```dart\n$code\n```', limit: 120);
      expect(parts.length, greaterThan(1));
      for (final p in parts) {
        expect(p.trimLeft().startsWith('```dart'), isTrue,
            reason: 'каждая часть начинается блоком: $p');
        expect(p.trimRight().endsWith('```'), isTrue,
            reason: 'и закрывается: $p');
        // Чётное число ограждений = блок в части сбалансирован.
        expect('```'.allMatches(p).length.isEven, isTrue);
      }
      // Код не потерян.
      final joined = parts
          .join('\n')
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('```'))
          .join('\n');
      expect(joined.replaceAll('\n', ''), code.replaceAll('\n', ''));
    });

    test('текст вокруг блока остаётся текстом', () {
      final parts = splitMessageBody(
        'до\n```\n${'кодовая строка\n' * 20}```\nпосле',
        limit: 100,
      );
      expect(parts.first.startsWith('до'), isTrue);
      expect(parts.last.trimRight().endsWith('после'), isTrue);
    });

    test('части не длиннее лимита даже с переоткрытием блока', () {
      final parts = splitMessageBody(
        '```python\n${'a' * 500}\n```',
        limit: 64,
      );
      for (final p in parts) {
        expect(p.length, lessThanOrEqualTo(64), reason: p);
      }
    });

    test('слишком маленький лимит — ошибка, а не бесконечный цикл', () {
      expect(() => splitMessageBody('текст', limit: 4), throwsArgumentError);
    });
  });

  group('messagePartCount', () {
    test('счёт частей — для предупреждения перед отправкой', () {
      expect(messagePartCount('короткий', limit: 100), 1);
      expect(messagePartCount('x' * 250, limit: 100), 3);
    });
  });
}
