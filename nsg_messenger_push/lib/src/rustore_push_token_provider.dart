import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rustore_push/flutter_rustore_push.dart';
import 'package:flutter_rustore_push/pigeons/rustore_push.dart' as rustore;
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'notification_channels.dart';
import 'push_status_resolver.dart';

/// **TASK61**: production [PushTokenProvider] поверх `flutter_rustore_push`
/// (RuStore Push / VKPNS) — для Android-устройств без Google Play Services.
///
/// **Host-app prerequisites**:
///   1. Приложение опубликовано в RuStore Console (иначе VKPNS не выдаёт
///      токены).
///   2. В `AndroidManifest.xml` — `<meta-data
///      android:name="ru.rustore.sdk.pushclient.project_id"
///      android:value="<project id из RuStore Console>" />` (SDK
///      инициализируется автоматически по этому значению).
///   3. На устройстве установлен RuStore, ему разрешён фон, пользователь
///      авторизован — всё это проверяет `RustorePushClient.available()`
///      (см. `resolvePushService()` в push_provider_resolver.dart).
///
/// **Отличия от FCM-пути**:
///   * НЕТ background-isolate (аналога `onBackgroundMessage`) — data-only
///     push в убитом приложении Dart-код не будит. Поэтому сервер для
///     rustore-устройств шлёт call-push обычной notification-побудкой
///     («Входящий звонок»), а не data-only CallKit-побудкой (см. серверный
///     `RuStorePushAdapter`).
///   * Обычные message-нотификации рисует сервис RuStore из
///     `notification`-блока — как и в FCM-пути, клиенту делать ничего не
///     нужно; клиентская логика только tap-routing.
///
/// **Tap-routing**: колбэки RuStore SDK глобальные
/// (`RustorePushClient.attachCallbacks` перезаписывает предыдущий набор),
/// поэтому provider владеет ими монопольно и раздаёт наружу:
///   * [messageOpenedStream] — тап по нотификации при живом app
///     (аналог `FirebaseMessaging.onMessageOpenedApp`);
///   * [getInitialTapData] — cold start из нотификации (аналог
///     `getInitialMessage`).
class RuStorePushTokenProvider implements PushTokenProvider {
  RuStorePushTokenProvider._({
    required this.deviceInfo,
    required bool permissionGranted,
  }) : _permissionGranted = permissionGranted,
       _status = permissionGranted
           ? PushTokenStatus.pending
           : PushTokenStatus.permissionDenied;

  /// Snapshotted DeviceInfo (pushService == rustore).
  final DeviceInfo deviceInfo;

  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();
  bool _disposed = false;

  /// **Issue #86**: вердикт «дойдут ли пуши». Отсутствие токена здесь
  /// такое же молчаливое, как было в FCM-пути, поэтому лечим одинаково.
  ///
  /// **Прежнее ограничение снято (этап 3).** Раньше провайдер никогда не
  /// выставлял [PushTokenStatus.permissionDenied]: SDK RuStore о
  /// POST_NOTIFICATIONS ничего не сообщает, а сами мы разрешение не
  /// спрашивали — считать его выданным было единственным честным
  /// вариантом. Теперь разрешение запрашиваем в [create] и знаем ответ,
  /// поэтому отказ на Android 13+ становится видимым вердиктом, а не
  /// молчаливым «токен есть, уведомлений нет».
  final bool _permissionGranted;
  PushTokenStatus _status;
  final StreamController<PushTokenStatus> _statusController =
      StreamController<PushTokenStatus>.broadcast();

  void _publishStatus(String? token) {
    final next = resolvePushTokenStatus(
      permissionGranted: _permissionGranted,
      token: token,
    );
    if (_disposed || _status == next) return;
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  /// Тапы по нотификациям (data-пейлоады) при живом (свёрнутом) app.
  /// Static broadcast — колбэки RuStore глобальные, host-app подписывается
  /// один раз независимо от пересоздания provider-а (switch аккаунта).
  static final StreamController<Map<String, String>> _openedController =
      StreamController<Map<String, String>>.broadcast();
  static Stream<Map<String, String>> get messageOpenedStream =>
      _openedController.stream;

  /// **TASK61 «Проверить пуш»**: foreground-доставка data-пейлоада
  /// (приложение открыто). Host-app подписывается, чтобы показать снекбар
  /// «пуш доставлен» для тестового пуша (`data['type']=='push_test'`).
  /// Обычные сообщения RuStore-сервис рисует нотификацией сам — host их
  /// игнорирует.
  static final StreamController<Map<String, String>> _receivedController =
      StreamController<Map<String, String>>.broadcast();
  static Stream<Map<String, String>> get messageReceivedStream =>
      _receivedController.stream;

  /// **Async factory**:
  ///   1. `WidgetsFlutterBinding.ensureInitialized()` (idempotent).
  ///   2. POST_NOTIFICATIONS (Android 13+) — см. ниже.
  ///   3. Каналы уведомлений ([NsgNotificationChannels]).
  ///   4. Resolve [DeviceInfo].
  ///   5. `attachCallbacks` — onNewToken → tokenStream, tap-колбэки →
  ///      [messageOpenedStream]. Повторный create (reinit при switch
  ///      аккаунта) пере-attach-ит колбэки на новый инстанс — старый
  ///      перестаёт эмитить (его stream больше никто не слушает).
  ///   6. Initial `getToken()` emit (next-tick, после подписки runtime).
  ///
  /// **Разрешение теперь спрашиваем сами (этап 3).** Раньше это было
  /// целиком на host-app: SDK RuStore разрешениями не занимается, а у нас
  /// в пакете не было, чем спросить. Хост, который об этом не знал,
  /// получал устройство с токеном и без единого уведомления — отказ,
  /// который ничем себя не проявляет. На FCM-пути того же добивается
  /// `FirebaseMessaging.requestPermission()`, поэтому там второй запрос не
  /// нужен и не делается.
  ///
  /// **Хост со своим запросом сломать этим нельзя, но диалог он может
  /// показать вторым.** Chatista спрашивает через `permission_handler` в
  /// `_setupCallPush` и перед показом сверяется со статусом: разрешил
  /// человек нам — второго диалога не будет. Отказал — статус остаётся
  /// `denied`, и хост спросит ещё раз (Android даёт две попытки). Так уже
  /// ведёт себя FCM-путь, где разрешение просит `requestPermission()`;
  /// RuStore-путь теперь просто ведёт себя так же, а не молчит.
  static Future<RuStorePushTokenProvider> create() async {
    WidgetsFlutterBinding.ensureInitialized();
    final granted = await requestAndroidNotificationsPermission();
    // Каналы — до первого возможного уведомления и независимо от ответа
    // на разрешение: категории видны в системных настройках и тому, кто
    // уведомления запретил, а RuStore-путь идентификатор канала пока не
    // получает вовсе (этап 6 ТЗ) — заводит их всё равно приложение.
    await NsgNotificationChannels.ensureCreated();
    final info = await _resolveDeviceInfo();
    final provider = RuStorePushTokenProvider._(
      deviceInfo: info,
      permissionGranted: granted,
    );

    await RustorePushClient.attachCallbacks(
      onNewToken: (dynamic token) {
        if (token is String && !provider._disposed) {
          provider._tokenController.add(token);
          provider._publishStatus(token);
        }
      },
      onMessageReceived: (dynamic message) {
        // Foreground-доставка: обычную notification рисует сервис RuStore
        // сам. Пробрасываем data наружу — host-app показывает снекбар для
        // тестового пуша (`type==push_test`), остальное игнорирует.
        final data = _dataOf(message);
        if (data != null) _receivedController.add(data);
      },
      onMessageOpenedApp: (dynamic message) {
        final data = _dataOf(message);
        if (data != null) _openedController.add(data);
      },
      onDeletedMessages: () {},
      onError: (dynamic err) {
        if (kDebugMode) {
          debugPrint('[RuStorePushTokenProvider] onError: $err');
        }
      },
    );

    // Initial token — next-tick, чтобы listener-ы в MessengerRuntime.init
    // успели подписаться.
    scheduleMicrotask(() async {
      if (provider._disposed) return;
      String? token;
      try {
        token = await RustorePushClient.getToken();
        if (token.isNotEmpty && !provider._disposed) {
          provider._tokenController.add(token);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[RuStorePushTokenProvider] initial getToken failed: $e');
        }
      }
      // **Issue #86**: неудача — состояние, а не запись в отладочной
      // консоли, которой у пользователя нет.
      provider._publishStatus(token);
    });

    return provider;
  }

  /// Cold start из нотификации: data-пейлоад «разбудившего» пуша, либо
  /// null. Аналог `FirebaseMessaging.instance.getInitialMessage()`.
  static Future<Map<String, String>?> getInitialTapData() async {
    try {
      final message = await RustorePushClient.getInitialMessage();
      return _dataOf(message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RuStorePushTokenProvider] getInitialMessage failed: $e');
      }
      return null;
    }
  }

  @override
  Future<DeviceInfo?> getDeviceInfo() async => deviceInfo;

  @override
  Future<String?> getCurrentToken() async {
    if (_disposed) return null;
    try {
      // Hard timeout как у FCM-провайдера — не вешаем UI, tokenStream
      // доэмитит позже через onNewToken.
      final token = await RustorePushClient.getToken()
          .timeout(const Duration(seconds: 2), onTimeout: () => '')
          .then((t) => t.isEmpty ? null : t);
      // **Issue #86**: успешный токен — тоже вердикт. На таймауте молчим:
      // 2 секунды ничего не доказывают, вердикт выносит микрозадача
      // из `create()`.
      if (token != null) _publishStatus(token);
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RuStorePushTokenProvider] getCurrentToken failed: $e');
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

  /// Closes token stream. Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (!_tokenController.isClosed) {
      await _tokenController.close();
    }
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }

  // ─────── Internals ───────

  /// Нормализовать `Message.data` плагина (`Map<String?, String?>`) к
  /// `Map<String, String>` (контракт tap-routing — как FCM data-поля).
  static Map<String, String>? _dataOf(dynamic message) {
    if (message is! rustore.Message) return null;
    final out = <String, String>{};
    message.data.forEach((k, v) {
      if (k != null) out[k] = v ?? '';
    });
    return out;
  }

  static Future<DeviceInfo> _resolveDeviceInfo() async {
    final pkg = await PackageInfo.fromPlatform();
    final appVersion = '${pkg.version}+${pkg.buildNumber}';
    final locale = PlatformDispatcher.instance.locale.toLanguageTag();

    String? model;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final android = await DeviceInfoPlugin().androidInfo;
        model = '${android.manufacturer} ${android.model}'.trim();
      }
    } catch (_) {
      // device_info_plus throws на unsupported platforms — null OK.
    }

    return DeviceInfo(
      // RuStore Push — Android-only.
      platform: DevicePlatform.android,
      pushService: PushService.rustore,
      locale: locale,
      appVersion: appVersion,
      deviceModel: model,
    );
  }
}
