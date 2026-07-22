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

/// **TASK51 итерация 1** — участник активной конференции (строка
/// состава). Живёт только пока конференция активна (Cascade от
/// `conferences`); история — не здесь.
abstract class ConferenceParticipant implements _i1.SerializableModel {
  ConferenceParticipant._({
    this.id,
    required this.conferenceId,
    required this.messengerUserId,
    required this.partyId,
    required this.joinedAt,
    required this.lastSeenAt,
  });

  factory ConferenceParticipant({
    int? id,
    required int conferenceId,
    required int messengerUserId,
    required String partyId,
    required DateTime joinedAt,
    required DateTime lastSeenAt,
  }) = _ConferenceParticipantImpl;

  factory ConferenceParticipant.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConferenceParticipant(
      id: jsonSerialization['id'] as int?,
      conferenceId: jsonSerialization['conferenceId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      partyId: jsonSerialization['partyId'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int conferenceId;

  int messengerUserId;

  /// Идентификатор устройства участника (тот же per-device uuid, что
  /// `party_id` в pairwise-сигналинге TASK46) — по паре
  /// (messengerUserId, partyId) остальные строят pairwise-сессии.
  /// Повторный join с ДРУГИМ partyId (другое устройство) заменяет
  /// строку: MVP-инвариант «один юзер — одно устройство в конференции»
  /// (см. unique-индекс). Мультидевайс-участие одного юзера — вне MVP.
  String partyId;

  DateTime joinedAt;

  /// Heartbeat зачистки «призраков»: продлевается идемпотентным
  /// повторным `joinConference` (SDK обязан звать его периодически,
  /// см. док RPC). `lastSeenAt` старше TTL → участник считается
  /// крашнувшимся и выпиливается lazy-prune-ом (join/get/leave) или
  /// свипером [ConferenceSweepFutureCall].
  DateTime lastSeenAt;

  /// Returns a shallow copy of this [ConferenceParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConferenceParticipant copyWith({
    int? id,
    int? conferenceId,
    int? messengerUserId,
    String? partyId,
    DateTime? joinedAt,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConferenceParticipant',
      if (id != null) 'id': id,
      'conferenceId': conferenceId,
      'messengerUserId': messengerUserId,
      'partyId': partyId,
      'joinedAt': joinedAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConferenceParticipantImpl extends ConferenceParticipant {
  _ConferenceParticipantImpl({
    int? id,
    required int conferenceId,
    required int messengerUserId,
    required String partyId,
    required DateTime joinedAt,
    required DateTime lastSeenAt,
  }) : super._(
         id: id,
         conferenceId: conferenceId,
         messengerUserId: messengerUserId,
         partyId: partyId,
         joinedAt: joinedAt,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [ConferenceParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConferenceParticipant copyWith({
    Object? id = _Undefined,
    int? conferenceId,
    int? messengerUserId,
    String? partyId,
    DateTime? joinedAt,
    DateTime? lastSeenAt,
  }) {
    return ConferenceParticipant(
      id: id is int? ? id : this.id,
      conferenceId: conferenceId ?? this.conferenceId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      partyId: partyId ?? this.partyId,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
