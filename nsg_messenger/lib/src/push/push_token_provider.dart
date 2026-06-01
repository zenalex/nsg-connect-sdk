import 'dart:async';

import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Контракт получения push-токена устройства от платформенного API.
/// Используется `MessengerRuntime` (TASK20 Chunk 3) для регистрации
/// токенов в серверной БД через `client.messenger.registerDevice`.
///
/// **Производственная имплементация** — `FirebasePushTokenProvider` в
/// отдельном пакете `nsg_messenger_push` (тонкая обёртка над
/// `firebase_messaging`). Отдельный package, чтобы pure-Dart `nsg_messenger`
/// core не тащил native plugin (web/embed-only customer не нуждается).
///
/// **Тесты** — [InMemoryPushTokenProvider]: подменяемый token + manual
/// rotation через `setToken(...)`. `MessengerRuntime` тестируется без
/// поднятия Firebase / native channels.
///
/// **Embed-mode без push** — host-app не передаёт provider в
/// `NsgMessenger.init`; runtime просто пропускает register/unregister.
abstract class PushTokenProvider {
  /// Метаданные о текущем устройстве (platform, locale, app version,
  /// model). Возвращает `null` если SDK не может определить (например,
  /// тесты) — runtime пропустит register-call.
  Future<DeviceInfo?> getDeviceInfo();

  /// Текущий push-token устройства. Возвращает `null` если provider
  /// ещё не получил token от FCM/APNs (платформа discoveryает asynchronously).
  /// `MessengerRuntime` ждёт первого emit на [tokenStream].
  Future<String?> getCurrentToken();

  /// Stream обновлений push-токена. Эмитит:
  ///   * первоначальный token при старте provider-а (если уже получен);
  ///   * каждое refresh от FCM/APNs (token rotation в результате
  ///     reinstall, expired credentials, и т.п.).
  /// `null` value emit-ит когда token revoked (logout / OS-level reset).
  Stream<String?> tokenStream();
}

/// Метаданные устройства, которые SDK передаёт в server-side
/// `registerDevice` для troubleshooting + locale-aware push routing.
class DeviceInfo {
  const DeviceInfo({
    required this.platform,
    required this.pushService,
    required this.locale,
    required this.appVersion,
    this.deviceModel,
  });

  /// Resolved платформа из `Platform.isIOS` / `Platform.isAndroid` /
  /// `kIsWeb` / `Platform.isMacOS|Linux|Windows`.
  final DevicePlatform platform;

  /// FCM / APNs / WebPush — определяется provider-ом по платформе.
  /// (Например, `FirebasePushTokenProvider` всегда использует FCM
  /// даже на iOS — Firebase wraps APNs token в FCM token.)
  final PushService pushService;

  /// IETF BCP 47 (например, `ru`, `en-US`).
  final String locale;

  /// Semver-style (`1.0.0+1` Flutter `package_info_plus` format).
  final String appVersion;

  /// Best-effort hardware identifier (e.g., `iPhone15,2`, `Pixel 7`).
  /// Может быть null если SDK не получил info или host-app не
  /// предоставил.
  final String? deviceModel;
}

/// Test-only / embed-only имплементация: host-app передаёт fixed token
/// + DeviceInfo, симулирует rotation через `setToken(...)`.
///
/// **Production**: используйте `FirebasePushTokenProvider` из
/// `nsg_messenger_push`.
///
/// **Тесты SDK / host-app integration tests**: `MessengerRuntime`
/// принимает этот provider, runtime сам зовёт register-device на
/// `init` и при каждом emit на [tokenStream].
class InMemoryPushTokenProvider implements PushTokenProvider {
  InMemoryPushTokenProvider({required this.deviceInfo, String? initialToken})
    : _token = initialToken {
    if (initialToken != null) {
      // Эмитим initial token в next-tick, чтобы listener-ы в `init`
      // успели подписаться.
      scheduleMicrotask(() {
        if (!_controller.isClosed) _controller.add(initialToken);
      });
    }
  }

  final DeviceInfo deviceInfo;
  String? _token;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  /// Симулирует token rotation от FCM/APNs (выдан новый token /
  /// revoked). Передайте null для simulation logout / token reset.
  void setToken(String? newToken) {
    _token = newToken;
    if (!_controller.isClosed) _controller.add(newToken);
  }

  @override
  Future<DeviceInfo?> getDeviceInfo() async => deviceInfo;

  @override
  Future<String?> getCurrentToken() async => _token;

  @override
  Stream<String?> tokenStream() => _controller.stream;

  /// Очистка ресурсов. После dispose `tokenStream` закрыт; повторный
  /// `setToken` — no-op.
  Future<void> dispose() => _controller.close();
}
