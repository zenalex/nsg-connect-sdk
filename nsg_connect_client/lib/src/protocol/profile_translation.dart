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

/// **TASK64**: языковая версия профиля пользователя. Базовый профиль =
/// колонки MessengerUser/ContactCard («что есть», legacy-пути читают
/// его как раньше); переводы — по строке на локаль. Resolution
/// per-viewer: alias > translation[uiLocale смотрящего] > en > база
/// (field-level, см. TASK64.md §3).
abstract class ProfileTranslation implements _i1.SerializableModel {
  ProfileTranslation._({
    this.id,
    required this.messengerUserId,
    required this.locale,
    this.displayName,
    this.about,
    this.jobTitle,
    this.company,
    required this.updatedAt,
  });

  factory ProfileTranslation({
    int? id,
    required int messengerUserId,
    required String locale,
    String? displayName,
    String? about,
    String? jobTitle,
    String? company,
    required DateTime updatedAt,
  }) = _ProfileTranslationImpl;

  factory ProfileTranslation.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProfileTranslation(
      id: jsonSerialization['id'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      locale: jsonSerialization['locale'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      about: jsonSerialization['about'] as String?,
      jobTitle: jsonSerialization['jobTitle'] as String?,
      company: jsonSerialization['company'] as String?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int messengerUserId;

  /// Короткий BCP-47 код ('en', 'de', 'zh'…). Формат валидирует сервис;
  /// список для выбора — на клиенте.
  String locale;

  /// Переводимые поля. null/пусто = «в этой локали не заполнено» —
  /// resolution идёт дальше по цепочке. Телефон/email/сайт не
  /// переводятся (language-neutral, живут только в базе).
  String? displayName;

  String? about;

  String? jobTitle;

  String? company;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ProfileTranslation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProfileTranslation copyWith({
    int? id,
    int? messengerUserId,
    String? locale,
    String? displayName,
    String? about,
    String? jobTitle,
    String? company,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProfileTranslation',
      if (id != null) 'id': id,
      'messengerUserId': messengerUserId,
      'locale': locale,
      if (displayName != null) 'displayName': displayName,
      if (about != null) 'about': about,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (company != null) 'company': company,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProfileTranslationImpl extends ProfileTranslation {
  _ProfileTranslationImpl({
    int? id,
    required int messengerUserId,
    required String locale,
    String? displayName,
    String? about,
    String? jobTitle,
    String? company,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         messengerUserId: messengerUserId,
         locale: locale,
         displayName: displayName,
         about: about,
         jobTitle: jobTitle,
         company: company,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ProfileTranslation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProfileTranslation copyWith({
    Object? id = _Undefined,
    int? messengerUserId,
    String? locale,
    Object? displayName = _Undefined,
    Object? about = _Undefined,
    Object? jobTitle = _Undefined,
    Object? company = _Undefined,
    DateTime? updatedAt,
  }) {
    return ProfileTranslation(
      id: id is int? ? id : this.id,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      locale: locale ?? this.locale,
      displayName: displayName is String? ? displayName : this.displayName,
      about: about is String? ? about : this.about,
      jobTitle: jobTitle is String? ? jobTitle : this.jobTitle,
      company: company is String? ? company : this.company,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
