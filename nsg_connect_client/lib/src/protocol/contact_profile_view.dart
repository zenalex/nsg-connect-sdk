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

/// **TASK63**: DTO профиля контакта глазами viewer-а: реальные публичные
/// поля (displayName/username/avatar) + приватные per-viewer alias,
/// заметка и id меток.
abstract class ContactProfileView implements _i1.SerializableModel {
  ContactProfileView._({
    required this.contactMessengerUserId,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.email,
    this.customName,
    this.note,
    required this.labelIds,
    required this.knownViaTeamNames,
    required this.knownViaSharedRoom,
    required this.knownViaManualContact,
  });

  factory ContactProfileView({
    required int contactMessengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? email,
    String? customName,
    String? note,
    required List<int> labelIds,
    required List<String> knownViaTeamNames,
    required bool knownViaSharedRoom,
    required bool knownViaManualContact,
  }) = _ContactProfileViewImpl;

  factory ContactProfileView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactProfileView(
      contactMessengerUserId:
          jsonSerialization['contactMessengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      username: jsonSerialization['username'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      email: jsonSerialization['email'] as String?,
      customName: jsonSerialization['customName'] as String?,
      note: jsonSerialization['note'] as String?,
      labelIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['labelIds'],
      ),
      knownViaTeamNames: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['knownViaTeamNames'],
      ),
      knownViaSharedRoom: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['knownViaSharedRoom'],
      ),
      knownViaManualContact: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['knownViaManualContact'],
      ),
    );
  }

  int contactMessengerUserId;

  /// Реальное публичное имя контакта (displayName ?? matrixUserId).
  String? displayName;

  String? username;

  String? avatarUrl;

  /// **TASK52 итер.2**: регистрационный email (EmailAccount.email).
  /// Есть у всех email/password-аккаунтов «по определению» — показываем
  /// в профиле как контакт (fallback, если в визитке email не задан).
  /// Отдаётся ТОЛЬКО взаимным контактам (isContact) — как обмен визитками;
  /// незнакомцу/pending-заявке null (не даём собирать email-ы). null также
  /// для SSO/бот-пользователей без EmailAccount.
  String? email;

  /// Per-viewer «своё имя» (alias). null = не задано.
  String? customName;

  /// Per-viewer заметка. null = не задана.
  String? note;

  /// Метки viewer-а, назначенные этому контакту.
  List<int> labelIds;

  /// **Откуда человек знаком** (§6 DESIGN_TEAMS_AND_CONTACT_SHARING).
  ///
  /// Нужно не для украшения карточки, а чтобы правильное поведение не
  /// выглядело багом. Убрал человека из команды — а он не пропал из
  /// списка людей, потому что остался общий чат. Без объяснения это
  /// читается как «исключение не сработало», и админ идёт искать ошибку
  /// там, где её нет.
  ///
  /// Источников может быть сразу несколько — поэтому не одно поле, а
  /// три: показать надо ВСЕ действующие, иначе объяснение снова
  /// окажется неполным.
  ///
  /// Утечки нет: имена команд видит только тот, кто сам в них состоит, а
  /// про общую комнату смотрящий и так знает — он в ней участник.
  List<String> knownViaTeamNames;

  /// Есть хотя бы одна общая комната.
  bool knownViaSharedRoom;

  /// Смотрящий добавил этого человека к себе сам (ручной контакт, QR,
  /// заявка и т.п. — любой ЯВНЫЙ жест, в отличие от автоматического
  /// «мы оказались в одной комнате»).
  bool knownViaManualContact;

  /// Returns a shallow copy of this [ContactProfileView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactProfileView copyWith({
    int? contactMessengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? email,
    String? customName,
    String? note,
    List<int>? labelIds,
    List<String>? knownViaTeamNames,
    bool? knownViaSharedRoom,
    bool? knownViaManualContact,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactProfileView',
      'contactMessengerUserId': contactMessengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (email != null) 'email': email,
      if (customName != null) 'customName': customName,
      if (note != null) 'note': note,
      'labelIds': labelIds.toJson(),
      'knownViaTeamNames': knownViaTeamNames.toJson(),
      'knownViaSharedRoom': knownViaSharedRoom,
      'knownViaManualContact': knownViaManualContact,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ContactProfileViewImpl extends ContactProfileView {
  _ContactProfileViewImpl({
    required int contactMessengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? email,
    String? customName,
    String? note,
    required List<int> labelIds,
    required List<String> knownViaTeamNames,
    required bool knownViaSharedRoom,
    required bool knownViaManualContact,
  }) : super._(
         contactMessengerUserId: contactMessengerUserId,
         displayName: displayName,
         username: username,
         avatarUrl: avatarUrl,
         email: email,
         customName: customName,
         note: note,
         labelIds: labelIds,
         knownViaTeamNames: knownViaTeamNames,
         knownViaSharedRoom: knownViaSharedRoom,
         knownViaManualContact: knownViaManualContact,
       );

  /// Returns a shallow copy of this [ContactProfileView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactProfileView copyWith({
    int? contactMessengerUserId,
    Object? displayName = _Undefined,
    Object? username = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? email = _Undefined,
    Object? customName = _Undefined,
    Object? note = _Undefined,
    List<int>? labelIds,
    List<String>? knownViaTeamNames,
    bool? knownViaSharedRoom,
    bool? knownViaManualContact,
  }) {
    return ContactProfileView(
      contactMessengerUserId:
          contactMessengerUserId ?? this.contactMessengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      username: username is String? ? username : this.username,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      email: email is String? ? email : this.email,
      customName: customName is String? ? customName : this.customName,
      note: note is String? ? note : this.note,
      labelIds: labelIds ?? this.labelIds.map((e0) => e0).toList(),
      knownViaTeamNames:
          knownViaTeamNames ?? this.knownViaTeamNames.map((e0) => e0).toList(),
      knownViaSharedRoom: knownViaSharedRoom ?? this.knownViaSharedRoom,
      knownViaManualContact:
          knownViaManualContact ?? this.knownViaManualContact,
    );
  }
}
