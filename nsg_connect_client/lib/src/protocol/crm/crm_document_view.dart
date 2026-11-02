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
import '../crm/crm_document_kind.dart' as _i2;

/// TASK98 A contract; see TASK95 sections 4-7.
abstract class CrmDocumentView implements _i1.SerializableModel {
  CrmDocumentView._({
    required this.id,
    required this.segmentId,
    this.companyId,
    this.dealId,
    required this.version,
    required this.kind,
    required this.title,
    this.attachmentObjectId,
    this.url,
    this.mxcUrl,
    this.mimeType,
    this.originalFilename,
    this.sizeBytes,
  });

  factory CrmDocumentView({
    required int id,
    required int segmentId,
    int? companyId,
    int? dealId,
    required int version,
    required _i2.CrmDocumentKind kind,
    required String title,
    int? attachmentObjectId,
    String? url,
    String? mxcUrl,
    String? mimeType,
    String? originalFilename,
    int? sizeBytes,
  }) = _CrmDocumentViewImpl;

  factory CrmDocumentView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CrmDocumentView(
      id: jsonSerialization['id'] as int,
      segmentId: jsonSerialization['segmentId'] as int,
      companyId: jsonSerialization['companyId'] as int?,
      dealId: jsonSerialization['dealId'] as int?,
      version: jsonSerialization['version'] as int,
      kind: _i2.CrmDocumentKind.fromJson((jsonSerialization['kind'] as String)),
      title: jsonSerialization['title'] as String,
      attachmentObjectId: jsonSerialization['attachmentObjectId'] as int?,
      url: jsonSerialization['url'] as String?,
      mxcUrl: jsonSerialization['mxcUrl'] as String?,
      mimeType: jsonSerialization['mimeType'] as String?,
      originalFilename: jsonSerialization['originalFilename'] as String?,
      sizeBytes: jsonSerialization['sizeBytes'] as int?,
    );
  }

  int id;

  int segmentId;

  /// Hidden parent in another segment: never disclose its reference.
  int? companyId;

  int? dealId;

  int version;

  _i2.CrmDocumentKind kind;

  String title;

  int? attachmentObjectId;

  String? url;

  /// TASK101: metadata only for an authorized attachment-backed document.
  /// Links have no attachment fields. URLs are signed by messenger.getAttachmentUrl.
  String? mxcUrl;

  String? mimeType;

  String? originalFilename;

  int? sizeBytes;

  /// Returns a shallow copy of this [CrmDocumentView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CrmDocumentView copyWith({
    int? id,
    int? segmentId,
    int? companyId,
    int? dealId,
    int? version,
    _i2.CrmDocumentKind? kind,
    String? title,
    int? attachmentObjectId,
    String? url,
    String? mxcUrl,
    String? mimeType,
    String? originalFilename,
    int? sizeBytes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CrmDocumentView',
      'id': id,
      'segmentId': segmentId,
      if (companyId != null) 'companyId': companyId,
      if (dealId != null) 'dealId': dealId,
      'version': version,
      'kind': kind.toJson(),
      'title': title,
      if (attachmentObjectId != null) 'attachmentObjectId': attachmentObjectId,
      if (url != null) 'url': url,
      if (mxcUrl != null) 'mxcUrl': mxcUrl,
      if (mimeType != null) 'mimeType': mimeType,
      if (originalFilename != null) 'originalFilename': originalFilename,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CrmDocumentViewImpl extends CrmDocumentView {
  _CrmDocumentViewImpl({
    required int id,
    required int segmentId,
    int? companyId,
    int? dealId,
    required int version,
    required _i2.CrmDocumentKind kind,
    required String title,
    int? attachmentObjectId,
    String? url,
    String? mxcUrl,
    String? mimeType,
    String? originalFilename,
    int? sizeBytes,
  }) : super._(
         id: id,
         segmentId: segmentId,
         companyId: companyId,
         dealId: dealId,
         version: version,
         kind: kind,
         title: title,
         attachmentObjectId: attachmentObjectId,
         url: url,
         mxcUrl: mxcUrl,
         mimeType: mimeType,
         originalFilename: originalFilename,
         sizeBytes: sizeBytes,
       );

  /// Returns a shallow copy of this [CrmDocumentView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CrmDocumentView copyWith({
    int? id,
    int? segmentId,
    Object? companyId = _Undefined,
    Object? dealId = _Undefined,
    int? version,
    _i2.CrmDocumentKind? kind,
    String? title,
    Object? attachmentObjectId = _Undefined,
    Object? url = _Undefined,
    Object? mxcUrl = _Undefined,
    Object? mimeType = _Undefined,
    Object? originalFilename = _Undefined,
    Object? sizeBytes = _Undefined,
  }) {
    return CrmDocumentView(
      id: id ?? this.id,
      segmentId: segmentId ?? this.segmentId,
      companyId: companyId is int? ? companyId : this.companyId,
      dealId: dealId is int? ? dealId : this.dealId,
      version: version ?? this.version,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      attachmentObjectId: attachmentObjectId is int?
          ? attachmentObjectId
          : this.attachmentObjectId,
      url: url is String? ? url : this.url,
      mxcUrl: mxcUrl is String? ? mxcUrl : this.mxcUrl,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      originalFilename: originalFilename is String?
          ? originalFilename
          : this.originalFilename,
      sizeBytes: sizeBytes is int? ? sizeBytes : this.sizeBytes,
    );
  }
}
