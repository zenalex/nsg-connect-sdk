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

/// **TASK52 итер.1**: DTO визитки глазами смотрящего — поля УЖЕ
/// отфильтрованы per-field видимостью (contacts-only поля вырезаны,
/// если смотрящий не контакт владельца). Имя НЕ ContactCardView —
/// в SDK так называется виджет-рендерер (урок коллизии ChatFolder).
abstract class ContactCardInfo implements _i1.SerializableModel {
  ContactCardInfo._({
    required this.ownerMessengerUserId,
    this.displayName,
    this.avatarUrl,
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
    required this.hasHiddenFields,
    required this.updatedAt,
  });

  factory ContactCardInfo({
    required int ownerMessengerUserId,
    String? displayName,
    String? avatarUrl,
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
    required bool hasHiddenFields,
    required DateTime updatedAt,
  }) = _ContactCardInfoImpl;

  factory ContactCardInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactCardInfo(
      ownerMessengerUserId: jsonSerialization['ownerMessengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
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
      hasHiddenFields: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasHiddenFields'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int ownerMessengerUserId;

  /// Публичное имя владельца (displayName ?? matrixUserId) — карточка
  /// самодостаточна для рендера (экран звонка не ждёт профиль).
  String? displayName;

  String? avatarUrl;

  String template;

  String? backgroundMxc;

  String? gradientStart;

  String? gradientEnd;

  String? nameFontStyle;

  String? nameColor;

  String? about;

  String? jobTitle;

  String? company;

  String? phone;

  String? email;

  String? website;

  /// true = часть полей скрыта видимостью (смотрящий не контакт).
  /// UI может показать «полная визитка видна контактам».
  bool hasHiddenFields;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ContactCardInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactCardInfo copyWith({
    int? ownerMessengerUserId,
    String? displayName,
    String? avatarUrl,
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
    bool? hasHiddenFields,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactCardInfo',
      'ownerMessengerUserId': ownerMessengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
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
      'hasHiddenFields': hasHiddenFields,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactCardInfoImpl extends ContactCardInfo {
  _ContactCardInfoImpl({
    required int ownerMessengerUserId,
    String? displayName,
    String? avatarUrl,
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
    required bool hasHiddenFields,
    required DateTime updatedAt,
  }) : super._(
         ownerMessengerUserId: ownerMessengerUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
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
         hasHiddenFields: hasHiddenFields,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ContactCardInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactCardInfo copyWith({
    int? ownerMessengerUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
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
    bool? hasHiddenFields,
    DateTime? updatedAt,
  }) {
    return ContactCardInfo(
      ownerMessengerUserId: ownerMessengerUserId ?? this.ownerMessengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
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
      hasHiddenFields: hasHiddenFields ?? this.hasHiddenFields,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
