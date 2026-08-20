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

/// **issue #90**: превью ссылки — заголовок, описание и картинка с сайта,
/// как в других мессенджерах.
///
/// **Ходит по ссылке СЕРВЕР, а не клиент.** Это главное решение, и оно про
/// приватность, а не про удобство: если превью тянет клиент, то каждый
/// участник чата своим IP стучится на чужой сайт по любой присланной ссылке.
/// Достаточно кинуть в чат ссылку-ловушку, чтобы собрать адреса всех, кто
/// открыл переписку, — а заодно узнать, кто и когда её прочитал. Сервер
/// ходит один раз за всех и кэширует.
///
/// Кэш — эта таблица. Хранится и НЕУДАЧА тоже (см. [status]): без этого
/// мёртвая ссылка в популярном чате означала бы поход наружу на каждое
/// открытие переписки каждым участником.
abstract class LinkPreview implements _i1.SerializableModel {
  LinkPreview._({
    this.id,
    required this.url,
    required this.status,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    required this.fetchedAt,
    required this.expiresAt,
  });

  factory LinkPreview({
    int? id,
    required String url,
    required String status,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    required DateTime fetchedAt,
    required DateTime expiresAt,
  }) = _LinkPreviewImpl;

  factory LinkPreview.fromJson(Map<String, dynamic> jsonSerialization) {
    return LinkPreview(
      id: jsonSerialization['id'] as int?,
      url: jsonSerialization['url'] as String,
      status: jsonSerialization['status'] as String,
      title: jsonSerialization['title'] as String?,
      description: jsonSerialization['description'] as String?,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      siteName: jsonSerialization['siteName'] as String?,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Нормализованный URL — ключ кэша (см. LinkPreviewService.normalizeUrl).
  String url;

  /// `ok` — данные есть; `empty` — страница прочитана, но разметки нет
  /// (og-тегов не оказалось); `failed` — не достучались/отказ/не HTML.
  ///
  /// `empty` и `failed` различаются намеренно: первое — свойство страницы и
  /// меняется редко, второе может быть временным (сеть, 5xx), и повторять
  /// его стоит чаще. Один статус «нет превью» заставил бы выбирать между
  /// «долбить живой сайт» и «навсегда запомнить случайный сбой».
  String status;

  String? title;

  String? description;

  /// Абсолютный URL картинки со страницы. Саму картинку не перекачиваем:
  /// её грузит клиент. Да, это его IP — но по адресу, который он и так
  /// увидит в ленте; тайны тут уже нет, а гонять мегабайты через себя
  /// ради этого дорого. Если понадобится полная непрозрачность —
  /// проксировать картинки отдельной задачей.
  String? imageUrl;

  String? siteName;

  DateTime fetchedAt;

  /// До какого момента отдаём из кэша не спрашивая сайт.
  DateTime expiresAt;

  /// Returns a shallow copy of this [LinkPreview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LinkPreview copyWith({
    int? id,
    String? url,
    String? status,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    DateTime? fetchedAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkPreview',
      if (id != null) 'id': id,
      'url': url,
      'status': status,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (siteName != null) 'siteName': siteName,
      'fetchedAt': fetchedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LinkPreviewImpl extends LinkPreview {
  _LinkPreviewImpl({
    int? id,
    required String url,
    required String status,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    required DateTime fetchedAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         url: url,
         status: status,
         title: title,
         description: description,
         imageUrl: imageUrl,
         siteName: siteName,
         fetchedAt: fetchedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [LinkPreview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LinkPreview copyWith({
    Object? id = _Undefined,
    String? url,
    String? status,
    Object? title = _Undefined,
    Object? description = _Undefined,
    Object? imageUrl = _Undefined,
    Object? siteName = _Undefined,
    DateTime? fetchedAt,
    DateTime? expiresAt,
  }) {
    return LinkPreview(
      id: id is int? ? id : this.id,
      url: url ?? this.url,
      status: status ?? this.status,
      title: title is String? ? title : this.title,
      description: description is String? ? description : this.description,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      siteName: siteName is String? ? siteName : this.siteName,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
