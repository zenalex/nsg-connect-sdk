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

/// **TASK80 итерация 1** — экран уже показывает другой участник.
/// MVP-правило «один докладчик одновременно»: попытка второго — ЯВНЫЙ
/// типизированный отказ, а не молчаливая борьба за поток (спека, п.2
/// состава работ). SDK по нему показывает «Сейчас показывает {имя}».
///
/// Отдельный тип (не [RoomUnavailableException] — комната и конференция
/// доступны; не [RateLimitExceededException] — «повторить позже» тут
/// бессмысленно, ждать надо не таймера, а докладчика).
abstract class ScreenShareBusyException
    implements _i1.SerializableException, _i1.SerializableModel {
  ScreenShareBusyException._({required this.presenterMessengerUserId});

  factory ScreenShareBusyException({required int presenterMessengerUserId}) =
      _ScreenShareBusyExceptionImpl;

  factory ScreenShareBusyException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ScreenShareBusyException(
      presenterMessengerUserId:
          jsonSerialization['presenterMessengerUserId'] as int,
    );
  }

  /// Кто сейчас показывает — SDK резолвит имя из состава комнаты
  /// (как в остальном конференц-UI).
  int presenterMessengerUserId;

  /// Returns a shallow copy of this [ScreenShareBusyException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ScreenShareBusyException copyWith({int? presenterMessengerUserId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScreenShareBusyException',
      'presenterMessengerUserId': presenterMessengerUserId,
    };
  }

  @override
  String toString() {
    return 'ScreenShareBusyException(presenterMessengerUserId: $presenterMessengerUserId)';
  }
}

class _ScreenShareBusyExceptionImpl extends ScreenShareBusyException {
  _ScreenShareBusyExceptionImpl({required int presenterMessengerUserId})
    : super._(presenterMessengerUserId: presenterMessengerUserId);

  /// Returns a shallow copy of this [ScreenShareBusyException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ScreenShareBusyException copyWith({int? presenterMessengerUserId}) {
    return ScreenShareBusyException(
      presenterMessengerUserId:
          presenterMessengerUserId ?? this.presenterMessengerUserId,
    );
  }
}
