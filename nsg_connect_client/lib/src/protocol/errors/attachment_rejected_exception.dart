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
import '../enums/attachment_reject_reason.dart' as _i2;

/// Issue #54: вложение отклонено валидацией `AttachmentService.upload`
/// (MIME whitelist / extension blacklist / size cap).
///
/// Зачем typed exception, а не прежний `ArgumentError`:
///   * `ArgumentError` — не `SerializableException`, Serverpod
///     заворачивает его в generic 500 без текста. Клиент видел
///     безымянную ошибку, показывал красный «!» и НЕ мог объяснить
///     юзеру причину (issue #54: .txt молча падал);
///   * permanent-ошибку нельзя ретраить — `isTransientSendError`
///     должен уметь распознать её по типу;
///   * поля позволяют SDK собрать локализованный текст («тип файла
///     не поддерживается» / «файл больше N МБ»).
///
/// `maxBytes` / `actualBytes` заполнены только для `tooLarge`.
abstract class AttachmentRejectedException
    implements _i1.SerializableException, _i1.SerializableModel {
  AttachmentRejectedException._({
    required this.reason,
    required this.mimeType,
    required this.filename,
    this.maxBytes,
    this.actualBytes,
  });

  factory AttachmentRejectedException({
    required _i2.AttachmentRejectReason reason,
    required String mimeType,
    required String filename,
    int? maxBytes,
    int? actualBytes,
  }) = _AttachmentRejectedExceptionImpl;

  factory AttachmentRejectedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AttachmentRejectedException(
      reason: _i2.AttachmentRejectReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
      mimeType: jsonSerialization['mimeType'] as String,
      filename: jsonSerialization['filename'] as String,
      maxBytes: jsonSerialization['maxBytes'] as int?,
      actualBytes: jsonSerialization['actualBytes'] as int?,
    );
  }

  _i2.AttachmentRejectReason reason;

  String mimeType;

  String filename;

  int? maxBytes;

  int? actualBytes;

  /// Returns a shallow copy of this [AttachmentRejectedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentRejectedException copyWith({
    _i2.AttachmentRejectReason? reason,
    String? mimeType,
    String? filename,
    int? maxBytes,
    int? actualBytes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentRejectedException',
      'reason': reason.toJson(),
      'mimeType': mimeType,
      'filename': filename,
      if (maxBytes != null) 'maxBytes': maxBytes,
      if (actualBytes != null) 'actualBytes': actualBytes,
    };
  }

  @override
  String toString() {
    return 'AttachmentRejectedException(reason: $reason, mimeType: $mimeType, filename: $filename, maxBytes: $maxBytes, actualBytes: $actualBytes)';
  }
}

class _Undefined {}

class _AttachmentRejectedExceptionImpl extends AttachmentRejectedException {
  _AttachmentRejectedExceptionImpl({
    required _i2.AttachmentRejectReason reason,
    required String mimeType,
    required String filename,
    int? maxBytes,
    int? actualBytes,
  }) : super._(
         reason: reason,
         mimeType: mimeType,
         filename: filename,
         maxBytes: maxBytes,
         actualBytes: actualBytes,
       );

  /// Returns a shallow copy of this [AttachmentRejectedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentRejectedException copyWith({
    _i2.AttachmentRejectReason? reason,
    String? mimeType,
    String? filename,
    Object? maxBytes = _Undefined,
    Object? actualBytes = _Undefined,
  }) {
    return AttachmentRejectedException(
      reason: reason ?? this.reason,
      mimeType: mimeType ?? this.mimeType,
      filename: filename ?? this.filename,
      maxBytes: maxBytes is int? ? maxBytes : this.maxBytes,
      actualBytes: actualBytes is int? ? actualBytes : this.actualBytes,
    );
  }
}
