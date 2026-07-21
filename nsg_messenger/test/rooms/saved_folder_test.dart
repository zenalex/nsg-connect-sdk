import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// **TASK68** — агрегатная папка «Избранное» (self-чаты) в `buildFolders` /
/// `buildRootRows`:
///   * появляется при наличии self-чатов и агрегирует их все;
///   * self-чаты НЕ попадают в «Личные» (у них `productId == null`, без
///     явного исключения провалились бы туда);
///   * self-чаты НЕ рендерятся плоскими строками в корне — иначе
///     «заметки»/«файлообмен»/«документы» забили бы ленту наравне с
///     настоящими собеседниками;
///   * `matches` папки пропускает только self-чаты.
void main() {
  RoomSummary saved({
    required int id,
    required String name,
    int unread = 0,
    int? autoCleanupTtlSeconds,
    DateTime? lastMessageAt,
  }) => RoomSummary(
    id: id,
    name: name,
    unreadCount: unread,
    archived: false,
    muted: false,
    roomType: RoomType.saved,
    autoCleanupTtlSeconds: autoCleanupTtlSeconds,
    lastMessageAt: lastMessageAt,
  );

  RoomSummary direct({required int id, DateTime? lastMessageAt}) => RoomSummary(
    id: id,
    name: 'Собеседник $id',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.direct,
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

  ChatFolder? savedFolder(List<ChatFolder> folders) =>
      folders.where((f) => f.kind == ChatFolderKind.saved).firstOrNull;

  ChatFolder? personalFolder(List<ChatFolder> folders) =>
      folders.where((f) => f.kind == ChatFolderKind.personal).firstOrNull;

  group('isSavedRoom', () {
    test('true только для RoomType.saved', () {
      expect(isSavedRoom(saved(id: 1, name: 'Избранное')), isTrue);
      expect(isSavedRoom(direct(id: 2)), isFalse);
      expect(isSavedRoom(groupRoom(id: 3)), isFalse);
    });
  });

  group('buildFolders — папка «Избранное»', () {
    test('появляется и агрегирует все self-чаты', () {
      final folders = buildFolders([
        saved(id: 1, name: 'Избранное', unread: 2),
        saved(id: 2, name: 'файлообмен', unread: 3),
        direct(id: 3),
      ]);
      final sf = savedFolder(folders);
      expect(sf, isNotNull);
      expect(sf!.roomCount, 2);
      expect(sf.unreadCount, 5);
      expect(sf.selectionKey, ChatFolder.savedSelectionKey);
    });

    test('нет self-чатов → папки «Избранное» нет', () {
      final folders = buildFolders([direct(id: 1), groupRoom(id: 2)]);
      expect(savedFolder(folders), isNull);
    });

    test('self-чаты НЕ попадают в «Личные»', () {
      final folders = buildFolders([
        saved(id: 1, name: 'заметки'),
        saved(id: 2, name: 'файлообмен'),
        direct(id: 3),
      ]);
      final personal = personalFolder(folders);
      expect(
        personal?.roomCount,
        1,
        reason: 'в «Личных» только настоящий собеседник',
      );
      expect(savedFolder(folders)!.roomCount, 2);
    });

    test('matches пропускает только self-чаты', () {
      final folders = buildFolders([saved(id: 1, name: 'заметки')]);
      final sf = savedFolder(folders)!;
      expect(sf.matches(saved(id: 1, name: 'заметки')), isTrue);
      expect(sf.matches(direct(id: 2)), isFalse);
      expect(sf.matches(groupRoom(id: 3, productId: 10)), isFalse);
    });

    test('папка «Личные» не матчит self-чат', () {
      final folders = buildFolders([
        saved(id: 1, name: 'заметки'),
        direct(id: 2),
      ]);
      final personal = personalFolder(folders)!;
      expect(personal.matches(direct(id: 2)), isTrue);
      expect(
        personal.matches(saved(id: 1, name: 'заметки')),
        isFalse,
        reason: 'иначе self-чат дублировался бы в двух папках',
      );
    });

    test('идёт перед продуктовыми и кастомными папками', () {
      final folders = buildFolders(
        [saved(id: 1, name: 'заметки'), groupRoom(id: 2, productId: 10)],
        customFolders: [
          ChatFolderView(id: 7, name: 'моя папка', sortOrder: 0, roomIds: [2]),
        ],
      );
      final kinds = folders.map((f) => f.kind).toList();
      expect(kinds.first, ChatFolderKind.all);
      expect(
        kinds.indexOf(ChatFolderKind.saved),
        lessThan(kinds.indexOf(ChatFolderKind.custom)),
      );
      expect(
        kinds.indexOf(ChatFolderKind.saved),
        lessThan(kinds.indexOf(ChatFolderKind.product)),
      );
    });
  });

  group('buildRootRows — self-чаты только внутри своей папки', () {
    test('корень содержит строку-папку, но не сами self-чаты', () {
      final rooms = [
        saved(id: 1, name: 'Избранное', lastMessageAt: DateTime(2026, 7, 18)),
        saved(id: 2, name: 'файлообмен'),
        direct(id: 3, lastMessageAt: DateTime(2026, 7, 17)),
      ];
      final rows = buildRootRows(rooms, buildFolders(rooms));
      final roomRowIds = rows
          .whereType<ChatRoomRow>()
          .map((r) => r.room.id)
          .toList();
      expect(roomRowIds, [3], reason: 'только настоящий чат плоской строкой');
      expect(
        rows.whereType<ChatFolderRow>().map((r) => r.folder.kind),
        contains(ChatFolderKind.saved),
      );
    });

    test('даже когда папки «не видны» (одна авто-группа) — self скрыты', () {
      // Только self-чаты: содержательная группа одна → foldersVisible
      // == false и весь список пошёл бы плоско. Строка-папка при этом
      // всё равно закреплена, а сами разделы в корень не попадают.
      final rooms = [
        saved(id: 1, name: 'Избранное'),
        saved(id: 2, name: 'заметки'),
      ];
      final rows = buildRootRows(rooms, buildFolders(rooms));
      expect(rows.whereType<ChatRoomRow>(), isEmpty);
      expect(rows.whereType<ChatFolderRow>(), hasLength(1));
      expect(
        rows.whereType<ChatFolderRow>().single.folder.kind,
        ChatFolderKind.saved,
      );
    });
  });

  group('RoomSummary.autoCleanupTtlSeconds', () {
    test('проброшен в строку списка (бейдж без отдельного getRoom)', () {
      final room = saved(
        id: 1,
        name: 'файлообмен',
        autoCleanupTtlSeconds: 604800,
      );
      expect(room.autoCleanupTtlSeconds, 604800);
      expect(
        saved(id: 2, name: 'заметки').autoCleanupTtlSeconds,
        isNull,
        reason: 'null = автоочистка выключена',
      );
    });
  });
}
