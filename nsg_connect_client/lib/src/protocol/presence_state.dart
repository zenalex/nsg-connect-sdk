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

/// Presence-состояние пользователя для PushRoutingService
/// foreground-suppression (TASK20) и для отображения "online".
///
/// Хранится в `session.caches.global` под ключом `presence:<messengerUserId>`
/// с TTL 60 сек. Истёкший TTL = клиент офлайн.
abstract class PresenceState implements _i1.SerializableModel {
  PresenceState._({
    required this.messengerUserId,
    this.currentRoomId,
    required this.foreground,
    required this.lastSeenAt,
  });

  factory PresenceState({
    required int messengerUserId,
    int? currentRoomId,
    required bool foreground,
    required DateTime lastSeenAt,
  }) = _PresenceStateImpl;

  factory PresenceState.fromJson(Map<String, dynamic> jsonSerialization) {
    return PresenceState(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      currentRoomId: jsonSerialization['currentRoomId'] as int?,
      foreground: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['foreground'],
      ),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  int messengerUserId;

  /// Если задан — пользователь сейчас открыл этот ChatScreen.
  /// PushRoutingService при создании уведомления для этой комнаты
  /// сравнивает roomId с currentRoomId и при совпадении suppress-ит push.
  int? currentRoomId;

  /// App в foreground (true) или background (false). Заполняется
  /// SDK через `WidgetsBindingObserver`.
  bool foreground;

  DateTime lastSeenAt;

  /// Returns a shallow copy of this [PresenceState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PresenceState copyWith({
    int? messengerUserId,
    int? currentRoomId,
    bool? foreground,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PresenceState',
      'messengerUserId': messengerUserId,
      if (currentRoomId != null) 'currentRoomId': currentRoomId,
      'foreground': foreground,
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PresenceStateImpl extends PresenceState {
  _PresenceStateImpl({
    required int messengerUserId,
    int? currentRoomId,
    required bool foreground,
    required DateTime lastSeenAt,
  }) : super._(
         messengerUserId: messengerUserId,
         currentRoomId: currentRoomId,
         foreground: foreground,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [PresenceState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PresenceState copyWith({
    int? messengerUserId,
    Object? currentRoomId = _Undefined,
    bool? foreground,
    DateTime? lastSeenAt,
  }) {
    return PresenceState(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      currentRoomId: currentRoomId is int? ? currentRoomId : this.currentRoomId,
      foreground: foreground ?? this.foreground,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
