/// **Сторож против возврата беды из #145/#149: бросающий рантайм в `build`.**
///
/// Смена профиля сносит рантайм под живым деревом (`NsgMessenger.dispose()`),
/// и `MessengerRuntime.client` / `.session` в этот момент БРОСАЮТ. Бросок из
/// `build` — это отказ сборки кадра: в #145 он обернулся вечным зависанием
/// приложения, потому что аварийный экран сам строился и сам же падал.
///
/// В хосте (Chatista) корень дерева на время смены уходит на нейтральный
/// экран (`AppRootView`, #149) — сноситься под виджетами больше нечему. Но
/// правило «в `build` рантайм спрашивают только так, чтобы можно было
/// промолчать» этим не гарантировано: следующий виджет с `instance.client` в
/// `build` вернёт ту же беду при любом другом сносе (logout, истёкшая
/// сессия, ранний кадр до `init`).
///
/// Поэтому проверка по ИСХОДНИКАМ, а не по поведению: воспроизвести это
/// виджет-тестом можно только для конкретного экрана, а забыть — в любом из
/// сотни `build`-ов. В `build` разрешён `clientOrNull` (виджет умеет жить без
/// данных); `client`/`session` остаются для путей ДЕЙСТВИЯ (нажатие, отправка)
/// — там бросок уместен и виден пользователю как ошибка операции, а не как
/// чёрный экран.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Обращения, которые бросают при снесённом/не поднятом рантайме.
const _throwing = <String>[
  'MessengerRuntime.instance.client',
  'MessengerRuntime.instance.session',
  'MessengerRuntime.instance.currentMessengerUserId',
  'NsgMessenger.session',
];

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

void main() {
  test('в build() нет бросающих обращений к рантайму', () {
    final root = Directory('lib/src');
    final offenders = <String>[];

    for (final f in root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = _stripComments(f.readAsStringSync());
      final buildRe = RegExp(r'\bWidget\s+build\s*\(\s*BuildContext');

      for (final m in buildRe.allMatches(src)) {
        // `=>`-форма тоже под запретом: тело есть, просто без скобок.
        final span = _body(src, m.end);
        final body = span == null
            ? src.substring(m.end, _statementEnd(src, m.end))
            : src.substring(span.from, span.to);

        for (final needle in _throwing) {
          var at = body.indexOf(needle);
          while (at >= 0) {
            final tail = body.substring(
              at + needle.length,
              (at + needle.length + 6).clamp(0, body.length),
            );
            // `clientOrNull` / `sessionOrNull` — разрешённая форма.
            if (!tail.startsWith('OrNull')) {
              final line = '\n'.allMatches(src.substring(0, m.end)).length + 1;
              offenders.add('${f.path} (build около строки $line): $needle');
            }
            at = body.indexOf(needle, at + 1);
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
          'отказ сборки кадра, см. #145/#149. Для путей действия '
          'client/session остаются как были.\n${offenders.join('\n')}',
    );
  });
}

/// Конец выражения-тела (`=> ...;`) — для `build`-ов без фигурных скобок.
int _statementEnd(String src, int from) {
  final semi = src.indexOf(';', from);
  return semi < 0 ? src.length : semi;
}
