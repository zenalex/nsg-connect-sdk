/// **Подвид «Поддержка» вместо «Групп».**
///
/// Предложение владельца 10.08.2026: «„Группы“ получились неинтересные —
/// туда попадает по сути всё. Давай заменим на поддержку: там будут группы
/// чатов поддержки и мои личные чаты поддержек по всем продуктам». И
/// уточнение: «оставить как на основной — чужие чаты поддержки папками,
/// мои списком; по сути просто фильтр на чаты в основной вкладке».
///
/// Отсюда и форма проверки: это ФИЛЬТР готового корневого списка, а не
/// вторая раскладка. Один и тот же чат обязан выглядеть одинаково на
/// вкладке «Все» и в подвиде — иначе человек решит, что это разные чаты.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

RoomSummary supportRoom({
  required int id,
  required int productId,
  required bool mine,
  DateTime? at,
}) => RoomSummary(
  id: id,
  name: mine ? 'Продукт $productId — вопрос' : 'Заявитель $id',
  unreadCount: 0,
  archived: false,
  muted: false,
  productId: productId,
  roomType: RoomType.support,
  productName: 'Продукт $productId',
  supportViewerIsRequester: mine,
  lastMessageAt: at,
);

RoomSummary direct(int id) => RoomSummary(
  id: id,
  name: 'Собеседник $id',
  unreadCount: 0,
  archived: false,
  muted: false,
  roomType: RoomType.direct,
  lastMessageAt: DateTime.utc(2026, 8, 10),
);

RoomSummary group(int id) => RoomSummary(
  id: id,
  name: 'Группа $id',
  unreadCount: 0,
  archived: false,
  muted: false,
  roomType: RoomType.group,
  lastMessageAt: DateTime.utc(2026, 8, 10),
);

List<ChatRootRow> rowsFor(List<RoomSummary> rooms) =>
    buildRootRows(rooms, buildFolders(rooms));

void main() {
  final rooms = [
    supportRoom(id: 1, productId: 7, mine: false, at: DateTime.utc(2026, 8, 9)),
    supportRoom(id: 2, productId: 7, mine: false, at: DateTime.utc(2026, 8, 8)),
    supportRoom(id: 3, productId: 7, mine: true, at: DateTime.utc(2026, 8, 7)),
    supportRoom(id: 4, productId: 9, mine: true, at: DateTime.utc(2026, 8, 6)),
    direct(5),
    group(6),
  ];

  test('остаются очереди папками и свои обращения строками', () {
    final support = supportRootRows(rowsFor(rooms));

    final folders = support.whereType<ChatFolderRow>().toList();
    final chats = support.whereType<ChatRoomRow>().toList();

    expect(
      folders.map((f) => f.folder.productId),
      [7],
      reason: 'очередь есть только по продукту, где смотрящий оператор',
    );
    expect(
      chats.map((c) => c.room.id).toSet(),
      {3, 4},
      reason:
          'свои обращения по ВСЕМ продуктам, включая тот, где я не оператор',
    );
  });

  test('личные чаты и группы сюда не попадают', () {
    // Ровно то, чем был плох прежний подвид: под «не direct» попадало всё.
    final support = supportRootRows(rowsFor(rooms));
    final ids = support.whereType<ChatRoomRow>().map((c) => c.room.id);

    expect(ids, isNot(contains(5)));
    expect(ids, isNot(contains(6)));
  });

  test('строки те же самые, что на вкладке «Все»', () {
    // Подвид — фильтр, а не вторая раскладка: объекты обязаны быть теми же,
    // иначе рендер разойдётся и один чат покажется двумя разными.
    final all = rowsFor(rooms);
    for (final row in supportRootRows(all)) {
      expect(all, contains(row));
    }
  });

  test('порядок не переставляется', () {
    // Сортировка уже сделана в корневом списке; пересортировать здесь
    // значило бы показать те же чаты в другом порядке.
    final all = rowsFor(rooms);
    final support = supportRootRows(all);
    final expected = all.where(support.contains).toList();

    expect(support, expected);
  });

  test('без поддержки подвид пуст, а не показывает всё подряд', () {
    // Пустой список честнее: «фильтр не нашёл ничего» и «фильтр не
    // сработал» человек различает только по этому.
    final support = supportRootRows(rowsFor([direct(5), group(6)]));
    expect(support, isEmpty);
  });
}
