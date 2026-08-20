/// **Карточка монитора в правой панели переживает обновление списка.**
///
/// Жалоба владельца 10.08.2026: «конкретный мониторинг опять разворачивается
/// на весь экран… а для десктопа должен в правой части отображаться, левую не
/// трогая». Карточка перестала быть модальной шторкой и переехала в правую
/// панель — и тем самым стала жить дольше, чем список, из которого её
/// открыли: стрим и перечитывание пересобирают мониторы под ней.
///
/// Сам экран поднять тестом нельзя — ему нужен живой рантайм
/// (`MessengerRuntime.instance.pulse`), поэтому проверяется вынесенная
/// наружу арифметика выбора.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/screens/pulse_screen.dart';

PulseMonitor monitor(int? id, {String name = 'Сервер', String? status}) =>
    PulseMonitor(
      id: id,
      tenantId: 1,
      name: name,
      tokenHash: 'hash-$id',
      periodSeconds: 60,
      graceSeconds: 60,
      status: status ?? 'up',
      paused: false,
      createdBy: 1,
      createdAt: DateTime.utc(2026, 8, 10),
    );

void main() {
  test('ничего не открыто — правая панель показывает дерево', () {
    expect(resolveOpenMonitor([monitor(1)], null), isNull);
  });

  test('открытый монитор находится по id', () {
    final open = monitor(2);
    final found = resolveOpenMonitor([monitor(1), open, monitor(3)], open);
    expect(found?.id, 2);
  });

  test('монитор исчез — панель возвращается к дереву', () {
    // Удалили здесь же или на другом устройстве. Карточка мёртвого
    // монитора отправляла бы «Паузу» и «Пересоздать токен» в никуда.
    final open = monitor(2);
    expect(resolveOpenMonitor([monitor(1), monitor(3)], open), isNull);
  });

  test('берём свежий объект, а не запомненный', () {
    // Имя и статус в шапке карточки обязаны быть текущими: монитор мог
    // упасть, пока карточка открыта, — ради этого мониторинг и нужен.
    final open = monitor(2, name: 'Старое имя', status: 'up');
    final fresh = monitor(2, name: 'Новое имя', status: 'down');

    final found = resolveOpenMonitor([fresh], open);
    expect(found?.name, 'Новое имя');
    expect(found?.status, 'down');
  });

  test('монитор без id не открывается', () {
    // Такого с сервера не приходит, но `id` в модели nullable, и поиск по
    // null совпал бы с любым другим безымянным.
    final open = monitor(null);
    expect(resolveOpenMonitor([monitor(null), monitor(1)], open), isNull);
  });

  test('пустой список закрывает карточку', () {
    expect(resolveOpenMonitor(const [], monitor(1)), isNull);
  });
}
