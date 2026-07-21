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

/// Backend push-провайдер, через который доставляется уведомление
/// на устройство (TASK20 §8). Determines выбор adapter-а в
/// `PushRoutingService` (TASK20-Phase2):
///   * `fcm` — Firebase Cloud Messaging (Android, iOS через FCM SDK,
///     Web).
///   * `apns` — Apple Push Notification Service напрямую (только iOS,
///     для customer-app которые не используют Firebase).
///   * `webpush` — W3C Web Push API (для Chatista web).
///   * `voip` — Apple PushKit VoIP-push (TASK46, звонки в фоне). Отдельный
///     APNs-канал/топик `<bundleId>.voip`: будит убитый app и даёт
///     показать CallKit-входящий вовремя. PushKit-токен отличается от
///     обычного APNs/FCM-токена → регистрируется отдельным
///     `DeviceRegistration` с этим `pushService`. Доставляется напрямую в
///     APNs через `ApnsVoipPushAdapter` (мимо FCM).
///   * `rustore` — RuStore Push (VKPNS) для Android-устройств без Google
///     Play Services (TASK61). Клиент выбирает провайдера на старте
///     (GMS → fcm, иначе RuStore); сервер доставляет через
///     `RuStorePushAdapter` (VKPNS `messages:send`, FCM-совместимый
///     формат, авторизация — сервисный токен проекта RuStore Console).
enum PushService implements _i1.SerializableModel {
  fcm,
  apns,
  webpush,
  voip,
  rustore;

  static PushService fromJson(String name) {
    switch (name) {
      case 'fcm':
        return PushService.fcm;
      case 'apns':
        return PushService.apns;
      case 'webpush':
        return PushService.webpush;
      case 'voip':
        return PushService.voip;
      case 'rustore':
        return PushService.rustore;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "PushService"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
