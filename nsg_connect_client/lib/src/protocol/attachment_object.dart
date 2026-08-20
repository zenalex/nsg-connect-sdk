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

/// **TASK92**: вложение, лежащее в S3, а не в media-store Synapse.
///
/// Появляется на загрузке и живёт независимо от сообщений: сначала человек
/// прикрепляет файл, и только потом (или никогда) отправляет сообщение.
///
/// **Зачем строка в БД, а если проще — вывести ключ из mxc.** Сегодня
/// членство в комнате проверяет Matrix: Authenticated Media отдаёт байты
/// только тому, кто состоит в комнате с этой медиа. Presigned-ссылку
/// выписываем мы, значит и проверять обязаны мы — а для этого нужно знать,
/// куда вложение отправлено (см. `AttachmentPlacement`). С выводимым
/// ключом и без записи любой залогиненный получал бы ссылку на чужое
/// вложение, подставив идентификатор. Это была бы настоящая регрессия
/// безопасности, а не формальность.
///
/// `mxcUrl` — синтетический `mxc://<server>/s3_<id>`. Не адрес в Synapse;
/// туда такое вложение не загружалось вовсе. Форма сохранена, потому что
/// по этой строке ключуется клиентский кэш
/// (`messenger_cache_store`, PK `(userId, mxcUrl, kind)`) и её требует
/// `AttachmentService.parseAttachmentFromContent` после круга через Matrix.
abstract class AttachmentObject implements _i1.SerializableModel {
  AttachmentObject._({
    this.id,
    required this.tenantId,
    required this.storageKey,
    required this.mxcUrl,
    required this.uploaderMessengerUserId,
    required this.mimeType,
    required this.sizeBytes,
    required this.originalFilename,
    this.width,
    this.height,
    this.thumbnailStorageKey,
    this.thumbnailSizeBytes,
    required this.createdAt,
  });

  factory AttachmentObject({
    int? id,
    required int tenantId,
    required String storageKey,
    required String mxcUrl,
    required int uploaderMessengerUserId,
    required String mimeType,
    required int sizeBytes,
    required String originalFilename,
    int? width,
    int? height,
    String? thumbnailStorageKey,
    int? thumbnailSizeBytes,
    required DateTime createdAt,
  }) = _AttachmentObjectImpl;

  factory AttachmentObject.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentObject(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      storageKey: jsonSerialization['storageKey'] as String,
      mxcUrl: jsonSerialization['mxcUrl'] as String,
      uploaderMessengerUserId:
          jsonSerialization['uploaderMessengerUserId'] as int,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      originalFilename: jsonSerialization['originalFilename'] as String,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
      thumbnailStorageKey: jsonSerialization['thumbnailStorageKey'] as String?,
      thumbnailSizeBytes: jsonSerialization['thumbnailSizeBytes'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Нужен для учёта по тенантам и для per-tenant бакетов (issue #71,
  /// строго ПОСЛЕ этой задачи). Берётся у загрузившего.
  int tenantId;

  /// Ключ объекта в бакете: `att/<yyyy>/<mm>/<id>[.ext]`.
  String storageKey;

  /// Синтетический mxc — идентичность вложения для клиента и для
  /// Matrix-события.
  String mxcUrl;

  int uploaderMessengerUserId;

  String mimeType;

  int sizeBytes;

  /// Имя файла как было у отправителя. Тот же PII-компромисс, что и в
  /// `AttachmentRef`.
  String originalFilename;

  /// Server-probed для image/*; null для HEIC/HEIF и видео.
  int? width;

  int? height;

  /// Второй объект в бакете — уменьшенная копия. null для всего, чему
  /// превью не делали (документы, видео, HEIC).
  String? thumbnailStorageKey;

  int? thumbnailSizeBytes;

  DateTime createdAt;

  /// Returns a shallow copy of this [AttachmentObject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentObject copyWith({
    int? id,
    int? tenantId,
    String? storageKey,
    String? mxcUrl,
    int? uploaderMessengerUserId,
    String? mimeType,
    int? sizeBytes,
    String? originalFilename,
    int? width,
    int? height,
    String? thumbnailStorageKey,
    int? thumbnailSizeBytes,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentObject',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'storageKey': storageKey,
      'mxcUrl': mxcUrl,
      'uploaderMessengerUserId': uploaderMessengerUserId,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'originalFilename': originalFilename,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnailStorageKey != null)
        'thumbnailStorageKey': thumbnailStorageKey,
      if (thumbnailSizeBytes != null) 'thumbnailSizeBytes': thumbnailSizeBytes,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AttachmentObjectImpl extends AttachmentObject {
  _AttachmentObjectImpl({
    int? id,
    required int tenantId,
    required String storageKey,
    required String mxcUrl,
    required int uploaderMessengerUserId,
    required String mimeType,
    required int sizeBytes,
    required String originalFilename,
    int? width,
    int? height,
    String? thumbnailStorageKey,
    int? thumbnailSizeBytes,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         storageKey: storageKey,
         mxcUrl: mxcUrl,
         uploaderMessengerUserId: uploaderMessengerUserId,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         originalFilename: originalFilename,
         width: width,
         height: height,
         thumbnailStorageKey: thumbnailStorageKey,
         thumbnailSizeBytes: thumbnailSizeBytes,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AttachmentObject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentObject copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? storageKey,
    String? mxcUrl,
    int? uploaderMessengerUserId,
    String? mimeType,
    int? sizeBytes,
    String? originalFilename,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? thumbnailStorageKey = _Undefined,
    Object? thumbnailSizeBytes = _Undefined,
    DateTime? createdAt,
  }) {
    return AttachmentObject(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      storageKey: storageKey ?? this.storageKey,
      mxcUrl: mxcUrl ?? this.mxcUrl,
      uploaderMessengerUserId:
          uploaderMessengerUserId ?? this.uploaderMessengerUserId,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalFilename: originalFilename ?? this.originalFilename,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
      thumbnailStorageKey: thumbnailStorageKey is String?
          ? thumbnailStorageKey
          : this.thumbnailStorageKey,
      thumbnailSizeBytes: thumbnailSizeBytes is int?
          ? thumbnailSizeBytes
          : this.thumbnailSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
