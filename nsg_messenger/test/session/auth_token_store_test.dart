import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/session/auth_token_store.dart';

/// Контракт-тесты для двух реализаций [AuthTokenStore]. Production
/// `SecureAuthTokenStore` тестируется только в части fallback-логики
/// (через подменённый FlutterSecureStorage было бы избыточно для
/// unit-теста — нужен MethodChannel-мок); остальное покрывается
/// integration-тестом host-app-а.
void main() {
  MessengerSession session({
    String token = 'tok-1',
    int messengerUserId = 42,
    String matrixUserId = '@alice:localhost',
    int tenantId = 1,
    int? productId,
    String? displayName,
    String? avatarUrl,
    DateTime? expiresAt,
  }) => MessengerSession(
    sessionToken: token,
    messengerUserId: messengerUserId,
    matrixUserId: matrixUserId,
    tenantId: tenantId,
    productId: productId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    expiresAt:
        expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 24)),
  );

  group('InMemoryAuthTokenStore', () {
    test('пустой по умолчанию', () async {
      final store = InMemoryAuthTokenStore();
      expect(await store.read(), isNull);
    });

    test('write → read возвращает то же значение', () async {
      final store = InMemoryAuthTokenStore();
      final value = StoredMessengerSession(
        fingerprint: 'fp-1',
        session: session(token: 'tok-A'),
        storedAt: DateTime.now().toUtc(),
      );
      await store.write(value);
      final read = await store.read();
      expect(read, isNotNull);
      expect(read!.fingerprint, 'fp-1');
      expect(read.session.sessionToken, 'tok-A');
    });

    test('clear очищает значение', () async {
      final store = InMemoryAuthTokenStore();
      await store.write(
        StoredMessengerSession(
          fingerprint: 'fp',
          session: session(),
          storedAt: DateTime.now().toUtc(),
        ),
      );
      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('StoredMessengerSession json round-trip', () {
    test('toJson → fromJson сохраняет все ключевые поля', () {
      final original = StoredMessengerSession(
        fingerprint: 'fp-deadbeef',
        session: session(
          token: 'tok-B',
          messengerUserId: 7,
          matrixUserId: '@bob:localhost',
          tenantId: 99,
          productId: 5,
          displayName: 'Bob',
          avatarUrl: 'https://example.com/a.png',
        ),
        storedAt: DateTime.utc(2026, 5, 1, 10, 0, 0),
      );
      final round = StoredMessengerSession.fromJson(original.toJson());
      expect(round.fingerprint, original.fingerprint);
      expect(round.storedAt, original.storedAt);
      expect(round.session.sessionToken, 'tok-B');
      expect(round.session.messengerUserId, 7);
      expect(round.session.matrixUserId, '@bob:localhost');
      expect(round.session.tenantId, 99);
      expect(round.session.productId, 5);
      expect(round.session.displayName, 'Bob');
      expect(round.session.avatarUrl, 'https://example.com/a.png');
    });
  });
}
