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

/// Bot — программный клиент мессенджера (TASK36 Bots MVP). Постит в чаты
/// через long-lived bearer-токен с capability-гейтингом. Каждый бот —
/// это обычный `MessengerUser` (matrixUserId + encrypted Matrix-токен),
/// которому выдан session-токен с far-future expiry в
/// `MessengerSessionToken` — поэтому существующий
/// `MessengerSessionAuthHandler` резолвит bot-токен в bot-а
/// messengerUserId без изменений в auth-слое.
///
/// Enforcement: action-сайты (`sendMessage` / room-management) зовут
/// `BotService.requireCapability` — для людей (botFor==null) no-op, для
/// бота — проверка `enabled` + наличие capability в CSV. Чтение
/// (userEventStream) всегда разрешено для enabled-ботов.
abstract class Bot implements _i1.SerializableModel {
  Bot._({
    this.id,
    required this.messengerUserId,
    required this.tenantId,
    this.productId,
    required this.name,
    required this.ownerEmail,
    required this.accessToken,
    required this.capabilities,
    bool? enabled,
    bool? discoverable,
    required this.createdAt,
  }) : enabled = enabled ?? true,
       discoverable = discoverable ?? false;

  factory Bot({
    int? id,
    required int messengerUserId,
    required int tenantId,
    int? productId,
    required String name,
    required String ownerEmail,
    required String accessToken,
    required String capabilities,
    bool? enabled,
    bool? discoverable,
    required DateTime createdAt,
  }) = _BotImpl;

  factory Bot.fromJson(Map<String, dynamic> jsonSerialization) {
    return Bot(
      id: jsonSerialization['id'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int?,
      name: jsonSerialization['name'] as String,
      ownerEmail: jsonSerialization['ownerEmail'] as String,
      accessToken: jsonSerialization['accessToken'] as String,
      capabilities: jsonSerialization['capabilities'] as String,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      discoverable: jsonSerialization['discoverable'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['discoverable']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на bot-овский MessengerUser. Cascade: бот удаляется вместе со
  /// своим MessengerUser-ом (и наоборот через app-level cleanup).
  int messengerUserId;

  /// FK на Tenant. Cascade-delete: боты удаляются вместе с tenant-ом.
  int tenantId;

  /// NULL = бот не привязан к конкретному продукту (tenant-wide).
  /// SetNull: при удалении продукта бот остаётся.
  int? productId;

  /// Человекочитаемое имя (= displayName MessengerUser-а).
  String name;

  /// Email владельца/ответственного (audit; кто создал бота).
  String ownerEmail;

  /// Bearer-токен бота (`bot_` + hex). Дублируется в
  /// `MessengerSessionToken.token` для auth-резолва. Показывается
  /// админу ОДИН раз при создании.
  String accessToken;

  /// CSV capability-grant-ов: `read_only,send_messages,manage_room,
  /// webhook_target`. Low-cardinality — substring/exact match в Dart.
  String capabilities;

  /// Kill-switch. `false` → requireCapability бросает на любой
  /// gated-action (бот не может постить/управлять). Чтение остаётся.
  bool enabled;

  /// **Issue #49 (открытая платформа)**: видимость в `searchUsers`.
  /// `false` (дефолт) — бот НЕ находится поиском, добавить его в чужую
  /// комнату «с улицы» нельзя; публичность — осознанный выбор владельца.
  /// Существующие боты помечаются `true` data-скриптом
  /// `infra/scripts/backfill_bots_discoverable.sql` (не ломаем текущее
  /// поведение: их и так находили).
  bool discoverable;

  DateTime createdAt;

  /// Returns a shallow copy of this [Bot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Bot copyWith({
    int? id,
    int? messengerUserId,
    int? tenantId,
    int? productId,
    String? name,
    String? ownerEmail,
    String? accessToken,
    String? capabilities,
    bool? enabled,
    bool? discoverable,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Bot',
      if (id != null) 'id': id,
      'messengerUserId': messengerUserId,
      'tenantId': tenantId,
      if (productId != null) 'productId': productId,
      'name': name,
      'ownerEmail': ownerEmail,
      'accessToken': accessToken,
      'capabilities': capabilities,
      'enabled': enabled,
      'discoverable': discoverable,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BotImpl extends Bot {
  _BotImpl({
    int? id,
    required int messengerUserId,
    required int tenantId,
    int? productId,
    required String name,
    required String ownerEmail,
    required String accessToken,
    required String capabilities,
    bool? enabled,
    bool? discoverable,
    required DateTime createdAt,
  }) : super._(
         id: id,
         messengerUserId: messengerUserId,
         tenantId: tenantId,
         productId: productId,
         name: name,
         ownerEmail: ownerEmail,
         accessToken: accessToken,
         capabilities: capabilities,
         enabled: enabled,
         discoverable: discoverable,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Bot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Bot copyWith({
    Object? id = _Undefined,
    int? messengerUserId,
    int? tenantId,
    Object? productId = _Undefined,
    String? name,
    String? ownerEmail,
    String? accessToken,
    String? capabilities,
    bool? enabled,
    bool? discoverable,
    DateTime? createdAt,
  }) {
    return Bot(
      id: id is int? ? id : this.id,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      tenantId: tenantId ?? this.tenantId,
      productId: productId is int? ? productId : this.productId,
      name: name ?? this.name,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      accessToken: accessToken ?? this.accessToken,
      capabilities: capabilities ?? this.capabilities,
      enabled: enabled ?? this.enabled,
      discoverable: discoverable ?? this.discoverable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
