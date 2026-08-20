import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **TASK75** — операторский support-инбокс в `buildFolders` /
/// `buildRootRows`. С переходом на **системные папки продуктов** инбокс
/// перестал быть одной агрегатной папкой «Поддержка» и разложился по
/// продуктам, но правила TASK75 обязаны сохраниться:
///   * папка появляется при наличии НЕ-«закрытых» обращений;
///   * «закрытые» (dismissed) support-комнаты исключены из всех агрегатов;
///   * support-чаты не сыпятся в корень плоскими строками;
///   * `matches` папки не пропускает «закрытые».
void main() {
  // Обращение, где смотрящий — ОПЕРАТОР (`supportViewerIsRequester: false`).
  RoomSummary support({
    required int id,
    required int productId,
    int unread = 0,
    bool dismissed = false,
    DateTime? lastMessageAt,
  }) => RoomSummary(
    id: id,
    name: 'Заявитель $id',
    unreadCount: unread,
    archived: false,
    muted: false,
    productId: productId,
    roomType: RoomType.support,
    supportRequesterName: 'Заявитель $id',
    productName: 'Проект $productId',
    dismissedUntilMessage: dismissed,
    supportViewerIsRequester: false,
    lastMessageAt: lastMessageAt,
  );

  RoomSummary groupRoom({required int id, int? productId}) => RoomSummary(
    id: id,
    name: 'Группа $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    productId: productId,
    roomType: RoomType.group,
  );

  List<ChatFolder> supportFolders(List<ChatFolder> folders) =>
      folders.where((f) => f.kind == ChatFolderKind.support).toList();

  group('buildFolders — операторский инбокс', () {
    test('обращения разложены по продуктам, по папке на продукт', () {
      final folders = buildFolders([
        support(id: 1, productId: 10, unread: 2),
        support(id: 2, productId: 20, unread: 3),
        groupRoom(id: 3, productId: 10),
      ]);
      final sf = supportFolders(folders);
      expect(sf.map((f) => f.productId), [10, 20]);
      // Папка продукта 10 несёт и обращение, и обычную группу продукта.
      expect(sf.first.roomCount, 2);
      expect(sf.first.unreadCount, 2);
      expect(sf.last.roomCount, 1);
      expect(sf.last.unreadCount, 3);
      // Агрегат «Все» по-прежнему первый.
      expect(folders.first.kind, ChatFolderKind.all);
      expect(sf.first.selectionKey, '${ChatFolder.supportSelectionPrefix}10');
    });

    test('нет support-комнат → папка продукта обычная, не инбокс', () {
      final folders = buildFolders([groupRoom(id: 1, productId: 10)]);
      expect(supportFolders(folders), isEmpty);
      expect(
        folders.where((f) => f.kind == ChatFolderKind.product).single.productId,
        10,
      );
    });

    test('«закрытые» (dismissed) support исключены из агрегата', () {
      final folders = buildFolders([
        support(id: 1, productId: 10, unread: 2),
        support(id: 2, productId: 10, unread: 9, dismissed: true),
      ]);
      final sf = supportFolders(folders).single;
      expect(sf.roomCount, 1, reason: 'dismissed не считается');
      expect(sf.unreadCount, 2, reason: 'unread dismissed не суммируется');
    });

    test('все support «закрыты» → инбокса по продукту нет', () {
      final folders = buildFolders([
        support(id: 1, productId: 10, dismissed: true),
      ]);
      expect(supportFolders(folders), isEmpty);
    });
  });

  group('ChatFolder.matches — папка продукта с инбоксом', () {
    test('пропускает НЕ-«закрытые» обращения своего продукта', () {
      final folders = buildFolders([support(id: 1, productId: 10)]);
      final sf = supportFolders(folders).single;
      expect(sf.matches(support(id: 1, productId: 10)), isTrue);
      expect(
        sf.matches(support(id: 2, productId: 10, dismissed: true)),
        isFalse,
      );
      expect(sf.matches(support(id: 3, productId: 99)), isFalse);
    });

    test('обычная комната продукта тоже в папке продукта', () {
      final folders = buildFolders([
        support(id: 1, productId: 10),
        groupRoom(id: 2, productId: 10),
      ]);
      final sf = supportFolders(folders).single;
      expect(sf.matches(groupRoom(id: 2, productId: 10)), isTrue);
      expect(sf.matches(groupRoom(id: 3, productId: 20)), isFalse);
    });
  });

  group('buildRootRows — операторский инбокс', () {
    test('папки продуктов — строки, обращения не плоские', () {
      final rooms = [
        support(id: 1, productId: 10),
        support(id: 2, productId: 20),
        groupRoom(id: 3, productId: null), // личный
      ];
      final rows = buildRootRows(rooms, buildFolders(rooms));

      final folderRows = rows.whereType<ChatFolderRow>().toList();
      expect(
        folderRows.map((r) => r.folder.productId).toSet(),
        {10, 20},
        reason: 'по строке-папке на каждый продукт инбокса',
      );
      // Ни одна плоская строка-чат не является чужим обращением.
      final roomRows = rows.whereType<ChatRoomRow>().toList();
      expect(roomRows.any((r) => r.room.roomType == RoomType.support), isFalse);
    });

    test('только обращения одного продукта → одна строка-папка', () {
      final rooms = [
        support(id: 1, productId: 10),
        support(id: 2, productId: 10),
      ];
      final rows = buildRootRows(rooms, buildFolders(rooms));
      expect(rows.length, 1);
      final only = rows.single as ChatFolderRow;
      expect(only.folder.kind, ChatFolderKind.support);
      expect(only.folder.productId, 10);
      expect(only.folder.roomCount, 2);
    });
  });
}
