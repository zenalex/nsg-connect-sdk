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

/// **Atomic dissolveRoom**: partial failure при server-side dissolveRoom
/// — часть peers были kick-нуты, на одном из них Matrix HTTP упал
/// (network blip / 5xx / permission edge). Caller'у возвращается этот
/// typed exception с количеством успешно kicked, чтобы UI решил retry
/// (idempotent — already-not-member kick'и пропускаются на следующей
/// попытке).
///
/// Поля:
///   * `kicked` — сколько участников успешно удалены (Matrix kick + DB
///     row delete);
///   * `total` — сколько peers было всего (без caller-а);
///   * `cause` — первое сообщение об ошибке (для логов / диагностики;
///     UI обычно показывает «удалось N из M, попробуйте снова»).
abstract class RoomDissolvePartialException
    implements _i1.SerializableException, _i1.SerializableModel {
  RoomDissolvePartialException._({
    required this.kicked,
    required this.total,
    required this.cause,
  });

  factory RoomDissolvePartialException({
    required int kicked,
    required int total,
    required String cause,
  }) = _RoomDissolvePartialExceptionImpl;

  factory RoomDissolvePartialException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RoomDissolvePartialException(
      kicked: jsonSerialization['kicked'] as int,
      total: jsonSerialization['total'] as int,
      cause: jsonSerialization['cause'] as String,
    );
  }

  int kicked;

  int total;

  String cause;

  /// Returns a shallow copy of this [RoomDissolvePartialException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomDissolvePartialException copyWith({
    int? kicked,
    int? total,
    String? cause,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomDissolvePartialException',
      'kicked': kicked,
      'total': total,
      'cause': cause,
    };
  }

  @override
  String toString() {
    return 'RoomDissolvePartialException(kicked: $kicked, total: $total, cause: $cause)';
  }
}

class _RoomDissolvePartialExceptionImpl extends RoomDissolvePartialException {
  _RoomDissolvePartialExceptionImpl({
    required int kicked,
    required int total,
    required String cause,
  }) : super._(
         kicked: kicked,
         total: total,
         cause: cause,
       );

  /// Returns a shallow copy of this [RoomDissolvePartialException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomDissolvePartialException copyWith({
    int? kicked,
    int? total,
    String? cause,
  }) {
    return RoomDissolvePartialException(
      kicked: kicked ?? this.kicked,
      total: total ?? this.total,
      cause: cause ?? this.cause,
    );
  }
}
