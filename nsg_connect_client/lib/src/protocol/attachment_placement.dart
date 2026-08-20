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

/// **TASK92**: в какие комнаты отправлено вложение из S3.
///
/// Это и есть контроль доступа: presigned-ссылка выдаётся, только если
/// запросивший состоит хотя бы в одной из этих комнат. Раньше ту же
/// проверку делал Matrix, у S3-объектов Matrix-а нет.
///
/// **Почему отдельная таблица, а не поле `roomId` у объекта.** Пересылка
/// сообщения переиспользует тот же `AttachmentRef` в другой комнате
/// (`forwardedFromRoomId` в `sendMessage`). При одном поле получатель в
/// целевой комнате не смог бы открыть пересланное вложение — либо, если
/// поле перезаписывать, его переставал бы видеть исходный получатель.
/// Связь по своей природе множественная.
///
/// Строка появляется на отправке сообщения с вложением. Загрузка сама по
/// себе строк не создаёт: до отправки вложение видит только загрузивший.
abstract class AttachmentPlacement implements _i1.SerializableModel {
  AttachmentPlacement._({
    this.id,
    required this.attachmentObjectId,
    required this.roomId,
    required this.createdAt,
  });

  factory AttachmentPlacement({
    int? id,
    required int attachmentObjectId,
    required int roomId,
    required DateTime createdAt,
  }) = _AttachmentPlacementImpl;

  factory AttachmentPlacement.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentPlacement(
      id: jsonSerialization['id'] as int?,
      attachmentObjectId: jsonSerialization['attachmentObjectId'] as int,
      roomId: jsonSerialization['roomId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int attachmentObjectId;

  int roomId;

  DateTime createdAt;

  /// Returns a shallow copy of this [AttachmentPlacement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentPlacement copyWith({
    int? id,
    int? attachmentObjectId,
    int? roomId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentPlacement',
      if (id != null) 'id': id,
      'attachmentObjectId': attachmentObjectId,
      'roomId': roomId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AttachmentPlacementImpl extends AttachmentPlacement {
  _AttachmentPlacementImpl({
    int? id,
    required int attachmentObjectId,
    required int roomId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         attachmentObjectId: attachmentObjectId,
         roomId: roomId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AttachmentPlacement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentPlacement copyWith({
    Object? id = _Undefined,
    int? attachmentObjectId,
    int? roomId,
    DateTime? createdAt,
  }) {
    return AttachmentPlacement(
      id: id is int? ? id : this.id,
      attachmentObjectId: attachmentObjectId ?? this.attachmentObjectId,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
