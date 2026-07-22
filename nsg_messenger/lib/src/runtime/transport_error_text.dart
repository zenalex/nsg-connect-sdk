/// Приведение текста транспортных ошибок к читаемому виду для наших логов.
///
/// **Зачем.** В логе mac-клиента при реконнектах мелькало
/// `https://api.chatista.me:0/v1/websocket#` — адрес, которого не существует:
/// схема `https` вместо `wss`, порт `0`, пустой фрагмент. Это **не** наш
/// битый URL: `serverpod_client` подключается по
/// `wss://api.chatista.me/v1/websocket`, а строку рисует `dart:io`, когда
/// HTTP-апгрейд вернул не 101 (`sdk/lib/_http/websocket_impl.dart`):
///
/// ```dart
/// uri = Uri(
///   scheme: uri.isScheme("wss") ? "https" : "http",
///   userInfo: uri.userInfo, host: uri.host, port: uri.port,
///   path: uri.path, query: uri.query, fragment: uri.fragment,
/// );
/// ...
/// return error("Connection to '$uri' was not upgraded to websocket", ...);
/// ```
///
/// `Uri.port` знает дефолтные порты только для `http`/`https`, для `wss`
/// возвращает `0`; `query`/`fragment` пустых строк печатаются как `#`.
/// Отсюда ровно `https://<host>:0<path>#`. Библиотеку не трогаем — правим
/// только СВОЙ вывод, чтобы в логе стоял настоящий адрес сокета и было
/// видно, что реконнект вызван отказом апгрейда (а не «портом 0»).
library;

/// Сигнатура артефакта `dart:io`: `http(s)://host:0/path#`.
///
/// Ловим намеренно узко — с обязательными `:0` и завершающим `#`, чтобы
/// не переписать нормальный URL, который где-то реально фигурирует.
final RegExp _dartIoWebSocketUriArtifact = RegExp(
  r"(https?)://([^\s'\x22/]+):0(/[^\s'\x22#]*)#",
);

/// Текст [error] для лога: с восстановленным ws/wss-адресом вместо
/// артефакта `dart:io` (см. doc библиотеки). Прочие ошибки — как есть.
String describeTransportError(Object? error) {
  final raw = error?.toString() ?? 'null';
  return raw.replaceAllMapped(_dartIoWebSocketUriArtifact, (m) {
    final scheme = m.group(1) == 'https' ? 'wss' : 'ws';
    return '$scheme://${m.group(2)}${m.group(3)}';
  });
}
