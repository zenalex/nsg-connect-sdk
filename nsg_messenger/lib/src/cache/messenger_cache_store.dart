import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

import '../outbox/outbox_item.dart';

// Conditional import: io-вариант (mobile+desktop) даёт реальную фабрику;
// web-стаб — null (дисковый кэш на web в iter1 отключён, §6).
import 'cache_factory_stub.dart' if (dart.library.io) 'cache_factory_io.dart';

/// **TASK47 iter1**: дисковый оффлайн-кэш чатов — список ([RoomSummary]) +
/// последние сообщения ([MessengerMessage]), **только текст** (байты
/// вложений — iter2).
///
/// **Скоуп** двухуровневый:
///   * по [namespace] — окружение/сервер (имя файла БД
///     `messenger_cache_{namespace}.db`): один и тот же каталог + userId в
///     dev/тест/prod НЕ смешивает данные (namespace = отпечаток
///     apiBaseUrl+tenant, см.
///     wiring в runtime; ср. `auth_context_fingerprint.dart`);
///   * по [userId] — колонка на каждой строке: мультиаккаунт на одном
///     устройстве; logout чистит через [clear] (`DELETE WHERE userId`).
///
/// **Хранение** — JSON-blob моделей (`toJson`) + индексные колонки. Каждая
/// строка декодируется в try-catch: битый/устаревший blob НЕ роняет чтение
/// (строка пропускается и удаляется).
///
/// **Платформы**: mobile+desktop (sqflite / sqflite_common_ffi). Web —
/// [openForUser] вернёт `null` (нужен sqlite-wasm worker — §6/iter2); host
/// тогда работает без дискового кэша (in-memory + индикация оффлайна).
class MessengerCacheStore {
  MessengerCacheStore._(this._db, this.userId);

  final Database _db;

  /// Владелец кэша — по нему скоупятся все строки.
  final int userId;

  /// v2 — добавлена таблица `outbox` (персистентная очередь исходящих).
  /// v3 — добавлена таблица `cached_room_details` (полные детали комнаты
  /// для оффлайн-открытия чата — read-through fallback `rooms.get`).
  /// v4 — добавлена таблица `cached_attachments` (байты превью/полноразмера
  /// вложений для оффлайн-показа миниатюр + LRU-обрезка по размеру, iter2).
  /// Таблицы кэша (`cached_rooms`/`cached_messages`/`cached_room_details`/
  /// `cached_attachments`) при апгрейде пересоздаются (расходный кэш), а
  /// `outbox` — `CREATE IF NOT EXISTS`, поэтому bump версии НЕ теряет
  /// поставленные в очередь отправки.
  static const int _schemaVersion = 4;

  /// Лимит превью тела в chat-list (совпадает с серверным TASK13).
  static const int _previewMaxChars = 120;

  /// **OUTBOX**: broadcast-поток roomId-ов, у которых изменилась очередь
  /// (enqueue / mark / delete). [MessagesController] подписан на него, чтобы
  /// pending-бабблы обновлялись вживую; [OutboxSender] — чтобы будить дренаж.
  final StreamController<int> _outboxChangesCtl =
      StreamController<int>.broadcast();
  Stream<int> get outboxRoomChanges => _outboxChangesCtl.stream;

  void _notifyOutbox(int roomId) {
    if (!_outboxChangesCtl.isClosed) _outboxChangesCtl.add(roomId);
  }

  /// Открывает (создавая при необходимости) кэш для [userId] в каталоге
  /// [directory], изолируя окружения по [namespace] (имя файла). Возвращает
  /// `null` на web / при ошибке открытия — тогда SDK работает без диска.
  static Future<MessengerCacheStore?> openForUser({
    required String directory,
    required String namespace,
    required int userId,
  }) async {
    final factory = resolveCacheDatabaseFactory();
    if (factory == null) return null; // web / неподдерживаемая платформа.
    try {
      final safeNs = _sanitizeNamespace(namespace);
      final db = await factory.openDatabase(
        p.join(directory, 'messenger_cache_$safeNs.db'),
        options: OpenDatabaseOptions(
          version: _schemaVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
      return MessengerCacheStore._(db, userId);
    } catch (e) {
      // Best-effort: не роняем init из-за кэша, но НЕ молчим (диагностика).
      debugPrint('[MessengerCacheStore] open failed (ns=$namespace): $e');
      return null;
    }
  }

  static String _sanitizeNamespace(String ns) {
    final cleaned = ns.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? 'default' : cleaned;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_rooms (
        userId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        lastMessageAt INTEGER,
        productId INTEGER,
        archived INTEGER NOT NULL DEFAULT 0,
        nameLower TEXT,
        lastViewedAt INTEGER,
        json TEXT NOT NULL,
        PRIMARY KEY (userId, roomId)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_rooms_user_time '
      'ON cached_rooms (userId, lastMessageAt)',
    );
    await db.execute('''
      CREATE TABLE cached_messages (
        userId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        matrixEventId TEXT NOT NULL,
        serverTimestamp INTEGER NOT NULL,
        json TEXT NOT NULL,
        PRIMARY KEY (userId, roomId, matrixEventId)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_msgs_user_room_time '
      'ON cached_messages (userId, roomId, serverTimestamp)',
    );
    await db.execute('''
      CREATE TABLE cached_room_details (
        userId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        json TEXT NOT NULL,
        PRIMARY KEY (userId, roomId)
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_attachments (
        userId INTEGER NOT NULL,
        mxcUrl TEXT NOT NULL,
        kind TEXT NOT NULL,
        bytes BLOB NOT NULL,
        sizeBytes INTEGER NOT NULL,
        lastAccessAt INTEGER NOT NULL,
        PRIMARY KEY (userId, mxcUrl, kind)
      )
    ''');
    // Индекс под LRU-обход: eviction идёт по возрастанию lastAccessAt.
    await db.execute(
      'CREATE INDEX idx_attachments_user_lru '
      'ON cached_attachments (userId, lastAccessAt)',
    );
    await _createOutboxTable(db);
  }

  /// **OUTBOX**: создать таблицу очереди исходящих. `IF NOT EXISTS` —
  /// чтобы bump схемы кэша (который DROP-ает cache-таблицы) НЕ стирал
  /// поставленные в очередь отправки. Вызывается и в [_onCreate], и в
  /// [_onUpgrade].
  static Future<void> _createOutboxTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox (
        clientTxnId TEXT PRIMARY KEY,
        userId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        kind TEXT NOT NULL,
        body TEXT NOT NULL DEFAULT '',
        msgType TEXT NOT NULL DEFAULT 'm.text',
        attachmentPath TEXT,
        mimeType TEXT,
        originalFilename TEXT,
        albumId TEXT,
        mentionsJson TEXT,
        replyToMatrixEventId TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        nextAttemptAt INTEGER NOT NULL DEFAULT 0,
        lastError TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_user_room '
      'ON outbox (userId, roomId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_due '
      'ON outbox (userId, status, nextAttemptAt)',
    );
  }

  /// Кэш — расходный: при смене версии схемы просто пересоздаём (без
  /// миграции данных; всё до-качается с сервера при первом онлайне). НО
  /// таблицу `outbox` НЕ трогаем (поставленные отправки должны пережить
  /// bump) — только гарантируем её наличие через `CREATE IF NOT EXISTS`.
  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    await db.execute('DROP TABLE IF EXISTS cached_rooms');
    await db.execute('DROP TABLE IF EXISTS cached_messages');
    await db.execute('DROP TABLE IF EXISTS cached_room_details');
    await db.execute('DROP TABLE IF EXISTS cached_attachments');
    // NB: outbox сознательно НЕ дропаем (иначе bump схемы стёр бы очередь).
    await _onCreate(db, newV);
  }

  // ───────────────────────────────────────────── rooms ──

  /// Upsert списка чатов (из ответа `rooms.list`). Идемпотентно по
  /// (userId, roomId). **UPSERT** через rawInsert (не REPLACE): обновляет
  /// только refresh-колонки, СОХРАНЯЯ `lastViewedAt` (нужен LRU итерации 2).
  Future<void> putRooms(List<RoomSummary> rooms) async {
    if (rooms.isEmpty) return;
    final batch = _db.batch();
    for (final r in rooms) {
      batch.rawInsert(
        'INSERT INTO cached_rooms '
        '(userId, roomId, lastMessageAt, productId, archived, nameLower, json) '
        'VALUES (?, ?, ?, ?, ?, ?, ?) '
        'ON CONFLICT(userId, roomId) DO UPDATE SET '
        'lastMessageAt=excluded.lastMessageAt, '
        'productId=excluded.productId, '
        'archived=excluded.archived, '
        'nameLower=excluded.nameLower, '
        'json=excluded.json',
        [
          userId,
          r.id,
          r.lastMessageAt?.millisecondsSinceEpoch,
          r.productId,
          r.archived ? 1 : 0,
          r.name?.toLowerCase(),
          jsonEncode(r.toJson()),
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Кэшированный список чатов: фильтр по [productId]/[includeArchived]/
  /// [search] — ВСЁ в SQL (search через `nameLower LIKE` ДО limit, чтобы
  /// старые комнаты тоже находились оффлайн), сортировка `lastMessageAt
  /// DESC`. Битые blob-строки пропускаются и удаляются.
  Future<List<RoomSummary>> getRooms({
    int? productId,
    bool includeArchived = false,
    String? search,
    int? limit,
  }) async {
    final where = <String>['userId = ?'];
    final args = <Object?>[userId];
    if (productId != null) {
      where.add('productId = ?');
      args.add(productId);
    }
    if (!includeArchived) where.add('archived = 0');
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      where.add('nameLower LIKE ? ESCAPE ?');
      args.add('%${_escapeLike(q)}%');
      args.add('\\');
    }

    final rows = await _db.query(
      'cached_rooms',
      columns: const ['roomId', 'json'],
      where: where.join(' AND '),
      whereArgs: args,
      // NULL lastMessageAt (пустые комнаты) — в конец.
      orderBy: 'lastMessageAt IS NULL, lastMessageAt DESC',
      limit: limit,
    );
    return _decodeRows(
      rows,
      table: 'cached_rooms',
      keyCol: 'roomId',
      decode: _decodeRoom,
    );
  }

  /// **TASK47 §3 п.6 (gap-фикс 2026-07-12)**: реконсиляция
  /// «комнат-призраков» после ПОЛНОГО server-ответа `rooms.list` — удалить
  /// из кэша комнаты скоупа, которых больше нет на сервере (например,
  /// пользователя удалили из комнаты, пока он был оффлайн — realtime-
  /// событие `membershipRemoved` не было доставлено). Без этого комната
  /// навсегда всплывала бы в оффлайн-списке.
  ///
  /// Caller обязан звать ТОЛЬКО когда [fresh] покрывает весь скоуп:
  /// первая страница (`cursor == null`), без search-фильтра и
  /// `fresh.length < limit` (весь список уместился в страницу). Скоуп
  /// удаления повторяет фильтры [getRooms]: [productId] и (при
  /// `includeArchived == false`) только неархивные строки.
  Future<void> reconcileRooms({
    required List<RoomSummary> fresh,
    int? productId,
    bool includeArchived = false,
  }) async {
    final keep = fresh.map((r) => r.id).toSet();
    final where = <String>['userId = ?'];
    final args = <Object?>[userId];
    if (productId != null) {
      where.add('productId = ?');
      args.add(productId);
    }
    if (!includeArchived) where.add('archived = 0');
    final rows = await _db.query(
      'cached_rooms',
      columns: const ['roomId'],
      where: where.join(' AND '),
      whereArgs: args,
    );
    for (final row in rows) {
      final id = row['roomId'] as int;
      if (!keep.contains(id)) await removeRoom(id);
    }
  }

  /// Удаляет комнату из кэша (напр. при выходе/удалении из комнаты) вместе
  /// с её сообщениями — в одной транзакции.
  Future<void> removeRoom(int roomId) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'cached_rooms',
        where: 'userId = ? AND roomId = ?',
        whereArgs: [userId, roomId],
      );
      await txn.delete(
        'cached_messages',
        where: 'userId = ? AND roomId = ?',
        whereArgs: [userId, roomId],
      );
      await txn.delete(
        'cached_room_details',
        where: 'userId = ? AND roomId = ?',
        whereArgs: [userId, roomId],
      );
    });
  }

  // ──────────────────────────────────────── room details ──

  /// **TASK47-i2**: upsert полных деталей комнаты (из `rooms.get`) — чтобы
  /// ChatScreen открывался ОФФЛАЙН (детали + кэш-сообщения), а не висел на
  /// сетевом `get(roomId)`. Идемпотентно по (userId, roomId).
  Future<void> putRoomDetails(int roomId, RoomDetails details) async {
    await _db.insert(
      'cached_room_details',
      {'userId': userId, 'roomId': roomId, 'json': jsonEncode(details.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// **TASK47-i2**: кэшированные детали комнаты (read-through fallback для
  /// `rooms.get` оффлайн). `null`, если записи нет или blob битый (битую
  /// строку удаляем — self-heal, как в [_decodeRows]).
  Future<RoomDetails?> getRoomDetails(int roomId) async {
    final rows = await _db.query(
      'cached_room_details',
      columns: const ['json'],
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      return _decodeRoomDetails(rows.first['json'] as String);
    } catch (_) {
      await _db.delete(
        'cached_room_details',
        where: 'userId = ? AND roomId = ?',
        whereArgs: [userId, roomId],
      );
      debugPrint('[MessengerCacheStore] dropped corrupt room_details $roomId');
      return null;
    }
  }

  // ─────────────────────────────────────────── attachments ──

  /// Значение `kind` для миниатюры (chat-bubble preview / avatar).
  static const String attachmentKindThumbnail = 'thumbnail';

  /// Значение `kind` для полноразмерного вложения (tap-fullscreen).
  static const String attachmentKindFull = 'full';

  /// **TASK47-i2**: положить байты вложения в дисковый кэш (upsert по
  /// (userId, mxcUrl, kind)). `sizeBytes` = длина буфера, `lastAccessAt` =
  /// «сейчас» (millis) — свежезаписанное считается недавно использованным.
  /// Контент по `mxcUrl` в Matrix иммутабелен, поэтому REPLACE безопасен.
  Future<void> putAttachment({
    required String mxcUrl,
    required String kind,
    required Uint8List bytes,
  }) async {
    await _db.insert('cached_attachments', {
      'userId': userId,
      'mxcUrl': mxcUrl,
      'kind': kind,
      'bytes': bytes,
      'sizeBytes': bytes.length,
      'lastAccessAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// **TASK47-i2**: байты вложения из кэша (`null`, если записи нет). ТРОГАЕТ
  /// `lastAccessAt` (LRU-touch) — прочитанное вложение становится «недавно
  /// использованным» и переживает следующую обрезку. Битую/пустую BLOB-строку
  /// удаляем (self-heal, как в [_decodeRows]).
  Future<Uint8List?> getAttachment(String mxcUrl, String kind) async {
    final rows = await _db.query(
      'cached_attachments',
      columns: const ['bytes'],
      where: 'userId = ? AND mxcUrl = ? AND kind = ?',
      whereArgs: [userId, mxcUrl, kind],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['bytes'];
    final Uint8List? data;
    if (raw is Uint8List) {
      data = raw;
    } else if (raw is List<int>) {
      data = Uint8List.fromList(raw);
    } else {
      data = null;
    }
    if (data == null || data.isEmpty) {
      await _db.delete(
        'cached_attachments',
        where: 'userId = ? AND mxcUrl = ? AND kind = ?',
        whereArgs: [userId, mxcUrl, kind],
      );
      return null;
    }
    // LRU-touch: помечаем как недавно использованный.
    await _db.update(
      'cached_attachments',
      {'lastAccessAt': DateTime.now().millisecondsSinceEpoch},
      where: 'userId = ? AND mxcUrl = ? AND kind = ?',
      whereArgs: [userId, mxcUrl, kind],
    );
    return data;
  }

  /// **TASK47-i2**: суммарный размер кэша вложений владельца, байт (для UI
  /// «Хранилище»). `0`, если кэш пуст.
  Future<int> attachmentsCacheSize() async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(sizeBytes), 0) AS total '
      'FROM cached_attachments WHERE userId = ?',
      [userId],
    );
    final v = rows.first['total'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  /// **TASK47-i2**: LRU-обрезка кэша вложений до [maxBytes]. Удаляет строки по
  /// ВОЗРАСТАНИЮ `lastAccessAt` (наименее недавно использованные — первыми),
  /// пока суммарный размер строго превышает лимит. Возвращает число удалённых
  /// строк.
  ///
  /// **Контракт «без лимита»**: `maxBytes < 0` → no-op (возвращает `0`, ничего
  /// не удаляет). `maxBytes == 0` → чистит всё. Так host может представить
  /// «без лимита» отрицательным сентинелом, не разветвляя логику на своей
  /// стороне.
  Future<int> evictAttachmentsToLimit(int maxBytes) async {
    if (maxBytes < 0) return 0; // «без лимита» — не трогаем.
    var total = await attachmentsCacheSize();
    if (total <= maxBytes) return 0;
    final rows = await _db.query(
      'cached_attachments',
      columns: const ['mxcUrl', 'kind', 'sizeBytes'],
      where: 'userId = ?',
      whereArgs: [userId],
      // Наименее недавно использованные — первыми; mxcUrl как tie-breaker,
      // чтобы порядок был детерминированным при равных lastAccessAt.
      orderBy: 'lastAccessAt ASC, mxcUrl ASC, kind ASC',
    );
    final batch = _db.batch();
    var removed = 0;
    for (final row in rows) {
      if (total <= maxBytes) break;
      final size = (row['sizeBytes'] as int?) ?? 0;
      batch.delete(
        'cached_attachments',
        where: 'userId = ? AND mxcUrl = ? AND kind = ?',
        whereArgs: [userId, row['mxcUrl'], row['kind']],
      );
      total -= size;
      removed++;
    }
    if (removed > 0) await batch.commit(noResult: true);
    return removed;
  }

  /// **TASK47-i2**: удалить ВСЕ вложения владельца из кэша (кнопка «Очистить
  /// кэш» в настройках). Возвращает число удалённых строк.
  Future<int> clearAttachments() async {
    return _db.delete(
      'cached_attachments',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ──────────────────────────────────────────── messages ──

  /// Upsert сообщений комнаты (из `listMessages`). Идемпотентно по
  /// (userId, roomId, matrixEventId).
  Future<void> putMessages(int roomId, List<MessengerMessage> messages) async {
    if (messages.isEmpty) return;
    final batch = _db.batch();
    for (final m in messages) {
      batch.insert(
        'cached_messages',
        _messageRow(roomId, m),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _messageRow(int roomId, MessengerMessage m) => {
    'userId': userId,
    'roomId': roomId,
    'matrixEventId': m.matrixEventId,
    'serverTimestamp': m.serverTimestamp.millisecondsSinceEpoch,
    'json': jsonEncode(m.toJson()),
  };

  /// Последние [limit] сообщений комнаты, в порядке ВОЗРАСТАНИЯ времени
  /// (как отдаёт `listMessages` для показа). Битые blob-строки пропускаются.
  Future<List<MessengerMessage>> getMessages(
    int roomId, {
    int limit = 50,
  }) async {
    final rows = await _db.query(
      'cached_messages',
      columns: const ['matrixEventId', 'json'],
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
      orderBy: 'serverTimestamp DESC',
      limit: limit,
    );
    final msgs = await _decodeRows(
      rows,
      table: 'cached_messages',
      keyCol: 'matrixEventId',
      decode: _decodeMessage,
    );
    return msgs.reversed.toList(); // → ascending
  }

  /// Realtime `messageCreated`: кладём сообщение и (если оно НОВЕЕ текущего
  /// last — guard от replay после reconnect) обновляем превью/время комнаты
  /// в chat-list-кэше + инкрементим unread для ЧУЖИХ сообщений (оффлайн-
  /// бейдж). Если комнаты ещё нет в кэше — только сообщение.
  Future<void> applyMessageCreated(MessengerMessage m) async {
    await putMessages(m.roomId, [m]);
    final rows = await _db.query(
      'cached_rooms',
      columns: const ['lastMessageAt', 'json'],
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, m.roomId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final currentLastAt = rows.first['lastMessageAt'] as int?;
    final newAt = m.serverTimestamp.millisecondsSinceEpoch;
    // Guard: не откатываем превью/время на re-delivered старом событии.
    if (currentLastAt != null && newAt <= currentLastAt) return;

    final summary = _tryDecodeRoom(rows.first['json'] as String);
    if (summary == null) return;
    summary.lastMessageAt = m.serverTimestamp;
    summary.lastMessagePreview = _previewOf(m);
    final sender = m.senderMessengerUserId;
    if (sender != null && sender != userId) {
      summary.unreadCount = summary.unreadCount + 1;
    }
    await putRooms([summary]);
  }

  /// Realtime `messageUpdated` (правка тела, TASK47 gap-фикс 2026-07-12):
  /// обновляем кэш-строку сообщения — но ТОЛЬКО если она уже в кэше
  /// (INSERT здесь запрещён: одиночная вставка в комнату, чьи сообщения
  /// не кэшированы/сброшены gap-детектом, создала бы несмежный диапазон —
  /// см. [resetRoomMessages]). Затем пересчитываем превью комнаты: если
  /// правили новейшее сообщение — текст в chat-list-превью обновится;
  /// для не-новейшего пересчёт по превью no-op.
  Future<void> applyMessageUpdated(MessengerMessage m) async {
    final updated = await _db.update(
      'cached_messages',
      _messageRow(m.roomId, m),
      where: 'userId = ? AND roomId = ? AND matrixEventId = ?',
      whereArgs: [userId, m.roomId, m.matrixEventId],
    );
    if (updated == 0) return;
    await _recomputeRoomPreview(m.roomId);
  }

  /// Realtime `messageDeleted`/redaction: убираем сообщение из кэша и
  /// ПЕРЕСЧИТЫВАЕМ превью комнаты по новейшему оставшемуся сообщению —
  /// иначе текст удалённого остаётся в chat-list-превью (§3 п.6).
  Future<void> applyMessageDeleted(int roomId, String matrixEventId) async {
    await _db.delete(
      'cached_messages',
      where: 'userId = ? AND roomId = ? AND matrixEventId = ?',
      whereArgs: [userId, roomId, matrixEventId],
    );
    await _recomputeRoomPreview(roomId);
  }

  Future<void> _recomputeRoomPreview(int roomId) async {
    final roomRows = await _db.query(
      'cached_rooms',
      columns: const ['json'],
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
      limit: 1,
    );
    if (roomRows.isEmpty) return;
    final summary = _tryDecodeRoom(roomRows.first['json'] as String);
    if (summary == null) return;

    final msgRows = await _db.query(
      'cached_messages',
      columns: const ['json'],
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
      orderBy: 'serverTimestamp DESC',
      limit: 1,
    );
    if (msgRows.isEmpty) {
      summary.lastMessagePreview = null;
      summary.lastMessageAt = null;
    } else {
      final newest = _tryDecodeMessage(msgRows.first['json'] as String);
      if (newest == null) return;
      summary.lastMessagePreview = _previewOf(newest);
      summary.lastMessageAt = newest.serverTimestamp;
    }
    await putRooms([summary]);
  }

  /// **Gap-стратегия** (§3 п.7): при разрыве между кэш-хвостом и новой
  /// «головой» комнаты сбрасываем ВСЕ её кэш-сообщения — дальше история
  /// докачивается скроллом как обычно (наивный merge несмежных диапазонов
  /// запрещён).
  Future<void> resetRoomMessages(int roomId) async {
    await _db.delete(
      'cached_messages',
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
    );
  }

  // ───────────────────────────────────────────── outbox ──

  /// **OUTBOX**: поставить исходящее в очередь (idempotent по clientTxnId —
  /// REPLACE). `userId` форсим на владельца store. Эмитит [outboxRoomChanges].
  Future<void> enqueueOutbox(OutboxItem item) async {
    final row = item.toRow();
    row['userId'] = userId; // скоуп на владельца store
    await _db.insert(
      'outbox',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyOutbox(item.roomId);
  }

  /// **OUTBOX**: все элементы очереди комнаты в FIFO-порядке (createdAt ASC).
  Future<List<OutboxItem>> outboxForRoom(int roomId) async {
    final rows = await _db.query(
      'outbox',
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(OutboxItem.fromRow).toList();
  }

  /// **OUTBOX**: due-строки для дренажа — не `sending` и `nextAttemptAt <=
  /// nowMs`, FIFO по createdAt. `failed` тоже исключаем (ручной retry
  /// переводит их обратно в pending с nextAttemptAt=0).
  Future<List<OutboxItem>> outboxDue(int nowMs) async {
    final rows = await _db.query(
      'outbox',
      where: 'userId = ? AND status = ? AND nextAttemptAt <= ?',
      whereArgs: [userId, OutboxStatus.pending, nowMs],
      orderBy: 'createdAt ASC',
    );
    return rows.map(OutboxItem.fromRow).toList();
  }

  /// **OUTBOX**: все элементы очереди владельца (все комнаты) — для
  /// стартового дренажа и тестов.
  Future<List<OutboxItem>> allOutbox() async {
    final rows = await _db.query(
      'outbox',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(OutboxItem.fromRow).toList();
  }

  /// **OUTBOX**: пометить строку `sending` (re-entrancy guard дренажа).
  Future<void> markOutboxSending(String clientTxnId) =>
      _updateOutbox(clientTxnId, {'status': OutboxStatus.sending});

  /// **OUTBOX**: транзиентная ошибка — назад в `pending` с бэкоффом.
  Future<void> markOutboxBackoff(
    String clientTxnId, {
    required int attempts,
    required int nextAttemptAt,
    String? lastError,
  }) => _updateOutbox(clientTxnId, {
    'status': OutboxStatus.pending,
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt,
    'lastError': lastError,
  });

  /// **OUTBOX**: перманентная ошибка (4xx/доменная) — `failed` (UI:
  /// повторить/удалить).
  /// [attempts] — передаётся, когда отправитель сдался по лимиту попыток:
  /// иначе в строке осталось бы число с ПРЕДЫДУЩЕЙ (успевшей записаться)
  /// попытки, и по логам не понять, сколько раз мы на самом деле пытались.
  Future<void> markOutboxFailed(
    String clientTxnId, {
    String? lastError,
    int? attempts,
  }) => _updateOutbox(clientTxnId, {
    'status': OutboxStatus.failed,
    'lastError': lastError,
    'attempts': ?attempts,
  });

  /// **OUTBOX**: ручной retry из UI — `failed`/`pending` строку возвращаем в
  /// `pending` с `nextAttemptAt=0`, чтобы ближайший дренаж её взял сразу.
  Future<void> resetOutboxForRetry(String clientTxnId) => _updateOutbox(
    clientTxnId,
    {'status': OutboxStatus.pending, 'nextAttemptAt': 0, 'lastError': null},
  );

  /// **OUTBOX**: удалить строку (успех / discard). Эмитит [outboxRoomChanges].
  Future<void> deleteOutbox(String clientTxnId) async {
    final roomId = await _outboxRoomId(clientTxnId);
    await _db.delete(
      'outbox',
      where: 'userId = ? AND clientTxnId = ?',
      whereArgs: [userId, clientTxnId],
    );
    if (roomId != null) _notifyOutbox(roomId);
  }

  Future<void> _updateOutbox(
    String clientTxnId,
    Map<String, Object?> values,
  ) async {
    await _db.update(
      'outbox',
      values,
      where: 'userId = ? AND clientTxnId = ?',
      whereArgs: [userId, clientTxnId],
    );
    final roomId = await _outboxRoomId(clientTxnId);
    if (roomId != null) _notifyOutbox(roomId);
  }

  Future<int?> _outboxRoomId(String clientTxnId) async {
    final rows = await _db.query(
      'outbox',
      columns: const ['roomId'],
      where: 'userId = ? AND clientTxnId = ?',
      whereArgs: [userId, clientTxnId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['roomId'] as int?;
  }

  // ─────────────────────────────────────────── lifecycle ──

  /// Logout: чистим кэш вышедшего пользователя (§3 п.3) — обе таблицы в
  /// одной транзакции. **Outbox НЕ трогаем** здесь: очередь отправок живёт
  /// своей жизнью (доставляется после re-login); явная чистка — на смене
  /// аккаунта через отдельный вызов при необходимости.
  Future<void> clear() async {
    await _db.transaction((txn) async {
      await txn.delete(
        'cached_rooms',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'cached_messages',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'cached_room_details',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'cached_attachments',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<void> close() async {
    await _outboxChangesCtl.close();
    await _db.close();
  }

  /// **@visibleForTesting**: LRU-метка last-viewed (колонка итерации 2).
  /// Нужна для теста, что [putRooms]-UPSERT её СОХРАНЯЕТ (не обнуляет).
  @visibleForTesting
  Future<void> debugSetLastViewed(int roomId, int millis) => _db.update(
    'cached_rooms',
    {'lastViewedAt': millis},
    where: 'userId = ? AND roomId = ?',
    whereArgs: [userId, roomId],
  );

  /// **@visibleForTesting**: вставить произвольный (в т.ч. битый) json —
  /// для проверки per-row self-heal в [getRooms].
  @visibleForTesting
  Future<void> debugInsertRawRoom(int roomId, String json) => _db.insert(
    'cached_rooms',
    {'userId': userId, 'roomId': roomId, 'lastMessageAt': 0, 'json': json},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @visibleForTesting
  Future<int> debugRoomRowCount() async {
    final rows = await _db.query(
      'cached_rooms',
      columns: const ['roomId'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.length;
  }

  @visibleForTesting
  Future<int?> debugLastViewed(int roomId) async {
    final rows = await _db.query(
      'cached_rooms',
      columns: const ['lastViewedAt'],
      where: 'userId = ? AND roomId = ?',
      whereArgs: [userId, roomId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['lastViewedAt'] as int?;
  }

  /// **@visibleForTesting**: детерминированно выставить `lastAccessAt` строки
  /// вложения — `DateTime.now()` в тесте не даёт стабильного порядка при
  /// быстрых put-ах, поэтому LRU-тест управляет метками явно.
  @visibleForTesting
  Future<void> debugSetAttachmentAccess(
    String mxcUrl,
    String kind,
    int millis,
  ) => _db.update(
    'cached_attachments',
    {'lastAccessAt': millis},
    where: 'userId = ? AND mxcUrl = ? AND kind = ?',
    whereArgs: [userId, mxcUrl, kind],
  );

  /// **@visibleForTesting**: `lastAccessAt` строки вложения (проверка
  /// LRU-touch в [getAttachment]). `null`, если записи нет.
  @visibleForTesting
  Future<int?> debugAttachmentAccess(String mxcUrl, String kind) async {
    final rows = await _db.query(
      'cached_attachments',
      columns: const ['lastAccessAt'],
      where: 'userId = ? AND mxcUrl = ? AND kind = ?',
      whereArgs: [userId, mxcUrl, kind],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['lastAccessAt'] as int?;
  }

  /// **@visibleForTesting**: число строк вложений владельца.
  @visibleForTesting
  Future<int> debugAttachmentRowCount() async {
    final rows = await _db.query(
      'cached_attachments',
      columns: const ['mxcUrl'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.length;
  }

  // ───────────────────────────────────────────── helpers ──

  /// Экранирование LIKE-метасимволов (`%`, `_`, `\`) в user-поиске.
  static String _escapeLike(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');

  /// Декодирует строки blob-ов; битые/устаревшие пропускает И удаляет
  /// (self-heal, чтобы не отравлять кэш навсегда).
  Future<List<T>> _decodeRows<T>(
    List<Map<String, Object?>> rows, {
    required String table,
    required String keyCol,
    required T Function(String json) decode,
  }) async {
    final result = <T>[];
    final bad = <Object?>[];
    for (final row in rows) {
      try {
        result.add(decode(row['json'] as String));
      } catch (e) {
        bad.add(row[keyCol]);
      }
    }
    if (bad.isNotEmpty) {
      final placeholders = List.filled(bad.length, '?').join(',');
      await _db.delete(
        table,
        where: 'userId = ? AND $keyCol IN ($placeholders)',
        whereArgs: [userId, ...bad],
      );
      debugPrint(
        '[MessengerCacheStore] dropped ${bad.length} stale/corrupt '
        '$table row(s)',
      );
    }
    return result;
  }

  RoomSummary _decodeRoom(String json) =>
      RoomSummary.fromJson(jsonDecode(json) as Map<String, dynamic>);

  MessengerMessage _decodeMessage(String json) =>
      MessengerMessage.fromJson(jsonDecode(json) as Map<String, dynamic>);

  RoomDetails _decodeRoomDetails(String json) =>
      RoomDetails.fromJson(jsonDecode(json) as Map<String, dynamic>);

  RoomSummary? _tryDecodeRoom(String json) {
    try {
      return _decodeRoom(json);
    } catch (_) {
      return null;
    }
  }

  MessengerMessage? _tryDecodeMessage(String json) {
    try {
      return _decodeMessage(json);
    } catch (_) {
      return null;
    }
  }

  /// Оффлайн-превью тела для chat-list (аппроксимация серверного). Обрезаем
  /// до [_previewMaxChars], НЕ разрезая суррогатную пару (эмодзи вне BMP).
  /// Полное совпадение с серверным правилом (плейсхолдеры медиа, «…») —
  /// при wiring realtime-merge.
  static String _previewOf(MessengerMessage m) {
    final body = m.body;
    if (body.length <= _previewMaxChars) return body;
    var end = _previewMaxChars;
    final unit = body.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) end -= 1; // high surrogate на границе
    return body.substring(0, end);
  }
}
