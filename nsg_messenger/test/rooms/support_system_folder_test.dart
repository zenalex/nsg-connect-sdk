import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **Системные папки продуктов для чатов поддержки.**
///
/// Проверяем модель владельца целиком:
///   * папка на ПРОДУКТ появляется, когда есть хотя бы одно обращение, где
///     смотрящий — ОПЕРАТОР; внутри — чаты, названные по заявителям;
///   * СОБСТВЕННОЕ обращение человека в папку НЕ попадает: оно лежит
///     строкой в корне списка (и названо по продукту — имя делает сервер);
///   * папки СИСТЕМНЫЕ: вычисляются при чтении, поэтому переименовать /
///     удалить / вынуть из них чат нельзя — мутирующему API нечего
///     передать (`customFolderId == null`);
///   * ручные папки (TASK62) при этом не сломаны и с системными не спорят.
void main() {
  /// Обращение по продукту [productId]. [mine] — смотрящий заявитель
  /// (собственный чат с поддержкой), иначе смотрящий — оператор.
  RoomSummary supportRoom({
    required int id,
    required int productId,
    required bool mine,
    int unread = 0,
    bool dismissed = false,
    DateTime? lastMessageAt,
  }) => RoomSummary(
    id: id,
    // Имя уже перспективное (его считает сервер): заявителю — продукт,
    // оператору — ФИО заявителя.
    name: mine ? 'Продукт $productId' : 'Заявитель $id',
    unreadCount: unread,
    archived: false,
    muted: false,
    productId: productId,
    roomType: RoomType.support,
    supportRequesterName: mine ? 'Я сам' : 'Заявитель $id',
    productName: 'Продукт $productId',
    dismissedUntilMessage: dismissed,
    supportViewerIsRequester: mine,
    lastMessageAt: lastMessageAt,
  );

  RoomSummary direct({required int id}) => RoomSummary(
    id: id,
    name: 'Собеседник $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.direct,
  );

  ChatFolder? folderOfProduct(List<ChatFolder> folders, int productId) =>
      folders
          .where(
            (f) =>
                (f.kind == ChatFolderKind.support ||
                    f.kind == ChatFolderKind.product) &&
                f.productId == productId,
          )
          .firstOrNull;

  group('папка продукта у оператора', () {
    test('появляется, когда есть хотя бы одно чужое обращение', () {
      final rooms = [supportRoom(id: 1, productId: 10, mine: false)];
      final folders = buildFolders(rooms);

      final f = folderOfProduct(folders, 10);
      expect(f, isNotNull);
      expect(
        f!.kind,
        ChatFolderKind.support,
        reason: 'папка продукта стала операторским инбоксом',
      );
      expect(f.roomCount, 1);
      // Внутри — чат, названный по заявителю.
      expect(rooms.where(f.matches).single.name, 'Заявитель 1');
    });

    test('по папке на каждый продукт, где смотрящий оператор', () {
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: false),
        supportRoom(id: 2, productId: 20, mine: false),
        supportRoom(id: 3, productId: 30, mine: false),
      ];
      final folders = buildFolders(rooms);
      expect(
        folders
            .where((f) => f.kind == ChatFolderKind.support)
            .map((f) => f.productId),
        [10, 20, 30],
      );
      // Каждая — строкой в корне: системную папку не «разворачивают».
      final rows = buildRootRows(rooms, folders);
      expect(rows.whereType<ChatFolderRow>().length, 3);
      expect(rows.whereType<ChatRoomRow>(), isEmpty);
    });

    test('единственная папка не разворачивается в плоский список', () {
      // Одна содержательная группа → `foldersVisible` == false. Для обычной
      // обёртки это повод показать чаты плоско, но системная папка обязана
      // остаться: иначе чужие обращения легли бы в корень.
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: false),
        supportRoom(id: 2, productId: 10, mine: false),
      ];
      final folders = buildFolders(rooms);
      expect(foldersVisible(folders), isFalse);

      final rows = buildRootRows(rooms, folders);
      expect(rows.whereType<ChatRoomRow>(), isEmpty);
      expect(rows.whereType<ChatFolderRow>().single.folder.productId, 10);
    });
  });

  group('собственное обращение', () {
    test('в папку продукта НЕ попадает', () {
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: false, unread: 4),
        supportRoom(id: 2, productId: 10, mine: true, unread: 7),
      ];
      final folders = buildFolders(rooms);
      final f = folderOfProduct(folders, 10)!;

      expect(rooms.where(f.matches).map((r) => r.id), [1]);
      expect(f.roomCount, 1, reason: 'своё обращение не считается в папке');
      expect(
        f.unreadCount,
        4,
        reason: 'непрочитанное своего вопроса не идёт в бейдж чужой очереди',
      );
    });

    test('лежит строкой в корне списка', () {
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: false),
        supportRoom(id: 2, productId: 10, mine: true),
        direct(id: 3),
      ];
      final rows = buildRootRows(rooms, buildFolders(rooms));

      final rootRoomIds = rows.whereType<ChatRoomRow>().map((r) => r.room.id);
      expect(
        rootRoomIds,
        containsAll(<int>[2, 3]),
        reason: 'своё обращение — обычный чат корня, рядом с личными',
      );
      expect(rootRoomIds, isNot(contains(1)));
    });

    test('своё обращение без чужих — папки продукта нет вовсе', () {
      // Ровно случай владельца: он пользователь Чатисты, но не оператор её
      // поддержки. Папка «Чатиста» не нужна — нужен один чат в корне.
      final rooms = [supportRoom(id: 1, productId: 10, mine: true)];
      final folders = buildFolders(rooms);

      expect(folderOfProduct(folders, 10), isNull);
      final rows = buildRootRows(rooms, folders);
      expect(rows.whereType<ChatRoomRow>().single.room.id, 1);
      expect(rows.whereType<ChatFolderRow>(), isEmpty);
    });

    test('оператор продукта, который сам туда написал: и папка, и чат', () {
      // Дословно из постановки: «у меня будет чат Чатиста — я там
      // пользователь, и папки Чатиста, Футболиста, 112».
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: true), // мой вопрос в Чатисту
        supportRoom(id: 2, productId: 10, mine: false), // чужой — я оператор
        supportRoom(id: 3, productId: 20, mine: false),
      ];
      final folders = buildFolders(rooms);
      final rows = buildRootRows(rooms, folders);

      expect(rows.whereType<ChatFolderRow>().map((r) => r.folder.productId), [
        10,
        20,
      ]);
      expect(rows.whereType<ChatRoomRow>().single.room.id, 1);
    });

    test('старый сервер (null) трактуется как «не заявитель»', () {
      // Скью версий: цена ошибки несимметрична — лучше показать свой чат в
      // папке, чем вывалить весь операторский инбокс в корень.
      final room = RoomSummary(
        id: 1,
        name: 'Заявитель 1',
        unreadCount: 0,
        archived: false,
        muted: false,
        productId: 10,
        roomType: RoomType.support,
      );
      expect(room.supportViewerIsRequester, isNull);
      expect(isOwnSupportRequest(room), isFalse);
      expect(folderOfProduct(buildFolders([room]), 10), isNotNull);
    });
  });

  group('системность папки', () {
    test('нечего передать в rename/delete/setRoomInChatFolder', () {
      // Весь мутирующий API папок адресуется `int folderId` — серверным id
      // строки `chat_folders`. У системной папки такой строки нет, поэтому
      // её нельзя ни переименовать, ни удалить, ни вынуть из неё чат.
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: false),
        supportRoom(id: 2, productId: 10, mine: true),
        direct(id: 3),
      ];
      for (final f in buildFolders(rooms)) {
        expect(f.isSystem, isTrue, reason: '${f.kind}: ручных папок тут нет');
        expect(
          f.customFolderId,
          isNull,
          reason: '${f.kind}: нет id для мутаций',
        );
      }
    });

    test('чат в ручной папке остаётся и в системной — вынуть нельзя', () {
      // Единственное, что человек может сделать с системной раскладкой —
      // положить тот же чат ещё и в свою папку. Это быстрый доступ, а не
      // перемещение: из папки продукта чат никуда не девается.
      final rooms = [supportRoom(id: 1, productId: 10, mine: false)];
      final manual = ChatFolderView(
        id: 77,
        name: 'Разобрать',
        sortOrder: 0,
        roomIds: [1],
      );
      final folders = buildFolders(rooms, customFolders: [manual]);

      final system = folderOfProduct(folders, 10)!;
      expect(rooms.where(system.matches).map((r) => r.id), [1]);

      final custom = folders
          .where((f) => f.kind == ChatFolderKind.custom)
          .single;
      expect(custom.isSystem, isFalse);
      expect(custom.customFolderId, 77);
      expect(rooms.where(custom.matches).map((r) => r.id), [1]);
    });

    test('ручные папки не сломаны: живут рядом и своей жизнью', () {
      final rooms = [
        supportRoom(id: 1, productId: 10, mine: false),
        direct(id: 2),
      ];
      final manual = ChatFolderView(
        id: 5,
        name: 'Важное',
        sortOrder: 0,
        roomIds: [2],
      );
      final folders = buildFolders(rooms, customFolders: [manual]);

      final custom = folders
          .where((f) => f.kind == ChatFolderKind.custom)
          .single;
      expect(custom.customName, 'Важное');
      expect(rooms.where(custom.matches).map((r) => r.id), [2]);

      // Обе папки — строками в корне; чат direct-а из ручной папки при этом
      // из корня не пропадает (папка — доступ, не перемещение).
      final rows = buildRootRows(rooms, folders);
      expect(rows.whereType<ChatFolderRow>().length, 2);
      expect(rows.whereType<ChatRoomRow>().single.room.id, 2);
    });

    test('пустая ручная папка видна, пустой системной не бывает', () {
      final rooms = [supportRoom(id: 1, productId: 10, mine: false)];
      final folders = buildFolders(
        rooms,
        customFolders: [
          ChatFolderView(id: 9, name: 'Пустая', sortOrder: 0, roomIds: []),
        ],
      );
      expect(
        folders.where((f) => f.kind == ChatFolderKind.custom).single.roomCount,
        0,
      );
      for (final f in folders.where(
        (f) =>
            f.kind == ChatFolderKind.support ||
            f.kind == ChatFolderKind.product,
      )) {
        expect(f.roomCount, greaterThan(0));
      }
    });
  });
}
