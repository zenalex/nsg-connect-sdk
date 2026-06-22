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

/// MessageIndex — серверный поисковый индекс сообщений (B17 phase 3).
///
/// **Зачем**: Synapse postgres работает в C-locale, поэтому его FTS
/// case-fold-ит только ASCII, не кириллицу → кросс-room content-поиск
/// («поиск по чатам») промахивается мимо сообщений, чей регистр отличается
/// от запроса. Наша nsg_connect БД Unicode-aware (ILIKE корректно
/// case-fold-ит кириллицу), поэтому индексируем сообщения у себя и ищем
/// `body ILIKE '%term%'` здесь.
///
/// Заполняется best-effort на двух hook-ах: outbound
/// (`MatrixMessageService.sendMessage`) и inbound
/// (`MatrixSyncDispatcher._publishEvents` → `_convertToMessage`). Dedup
/// по `matrixEventId` (UPSERT) — одно событие приходит N sync-worker-ам
/// (по worker-у на каждого нашего юзера в комнате), индексируем ОДИН раз.
/// Redaction (`m.room.redaction`) → `deleted=true` (`markDeleted`).
abstract class MessageIndex implements _i1.SerializableModel {
  MessageIndex._({
    this.id,
    required this.tenantId,
    required this.roomId,
    required this.matrixEventId,
    this.senderMessengerUserId,
    required this.body,
    required this.createdAt,
    bool? deleted,
  }) : deleted = deleted ?? false;

  factory MessageIndex({
    int? id,
    required int tenantId,
    required int roomId,
    required String matrixEventId,
    int? senderMessengerUserId,
    required String body,
    required DateTime createdAt,
    bool? deleted,
  }) = _MessageIndexImpl;

  factory MessageIndex.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessageIndex(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      roomId: jsonSerialization['roomId'] as int,
      matrixEventId: jsonSerialization['matrixEventId'] as String,
      senderMessengerUserId: jsonSerialization['senderMessengerUserId'] as int?,
      body: jsonSerialization['body'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deleted: jsonSerialization['deleted'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['deleted']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// Наш `Room.id` (не matrix room id).
  int roomId;

  String matrixEventId;

  /// `null` для system-сообщений (sender без MessengerUser).
  int? senderMessengerUserId;

  /// Оригинальный body сообщения (не trimmed). Поиск идёт по нему через
  /// ILIKE — Unicode case-folding-ом БД.
  String body;

  /// origin_server_ts / время отправки. Сортировка результатов поиска
  /// `createdAt DESC` (newest first).
  DateTime createdAt;

  /// Tombstone для redaction-ов: поиск исключает `deleted=true`.
  bool deleted;

  /// Returns a shallow copy of this [MessageIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessageIndex copyWith({
    int? id,
    int? tenantId,
    int? roomId,
    String? matrixEventId,
    int? senderMessengerUserId,
    String? body,
    DateTime? createdAt,
    bool? deleted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessageIndex',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      'matrixEventId': matrixEventId,
      if (senderMessengerUserId != null)
        'senderMessengerUserId': senderMessengerUserId,
      'body': body,
      'createdAt': createdAt.toJson(),
      'deleted': deleted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageIndexImpl extends MessageIndex {
  _MessageIndexImpl({
    int? id,
    required int tenantId,
    required int roomId,
    required String matrixEventId,
    int? senderMessengerUserId,
    required String body,
    required DateTime createdAt,
    bool? deleted,
  }) : super._(
         id: id,
         tenantId: tenantId,
         roomId: roomId,
         matrixEventId: matrixEventId,
         senderMessengerUserId: senderMessengerUserId,
         body: body,
         createdAt: createdAt,
         deleted: deleted,
       );

  /// Returns a shallow copy of this [MessageIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessageIndex copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? roomId,
    String? matrixEventId,
    Object? senderMessengerUserId = _Undefined,
    String? body,
    DateTime? createdAt,
    bool? deleted,
  }) {
    return MessageIndex(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      matrixEventId: matrixEventId ?? this.matrixEventId,
      senderMessengerUserId: senderMessengerUserId is int?
          ? senderMessengerUserId
          : this.senderMessengerUserId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
    );
  }
}
