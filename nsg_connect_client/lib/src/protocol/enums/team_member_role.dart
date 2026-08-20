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

/// **Роль в команде** ([TeamMember]).
///
/// `owner` управляет составом, `member` — просто состоит. Для оргкоманд
/// (`TeamKind.org`) роль пока декоративна: состав правит админ платформы,
/// а не владелец команды. Поле заведено сразу, потому что своими
/// командами (`private`, этап 3) распоряжается именно их создатель, и
/// добавлять колонку в непустую таблицу дороже, чем предусмотреть её.
///
/// Не путать с `RoomMemberRole` (роль в конкретной комнате) и с
/// [SupportTeamRole] (роль в операторской команде поддержки).
enum TeamMemberRole implements _i1.SerializableModel {
  owner,
  member;

  static TeamMemberRole fromJson(String name) {
    switch (name) {
      case 'owner':
        return TeamMemberRole.owner;
      case 'member':
        return TeamMemberRole.member;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "TeamMemberRole"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
