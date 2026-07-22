// Причёсывание текста транспортных ошибок для наших логов.
//
// Повод — шум в консоли mac-клиента при реконнектах:
// `https://api.chatista.me:0/v1/websocket#`. Это НЕ наш битый URL, а то,
// как `dart:io` печатает адрес в `WebSocketException`, когда HTTP-апгрейд
// вернул не 101: он пересобирает `wss://…` в `https://…` через
// `Uri(scheme:…, port: uri.port, query: uri.query, fragment: uri.fragment)`,
// а `Uri.port` для схемы `wss` отдаёт 0 (дефолтные порты известны только
// для http/https), пустой же fragment печатается как `#`.
//
// Ниже — воспроизведение той самой строки прямо из `Uri` (чтобы тест
// доказывал происхождение артефакта, а не сверялся с копипастой) и
// проверка, что наш логгер возвращает настоящий адрес сокета.

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/runtime/transport_error_text.dart';

/// Ровно то, что делает `dart:io` (`_WebSocketImpl.connect`) перед тем как
/// подставить URI в текст ошибки.
String _dartIoRendered(Uri socketUri) => Uri(
  scheme: socketUri.isScheme('wss') ? 'https' : 'http',
  userInfo: socketUri.userInfo,
  host: socketUri.host,
  port: socketUri.port,
  path: socketUri.path,
  query: socketUri.query,
  fragment: socketUri.fragment,
).toString();

void main() {
  test('артефакт dart:io воспроизводится из настоящего wss-адреса', () {
    final socket = Uri.parse('wss://api.chatista.me/v1/websocket');
    // Порт «0» берётся не из нашего кода — так устроен Uri.port для wss.
    expect(socket.port, 0);
    expect(_dartIoRendered(socket), 'https://api.chatista.me:0/v1/websocket#');
  });

  test('в логе восстанавливается настоящий адрес сокета', () {
    const raw =
        "WebSocketException: Connection to "
        "'https://api.chatista.me:0/v1/websocket#' was not upgraded to websocket";
    expect(
      describeTransportError(raw),
      "WebSocketException: Connection to "
      "'wss://api.chatista.me/v1/websocket' was not upgraded to websocket",
    );
  });

  test('ws (не защищённый) вариант тоже разворачивается', () {
    expect(
      describeTransportError("to 'http://localhost:0/v1/websocket#' oops"),
      "to 'ws://localhost/v1/websocket' oops",
    );
  });

  test('обычные URL и прочий текст не трогаем', () {
    const untouched =
        'ClientException: https://api.chatista.me/v1/websocket failed; '
        'see https://example.com/docs#anchor and http://host:8080/x';
    expect(describeTransportError(untouched), untouched);
  });

  test('не-строковые ошибки и null отдаются как есть', () {
    expect(
      describeTransportError(const FormatException('bad')),
      contains('bad'),
    );
    expect(describeTransportError(null), 'null');
  });
}
