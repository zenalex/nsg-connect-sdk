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

/// **Главная защита этапа 3** (`DESIGN_TEAMS_AND_CONTACT_SHARING.md`,
/// §4): в свою команду (`TeamKind.private`) пытались добавить человека,
/// которого добавляющий не знает — нет ни общей комнаты, ни общей
/// команды, ни ручного контакта.
///
/// Без этого правила намеренное ограничение поиска по email не стоит
/// ничего: создал команду, вписал кого хотел, получил их в списке людей.
///
/// Тип отдельный и сериализуемый намеренно. Общий 500 клиент показал бы
/// как «что-то сломалось», и человек жал бы кнопку повторно; здесь же
/// надо сказать ровно одно: сначала познакомьтесь — общий чат, общая
/// команда или добавление в контакты.
abstract class TeamPeerUnknownException
    implements _i1.SerializableException, _i1.SerializableModel {
  TeamPeerUnknownException._({required this.messengerUserId});

  factory TeamPeerUnknownException({required int messengerUserId}) =
      _TeamPeerUnknownExceptionImpl;

  factory TeamPeerUnknownException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TeamPeerUnknownException(
      messengerUserId: jsonSerialization['messengerUserId'] as int,
    );
  }

  int messengerUserId;

  /// Returns a shallow copy of this [TeamPeerUnknownException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamPeerUnknownException copyWith({int? messengerUserId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamPeerUnknownException',
      'messengerUserId': messengerUserId,
    };
  }

  @override
  String toString() {
    return 'TeamPeerUnknownException(messengerUserId: $messengerUserId)';
  }
}

class _TeamPeerUnknownExceptionImpl extends TeamPeerUnknownException {
  _TeamPeerUnknownExceptionImpl({required int messengerUserId})
    : super._(messengerUserId: messengerUserId);

  /// Returns a shallow copy of this [TeamPeerUnknownException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamPeerUnknownException copyWith({int? messengerUserId}) {
    return TeamPeerUnknownException(
      messengerUserId: messengerUserId ?? this.messengerUserId,
    );
  }
}
