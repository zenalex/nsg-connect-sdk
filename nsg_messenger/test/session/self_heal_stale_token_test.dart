import 'dart:async';
import 'dart:io' show HandshakeException, HttpException, SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/session/messenger_session_manager.dart';

/// **TASK20 followup (b)**: тесты stale-token self-healing.
///
/// Сценарии: happy path / refresh fails / single-flight / network-error
/// no-op / 5xx no-op / 403 no-op / infinite-loop guard / store clear
/// on failedUnauthorized.
void main() {
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
  }) => MessengerSession(
    sessionToken: token,
    messengerUserId: 42,
    matrixUserId: '@alice:localhost',
    tenantId: 1,
    expiresAt: DateTime.now().toUtc().add(validFor),
  );

  // ─────────────────────────────────────────────────────────────
  // isAuthInvalidation predicate
  // ─────────────────────────────────────────────────────────────

  group('isAuthInvalidation predicate', () {
    test('MessengerNotAuthenticatedException → true', () {
      expect(isAuthInvalidation(MessengerNotAuthenticatedException()), isTrue);
    });

    test('InvalidTokenException → true', () {
      expect(isAuthInvalidation(InvalidTokenException(reason: 'x')), isTrue);
    });

    test('ServerpodClientUnauthorized → true', () {
      expect(isAuthInvalidation(ServerpodClientUnauthorized()), isTrue);
    });

    test('TimeoutException → false (transport, NOT auth)', () {
      expect(isAuthInvalidation(TimeoutException('network slow')), isFalse);
    });

    test('SocketException → false (transport, NOT auth)', () {
      expect(
        isAuthInvalidation(const SocketException('connection refused')),
        isFalse,
      );
    });

    test('HandshakeException → false (TLS, NOT auth)', () {
      expect(isAuthInvalidation(const HandshakeException('tls fail')), isFalse);
    });

    test('HttpException without 401 → false', () {
      expect(isAuthInvalidation(const HttpException('500')), isFalse);
    });

    test('Generic Exception → false', () {
      expect(isAuthInvalidation(Exception('boom')), isFalse);
    });

    test('StateError → false (program bug, NOT auth)', () {
      expect(isAuthInvalidation(StateError('x')), isFalse);
    });

    test('Generic ServerpodClientException → false (5xx etc.)', () {
      expect(
        isAuthInvalidation(
          ServerpodClientException('internal server error', 500),
        ),
        isFalse,
      );
    });

    test('"403 Forbidden"-style string → false', () {
      // String literal doesn't match — we look for typed exceptions only.
      expect(isAuthInvalidation('403 Forbidden'), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // withAuthRetry — wrapper behavior
  // ─────────────────────────────────────────────────────────────

  group('withAuthRetry — happy path', () {
    test('RPC succeeds first time → no refresh, no retry', () async {
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async => throw StateError('refresh must NOT be called'),
        authTokenProvider: _FakeProvider([ctx()]),
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: (_) {},
      );
      await manager.init();

      var rpcCalls = 0;
      final result = await withAuthRetry(() async {
        rpcCalls++;
        return 'ok';
      }, manager);

      expect(result, 'ok');
      expect(rpcCalls, 1);
      await manager.dispose();
    });

    test(
      'RPC fails with MessengerNotAuth → selfHeal → retry succeeds',
      () async {
        var refreshCalls = 0;
        final manager = MessengerSessionManager.attachWithRpcs(
          sessionRpc: (c) async => sessionFor(
            token: 'tok-initial',
            validFor: const Duration(hours: 24),
          ),
          refreshRpc: (c, {previousToken}) async {
            refreshCalls++;
            return sessionFor(
              token: 'tok-refreshed',
              validFor: const Duration(hours: 24),
            );
          },
          authTokenProvider: _FakeProvider([ctx(), ctx()]),
          store: InMemoryAuthTokenStore(),
          errorReporter: null,
          emitState: (_) {},
        );
        await manager.init();

        var rpcCalls = 0;
        final result = await withAuthRetry(() async {
          rpcCalls++;
          if (rpcCalls == 1) throw MessengerNotAuthenticatedException();
          return 'ok-after-refresh';
        }, manager);

        expect(result, 'ok-after-refresh');
        expect(rpcCalls, 2, reason: 'failed once, retried once');
        expect(refreshCalls, 1, reason: 'self-heal triggered refresh once');
        expect(manager.session?.sessionToken, 'tok-refreshed');
        await manager.dispose();
      },
    );

    test(
      'RPC fails with InvalidTokenException → selfHeal → retry succeeds',
      () async {
        var refreshCalls = 0;
        final manager = MessengerSessionManager.attachWithRpcs(
          sessionRpc: (c) async => sessionFor(
            token: 'tok-initial',
            validFor: const Duration(hours: 24),
          ),
          refreshRpc: (c, {previousToken}) async {
            refreshCalls++;
            return sessionFor(
              token: 'tok-refreshed',
              validFor: const Duration(hours: 24),
            );
          },
          authTokenProvider: _FakeProvider([ctx(), ctx()]),
          store: InMemoryAuthTokenStore(),
          errorReporter: null,
          emitState: (_) {},
        );
        await manager.init();

        var rpcCalls = 0;
        final result = await withAuthRetry(() async {
          rpcCalls++;
          if (rpcCalls == 1) throw InvalidTokenException(reason: 'simulated');
          return 'ok';
        }, manager);

        expect(result, 'ok');
        expect(refreshCalls, 1);
        await manager.dispose();
      },
    );
  });

  group('withAuthRetry — non-auth errors MUST NOT trigger refresh', () {
    test('TimeoutException → no refresh, original error rethrown', () async {
      var refreshCalls = 0;
      final store = InMemoryAuthTokenStore();
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async {
          refreshCalls++;
          throw StateError('refresh MUST NOT be called on network error');
        },
        authTokenProvider: _FakeProvider([ctx()]),
        store: store,
        errorReporter: null,
        emitState: (_) {},
      );
      await manager.init();
      final tokenBefore = manager.session!.sessionToken;
      final storeBefore = await store.read();

      await expectLater(
        () =>
            withAuthRetry(() async => throw TimeoutException('slow'), manager),
        throwsA(isA<TimeoutException>()),
      );
      expect(refreshCalls, 0, reason: 'network error MUST NOT trigger refresh');
      // Token unchanged, store unchanged.
      expect(manager.session?.sessionToken, tokenBefore);
      expect(
        (await store.read())?.session.sessionToken,
        storeBefore?.session.sessionToken,
      );
      await manager.dispose();
    });

    test('SocketException → no refresh, original error rethrown', () async {
      var refreshCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async {
          refreshCalls++;
          throw StateError('refresh MUST NOT be called');
        },
        authTokenProvider: _FakeProvider([ctx()]),
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: (_) {},
      );
      await manager.init();

      await expectLater(
        () => withAuthRetry(
          () async => throw const SocketException('no route'),
          manager,
        ),
        throwsA(isA<SocketException>()),
      );
      expect(refreshCalls, 0);
      await manager.dispose();
    });

    test('Generic ServerpodClientException 5xx → no refresh', () async {
      var refreshCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async {
          refreshCalls++;
          throw StateError('refresh MUST NOT be called');
        },
        authTokenProvider: _FakeProvider([ctx()]),
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: (_) {},
      );
      await manager.init();

      await expectLater(
        () => withAuthRetry(
          () async => throw ServerpodClientException('500 internal', 500),
          manager,
        ),
        throwsA(isA<ServerpodClientException>()),
      );
      expect(refreshCalls, 0);
      await manager.dispose();
    });

    test('Generic Exception (403-ish wrapper) → no refresh', () async {
      var refreshCalls = 0;
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async {
          refreshCalls++;
          throw StateError('refresh MUST NOT be called');
        },
        authTokenProvider: _FakeProvider([ctx()]),
        store: InMemoryAuthTokenStore(),
        errorReporter: null,
        emitState: (_) {},
      );
      await manager.init();

      await expectLater(
        () => withAuthRetry(
          () async => throw Exception('403 Forbidden'),
          manager,
        ),
        throwsA(isA<Exception>()),
      );
      expect(refreshCalls, 0);
      await manager.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Single-flight
  // ─────────────────────────────────────────────────────────────

  group('withAuthRetry — single-flight', () {
    test(
      'N concurrent RPCs all fail with auth → single refresh, all retry',
      () async {
        var refreshCalls = 0;
        final refreshCompleter = Completer<MessengerSession>();
        final manager = MessengerSessionManager.attachWithRpcs(
          sessionRpc: (c) async => sessionFor(
            token: 'tok-initial',
            validFor: const Duration(hours: 24),
          ),
          refreshRpc: (c, {previousToken}) async {
            refreshCalls++;
            return refreshCompleter.future;
          },
          authTokenProvider: _FakeProvider(List.generate(10, (_) => ctx())),
          store: InMemoryAuthTokenStore(),
          errorReporter: null,
          emitState: (_) {},
        );
        await manager.init();

        // 5 concurrent RPCs each failing once with auth, then succeeding.
        final rpcCallsPerCaller = <int, int>{};
        Future<String> caller(int id) => withAuthRetry(() async {
          rpcCallsPerCaller.update(id, (v) => v + 1, ifAbsent: () => 1);
          if (rpcCallsPerCaller[id] == 1) {
            throw MessengerNotAuthenticatedException();
          }
          return 'ok-$id-${manager.session!.sessionToken}';
        }, manager);

        final futures = [for (var i = 0; i < 5; i++) caller(i)];
        // Let all 5 race to selfHeal; refreshRpc is awaiting completer.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Single refresh in-flight at this point.
        expect(
          refreshCalls,
          1,
          reason: 'single-flight: 1 refresh for 5 callers',
        );
        // Unblock refresh.
        refreshCompleter.complete(
          sessionFor(
            token: 'tok-refreshed',
            validFor: const Duration(hours: 24),
          ),
        );

        final results = await Future.wait(futures);
        for (final r in results) {
          expect(r, endsWith('tok-refreshed'));
        }
        expect(
          refreshCalls,
          1,
          reason: 'refresh stayed at 1 even after all retries',
        );
        await manager.dispose();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────
  // selfHealStaleToken — failure paths
  // ─────────────────────────────────────────────────────────────

  group('selfHealStaleToken — failure paths', () {
    test('refresh fails with InvalidTokenException → state.expired, '
        'store cleared, throws', () async {
      final store = InMemoryAuthTokenStore();
      final states = <MessengerSessionState>[];
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async =>
            throw InvalidTokenException(reason: 'simulated expiry'),
        authTokenProvider: _FakeProvider([ctx(), ctx()]),
        store: store,
        errorReporter: null,
        emitState: states.add,
      );
      await manager.init();
      // Stored after init.
      expect(await store.read(), isNotNull);
      states.clear();

      await expectLater(
        () => manager.selfHealStaleToken(),
        throwsA(isA<StateError>()),
      );
      // **CRITICAL**: store cleared on typed auth-invalidation.
      expect(await store.read(), isNull);
      expect(states.last, MessengerSessionState.expired);
      expect(manager.session, isNull);
      // Auth header empty → next RPC goes без Authorization.
      expect(await manager.currentAuthHeaderValueForTest, isNull);
      await manager.dispose();
    });

    test('refresh fails with network error → state.error, '
        'store NOT cleared, token preserved', () async {
      final store = InMemoryAuthTokenStore();
      final states = <MessengerSessionState>[];
      final manager = MessengerSessionManager.attachWithRpcs(
        sessionRpc: (c) async =>
            sessionFor(token: 'live', validFor: const Duration(hours: 24)),
        refreshRpc: (c, {previousToken}) async => throw const SocketException('offline'),
        authTokenProvider: _FakeProvider([ctx(), ctx()]),
        store: store,
        errorReporter: null,
        emitState: states.add,
      );
      await manager.init();
      final storeBefore = await store.read();
      final tokenBefore = manager.session!.sessionToken;
      states.clear();

      await expectLater(
        () => manager.selfHealStaleToken(),
        throwsA(isA<StateError>()),
      );
      // **CRITICAL**: store NOT cleared on network error.
      final storeAfter = await store.read();
      expect(storeAfter, isNotNull);
      expect(
        storeAfter!.session.sessionToken,
        storeBefore!.session.sessionToken,
      );
      // Session still alive on manager side.
      expect(manager.session?.sessionToken, tokenBefore);
      expect(states.last, MessengerSessionState.error);
      await manager.dispose();
    });

    test(
      'withAuthRetry — refresh fails unauthorized → second RPC NOT attempted',
      () async {
        var rpcCalls = 0;
        final manager = MessengerSessionManager.attachWithRpcs(
          sessionRpc: (c) async =>
              sessionFor(token: 'live', validFor: const Duration(hours: 24)),
          refreshRpc: (c, {previousToken}) async => throw InvalidTokenException(reason: 'dead'),
          authTokenProvider: _FakeProvider([ctx(), ctx()]),
          store: InMemoryAuthTokenStore(),
          errorReporter: null,
          emitState: (_) {},
        );
        await manager.init();

        await expectLater(
          () => withAuthRetry(() async {
            rpcCalls++;
            throw MessengerNotAuthenticatedException();
          }, manager),
          throwsA(
            anyOf(isA<MessengerNotAuthenticatedException>(), isA<StateError>()),
          ),
        );
        // RPC tried exactly once — refresh died, no second attempt.
        expect(rpcCalls, 1);
        await manager.dispose();
      },
    );
  });

  // ─────────────────────────────────────────────────────────────
  // Infinite-loop guard
  // ─────────────────────────────────────────────────────────────

  group('withAuthRetry — infinite-loop guard', () {
    test(
      'retry ALSO fails with auth-error → NO third refresh, throws',
      () async {
        var refreshCalls = 0;
        final manager = MessengerSessionManager.attachWithRpcs(
          sessionRpc: (c) async => sessionFor(
            token: 'tok-initial',
            validFor: const Duration(hours: 24),
          ),
          refreshRpc: (c, {previousToken}) async {
            refreshCalls++;
            return sessionFor(
              token: 'tok-refreshed-$refreshCalls',
              validFor: const Duration(hours: 24),
            );
          },
          authTokenProvider: _FakeProvider([ctx(), ctx(), ctx()]),
          store: InMemoryAuthTokenStore(),
          errorReporter: null,
          emitState: (_) {},
        );
        await manager.init();

        var rpcCalls = 0;
        await expectLater(
          () => withAuthRetry(() async {
            rpcCalls++;
            // BOTH attempts throw auth-invalidation (broken server scenario).
            throw MessengerNotAuthenticatedException();
          }, manager),
          throwsA(isA<MessengerNotAuthenticatedException>()),
        );
        expect(rpcCalls, 2, reason: '1 original + 1 retry');
        expect(refreshCalls, 1, reason: 'exactly 1 refresh — no infinite loop');
        await manager.dispose();
      },
    );
  });
}

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
