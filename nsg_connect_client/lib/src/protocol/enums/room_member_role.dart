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

/// Роль члена комнаты с точки зрения SDK-визуализации (значки рядом
/// с именем, доступность кнопок «удалить участника» и пр.). На MVP
/// TASK13 различаются только `owner` (создатель — может всё) /
/// `admin` (может приглашать) / `member` (обычный участник).
///
/// Расширяется в TASK29 (moderation) — `moderator`, `read_only`, и пр.
///
/// **Отличается от `RoomMembership.role: String`** — то поле сырая
/// строка, заполняемая при создании; этот enum — производное значение
/// для DTO-уровня. Маппинг строки → enum в `RoomService._roleOf`.
enum RoomMemberRole implements _i1.SerializableModel {
  owner,
  admin,
  member;

  static RoomMemberRole fromJson(String name) {
    switch (name) {
      case 'owner':
        return RoomMemberRole.owner;
      case 'admin':
        return RoomMemberRole.admin;
      case 'member':
        return RoomMemberRole.member;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RoomMemberRole"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
