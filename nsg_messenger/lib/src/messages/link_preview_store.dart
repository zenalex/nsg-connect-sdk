/// **issue #90**: клиентская сторона превью ссылок — кто и когда спрашивает
/// сервер.
///
/// По ссылке ходит сервер (см. `LinkPreviewService` — это про приватность
/// участников чата, а не про удобство). Задача клиента — спросить один раз
/// и не долбить: лента перестраивается на каждый чих (новое сообщение,
/// прокрутка, смена темы), и наивный «запросить в build» превратил бы
/// одну ссылку в поток запросов.
library;

import 'dart:async';

import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// RPC-абстракция (как [MessagesRpc] и прочие в SDK) — чтобы стор
/// тестировался hand-written фейком, без сети и без Serverpod.
abstract class LinkPreviewRpc {
  /// Превью для [urls]. В ответе МОГУТ отсутствовать некоторые из них —
  /// значит, показывать нечего (сервер не достучался или разметки нет).
  Future<List<LinkPreviewView>> getLinkPreviews(List<String> urls);
}

/// Продакшн-реализация: generated Serverpod-client через `withAuthRetry`.
class ClientLinkPreviewRpc implements LinkPreviewRpc {
  ClientLinkPreviewRpc(this._client);

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  @override
  Future<List<LinkPreviewView>> getLinkPreviews(List<String> urls) =>
      withAuthRetry(
        () => _client.messenger.getLinkPreviews(urls: urls),
        _session,
      );
}

/// Кэш превью на время работы приложения + склейка запросов.
///
/// Живёт один на приложение: одна и та же ссылка встречается в разных
/// комнатах и всплывает при каждой прокрутке назад.
class LinkPreviewStore {
  LinkPreviewStore(this._rpc);

  final LinkPreviewRpc _rpc;

  /// Потолок сервера на один запрос (`getLinkPreviews`, `maxUrls`). Лишнее
  /// сверх него сервер молча отбросил бы, и часть карточек не появилась бы
  /// никогда — поэтому режем сами.
  static const int maxUrlsPerRequest = 10;

  /// Столько подряд неудачных запросов — и до перезапуска приложения больше
  /// не спрашиваем. Сервер лежит или сети нет: без этого каждая прокрутка
  /// ленты добавляла бы запросов в очередь, которая и так не разгребается.
  /// Счётчик сбрасывается любым успехом, так что одиночный сбой не выключает
  /// превью до конца сессии.
  static const int maxConsecutiveFailures = 3;

  /// Известный результат: значение — превью либо `null` («показывать
  /// нечего»). Отрицательный ответ кэшируется НАРАВНЕ с положительным:
  /// без этого ссылка без разметки давала бы запрос на каждую перерисовку.
  final Map<String, LinkPreviewView?> _known = <String, LinkPreviewView?>{};

  /// Кто ждёт ответа по этому URL. Второй спрашивающий не порождает второй
  /// запрос — подписывается к первому.
  final Map<String, List<Completer<LinkPreviewView?>>> _waiting = {};

  /// Накопленные к отправке. Копятся в пределах одного прохода событийного
  /// цикла — то есть ровно то, что успел отрисовать текущий кадр.
  final Set<String> _pending = <String>{};

  bool _flushScheduled = false;
  int _failures = 0;

  /// Сдались до перезапуска (см. [maxConsecutiveFailures]).
  bool get isGivenUp => _failures >= maxConsecutiveFailures;

  /// Синхронный ответ, если он уже известен. `null` — либо не знаем, либо
  /// знаем, что превью нет; для различения есть [isResolved].
  LinkPreviewView? peek(String url) => _known[url];

  /// Спрашивали ли уже про этот URL и получили ответ.
  bool isResolved(String url) => _known.containsKey(url);

  /// Узнать превью [url]. Идемпотентно и дёшево: из кэша — сразу, иначе
  /// URL уезжает в общий пакет с теми, что просят в этом же кадре.
  Future<LinkPreviewView?> resolve(String url) {
    if (_known.containsKey(url)) return Future.value(_known[url]);
    if (isGivenUp) return Future.value(null);
    final completer = Completer<LinkPreviewView?>();
    _waiting.putIfAbsent(url, () => []).add(completer);
    _pending.add(url);
    _scheduleFlush();
    return completer.future;
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    // Микрозадача, а не таймер: она выполняется сразу после текущего
    // синхронного участка, то есть после того, как кадр построил все
    // видимые пузыри. Пять ссылок на экране — один запрос, и тестам не
    // нужно ждать «когда-нибудь через N миллисекунд».
    scheduleMicrotask(_flush);
  }

  Future<void> _flush() async {
    _flushScheduled = false;
    while (_pending.isNotEmpty) {
      // Забираем пакет СИНХРОННО (до первого await): иначе параллельный
      // flush отправил бы те же URL-ы вторым запросом.
      final batch = _pending.take(maxUrlsPerRequest).toList();
      _pending.removeAll(batch);
      await _send(batch);
    }
  }

  Future<void> _send(List<String> batch) async {
    try {
      final views = await _rpc.getLinkPreviews(batch);
      _failures = 0;
      // Сопоставляем по `url` — сервер возвращает ту строку, которой
      // спросили (порядок и полнота ответа не гарантированы).
      final byUrl = {for (final v in views) v.url: v};
      for (final url in batch) {
        final view = byUrl[url];
        _known[url] = view;
        _complete(url, view);
      }
    } catch (e) {
      _failures++;
      // Ошибку НЕ кэшируем: «не дозвонились» — это не «превью нет».
      // Ссылка останется текстом, а следующая попытка возможна (пока не
      // сработал [maxConsecutiveFailures]).
      for (final url in batch) {
        _complete(url, null);
      }
    }
  }

  void _complete(String url, LinkPreviewView? view) {
    final waiters = _waiting.remove(url);
    if (waiters == null) return;
    for (final c in waiters) {
      if (!c.isCompleted) c.complete(view);
    }
  }
}
