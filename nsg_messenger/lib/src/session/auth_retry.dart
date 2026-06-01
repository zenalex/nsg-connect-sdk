import 'dart:async';

import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'messenger_session_manager.dart';

/// **TASK20 followup (b)**: helpers вокруг self-healing для stale
/// `sessionToken`.
///
/// Архитектурный контекст:
///
///   * `Serverpod-client` уже catch-ит `ServerpodClientUnauthorized`
///     (HTTP 401) на каждом RPC и автоматически вызывает
///     `MutexRefresherClientAuthKeyProvider.refreshAuthKey()` → наш
///     `_refreshAuthKey()`. Если refresh успешен — RPC ретраится
///     прозрачно для caller-а. См.
///     `serverpod_client_shared.dart::callServerEndpoint`. → 401-сценарий
///     УЖЕ работает без дополнительного кода в SDK.
///
///   * Что НЕ работает автоматически: типизированное
///     [MessengerNotAuthenticatedException] — оно сериализуется как
///     обычный SerializableException и приезжает к клиенту НЕ через
///     HTTP 401, а как regular endpoint-response → Serverpod бросает
///     его наверх и НЕ запускает 401-retry pipeline. Этот wrapper
///     закрывает дыру.
///
/// **Red-line constraint** (от пользователя): token-кэш чистить ТОЛЬКО
/// на эксплицитном auth-invalidation от сервера. См. [isAuthInvalidation]
/// для исчерпывающего списка совпадающих типов.

/// Возвращает `true`, если [error] — ТОЧНО серверный сигнал «session
/// invalidated, надо обновлять токен». Любая другая ошибка (сеть,
/// timeout, 5xx, 403, generic Exception) — `false`, чтобы НЕ триггерить
/// очистку кэша.
///
/// Список совпадений (исчерпывающий):
///   * [MessengerNotAuthenticatedException] — серверный
///     `messenger_session_auth_handler` не смог аутентифицировать
///     запрос (токена нет, не тот scheme, токен revoke-нут/истёк);
///   * [InvalidTokenException] — `CustomerAuthAdapter` на сервере
///     отверг accessToken интегратора;
///   * [ServerpodClientUnauthorized] — HTTP 401 от Serverpod-канала
///     (этот случай уже обрабатывает Serverpod-client автоматически,
///     но если caller сам ловит auth-ошибку — мы должны их матчить).
///
/// **НЕ совпадает с**:
///   * `TimeoutException` / `SocketException` / `HandshakeException` /
///     `HttpException` без явного 401 — транспортный layer, токен жив;
///   * Generic `Exception` / `Object` — если бы матчили, упустили бы
///     network errors;
///   * HTTP 403 (Forbidden) — другой статус, означает "не разрешено",
///     токен НЕ обязательно мёртвый;
///   * HTTP 5xx — server problem, токен жив;
///   * `ServerpodClientException` без типа `Unauthorized` — generic
///     server error;
///   * `StateError` / `ArgumentError` и пр. программные ошибки.
bool isAuthInvalidation(Object error) {
  // Типизированные доменные exception-ы (codegen-нутые в
  // nsg_connect_client). Эти ИДУТ через regular endpoint-response, НЕ
  // через HTTP 401 — Serverpod auto-retry их не ловит.
  if (error is MessengerNotAuthenticatedException) return true;
  if (error is InvalidTokenException) return true;
  // HTTP 401, обычно уже отработан Serverpod-client-ом, но если
  // caller перехватил — тоже трактуем как auth-invalidation.
  if (error is ServerpodClientUnauthorized) return true;
  // Всё остальное — НЕ auth invalidation. Особенно намеренно не
  // матчим generic `ServerpodClientException` (5xx, parse errors,
  // network) и `TimeoutException` / `SocketException`.
  return false;
}

/// Обёртка вокруг RPC-вызова с авто-retry на серверный auth-invalidation.
///
/// **Логика**:
///   1. Вызвать [rpc].
///   2. Если упало → [isAuthInvalidation] проверяет тип. False →
///      `rethrow` (caller получает исходное network/5xx/403/etc.).
///   3. True → вызвать [session.selfHealStaleToken] (single-flight под
///      `_selfHealInProgress`).
///      * Refresh успешен → вызвать [rpc] ЕЩЁ РАЗ с новым токеном.
///      * Refresh упал — bubble up auth-исключение, host-app покажет
///        login UI.
///   4. Если retry ТОЖЕ падает с auth-invalidation → НЕ делаем третий
///      refresh (защита от infinite loop при server-side bug-е, когда
///      даже свежий токен отвергается). Throw исходное исключение
///      retry-вызова — пусть бубнит наверх.
///
/// **Single-flight гарантируется внутри `selfHealStaleToken`**: N
/// конкурентных вызовов `withAuthRetry` поймали один и тот же
/// auth-error, все зовут selfHeal — только первый делает реальный
/// refresh, остальные ждут его future. После refresh все N retry-ятся
/// с новым токеном.
///
/// **Пример**:
/// ```dart
/// final rooms = await withAuthRetry(
///   () => client.messenger.listRooms(),
///   sessionManager,
/// );
/// ```
///
/// **Где НЕ нужен**:
///   * `messenger.session(ctx)` и `messenger.refresh(ctx)` — auth-эндпоинты
///     помечены `@unauthenticatedClientCall`, они НЕ возвращают
///     `MessengerNotAuthenticatedException`. Wrapping приведёт к
///     путанице (но не сломает).
Future<T> withAuthRetry<T>(
  Future<T> Function() rpc,
  MessengerSessionManager session,
) async {
  try {
    return await rpc();
  } catch (e) {
    if (!isAuthInvalidation(e)) {
      // Любая non-auth ошибка — пробрасываем как есть. Токен НЕ
      // трогаем. Это RED-LINE контракт от пользователя.
      rethrow;
    }
    // Поймали типизированный auth-сигнал → self-heal.
    try {
      await session.selfHealStaleToken();
    } catch (_) {
      // Self-heal не смог обновить токен — host-app получит исходное
      // auth-исключение (NotAuth / InvalidToken). selfHealStaleToken
      // уже выставил MessengerSessionState.expired, host-app покажет
      // login UI через свой listener.
      rethrow;
    }
    // Retry один раз с новым токеном. Если retry ТОЖЕ падает с
    // auth-invalidation — бросаем НЕ зацикливаясь (server-side bug
    // или race, host-app разрулит).
    return await rpc();
  }
}
