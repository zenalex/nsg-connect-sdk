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

/// **TASK79 п.9**: строка списка «Участники» папки/монитора. Display-уровень
/// (по образцу `RoomParticipant`): SDK рисует имя + бейдж роли, не делая
/// второй запрос за профилем.
abstract class PulseMemberView implements _i1.SerializableModel {
  PulseMemberView._({
    required this.messengerUserId,
    this.displayName,
    this.username,
    this.avatarUrl,
    required this.role,
    bool? inherited,
    this.inheritedFromFolderId,
    this.addedAt,
  }) : inherited = inherited ?? false;

  factory PulseMemberView({
    required int messengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    required String role,
    bool? inherited,
    int? inheritedFromFolderId,
    DateTime? addedAt,
  }) = _PulseMemberViewImpl;

  factory PulseMemberView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseMemberView(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      username: jsonSerialization['username'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: jsonSerialization['role'] as String,
      inherited: jsonSerialization['inherited'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['inherited']),
      inheritedFromFolderId: jsonSerialization['inheritedFromFolderId'] as int?,
      addedAt: jsonSerialization['addedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['addedAt']),
    );
  }

  int messengerUserId;

  String? displayName;

  /// Публичный handle (`EmailAccount.username`), если есть.
  String? username;

  String? avatarUrl;

  /// `owner` | `admin` | `viewer`.
  String role;

  /// `true` — роль пришла не с самого объекта, а с папки-предка
  /// (наследование вниз). UI показывает такую строку read-only: убирать
  /// участника надо там, где его добавили, иначе жест «удалить» молча
  /// ничего не делает.
  bool inherited;

  /// С какой папки унаследовано (для подсказки в UI). null для прямого
  /// членства.
  int? inheritedFromFolderId;

  DateTime? addedAt;

  /// Returns a shallow copy of this [PulseMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseMemberView copyWith({
    int? messengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? role,
    bool? inherited,
    int? inheritedFromFolderId,
    DateTime? addedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseMemberView',
      'messengerUserId': messengerUserId,
      if (displayName != null) 'displayName': displayName,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role,
      'inherited': inherited,
      if (inheritedFromFolderId != null)
        'inheritedFromFolderId': inheritedFromFolderId,
      if (addedAt != null) 'addedAt': addedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseMemberViewImpl extends PulseMemberView {
  _PulseMemberViewImpl({
    required int messengerUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    required String role,
    bool? inherited,
    int? inheritedFromFolderId,
    DateTime? addedAt,
  }) : super._(
         messengerUserId: messengerUserId,
         displayName: displayName,
         username: username,
         avatarUrl: avatarUrl,
         role: role,
         inherited: inherited,
         inheritedFromFolderId: inheritedFromFolderId,
         addedAt: addedAt,
       );

  /// Returns a shallow copy of this [PulseMemberView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseMemberView copyWith({
    int? messengerUserId,
    Object? displayName = _Undefined,
    Object? username = _Undefined,
    Object? avatarUrl = _Undefined,
    String? role,
    bool? inherited,
    Object? inheritedFromFolderId = _Undefined,
    Object? addedAt = _Undefined,
  }) {
    return PulseMemberView(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      username: username is String? ? username : this.username,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
      inherited: inherited ?? this.inherited,
      inheritedFromFolderId: inheritedFromFolderId is int?
          ? inheritedFromFolderId
          : this.inheritedFromFolderId,
      addedAt: addedAt is DateTime? ? addedAt : this.addedAt,
    );
  }
}
