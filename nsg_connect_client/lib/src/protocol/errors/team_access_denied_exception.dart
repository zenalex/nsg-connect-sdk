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

/// Своей командой (`TeamKind.private`) распоряжается её владелец:
/// правка состава и роспуск чужой команды отклонены.
///
/// Сериализуемый тип, а не общий отказ, потому что причина не техническая
/// — интерфейс обязан сказать про право, а не показать «ошибка сервера».
/// Тем же исключением отвечаем на попытку выкинуть из команды её
/// владельца: без владельца команду стало бы некому ни править, ни
/// распустить.
abstract class TeamAccessDeniedException
    implements _i1.SerializableException, _i1.SerializableModel {
  TeamAccessDeniedException._({required this.teamId});

  factory TeamAccessDeniedException({required int teamId}) =
      _TeamAccessDeniedExceptionImpl;

  factory TeamAccessDeniedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TeamAccessDeniedException(
      teamId: jsonSerialization['teamId'] as int,
    );
  }

  int teamId;

  /// Returns a shallow copy of this [TeamAccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamAccessDeniedException copyWith({int? teamId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamAccessDeniedException',
      'teamId': teamId,
    };
  }

  @override
  String toString() {
    return 'TeamAccessDeniedException(teamId: $teamId)';
  }
}

class _TeamAccessDeniedExceptionImpl extends TeamAccessDeniedException {
  _TeamAccessDeniedExceptionImpl({required int teamId})
    : super._(teamId: teamId);

  /// Returns a shallow copy of this [TeamAccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamAccessDeniedException copyWith({int? teamId}) {
    return TeamAccessDeniedException(teamId: teamId ?? this.teamId);
  }
}
