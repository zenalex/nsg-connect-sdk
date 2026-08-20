/// **Разбор списка целей, вставленного текстом** (TASK94 §2, issue #108).
///
/// Интегратор прислал 13 пар `host:port` и попросил завести их «через
/// штатный API с audit». Вбивать по четыре поля тринадцать раз — способ
/// ошибиться, а ошибка здесь означает разрешение пробам ходить не туда.
/// Поэтому разбор проверяется отдельно от экрана.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/pulse/probe_allowlist_paste.dart';

void main() {
  test('список интегратора разбирается целиком', () {
    // Ровно тот текст, что пришёл в issue #108 (первые строки обоих узлов).
    const text = '''
92.255.105.45:443
92.255.105.45:8081

78.37.191.63:5077
78.37.191.63:60531
''';
    final r = parseProbeAllowlistPaste(text);

    expect(r.rejected, isEmpty);
    expect(r.targets.map((t) => t.toString()).toList(), [
      '92.255.105.45:443',
      '92.255.105.45:8081',
      '78.37.191.63:5077',
      '78.37.191.63:60531',
    ]);
    expect(
      r.targets.first.port,
      443,
      reason: 'порт обязан быть числом, а не куском строки',
    );
  });

  test('маска разбирается и не путается с портом', () {
    final r = parseProbeAllowlistPaste('92.255.105.45/32:443');
    expect(r.targets.single.address, '92.255.105.45');
    expect(r.targets.single.prefixLength, 32);
    expect(r.targets.single.port, 443);
  });

  test('IPv6 только в скобках — иначе адрес не отличить от порта', () {
    // В самом адресе двоеточий сколько угодно, и правило «последнее
    // двоеточие — порт» ломается на первом же таком адресе. Угадывать
    // нельзя: ошибка даст разрешение не на тот адрес.
    final ok = parseProbeAllowlistPaste('[2001:db8::1]:443');
    expect(ok.targets.single.address, '2001:db8::1');
    expect(ok.targets.single.port, 443);

    final bad = parseProbeAllowlistPaste('2001:db8::1:443');
    expect(
      bad.targets,
      isEmpty,
      reason: 'без скобок это не адрес с портом, а догадка',
    );
    expect(bad.rejected.single, '2001:db8::1:443');
  });

  test('маска IPv4 больше 32 отвергается', () {
    // `/64` у IPv4 — почти наверняка скопированная не оттуда строка.
    // Пропустить её значит разрешить пробам ходить не туда, куда думал
    // человек.
    expect(parseProbeAllowlistPaste('10.0.0.1/64:443').targets, isEmpty);
    expect(parseProbeAllowlistPaste('[2001:db8::]/64:443').targets, hasLength(1));
  });

  test('порт вне диапазона — отказ, а не молчаливое усечение', () {
    expect(parseProbeAllowlistPaste('1.2.3.4:70000').rejected, hasLength(1));
    expect(parseProbeAllowlistPaste('1.2.3.4:0').rejected, hasLength(1));
  });

  test('пустые строки и комментарии пропускаются', () {
    final r = parseProbeAllowlistPaste('''
# узел заказчика
1.2.3.4:443

  # ещё комментарий
''');
    expect(r.targets, hasLength(1));
    expect(r.rejected, isEmpty);
  });

  test('повтор цели не ошибка, но и не вторая строка', () {
    // В присланных списках дубли обычны; падать на них значило бы
    // заставлять человека вычищать текст руками.
    final r = parseProbeAllowlistPaste('1.2.3.4:443\n1.2.3.4:443');
    expect(r.targets, hasLength(1));
    expect(r.duplicates, 1);
    expect(r.rejected, isEmpty);
  });

  test('битая строка называется целиком, а не пересказывается', () {
    // Человек ищет свою строку глазами; наш пересказ он в своём списке
    // не найдёт.
    final r = parseProbeAllowlistPaste('нежданчик\n1.2.3.4:443');
    expect(r.rejected.single, 'нежданчик');
    expect(r.targets, hasLength(1));
  });
}
