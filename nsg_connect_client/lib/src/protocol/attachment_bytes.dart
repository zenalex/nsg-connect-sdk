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
import 'dart:typed_data' as _i2;

/// Возврат `messenger.downloadAttachment(mxcUrl)`. Bytes —
/// body media-файла, contentType — из Matrix response header
/// (может отличаться от того что был на upload — Synapse может
/// transcode HEIC → WebP, etc).
///
/// **TASK19-Phase2 backlog**: streaming через `Stream<List<int>>`
/// либо presigned MinIO URL для memory relief — текущий MVP
/// грузит весь byte-array в heap (50-100MB cap). Acceptable для
/// начала, но при move на > 100MB videos станет block.
abstract class AttachmentBytes implements _i1.SerializableModel {
  AttachmentBytes._({
    required this.bytes,
    required this.contentType,
  });

  factory AttachmentBytes({
    required _i2.ByteData bytes,
    required String contentType,
  }) = _AttachmentBytesImpl;

  factory AttachmentBytes.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentBytes(
      bytes: _i1.ByteDataJsonExtension.fromJson(jsonSerialization['bytes']),
      contentType: jsonSerialization['contentType'] as String,
    );
  }

  _i2.ByteData bytes;

  String contentType;

  /// Returns a shallow copy of this [AttachmentBytes]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentBytes copyWith({
    _i2.ByteData? bytes,
    String? contentType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentBytes',
      'bytes': bytes.toJson(),
      'contentType': contentType,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AttachmentBytesImpl extends AttachmentBytes {
  _AttachmentBytesImpl({
    required _i2.ByteData bytes,
    required String contentType,
  }) : super._(
         bytes: bytes,
         contentType: contentType,
       );

  /// Returns a shallow copy of this [AttachmentBytes]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentBytes copyWith({
    _i2.ByteData? bytes,
    String? contentType,
  }) {
    return AttachmentBytes(
      bytes: bytes ?? this.bytes.clone(),
      contentType: contentType ?? this.contentType,
    );
  }
}
