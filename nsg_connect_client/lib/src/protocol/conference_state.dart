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
import 'conference_member.dart' as _i2;
import 'package:nsg_connect_client/src/protocol/protocol.dart' as _i3;

/// **TASK51** — снапшот активной конференции комнаты: ответ
/// `joinConference` / `getConference`. Поздний участник получает
/// АКТУАЛЬНЫЙ состав одним запросом (§3A.2) и строит pairwise-сессии
/// с каждым из [members]. Transient — источник правды в таблицах
/// `conferences` / `conference_participants`.
abstract class ConferenceState implements _i1.SerializableModel {
  ConferenceState._({
    required this.confId,
    required this.roomId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConferenceState({
    required String confId,
    required int roomId,
    required List<_i2.ConferenceMember> members,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConferenceStateImpl;

  factory ConferenceState.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConferenceState(
      confId: jsonSerialization['confId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      members: _i3.Protocol().deserialize<List<_i2.ConferenceMember>>(
        jsonSerialization['members'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Публичный id конференции (`conf_<32 hex>`) — коррелятор mesh-звонка
  /// (iOS CallKit-коллапс: все push-и конференции схлопываются в один
  /// входящий с callId = confId, §3A п.6).
  String confId;

  int roomId;

  /// Полный текущий состав, отсортирован по joinedAt (старшие первыми).
  /// Caller включён.
  List<_i2.ConferenceMember> members;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConferenceState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConferenceState copyWith({
    String? confId,
    int? roomId,
    List<_i2.ConferenceMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConferenceState',
      'confId': confId,
      'roomId': roomId,
      'members': members.toJson(valueToJson: (v) => v.toJson()),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ConferenceStateImpl extends ConferenceState {
  _ConferenceStateImpl({
    required String confId,
    required int roomId,
    required List<_i2.ConferenceMember> members,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         confId: confId,
         roomId: roomId,
         members: members,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConferenceState]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConferenceState copyWith({
    String? confId,
    int? roomId,
    List<_i2.ConferenceMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConferenceState(
      confId: confId ?? this.confId,
      roomId: roomId ?? this.roomId,
      members: members ?? this.members.map((e0) => e0.copyWith()).toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
