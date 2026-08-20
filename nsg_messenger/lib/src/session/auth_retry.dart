import 'dart:async';
import 'dart:io';

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

/// **issue #135**: транспортная ошибка — канал протух, а не запрос
/// невозможен.
///
/// Отличается от [isAuthInvalidation] тем, что говорит о СВЯЗИ, а не о
/// праве: токен жив, сервер, скорее всего, тоже. 13.08.2026 экран
/// мониторинга упирался в такое намертво — двадцать секунд ожидания и
/// тупик до перезапуска приложения, при том что сервер отвечал за 2 мс, а
/// соседний вызов тем же клиентом проходил. В GlitchTip эта подпись
/// копилась пять недель.
///
/// Восстановление у нас было построено ТОЛЬКО для авторизации, и это
/// решение верное по своей задаче — но за транспортом при этом не следил
/// никто.
///
/// Сюда НЕ входят серверные отказы (5xx, 403, разбор ответа): повторять
/// их вслепую значит удваивать нагрузку ровно тогда, когда серверу плохо.
///
/// **Первая редакция этой функции на живом пути не срабатывала НИ РАЗУ**
/// (найдено живой проверкой 15.08.2026). Сырые `SocketException` и
/// `ClientException` до приложения не доходят: клиент Serverpod ловит их
/// сам и заворачивает в `ServerpodClientException(текст, -1)` —
/// `serverpod_client_io.dart:75` и `serverpod_client_browser.dart:59-61`.
/// Уцелел только путь тайм-аута: `TimeoutException` бросает `.timeout()`
/// выше этих catch-ей. Поэтому при обрыве связи (перезапуск сервера —
/// случай куда более частый, чем молчание) человеку по-прежнему
/// показывалось `statusCode = -1` в лицо, то есть ровно симптом заявки.
///
/// Тесты этого не поймали, потому что кормили предикат сырыми типами
/// напрямую — тем, чего на живом пути не бывает. Ниже они кормят его тем,
/// что клиент бросает НА САМОМ ДЕЛЕ.
bool isTransportFailure(Object error) {
  if (error is TimeoutException) return true;
  if (error is ServerpodClientException &&
      error.statusCode == transportStatusCode) {
    return true;
  }
  // Сырые типы оставлены: путь мимо клиента Serverpod (свои HTTP-вызовы,
  // будущие каналы) обязан пониматься так же.
  if (error is SocketException) return true;
  if (error is HandshakeException) return true;
  // `HttpException` без ответа — оборванное соединение (не путать с
  // ответом об ошибке: у того есть статус, и он приезжает типизированным).
  if (error is HttpException) return true;
  return false;
}

/// `statusCode`, которым клиент Serverpod помечает «ответа не было вовсе».
///
/// В пакете это значение ставится ровно в двух местах — обёртках
/// `SocketException` (io) и `http.ClientException` (browser); настоящий
/// HTTP-статус здесь невозможен. Поэтому `-1` — надёжный признак
/// транспортного отказа, а не догадка по тексту сообщения.
const int transportStatusCode = -1;

/// Шлюз не дозвался до сервера: 502/503/504.
///
/// **Это не отказ приложения, а его отсутствие.** nginx отвечает такой
/// страницей, когда за ним никого нет: сервер перезапускается, выкатывается
/// или лежит. Тела с предметной причиной там нет вовсе — есть HTML-заглушка
/// шлюза.
///
/// Найдено по жалобе 16.08.2026: во время выкатки человек открыл мониторинг и
/// получил на экран `ServerpodClientException: Unknown error, data:` и следом
/// целиком HTML-страницу «502 Bad Gateway» со `statusCode = 502`. Формально это
/// ответ сервера, поэтому под [isTransportFailure] он не подпадал и разметка
/// шлюза уезжала человеку в лицо — ровно та беда, ради которой заводился
/// #135, только с другого входа.
///
/// Отдельно от 5xx вообще: 500 у нас означает сбой обработчика, и там
/// подробность помогает поддержке. А 502/503/504 подробности не несут.
bool isServerUnavailable(Object error) =>
    error is ServerpodClientException &&
    const {502, 503, 504}.contains(error.statusCode);

/// Показывать ли человеку «сервер недоступен» вместо текста исключения.
///
/// Одна мысль вместо двух: и мёртвая связь, и молчащий за шлюзом сервер для
/// человека — одно и то же положение («сейчас не работает, попробуйте
/// позже»), и лечится оно одинаково — кнопкой, а не текстом.
bool isUnreachable(Object error) =>
    isTransportFailure(error) || isServerUnavailable(error);

/// Стоит ли ПОВТОРЯТЬ — вопрос отдельный от «показать ли человеку
/// «нет связи»».
///
/// **Тайм-аут не повторяем, и это не оплошность.** `.timeout()` бросает
/// ожидание, но НЕ отменяет сам запрос: сокет остаётся занят. В браузере
/// на хост даётся шесть соединений — замер 15.08.2026 показал, что один
/// заход экрана мониторинга (четыре вызова) с повтором забивает пул
/// целиком, и следующее нажатие «Повторить» до сети уже не доходит вовсе,
/// при живом сервере. То есть для молчащей связи повтор делал ХУЖЕ:
/// удваивал ожидание (16,5 с вместо 8,3) и съедал пул вдвое быстрее.
///
/// А вот мгновенный отказ повторять и дёшево, и осмысленно: соединение уже
/// закрыто, пул свободен, и вторая попытка через 300 мс ловит ровно ту
/// сетевую икоту, ради которой всё затевалось.
///
/// Молчание же лечится не повтором, а честным отказом за восемь секунд и
/// кнопкой у человека — по-настоящему его вылечила бы отмена запроса, но
/// сгенерированный `Client` наружу ни делегата, ни `HttpClient` не отдаёт.
bool shouldRetryTransport(Object error) {
  if (error is TimeoutException) return false;
  return isTransportFailure(error);
}

/// Сколько ждём ответа сервера, прежде чем считать канал мёртвым.
///
/// Умолчание Serverpod — двадцать секунд, и это цена одного отказа для
/// человека, смотрящего в крутилку (issue #135). Восемь — компромисс:
/// слабая мобильная сеть по TLS законно отдаёт первый байт через
/// несколько секунд, а вот не ответившая за восемь почти никогда не
/// отвечает за двадцать.
const Duration clientConnectionTimeout = Duration(seconds: 8);

/// Пауза перед повтором транспортной ошибки.
///
/// Не ноль: мгновенный повтор попадает в ту же секунду сетевой икоты и
/// чаще всего повторяет отказ. И не секунды: человек уже ждёт, а мы лишь
/// добираем шанс, а не выжидаем выздоровления.
const Duration transportRetryDelay = Duration(milliseconds: 300);

/// Одна повторная попытка на транспортной ошибке.
///
/// **Почему ровно одна.** Вторая уже не про икоту, а про недоступность —
/// её лечит не повтор, а честный отказ с кнопкой у человека. Бесконечный
/// повтор превратил бы тупик в тупик с крутилкой.
///
/// **Чего эта обёртка НЕ делает — и это надо знать.** Она не отменяет
/// зависший запрос: `Client` из сгенерированного кода не отдаёт наружу ни
/// свой `HttpClient`, ни делегат запросов, а закрыть его целиком значит
/// порвать и поток событий. Поэтому молчащая связь лечится здесь только
/// ценой ожидания (восемь секунд вместо двадцати), а не по существу —
/// и повторять её нельзя, см. [shouldRetryTransport].
Future<T> withTransportRetry<T>(
  Future<T> Function() rpc, {
  Duration delay = transportRetryDelay,
}) async {
  try {
    return await rpc();
  } catch (e) {
    if (!shouldRetryTransport(e)) rethrow;
    await Future<void>.delayed(delay);
    return await rpc();
  }
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
  // **issue #135**: транспорт лечится ВНУТРИ, чтобы это получили все, кто
  // уже зовёт `withAuthRetry`, — экраны звали именно её и упирались в
  // тупик. Порядок важен: сперва отрабатывает повтор связи, и только
  // дошедший до сервера ответ разбирается на auth-invalidation.
  Future<T> call() => withTransportRetry(rpc);
  try {
    return await call();
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
    return await call();
  }
}
