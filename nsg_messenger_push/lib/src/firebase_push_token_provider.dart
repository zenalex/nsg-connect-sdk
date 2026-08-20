import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'call_push.dart';
import 'call_push_presenter.dart';
import 'notification_channels.dart';
import 'push_status_resolver.dart';

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
/// prompt. На Android 13+ тот же вызов просит POST_NOTIFICATIONS —
/// проверено по коду плагина, там ровно `ActivityCompat.requestPermissions`
/// на `Manifest.permission.POST_NOTIFICATIONS`; до Android 13 разрешение
/// выдаётся при установке и диалога нет. Мы запрашиваем automatically в
/// `create()`; customer хочет gating-by-onboarding-step → провайдер
/// subclass-уется.
///
/// **Каналы уведомлений (этап 3 TASK_TITAN_PRODUCT_PUSH01 §4.1)**:
/// `create()` заводит их на Android — см. [NsgNotificationChannels].
/// Идентификатор канала приезжает в нагрузке продуктовых уведомлений, но
/// сам канал обязан существовать на устройстве заранее, иначе Firebase
/// молча подставит канал из манифеста и тревога станет обычным
/// уведомлением.
class FirebasePushTokenProvider implements PushTokenProvider {
  FirebasePushTokenProvider._({
    required this.deviceInfo,
    required bool permissionGranted,
  }) : _permissionGranted = permissionGranted,
       _status = permissionGranted
           ? PushTokenStatus.pending
           : PushTokenStatus.permissionDenied;

  /// Snapshotted DeviceInfo — не меняется в lifecycle session-а
  /// (новая session при app restart).
  final DeviceInfo deviceInfo;

  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();
  StreamSubscription<String>? _refreshSub;
  bool _disposed = false;

  /// **Issue #86**: разрешила ли ОС показывать уведомления (ответ на
  /// `requestPermission` при старте). Хранится, потому что вердикт о
  /// доставке зависит от него на каждом шаге: токен без разрешения на
  /// Android «есть», а уведомления не показываются.
  final bool _permissionGranted;
  PushTokenStatus _status;
  final StreamController<PushTokenStatus> _statusController =
      StreamController<PushTokenStatus>.broadcast();

  /// Единая точка смены состояния: пересчитываем вердикт по разрешению и
  /// токену, дубли не эмитим.
  void _publishStatus(String? token) {
    final next = resolvePushTokenStatus(
      permissionGranted: _permissionGranted,
      token: token,
    );
    if (_disposed || _status == next) return;
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  /// **Async factory**:
  ///   1. `WidgetsFlutterBinding.ensureInitialized()` (idempotent).
  ///   2. `FirebaseMessaging.requestPermission()` (iOS prompt;
  ///      POST_NOTIFICATIONS на Android 13+, no-op ниже).
  ///   3. Каналы уведомлений на Android ([NsgNotificationChannels]).
  ///   4. Resolve [DeviceInfo] (platform/locale/version/model).
  ///   5. Subscribe to `onTokenRefresh` для emit на rotation.
  ///   6. Initial `getToken()` emit (next-tick, после listener attach).
  static Future<FirebasePushTokenProvider> create() async {
    WidgetsFlutterBinding.ensureInitialized();
    final fcm = FirebaseMessaging.instance;
    // iOS prompt; на Android 13+ этот же вызов просит POST_NOTIFICATIONS.
    final permission = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // **Issue #86**: ответ ОС больше не выбрасываем — из него берётся
    // причина «уведомлений нет». `provisional` (тихие уведомления,
    // iOS 12+) считаем выданным разрешением: доставка работает.
    final granted =
        permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;
    // Каналы заводим ДО того, как устройство сможет получить первое
    // уведомление: канал, созданный позже, уже не изменит показ того, что
    // пришло раньше. Разрешения этот шаг не требует — категории видны в
    // системных настройках и у того, кто уведомления запретил.
    await NsgNotificationChannels.ensureCreated();
    final info = await _resolveDeviceInfo();
    final provider = FirebasePushTokenProvider._(
      deviceInfo: info,
      permissionGranted: granted,
    );

    // onTokenRefresh — emit на rotation (FCM periodic cycle / reinstall).
    provider._refreshSub = fcm.onTokenRefresh.listen(
      (token) {
        if (!provider._disposed) {
          provider._tokenController.add(token);
          provider._publishStatus(token);
        }
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[FirebasePushTokenProvider] onTokenRefresh error: $e');
        }
      },
    );

    // Initial token — emit в next-tick чтобы listener-ы в
    // MessengerRuntime.init успели subscribe.
    scheduleMicrotask(() async {
      if (provider._disposed) return;
      String? token;
      try {
        // iOS race: FCM `getToken()` бросает `apns-token-not-set`, если
        // APNS-токен ещё не доехал. На physical-device первый launch
        // APNS приходит через сотни ms после grant permission. Делаем
        // polling до 10s; на Android — no-op (getAPNSToken возвращает
        // null moментально).
        //
        // **Issue #86**: без разрешения ждать нечего — iOS APNs-токен не
        // выдаст в принципе, и 30 секунд опроса лишь оттянули бы вердикт.
        // `getToken()` при этом зовём всё равно: на Android токен выдаётся
        // и без POST_NOTIFICATIONS, а регистрация на сервере нужна, чтобы
        // уведомления заработали сразу, как только человек разрешит их.
        if (!kIsWeb && Platform.isIOS && granted) {
          await _waitForApnsToken(fcm);
        }
        token = await fcm.getToken();
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
      // **Issue #86** — то самое место, где приложение молчало. Раньше
      // единственным следом неудачи был `debugPrint` под `kDebugMode`,
      // которого в релизной сборке нет вовсе: человек две недели не
      // получал уведомлений и не мог узнать причину. Теперь неудача —
      // состояние, и оно доезжает до экрана.
      provider._publishStatus(token);
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
      final token = await FirebaseMessaging.instance.getToken().timeout(
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
      // **Issue #86**: успешный токен здесь — тоже вердикт. Не публикуем
      // «нет токена» на таймауте: 2 секунды ничего не доказывают, вердикт
      // выносит фоновая микрозадача из `create()`.
      if (token != null) _publishStatus(token);
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebasePushTokenProvider] getCurrentToken failed: $e');
      }
      return null;
    }
  }

  @override
  Stream<String?> tokenStream() => _tokenController.stream;

  @override
  PushTokenStatus get pushStatus => _status;

  @override
  Stream<PushTokenStatus> pushStatusStream() => _statusController.stream;

  /// Closes subscription + token stream. Idempotent — second call no-op.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (!_tokenController.isClosed) {
      await _tokenController.close();
    }
    if (!_statusController.isClosed) {
      await _statusController.close();
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

/// **TASK20-Phase2 Chunk 5 / TASK46 (звонки в фоне)**: top-level
/// background message handler. Flutter требует top-level (не closure)
/// функцию для FCM bg-dispatch (граница isolate).
///
/// **Использование**: host-app в `main()`:
/// ```dart
/// FirebaseMessaging.onBackgroundMessage(nsgMessengerBackgroundHandler);
/// ```
///
/// **Важно**: этот handler исполняется в ОТДЕЛЬНОМ isolate (в т.ч. когда
/// приложение убито) — у него НЕТ доступа к app-синглтонам
/// (`NsgMessenger`, `MessengerRuntime`, `CallController`). Поэтому call-
/// побудка полностью self-contained: разбираем data-payload
/// ([CallPushData]) и поднимаем нативный полноэкранный входящий через
/// `flutter_callkit_incoming` ([CallPushPresenter]). Реальный WebRTC-
/// звонок стартует уже в главном isolate: при accept host-app выводит app
/// на передний план, дожидается `m.call.invite` из /sync (коррелирует по
/// callId) и зовёт `NsgMessenger.callController.accept()`.
///
/// Для НЕ-call сообщений — поведение как раньше (no-op; обычную
/// notification система показывает сама, если в payload есть
/// `notification`-блок). Phase3 E2EE: расшифровать payload + local
/// notification.
@pragma('vm:entry-point')
Future<void> nsgMessengerBackgroundHandler(RemoteMessage message) async {
  final call = CallPushData.tryParse(message.data);
  if (call != null) {
    // Call-побудка: поднять полноэкранный входящий (Android full-screen-
    // intent / iOS CallKit). Self-contained — не трогаем app-синглтоны.
    if (kDebugMode) {
      debugPrint(
        '[nsgMessengerBackgroundHandler] call-push: ${call.callId} '
        'from ${call.callerName}',
      );
    }
    await CallPushPresenter.showIncoming(call);
    return;
  }

  // No-op MVP для обычных сообщений. Phase3: decrypt E2EE payload + show
  // local notification. Без этого handler-а Firebase всё равно показывает
  // notification (если payload содержит `notification` field).
  if (kDebugMode) {
    debugPrint(
      '[nsgMessengerBackgroundHandler] received: ${message.messageId}',
    );
  }
}
