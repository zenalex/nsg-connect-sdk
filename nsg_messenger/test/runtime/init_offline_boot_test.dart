/// **issue #77 — офлайн-старт: «сейчас частенько нет интернета и когда
/// захожу и хочу прочитать сообщение, то вижу облако, а не те сообщения,
/// которые мне могли бы прийти или уже пришли».**
///
/// Кэш чатов и офлайн-старт на сохранённой сессии в SDK есть (TASK47) —
/// ломалось не это. `init()` ЖДАЛ регистрацию push-устройства, а та при
/// недоступной сети уходит в ретраи с задержками 2+6+20+60 секунд. Host
/// обрывает init по своему таймауту (20 с) — и человек вместо кэша чатов
/// получал полноэкранное «не удалось подключиться».
///
/// Регистрация устройства — вещь заведомо необязательная (сама себя
/// лечит на следующем эмите токена и на следующем запуске), поэтому
/// держать на ней запуск приложения нельзя. Тест это и фиксирует:
/// сессия есть, сеть мертва — init обязан вернуться быстро.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';
import 'package:nsg_messenger/src/session/auth_context_fingerprint.dart';

/// Порт, на котором никто не слушает: RPC падает сразу, как при
/// недоступном сервере.
const _deadUrl = 'http://127.0.0.1:9/';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    try {
      await NsgMessenger.dispose();
    } catch (_) {}
  });

  final ctx = MessengerAuthContext(
    tenantExternalKey: 'chatista',
    productExternalKey: 'chatista',
    identityProvider: IdentityProvider.nsg,
    externalUserId: 'acc-1',
    accessToken: 'customer-token',
  );

  /// Сохранённая сессия того же пользователя, ещё живая по сроку — на
  /// такой SDK стартует без обращения к серверу.
  InMemoryAuthTokenStore storeWithSession() {
    final store = InMemoryAuthTokenStore();
    store.write(
      StoredMessengerSession(
        fingerprint: authContextFingerprint(ctx),
        storedAt: DateTime.now().toUtc(),
        session: MessengerSession(
          sessionToken: 'session-token',
          messengerUserId: 42,
          matrixUserId: '@me:t',
          tenantId: 1,
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
        ),
      ),
    );
    return store;
  }

  Future<void> initOffline({required PushTokenProvider? push}) =>
      MessengerRuntime.instance.init(
        apiBaseUrl: _deadUrl,
        authTokenProvider: _FakeAuthProvider(ctx),
        tokenStoreOverride: storeWithSession(),
        pushTokenProvider: push,
        productExternalKey: 'chatista',
        // Дисковый кэш в тесте не нужен — проверяем только, что запуск не
        // упирается в сеть.
        enableOfflineCache: false,
      );

  test(
    'офлайн-старт на сохранённой сессии не ждёт регистрацию устройства',
    () async {
      final started = DateTime.now();
      await initOffline(push: _FakePushProvider('fcm-token'));
      final elapsed = DateTime.now().difference(started);

      // Первая пауза в ретраях регистрации — 2 секунды. Если init её ждёт,
      // офлайн-запуск уже не укладывается в бюджет хоста (20 с уходят на
      // 2+6+20+60), и человек видит экран ошибки вместо кэша чатов.
      expect(
        elapsed,
        lessThan(const Duration(milliseconds: 1500)),
        reason: 'init не должен ждать необязательную регистрацию: $elapsed',
      );
      expect(
        MessengerRuntime.instance.isInitialized,
        isTrue,
        reason: 'запуск состоялся — кэш чатов достижим',
      );
    },
  );

  test('без push-провайдера офлайн-старт тоже проходит', () async {
    // Десктоп/веб: провайдера нет вовсе — путь регистрации не задействован.
    await initOffline(push: null);
    expect(MessengerRuntime.instance.isInitialized, isTrue);
  });
}

class _FakeAuthProvider implements AuthTokenProvider {
  _FakeAuthProvider(this.ctx);
  final MessengerAuthContext ctx;

  @override
  Future<MessengerAuthContext> getAuthContext() async => ctx;
}

/// Провайдер отдаёт токен из локального кэша FCM — офлайн он есть, а вот
/// зарегистрировать его на сервере не выйдет.
class _FakePushProvider implements PushTokenProvider {
  _FakePushProvider(this.token);
  final String token;

  @override
  Future<String?> getCurrentToken() async => token;

  @override
  Stream<String?> tokenStream() => const Stream<String?>.empty();

  @override
  Future<DeviceInfo?> getDeviceInfo() async => const DeviceInfo(
    platform: DevicePlatform.android,
    pushService: PushService.fcm,
    locale: 'ru',
    appVersion: '1.1.10',
    deviceModel: 'Test',
  );
}
