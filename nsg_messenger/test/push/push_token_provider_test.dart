import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

/// Тесты [InMemoryPushTokenProvider] — test-only / embed-only
/// имплементация [PushTokenProvider] (TASK20 Chunk 3). Production
/// `FirebasePushTokenProvider` живёт в `nsg_messenger_push` package
/// (skeleton; impl в TASK20-Phase2).
void main() {
  const info = DeviceInfo(
    platform: DevicePlatform.android,
    pushService: PushService.fcm,
    locale: 'en',
    appVersion: '1.0.0+1',
    deviceModel: 'Pixel 7',
  );

  test('initialToken: emits на следующем microtask', () async {
    final provider = InMemoryPushTokenProvider(
      deviceInfo: info,
      initialToken: 'tok-1',
    );
    final received = <String?>[];
    final sub = provider.tokenStream().listen(received.add);
    await Future<void>.delayed(Duration.zero);

    expect(received, ['tok-1']);
    expect(await provider.getCurrentToken(), 'tok-1');

    await sub.cancel();
    await provider.dispose();
  });

  test('без initialToken: no emit до setToken', () async {
    final provider = InMemoryPushTokenProvider(deviceInfo: info);
    final received = <String?>[];
    final sub = provider.tokenStream().listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    expect(await provider.getCurrentToken(), isNull);

    provider.setToken('tok-X');
    await Future<void>.delayed(Duration.zero);
    expect(received, ['tok-X']);

    await sub.cancel();
    await provider.dispose();
  });

  test('setToken: эмит каждый вызов (token rotation simulation)', () async {
    final provider = InMemoryPushTokenProvider(deviceInfo: info);
    final received = <String?>[];
    final sub = provider.tokenStream().listen(received.add);
    await Future<void>.delayed(Duration.zero);

    provider.setToken('a');
    provider.setToken('b');
    provider.setToken('c');
    await Future<void>.delayed(Duration.zero);

    expect(received, ['a', 'b', 'c']);
    expect(await provider.getCurrentToken(), 'c');

    await sub.cancel();
    await provider.dispose();
  });

  test('setToken(null) — эмитит null (logout / OS reset symulation)', () async {
    final provider = InMemoryPushTokenProvider(
      deviceInfo: info,
      initialToken: 'tok-x',
    );
    final received = <String?>[];
    final sub = provider.tokenStream().listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(received, ['tok-x']);

    provider.setToken(null);
    await Future<void>.delayed(Duration.zero);
    expect(received, ['tok-x', null]);
    expect(await provider.getCurrentToken(), isNull);

    await sub.cancel();
    await provider.dispose();
  });

  test('getDeviceInfo: возвращает то что было передано', () async {
    final provider = InMemoryPushTokenProvider(deviceInfo: info);
    final fetched = await provider.getDeviceInfo();
    expect(fetched, isNotNull);
    expect(fetched!.platform, DevicePlatform.android);
    expect(fetched.pushService, PushService.fcm);
    expect(fetched.locale, 'en');
    expect(fetched.appVersion, '1.0.0+1');
    expect(fetched.deviceModel, 'Pixel 7');
    await provider.dispose();
  });

  test('dispose: stream закрывается, повторный setToken — no-op', () async {
    final provider = InMemoryPushTokenProvider(deviceInfo: info);
    final received = <String?>[];
    final sub = provider.tokenStream().listen(received.add);
    await Future<void>.delayed(Duration.zero);

    provider.setToken('before');
    await Future<void>.delayed(Duration.zero);
    expect(received, ['before']);

    await provider.dispose();
    // После dispose повторный setToken — no-op (controller closed).
    provider.setToken('after-dispose');
    await Future<void>.delayed(Duration.zero);
    expect(received, ['before'], reason: 'после dispose новый emit не пришёл');

    await sub.cancel();
  });
}
