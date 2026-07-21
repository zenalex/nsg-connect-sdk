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
import 'enums/room_type.dart' as _i2;

/// Lightweight DTO для `listRooms` — оптимизирован под рендер списка
/// чатов в SDK без отдельного RPC за каждой комнатой. См. TASK13.
///
/// Не table — это transient DTO, собирается в RoomService из Room +
/// RoomMembership с join-ом.
abstract class RoomSummary implements _i1.SerializableModel {
  RoomSummary._({
    required this.id,
    this.name,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
    required this.archived,
    required this.muted,
    this.productId,
    this.productEntityType,
    this.productEntityId,
    required this.roomType,
    this.directPeerMessengerUserId,
    this.supportRequesterName,
    this.productKey,
    this.productName,
    this.supportAwaitingSince,
    this.dismissedUntilMessage,
    this.autoCleanupTtlSeconds,
  });

  factory RoomSummary({
    required int id,
    String? name,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    required int unreadCount,
    required bool archived,
    required bool muted,
    int? productId,
    String? productEntityType,
    String? productEntityId,
    required _i2.RoomType roomType,
    int? directPeerMessengerUserId,
    String? supportRequesterName,
    String? productKey,
    String? productName,
    DateTime? supportAwaitingSince,
    bool? dismissedUntilMessage,
    int? autoCleanupTtlSeconds,
  }) = _RoomSummaryImpl;

  factory RoomSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomSummary(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      lastMessagePreview: jsonSerialization['lastMessagePreview'] as String?,
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      unreadCount: jsonSerialization['unreadCount'] as int,
      archived: _i1.BoolJsonExtension.fromJson(jsonSerialization['archived']),
      muted: _i1.BoolJsonExtension.fromJson(jsonSerialization['muted']),
      productId: jsonSerialization['productId'] as int?,
      productEntityType: jsonSerialization['productEntityType'] as String?,
      productEntityId: jsonSerialization['productEntityId'] as String?,
      roomType: _i2.RoomType.fromJson(
        (jsonSerialization['roomType'] as String),
      ),
      directPeerMessengerUserId:
          jsonSerialization['directPeerMessengerUserId'] as int?,
      supportRequesterName:
          jsonSerialization['supportRequesterName'] as String?,
      productKey: jsonSerialization['productKey'] as String?,
      productName: jsonSerialization['productName'] as String?,
      supportAwaitingSince: jsonSerialization['supportAwaitingSince'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['supportAwaitingSince'],
            ),
      dismissedUntilMessage: jsonSerialization['dismissedUntilMessage'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['dismissedUntilMessage'],
            ),
      autoCleanupTtlSeconds: jsonSerialization['autoCleanupTtlSeconds'] as int?,
    );
  }

  int id;

  /// Computed name: для direct — display peer-а; для group/product —
  /// Room.name; null если ничего не задано (SDK покажет fallback).
  String? name;

  /// Computed avatarUrl: для direct — peer.avatarUrl; для group —
  /// общая аватарка комнаты (TASK19 / null на MVP).
  String? avatarUrl;

  /// Превью последнего сообщения, обрезано до 120 символов
  /// в RoomLastMessageWatcher. Для не-text типов (m.image / m.file) —
  /// placeholder типа `📷 image` / `📎 filename`.
  String? lastMessagePreview;

  DateTime? lastMessageAt;

  /// Per-user unread (TASK18). На TASK13 MVP всегда 0 — поле в DTO
  /// есть для стабильности контракта.
  int unreadCount;

  /// Per-user архив (RoomMembership.archived).
  bool archived;

  /// Per-user mute (RoomMembership.mutedUntil > now).
  bool muted;

  int? productId;

  /// Привязка к product entity ('team' / 'support_ticket' / etc).
  String? productEntityType;

  String? productEntityId;

  _i2.RoomType roomType;

  /// **TASK63**: id собеседника для direct-комнат (null для остальных
  /// типов). Клиенту нужен для входа в «профиль контакта» (alias /
  /// заметка / метки) прямо из списка чатов или шапки диалога.
  int? directPeerMessengerUserId;

  /// **TASK75 — support-инбокс.** Ниже поля значимы ТОЛЬКО для
  /// support-комнат (roomType == support); у прочих типов остаются
  /// null / default. Server резолвит их в `RoomService._toSummary`,
  /// чтобы оператор не парсил строку «Поддержка — <ФИО>».
  ///
  /// ФИО заявителя (создателя обращения — owner-membership.displayName).
  /// Primary-строка кастомного рендера support-строки. null, если owner
  /// не резолвится — клиент откатывается на `name`.
  String? supportRequesterName;

  /// `Product.externalKey` продукта комнаты (резолв productId→Product).
  /// Fallback-подпись проекта в support-строке.
  String? productKey;

  /// `Product.displayName` продукта комнаты. Вторичная (мелкая) подпись
  /// проекта в support-строке.
  String? productName;

  /// `Room.awaitingOperatorSince` — момент, с которого support-чат ждёт
  /// ответа человека-оператора (null = никто не ждёт / оператор ответил).
  /// Клиент рисует «светофор»-маркер по давности ожидания (SLA).
  DateTime? supportAwaitingSince;

  /// **TASK75** per-operator «закрыть до ответа»: viewer скрыл этот
  /// support-чат у себя до следующего сообщения заявителя
  /// (`RoomMembership.dismissedUntilMessage`). Клиент прячет dismissed
  /// из support-списка; авто-сброс на сервере при сообщении заявителя.
  /// Nullable (не required в конструкторе) — старый сервер/клиент-скью
  /// трактует null как false; сервер всегда проставляет реальное значение.
  bool? dismissedUntilMessage;

  /// **TASK68**: TTL автоочистки в секундах (`Room.autoCleanupTtlSeconds`).
  /// null = выключено. В списке чатов SDK рисует по нему бейдж «⏱ неделя»
  /// на строках self-чатов, не дёргая getRoom за каждой комнатой.
  int? autoCleanupTtlSeconds;

  /// Returns a shallow copy of this [RoomSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomSummary copyWith({
    int? id,
    String? name,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? archived,
    bool? muted,
    int? productId,
    String? productEntityType,
    String? productEntityId,
    _i2.RoomType? roomType,
    int? directPeerMessengerUserId,
    String? supportRequesterName,
    String? productKey,
    String? productName,
    DateTime? supportAwaitingSince,
    bool? dismissedUntilMessage,
    int? autoCleanupTtlSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomSummary',
      'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      'unreadCount': unreadCount,
      'archived': archived,
      'muted': muted,
      if (productId != null) 'productId': productId,
      if (productEntityType != null) 'productEntityType': productEntityType,
      if (productEntityId != null) 'productEntityId': productEntityId,
      'roomType': roomType.toJson(),
      if (directPeerMessengerUserId != null)
        'directPeerMessengerUserId': directPeerMessengerUserId,
      if (supportRequesterName != null)
        'supportRequesterName': supportRequesterName,
      if (productKey != null) 'productKey': productKey,
      if (productName != null) 'productName': productName,
      if (supportAwaitingSince != null)
        'supportAwaitingSince': supportAwaitingSince?.toJson(),
      if (dismissedUntilMessage != null)
        'dismissedUntilMessage': dismissedUntilMessage,
      if (autoCleanupTtlSeconds != null)
        'autoCleanupTtlSeconds': autoCleanupTtlSeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomSummaryImpl extends RoomSummary {
  _RoomSummaryImpl({
    required int id,
    String? name,
    String? avatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    required int unreadCount,
    required bool archived,
    required bool muted,
    int? productId,
    String? productEntityType,
    String? productEntityId,
    required _i2.RoomType roomType,
    int? directPeerMessengerUserId,
    String? supportRequesterName,
    String? productKey,
    String? productName,
    DateTime? supportAwaitingSince,
    bool? dismissedUntilMessage,
    int? autoCleanupTtlSeconds,
  }) : super._(
         id: id,
         name: name,
         avatarUrl: avatarUrl,
         lastMessagePreview: lastMessagePreview,
         lastMessageAt: lastMessageAt,
         unreadCount: unreadCount,
         archived: archived,
         muted: muted,
         productId: productId,
         productEntityType: productEntityType,
         productEntityId: productEntityId,
         roomType: roomType,
         directPeerMessengerUserId: directPeerMessengerUserId,
         supportRequesterName: supportRequesterName,
         productKey: productKey,
         productName: productName,
         supportAwaitingSince: supportAwaitingSince,
         dismissedUntilMessage: dismissedUntilMessage,
         autoCleanupTtlSeconds: autoCleanupTtlSeconds,
       );

  /// Returns a shallow copy of this [RoomSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomSummary copyWith({
    int? id,
    Object? name = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? lastMessagePreview = _Undefined,
    Object? lastMessageAt = _Undefined,
    int? unreadCount,
    bool? archived,
    bool? muted,
    Object? productId = _Undefined,
    Object? productEntityType = _Undefined,
    Object? productEntityId = _Undefined,
    _i2.RoomType? roomType,
    Object? directPeerMessengerUserId = _Undefined,
    Object? supportRequesterName = _Undefined,
    Object? productKey = _Undefined,
    Object? productName = _Undefined,
    Object? supportAwaitingSince = _Undefined,
    Object? dismissedUntilMessage = _Undefined,
    Object? autoCleanupTtlSeconds = _Undefined,
  }) {
    return RoomSummary(
      id: id ?? this.id,
      name: name is String? ? name : this.name,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      lastMessagePreview: lastMessagePreview is String?
          ? lastMessagePreview
          : this.lastMessagePreview,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      archived: archived ?? this.archived,
      muted: muted ?? this.muted,
      productId: productId is int? ? productId : this.productId,
      productEntityType: productEntityType is String?
          ? productEntityType
          : this.productEntityType,
      productEntityId: productEntityId is String?
          ? productEntityId
          : this.productEntityId,
      roomType: roomType ?? this.roomType,
      directPeerMessengerUserId: directPeerMessengerUserId is int?
          ? directPeerMessengerUserId
          : this.directPeerMessengerUserId,
      supportRequesterName: supportRequesterName is String?
          ? supportRequesterName
          : this.supportRequesterName,
      productKey: productKey is String? ? productKey : this.productKey,
      productName: productName is String? ? productName : this.productName,
      supportAwaitingSince: supportAwaitingSince is DateTime?
          ? supportAwaitingSince
          : this.supportAwaitingSince,
      dismissedUntilMessage: dismissedUntilMessage is bool?
          ? dismissedUntilMessage
          : this.dismissedUntilMessage,
      autoCleanupTtlSeconds: autoCleanupTtlSeconds is int?
          ? autoCleanupTtlSeconds
          : this.autoCleanupTtlSeconds,
    );
  }
}
