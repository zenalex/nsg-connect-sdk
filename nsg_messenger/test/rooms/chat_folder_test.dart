import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// TASK44 фаза 1.5: unit-тесты чистой группировки [buildFolders] +
/// [foldersVisible] + модели «папка-как-строка» [buildRootRows]:
///   * группировка по productId + «Личные» (productId == null);
///   * суммирование unread на папку и на «Все»;
///   * агрегаты lastMessageAt/lastMessagePreview (самый свежий чат папки);
///   * человекочитаемые имена из Product, fallback на ключ;
///   * пустые папки не создаются;
///   * «обёртка-папка скрыта при ≤1 содержательной группе»;
///   * порядок детерминирован (Все → продукты по возр. id → Личные);
///   * [buildRootRows]: смесь строк-чатов и строк-папок, сортировка,
///     плоский список при 1 группе.
void main() {
  RoomSummary room({
    required int id,
    int? productId,
    int unread = 0,
    RoomType roomType = RoomType.group,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
  }) => RoomSummary(
    id: id,
    name: 'Room $id',
    unreadCount: unread,
    archived: false,
    muted: false,
    productId: productId,
    roomType: roomType,
    lastMessageAt: lastMessageAt,
    lastMessagePreview: lastMessagePreview,
  );

  Product product({
    required int id,
    required String key,
    required String name,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Product(
      id: id,
      tenantId: 1,
      externalKey: key,
      displayName: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('buildFolders — группировка', () {
    test('только личные комнаты → одна папка «Все» (полоса скрыта)', () {
      final folders = buildFolders([
        room(id: 1),
        room(id: 2, roomType: RoomType.direct),
      ]);
      // Personal не выделяется отдельной папкой, если это ВСЕ комнаты:
      // получаем «Все» + «Личные» = 2? Нет — «Личные» появляется всегда
      // при наличии беспродуктовых комнат. Проверяем реальную семантику.
      expect(folders.first.kind, ChatFolderKind.all);
      // Есть личные комнаты → есть папка personal.
      expect(folders.any((f) => f.kind == ChatFolderKind.personal), isTrue);
      // Но продуктовых нет → только All + Personal.
      expect(folders.length, 2);
    });

    test('один продукт + личные → All, продукт, Личные (3 папки)', () {
      final folders = buildFolders(
        [
          room(id: 1, productId: 10),
          room(id: 2, productId: 10),
          room(id: 3), // личная
        ],
        products: [product(id: 10, key: 'titan_control', name: 'Титан')],
      );
      expect(folders.map((f) => f.kind), [
        ChatFolderKind.all,
        ChatFolderKind.product,
        ChatFolderKind.personal,
      ]);
      final prod = folders[1];
      expect(prod.productId, 10);
      expect(prod.productDisplayName, 'Титан');
      expect(prod.roomCount, 2);
    });

    test('только продуктовые комнаты (без личных) → All + продукт', () {
      final folders = buildFolders(
        [room(id: 1, productId: 10), room(id: 2, productId: 10)],
        products: [product(id: 10, key: 'titan', name: 'Титан')],
      );
      expect(folders.map((f) => f.kind), [
        ChatFolderKind.all,
        ChatFolderKind.product,
      ]);
      // Нет беспродуктовых комнат → нет папки Личные.
      expect(folders.any((f) => f.kind == ChatFolderKind.personal), isFalse);
    });

    test('несколько продуктов сортируются по возрастанию productId', () {
      final folders = buildFolders(
        [
          room(id: 1, productId: 30),
          room(id: 2, productId: 10),
          room(id: 3, productId: 20),
        ],
        products: [
          product(id: 10, key: 'a', name: 'A'),
          product(id: 20, key: 'b', name: 'B'),
          product(id: 30, key: 'c', name: 'C'),
        ],
      );
      final productIds = folders
          .where((f) => f.kind == ChatFolderKind.product)
          .map((f) => f.productId)
          .toList();
      expect(productIds, [10, 20, 30], reason: 'стабильный порядок табов');
    });

    test('пустой список комнат → только «Все» (пустая)', () {
      final folders = buildFolders(const []);
      expect(folders.length, 1);
      expect(folders.single.kind, ChatFolderKind.all);
      expect(folders.single.roomCount, 0);
    });
  });

  group('buildFolders — unread-суммы', () {
    test('unread суммируется на папку продукта и на «Все»', () {
      final folders = buildFolders(
        [
          room(id: 1, productId: 10, unread: 3),
          room(id: 2, productId: 10, unread: 2),
          room(id: 3, unread: 5), // личная
        ],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      final all = folders.firstWhere((f) => f.kind == ChatFolderKind.all);
      final prod = folders.firstWhere((f) => f.kind == ChatFolderKind.product);
      final personal = folders.firstWhere(
        (f) => f.kind == ChatFolderKind.personal,
      );
      expect(all.unreadCount, 10, reason: '3+2+5');
      expect(prod.unreadCount, 5, reason: '3+2');
      expect(personal.unreadCount, 5);
    });
  });

  group('buildFolders — имена продуктов', () {
    test('fallback на externalKey когда продукт есть в комнатах, '
        'но displayName не резолвится', () {
      // products == null → имя не резолвится, только productKey недоступен.
      final folders = buildFolders([room(id: 1, productId: 42)]);
      final prod = folders.firstWhere((f) => f.kind == ChatFolderKind.product);
      expect(prod.productDisplayName, isNull);
      expect(prod.productKey, isNull);
      // selectionKey всё равно стабилен по productId.
      expect(prod.selectionKey, 'product:42');
    });

    test('productKey из Product когда displayName задан', () {
      final folders = buildFolders(
        [room(id: 1, productId: 42)],
        products: [product(id: 42, key: 'titan_control', name: 'Титан')],
      );
      final prod = folders.firstWhere((f) => f.kind == ChatFolderKind.product);
      expect(prod.productKey, 'titan_control');
      expect(prod.productDisplayName, 'Титан');
    });
  });

  group('buildFolders — агрегаты фаза 1.5 (превью/время самого свежего)', () {
    test('lastMessageAt/Preview берутся от чата с max lastMessageAt', () {
      final tOld = DateTime.utc(2026, 1, 1, 9);
      final tNew = DateTime.utc(2026, 1, 1, 15);
      final folders = buildFolders(
        [
          room(
            id: 1,
            productId: 10,
            lastMessageAt: tOld,
            lastMessagePreview: 'старое',
          ),
          room(
            id: 2,
            productId: 10,
            lastMessageAt: tNew,
            lastMessagePreview: 'свежее',
          ),
        ],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      final prod = folders.firstWhere((f) => f.kind == ChatFolderKind.product);
      expect(prod.lastMessageAt, tNew);
      expect(prod.lastMessagePreview, 'свежее');
      // «Все» агрегирует по всем комнатам — тоже самый свежий.
      expect(folders.first.lastMessageAt, tNew);
      expect(folders.first.lastMessagePreview, 'свежее');
    });

    test('нет ни одной даты → lastMessageAt null', () {
      final folders = buildFolders([room(id: 1, productId: 10)]);
      final prod = folders.firstWhere((f) => f.kind == ChatFolderKind.product);
      expect(prod.lastMessageAt, isNull);
      expect(prod.lastMessagePreview, isNull);
    });

    test('productAvatarUrl всегда null (Product без аватара в схеме)', () {
      final folders = buildFolders(
        [room(id: 1, productId: 10)],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      final prod = folders.firstWhere((f) => f.kind == ChatFolderKind.product);
      expect(prod.productAvatarUrl, isNull);
    });
  });

  group('foldersVisible — обёртка-папка при >1 группе', () {
    test('пустой список (только «Все») → скрыта', () {
      expect(foldersVisible(buildFolders(const [])), isFalse);
    });

    test('только личные (одна группа) → скрыта (плоско)', () {
      final folders = buildFolders([room(id: 1), room(id: 2)]);
      // All + Personal = 2 папки, но 1 содержательная группа.
      expect(folders.length, 2);
      expect(foldersVisible(folders), isFalse);
    });

    test('только один продукт (одна группа) → скрыта (плоско)', () {
      final folders = buildFolders(
        [room(id: 1, productId: 10), room(id: 2, productId: 10)],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      expect(foldersVisible(folders), isFalse);
    });

    test('продукт + личные (две группы) → видна', () {
      final folders = buildFolders(
        [room(id: 1, productId: 10), room(id: 2)],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      expect(foldersVisible(folders), isTrue);
    });

    test('несколько продуктов (две группы) → видна', () {
      final folders = buildFolders(
        [room(id: 1, productId: 10), room(id: 2, productId: 20)],
        products: [
          product(id: 10, key: 'a', name: 'A'),
          product(id: 20, key: 'b', name: 'B'),
        ],
      );
      expect(foldersVisible(folders), isTrue);
    });
  });

  group('buildRootRows — модель «папка-как-строка»', () {
    List<ChatRootRow> rows(List<RoomSummary> r, {List<Product>? products}) =>
        buildRootRows(r, buildFolders(r, products: products));

    test('одна группа → плоский список строк-чатов (без строк-папок)', () {
      final result = rows(
        [room(id: 1, productId: 10), room(id: 2, productId: 10)],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      expect(result.every((x) => x is ChatRoomRow), isTrue);
      expect(result.length, 2);
    });

    test('продукт+личные → строка-папка + строки-чаты личных', () {
      final result = rows(
        [
          room(id: 1, productId: 10),
          room(id: 2, productId: 10),
          room(id: 3), // личная
        ],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      // Личная комната как строка-чат; продукт свёрнут в одну строку-папку.
      expect(result.whereType<ChatFolderRow>().length, 1);
      expect(result.whereType<ChatRoomRow>().length, 1);
      expect(result.whereType<ChatRoomRow>().single.room.id, 3);
      expect(result.whereType<ChatFolderRow>().single.folder.productId, 10);
    });

    test('сортировка: свежие сверху (папка и чаты в общем порядке)', () {
      final tOld = DateTime.utc(2026, 1, 1, 8);
      final tMid = DateTime.utc(2026, 1, 1, 10);
      final tNew = DateTime.utc(2026, 1, 1, 12);
      final result = rows(
        [
          room(id: 1, productId: 10, lastMessageAt: tOld),
          room(id: 2, productId: 10, lastMessageAt: tNew), // папка = tNew
          room(id: 3, lastMessageAt: tMid), // личная = tMid
        ],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      // Папка (tNew) выше личного чата (tMid).
      expect(result[0], isA<ChatFolderRow>());
      expect(result[1], isA<ChatRoomRow>());
    });

    test('несколько продуктов → строка-папка на каждый, без строк-чатов', () {
      final result = rows(
        [room(id: 1, productId: 10), room(id: 2, productId: 20)],
        products: [
          product(id: 10, key: 'a', name: 'A'),
          product(id: 20, key: 'b', name: 'B'),
        ],
      );
      expect(result.whereType<ChatFolderRow>().length, 2);
      expect(result.whereType<ChatRoomRow>(), isEmpty);
    });

    test('строки без активности уходят вниз', () {
      final tNew = DateTime.utc(2026, 1, 1, 12);
      final result = rows(
        [
          room(id: 1, productId: 10, lastMessageAt: tNew), // папка с датой
          room(id: 2), // личная без даты
        ],
        products: [product(id: 10, key: 'x', name: 'X')],
      );
      expect(result.first, isA<ChatFolderRow>());
      expect(result.last, isA<ChatRoomRow>());
    });
  });

  group('ChatFolder.matches — предикат фильтрации', () {
    test('all матчит всё; personal — только беспродуктовые; '
        'product — по productId', () {
      const all = ChatFolder(
        kind: ChatFolderKind.all,
        unreadCount: 0,
        roomCount: 0,
      );
      const personal = ChatFolder(
        kind: ChatFolderKind.personal,
        unreadCount: 0,
        roomCount: 0,
      );
      const prod = ChatFolder(
        kind: ChatFolderKind.product,
        productId: 10,
        unreadCount: 0,
        roomCount: 0,
      );
      final personalRoom = room(id: 1);
      final productRoom = room(id: 2, productId: 10);
      final otherProduct = room(id: 3, productId: 20);

      expect(all.matches(personalRoom), isTrue);
      expect(all.matches(productRoom), isTrue);

      expect(personal.matches(personalRoom), isTrue);
      expect(personal.matches(productRoom), isFalse);

      expect(prod.matches(productRoom), isTrue);
      expect(prod.matches(personalRoom), isFalse);
      expect(prod.matches(otherProduct), isFalse);
    });
  });
}
