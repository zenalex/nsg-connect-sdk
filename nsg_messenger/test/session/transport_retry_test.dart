/// **Восстановление после мёртвого соединения** — issue #135.
///
/// 13.08.2026 экран мониторинга перестал открываться и не открывался,
/// сколько ни пробуй: двадцать секунд ожидания и тупик до перезапуска
/// приложения. Сервер при этом отвечал за 2 мс, а соседний вызов тем же
/// клиентом проходил. В GlitchTip та же подпись копилась пять недель.
///
/// Причина в устройстве восстановления: оно было построено ТОЛЬКО для
/// авторизации. Решение верное по своей задаче — токен-то жив, — но за
/// транспортом при этом не следил никто.
///
/// Здесь проверяется разделение: что считаем протухшей связью, что —
/// отказом сервера, и что повтор ровно один.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/session/auth_retry.dart';

void main() {
  /// **То, что клиент Serverpod бросает НА САМОМ ДЕЛЕ.**
  ///
  /// Первая редакция правки на живом пути не срабатывала ни разу, а тесты
  /// были зелёными: они кормили предикат сырыми `SocketException` — тем,
  /// чего до приложения не доходит. Клиент ловит сырое сам и заворачивает
  /// в `ServerpodClientException(текст, -1)` (`serverpod_client_io.dart:75`,
  /// `serverpod_client_browser.dart:59-61`). Поэтому здесь — дословные
  /// формы обёрток, а не удобные типы.
  group('живой путь: обёртки клиента Serverpod', () {
    // Дословно: `throw ServerpodClientException(e.toString(), -1)`.
    final wrappedIo = ServerpodClientException(
      "SocketException: Connection refused (OS Error: Connection refused, "
      "errno = 111), address = api.chatista.me, port = 443",
      -1,
    );
    // Дословно: `'Unknown server response code. ($e)'`, statusCode -1.
    final wrappedWeb = ServerpodClientException(
      'Unknown server response code. (ClientException: Failed to fetch, '
      'uri=https://api.chatista.me/pulse/listMonitors)',
      -1,
    );

    test('обёрнутый обрыв — это транспорт, а не отказ сервера', () {
      // Ровно то, что человек видел в лицо строкой «statusCode = -1».
      expect(isTransportFailure(wrappedIo), isTrue);
      expect(isTransportFailure(wrappedWeb), isTrue);
    });

    test('обёрнутый обрыв ПОВТОРЯЕТСЯ: соединение уже закрыто', () {
      expect(shouldRetryTransport(wrappedIo), isTrue);
      expect(shouldRetryTransport(wrappedWeb), isTrue);
    });

    test('признак — statusCode, а не текст сообщения', () {
      // Текст сообщения приходит от ОС и от браузера, он разный на каждой
      // платформе и локали. `-1` клиент ставит ровно в двух местах, и оба
      // — обёртки транспорта; настоящий HTTP-статус там невозможен.
      expect(isTransportFailure(ServerpodClientException('что угодно', -1)),
          isTrue);
      expect(isTransportFailure(ServerpodClientException('', -1)), isTrue);
    });

    test('настоящий ответ сервера транспортом НЕ считается', () {
      // Опора: иначе `-1` разъехался бы в «любой ServerpodClientException»,
      // и мы повторяли бы 5xx — то есть били по больному серверу вдвое.
      expect(isTransportFailure(ServerpodClientException('500', 500)), isFalse);
      expect(isTransportFailure(ServerpodClientException('boom', 502)), isFalse);
      expect(isTransportFailure(ServerpodClientUnauthorized()), isFalse);
    });
  });

  /// **Заглушка шлюза — тоже «недоступен»** (жалоба 16.08.2026).
  ///
  /// Во время выкатки человек открыл мониторинг и получил на экран
  /// `ServerpodClientException: Unknown error, data: <html><head><title>502
  /// Bad Gateway</title>… statusCode = 502`. Формально это ответ сервера,
  /// поэтому под транспортный отказ он не подпадал — и разметка nginx уехала
  /// человеку в лицо. Та же беда, что в #135, только с другого входа.
  group('шлюз не дозвался: 502/503/504', () {
    /// Дословно то, что пришло на экран (тело урезано).
    final badGateway = ServerpodClientException(
      'Unknown error, data: <html>\r\n<head><title>502 Bad Gateway</title>'
      '</head>\r\n<body>\r\n<center><h1>502 Bad Gateway</h1></center>\r\n',
      502,
    );

    test('502 — недоступность, а не предметный отказ', () {
      expect(isServerUnavailable(badGateway), isTrue);
      expect(isUnreachable(badGateway), isTrue);
    });

    test('503 и 504 — то же самое', () {
      // Перезапуск, выкатка, перегрузка апстрима: за шлюзом никого нет.
      expect(isServerUnavailable(ServerpodClientException('x', 503)), isTrue);
      expect(isServerUnavailable(ServerpodClientException('x', 504)), isTrue);
    });

    test('500 — НЕ сюда: там подробность помогает поддержке', () {
      // 500 означает, что обработчик до сервера дошёл и сломался внутри.
      // Скрыв причину, мы отняли бы у поддержки единственную зацепку.
      expect(isServerUnavailable(ServerpodClientException('boom', 500)), isFalse);
      expect(isUnreachable(ServerpodClientException('boom', 500)), isFalse);
    });

    test('недоступность НЕ повторяем автоматически', () {
      // 502 при выкатке живёт десятки секунд — повтор через 300 мс попадёт
      // в ту же яму, только удвоит ожидание. Лечит кнопка у человека.
      expect(shouldRetryTransport(badGateway), isFalse);
    });

    test('транспорт по-прежнему считается недоступностью', () {
      // Опора: новая мысль не должна была сузить старую.
      expect(isUnreachable(TimeoutException('8 c')), isTrue);
      expect(isUnreachable(ServerpodClientException('оборвано', -1)), isTrue);
    });
  });

  group('что считаем протухшей связью', () {
    test('таймаут, сокет, рукопожатие, оборванный HTTP', () {
      // Все четыре означают «канал не довёз», а не «запрос невозможен».
      // Сырые типы оставлены ради путей мимо клиента Serverpod.
      expect(isTransportFailure(TimeoutException('20 c')), isTrue);
      expect(isTransportFailure(const SocketException('нет маршрута')), isTrue);
      expect(isTransportFailure(const HandshakeException('tls')), isTrue);
      expect(isTransportFailure(const HttpException('оборвано')), isTrue);
    });

    test('серверные отказы — НЕ транспорт', () {
      // Повторять их вслепую значит удваивать нагрузку ровно тогда, когда
      // серверу плохо. У них есть ответ, просто ответ неприятный.
      expect(isTransportFailure(ServerpodClientException('500', 500)), isFalse);
      expect(isTransportFailure(ServerpodClientUnauthorized()), isFalse);
      expect(isTransportFailure(StateError('ошибка в коде')), isFalse);
    });

    test('транспорт и auth-инвалидация НЕ пересекаются', () {
      // Иначе одно лечилось бы другим: обновлением токена — мёртвый сокет
      // либо повтором — отозванный токен. И то и другое молча не сработало
      // бы, оставив человека в том же тупике.
      final transport = <Object>[
        TimeoutException('t'),
        const SocketException('s'),
      ];
      for (final e in transport) {
        expect(isTransportFailure(e), isTrue, reason: '$e');
        expect(isAuthInvalidation(e), isFalse, reason: '$e');
      }
      final auth = ServerpodClientUnauthorized();
      expect(isAuthInvalidation(auth), isTrue);
      expect(isTransportFailure(auth), isFalse);
    });
  });

  /// **Тайм-аут не повторяем — это решение, а не упущение.**
  ///
  /// Замер на живой web-сборке 15.08.2026: `.timeout()` бросает ожидание,
  /// но НЕ отменяет запрос — сокет остаётся занят. Браузер даёт шесть
  /// соединений на хост, и один заход экрана мониторинга (четыре вызова) с
  /// повтором забивал пул целиком: следующее нажатие «Повторить» до сети
  /// не доходило вовсе, при живом сервере. Повтор здесь удваивал ожидание
  /// (16,5 с вместо 8,3) и съедал пул вдвое быстрее — то есть делал хуже.
  group('молчащая связь: ждём один раз', () {
    test('тайм-аут — «нет связи» человеку, но БЕЗ повтора', () {
      final timeout = TimeoutException('8 c');
      expect(
        isTransportFailure(timeout),
        isTrue,
        reason: 'человеку показываем «нет связи», а не текст исключения',
      );
      expect(
        shouldRetryTransport(timeout),
        isFalse,
        reason: 'запрос не отменён и держит сокет — повтор бьёт по пулу',
      );
    });

    test('тайм-аут: вызова ровно один, второго НЕТ', () async {
      var calls = 0;
      await expectLater(
        withTransportRetry(() async {
          calls++;
          throw TimeoutException('молчит');
        }, delay: Duration.zero),
        throwsA(isA<TimeoutException>()),
      );
      expect(calls, 1, reason: 'иначе ожидание удваивается, а пул забивается');
    });
  });

  group('повтор', () {
    test('транспортная ошибка → вторая попытка, и она отдаёт результат', () {
      // Форма отказа — та, что приходит на живом пути (обёртка клиента).
      var calls = 0;
      return expectLater(
        withTransportRetry(() async {
          calls++;
          if (calls == 1) {
            throw ServerpodClientException('ClientException: Failed to fetch', -1);
          }
          return 'ответ';
        }, delay: Duration.zero),
        completion('ответ'),
      ).then((_) => expect(calls, 2));
    });

    test('повтор РОВНО один: второй отказ уходит наверх', () async {
      // Вторая неудача — это уже не икота связи, а недоступность. Её лечит
      // честный отказ с кнопкой у человека, а не бесконечная крутилка.
      var calls = 0;
      await expectLater(
        withTransportRetry(() async {
          calls++;
          throw ServerpodClientException('всё ещё мертво', -1);
        }, delay: Duration.zero),
        throwsA(isA<ServerpodClientException>()),
      );
      expect(calls, 2, reason: 'ни одной попытки сверх второй');
    });

    test('успех с первого раза — второго вызова НЕТ', () async {
      // Опора: обёртка не должна удваивать нормальную работу.
      var calls = 0;
      final r = await withTransportRetry(() async {
        calls++;
        return 42;
      }, delay: Duration.zero);
      expect(r, 42);
      expect(calls, 1);
    });

    test('серверный отказ не повторяется', () async {
      var calls = 0;
      await expectLater(
        withTransportRetry(() async {
          calls++;
          throw ServerpodClientException('500', 500);
        }, delay: Duration.zero),
        throwsA(isA<ServerpodClientException>()),
      );
      expect(
        calls,
        1,
        reason: 'повтор 5xx удваивает нагрузку на больной сервер',
      );
    });
  });

  group('цена ожидания', () {
    test('таймаут клиента заметно короче двадцати секунд Serverpod', () {
      // Двадцать секунд до первого признака жизни — вечность для экрана.
      // Дешевле короткое ожидание плюс повтор, чем одно долгое молчание.
      expect(clientConnectionTimeout, lessThan(const Duration(seconds: 20)));
      // Но и не настолько коротко, чтобы объявлять мёртвыми живые
      // соединения слабой мобильной сети.
      expect(
        clientConnectionTimeout,
        greaterThanOrEqualTo(const Duration(seconds: 5)),
      );
      // Худший случай молчащей связи — ОДИН таймаут: повтора там нет
      // (см. `shouldRetryTransport`), и восемь секунд — это всё ожидание.
      // Проверка на двойной таймаут осталась бы верной арифметически, но
      // описывала бы поведение, которого больше нет.
      expect(clientConnectionTimeout, lessThan(const Duration(seconds: 20)));
    });

    test('пауза перед повтором есть, но не заметна человеку', () {
      // Ноль попал бы в ту же секунду сетевой икоты; секунды — это уже
      // ожидание поверх ожидания.
      expect(transportRetryDelay, greaterThan(Duration.zero));
      expect(transportRetryDelay, lessThan(const Duration(seconds: 1)));
    });
  });
}
