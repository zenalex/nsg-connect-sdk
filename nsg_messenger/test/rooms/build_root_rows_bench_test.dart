import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **issue #26** — сколько на самом деле стоит группировка по папкам.
///
/// `ChatsListController.rootRows` — геттер, который на КАЖДОЕ обращение
/// заново вызывает `buildRootRows` (обход комнат + сортировка), и дёргается
/// он прямо из `build()` экрана. Выглядит подозрительно, поэтому возник
/// вопрос: не в папках ли причина лагов списка и не нужна ли модель
/// «у чата есть родитель» вместо вычисляемых папок.
///
/// Этот бенчмарк отвечает числом. Бюджет кадра на 60 Гц — 16.67 мс.
void main() {
  RoomSummary direct(int id) => RoomSummary(
    id: id,
    name: 'Собеседник $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.direct,
    lastMessageAt: DateTime(2026, 7, 19).subtract(Duration(minutes: id)),
  );

  RoomSummary product(int id, int productId) => RoomSummary(
    id: id,
    name: 'Группа $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    productId: productId,
    roomType: RoomType.group,
    lastMessageAt: DateTime(2026, 7, 19).subtract(Duration(minutes: id)),
  );

  /// Прогоняет [iterations] пересборок и печатает среднее на одну.
  void bench(String label, List<RoomSummary> rooms) {
    final folders = buildFolders(rooms);
    // Прогрев — JIT не должен попасть в измерение.
    for (var i = 0; i < 200; i++) {
      buildRootRows(rooms, folders);
    }
    const iterations = 2000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      buildRootRows(rooms, folders);
    }
    sw.stop();
    final perCallUs = sw.elapsedMicroseconds / iterations;
    // ignore: avoid_print
    print(
      '$label: ${rooms.length} комнат, ${folders.length} папок → '
      '${perCallUs.toStringAsFixed(1)} мкс на пересборку '
      '(${(perCallUs / 16670 * 100).toStringAsFixed(3)}% бюджета кадра)',
    );
  }

  test('стоимость buildRootRows на реальных и завышенных объёмах', () {
    // Как на тестовом стенде.
    bench('стенд', [
      for (var i = 0; i < 18; i++)
        i.isEven ? direct(i) : product(i, 10 + (i % 3)),
    ]);
    // Как просили для профилирования.
    bench('целевой', [
      for (var i = 0; i < 50; i++)
        i.isEven ? direct(i) : product(i, 10 + (i % 5)),
    ]);
    // Заведомо больше любого реального пользователя.
    bench('стресс', [
      for (var i = 0; i < 500; i++)
        i.isEven ? direct(i) : product(i, 10 + (i % 20)),
    ]);
  });
}
