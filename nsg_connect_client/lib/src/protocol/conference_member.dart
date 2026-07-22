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

/// **TASK51** — участник конференции в wire-DTO ([ConferenceState] и
/// событие `conferenceUpdated`). Transient (без таблицы): проекция
/// [ConferenceParticipant] без внутренних id/lastSeenAt — клиенту для
/// построения pairwise-сессий нужны ровно эти три поля (§3A.2).
abstract class ConferenceMember implements _i1.SerializableModel {
  ConferenceMember._({
    required this.messengerUserId,
    required this.partyId,
    required this.joinedAt,
  });

  factory ConferenceMember({
    required int messengerUserId,
    required String partyId,
    required DateTime joinedAt,
  }) = _ConferenceMemberImpl;

  factory ConferenceMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConferenceMember(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      partyId: jsonSerialization['partyId'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  int messengerUserId;

  /// Per-device идентификатор для pairwise-сигналинга (TASK46 party_id).
  String partyId;

  /// Порядок вступления — стабильная сортировка состава (кто раньше
  /// вошёл, тот раньше в списке) и tie-break договорённостей SDK
  /// (например, кто offer-ит в паре: старший joinedAt).
  DateTime joinedAt;

  /// Returns a shallow copy of this [ConferenceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConferenceMember copyWith({
    int? messengerUserId,
    String? partyId,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConferenceMember',
      'messengerUserId': messengerUserId,
      'partyId': partyId,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ConferenceMemberImpl extends ConferenceMember {
  _ConferenceMemberImpl({
    required int messengerUserId,
    required String partyId,
    required DateTime joinedAt,
  }) : super._(
         messengerUserId: messengerUserId,
         partyId: partyId,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [ConferenceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConferenceMember copyWith({
    int? messengerUserId,
    String? partyId,
    DateTime? joinedAt,
  }) {
    return ConferenceMember(
      messengerUserId: messengerUserId ?? this.messengerUserId,
      partyId: partyId ?? this.partyId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
