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
import 'enums/room_member_role.dart' as _i2;
import 'enums/participant_kind.dart' as _i3;

/// Один участник комнаты в DTO `RoomDetails.participants`. Возвращает
/// display-уровень: SDK показывает рядом с именем role-badge и аватарку.
/// messengerUserId полезен только для followup-запросов (профиль,
/// remove-from-room — TASK29).
abstract class RoomParticipant implements _i1.SerializableModel {
  RoomParticipant._({
    required this.messengerUserId,
    required this.matrixUserId,
    this.displayName,
    this.avatarUrl,
    required this.role,
    this.username,
    this.writeBannedUntil,
    this.participantKind,
  });

  factory RoomParticipant({
    required int messengerUserId,
    required String matrixUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.RoomMemberRole role,
    String? username,
    DateTime? writeBannedUntil,
    _i3.ParticipantKind? participantKind,
  }) = _RoomParticipantImpl;

  factory RoomParticipant.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomParticipant(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      matrixUserId: jsonSerialization['matrixUserId'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: _i2.RoomMemberRole.fromJson((jsonSerialization['role'] as String)),
      username: jsonSerialization['username'] as String?,
      writeBannedUntil: jsonSerialization['writeBannedUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['writeBannedUntil'],
            ),
      participantKind: jsonSerialization['participantKind'] == null
          ? null
          : _i3.ParticipantKind.fromJson(
              (jsonSerialization['participantKind'] as String),
            ),
    );
  }

  int messengerUserId;

  String matrixUserId;

  String? displayName;

  String? avatarUrl;

  _i2.RoomMemberRole role;

  /// **Вариант B (@username)**: публичный handle пользователя (см.
  /// EmailAccount.username). Nullable — старые пользователи без backfill
  /// или non-nsg identity-провайдеры его не имеют. UI показывает
  /// `@username` рядом с displayName в результатах поиска.
  String? username;

  /// **Write-ban (2026-07-13)**: активный запрет писать в ЭТУ комнату
  /// (для шита участника: показать «Разрешить писать» и бейдж).
  /// Заполняется только в RoomDetails.participants; в поиске/директории
  /// null (нет комнатного контекста).
  DateTime? writeBannedUntil;

  /// **Issue #39**: тип участника (`RoomMembership.participantKind`) —
  /// чтобы SDK отличал бота/систему от живого оператора в ленте чата
  /// (подпись отправителя + бейдж «Бот» в support-комнатах).
  /// Nullable: заполняется только в RoomDetails.participants; в поиске/
  /// директории нет комнатного контекста, а старый сервер поля не пришлёт
  /// — клиент трактует null как обычного пользователя.
  _i3.ParticipantKind? participantKind;

  /// Returns a shallow copy of this [RoomParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomParticipant copyWith({
    int? messengerUserId,
    String? matrixUserId,
    String? displayName,
    String? avatarUrl,
    _i2.RoomMemberRole? role,
    String? username,
    DateTime? writeBannedUntil,
    _i3.ParticipantKind? participantKind,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomParticipant',
      'messengerUserId': messengerUserId,
      'matrixUserId': matrixUserId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role.toJson(),
      if (username != null) 'username': username,
      if (writeBannedUntil != null)
        'writeBannedUntil': writeBannedUntil?.toJson(),
      if (participantKind != null) 'participantKind': participantKind?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomParticipantImpl extends RoomParticipant {
  _RoomParticipantImpl({
    required int messengerUserId,
    required String matrixUserId,
    String? displayName,
    String? avatarUrl,
    required _i2.RoomMemberRole role,
    String? username,
    DateTime? writeBannedUntil,
    _i3.ParticipantKind? participantKind,
  }) : super._(
         messengerUserId: messengerUserId,
         matrixUserId: matrixUserId,
         displayName: displayName,
         avatarUrl: avatarUrl,
         role: role,
         username: username,
         writeBannedUntil: writeBannedUntil,
         participantKind: participantKind,
       );

  /// Returns a shallow copy of this [RoomParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomParticipant copyWith({
    int? messengerUserId,
    String? matrixUserId,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    _i2.RoomMemberRole? role,
    Object? username = _Undefined,
    Object? writeBannedUntil = _Undefined,
    Object? participantKind = _Undefined,
  }) {
    return RoomParticipant(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      matrixUserId: matrixUserId ?? this.matrixUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
      username: username is String? ? username : this.username,
      writeBannedUntil: writeBannedUntil is DateTime?
          ? writeBannedUntil
          : this.writeBannedUntil,
      participantKind: participantKind is _i3.ParticipantKind?
          ? participantKind
          : this.participantKind,
    );
  }
}
