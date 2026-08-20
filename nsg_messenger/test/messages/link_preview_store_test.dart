/// **issue #90**: кто и когда спрашивает сервер о превью.
///
/// Проверяется не «пришли ли данные» (это RPC), а СКОЛЬКО раз мы вышли
/// наружу. Лента перестраивается на каждый чих — новое сообщение, прокрутка,
/// смена темы, — и наивный запрос из `build` превратил бы одну ссылку в
/// поток запросов к серверу, а через него к чужому сайту.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/link_preview_store.dart';

class _FakeRpc implements LinkPreviewRpc {
  _FakeRpc({
    this.known = const {},
    this.failTimes = 0,
    this.failUrls = const {},
  });

  /// url → превью. Отсутствие url-а в карте = «сервер превью не дал».
  final Map<String, LinkPreviewView> known;

  /// Сколько первых вызовов уронить (имитация «сервер лежит»).
  int failTimes;

  /// Пакеты с этими URL-ами падают — так строится ЧЕРЕДОВАНИЕ сбоев и
  /// успехов, на котором и видно, сбрасывается ли счётчик.
  final Set<String> failUrls;

  /// Пакеты в порядке отправки — по ним и считаем походы наружу.
  final List<List<String>> calls = [];

  @override
  Future<List<LinkPreviewView>> getLinkPreviews(List<String> urls) async {
    calls.add(List.of(urls));
    if (failTimes > 0) {
      failTimes--;
      throw StateError('сервер недоступен');
    }
    if (urls.any(failUrls.contains)) {
      throw StateError('сервер недоступен');
    }
    return [
      for (final u in urls)
        if (known[u] != null) known[u]!,
    ];
  }
}

LinkPreviewView _view(String url, {String? title}) =>
    LinkPreviewView(url: url, title: title ?? 'Заголовок');

void main() {
  group('Given несколько ссылок в одном кадре', () {
    test('уходит ОДИН запрос, а не по одному на ссылку', () async {
      final rpc = _FakeRpc(known: {'https://a.com': _view('https://a.com')});
      final store = LinkPreviewStore(rpc);

      // Так и рисуется лента: пузыри строятся один за другим синхронно.
      final futures = [
        store.resolve('https://a.com'),
        store.resolve('https://b.com'),
        store.resolve('https://c.com'),
      ];
      await Future.wait(futures);

      expect(rpc.calls.length, 1);
      expect(rpc.calls.single.length, 3);
    });

    test('пакет режется по потолку сервера (10 на запрос)', () async {
      // Лишнее сверх потолка сервер молча отбрасывает — часть карточек не
      // появилась бы никогда.
      final rpc = _FakeRpc();
      final store = LinkPreviewStore(rpc);
      await Future.wait([
        for (var i = 0; i < 23; i++) store.resolve('https://e.com/$i'),
      ]);
      expect(rpc.calls.map((c) => c.length).toList(), [10, 10, 3]);
    });
  });

  group('Given повторный вопрос про ту же ссылку', () {
    test('ответ берётся из кэша, второго запроса нет', () async {
      final rpc = _FakeRpc(known: {'https://a.com': _view('https://a.com')});
      final store = LinkPreviewStore(rpc);

      final first = await store.resolve('https://a.com');
      final second = await store.resolve('https://a.com');

      expect(first?.title, 'Заголовок');
      expect(second?.title, 'Заголовок');
      expect(rpc.calls.length, 1);
    });

    test('«превью нет» кэшируется НАРАВНЕ с ответом', () async {
      // Иначе ссылка без разметки давала бы запрос на каждую перерисовку —
      // а таких ссылок большинство.
      final rpc = _FakeRpc();
      final store = LinkPreviewStore(rpc);

      expect(await store.resolve('https://nothing.com'), isNull);
      expect(await store.resolve('https://nothing.com'), isNull);

      expect(rpc.calls.length, 1);
      expect(store.isResolved('https://nothing.com'), isTrue);
      expect(store.peek('https://nothing.com'), isNull);
    });

    test('двое ждут один URL — запрос всё равно один', () async {
      final rpc = _FakeRpc(known: {'https://a.com': _view('https://a.com')});
      final store = LinkPreviewStore(rpc);

      final both = await Future.wait([
        store.resolve('https://a.com'),
        store.resolve('https://a.com'),
      ]);

      expect(rpc.calls.length, 1);
      expect(rpc.calls.single, ['https://a.com']);
      expect(both.every((v) => v?.title == 'Заголовок'), isTrue);
    });
  });

  group('Given сервер отвечает не про всё', () {
    test('сопоставление идёт по url, а не по порядку ответа', () async {
      // Сервер возвращает список без гарантии порядка и С ПРОПУСКАМИ:
      // сопоставлять позиционно значит подписать карточку чужим сайтом.
      //
      // Спрашиваем В ОДНОМ пакете (без await между) — иначе в каждом
      // пакете по одному URL, и позиционное сопоставление сошлось бы
      // случайно, а тест был бы зелёным по неверной причине.
      final rpc = _FakeRpc(known: {'https://b.com': _view('https://b.com')});
      final store = LinkPreviewStore(rpc);

      final results = await Future.wait([
        store.resolve('https://a.com'), // сервер о нём ничего не вернёт
        store.resolve('https://b.com'),
      ]);

      expect(rpc.calls.single.length, 2, reason: 'должен быть один пакет');
      expect(results[0], isNull, reason: 'чужая карточка под ссылкой a');
      expect(results[1]?.url, 'https://b.com');
    });
  });

  group('Given сервер недоступен', () {
    test('сбой НЕ кэшируется — это не «превью нет»', () async {
      final rpc = _FakeRpc(
        known: {'https://a.com': _view('https://a.com')},
        failTimes: 1,
      );
      final store = LinkPreviewStore(rpc);

      expect(await store.resolve('https://a.com'), isNull);
      expect(store.isResolved('https://a.com'), isFalse);

      // Вторая попытка проходит — одиночный сбой не выключает превью.
      expect((await store.resolve('https://a.com'))?.title, 'Заголовок');
      expect(rpc.calls.length, 2);
    });

    test('после трёх подряд сбоев больше не спрашиваем', () async {
      // Сервер лежит: без этого каждая прокрутка ленты добавляла бы
      // запросов в очередь, которая и так не разгребается.
      final rpc = _FakeRpc(failTimes: 99);
      final store = LinkPreviewStore(rpc);

      for (var i = 0; i < 5; i++) {
        await store.resolve('https://e.com/$i');
      }

      expect(rpc.calls.length, LinkPreviewStore.maxConsecutiveFailures);
      expect(store.isGivenUp, isTrue);
    });

    test('успех сбрасывает счётчик сбоев', () async {
      // Смысл сброса: ТРИ ПОДРЯД, а не три за всё время. Иначе редкие
      // одиночные сбои за день накопились бы до отказа, и превью тихо
      // выключились бы на исправно работающем сервере.
      //
      // Порядок: сбой, сбой, успех, сбой — и после него пятый вопрос
      // ОБЯЗАН уйти. Без сброса счётчик дошёл бы до трёх и запер стор.
      final rpc = _FakeRpc(
        known: {'https://ok.com': _view('https://ok.com')},
        failUrls: {
          'https://bad.com/1',
          'https://bad.com/2',
          'https://bad.com/3',
        },
      );
      final store = LinkPreviewStore(rpc);

      await store.resolve('https://bad.com/1');
      await store.resolve('https://bad.com/2');
      await store.resolve('https://ok.com');
      await store.resolve('https://bad.com/3');
      await store.resolve('https://last.com');

      expect(store.isGivenUp, isFalse);
      expect(rpc.calls.length, 5, reason: 'пятый вопрос не должен быть заперт');
    });
  });
}
