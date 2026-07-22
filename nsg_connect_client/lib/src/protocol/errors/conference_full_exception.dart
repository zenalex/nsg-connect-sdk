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

/// **TASK51 §3A.5** — конференция полна: join сверх серверного лимита
/// участников mesh. Лимит — гейт НА СЕРВЕРЕ (не только скрытие в UI):
/// mesh квадратичен по трафику/CPU, N+1-й участник деградирует звонок
/// ВСЕМ, поэтому отказ типизированный, а не строка.
///
/// Уже-участник конференции под лимит не подпадает: его повторный
/// join — идемпотентный keepalive и проходит всегда.
///
/// Отдельный тип (не RateLimitExceededException — тут нечего
/// «повторить позже», и не RoomUnavailableException — комната-то
/// доступна): SDK по типу показывает «Конференция заполнена (N)».
abstract class ConferenceFullException
    implements _i1.SerializableException, _i1.SerializableModel {
  ConferenceFullException._({required this.maxParticipants});

  factory ConferenceFullException({required int maxParticipants}) =
      _ConferenceFullExceptionImpl;

  factory ConferenceFullException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConferenceFullException(
      maxParticipants: jsonSerialization['maxParticipants'] as int,
    );
  }

  /// Действующий серверный лимит (default 4, env
  /// `CONFERENCE_MAX_PARTICIPANTS`) — для честного текста в UI.
  int maxParticipants;

  /// Returns a shallow copy of this [ConferenceFullException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConferenceFullException copyWith({int? maxParticipants});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConferenceFullException',
      'maxParticipants': maxParticipants,
    };
  }

  @override
  String toString() {
    return 'ConferenceFullException(maxParticipants: $maxParticipants)';
  }
}

class _ConferenceFullExceptionImpl extends ConferenceFullException {
  _ConferenceFullExceptionImpl({required int maxParticipants})
    : super._(maxParticipants: maxParticipants);

  /// Returns a shallow copy of this [ConferenceFullException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConferenceFullException copyWith({int? maxParticipants}) {
    return ConferenceFullException(
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }
}
