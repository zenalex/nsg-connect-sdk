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

/// IncomingWebhook — входящий webhook для автопоста статусов процессов в
/// комнату (TASK58 фаза 2 — «inbound webhooks» из BOT_QUICKSTART «Отложено»).
/// Внешний процесс (CI / мониторинг / бэкенд) шлёт `POST /hooks/<token>` →
/// сообщение появляется в комнате от имени служебного бота-подпорки.
///
/// Простота (модель Slack, в отличие от outbound TASK35): секрет живёт в
/// URL, HMAC-подпись от отправителя НЕ требуется. Компенсация — узкий scope:
/// привязка к ОДНОЙ комнате (`roomId`), только запись (постинг), лёгкая
/// ротация. `token` в БД не хранится — только его SHA-256 хеш (`tokenHash`);
/// открытый токен показывается админу один раз при создании/ротации.
///
/// Подпирается ботом (`botMessengerUserId`, capability `send_messages`) —
/// переиспользует messenger send-path (идентичность, история, rate-limit).
/// Ротация токена НЕ пересоздаёт бота (имя отправителя/история постов не
/// рвутся) — меняется только `tokenHash`.
abstract class IncomingWebhook implements _i1.SerializableModel {
  IncomingWebhook._({
    this.id,
    required this.tenantId,
    required this.roomId,
    required this.botMessengerUserId,
    required this.name,
    required this.tokenHash,
    String? defaultFormat,
    bool? enabled,
    required this.createdBy,
    required this.createdAt,
    this.lastPostedAt,
    int? postCount,
  }) : defaultFormat = defaultFormat ?? 'text',
       enabled = enabled ?? true,
       postCount = postCount ?? 0;

  factory IncomingWebhook({
    int? id,
    required int tenantId,
    required int roomId,
    required int botMessengerUserId,
    required String name,
    required String tokenHash,
    String? defaultFormat,
    bool? enabled,
    required int createdBy,
    required DateTime createdAt,
    DateTime? lastPostedAt,
    int? postCount,
  }) = _IncomingWebhookImpl;

  factory IncomingWebhook.fromJson(Map<String, dynamic> jsonSerialization) {
    return IncomingWebhook(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      roomId: jsonSerialization['roomId'] as int,
      botMessengerUserId: jsonSerialization['botMessengerUserId'] as int,
      name: jsonSerialization['name'] as String,
      tokenHash: jsonSerialization['tokenHash'] as String,
      defaultFormat: jsonSerialization['defaultFormat'] as String?,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      createdBy: jsonSerialization['createdBy'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastPostedAt: jsonSerialization['lastPostedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastPostedAt'],
            ),
      postCount: jsonSerialization['postCount'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade-delete: webhook-и удаляются вместе с tenant-ом.
  int tenantId;

  /// Комната-цель. Cascade: webhook удаляется вместе с комнатой.
  int roomId;

  /// messengerUserId служебного бота-подпорки (создаётся при create).
  /// Через него идёт MatrixMessageService.sendMessage.
  int botMessengerUserId;

  /// Отображаемое имя = имя отправителя в ленте, напр. "CI · Деплой".
  String name;

  /// SHA-256(hex) публичного токена. Резолв входящего POST:
  /// sha256(token) == tokenHash. Сам токен в БД не хранится.
  String tokenHash;

  /// Формат по умолчанию при неоднозначном теле: text | markdown | status-card.
  String defaultFormat;

  bool enabled;

  /// MUID админа-создателя (аудит: кто завёл интеграцию).
  int createdBy;

  DateTime createdAt;

  DateTime? lastPostedAt;

  int postCount;

  /// Returns a shallow copy of this [IncomingWebhook]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IncomingWebhook copyWith({
    int? id,
    int? tenantId,
    int? roomId,
    int? botMessengerUserId,
    String? name,
    String? tokenHash,
    String? defaultFormat,
    bool? enabled,
    int? createdBy,
    DateTime? createdAt,
    DateTime? lastPostedAt,
    int? postCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IncomingWebhook',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      'botMessengerUserId': botMessengerUserId,
      'name': name,
      'tokenHash': tokenHash,
      'defaultFormat': defaultFormat,
      'enabled': enabled,
      'createdBy': createdBy,
      'createdAt': createdAt.toJson(),
      if (lastPostedAt != null) 'lastPostedAt': lastPostedAt?.toJson(),
      'postCount': postCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IncomingWebhookImpl extends IncomingWebhook {
  _IncomingWebhookImpl({
    int? id,
    required int tenantId,
    required int roomId,
    required int botMessengerUserId,
    required String name,
    required String tokenHash,
    String? defaultFormat,
    bool? enabled,
    required int createdBy,
    required DateTime createdAt,
    DateTime? lastPostedAt,
    int? postCount,
  }) : super._(
         id: id,
         tenantId: tenantId,
         roomId: roomId,
         botMessengerUserId: botMessengerUserId,
         name: name,
         tokenHash: tokenHash,
         defaultFormat: defaultFormat,
         enabled: enabled,
         createdBy: createdBy,
         createdAt: createdAt,
         lastPostedAt: lastPostedAt,
         postCount: postCount,
       );

  /// Returns a shallow copy of this [IncomingWebhook]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IncomingWebhook copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? roomId,
    int? botMessengerUserId,
    String? name,
    String? tokenHash,
    String? defaultFormat,
    bool? enabled,
    int? createdBy,
    DateTime? createdAt,
    Object? lastPostedAt = _Undefined,
    int? postCount,
  }) {
    return IncomingWebhook(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      botMessengerUserId: botMessengerUserId ?? this.botMessengerUserId,
      name: name ?? this.name,
      tokenHash: tokenHash ?? this.tokenHash,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      enabled: enabled ?? this.enabled,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastPostedAt: lastPostedAt is DateTime?
          ? lastPostedAt
          : this.lastPostedAt,
      postCount: postCount ?? this.postCount,
    );
  }
}
