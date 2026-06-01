import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Контракт интегратора, см. TASK12 для полной спецификации.
///
/// SDK дёргает `getAuthContext()` при первом `init()`, при истечении
/// `MessengerSession.expiresAt` (за 5 мин) и при 401 от любого endpoint-а.
/// Каждый раз интегратор обязан:
///   1. Убедиться, что customer accessToken актуален (refresh у себя).
///   2. Вернуть `MessengerAuthContext` со свежим accessToken.
///
/// SDK НЕ хранит customer accessToken между вызовами — только серверный
/// `sessionToken`.
abstract class AuthTokenProvider {
  Future<MessengerAuthContext> getAuthContext();
}

/// Опциональный hook для отправки ошибок SDK в host-app-овский Sentry
/// (или любой другой error tracker). Если не передан — SDK сам ничего
/// не репортит, ошибки уходят в обычный flutter `print` через
/// `debugPrint`.
///
/// Пример: `nsg_messenger_sentry` пакет (или host-app inline):
/// ```dart
/// class SentryErrorReporter implements ErrorReporter {
///   @override
///   void reportError(Object error, StackTrace? stack, {Map<String, String>? tags}) {
///     Sentry.captureException(error, stackTrace: stack, hint: Hint.withMap(tags ?? {}));
///   }
/// }
/// ```
abstract class ErrorReporter {
  void reportError(
    Object error,
    StackTrace? stack, {
    Map<String, String>? tags,
  });
}
