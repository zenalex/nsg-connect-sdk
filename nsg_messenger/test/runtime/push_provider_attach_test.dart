/// **Настройка пушей не стоит на пути к чатам.**
///
/// Жалоба владельца 09.08.2026: «давай добьём вопрос с работой без
/// интернета… решит сразу и вопрос времени запуска и отсутствие плашки
/// "нет соединения"». Разбор показал, что до списка чатов приложение
/// проходило через ДВА системных диалога разрешений (`requestPermission`
/// на iOS, `Permission.notification` на Android) и через `getToken()`.
/// Всё это стояло ПЕРЕД `init`, то есть между человеком и его чатами,
/// которые всё это время лежали на диске.
///
/// Теперь провайдер подключается отдельно и когда угодно — приложение
/// делает это уже после того, как чаты на экране. Здесь проверяется
/// граница: `init` без провайдера не трогает пуши, а `attach` не ждёт
/// ничего сетевого.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';
import 'package:nsg_messenger/src/session/auth_context_fingerprint.dart';

/// Порт, на котором никто не слушает: сеть мертва, как в самолёте.
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

  Future<void> initOffline({PushTokenProvider? push}) =>
      MessengerRuntime.instance.init(
        apiBaseUrl: _deadUrl,
        authTokenProvider: _FakeAuthProvider(ctx),
        tokenStoreOverride: storeWithSession(),
        pushTokenProvider: push,
        productExternalKey: 'chatista',
        enableOfflineCache: false,
      );

  test('провайдер, который никогда не отвечает, не держит init', () async {
    // Ровно тот случай, что был на проде: `getToken()` на iOS без APNs
    // висит, и приложение висит вместе с ним. Провайдер тут не отвечает
    // НИКОГДА — init обязан вернуться всё равно.
    final started = DateTime.now();
    await initOffline(push: _HangingPushProvider());
    final elapsed = DateTime.now().difference(started);

    expect(
      elapsed,
      lessThan(const Duration(milliseconds: 1500)),
      reason: 'init подождал выдачу токена: $elapsed',
    );
    expect(MessengerRuntime.instance.isInitialized, isTrue);
  });

  test('без провайдера запуск проходит, и пуши помечены как недоступные', () {
    // Так теперь стартует приложение: сначала чаты, пуши потом.
    return initOffline().then((_) {
      expect(MessengerRuntime.instance.isInitialized, isTrue);
      expect(
        MessengerRuntime.instance.pushStatus,
        PushTokenStatus.unsupported,
        reason: 'провайдера нет — и вердикт об этом честный',
      );
    });
  });

  test('attach после init доносит вердикт провайдера до UI', () async {
    await initOffline();
    expect(MessengerRuntime.instance.pushStatus, PushTokenStatus.unsupported);

    MessengerRuntime.instance.attachPushTokenProvider(
      _FakePushProvider('fcm-token', status: PushTokenStatus.ready),
      productExternalKey: 'chatista',
    );

    expect(
      MessengerRuntime.instance.pushStatus,
      PushTokenStatus.ready,
      reason: 'иначе плашка «пуши не придут» осталась бы висеть навсегда',
    );
  });

  test('вердикт провайдера не ждёт выдачу токена', () async {
    // Провайдер уже знает, что разрешения нет, — сказать об этом можно
    // сразу. Если ждать токена, который в этом состоянии не придёт
    // никогда, плашка «уведомления не придут» не появится вовсе.
    await initOffline();

    MessengerRuntime.instance.attachPushTokenProvider(
      _HangingPushProvider(status: PushTokenStatus.permissionDenied),
    );

    expect(
      MessengerRuntime.instance.pushStatus,
      PushTokenStatus.permissionDenied,
    );
  });

  test('повторный attach переподписывается на новый провайдер', () async {
    // Переключение аккаунта: рантайм новый, а платформенная подписка та же.
    // Если старая не отменяется, токен уезжает регистрироваться дважды.
    await initOffline();
    final first = _FakePushProvider('token-1', status: PushTokenStatus.ready);
    final second = _FakePushProvider(
      'token-2',
      status: PushTokenStatus.permissionDenied,
    );

    MessengerRuntime.instance.attachPushTokenProvider(first);
    MessengerRuntime.instance.attachPushTokenProvider(second);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(MessengerRuntime.instance.pushStatus, second.pushStatus);

    // Старый провайдер эмитит — его больше не слушают.
    first.emitStatus(PushTokenStatus.ready);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      MessengerRuntime.instance.pushStatus,
      second.pushStatus,
      reason: 'подписка на прежний провайдер осталась живой',
    );
  });
}

class _FakeAuthProvider implements AuthTokenProvider {
  _FakeAuthProvider(this.ctx);
  final MessengerAuthContext ctx;

  @override
  Future<MessengerAuthContext> getAuthContext() async => ctx;
}

/// Провайдер, у которого выдача токена не завершается никогда — так ведёт
/// себя FCM на iOS, пока не приехал APNs-токен.
class _HangingPushProvider implements PushTokenProvider {
  _HangingPushProvider({this.status = PushTokenStatus.pending});

  final PushTokenStatus status;

  @override
  Future<String?> getCurrentToken() => Completer<String?>().future;

  @override
  Stream<String?> tokenStream() => const Stream<String?>.empty();

  @override
  PushTokenStatus get pushStatus => status;

  @override
  Stream<PushTokenStatus> pushStatusStream() =>
      const Stream<PushTokenStatus>.empty();

  @override
  Future<DeviceInfo?> getDeviceInfo() async => null;
}

class _FakePushProvider implements PushTokenProvider {
  _FakePushProvider(this.token, {required PushTokenStatus status})
    : _status = status;

  final String token;
  PushTokenStatus _status;
  final _statusCtl = StreamController<PushTokenStatus>.broadcast();

  void emitStatus(PushTokenStatus s) {
    _status = s;
    _statusCtl.add(s);
  }

  @override
  Future<String?> getCurrentToken() async => token;

  @override
  Stream<String?> tokenStream() => const Stream<String?>.empty();

  @override
  PushTokenStatus get pushStatus => _status;

  @override
  Stream<PushTokenStatus> pushStatusStream() => _statusCtl.stream;

  @override
  Future<DeviceInfo?> getDeviceInfo() async => const DeviceInfo(
    platform: DevicePlatform.android,
    pushService: PushService.fcm,
    locale: 'ru',
    appVersion: '1.1.35',
    deviceModel: 'Test',
  );
}
