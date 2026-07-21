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

/// **TASK52 итер.2**: откуда возникла trust-связь ContactLink.
///   * roomMate — backfill: участники существующей direct-комнаты;
///   * manual — «добавить в контакты» вручную;
///   * qr — обмен по QR-визитке (токен-handshake);
///   * nearby — обмен через BLE «Рядом» (токен-handshake);
///   * request — принята карточка-заявка (message-request);
///   * invite — переход по инвайт-ссылке (TASK65 фаза 1а, тот же
///     TrustTokenService, что qr/nearby, transport = share-ссылка);
///   * recommendation — принята интродукция по рекомендации (итер.4).
enum ContactLinkSource implements _i1.SerializableModel {
  roomMate,
  manual,
  qr,
  nearby,
  request,
  invite,
  recommendation;

  static ContactLinkSource fromJson(String name) {
    switch (name) {
      case 'roomMate':
        return ContactLinkSource.roomMate;
      case 'manual':
        return ContactLinkSource.manual;
      case 'qr':
        return ContactLinkSource.qr;
      case 'nearby':
        return ContactLinkSource.nearby;
      case 'request':
        return ContactLinkSource.request;
      case 'invite':
        return ContactLinkSource.invite;
      case 'recommendation':
        return ContactLinkSource.recommendation;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ContactLinkSource"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
