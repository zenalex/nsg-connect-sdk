import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';

/// **TASK20-Phase2 Chunk 4**: SDK API для notification settings.
/// Wrapper над `client.messenger.{getNotificationSettings,
/// setNotificationSettings}` с in-memory cache (60s TTL).
///
/// **Why in-memory cache**: settings rarely change (user opens screen,
/// toggles 1-2 раза, закрывает). Зацепить cache invalidate через
/// realtime event — overengineering на MVP. Если другой device user-а
/// меняет settings, текущий device увидит свежие при первом
/// `get` после TTL expire (60s) ИЛИ explicit `invalidate()`.
class NsgMessengerSettings {
  NsgMessengerSettings._({
    required GetNotificationSettingsRpc getRpc,
    required SetNotificationSettingsRpc setRpc,
  }) : _getRpc = getRpc,
       _setRpc = setRpc;

  /// Production-фабрика: привязывает к `client.messenger.*` методам.
  ///
  /// **TASK20 followup (α)**: оба RPC обёрнуты в [withAuthRetry] для
  /// self-heal на типизированную auth-invalidation. Session manager
  /// резолвится лениво через [MessengerRuntime.instance.sessionManager]
  /// (см. `nsg_messenger_rooms.dart` для аналогичного паттерна).
  factory NsgMessengerSettings.attach(Client client) => NsgMessengerSettings._(
    getRpc: () => withAuthRetry(
      () => client.messenger.getNotificationSettings(),
      MessengerRuntime.instance.sessionManager,
    ),
    setRpc: ({required bool showMessagePreview}) => withAuthRetry(
      () => client.messenger.setNotificationSettings(
        showMessagePreview: showMessagePreview,
      ),
      MessengerRuntime.instance.sessionManager,
    ),
  );

  /// Test-фабрика — позволяет подменить RPC на in-memory fake.
  @visibleForTesting
  factory NsgMessengerSettings.attachWithRpcs({
    required GetNotificationSettingsRpc getRpc,
    required SetNotificationSettingsRpc setRpc,
  }) => NsgMessengerSettings._(getRpc: getRpc, setRpc: setRpc);

  final GetNotificationSettingsRpc _getRpc;
  final SetNotificationSettingsRpc _setRpc;

  /// Cache duration. Settings меняются редко.
  static const Duration cacheTtl = Duration(seconds: 60);

  NotificationSettings? _cached;
  DateTime? _cachedAt;

  /// Cache hit: возвращает закэшированный snapshot. Cache miss или TTL
  /// истёк: дёргает `client.messenger.getNotificationSettings`.
  Future<NotificationSettings> get() async {
    final cached = _cached;
    final at = _cachedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < cacheTtl) {
      return cached;
    }
    final fresh = await _getRpc();
    _cached = fresh;
    _cachedAt = DateTime.now();
    return fresh;
  }

  /// Update settings и обновить cache. Если RPC fails — cache не
  /// trogается, throw пробрасывается caller-у (UI должен показать
  /// snackbar / revert toggle).
  Future<void> set({required bool showMessagePreview}) async {
    await _setRpc(showMessagePreview: showMessagePreview);
    // Update cache immediately — UX: следующий `get()` reflect
    // обновлённое значение без extra RPC.
    _cached = NotificationSettings(showMessagePreview: showMessagePreview);
    _cachedAt = DateTime.now();
  }

  /// Drop cache — следующий `get()` обращается к серверу. Использовать
  /// если внешний сигнал говорит что settings изменены (например cross-
  /// device event в будущем).
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }
}

typedef GetNotificationSettingsRpc = Future<NotificationSettings> Function();
typedef SetNotificationSettingsRpc =
    Future<void> Function({required bool showMessagePreview});
