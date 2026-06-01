import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Сохранённая на диск/в-память запись о MessengerSession.
///
/// Хранит:
///   * `fingerprint` — sha256 от identity-фактов `MessengerAuthContext`-а
///     (tenant/product/provider/externalUserId), чтобы при смене юзера
///     не подтянуть чужую запись из storage-а;
///   * сам `MessengerSession`, выданный backend-ом (`sessionToken`,
///     `messengerUserId`, `expiresAt`, `matrixUserId` и пр.).
///
/// `accessToken` интегратора **никогда** в этой записи не хранится —
/// SDK всегда дёргает `AuthTokenProvider.getAuthContext()` за свежим.
@immutable
class StoredMessengerSession {
  final String fingerprint;
  final MessengerSession session;
  final DateTime storedAt;

  const StoredMessengerSession({
    required this.fingerprint,
    required this.session,
    required this.storedAt,
  });

  Map<String, dynamic> toJson() => {
    'fingerprint': fingerprint,
    'storedAt': storedAt.toIso8601String(),
    'session': session.toJson(),
  };

  static StoredMessengerSession fromJson(Map<String, dynamic> json) =>
      StoredMessengerSession(
        fingerprint: json['fingerprint'] as String,
        storedAt: DateTime.parse(json['storedAt'] as String),
        session: MessengerSession.fromJson(
          (json['session'] as Map).cast<String, dynamic>(),
        ),
      );
}

/// Контракт persistence-слоя для активной сессии. Реализаций две:
///   * [SecureAuthTokenStore] — production: flutter_secure_storage с
///     fallback-ом на in-memory при ошибке (Windows DPAPI бывает
///     капризным; см. ревью 51c1094 п.4);
///   * [InMemoryAuthTokenStore] — для тестов и web-fallback.
///
/// Все методы async, чтобы реализация могла лежать в native-канале.
abstract class AuthTokenStore {
  Future<StoredMessengerSession?> read();
  Future<void> write(StoredMessengerSession value);
  Future<void> clear();
}

/// Production-impl поверх `flutter_secure_storage`. Любая ошибка чтения
/// или записи деградирует на in-memory кеш + warning через `debugPrint`,
/// чтобы SDK работал даже на сломанной DPAPI/Keychain (приложение
/// продолжит запрашивать `AuthTokenProvider.getAuthContext()` каждый
/// init вместо использования cached сессии — это потеря производительности,
/// не потеря функциональности).
class SecureAuthTokenStore implements AuthTokenStore {
  static const _storageKey = 'nsg_messenger.session.v1';

  final FlutterSecureStorage _storage;

  /// Резервный in-memory кеш на случай, если secure_storage падает на
  /// конкретной платформе/конфигурации. Если read из secure упал — пишем
  /// сюда; следующий read попытается snapshot отдать.
  StoredMessengerSession? _memoryFallback;

  SecureAuthTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<StoredMessengerSession?> read() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null) return _memoryFallback;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final value = StoredMessengerSession.fromJson(json);
      _memoryFallback = value;
      return value;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[nsg_messenger] secure_storage read failed, '
          'using memory fallback: $e\n$st',
        );
      }
      return _memoryFallback;
    }
  }

  @override
  Future<void> write(StoredMessengerSession value) async {
    _memoryFallback = value;
    try {
      // iOS Keychain bug: `write` поверх существующего item-а возвращает
      // `-25299 errSecDuplicateItem` (flutter_secure_storage issue
      // dart-lang/flutter_secure_storage#43). Гарантированный fix —
      // `delete` перед `write`. На Android / Linux / Windows / Web
      // delete-of-missing — no-op.
      await _storage.delete(key: _storageKey);
      await _storage.write(key: _storageKey, value: jsonEncode(value.toJson()));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[nsg_messenger] secure_storage write failed, '
          'kept in memory only: $e\n$st',
        );
      }
    }
  }

  @override
  Future<void> clear() async {
    _memoryFallback = null;
    try {
      await _storage.delete(key: _storageKey);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[nsg_messenger] secure_storage delete failed, '
          'memory fallback cleared: $e\n$st',
        );
      }
    }
  }
}

/// Тестовая / fallback-имплементация. Никакой персистенции, всё в RAM.
class InMemoryAuthTokenStore implements AuthTokenStore {
  StoredMessengerSession? _value;

  @override
  Future<StoredMessengerSession?> read() async => _value;

  @override
  Future<void> write(StoredMessengerSession value) async => _value = value;

  @override
  Future<void> clear() async => _value = null;
}
