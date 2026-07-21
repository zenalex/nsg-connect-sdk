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
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i2;

/// **TASK52 итер.1**: личная визитка (аналог iOS Contact Poster) —
/// стиль + поля «о себе» с per-field видимостью. 1:1 к MessengerUser
/// (unique index; plain int — конвенция contact_meta: FK-relation на
/// messenger_users здесь не заводим, чистка при удалении юзера —
/// бэклог-джоба).
///
/// Стиль — ФИКС-ШАБЛОНЫ (photo | gradient | monogram), не свободный
/// canvas (решение постановщика, §3A.1): автоконтраст имени поверх
/// фона считает клиент, тёмная тема из коробки.
abstract class ContactCard implements _i1.SerializableModel {
  ContactCard._({
    this.id,
    required this.messengerUserId,
    required this.template,
    this.backgroundMxc,
    this.gradientStart,
    this.gradientEnd,
    this.nameFontStyle,
    this.nameColor,
    this.about,
    this.jobTitle,
    this.company,
    this.phone,
    this.email,
    this.website,
    required this.contactsOnlyFields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactCard({
    int? id,
    required int messengerUserId,
    required String template,
    String? backgroundMxc,
    String? gradientStart,
    String? gradientEnd,
    String? nameFontStyle,
    String? nameColor,
    String? about,
    String? jobTitle,
    String? company,
    String? phone,
    String? email,
    String? website,
    required List<String> contactsOnlyFields,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ContactCardImpl;

  factory ContactCard.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactCard(
      id: jsonSerialization['id'] as int?,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      template: jsonSerialization['template'] as String,
      backgroundMxc: jsonSerialization['backgroundMxc'] as String?,
      gradientStart: jsonSerialization['gradientStart'] as String?,
      gradientEnd: jsonSerialization['gradientEnd'] as String?,
      nameFontStyle: jsonSerialization['nameFontStyle'] as String?,
      nameColor: jsonSerialization['nameColor'] as String?,
      about: jsonSerialization['about'] as String?,
      jobTitle: jsonSerialization['jobTitle'] as String?,
      company: jsonSerialization['company'] as String?,
      phone: jsonSerialization['phone'] as String?,
      email: jsonSerialization['email'] as String?,
      website: jsonSerialization['website'] as String?,
      contactsOnlyFields: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['contactsOnlyFields'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
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

  /// Шаблон фона: 'photo' | 'gradient' | 'monogram'. Whitelist в
  /// ContactCardService.
  String template;

  /// mxc-URL фото-фона (template='photo'); загружается существующим
  /// uploadAttachment (TASK19), рендер — MxcImageProvider.
  String? backgroundMxc;

  /// Пара цветов градиента '#RRGGBB' (gradient; monogram использует
  /// gradientStart как тон подложки).
  String? gradientStart;

  String? gradientEnd;

  /// Пресет начертания имени: 'classic' | 'bold' | 'airy' | 'mono'.
  /// Итер.1 — вариации системного шрифта (бандл OFL-шрифтов отложен).
  String? nameFontStyle;

  /// Цвет имени '#RRGGBB'; null = автоконтраст по фону (клиент).
  String? nameColor;

  /// Поля «о себе». Все опциональны; лимиты в ContactCardService.
  String? about;

  String? jobTitle;

  String? company;

  String? phone;

  String? email;

  String? website;

  /// Имена полей, видимых ТОЛЬКО контактам (итер.1: контакт = общая
  /// комната, предикат isContact; итер.2 мигрирует на ContactLink).
  /// Подмножество {about, jobTitle, company, phone, email, website};
  /// не перечисленные здесь поля видны everyone.
  List<String> contactsOnlyFields;

  DateTime createdAt;

  /// Версионирование для клиентского кэша (§3A.6).
  DateTime updatedAt;

  /// Returns a shallow copy of this [ContactCard]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactCard copyWith({
    int? id,
    int? messengerUserId,
    String? template,
    String? backgroundMxc,
    String? gradientStart,
    String? gradientEnd,
    String? nameFontStyle,
    String? nameColor,
    String? about,
    String? jobTitle,
    String? company,
    String? phone,
    String? email,
    String? website,
    List<String>? contactsOnlyFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactCard',
      if (id != null) 'id': id,
      'messengerUserId': messengerUserId,
      'template': template,
      if (backgroundMxc != null) 'backgroundMxc': backgroundMxc,
      if (gradientStart != null) 'gradientStart': gradientStart,
      if (gradientEnd != null) 'gradientEnd': gradientEnd,
      if (nameFontStyle != null) 'nameFontStyle': nameFontStyle,
      if (nameColor != null) 'nameColor': nameColor,
      if (about != null) 'about': about,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (company != null) 'company': company,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      'contactsOnlyFields': contactsOnlyFields.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactCardImpl extends ContactCard {
  _ContactCardImpl({
    int? id,
    required int messengerUserId,
    required String template,
    String? backgroundMxc,
    String? gradientStart,
    String? gradientEnd,
    String? nameFontStyle,
    String? nameColor,
    String? about,
    String? jobTitle,
    String? company,
    String? phone,
    String? email,
    String? website,
    required List<String> contactsOnlyFields,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         messengerUserId: messengerUserId,
         template: template,
         backgroundMxc: backgroundMxc,
         gradientStart: gradientStart,
         gradientEnd: gradientEnd,
         nameFontStyle: nameFontStyle,
         nameColor: nameColor,
         about: about,
         jobTitle: jobTitle,
         company: company,
         phone: phone,
         email: email,
         website: website,
         contactsOnlyFields: contactsOnlyFields,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ContactCard]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactCard copyWith({
    Object? id = _Undefined,
    int? messengerUserId,
    String? template,
    Object? backgroundMxc = _Undefined,
    Object? gradientStart = _Undefined,
    Object? gradientEnd = _Undefined,
    Object? nameFontStyle = _Undefined,
    Object? nameColor = _Undefined,
    Object? about = _Undefined,
    Object? jobTitle = _Undefined,
    Object? company = _Undefined,
    Object? phone = _Undefined,
    Object? email = _Undefined,
    Object? website = _Undefined,
    List<String>? contactsOnlyFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactCard(
      id: id is int? ? id : this.id,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      template: template ?? this.template,
      backgroundMxc: backgroundMxc is String?
          ? backgroundMxc
          : this.backgroundMxc,
      gradientStart: gradientStart is String?
          ? gradientStart
          : this.gradientStart,
      gradientEnd: gradientEnd is String? ? gradientEnd : this.gradientEnd,
      nameFontStyle: nameFontStyle is String?
          ? nameFontStyle
          : this.nameFontStyle,
      nameColor: nameColor is String? ? nameColor : this.nameColor,
      about: about is String? ? about : this.about,
      jobTitle: jobTitle is String? ? jobTitle : this.jobTitle,
      company: company is String? ? company : this.company,
      phone: phone is String? ? phone : this.phone,
      email: email is String? ? email : this.email,
      website: website is String? ? website : this.website,
      contactsOnlyFields:
          contactsOnlyFields ??
          this.contactsOnlyFields.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
