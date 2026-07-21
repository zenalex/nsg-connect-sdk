import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';

/// **TASK47 iter1**: unit-тесты дискового кэша [MessengerCacheStore].
///
/// Работают на desktop-VM (`flutter test`): `openForUser` резолвит
/// `databaseFactoryFfi` и открывает реальную БД во временном каталоге —
/// это же позволяет проверить скоуп по userId (переоткрытие того же файла
/// под другим пользователем).
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('msg_cache_test');
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<MessengerCacheStore> open(
    int userId, {
    String namespace = 'test',
  }) async {
    final store = await MessengerCacheStore.openForUser(
      directory: tmp.path,
      namespace: namespace,
      userId: userId,
    );
    expect(
      store,
      isNotNull,
      reason: 'ffi-фабрика должна открыть кэш на desktop',
    );
    return store!;
  }

  RoomSummary room(
    int id, {
    DateTime? at,
    String? name,
    bool archived = false,
    int? productId,
    int unread = 0,
  }) => RoomSummary(
    id: id,
    name: name ?? 'Room $id',
    lastMessagePreview: 'prev $id',
    lastMessageAt: at,
    unreadCount: unread,
    archived: archived,
    muted: false,
    productId: productId,
    roomType: RoomType.group,
  );

  MessengerMessage msg(
    int roomId,
    String evt, {
    required DateTime at,
    String body = 'hi',
    int? sender,
  }) => MessengerMessage(
    matrixEventId: evt,
    roomId: roomId,
    matrixRoomId: '!$roomId:l',
    senderMessengerUserId: sender,
    senderMatrixUserId: '@u:l',
    msgType: 'm.text',
    body: body,
    serverTimestamp: at,
  );

  final t0 = DateTime.utc(2026, 1, 1, 12);

  test('rooms: upsert + порядок по lastMessageAt DESC + фильтры', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putRooms([
      room(1, at: t0),
      room(2, at: t0.add(const Duration(minutes: 5))),
      room(3, at: null), // пустая — в конец
      room(4, at: t0, archived: true),
      room(5, at: t0, productId: 42),
    ]);

    final all = await s.getRooms();
    expect(all.map((r) => r.id).toList(), [2, 1, 5, 3]);
    expect(
      (await s.getRooms(includeArchived: true)).map((r) => r.id),
      contains(4),
    );
    expect((await s.getRooms(productId: 42)).map((r) => r.id).toList(), [5]);
  });

  test('search: фильтр в SQL ДО limit — старая комната находится', () async {
    final s = await open(1);
    addTearDown(s.close);
    // Совпадение по имени — у САМОЙ СТАРОЙ комнаты; свежих (не совпадающих)
    // больше, чем limit. Раньше (фильтр в Dart после limit) её теряли.
    await s.putRooms([
      room(1, at: t0.add(const Duration(minutes: 9)), name: 'Чат A'),
      room(2, at: t0.add(const Duration(minutes: 8)), name: 'Чат B'),
      room(3, at: t0, name: 'Поддержка НСГ'),
    ]);
    final found = await s.getRooms(search: 'поддержка', limit: 1);
    expect(found.map((r) => r.id).toList(), [3], reason: 'LIKE до limit');
    // Case-insensitive для кириллицы (pre-lowered колонка).
    expect((await s.getRooms(search: 'НСГ')).map((r) => r.id).toList(), [3]);
  });

  test('putRooms UPSERT сохраняет lastViewedAt (LRU итер.2)', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putRooms([room(1, at: t0)]);
    await s.debugSetLastViewed(1, 999);
    // Рефреш той же комнаты (новый список с сервера) НЕ должен обнулить.
    await s.putRooms([room(1, at: t0.add(const Duration(minutes: 1)))]);
    expect(await s.debugLastViewed(1), 999);
  });

  test('messages: upsert + последние N по возрастанию', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putMessages(7, [
      msg(7, 'e1', at: t0),
      msg(7, 'e2', at: t0.add(const Duration(minutes: 1))),
      msg(7, 'e3', at: t0.add(const Duration(minutes: 2))),
    ]);
    final last2 = await s.getMessages(7, limit: 2);
    expect(last2.map((m) => m.matrixEventId).toList(), ['e2', 'e3']);
  });

  test(
    'applyMessageCreated: превью + unread++ для чужого; guard от replay',
    () async {
      final s = await open(1);
      addTearDown(s.close);
      await s.putRooms([room(8, at: t0, unread: 0)]);
      final later = t0.add(const Duration(hours: 1));

      // Чужое сообщение (sender=2) → превью+время+unread=1.
      await s.applyMessageCreated(
        msg(8, 'ex', at: later, body: 'свежак', sender: 2),
      );
      var r = (await s.getRooms()).single;
      expect(r.lastMessageAt, later);
      expect(r.lastMessagePreview, 'свежак');
      expect(r.unreadCount, 1);

      // Replay СТАРОГО события (older ts) → НЕ откатывает превью/время/unread.
      await s.applyMessageCreated(
        msg(8, 'old', at: t0, body: 'старьё', sender: 2),
      );
      r = (await s.getRooms()).single;
      expect(r.lastMessageAt, later, reason: 'guard от replay');
      expect(r.lastMessagePreview, 'свежак');
      expect(r.unreadCount, 1);

      // Своё сообщение (sender=1 == userId) новее → превью да, unread НЕТ.
      await s.applyMessageCreated(
        msg(
          8,
          'mine',
          at: later.add(const Duration(minutes: 1)),
          body: 'моё',
          sender: 1,
        ),
      );
      r = (await s.getRooms()).single;
      expect(r.lastMessagePreview, 'моё');
      expect(r.unreadCount, 1, reason: 'своё сообщение не растит unread');
    },
  );

  test(
    'applyMessageDeleted: пересчёт превью (redacted текст не остаётся)',
    () async {
      final s = await open(1);
      addTearDown(s.close);
      await s.putRooms([room(9, at: t0)]);
      await s.putMessages(9, [msg(9, 'a', at: t0, body: 'первое')]);
      await s.applyMessageCreated(
        msg(
          9,
          'b',
          at: t0.add(const Duration(minutes: 1)),
          body: 'секрет',
          sender: 2,
        ),
      );
      expect((await s.getRooms()).single.lastMessagePreview, 'секрет');

      // Удаляем последнее (redaction) → превью откатывается к 'первое', а НЕ
      // остаётся 'секрет'.
      await s.applyMessageDeleted(9, 'b');
      final r = (await s.getRooms()).single;
      expect(r.lastMessagePreview, 'первое');
      expect((await s.getMessages(9)).map((m) => m.matrixEventId).toList(), [
        'a',
      ]);
    },
  );

  test(
    'applyMessageUpdated: правка тела обновляет кэш-сообщение + превью; '
    'НЕ-кэшированное сообщение НЕ вставляется (несмежные диапазоны)',
    () async {
      final s = await open(1);
      addTearDown(s.close);
      await s.putRooms([room(10, at: t0)]);
      await s.putMessages(10, [
        msg(10, 'a', at: t0, body: 'старое тело'),
      ]);
      // Правка новейшего → тело в кэше и превью комнаты обновились.
      await s.applyMessageUpdated(
        msg(10, 'a', at: t0, body: 'новое тело'),
      );
      expect((await s.getMessages(10)).single.body, 'новое тело');
      expect((await s.getRooms()).single.lastMessagePreview, 'новое тело');

      // Update события, которого НЕТ в кэше (комната с несинхронной
      // историей) — no-op, вставки не происходит.
      await s.applyMessageUpdated(
        msg(10, 'ghost-evt', at: t0.add(const Duration(hours: 2)), body: 'x'),
      );
      expect(await s.getMessages(10), hasLength(1));
      expect((await s.getRooms()).single.lastMessagePreview, 'новое тело');
    },
  );

  test(
    'reconcileRooms: удаляет «призраков» (нет в свежем списке) в скоупе; '
    'архивные при includeArchived=false не трогает',
    () async {
      final s = await open(1);
      addTearDown(s.close);
      await s.putRooms([
        room(1, at: t0),
        room(2, at: t0), // призрак — удалили из комнаты, пока офлайн
        room(3, at: t0, archived: true), // архив вне скоупа
        room(4, at: t0, productId: 42), // другой продукт
      ]);
      await s.putMessages(2, [msg(2, 'm2', at: t0)]);

      // Полный список сервера (не-архив, без product-фильтра): 1 и 4.
      await s.reconcileRooms(fresh: [room(1, at: t0), room(4, at: t0)]);

      final ids = (await s.getRooms(includeArchived: true))
          .map((r) => r.id)
          .toSet();
      expect(ids, {1, 3, 4}, reason: 'призрак 2 удалён, архив 3 остался');
      expect(
        await s.getMessages(2),
        isEmpty,
        reason: 'сообщения призрака удалены вместе с комнатой',
      );

      // Product-scoped reconcile: полный список продукта 42 пуст →
      // удаляется только комната продукта 42, глобальные не трогаем.
      await s.reconcileRooms(fresh: const [], productId: 42);
      expect(
        (await s.getRooms(includeArchived: true)).map((r) => r.id).toSet(),
        {1, 3},
      );
    },
  );

  test('gap-reset + removeRoom', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putRooms([room(11, at: t0)]);
    await s.putMessages(11, [msg(11, 'x', at: t0)]);
    await s.resetRoomMessages(11);
    expect(await s.getMessages(11), isEmpty);
    expect(await s.getRooms(), hasLength(1));
    await s.removeRoom(11);
    expect(await s.getRooms(), isEmpty);
  });

  test('битый blob пропускается и удаляется (self-heal)', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putRooms([room(1, at: t0), room(2, at: t0)]);
    await s.debugInsertRawRoom(3, '{ это не json'); // битая строка
    expect(await s.debugRoomRowCount(), 3);

    // getRooms возвращает только валидные И удаляет битую.
    final rooms = await s.getRooms();
    expect(rooms.map((r) => r.id).toSet(), {1, 2});
    expect(await s.debugRoomRowCount(), 2, reason: 'битая строка удалена');
  });

  test('clear (logout) + скоуп по userId (не видно чужого)', () async {
    final s1 = await open(1);
    await s1.putRooms([room(10, at: t0)]);
    await s1.putMessages(10, [msg(10, 'm', at: t0)]);
    await s1.close();

    final s2 = await open(2);
    expect(await s2.getRooms(), isEmpty, reason: 'скоуп по userId');
    await s2.close();

    final s1b = await open(1);
    expect(await s1b.getRooms(), hasLength(1));
    await s1b.clear();
    expect(await s1b.getRooms(), isEmpty);
    expect(await s1b.getMessages(10), isEmpty);
    await s1b.close();
  });

  test(
    'namespace изолирует окружения (тот же userId, разные стенды)',
    () async {
      final prod = await open(5, namespace: 'prod');
      await prod.putRooms([room(1, at: t0)]);
      await prod.close();
      // Другой namespace (тот же userId, тот же каталог) — чужих чатов нет.
      final testEnv = await open(5, namespace: 'stand');
      expect(await testEnv.getRooms(), isEmpty);
      await testEnv.close();
    },
  );

  // ─── TASK47 iter2: дисковый кэш ВЛОЖЕНИЙ (превью картинок) ──────────

  Uint8List blob(int n, {int fill = 7}) =>
      Uint8List.fromList(List.filled(n, fill));

  const thumb = MessengerCacheStore.attachmentKindThumbnail;
  const full = MessengerCacheStore.attachmentKindFull;

  test('attachments: put/get roundtrip + LRU-touch (lastAccessAt)', () async {
    final s = await open(1);
    addTearDown(s.close);
    final data = Uint8List.fromList([1, 2, 3, 4, 5]);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: data);

    // roundtrip: те же байты.
    expect(await s.getAttachment('mxc://a', thumb), equals(data));
    // miss по другому kind / url.
    expect(await s.getAttachment('mxc://a', full), isNull);
    expect(await s.getAttachment('mxc://b', thumb), isNull);

    // LRU-touch: getAttachment двигает lastAccessAt вперёд.
    await s.debugSetAttachmentAccess('mxc://a', thumb, 1000);
    expect(await s.debugAttachmentAccess('mxc://a', thumb), 1000);
    await s.getAttachment('mxc://a', thumb);
    final touched = await s.debugAttachmentAccess('mxc://a', thumb);
    expect(touched, isNotNull);
    expect(
      touched! > 1000,
      isTrue,
      reason: 'getAttachment трогает lastAccessAt (LRU)',
    );
  });

  test('attachments: attachmentsCacheSize = SUM(sizeBytes)', () async {
    final s = await open(1);
    addTearDown(s.close);
    expect(await s.attachmentsCacheSize(), 0);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(100));
    await s.putAttachment(mxcUrl: 'mxc://b', kind: thumb, bytes: blob(250));
    expect(await s.attachmentsCacheSize(), 350);
    // upsert того же ключа обновляет размер (REPLACE — не дублирует строку).
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(50));
    expect(await s.attachmentsCacheSize(), 300);
    expect(await s.debugAttachmentRowCount(), 2);
  });

  test(
    'evictAttachmentsToLimit удаляет наименее-недавно-использованные до лимита',
    () async {
      final s = await open(1);
      addTearDown(s.close);
      for (final id in ['a', 'b', 'c']) {
        await s.putAttachment(mxcUrl: 'mxc://$id', kind: thumb, bytes: blob(100));
      }
      // Явные метки: a — самое старое, c — самое свежее.
      await s.debugSetAttachmentAccess('mxc://a', thumb, 100);
      await s.debugSetAttachmentAccess('mxc://b', thumb, 200);
      await s.debugSetAttachmentAccess('mxc://c', thumb, 300);
      expect(await s.attachmentsCacheSize(), 300);

      // Лимит 150 → удаляем a (100), затем b (200) → остаётся c (100 ≤ 150).
      final removed = await s.evictAttachmentsToLimit(150);
      expect(removed, 2);
      expect(await s.attachmentsCacheSize(), 100);
      expect(await s.getAttachment('mxc://c', thumb), isNotNull);
      expect(await s.getAttachment('mxc://a', thumb), isNull);
      expect(await s.getAttachment('mxc://b', thumb), isNull);
    },
  );

  test('evict: touched (недавно прочитанное) переживает обрезку', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(100));
    await s.putAttachment(mxcUrl: 'mxc://b', kind: thumb, bytes: blob(100));
    await s.debugSetAttachmentAccess('mxc://a', thumb, 100); // старее
    await s.debugSetAttachmentAccess('mxc://b', thumb, 200);
    // Читаем 'a' → его lastAccessAt прыгает в now (самый свежий).
    await s.getAttachment('mxc://a', thumb);
    // Лимит 100 → удалить одно; теперь самое старое — 'b'.
    final removed = await s.evictAttachmentsToLimit(100);
    expect(removed, 1);
    expect(
      await s.getAttachment('mxc://a', thumb),
      isNotNull,
      reason: 'touched выжил',
    );
    expect(await s.getAttachment('mxc://b', thumb), isNull);
  });

  test('evict: «без лимита» (<0) — no-op; 0 — чистит всё', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(100));
    expect(await s.evictAttachmentsToLimit(-1), 0);
    expect(await s.attachmentsCacheSize(), 100, reason: '<0 = без лимита');
    expect(await s.evictAttachmentsToLimit(0), 1);
    expect(await s.attachmentsCacheSize(), 0);
  });

  test('битый BLOB attachment пропускается и удаляется (self-heal)', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(0));
    // Пустой BLOB трактуем как отсутствие + удаляем строку.
    expect(await s.getAttachment('mxc://a', thumb), isNull);
    expect(await s.debugAttachmentRowCount(), 0);
  });

  test('clear (logout) чистит и вложения', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putRooms([room(1, at: t0)]);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(100));
    await s.clear();
    expect(await s.attachmentsCacheSize(), 0);
    expect(await s.getAttachment('mxc://a', thumb), isNull);
    expect(await s.getRooms(), isEmpty);
  });

  test('clearAttachments чистит только вложения (комнаты остаются)', () async {
    final s = await open(1);
    addTearDown(s.close);
    await s.putRooms([room(1, at: t0)]);
    await s.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(100));
    final removed = await s.clearAttachments();
    expect(removed, 1);
    expect(await s.attachmentsCacheSize(), 0);
    expect(
      await s.getRooms(),
      hasLength(1),
      reason: 'clearAttachments не трогает комнаты',
    );
  });

  test('attachments скоуплены по userId (не видно чужого)', () async {
    final s1 = await open(1);
    await s1.putAttachment(mxcUrl: 'mxc://a', kind: thumb, bytes: blob(100));
    await s1.close();
    final s2 = await open(2);
    expect(await s2.getAttachment('mxc://a', thumb), isNull);
    expect(await s2.attachmentsCacheSize(), 0);
    await s2.close();
  });
}
