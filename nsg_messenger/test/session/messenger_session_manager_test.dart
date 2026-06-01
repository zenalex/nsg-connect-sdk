import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/session/auth_context_fingerprint.dart';
import 'package:nsg_messenger/src/session/messenger_session_manager.dart';

/// Тесты для [MessengerSessionManager] — самой нетривиальной части
/// Chunk 3 (proactive timer + reactive 401 + cache reuse + fingerprint
/// switch + state-stream).
///
/// Реальный Serverpod-клиент не нужен — менеджер берёт session/refresh
/// RPC через инъекцию (`attachWithRpcs`), и тесты подменяют их на
/// in-memory fake-и.
void main() {
  // ───────── Test fixtures ─────────

  MessengerAuthContext ctx({
    String externalUserId = 'alice',
    String accessToken = 'token-1',
  }) => MessengerAuthContext(
    tenantExternalKey: 'nsg',
    productExternalKey: 'chatista',
    identityProvider: IdentityProvider.nsg,
    externalUserId: externalUserId,
    accessToken: accessToken,
  );

  MessengerSession sessionFor({
    required String token,
    required Duration validFor,
    int messengerUserId = 42,
  }) => MessengerSession(
    sessionToken: token,
    messengerUserId: messengerUserId,
    matrixUserId: '@alice:localhost',
    tenantId: 1,
    expiresAt: DateTime.now().toUtc().add(validFor),
  );

  // ───────── Tests ─────────

  test(
    'init: cache miss → зовёт provider + sessionRpc, эмитит active',
    () async {
      final provider = _FakeProvider([ctx()]);
      final store = InMemoryAuthTokenStore();
      final states = <MessengerSessionState>[];
      var sessionCalls = 0;
      var refreshCalls = 0;

      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async {
          sessionCalls++;
          return sessionFor(
            token: 'srv-1',
            validFor: const Duration(hours: 24),
          );
        },
        refreshRpc: (c) async {
          refreshCalls++;
          return sessionFor(
            token: 'srv-1-refreshed',
            validFor: const Duration(hours: 24),
          );
        },
        authTokenProvider: provider,
        store: store,
        errorReporter: null,
        emitState: states.add,
      );

      await manager.init();
      expect(sessionCalls, 1);
      expect(refreshCalls, 0);
      expect(states, [
        MessengerSessionState.refreshing,
        MessengerSessionState.active,
      ]);
      expect(manager.session?.sessionToken, 'srv-1');

      // В store — запись с правильным fingerprint-ом.
      final cached = await store.read();
      expect(cached, isNotNull);
      expect(cached!.fingerprint, authContextFingerprint(ctx()));

      // authKeyProvider содержит Bearer + новый токен.
      expect(
        await manager.currentAuthHeaderValueForTest,
        wrapAsBearerAuthHeaderValue('srv-1'),
      );

      await manager.dispose();
    },
  );

  test(
    'init: cache hit (свежая сессия + matching fp) → НЕ зовёт sessionRpc',
    () async {
      final fp = authContextFingerprint(ctx());
      final cached = sessionFor(
        token: 'cached-tok',
        validFor: const Duration(hours: 24),
      );
      final store = InMemoryAuthTokenStore();
      await store.write(
        StoredMessengerSession(
          fingerprint: fp,
          session: cached,
          storedAt: DateTime.now().toUtc(),
        ),
      );

      final provider = _FakeProvider([ctx()]);
      var sessionCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async {
          sessionCalls++;
          throw StateError('не должно вызываться');
        },
        refreshRpc: (c) async => throw StateError('не должно вызываться'),
        authTokenProvider: provider,
        store: store,
        errorReporter: null,
        emitState: (_) {},
      );

      await manager.init();
      expect(sessionCalls, 0);
      expect(manager.session?.sessionToken, 'cached-tok');
      await manager.dispose();
    },
  );

  test(
    'init: cache fingerprint mismatch (другой юзер) → clear + new session',
    () async {
      final oldFp = authContextFingerprint(ctx(externalUserId: 'OLD-USER'));
      final store = InMemoryAuthTokenStore();
      await store.write(
        StoredMessengerSession(
          fingerprint: oldFp,
          session: sessionFor(
            token: 'old-user-tok',
            validFor: const Duration(hours: 24),
          ),
          storedAt: DateTime.now().toUtc(),
        ),
      );

      var sessionCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async {
          sessionCalls++;
          return sessionFor(
            token: 'new-user-tok',
            validFor: const Duration(hours: 24),
          );
        },
        refreshRpc: (c) async => throw StateError('не должно вызываться'),
        authTokenProvider: _FakeProvider([ctx()]),
        store: store,
        errorReporter: null,
        emitState: (_) {},
      );

      await manager.init();
      expect(sessionCalls, 1);
      expect(manager.session?.sessionToken, 'new-user-tok');

      // Кэш теперь принадлежит новому юзеру.
      final after = await store.read();
      expect(after!.fingerprint, authContextFingerprint(ctx()));
      await manager.dispose();
    },
  );

  test(
    'init: cache hit но expiresAt ВСКОРЕ (внутри lead-time) → новая session, не cached',
    () async {
      final fp = authContextFingerprint(ctx());
      // Сессия ещё валидна (≈4 минуты), но входит в lead-time (5 мин).
      final aboutToExpire = sessionFor(
        token: 'about-to-expire',
        validFor: const Duration(minutes: 4),
      );
      final store = InMemoryAuthTokenStore();
      await store.write(
        StoredMessengerSession(
          fingerprint: fp,
          session: aboutToExpire,
          storedAt: DateTime.now().toUtc(),
        ),
      );

      var sessionCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async {
          sessionCalls++;
          return sessionFor(
            token: 'fresh-tok',
            validFor: const Duration(hours: 24),
          );
        },
        refreshRpc: (c) async => throw StateError('не должно вызываться'),
        authTokenProvider: _FakeProvider([ctx()]),
        store: store,
        errorReporter: null,
        emitState: (_) {},
      );

      await manager.init();
      expect(sessionCalls, 1, reason: 'lead-time elapsed → new session');
      expect(manager.session?.sessionToken, 'fresh-tok');
      await manager.dispose();
    },
  );

  test(
    'proactive refresh: короткая сессия → refresh-таймер срабатывает',
    () async {
      // 5 min lead-time + 100 ms minimum → если сессия живёт 5 мин,
      // delay = 100 ms (clamped), refresh должен случиться очень быстро.
      final provider = _FakeProvider([ctx(), ctx()]);
      final store = InMemoryAuthTokenStore();
      var refreshCalls = 0;
      final states = <MessengerSessionState>[];

      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async => sessionFor(
          token: 'short-lived',
          validFor: const Duration(minutes: 5),
        ),
        refreshRpc: (c) async {
          refreshCalls++;
          return sessionFor(
            token: 'after-refresh',
            validFor: const Duration(hours: 24),
          );
        },
        authTokenProvider: provider,
        store: store,
        errorReporter: null,
        emitState: states.add,
      );
      await manager.init();
      expect(states.last, MessengerSessionState.active);
      expect(refreshCalls, 0);

      // Ждём чуть больше minRefreshDelay (100ms) + tolerance.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(refreshCalls, 1, reason: 'proactive timer должен сработать');
      expect(manager.session?.sessionToken, 'after-refresh');
      expect(
        await manager.currentAuthHeaderValueForTest,
        wrapAsBearerAuthHeaderValue('after-refresh'),
      );
      expect(states.last, MessengerSessionState.active);

      await manager.dispose();
    },
  );

  test(
    'refresh: InvalidTokenException → state.expired + failedUnauthorized',
    () async {
      var refreshCalls = 0;
      final states = <MessengerSessionState>[];
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c) async {
          refreshCalls++;
          throw InvalidTokenException(reason: 'simulated');
        },
        authTokenProvider: _FakeProvider([ctx(), ctx()]),
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: states.add,
      );

      await manager.init();
      states.clear();
      final result = await manager.refreshForTest();
      expect(result, RefreshAuthKeyResult.failedUnauthorized);
      expect(refreshCalls, 1);
      expect(states, contains(MessengerSessionState.refreshing));
      expect(states.last, MessengerSessionState.expired);

      await manager.dispose();
    },
  );

  test(
    'refresh: сетевая ошибка → state.error, failedOther, сессия живёт',
    () async {
      var refreshCalls = 0;
      final states = <MessengerSessionState>[];
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c) async {
          refreshCalls++;
          throw const _FakeSocketException('network down');
        },
        authTokenProvider: _FakeProvider([ctx(), ctx()]),
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: states.add,
      );

      await manager.init();
      states.clear();
      final result = await manager.refreshForTest();
      expect(result, RefreshAuthKeyResult.failedOther);
      expect(refreshCalls, 1);
      expect(states.last, MessengerSessionState.error);
      // Сессия НЕ обнулена — host-app может попробовать `reauthenticate()`
      // позже, текущий токен ещё может работать.
      expect(manager.session, isNotNull);

      await manager.dispose();
    },
  );

  test(
    'refresh: provider вернул ctx с другим fingerprint → создаём новую сессию',
    () async {
      // На init юзер 'alice'; перед refresh provider даёт 'bob'.
      final providerCtxs = [
        ctx(externalUserId: 'alice'),
        ctx(externalUserId: 'bob'),
      ];
      final provider = _FakeProvider(providerCtxs);

      var sessionCalls = 0;
      var refreshCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async {
          sessionCalls++;
          return sessionFor(
            token: 'tok-${c.externalUserId}',
            validFor: const Duration(hours: 24),
          );
        },
        refreshRpc: (c) async {
          refreshCalls++;
          // Не должен вызываться при mismatch — менеджер делает session,
          // не refresh.
          throw StateError('refresh не должен вызываться при fp-mismatch');
        },
        authTokenProvider: provider,
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: (_) {},
      );

      await manager.init();
      expect(sessionCalls, 1);
      expect(manager.session?.sessionToken, 'tok-alice');

      final result = await manager.refreshForTest();
      expect(result, RefreshAuthKeyResult.success);
      expect(refreshCalls, 0);
      expect(
        sessionCalls,
        2,
        reason: 'fp mismatch → новая session, не refresh',
      );
      expect(manager.session?.sessionToken, 'tok-bob');

      await manager.dispose();
    },
  );

  test(
    'dispose() во время in-flight refresh → store.write не происходит',
    () async {
      // Симулируем: refreshRpc «зависает» на 200ms, в это время host-app
      // зовёт dispose(). По возвращении rpc-результата manager должен
      // ничего не писать в store (guard `_disposed` после await). См.
      // ревью 3e7e61b #2.
      final store = InMemoryAuthTokenStore();
      final completer = Completer<MessengerSession>();

      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c) => completer.future,
        authTokenProvider: _FakeProvider([ctx(), ctx()]),
        store: store,
        errorReporter: null,
        emitState: (_) {},
      );

      await manager.init();
      final tokenAfterInit = (await store.read())!.session.sessionToken;
      expect(tokenAfterInit, 'live');

      // Стартуем refresh, не дожидаясь его завершения.
      final refreshFuture = manager.refreshForTest();

      // Сразу же dispose(), пока refreshRpc висит на completer.future.
      await manager.dispose();

      // Теперь «отпускаем» rpc — manager должен увидеть _disposed=true и
      // не писать новый токен в store.
      completer.complete(
        sessionFor(
          token: 'after-dispose-this-must-not-land',
          validFor: const Duration(hours: 24),
        ),
      );
      final result = await refreshFuture;
      expect(result, RefreshAuthKeyResult.failedOther);

      // В store по-прежнему 'live', не 'after-dispose-...'.
      final stored = await store.read();
      expect(stored!.session.sessionToken, 'live');
    },
  );

  test('reauthenticate(): clear store + новый init', () async {
    var sessionCalls = 0;
    final store = InMemoryAuthTokenStore();
    final manager = MessengerSessionManager.attachWithRpcs(
      sessionRpc: (c) async {
        sessionCalls++;
        return sessionFor(
          token: 'tok-$sessionCalls',
          validFor: const Duration(hours: 24),
        );
      },
      refreshRpc: (c) async => throw StateError('не должно вызываться'),
      authTokenProvider: _FakeProvider([ctx(), ctx()]),
      store: store,
      errorReporter: null,
      emitState: (_) {},
    );
    await manager.init();
    expect(sessionCalls, 1);
    final firstToken = manager.session!.sessionToken;

    await manager.reauthenticate();
    expect(sessionCalls, 2);
    expect(manager.session!.sessionToken, isNot(firstToken));
    await manager.dispose();
  });
}

/// Простейший AuthTokenProvider, отдающий заранее заданные ctx-ы по
/// очереди. После исчерпания списка повторяет последний.
class _FakeProvider implements AuthTokenProvider {
  final List<MessengerAuthContext> _queue;
  int _idx = 0;
  _FakeProvider(this._queue) : assert(_queue.isNotEmpty);

  @override
  Future<MessengerAuthContext> getAuthContext() async {
    final ctx = _idx < _queue.length ? _queue[_idx] : _queue.last;
    _idx++;
    return ctx;
  }
}

/// SocketException-stub без зависимости от dart:io (тест проходит
/// и в web-режиме). Семантически — non-auth ошибка сети.
class _FakeSocketException implements Exception {
  final String message;
  const _FakeSocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}
