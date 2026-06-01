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

/// Платформа устройства, на котором работает SDK (TASK20 §8).
/// Используется в `DeviceRegistration` для маршрутизации push через
/// соответствующий Apple/Google/WebPush channel. На MVP `desktop` —
/// задел (push на macOS/Linux/Windows desktop через `firebase_messaging`
/// или native — TASK20-Phase2 / customer-specific).
enum DevicePlatform implements _i1.SerializableModel {
  ios,
  android,
  web,
  desktop;

  static DevicePlatform fromJson(String name) {
    switch (name) {
      case 'ios':
        return DevicePlatform.ios;
      case 'android':
        return DevicePlatform.android;
      case 'web':
        return DevicePlatform.web;
      case 'desktop':
        return DevicePlatform.desktop;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DevicePlatform"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
