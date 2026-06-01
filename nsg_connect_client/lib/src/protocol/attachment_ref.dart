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

/// Ссылка на медиа-вложение (image / video / file) внутри Matrix
/// media repo. Возвращается из `messenger.uploadAttachment` и идёт в
/// `MessengerMessage.attachment` для render-а в SDK MessageBubble.
///
/// `mxcUrl` — Matrix Content URI (`mxc://server/mediaId`). НЕ HTTP URL;
/// SDK не качает напрямую — только через server-proxy
/// `messenger.downloadAttachment` (TASK07 invariant: matrix token не
/// покидает сервер; Matrix C-S 1.11+ Authenticated Media обязателен).
///
/// `width`/`height` server-probed для image (через `image` package).
/// Для HEIC/HEIF Dart нет хорошего decoder-а на TASK19 MVP — поля
/// остаются `null`, UI fallback на aspect-ratio placeholder. `durationMs`
/// для video — TASK19-Phase2 (нужен FFmpeg server-side).
///
/// `thumbnailMxcUrl` — TASK19 Chunk 1 оставляет null; Chunk 2
/// populated через Synapse `/thumbnail` endpoint (Synapse кэширует
/// automatically).
abstract class AttachmentRef implements _i1.SerializableModel {
  AttachmentRef._({
    required this.mxcUrl,
    required this.mimeType,
    required this.sizeBytes,
    required this.originalFilename,
    this.width,
    this.height,
    this.durationMs,
    this.thumbnailMxcUrl,
  });

  factory AttachmentRef({
    required String mxcUrl,
    required String mimeType,
    required int sizeBytes,
    required String originalFilename,
    int? width,
    int? height,
    int? durationMs,
    String? thumbnailMxcUrl,
  }) = _AttachmentRefImpl;

  factory AttachmentRef.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentRef(
      mxcUrl: jsonSerialization['mxcUrl'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      originalFilename: jsonSerialization['originalFilename'] as String,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
      durationMs: jsonSerialization['durationMs'] as int?,
      thumbnailMxcUrl: jsonSerialization['thumbnailMxcUrl'] as String?,
    );
  }

  String mxcUrl;

  String mimeType;

  int sizeBytes;

  /// Имя файла как было на устройстве sender-а. PII concern (может
  /// содержать `IMG_alice_passport.jpg`); на MVP записываем как есть
  /// (Telegram does same), TASK33 backlog для optional scrubbing.
  String originalFilename;

  /// Server-probed для image/* (PNG/JPEG/WebP). Для HEIC/HEIF/video —
  /// null на MVP; UI делает aspect-ratio fallback.
  int? width;

  int? height;

  /// TASK19-Phase2 — FFmpeg dependency, defer.
  int? durationMs;

  /// Chunk 2 populates. Тот же mxc:// что и оригинал — Synapse сам
  /// serve-ит scaled через `/thumbnail` endpoint (server делает, не SDK).
  String? thumbnailMxcUrl;

  /// Returns a shallow copy of this [AttachmentRef]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentRef copyWith({
    String? mxcUrl,
    String? mimeType,
    int? sizeBytes,
    String? originalFilename,
    int? width,
    int? height,
    int? durationMs,
    String? thumbnailMxcUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentRef',
      'mxcUrl': mxcUrl,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'originalFilename': originalFilename,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMs != null) 'durationMs': durationMs,
      if (thumbnailMxcUrl != null) 'thumbnailMxcUrl': thumbnailMxcUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AttachmentRefImpl extends AttachmentRef {
  _AttachmentRefImpl({
    required String mxcUrl,
    required String mimeType,
    required int sizeBytes,
    required String originalFilename,
    int? width,
    int? height,
    int? durationMs,
    String? thumbnailMxcUrl,
  }) : super._(
         mxcUrl: mxcUrl,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         originalFilename: originalFilename,
         width: width,
         height: height,
         durationMs: durationMs,
         thumbnailMxcUrl: thumbnailMxcUrl,
       );

  /// Returns a shallow copy of this [AttachmentRef]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentRef copyWith({
    String? mxcUrl,
    String? mimeType,
    int? sizeBytes,
    String? originalFilename,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? durationMs = _Undefined,
    Object? thumbnailMxcUrl = _Undefined,
  }) {
    return AttachmentRef(
      mxcUrl: mxcUrl ?? this.mxcUrl,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalFilename: originalFilename ?? this.originalFilename,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
      durationMs: durationMs is int? ? durationMs : this.durationMs,
      thumbnailMxcUrl: thumbnailMxcUrl is String?
          ? thumbnailMxcUrl
          : this.thumbnailMxcUrl,
    );
  }
}
