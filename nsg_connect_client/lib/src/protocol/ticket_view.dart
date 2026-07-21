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

/// **TASK57 фаза 1**: DTO для `listMyTickets` RPC. Транзиентный (без `table:`),
/// собирается в `TicketService` из `Ticket` + последнего `TicketEvent` + имени
/// комнаты. `title` — человекочитаемое имя обращения (имя support-комнаты).
abstract class TicketView implements _i1.SerializableModel {
  TicketView._({
    required this.id,
    required this.kind,
    required this.status,
    required this.stage,
    required this.roomId,
    this.externalTaskUrl,
    this.externalTaskKey,
    this.resolution,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastEventPreview,
    this.lastEventAt,
  });

  factory TicketView({
    required int id,
    required String kind,
    required String status,
    required String stage,
    required int roomId,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? resolution,
    String? title,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? lastEventPreview,
    DateTime? lastEventAt,
  }) = _TicketViewImpl;

  factory TicketView.fromJson(Map<String, dynamic> jsonSerialization) {
    return TicketView(
      id: jsonSerialization['id'] as int,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      stage: jsonSerialization['stage'] as String,
      roomId: jsonSerialization['roomId'] as int,
      externalTaskUrl: jsonSerialization['externalTaskUrl'] as String?,
      externalTaskKey: jsonSerialization['externalTaskKey'] as String?,
      resolution: jsonSerialization['resolution'] as String?,
      title: jsonSerialization['title'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      lastEventPreview: jsonSerialization['lastEventPreview'] as String?,
      lastEventAt: jsonSerialization['lastEventAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEventAt'],
            ),
    );
  }

  int id;

  String kind;

  String status;

  /// **issue #19**: гранулярный статус для бейджа «Мои обращения» —
  /// `new` / `in_progress` / `accepted` / `rejected`. Всегда заполнен сервером
  /// (для старых тикетов выводится из `status`+`resolution`).
  String stage;

  int roomId;

  String? externalTaskUrl;

  String? externalTaskKey;

  String? resolution;

  String? title;

  DateTime createdAt;

  DateTime updatedAt;

  String? lastEventPreview;

  DateTime? lastEventAt;

  /// Returns a shallow copy of this [TicketView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TicketView copyWith({
    int? id,
    String? kind,
    String? status,
    String? stage,
    int? roomId,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? resolution,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastEventPreview,
    DateTime? lastEventAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TicketView',
      'id': id,
      'kind': kind,
      'status': status,
      'stage': stage,
      'roomId': roomId,
      if (externalTaskUrl != null) 'externalTaskUrl': externalTaskUrl,
      if (externalTaskKey != null) 'externalTaskKey': externalTaskKey,
      if (resolution != null) 'resolution': resolution,
      if (title != null) 'title': title,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (lastEventPreview != null) 'lastEventPreview': lastEventPreview,
      if (lastEventAt != null) 'lastEventAt': lastEventAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketViewImpl extends TicketView {
  _TicketViewImpl({
    required int id,
    required String kind,
    required String status,
    required String stage,
    required int roomId,
    String? externalTaskUrl,
    String? externalTaskKey,
    String? resolution,
    String? title,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? lastEventPreview,
    DateTime? lastEventAt,
  }) : super._(
         id: id,
         kind: kind,
         status: status,
         stage: stage,
         roomId: roomId,
         externalTaskUrl: externalTaskUrl,
         externalTaskKey: externalTaskKey,
         resolution: resolution,
         title: title,
         createdAt: createdAt,
         updatedAt: updatedAt,
         lastEventPreview: lastEventPreview,
         lastEventAt: lastEventAt,
       );

  /// Returns a shallow copy of this [TicketView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TicketView copyWith({
    int? id,
    String? kind,
    String? status,
    String? stage,
    int? roomId,
    Object? externalTaskUrl = _Undefined,
    Object? externalTaskKey = _Undefined,
    Object? resolution = _Undefined,
    Object? title = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastEventPreview = _Undefined,
    Object? lastEventAt = _Undefined,
  }) {
    return TicketView(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      roomId: roomId ?? this.roomId,
      externalTaskUrl: externalTaskUrl is String?
          ? externalTaskUrl
          : this.externalTaskUrl,
      externalTaskKey: externalTaskKey is String?
          ? externalTaskKey
          : this.externalTaskKey,
      resolution: resolution is String? ? resolution : this.resolution,
      title: title is String? ? title : this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastEventPreview: lastEventPreview is String?
          ? lastEventPreview
          : this.lastEventPreview,
      lastEventAt: lastEventAt is DateTime? ? lastEventAt : this.lastEventAt,
    );
  }
}
