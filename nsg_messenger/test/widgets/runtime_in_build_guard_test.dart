/// **Сторож против возврата беды из #145/#149/#167: бросающий рантайм в
/// `build`.**
///
/// Снос рантайма под живым деревом (смена профиля, выход, истёкшая сессия,
/// ранний кадр до `init`) делает бросающие геттеры `MessengerRuntime`
/// опасными: бросок из `build` — это отказ сборки кадра. В #145 он обернулся
/// вечным зависанием, в #167 — сломанным деревом рендера на Windows
/// (`ErrorWidget` встал на место sliver-заголовка, а `RenderErrorBox` не
/// sliver).
///
/// Проверка по ИСХОДНИКАМ, а не по поведению: воспроизвести это виджет-тестом
/// можно только для конкретного экрана, а забыть — в любом из сотни
/// `build`-ов.
///
/// ## Что изменилось после #167 — и почему прежний сторож промолчал
///
/// Он существовал с #149 и пропустил ровно ту беду, ради которой писался.
/// Три отдельные дыры, каждая из которых хоронила проверку молча:
///
///   1. **Список был перечислительным.** Запрещались четыре обращения
///      (`client`, `session`, `currentMessengerUserId`, `NsgMessenger.session`),
///      а бросающих геттеров в рантайме **восемнадцать**. Упало на
///      `contacts` — его в списке не было. Теперь список НЕ пишется руками:
///      он выводится из `messenger_runtime.dart` — геттер с `throw` в теле
///      автоматически становится запрещённым в `build`. Добавят
///      девятнадцатый — сторож узнает об этом сам;
///   2. **Поиск шёл по подстроке.** `dart format` разносит длинную цепочку
///      по строкам, и текста `MessengerRuntime.instance.contacts` в файле
///      физически НЕ БЫЛО — были `MessengerRuntime`, `.instance`,
///      `.contacts` на разных строках. Сторожа побеждало форматирование.
///      Теперь перед поиском пробелы вокруг точек схлопываются;
///   3. **Смотрел только на себя.** Сканировался `lib/src` пакета SDK, а
///      упало в `apps/chatista` — туда сторож не заглядывал вовсе. Правило
///      описывает, как ПОЛЬЗОВАТЬСЯ рантаймом, поэтому проверяются все
///      потребители в этом репозитории.
///
/// ## Что разрешено
///
/// Форма `*OrNull` (`clientOrNull`, `contactsOrNull`, `callsOrNull`): виджет
/// умеет жить без данных и молчит, когда рантайма нет. Бросающие геттеры
/// остаются для путей ДЕЙСТВИЯ (нажатие, отправка) — там исключение уместно
/// и видно человеку как отказ операции, а не как чёрный экран.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Где искать потребителей рантайма. Пути — относительно корня пакета SDK
/// (там запускаются тесты). Несуществующие молча пропускаем: репозиторий
/// могут выложить и без хост-приложения.
const _roots = <String>['lib/src', '../../apps/chatista/lib'];

/// Откуда берётся список запрещённого.
const _runtimeSource = 'lib/src/messenger_runtime.dart';

/// Убрать комментарии — иначе сторож ловит собственные объяснения в доках
/// (в `nsg_avatar_image.dart` разбор #145 упоминает `instance.client`).
String _stripComments(String src) {
  final out = StringBuffer();
  var i = 0;
  while (i < src.length) {
    if (src.startsWith('//', i)) {
      final nl = src.indexOf('\n', i);
      if (nl < 0) break;
      out.write('\n'); // держим нумерацию строк
      i = nl + 1;
      continue;
    }
    if (src.startsWith('/*', i)) {
      final end = src.indexOf('*/', i + 2);
      if (end < 0) break;
      out.write('\n' * '\n'.allMatches(src.substring(i, end)).length);
      i = end + 2;
      continue;
    }
    out.write(src[i]);
    i++;
  }
  return out.toString();
}

/// Тело метода от первой `{` после [start] до парной закрывающей.
/// `null` — тело не найдено (например, `=>`-форма).
({int from, int to})? _body(String src, int start) {
  final open = src.indexOf('{', start);
  if (open < 0) return null;
  // `=>` до `{` — выражение-тело, фигурная скобка чужая.
  final arrow = src.indexOf('=>', start);
  if (arrow >= 0 && arrow < open) return null;
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    if (src[i] == '{') depth++;
    if (src[i] == '}') {
      depth--;
      if (depth == 0) return (from: open, to: i);
    }
  }
  return null;
}

/// Схлопнуть пробелы вокруг точек: цепочка, разнесённая форматтером по
/// строкам, должна искаться так же, как записанная в одну.
String _flattenChains(String src) => src.replaceAll(RegExp(r'\s*\.\s*'), '.');

/// Геттеры рантайма, которые БРОСАЮТ при снесённом/не поднятом рантайме.
///
/// Выводим из исходника, а не перечисляем: перечисление отстанет от кода
/// молча — так и вышло с `contacts` в #167.
Set<String> _throwingGetters(String runtimeSrc) {
  final found = <String>{};
  final re = RegExp(r'^\s*[\w<>?, ]+\s+get\s+(\w+)\s*\{', multiLine: true);
  for (final m in re.allMatches(runtimeSrc)) {
    final span = _body(runtimeSrc, m.end - 1);
    if (span == null) continue;
    if (runtimeSrc.substring(span.from, span.to).contains('throw')) {
      found.add(m.group(1)!);
    }
  }
  // `=>`-делегаты к бросающему: тела с `throw` у них нет, а бросают.
  found.add('currentMessengerUserId');
  return found;
}

void main() {
  test('в build() нет бросающих обращений к рантайму', () {
    final runtimeFile = File(_runtimeSource);
    expect(
      runtimeFile.existsSync(),
      isTrue,
      reason:
          'Не найден $_runtimeSource — список запрещённого выводится из него, '
          'и без файла сторож проверял бы пустоту, то есть ничего.',
    );
    final throwing = _throwingGetters(
      _stripComments(runtimeFile.readAsStringSync()),
    );
    expect(
      throwing.length,
      greaterThan(4),
      reason:
          'Бросающих геттеров подозрительно мало — разбор исходника, похоже, '
          'сломался, и сторож молча перестал ловить.',
    );

    final offenders = <String>[];
    final buildRe = RegExp(r'\bWidget\s+build\s*\(\s*BuildContext');

    for (final rootPath in _roots) {
      final root = Directory(rootPath);
      if (!root.existsSync()) continue;

      for (final f
          in root
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final src = _stripComments(f.readAsStringSync());

        for (final m in buildRe.allMatches(src)) {
          // `=>`-форма тоже под запретом: тело есть, просто без скобок.
          final span = _body(src, m.end);
          final body = span == null
              ? src.substring(m.end, _statementEnd(src, m.end))
              : src.substring(span.from, span.to);
          final flat = _flattenChains(body);
          final line = '\n'.allMatches(src.substring(0, m.end)).length + 1;

          for (final getter in throwing) {
            // Граница слова справа: `contacts` не должен ловить
            // `contactsOrNull`, а `client` — `clientOrNull`.
            final re = RegExp('MessengerRuntime\\.instance\\.$getter\\b');
            if (re.hasMatch(flat)) {
              offenders.add('${f.path} (build около строки $line): .$getter');
            }
          }
          if (RegExp(r'NsgMessenger\.session\b').hasMatch(flat)) {
            offenders.add(
              '${f.path} (build около строки $line): NsgMessenger.session',
            );
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'В build() рантайм спрашивают только через *OrNull — иначе снос '
          'рантайма (смена профиля, logout, истёкшая сессия) превращается в '
          'отказ сборки кадра, см. #145/#149/#167. Для путей действия '
          'бросающие геттеры остаются как были.\n${offenders.join('\n')}',
    );
  });

  test('сторожа не побеждает форматирование', () {
    // #167: цепочку разнесло по строкам, и поиск по подстроке ослеп.
    // Проверяем сам механизм, а не последствия.
    const wrapped = '''
      valueListenable: MessengerRuntime
          .instance
          .contacts
          .incomingRequestCount,
    ''';
    expect(
      wrapped.contains('MessengerRuntime.instance.contacts'),
      isFalse,
      reason: 'исходный текст и правда не содержит склеенной цепочки',
    );
    expect(
      _flattenChains(wrapped).contains('MessengerRuntime.instance.contacts'),
      isTrue,
      reason: 'после схлопывания точек цепочка обязана находиться',
    );
  });

  test('список запрещённого выводится из рантайма, а не из этого файла', () {
    final src = _stripComments(File(_runtimeSource).readAsStringSync());
    final throwing = _throwingGetters(src);
    // Те, на которых уже обжигались: #145 — client/session, #167 — contacts.
    expect(throwing, containsAll(<String>['client', 'session', 'contacts']));
    // А безопасные, которые в `build` нужны и ничего не ломают, — не в списке.
    expect(throwing, isNot(contains('locale')));
    expect(throwing, isNot(contains('connectionState')));
  });
}

/// Конец выражения-тела (`=> ...;`) — для `build`-ов без фигурных скобок.
int _statementEnd(String src, int from) {
  final semi = src.indexOf(';', from);
  return semi < 0 ? src.length : semi;
}
