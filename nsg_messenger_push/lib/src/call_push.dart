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
/// **TASK51 чанк 4 (mesh-конференции)** — аддитивные поля, есть только у
/// побудки на ГРУППОВОЙ звонок:
///
///   * `callKind`   = `"conference"` — accept ведёт не в 1:1, а в
///                    конференцию комнаты;
///   * `confId`     = id конференции (`conf_<32 hex>`) — стабилен на всю
///                    конференцию, в отличие от `callId` пары;
///   * `callKitId`  = id CallKit-сессии (UUID из confId, см.
///                    [conferenceCallKitId]) — ОДИН на конференцию, чтобы
///                    повторные побудки (каждый новый участник шлёт свой
///                    pairwise-invite) схлопывались в один «входящий», а
///                    не в стопку;
///   * `roomName`   = имя комнаты для заголовка входящего.
///
/// Старый сервер этих полей не шлёт → [isConference] = false и всё
/// работает как в TASK46.
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
    this.confId,
    this.roomName = '',
    String? callKitIdOverride,
  }) : _callKitIdOverride = callKitIdOverride;

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

  /// **TASK51 чанк 4**: id конференции (`conf_<32 hex>`), если это побудка
  /// на групповой звонок; `null` для 1:1. Стабилен на всю конференцию —
  /// в отличие от [callId], который свой у каждой pairwise-пары.
  final String? confId;

  /// Имя комнаты (для заголовка группового входящего). Пусто, если сервер
  /// его не прислал (безымянная комната / старый сервер).
  final String roomName;

  /// Готовый id CallKit-сессии из payload (`data['callKitId']`). Приватен:
  /// наружу отдаётся [callKitId], который умеет и посчитать его сам.
  final String? _callKitIdOverride;

  /// Это побудка на групповой (mesh) звонок: accept = вход в конференцию
  /// комнаты, а не ответ на 1:1.
  bool get isConference => confId != null && confId!.isNotEmpty;

  /// **id CallKit-сессии** — то, что уезжает в `CallKitParams.id`.
  ///
  ///   * 1:1 — сам [callId] (он же UUID звонка; так было в TASK46);
  ///   * конференция — id, общий для ВСЕХ побудок этой конференции
  ///     (см. [conferenceCallKitId]). Именно это схлопывает пачку
  ///     pairwise-побудок в один «входящий».
  String get callKitId {
    final override = _callKitIdOverride;
    if (override != null && override.isNotEmpty) return override;
    final conf = confId;
    if (conf != null && conf.isNotEmpty) return conferenceCallKitId(conf);
    return callId;
  }

  /// **TASK51 чанк 4**: id CallKit-сессии для конференции [confId].
  ///
  /// CallKit требует ВАЛИДНЫЙ UUID (нативный слой делает
  /// `UUID(uuidString:)`, плагин форс-анврапит результат), а confId имеет
  /// вид `conf_<32 hex>` — это ровно 16 случайных байт, то есть UUID без
  /// дефисов. Расставляем дефисы `8-4-4-4-12`: отображение
  /// детерминированное, один confId → один «входящий».
  ///
  /// Дублирует `PushPayloadBuilder.conferenceCallKitId` на сервере
  /// (**менять синхронно**). Здесь она нужна для случая, когда confId
  /// известен из realtime-стрима, а пуша не было — например, чтобы
  /// закрыть CallKit-UI умершей конференции.
  ///
  /// Не-каноничный confId возвращаем как есть (на Android годится любая
  /// строка; на iOS натив упадёт на свой fallback-UUID).
  static String conferenceCallKitId(String confId) {
    final hex = confId.startsWith('conf_') ? confId.substring(5) : confId;
    if (hex.length != 32 || !_hex32.hasMatch(hex)) return confId;
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static final RegExp _hex32 = RegExp(r'^[0-9a-fA-F]{32}$');

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
    final roomName = _asNonEmptyString(data['roomName']);
    // **TASK51 чанк 4**: групповой звонок помечен `callKind=conference`.
    // Признаком считаем именно confId: без него в конференцию не войти
    // (нечего сопоставлять с состоянием контроллера), так что «конференция
    // без confId» — это битый payload, обрабатываем как 1:1.
    final confId = data['callKind'] == 'conference'
        ? _asNonEmptyString(data['confId'])
        : null;

    // callId + roomId обязательны для accept-корреляции; matrixRoomId и
    // имя — для контекста/UI. Без callId/roomId push бесполезен.
    if (callId == null || roomId == null) return null;

    return CallPushData(
      callId: callId,
      roomId: roomId,
      matrixRoomId: matrixRoomId ?? '',
      callerId: callerId ?? 0,
      callerName: callerName ?? '',
      confId: confId,
      roomName: roomName ?? '',
      callKitIdOverride: confId == null
          ? null
          : _asNonEmptyString(data['callKitId']),
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
      other.callerName == callerName &&
      other.confId == confId &&
      other.roomName == roomName &&
      other.callKitId == callKitId;

  @override
  int get hashCode => Object.hash(
    callId,
    roomId,
    matrixRoomId,
    callerId,
    callerName,
    confId,
    roomName,
    callKitId,
  );

  @override
  String toString() =>
      'CallPushData(callId: $callId, roomId: $roomId, '
      'matrixRoomId: $matrixRoomId, callerId: $callerId, '
      'callerName: $callerName, confId: $confId, '
      'roomName: $roomName, callKitId: $callKitId)';
}
