import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **TASK75** — агрегатная папка «Поддержка» в `buildFolders` /
/// `buildRootRows`:
///   * появляется при наличии НЕ-«закрытых» support-комнат, агрегирует
///     их по всем продуктам;
///   * «закрытые» (dismissed) support-комнаты исключены из всех агрегатов;
///   * support-комнаты не попадают в продуктовые/личные папки;
///   * `matches` папки «Поддержка» пропускает только НЕ-«закрытые» support.
void main() {
  RoomSummary support({
    required int id,
    required int productId,
    int unread = 0,
    bool dismissed = false,
    DateTime? lastMessageAt,
  }) => RoomSummary(
    id: id,
    name: 'Поддержка — Заявитель $id',
    unreadCount: unread,
    archived: false,
    muted: false,
    productId: productId,
    roomType: RoomType.support,
    supportRequesterName: 'Заявитель $id',
    productName: 'Проект $productId',
    dismissedUntilMessage: dismissed,
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

  ChatFolder? supportFolder(List<ChatFolder> folders) =>
      folders.where((f) => f.kind == ChatFolderKind.support).firstOrNull;

  group('buildFolders — папка «Поддержка»', () {
    test('появляется и агрегирует support по всем продуктам', () {
      final folders = buildFolders([
        support(id: 1, productId: 10, unread: 2),
        support(id: 2, productId: 20, unread: 3),
        groupRoom(id: 3, productId: 10),
      ]);
      final sf = supportFolder(folders);
      expect(sf, isNotNull);
      expect(sf!.roomCount, 2);
      expect(sf.unreadCount, 5);
      // Идёт сразу после агрегата «Все».
      expect(folders[0].kind, ChatFolderKind.all);
      expect(folders[1].kind, ChatFolderKind.support);
      expect(sf.selectionKey, ChatFolder.supportSelectionKey);
    });

    test('нет support-комнат → папки «Поддержка» нет', () {
      final folders = buildFolders([groupRoom(id: 1, productId: 10)]);
      expect(supportFolder(folders), isNull);
    });

    test('«закрытые» (dismissed) support исключены из агрегата', () {
      final folders = buildFolders([
        support(id: 1, productId: 10, unread: 2),
        support(id: 2, productId: 10, unread: 9, dismissed: true),
      ]);
      final sf = supportFolder(folders);
      expect(sf, isNotNull);
      expect(sf!.roomCount, 1, reason: 'dismissed не считается');
      expect(sf.unreadCount, 2, reason: 'unread dismissed не суммируется');
    });

    test('все support «закрыты» → папки «Поддержка» нет', () {
      final folders = buildFolders([
        support(id: 1, productId: 10, dismissed: true),
      ]);
      expect(supportFolder(folders), isNull);
    });

    test('support-комнаты НЕ попадают в продуктовую папку', () {
      final folders = buildFolders([
        support(id: 1, productId: 10),
        groupRoom(id: 2, productId: 10),
      ]);
      final product = folders.firstWhere(
        (f) => f.kind == ChatFolderKind.product && f.productId == 10,
      );
      // Только обычная группа, support ушла в «Поддержку».
      expect(product.roomCount, 1);
    });
  });

  group('ChatFolder.matches — папка «Поддержка»', () {
    test('пропускает НЕ-«закрытые» support, режет остальное', () {
      final folders = buildFolders([support(id: 1, productId: 10)]);
      final sf = supportFolder(folders)!;
      expect(sf.matches(support(id: 1, productId: 10)), isTrue);
      expect(
        sf.matches(support(id: 2, productId: 10, dismissed: true)),
        isFalse,
      );
      expect(sf.matches(groupRoom(id: 3, productId: 10)), isFalse);
    });

    test('продуктовая папка НЕ матчит support своего продукта', () {
      final folders = buildFolders([
        support(id: 1, productId: 10),
        groupRoom(id: 2, productId: 10),
      ]);
      final product = folders.firstWhere(
        (f) => f.kind == ChatFolderKind.product && f.productId == 10,
      );
      expect(product.matches(support(id: 1, productId: 10)), isFalse);
      expect(product.matches(groupRoom(id: 2, productId: 10)), isTrue);
    });
  });

  group('buildRootRows — папка «Поддержка»', () {
    test('support-папка — закреплённая строка, support-чаты не плоские', () {
      final rooms = [
        support(id: 1, productId: 10),
        support(id: 2, productId: 20),
        groupRoom(id: 3, productId: null), // личный
      ];
      final folders = buildFolders(rooms);
      final rows = buildRootRows(rooms, folders);

      // Есть строка-папка «Поддержка».
      final folderRows = rows.whereType<ChatFolderRow>().toList();
      expect(
        folderRows.any((r) => r.folder.kind == ChatFolderKind.support),
        isTrue,
      );
      // Ни одна плоская строка-чат не является support-комнатой.
      final roomRows = rows.whereType<ChatRoomRow>().toList();
      expect(
        roomRows.any((r) => r.room.roomType == RoomType.support),
        isFalse,
      );
    });

    test('только support-комнаты → одна строка-папка «Поддержка»', () {
      final rooms = [
        support(id: 1, productId: 10),
        support(id: 2, productId: 10),
      ];
      final rows = buildRootRows(rooms, buildFolders(rooms));
      expect(rows.length, 1);
      final only = rows.single as ChatFolderRow;
      expect(only.folder.kind, ChatFolderKind.support);
      expect(only.folder.roomCount, 2);
    });
  });
}
