/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// Ожидание подтверждения доставки сообщения конкретному получателю.
///
/// Живёт в кэше (Redis) несколько секунд и служит payload-ом отложенной
/// проверки [PushAfterAckFutureCall]: не подтвердил никто — шлём пуш.
///
/// **Зачем понадобилось.** Раньше пуш подавлялся ДОГАДКОЙ: сервер держал
/// `presence:<user>` с TTL 60 секунд и, если там значилось «приложение
/// открыто в этой же комнате», молчал. Догадка врала в обе стороны:
/// запись протухала у человека, который сидит в чате (лишний баннер), и
/// наоборот — оставалась после закрытия приложения, глуша уведомления у
/// того, кто ушёл. Плюс ключ был один на пользователя, поэтому открытый
/// чат на десктопе глушил телефон.
///
/// Теперь подавление — следствие ФАКТА: клиент подтвердил, что принял
/// сообщение и способен показать его человеку. Не подтвердил никто за
/// отведённое окно — значит человек недоступен, шлём пуш.
///
/// DTO без `table:` — состояние живёт в кэше, в БД ему делать нечего.
abstract class DeliveryPending implements _i1.SerializableModel {
  DeliveryPending._({
    required this.recipientMessengerUserId,
    required this.matrixEventId,
    required this.roomId,
    required this.payloadsJson,
    required this.createdAt,
  });

  factory DeliveryPending({
    required int recipientMessengerUserId,
    required String matrixEventId,
    required int roomId,
    required List<String> payloadsJson,
    required DateTime createdAt,
  }) = _DeliveryPendingImpl;

  factory DeliveryPending.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeliveryPending(
      recipientMessengerUserId:
          jsonSerialization['recipientMessengerUserId'] as int,
      matrixEventId: jsonSerialization['matrixEventId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      payloadsJson: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['payloadsJson'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Кому доставляем.
  int recipientMessengerUserId;

  /// Событие Matrix — ключ идемпотентности: повтор sync-а не должен
  /// порождать второй пуш.
  String matrixEventId;

  /// Комната — для диагностики и логов.
  int roomId;

  /// Готовые пуш-полезные нагрузки (по одной на устройство), собранные
  /// в момент отправки: все фильтры (заглушка, архив, блокировка, подбор
  /// устройств и продуктовых кредов) уже применены. Отложенной проверке
  /// остаётся только решить «слать или нет» — пересчитывать маршрут
  /// через три секунды незачем, а состав устройств за это время не
  /// меняется.
  List<String> payloadsJson;

  /// Когда поставили ожидание — для диагностики опозданий.
  DateTime createdAt;

  /// Returns a shallow copy of this [DeliveryPending]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliveryPending copyWith({
    int? recipientMessengerUserId,
    String? matrixEventId,
    int? roomId,
    List<String>? payloadsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliveryPending',
      'recipientMessengerUserId': recipientMessengerUserId,
      'matrixEventId': matrixEventId,
      'roomId': roomId,
      'payloadsJson': payloadsJson.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeliveryPendingImpl extends DeliveryPending {
  _DeliveryPendingImpl({
    required int recipientMessengerUserId,
    required String matrixEventId,
    required int roomId,
    required List<String> payloadsJson,
    required DateTime createdAt,
  }) : super._(
         recipientMessengerUserId: recipientMessengerUserId,
         matrixEventId: matrixEventId,
         roomId: roomId,
         payloadsJson: payloadsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DeliveryPending]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliveryPending copyWith({
    int? recipientMessengerUserId,
    String? matrixEventId,
    int? roomId,
    List<String>? payloadsJson,
    DateTime? createdAt,
  }) {
    return DeliveryPending(
      recipientMessengerUserId:
          recipientMessengerUserId ?? this.recipientMessengerUserId,
      matrixEventId: matrixEventId ?? this.matrixEventId,
      roomId: roomId ?? this.roomId,
      payloadsJson: payloadsJson ?? this.payloadsJson.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
