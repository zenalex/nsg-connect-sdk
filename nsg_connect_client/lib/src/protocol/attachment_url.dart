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

/// **TASK92**: временная ссылка, по которой клиент скачивает вложение из
/// S3 сам — минуя и Serverpod, и Synapse.
///
/// `expiresAt` отдаётся не для красоты: ссылка это самостоятельный секрет
/// с коротким сроком, и клиент должен знать, когда перезапросить, а не
/// узнавать об истечении по битой картинке. Перезапрос дёшев — подпись
/// считается локально, без обращения к хранилищу.
abstract class AttachmentUrl implements _i1.SerializableModel {
  AttachmentUrl._({
    required this.url,
    required this.expiresAt,
    required this.contentType,
  });

  factory AttachmentUrl({
    required String url,
    required DateTime expiresAt,
    required String contentType,
  }) = _AttachmentUrlImpl;

  factory AttachmentUrl.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentUrl(
      url: jsonSerialization['url'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      contentType: jsonSerialization['contentType'] as String,
    );
  }

  String url;

  /// Момент, после которого ссылка перестаёт работать (UTC).
  DateTime expiresAt;

  /// Тип содержимого — клиенту незачем угадывать его по расширению.
  String contentType;

  /// Returns a shallow copy of this [AttachmentUrl]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentUrl copyWith({
    String? url,
    DateTime? expiresAt,
    String? contentType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentUrl',
      'url': url,
      'expiresAt': expiresAt.toJson(),
      'contentType': contentType,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AttachmentUrlImpl extends AttachmentUrl {
  _AttachmentUrlImpl({
    required String url,
    required DateTime expiresAt,
    required String contentType,
  }) : super._(
         url: url,
         expiresAt: expiresAt,
         contentType: contentType,
       );

  /// Returns a shallow copy of this [AttachmentUrl]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentUrl copyWith({
    String? url,
    DateTime? expiresAt,
    String? contentType,
  }) {
    return AttachmentUrl(
      url: url ?? this.url,
      expiresAt: expiresAt ?? this.expiresAt,
      contentType: contentType ?? this.contentType,
    );
  }
}
