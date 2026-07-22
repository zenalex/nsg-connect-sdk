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

/// Issue #54: причина реджекта вложения на аплоаде. Нужна клиенту,
/// чтобы показать ВНЯТНЫЙ текст вместо голого красного «!» — до этого
/// валидация кидала `ArgumentError`, Serverpod отдавал generic 500,
/// и SDK не мог отличить «не тот тип» от «сеть отвалилась» (и, что
/// хуже, ретраил permanent-ошибку).
///
///   * unsupportedType — MIME не в whitelist (`_validateMime`);
///   * blockedExtension — расширение в blacklist, executable/installer
///     (`_validateExtension`) — реджект даже при валидном MIME;
///   * tooLarge — превышен size cap (`_validateSize`); в этом случае
///     заполнены `actualBytes` / `maxBytes`.
enum AttachmentRejectReason implements _i1.SerializableModel {
  unsupportedType,
  blockedExtension,
  tooLarge;

  static AttachmentRejectReason fromJson(String name) {
    switch (name) {
      case 'unsupportedType':
        return AttachmentRejectReason.unsupportedType;
      case 'blockedExtension':
        return AttachmentRejectReason.blockedExtension;
      case 'tooLarge':
        return AttachmentRejectReason.tooLarge;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AttachmentRejectReason"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
