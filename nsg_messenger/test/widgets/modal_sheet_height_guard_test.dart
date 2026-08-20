/// **Сторож против возврата ловушки из #101/#105.**
///
/// `showModalBottomSheet(isScrollControlled: true)` не ограничивает высоту:
/// при длинном содержимом шторка дорастает до верха экрана, ручку
/// перетаскивания фреймворк рисует ПОВЕРХ содержимого (вне `SafeArea`), и она
/// уходит под вырез. Тапнуть мимо шторки тоже некуда — она заняла экран. Оба
/// штатных способа закрыть исчезают разом; так и появилась жалоба про
/// мониторинг под Dynamic Island.
///
/// Без `isScrollControlled` шторка ограничена 9/16 экрана
/// (`_kDefaultScrollControlDisabledMaxHeightRatio` во Flutter) и до выреза не
/// дотягивается — такие вызовы сторож не трогает.
///
/// Проверка по ИСХОДНИКАМ, а не по поведению: воспроизвести это виджет-тестом
/// можно только для конкретного экрана, а забыть ограничение — в любом из
/// двух десятков мест. Ошибку дешевле не пустить, чем ловить.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Начало вызова `showModalBottomSheet<...>` с учётом вложенных дженериков
/// (`<List<RoomSummary>>` регуляркой без счётчика не разобрать).
int _genericEnd(String s, int at) {
  var i = s.indexOf('<', at);
  var depth = 0;
  while (i < s.length) {
    if (s[i] == '<') depth++;
    if (s[i] == '>') {
      depth--;
      if (depth == 0) return i;
    }
    i++;
  }
  return at;
}

void main() {
  test('нет шторок без потолка высоты', () {
    final root = Directory('lib/src');
    final offenders = <String>[];

    for (final f
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      // Сам помощник — исключение: он и есть лечение.
      if (f.path.endsWith('nsg_modal_sheet.dart')) continue;
      final src = f.readAsStringSync();

      for (
        var at = src.indexOf('showModalBottomSheet');
        at >= 0;
        at = src.indexOf('showModalBottomSheet', at + 1)
      ) {
        // Упоминания в комментариях и доках не считаем.
        final lineStart = src.lastIndexOf('\n', at) + 1;
        final linePrefix = src.substring(lineStart, at).trimLeft();
        if (linePrefix.startsWith('//') || linePrefix.startsWith('///')) {
          continue;
        }
        final head = src.substring(
          _genericEnd(src, at),
          (at + 900).clamp(0, src.length),
        );
        final args = head.split('builder:').first;
        if (!args.contains('isScrollControlled: true')) continue;
        if (args.contains('constraints:')) continue;

        final line = '\n'.allMatches(src.substring(0, at)).length + 1;
        offenders.add('${f.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Эти шторки могут дорасти до верха экрана, и ручка уйдёт под вырез '
          '(#101). Возьмите showNsgModalSheet из widgets/nsg_modal_sheet.dart '
          'либо задайте свой constraints, как в message_action_sheet.dart:\n'
          '  ${offenders.join('\n  ')}',
    );
  });
}
