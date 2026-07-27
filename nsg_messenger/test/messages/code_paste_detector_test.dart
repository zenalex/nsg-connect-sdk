/// **issue #70**: распознавание кода при вставке.
///
/// Цена ошибки несимметрична: не распознали код — человек выделит и
/// нажмёт «Код»; распознали код в обычном тексте — сообщение уехало
/// моноширинным, и это уже испорченное сообщение. Поэтому тесты на
/// ложные срабатывания здесь важнее тестов на распознавание.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/code_paste_detector.dart';

void main() {
  group('распознаём код', () {
    test('dart из редактора', () {
      expect(
        looksLikeCode('''
void main() {
  final x = 1;
  print(x);
}'''),
        isTrue,
      );
    });

    test('python', () {
      expect(
        looksLikeCode('''
def main():
    x = compute(1)
    return x'''),
        isTrue,
      );
    });

    test('html', () {
      expect(
        looksLikeCode('''
<div class="a">
  <span>текст</span>
</div>'''),
        isTrue,
      );
    });

    test('sql', () {
      expect(
        looksLikeCode('''
SELECT id, name
FROM users
WHERE active = 1;'''),
        isTrue,
      );
    });
  });

  group('НЕ трогаем обычный текст (ложные срабатывания дороже)', () {
    test('многострочное письмо', () {
      expect(
        looksLikeCode('''
Привет!
Посмотри, пожалуйста, задачу — там всё описано.
Спасибо.'''),
        isFalse,
      );
    });

    test('список пунктов', () {
      expect(
        looksLikeCode('''
1. Собрать релиз
2. Проверить уведомления
3. Выложить'''),
        isFalse,
      );
    });

    test('стихи с отступами', () {
      expect(
        looksLikeCode('''
   Буря мглою небо кроет,
   Вихри снежные крутя;
   То, как зверь, она завоет,'''),
        isFalse,
        reason: 'отступы + «;» — но это один-два признака, не код',
      );
    });

    test('одна строка кода — не блок (для этого есть inline)', () {
      expect(looksLikeCode('final x = 1;'), isFalse);
      expect(looksLikeCode('SELECT * FROM users;'), isFalse);
    });

    test('пустой и пробельный текст', () {
      expect(looksLikeCode(''), isFalse);
      expect(looksLikeCode('   \n  \n'), isFalse);
    });

    test('уже размеченный markdown не трогаем повторно', () {
      expect(
        looksLikeCode('```dart\nvoid main() {}\n```'),
        isFalse,
        reason: 'пользователь скопировал готовую разметку',
      );
    });

    test('лог приложения — не код', () {
      expect(
        looksLikeCode('''
2026-07-27 21:29:44 INFO оператор пишет chat=13
2026-07-27 21:32:09 INFO заявка создана'''),
        isFalse,
      );
    });
  });

  test('wrapAsCodeBlock оборачивает ограждениями со своих строк', () {
    expect(wrapAsCodeBlock('  a\nb  '), '```\na\nb\n```');
  });
}
