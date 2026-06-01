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

/// Тип Matrix-комнаты с точки зрения NSG-семантики (§9 ТЗ).
/// `productRoom`/`customerRoom` — комнаты, привязанные к продуктовой сущности
/// (см. TASK13 getOrCreateProductRoom).
enum RoomType implements _i1.SerializableModel {
  direct,
  group,
  team,
  support,
  family,
  internal,
  system,
  productRoom,
  customerRoom;

  static RoomType fromJson(String name) {
    switch (name) {
      case 'direct':
        return RoomType.direct;
      case 'group':
        return RoomType.group;
      case 'team':
        return RoomType.team;
      case 'support':
        return RoomType.support;
      case 'family':
        return RoomType.family;
      case 'internal':
        return RoomType.internal;
      case 'system':
        return RoomType.system;
      case 'productRoom':
        return RoomType.productRoom;
      case 'customerRoom':
        return RoomType.customerRoom;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "RoomType"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
