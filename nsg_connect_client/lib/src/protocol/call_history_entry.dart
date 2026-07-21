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
import 'enums/call_status.dart' as _i2;

/// **TASK46 (история звонков)**: запись одного 1:1 голосового звонка.
/// Пишется server-side из `MessengerEndpoint.sendCallEvent` по `callId`
/// (invite создаёт запись, answer/hangup/reject её обновляют — см.
/// `CallHistoryService`). Обе стороны видят звонок в своей истории:
/// `listCallHistory` фильтрует по `callerMessengerUserId | callee...`.
///
/// Направление и «пропущенный» выводятся per-viewer на клиенте
/// (viewer==caller → исходящий; status=missed && viewer==callee →
/// пропущенный). Имя собеседника клиент резолвит по `roomId` (direct-
/// комната = имя собеседника) — денормализованное имя тут не храним,
/// чтобы не устаревало.
abstract class CallHistoryEntry implements _i1.SerializableModel {
  CallHistoryEntry._({
    this.id,
    required this.callId,
    required this.roomId,
    this.productId,
    required this.callerMessengerUserId,
    required this.calleeMessengerUserId,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory CallHistoryEntry({
    int? id,
    required String callId,
    required int roomId,
    int? productId,
    required int callerMessengerUserId,
    required int calleeMessengerUserId,
    required _i2.CallStatus status,
    required DateTime startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) = _CallHistoryEntryImpl;

  factory CallHistoryEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return CallHistoryEntry(
      id: jsonSerialization['id'] as int?,
      callId: jsonSerialization['callId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      productId: jsonSerialization['productId'] as int?,
      callerMessengerUserId: jsonSerialization['callerMessengerUserId'] as int,
      calleeMessengerUserId: jsonSerialization['calleeMessengerUserId'] as int,
      status: _i2.CallStatus.fromJson((jsonSerialization['status'] as String)),
      startedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      answeredAt: jsonSerialization['answeredAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['answeredAt']),
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      durationSeconds: jsonSerialization['durationSeconds'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Коррелятор m.call-событий (тот же, что в сигналинге). Unique —
  /// одна запись на звонок, события лишь обновляют её.
  String callId;

  /// Direct 1:1 комната звонка. Нужна для перезвона из истории
  /// (`startCall(roomId)`) и для резолва имени собеседника на клиенте.
  int roomId;

  /// Продукт (embedded SDK) или null (standalone Chatista).
  int? productId;

  /// Кто инициировал звонок (session-user на invite).
  int callerMessengerUserId;

  /// Второй участник 1:1 (единственный не-caller в `RoomMembership`).
  int calleeMessengerUserId;

  _i2.CallStatus status;

  /// Время invite — начало звонка и ключ сортировки истории.
  DateTime startedAt;

  /// Когда пришёл answer (звонок соединился). null если не отвечен.
  DateTime? answeredAt;

  /// Время завершения (hangup/reject). null пока ringing.
  DateTime? endedAt;

  /// Длительность разговора (endedAt−answeredAt в секундах), если
  /// звонок состоялся. null для missed/declined.
  int? durationSeconds;

  /// Returns a shallow copy of this [CallHistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CallHistoryEntry copyWith({
    int? id,
    String? callId,
    int? roomId,
    int? productId,
    int? callerMessengerUserId,
    int? calleeMessengerUserId,
    _i2.CallStatus? status,
    DateTime? startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CallHistoryEntry',
      if (id != null) 'id': id,
      'callId': callId,
      'roomId': roomId,
      if (productId != null) 'productId': productId,
      'callerMessengerUserId': callerMessengerUserId,
      'calleeMessengerUserId': calleeMessengerUserId,
      'status': status.toJson(),
      'startedAt': startedAt.toJson(),
      if (answeredAt != null) 'answeredAt': answeredAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CallHistoryEntryImpl extends CallHistoryEntry {
  _CallHistoryEntryImpl({
    int? id,
    required String callId,
    required int roomId,
    int? productId,
    required int callerMessengerUserId,
    required int calleeMessengerUserId,
    required _i2.CallStatus status,
    required DateTime startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) : super._(
         id: id,
         callId: callId,
         roomId: roomId,
         productId: productId,
         callerMessengerUserId: callerMessengerUserId,
         calleeMessengerUserId: calleeMessengerUserId,
         status: status,
         startedAt: startedAt,
         answeredAt: answeredAt,
         endedAt: endedAt,
         durationSeconds: durationSeconds,
       );

  /// Returns a shallow copy of this [CallHistoryEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CallHistoryEntry copyWith({
    Object? id = _Undefined,
    String? callId,
    int? roomId,
    Object? productId = _Undefined,
    int? callerMessengerUserId,
    int? calleeMessengerUserId,
    _i2.CallStatus? status,
    DateTime? startedAt,
    Object? answeredAt = _Undefined,
    Object? endedAt = _Undefined,
    Object? durationSeconds = _Undefined,
  }) {
    return CallHistoryEntry(
      id: id is int? ? id : this.id,
      callId: callId ?? this.callId,
      roomId: roomId ?? this.roomId,
      productId: productId is int? ? productId : this.productId,
      callerMessengerUserId:
          callerMessengerUserId ?? this.callerMessengerUserId,
      calleeMessengerUserId:
          calleeMessengerUserId ?? this.calleeMessengerUserId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      answeredAt: answeredAt is DateTime? ? answeredAt : this.answeredAt,
      endedAt: endedAt is DateTime? ? endedAt : this.endedAt,
      durationSeconds: durationSeconds is int?
          ? durationSeconds
          : this.durationSeconds,
    );
  }
}
