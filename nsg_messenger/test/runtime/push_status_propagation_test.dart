/// **Issue #86 — «пуш-токен не взялся, приложение молчит».**
///
/// Провайдер, не сумевший получить токен, писал `debugPrint` под
/// `kDebugMode` и замолкал: в релизной сборке следа не оставалось вовсе.
/// Человек две недели не получал уведомлений и не мог узнать почему.
///
/// Здесь фиксируется середина маршрута, без которой вся затея
/// бессмысленна: вердикт провайдера обязан доехать до рантайма, откуда
/// его читает UI. И обратное — после логаута вердикт чужого, уже
/// уничтоженного провайдера не должен залипать на экране.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';
import 'package:nsg_messenger/src/session/auth_context_fingerprint.dart';

/// Порт, на котором никто не слушает: регистрация устройства заведомо не
/// удастся, но к статусу доставки это отношения не имеет.
const _deadUrl = 'http://127.0.0.1:9/';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    try {
      await NsgMessenger.dispose();
    } catch (_) {}
  });

  const deviceInfo = DeviceInfo(
    platform: DevicePlatform.ios,
    pushService: PushService.fcm,
    locale: 'ru',
    appVersion: '1.1.17+118',
    deviceModel: 'iPhone15,2',
  );

  final ctx = MessengerAuthContext(
    tenantExternalKey: 'chatista',
    productExternalKey: 'chatista',
    identityProvider: IdentityProvider.nsg,
    externalUserId: 'acc-1',
    accessToken: 'customer-token',
  );

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

  Future<void> initWith(PushTokenProvider? push) =>
      MessengerRuntime.instance.init(
        apiBaseUrl: _deadUrl,
        authTokenProvider: _FakeAuthProvider(ctx),
        tokenStoreOverride: storeWithSession(),
        pushTokenProvider: push,
        productExternalKey: 'chatista',
        enableOfflineCache: false,
      );

  test('вердикт, вынесенный ДО init, не теряется', () async {
    // Ровно случай владельца: разрешение не выдано ещё до того, как
    // поднялась сессия. Раньше об этом знал только `debugPrint`.
    final provider = InMemoryPushTokenProvider(deviceInfo: deviceInfo)
      ..setStatus(PushTokenStatus.permissionDenied);
    addTearDown(provider.dispose);

    await initWith(provider);

    expect(
      MessengerRuntime.instance.pushStatus,
      PushTokenStatus.permissionDenied,
    );
  });

  test('поздний вердикт провайдера доезжает до рантайма потоком', () async {
    // Так и происходит на iOS: APNs-токен ждут до 30 секунд, приложение
    // к этому моменту давно работает.
    final provider = InMemoryPushTokenProvider(deviceInfo: deviceInfo);
    addTearDown(provider.dispose);
    await initWith(provider);

    final seen = <PushTokenStatus>[];
    final sub = MessengerRuntime.instance.pushStatusStream.listen(seen.add);

    provider.setStatus(PushTokenStatus.tokenUnavailable);
    await Future<void>.delayed(Duration.zero);

    expect(seen, [PushTokenStatus.tokenUnavailable]);
    expect(
      MessengerRuntime.instance.pushStatus,
      PushTokenStatus.tokenUnavailable,
    );
    await sub.cancel();
  });

  test('без провайдера — unsupported: на десктопе чинить нечего', () async {
    await initWith(null);
    expect(MessengerRuntime.instance.pushStatus, PushTokenStatus.unsupported);
  });

  test('после dispose вердикт чужого провайдера не залипает', () async {
    final provider = InMemoryPushTokenProvider(deviceInfo: deviceInfo)
      ..setStatus(PushTokenStatus.tokenUnavailable);
    addTearDown(provider.dispose);
    await initWith(provider);
    expect(
      MessengerRuntime.instance.pushStatus,
      PushTokenStatus.tokenUnavailable,
    );

    await NsgMessenger.dispose();

    expect(
      MessengerRuntime.instance.pushStatus,
      PushTokenStatus.unsupported,
      reason: 'после логаута «уведомления не подключены» висеть не должно',
    );
  });
}

class _FakeAuthProvider implements AuthTokenProvider {
  _FakeAuthProvider(this.ctx);
  final MessengerAuthContext ctx;

  @override
  Future<MessengerAuthContext> getAuthContext() async => ctx;
}
