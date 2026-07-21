import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_rustore_push/flutter_rustore_push.dart';
import 'package:google_api_availability/google_api_availability.dart';

/// **TASK61**: какой push-провайдер использовать на этом устройстве.
enum ResolvedPushService {
  /// Firebase Cloud Messaging — дефолт (iOS всегда; Android с Google
  /// Play Services).
  fcm,

  /// RuStore Push (VKPNS) — Android без GMS, с установленным и
  /// работоспособным RuStore.
  rustore,
}

/// **TASK61**: выбор push-провайдера на старте приложения.
///
/// Цепочка (только Android; iOS/прочее → всегда [ResolvedPushService.fcm],
/// как раньше):
///   1. Google Play Services доступны (или чинятся обновлением) → `fcm`.
///   2. Иначе, если RuStore на устройстве может доставлять пуши
///      (`RustorePushClient.available()`: установлен + разрешён фон +
///      пользователь авторизован) → `rustore`.
///   3. Иначе → `fcm` (прежнее поведение: провайдер поднимется, токена
///      скорее всего не будет, приложение живёт на /sync).
///
/// Выбор пере-оценивается на каждом старте: если у пользователя появились
/// GMS (или наоборот), регистрация уедет на нового провайдера, а старая
/// запись `device_registrations` отомрёт по stale-cleanup (60 дней) либо
/// снимется сервером на первом невалидном пуше.
Future<ResolvedPushService> resolvePushService() async {
  if (kIsWeb || !Platform.isAndroid) return ResolvedPushService.fcm;

  // (1) GMS-детект. `serviceUpdating` / `serviceVersionUpdateRequired` —
  // GMS есть и FCM скорее всего заработает (после обновления) → fcm.
  try {
    final gms = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability()
        .timeout(const Duration(seconds: 5));
    switch (gms) {
      case GooglePlayServicesAvailability.success:
      case GooglePlayServicesAvailability.serviceUpdating:
      case GooglePlayServicesAvailability.serviceVersionUpdateRequired:
        return ResolvedPushService.fcm;
      default:
        break; // serviceMissing / serviceDisabled / serviceInvalid / unknown
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[resolvePushService] GMS check failed: $e');
    }
    // Детект не удался — не делаем вывод об отсутствии GMS, пробуем
    // RuStore ниже; его отказ вернёт fcm-fallback.
  }

  // (2) RuStore-детект.
  try {
    final available = await RustorePushClient.available().timeout(
      const Duration(seconds: 5),
    );
    if (available) return ResolvedPushService.rustore;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[resolvePushService] RuStore check failed: $e');
    }
  }

  // (3) Fallback — прежнее поведение.
  return ResolvedPushService.fcm;
}
