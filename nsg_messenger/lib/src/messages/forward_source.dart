import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'chat_message.dart';

/// **Issue #41 — переход к первоисточнику пересланного сообщения.**
///
/// Координаты исходного сообщения: внутренний `roomId` (наш, НЕ Matrix
/// `!room:server`) + Matrix `eventId`. Едут в custom-полях сырого
/// Matrix-content-а (`nsg.forwarded_room_id` / `nsg.forwarded_event_id`) —
/// тот же passthrough-паттерн, что `nsg.album_id` / `nsg.forwarded_from`.
///
/// Пара **атомарна**: одна половина бесполезна (по eventId без комнаты
/// нечего открывать, по комнате без eventId некуда скроллить), поэтому
/// [tryParse] возвращает null, если распарсилась не вся пара.
@immutable
class ForwardSource {
  const ForwardSource({required this.roomId, required this.eventId});

  /// Внутренний id комнаты-первоисточника (`Room.id`).
  final int roomId;

  /// Matrix event id исходного сообщения.
  final String eventId;

  /// Разобрать координаты из сырого Matrix-content-а.
  ///
  /// Возвращает null для всех «промахов» — это НОРМА, а не ошибка:
  ///   * старое пересланное сообщение (отправлено до issue #41) — полей нет;
  ///   * кривые значения (не-число, пустая строка, отрицательный id) —
  ///     content приходит из Matrix, где кто угодно мог положить что угодно,
  ///     так что доверять типам нельзя;
  ///   * заполнена лишь половина пары.
  ///
  /// `roomId` терпимо принимает и число, и строку-число: JSON-мост между
  /// Matrix и клиентом исторически возвращал числа то как `int`, то как
  /// строку (см. такой же defensive-парсинг у `nsg.forwarded_from_uid`).
  static ForwardSource? tryParse(Map<String, dynamic>? content) {
    if (content == null) return null;
    final roomId = _asPositiveInt(content['nsg.forwarded_room_id']);
    final eventId = content['nsg.forwarded_event_id'];
    if (roomId == null) return null;
    if (eventId is! String || eventId.isEmpty) return null;
    return ForwardSource(roomId: roomId, eventId: eventId);
  }

  /// Число > 0 из `int` / целочисленного `num` / строки-числа. Иначе null.
  /// Дробное значение отбрасываем целиком (а не усекаем): «3.7» — признак
  /// битых данных, а не round-trip-а корректного id.
  static int? _asPositiveInt(Object? v) {
    int? parsed;
    if (v is int) {
      parsed = v;
    } else if (v is num) {
      if (v != v.roundToDouble()) return null;
      parsed = v.toInt();
    } else if (v is String) {
      parsed = int.tryParse(v.trim());
    }
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  @override
  bool operator ==(Object other) =>
      other is ForwardSource &&
      other.roomId == roomId &&
      other.eventId == eventId;

  @override
  int get hashCode => Object.hash(roomId, eventId);

  @override
  String toString() => 'ForwardSource(room=$roomId, event=$eventId)';
}

/// Какие координаты записать в **новое** пересланное сообщение при
/// пересылке [message] из комнаты [currentRoomId].
///
/// Правило зеркалит атрибуцию по имени (`forwardedFromName ??
/// senderDisplayName` в `MessagesController._forwardOne`): при повторной
/// пересылке уже пересланного сообщения и имя, и координаты указывают на
/// **первоисточник**, а не на промежуточное звено. Иначе шапка врала бы:
/// «Переслано от Алисы», а тап открывал бы чат Боба, который всего лишь
/// переслал сообщение Алисы дальше.
///
/// Возвращает null (пересылаем без координат — шапка будет некликабельной):
///   * у re-forward-а старого сообщения координат нет: указать на
///     промежуточное звено было бы РАСХОЖДЕНИЕМ с именем в шапке, а
///     первоисточник нам взять неоткуда — честнее не давать ссылку вообще;
///   * у сообщения ещё нет `matrixEventId` (pending, RPC не вернулся) —
///     ссылаться не на что.
ForwardSource? resolveForwardSource({
  required ChatMessage message,
  required int currentRoomId,
}) {
  // Re-forward: переносим координаты первоисточника как есть.
  final inherited = message.forwardedSource;
  if (inherited != null) return inherited;
  // Re-forward старого сообщения (имя есть, координат нет) — см. doc выше.
  if (message.isForwarded) return null;

  final eventId = message.matrixEventId;
  if (eventId == null || eventId.isEmpty) return null;
  if (currentRoomId <= 0) return null;
  return ForwardSource(roomId: currentRoomId, eventId: eventId);
}
