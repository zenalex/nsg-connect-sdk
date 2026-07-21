import 'package:flutter/foundation.dart';

/// **Issue #33 (TASK67 часть B)**: типизированный разбор data-payload
/// тихого «read-sync»-пуша — сигнала «комната прочитана на другом
/// устройстве, сними её уведомления».
///
/// Зачем нужен пуш. Событие `roomUnreadChanged` сервер публикует в
/// per-user realtime-канал, поэтому уведомления снимаются только там,
/// где приложение живо и подписано на стрим. Свёрнутое/убитое
/// приложение стрима не слушает — его уведомления по уже прочитанной
/// комнате висят, пока пользователь не смахнёт их руками. Тихий
/// data-пуш будит клиента ровно для того, чтобы он позвал
/// `cancelRoom(roomId)`.
///
/// Серверный контракт (см. `PushPayloadBuilder.buildReadSync` в
/// `nsg_connect_server`) — **data-only** сообщение БЕЗ `notification`-
/// блока (иначе вместо снятия старых уведомлений вспыхнуло бы новое);
/// все значения строковые:
///
///   * `type`         = `"read_sync"` — маркер (иначе парсер вернёт
///                      null и вызывающий код идёт обычной веткой);
///   * `roomId`       = локальный id прочитанной комнаты (int строкой) —
///                      он же `android.notification.tag` / `apns
///                      thread-id` снимаемых уведомлений;
///   * `matrixRoomId` = Matrix room id (контекст/диагностика);
///   * `recipientId`  = messengerUserId адресата (int строкой) — на
///                      устройстве может быть залогинен другой аккаунт.
///
/// Чистая логика (без плагинов и isolate-состояния) — юнит-тестируется и
/// переиспользуется во всех трёх точках приёма: FCM background isolate
/// (app убит), FCM foreground и RuStore foreground.
@immutable
class ReadSyncPushData {
  const ReadSyncPushData({
    required this.roomId,
    required this.matrixRoomId,
    required this.recipientId,
  });

  /// Локальный id прочитанной комнаты (уже распарсен в int).
  final int roomId;

  /// Matrix room id (может быть пустым — для снятия не обязателен).
  final String matrixRoomId;

  /// messengerUserId адресата, или `null` если сервер его не прислал.
  /// Клиент сверяет его с активной сессией: пуш мог прийти для другого
  /// аккаунта, залогиненного на этом устройстве раньше.
  final int? recipientId;

  /// Разобрать data-map входящего пуша. Возвращает `null`, если это не
  /// read-sync (`type != 'read_sync'`) или payload битый.
  ///
  /// `data` типизирован как `Map<String, dynamic>`, потому что
  /// `RemoteMessage.data` именно такой; значения по контракту — строки.
  static ReadSyncPushData? tryParse(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['type'] != readSyncPushType) return null;

    // roomId — единственное обязательное поле: без него нечего снимать.
    final roomId = _asInt(data['roomId']);
    if (roomId == null) return null;

    return ReadSyncPushData(
      roomId: roomId,
      matrixRoomId: _asNonEmptyString(data['matrixRoomId']) ?? '',
      recipientId: _asInt(data['recipientId']),
    );
  }

  static String? _asNonEmptyString(Object? v) {
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return null;
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  @override
  String toString() =>
      'ReadSyncPushData(roomId: $roomId, matrixRoomId: $matrixRoomId, '
      'recipientId: $recipientId)';
}

/// Значение `data['type']` тихого read-sync-пуша. Зеркалит серверную
/// константу `readSyncPushType` (`nsg_connect_server/src/push/
/// push_payload.dart`) — менять только синхронно с сервером.
const String readSyncPushType = 'read_sync';
