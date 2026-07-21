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

/// **TASK38**: связь между chat-сообщением и созданной из него внешней
/// задачей. Пишется после успешного `GenericWebhookTaskAdapter.createTask`.
/// Хранит external id/key/url для последующего отображения «задача
/// уже создана» и (DEFERRED) приёма апдейтов статуса задачи.
abstract class TaskLink implements _i1.SerializableModel {
  TaskLink._({
    this.id,
    required this.tenantId,
    required this.roomId,
    required this.matrixEventId,
    required this.adapterType,
    required this.externalTaskId,
    this.externalTaskKey,
    required this.externalTaskUrl,
    this.createdByMessengerUserId,
    required this.createdAt,
  });

  factory TaskLink({
    int? id,
    required int tenantId,
    required int roomId,
    required String matrixEventId,
    required String adapterType,
    required String externalTaskId,
    String? externalTaskKey,
    required String externalTaskUrl,
    int? createdByMessengerUserId,
    required DateTime createdAt,
  }) = _TaskLinkImpl;

  factory TaskLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskLink(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      roomId: jsonSerialization['roomId'] as int,
      matrixEventId: jsonSerialization['matrixEventId'] as String,
      adapterType: jsonSerialization['adapterType'] as String,
      externalTaskId: jsonSerialization['externalTaskId'] as String,
      externalTaskKey: jsonSerialization['externalTaskKey'] as String?,
      externalTaskUrl: jsonSerialization['externalTaskUrl'] as String,
      createdByMessengerUserId:
          jsonSerialization['createdByMessengerUserId'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade-delete вместе с tenant-ом.
  int tenantId;

  /// FK на Room (источник сообщения). Cascade-delete вместе с комнатой.
  int roomId;

  /// Matrix event_id исходного сообщения, из которого создана задача.
  String matrixEventId;

  /// Тип адаптера, создавшего задачу (`generic_webhook`).
  String adapterType;

  /// Идентификатор задачи во внешней системе (как вернул integration url).
  String externalTaskId;

  /// Человеко-читаемый ключ задачи, напр. "PROJ-123" (опционально).
  String? externalTaskKey;

  /// URL задачи во внешней системе (для confirmation-сообщения / UI).
  String externalTaskUrl;

  /// Кто создал задачу (MessengerUser id caller-а).
  int? createdByMessengerUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [TaskLink]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TaskLink copyWith({
    int? id,
    int? tenantId,
    int? roomId,
    String? matrixEventId,
    String? adapterType,
    String? externalTaskId,
    String? externalTaskKey,
    String? externalTaskUrl,
    int? createdByMessengerUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskLink',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      'matrixEventId': matrixEventId,
      'adapterType': adapterType,
      'externalTaskId': externalTaskId,
      if (externalTaskKey != null) 'externalTaskKey': externalTaskKey,
      'externalTaskUrl': externalTaskUrl,
      if (createdByMessengerUserId != null)
        'createdByMessengerUserId': createdByMessengerUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskLinkImpl extends TaskLink {
  _TaskLinkImpl({
    int? id,
    required int tenantId,
    required int roomId,
    required String matrixEventId,
    required String adapterType,
    required String externalTaskId,
    String? externalTaskKey,
    required String externalTaskUrl,
    int? createdByMessengerUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         roomId: roomId,
         matrixEventId: matrixEventId,
         adapterType: adapterType,
         externalTaskId: externalTaskId,
         externalTaskKey: externalTaskKey,
         externalTaskUrl: externalTaskUrl,
         createdByMessengerUserId: createdByMessengerUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaskLink]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TaskLink copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? roomId,
    String? matrixEventId,
    String? adapterType,
    String? externalTaskId,
    Object? externalTaskKey = _Undefined,
    String? externalTaskUrl,
    Object? createdByMessengerUserId = _Undefined,
    DateTime? createdAt,
  }) {
    return TaskLink(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      matrixEventId: matrixEventId ?? this.matrixEventId,
      adapterType: adapterType ?? this.adapterType,
      externalTaskId: externalTaskId ?? this.externalTaskId,
      externalTaskKey: externalTaskKey is String?
          ? externalTaskKey
          : this.externalTaskKey,
      externalTaskUrl: externalTaskUrl ?? this.externalTaskUrl,
      createdByMessengerUserId: createdByMessengerUserId is int?
          ? createdByMessengerUserId
          : this.createdByMessengerUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
