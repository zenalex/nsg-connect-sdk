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

/// **TASK52 итер.2 (чанк 3)**: тип эфемерного trust-токена — задаёт
/// политику (TTL, число использований) и источник итоговой ContactLink.
///   * qr — показан на экране визитки, сканируется камерой (одноразовый,
///     короткий TTL);
///   * nearby — обмен через BLE «Рядом» (одноразовый, короткий TTL);
///   * invite — share-ссылка (TASK65 1а): многоразовый с потолком, TTL ~30д.
enum TrustTokenKind implements _i1.SerializableModel {
  qr,
  nearby,
  invite;

  static TrustTokenKind fromJson(String name) {
    switch (name) {
      case 'qr':
        return TrustTokenKind.qr;
      case 'nearby':
        return TrustTokenKind.nearby;
      case 'invite':
        return TrustTokenKind.invite;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "TrustTokenKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
