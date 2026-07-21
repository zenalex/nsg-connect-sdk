import 'package:flutter/foundation.dart';

/// **TASK46 (звонки в фоне)**: типизированный разбор data-payload
/// FCM-push-побудки на входящий звонок.
///
/// Серверный контракт (см. `PushPayloadBuilder.buildCall` в
/// `nsg_connect_server`) — data-only high-priority FCM-сообщение, все
/// значения строковые:
///
///   * `type`         = `"call"` — маркер call-push (иначе это обычная
///                      message-нотификация, парсер вернёт null);
///   * `callId`       = id звонка (коррелирует с `m.call.invite`, который
///                      прилетит через /sync и переведёт `CallController`
///                      в `CallIncomingRinging` с тем же callId);
///   * `roomId`       = локальный id комнаты (int строкой);
///   * `matrixRoomId` = Matrix room id;
///   * `callerId`     = messengerUserId звонящего (int строкой);
///   * `callerName`   = отображаемое имя (уже локализовано сервером).
///
/// Чистая логика (без плагинов/isolate-состояния) — тестируется юнит-
/// тестом; используется и в FCM background isolate (app killed), и в
/// foreground-обработчике.
@immutable
class CallPushData {
  const CallPushData({
    required this.callId,
    required this.roomId,
    required this.matrixRoomId,
    required this.callerId,
    required this.callerName,
  });

  /// id звонка — коррелирует с `m.call.invite` (`event.callId`).
  final String callId;

  /// Локальный id комнаты (уже распарсен в int).
  final int roomId;

  /// Matrix room id.
  final String matrixRoomId;

  /// messengerUserId звонящего (уже распарсен в int).
  final int callerId;

  /// Отображаемое имя звонящего (для UI входящего звонка).
  final String callerName;

  /// Разобрать data-map FCM-сообщения. Возвращает `null`, если это не
  /// call-push (`type != 'call'`) или payload неполный/битый — вызывающий
  /// код тогда идёт по обычной ветке (message-нотификация / no-op).
  ///
  /// `data` типизирован как `Map<String, dynamic>`, потому что
  /// `RemoteMessage.data` именно такой; значения по контракту — строки.
  static CallPushData? tryParse(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['type'] != 'call') return null;

    final callId = _asNonEmptyString(data['callId']);
    final matrixRoomId = _asNonEmptyString(data['matrixRoomId']);
    final callerName = _asNonEmptyString(data['callerName']);
    final roomId = _asInt(data['roomId']);
    final callerId = _asInt(data['callerId']);

    // callId + roomId обязательны для accept-корреляции; matrixRoomId и
    // имя — для контекста/UI. Без callId/roomId push бесполезен.
    if (callId == null || roomId == null) return null;

    return CallPushData(
      callId: callId,
      roomId: roomId,
      matrixRoomId: matrixRoomId ?? '',
      callerId: callerId ?? 0,
      callerName: callerName ?? '',
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
  bool operator ==(Object other) =>
      other is CallPushData &&
      other.callId == callId &&
      other.roomId == roomId &&
      other.matrixRoomId == matrixRoomId &&
      other.callerId == callerId &&
      other.callerName == callerName;

  @override
  int get hashCode =>
      Object.hash(callId, roomId, matrixRoomId, callerId, callerName);

  @override
  String toString() =>
      'CallPushData(callId: $callId, roomId: $roomId, '
      'matrixRoomId: $matrixRoomId, callerId: $callerId, '
      'callerName: $callerName)';
}
