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

/// **TASK80 итерация 1** — кто сейчас показывает экран в конференции.
/// Строка существует = показ идёт; конец показа (stop / выход докладчика /
/// зачистка призрака / смерть конференции) = DELETE строки.
///
/// **Почему арбитраж на СЕРВЕРЕ, а не в SDK.** MVP-правило «один
/// докладчик одновременно» при клиентском арбитраже дырявое ровно так
/// же, как был бы дырявым лимит участников: двое, нажавшие «Показать
/// экран» одновременно, читают один и тот же (ещё пустой) ростер, оба
/// считают себя докладчиком и начинают слать видео — это не «явный
/// отказ», а молчаливая борьба за поток, которую спека запрещает.
/// Unique-индекс по `conferenceId` делает захват атомарным: INSERT
/// выигрывает ровно один, проигравший получает
/// `ScreenShareBusyException` с id текущего докладчика и показывает
/// «сейчас показывает X». Тот же приём, что `conference_room_unique`
/// для «одна конференция на комнату».
///
/// Cascade от `conferences`: конференция умерла — показ тоже (никаких
/// висящих «идёт показ» после teardown-а).
abstract class ConferenceScreenShare implements _i1.SerializableModel {
  ConferenceScreenShare._({
    this.id,
    required this.conferenceId,
    required this.messengerUserId,
    required this.partyId,
    required this.startedAt,
  });

  factory ConferenceScreenShare({
    int? id,
    required int conferenceId,
    required int messengerUserId,
    required String partyId,
    required DateTime startedAt,
  }) = _ConferenceScreenShareImpl;

  factory ConferenceScreenShare.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConferenceScreenShare(
      id: jsonSerialization['id'] as int?,
      conferenceId: jsonSerialization['conferenceId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      partyId: jsonSerialization['partyId'] as String,
      startedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int conferenceId;

  /// Докладчик. Cascade от `messenger_users` — как у участников.
  int messengerUserId;

  /// Устройство докладчика (тот же per-device uuid, что `party_id`
  /// pairwise-сигналинга). Нужен, чтобы отличить «тот же человек с
  /// другого устройства» — такой показ считается протухшим и
  /// снимается вместе со старой pairwise-идентичностью.
  String partyId;

  /// Момент начала показа — для UI («показывает N мин») и для
  /// диагностики забытого показа.
  DateTime startedAt;

  /// Returns a shallow copy of this [ConferenceScreenShare]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConferenceScreenShare copyWith({
    int? id,
    int? conferenceId,
    int? messengerUserId,
    String? partyId,
    DateTime? startedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConferenceScreenShare',
      if (id != null) 'id': id,
      'conferenceId': conferenceId,
      'messengerUserId': messengerUserId,
      'partyId': partyId,
      'startedAt': startedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConferenceScreenShareImpl extends ConferenceScreenShare {
  _ConferenceScreenShareImpl({
    int? id,
    required int conferenceId,
    required int messengerUserId,
    required String partyId,
    required DateTime startedAt,
  }) : super._(
         id: id,
         conferenceId: conferenceId,
         messengerUserId: messengerUserId,
         partyId: partyId,
         startedAt: startedAt,
       );

  /// Returns a shallow copy of this [ConferenceScreenShare]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConferenceScreenShare copyWith({
    Object? id = _Undefined,
    int? conferenceId,
    int? messengerUserId,
    String? partyId,
    DateTime? startedAt,
  }) {
    return ConferenceScreenShare(
      id: id is int? ? id : this.id,
      conferenceId: conferenceId ?? this.conferenceId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      partyId: partyId ?? this.partyId,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
