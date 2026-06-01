import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/session/auth_context_fingerprint.dart';

/// Контракт: fingerprint детерминирован, не зависит от accessToken,
/// чувствителен к каждому identity-полю. Если этот тест упадёт после
/// изменения формулы — это breaking change для уже существующих
/// записей в SecureAuthTokenStore (старые fingerprint-ы перестанут
/// совпадать с провайдер-ским ctx, на старте SDK сделает лишний
/// session() вместо использования кэша).
void main() {
  MessengerAuthContext ctx({
    String tenant = 'nsg',
    String? product = 'chatista',
    IdentityProvider provider = IdentityProvider.nsg,
    String externalUserId = 'alice',
    String accessToken = 'token-1',
  }) => MessengerAuthContext(
    tenantExternalKey: tenant,
    productExternalKey: product,
    identityProvider: provider,
    externalUserId: externalUserId,
    accessToken: accessToken,
  );

  group('authContextFingerprint', () {
    test('детерминирован — одинаковый ctx → одинаковый fingerprint', () {
      final a = authContextFingerprint(ctx());
      final b = authContextFingerprint(ctx());
      expect(a, b);
      expect(a.length, 64); // sha256 hex
    });

    test('не зависит от accessToken (в этом и смысл refresh-а)', () {
      final a = authContextFingerprint(ctx(accessToken: 'token-1'));
      final b = authContextFingerprint(ctx(accessToken: 'token-2-rotated'));
      expect(a, b);
    });

    test('чувствителен к externalUserId', () {
      final a = authContextFingerprint(ctx(externalUserId: 'alice'));
      final b = authContextFingerprint(ctx(externalUserId: 'bob'));
      expect(a, isNot(b));
    });

    test('чувствителен к tenantExternalKey', () {
      final a = authContextFingerprint(ctx(tenant: 'nsg'));
      final b = authContextFingerprint(ctx(tenant: 'foreign'));
      expect(a, isNot(b));
    });

    test('чувствителен к productExternalKey, включая null vs ""', () {
      final empty = authContextFingerprint(ctx(product: ''));
      final nullProd = authContextFingerprint(ctx(product: null));
      // Null трактуем как пустую строку — оба варианта дают одинаковый
      // fingerprint, но при смене null↔"chatista" fingerprint меняется.
      expect(empty, nullProd);
      final chatista = authContextFingerprint(ctx(product: 'chatista'));
      expect(chatista, isNot(empty));
    });

    test('чувствителен к identityProvider', () {
      final a = authContextFingerprint(ctx(provider: IdentityProvider.nsg));
      final b = authContextFingerprint(
        ctx(provider: IdentityProvider.customer),
      );
      expect(a, isNot(b));
    });
  });
}
