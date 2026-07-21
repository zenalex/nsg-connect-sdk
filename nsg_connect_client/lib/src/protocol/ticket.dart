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

/// **TASK57 фаза 1**: тикет-обращение поверх support-комнаты. Один тикет на
/// support-комнату (unique roomId). `status`: `open` / `closed` (грубый цикл).
/// `stage` (issue #19): гранулярный статус жизненного цикла обращения —
/// `new` / `in_progress` / `accepted` / `rejected`, вычисляется из сигналов
/// GitHub (state_reason, labels, assignee; см. `TicketService`). `kind`:
/// `support` / `bug` / `idea`. Привязка к GitHub issue ОПЦИОНАЛЬНА
/// (`externalTaskUrl` == null, если обращение живёт только в чате, без задачи).
/// `resolution` заполняется при закрытии (из GitHub state_reason, фаза 2).
abstract class Ticket implements _i1.SerializableModel {
  Ticket._({
    this.id,
    required this.tenantId,
    required this.roomId,
    this.productId,
    this.createdByMessengerUserId,
    required this.kind,
    required this.status,
    this.stage,
    this.externalTaskUrl,
    this.externalTaskKey,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  factory Ticket({
    int? id,
    required int tenantId,
    required int roomId,
    int? productId,
    int? createdByMessengerUserId,
    required String kind,
    required String status,
    String? stage,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? resolution,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? closedAt,
  }) = _TicketImpl;

  factory Ticket.fromJson(Map<String, dynamic> jsonSerialization) {
    return Ticket(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      roomId: jsonSerialization['roomId'] as int,
      productId: jsonSerialization['productId'] as int?,
      createdByMessengerUserId:
          jsonSerialization['createdByMessengerUserId'] as int?,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      stage: jsonSerialization['stage'] as String?,
      externalTaskUrl: jsonSerialization['externalTaskUrl'] as String?,
      externalTaskKey: jsonSerialization['externalTaskKey'] as String?,
      resolution: jsonSerialization['resolution'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// Support-комната обращения (per-user, TASK57-фикс). Cascade-delete.
  int roomId;

  int? productId;

  int? createdByMessengerUserId;

  String kind;

  /// Грубый цикл: `open` / `closed` (совместимость с фазой 1).
  String status;

  /// **issue #19**: гранулярный статус — `new` / `in_progress` / `accepted` /
  /// `rejected`. null → тикет заведён до фичи (старые строки); UI/сервер
  /// выводят разумный статус из `status`+`resolution` (`effectiveStage`).
  String? stage;

  /// GitHub issue (если заведён). null → обращение без внешней задачи.
  String? externalTaskUrl;

  String? externalTaskKey;

  /// Итог при закрытии (RU): «выполнено» / «не будем делать» и т.п.
  String? resolution;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? closedAt;

  /// Returns a shallow copy of this [Ticket]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Ticket copyWith({
    int? id,
    int? tenantId,
    int? roomId,
    int? productId,
    int? createdByMessengerUserId,
    String? kind,
    String? status,
    String? stage,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? resolution,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Ticket',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      if (productId != null) 'productId': productId,
      if (createdByMessengerUserId != null)
        'createdByMessengerUserId': createdByMessengerUserId,
      'kind': kind,
      'status': status,
      if (stage != null) 'stage': stage,
      if (externalTaskUrl != null) 'externalTaskUrl': externalTaskUrl,
      if (externalTaskKey != null) 'externalTaskKey': externalTaskKey,
      if (resolution != null) 'resolution': resolution,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketImpl extends Ticket {
  _TicketImpl({
    int? id,
    required int tenantId,
    required int roomId,
    int? productId,
    int? createdByMessengerUserId,
    required String kind,
    required String status,
    String? stage,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? resolution,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? closedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         roomId: roomId,
         productId: productId,
         createdByMessengerUserId: createdByMessengerUserId,
         kind: kind,
         status: status,
         stage: stage,
         externalTaskUrl: externalTaskUrl,
         externalTaskKey: externalTaskKey,
         resolution: resolution,
         createdAt: createdAt,
         updatedAt: updatedAt,
         closedAt: closedAt,
       );

  /// Returns a shallow copy of this [Ticket]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Ticket copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? roomId,
    Object? productId = _Undefined,
    Object? createdByMessengerUserId = _Undefined,
    String? kind,
    String? status,
    Object? stage = _Undefined,
    Object? externalTaskUrl = _Undefined,
    Object? externalTaskKey = _Undefined,
    Object? resolution = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? closedAt = _Undefined,
  }) {
    return Ticket(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      productId: productId is int? ? productId : this.productId,
      createdByMessengerUserId: createdByMessengerUserId is int?
          ? createdByMessengerUserId
          : this.createdByMessengerUserId,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      stage: stage is String? ? stage : this.stage,
      externalTaskUrl: externalTaskUrl is String?
          ? externalTaskUrl
          : this.externalTaskUrl,
      externalTaskKey: externalTaskKey is String?
          ? externalTaskKey
          : this.externalTaskKey,
      resolution: resolution is String? ? resolution : this.resolution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt is DateTime? ? closedAt : this.closedAt,
    );
  }
}
