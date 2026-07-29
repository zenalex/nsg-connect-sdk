/// **issue #79**: комната, открытая прямо сейчас, — по ней решают, не
/// показать ли плашку о новом сообщении.
///
/// Тонкость одна, но важная: на десктопной раскладке чатов на экране
/// несколько, и уходящий в фон не должен стирать заявку того, кто только
/// что стал активным.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/runtime/active_room.dart';

void main() {
  setUp(ActiveRoom.reset);

  test('заявка и снятие', () {
    expect(ActiveRoom.current, isNull);
    ActiveRoom.claim(5);
    expect(ActiveRoom.current, 5);
    ActiveRoom.release(5);
    expect(ActiveRoom.current, isNull);
  });

  test('чужое снятие не трогает активную заявку', () {
    // Порядок колбэков между панелями не гарантирован: новый активный
    // чат может заявиться раньше, чем прежний узнает, что он в фоне.
    ActiveRoom.claim(5);
    ActiveRoom.claim(6);
    ActiveRoom.release(5);
    expect(ActiveRoom.current, 6, reason: 'снял бы чужую — плашки пропали бы');
  });

  test('слушатели видят смену', () {
    final seen = <int?>[];
    void listener() => seen.add(ActiveRoom.current);
    ActiveRoom.listenable.addListener(listener);
    addTearDown(() => ActiveRoom.listenable.removeListener(listener));
    ActiveRoom.claim(1);
    ActiveRoom.release(1);
    expect(seen, [1, null]);
  });
}
