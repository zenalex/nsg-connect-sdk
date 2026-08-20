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

/// **issue #90**: превью ссылки в том виде, в каком его получает клиент.
/// Транзиентный DTO (без `table:`).
///
/// Отдельно от [LinkPreview] потому, что наружу не нужны ни сроки кэша, ни
/// `failed`/`empty`: клиенту решать нечего — если сервер не отдал карточку,
/// значит её нет, и ссылка остаётся обычным текстом. Отдавать статусы «на
/// всякий случай» — приглашение завести на клиенте второй, расходящийся
/// набор правил.
abstract class LinkPreviewView implements _i1.SerializableModel {
  LinkPreviewView._({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  factory LinkPreviewView({
    required String url,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
  }) = _LinkPreviewViewImpl;

  factory LinkPreviewView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LinkPreviewView(
      url: jsonSerialization['url'] as String,
      title: jsonSerialization['title'] as String?,
      description: jsonSerialization['description'] as String?,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      siteName: jsonSerialization['siteName'] as String?,
    );
  }

  /// URL, к которому относится превью — **ровно та строка, которой спросил
  /// клиент**, а не серверный ключ кэша (нормализация специально уводит ключ
  /// от написанного в сообщении). Ответ приходит списком без гарантии
  /// порядка и с пропусками (превью может не быть), поэтому сопоставить
  /// карточку с сообщением клиент может только по этому полю.
  String url;

  String? title;

  String? description;

  String? imageUrl;

  String? siteName;

  /// Returns a shallow copy of this [LinkPreviewView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LinkPreviewView copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkPreviewView',
      'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (siteName != null) 'siteName': siteName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LinkPreviewViewImpl extends LinkPreviewView {
  _LinkPreviewViewImpl({
    required String url,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
  }) : super._(
         url: url,
         title: title,
         description: description,
         imageUrl: imageUrl,
         siteName: siteName,
       );

  /// Returns a shallow copy of this [LinkPreviewView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LinkPreviewView copyWith({
    String? url,
    Object? title = _Undefined,
    Object? description = _Undefined,
    Object? imageUrl = _Undefined,
    Object? siteName = _Undefined,
  }) {
    return LinkPreviewView(
      url: url ?? this.url,
      title: title is String? ? title : this.title,
      description: description is String? ? description : this.description,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      siteName: siteName is String? ? siteName : this.siteName,
    );
  }
}
