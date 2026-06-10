import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// **TASK20-Phase2 Chunk 5**: production [PushTokenProvider] поверх
/// `firebase_messaging` (variant (a) — Firebase wraps APNs on iOS).
///
/// **Host-app prerequisites** (НЕ делаем здесь — customer-specific
/// configuration):
///   1. `Firebase.initializeApp(options: DefaultFirebaseOptions.
///      currentPlatform)` в `main()` ДО `MessengerRuntime.init`.
///      Файлы `google-services.json` (Android) +
///      `GoogleService-Info.plist` (iOS) положены в Flutter project
///      per platform-folder.
///   2. iOS Xcode: Push Notifications + Background Modes (Remote
///      notifications) capabilities.
///   3. Bundle ID совпадает в Xcode + Apple Developer + Firebase
///      Console + APNs Auth Key (.p8) загружен в Firebase Console
///      (server-side нашему path этот key не нужен).
///
/// **Permission**: на iOS `requestPermission()` показывает system
/// prompt. На Android (API 33+) — POST_NOTIFICATIONS permission. Мы
/// запрашиваем automatically в `create()`; customer хочет
/// gating-by-onboarding-step → провайдер subclass-уется.
class FirebasePushTokenProvider implements PushTokenProvider {
  FirebasePushTokenProvider._({required this.deviceInfo});

  /// Snapshotted DeviceInfo — не меняется в lifecycle session-а
  /// (новая session при app restart).
  final DeviceInfo deviceInfo;

  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();
  StreamSubscription<String>? _refreshSub;
  bool _disposed = false;

  /// **Async factory**:
  ///   1. `WidgetsFlutterBinding.ensureInitialized()` (idempotent).
  ///   2. `FirebaseMessaging.requestPermission()` (iOS prompt; Android
  ///      no-op pre-API-33).
  ///   3. Resolve [DeviceInfo] (platform/locale/version/model).
  ///   4. Subscribe to `onTokenRefresh` для emit на rotation.
  ///   5. Initial `getToken()` emit (next-tick, после listener attach).
  static Future<FirebasePushTokenProvider> create() async {
    WidgetsFlutterBinding.ensureInitialized();
    final fcm = FirebaseMessaging.instance;
    // iOS prompt; Android: alert/badge/sound granted by default.
    await fcm.requestPermission(alert: true, badge: true, sound: true);
    final info = await _resolveDeviceInfo();
    final provider = FirebasePushTokenProvider._(deviceInfo: info);

    // onTokenRefresh — emit на rotation (FCM periodic cycle / reinstall).
    provider._refreshSub = fcm.onTokenRefresh.listen(
      (token) {
        if (!provider._disposed) provider._tokenController.add(token);
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode)
          debugPrint('[FirebasePushTokenProvider] onTokenRefresh error: $e');
      },
    );

    // Initial token — emit в next-tick чтобы listener-ы в
    // MessengerRuntime.init успели subscribe.
    scheduleMicrotask(() async {
      if (provider._disposed) return;
      try {
        // iOS race: FCM `getToken()` бросает `apns-token-not-set`, если
        // APNS-токен ещё не доехал. На physical-device первый launch
        // APNS приходит через сотни ms после grant permission. Делаем
        // polling до 10s; на Android — no-op (getAPNSToken возвращает
        // null moментально).
        if (!kIsWeb && Platform.isIOS) {
          await _waitForApnsToken(fcm);
        }
        final token = await fcm.getToken();
        if (token != null && !provider._disposed) {
          provider._tokenController.add(token);
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[FirebasePushTokenProvider] initial getToken failed: $e\n$st',
          );
        }
      }
    });

    return provider;
  }

  /// iOS-only: poll `getAPNSToken()` до 30 секунд (60 × 500ms). На
  /// physical-device после grant permission APNS-токен обычно приходит
  /// 1-3s, но cold start / медленная сеть могут занять до 30s. Без
  /// этого FCM `getToken()` бросает `apns-token-not-set`.
  ///
  /// Если timeout — typical blockers:
  ///   1. Wi-Fi блокирует APNs (port 5223 to push.apple.com).
  ///      Workaround: cellular.
  ///   2. iPhone не зарегистрирован в `application.registerForRemote
  ///      Notifications()` — нет push capability / нет entitlement.
  ///   3. APNs Auth Key в Firebase Console не загружен (только
  ///      receive-side это НЕ ломает, но send не будет работать).
  static Future<void> _waitForApnsToken(FirebaseMessaging fcm) async {
    final start = DateTime.now();
    for (var attempt = 0; attempt < 60; attempt++) {
      try {
        final apns = await fcm.getAPNSToken();
        if (apns != null) {
          final elapsed = DateTime.now().difference(start).inMilliseconds;
          if (kDebugMode) {
            debugPrint(
              '[FirebasePushTokenProvider] APNS token ready in ${elapsed}ms.',
            );
          }
          return;
        }
      } catch (_) {
        // ignore — повторим
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (kDebugMode) {
      debugPrint(
        '[FirebasePushTokenProvider] APNS token not available after 30s; '
        'getToken() likely failed. Check: (1) Push capability + entitlement, '
        '(2) Wi-Fi блокирует port 5223 (try cellular), (3) APNs Auth Key '
        'в Firebase Console.',
      );
    }
  }

  @override
  Future<DeviceInfo?> getDeviceInfo() async => deviceInfo;

  @override
  Future<String?> getCurrentToken() async {
    if (_disposed) return null;
    try {
      // Hard timeout: getToken() на iOS без APNS-токена может висеть
      // неопределённо долго (internal retry в FCM SDK). Возвращаем null
      // быстро, чтобы host-app смог поднять UI без push-токена. Background-
      // microtask в create() продолжит ждать APNs + emit-нет token через
      // onTokenRefresh когда APNs реально подъедет.
      return await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              '[FirebasePushTokenProvider] getCurrentToken timeout (2s); '
              'returning null. tokenStream() ещё может emit-нуть позже.',
            );
          }
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode)
        debugPrint('[FirebasePushTokenProvider] getCurrentToken failed: $e');
      return null;
    }
  }

  @override
  Stream<String?> tokenStream() => _tokenController.stream;

  /// Closes subscription + token stream. Idempotent — second call no-op.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (!_tokenController.isClosed) {
      await _tokenController.close();
    }
  }

  // ─────── Internals ───────

  static Future<DeviceInfo> _resolveDeviceInfo() async {
    final pkg = await PackageInfo.fromPlatform();
    final appVersion = '${pkg.version}+${pkg.buildNumber}';
    final locale = PlatformDispatcher.instance.locale.toLanguageTag();

    final platform = _resolvePlatform();
    String? model;
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        // Web — no hardware identifier per privacy; null acceptable.
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        model = ios.utsname.machine; // e.g., 'iPhone15,2'
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        model = '${android.manufacturer} ${android.model}'.trim();
      }
      // Desktop платформы (macos / linux / windows) — push на MVP не
      // supported (no firebase_messaging plugin). model оставляем null.
    } catch (_) {
      // device_info_plus throws на unsupported platforms — null OK.
    }

    return DeviceInfo(
      platform: platform,
      // Variant (a): always FCM, даже на iOS (Firebase wraps APNs).
      pushService: PushService.fcm,
      locale: locale,
      appVersion: appVersion,
      deviceModel: model,
    );
  }

  static DevicePlatform _resolvePlatform() {
    if (kIsWeb) return DevicePlatform.web;
    if (Platform.isIOS) return DevicePlatform.ios;
    if (Platform.isAndroid) return DevicePlatform.android;
    // DevicePlatform enum (server-side) сейчас покрывает только ios /
    // android / web — desktop платформы push не support-ируются на
    // MVP, fallback на android чтобы NotificationChannel получился
    // (на самом деле desktop сюда не дойдёт без Firebase plugin).
    return DevicePlatform.android;
  }
}

/// **TASK20-Phase2 Chunk 5**: top-level background message handler.
/// Flutter requires top-level (не closure) function for FCM bg
/// dispatch (isolate boundary).
///
/// **Использование**: host-app в `main()`:
/// ```dart
/// FirebaseMessaging.onBackgroundMessage(nsgMessengerBackgroundHandler);
/// ```
///
/// На MVP — no-op (notification UI Firebase сам показывает via OS).
/// Phase3 E2EE: расшифровать payload + show local notification.
@pragma('vm:entry-point')
Future<void> nsgMessengerBackgroundHandler(RemoteMessage message) async {
  // No-op MVP. Phase3: decrypt E2EE payload + show local notification.
  // Без этого handler-а Firebase всё равно показывает notification
  // (если payload содержит `notification` field, который мы send-аем
  // в FcmPushAdapter._buildFcmMessage).
  if (kDebugMode)
    debugPrint(
      '[nsgMessengerBackgroundHandler] received: ${message.messageId}',
    );
}
