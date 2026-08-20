/// **issue #90**: правило «за какой ссылкой идти за превью».
///
/// Проверяется отдельно от вёрстки, потому что каждая найденная здесь
/// ссылка превращается в поход СЕРВЕРА на чужой сайт: лишний URL — это не
/// косметика, а запрос наружу от имени всех участников чата.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/link_preview_urls.dart';

void main() {
  group('Given обычный текст со ссылкой', () {
    test('голый URL находится', () {
      expect(extractPreviewUrls('смотри https://example.com/a вот тут'), [
        'https://example.com/a',
      ]);
    });

    test('markdown-ссылка отдаёт URL, а не подпись', () {
      expect(extractPreviewUrls('вот [статья](https://example.com/a)'), [
        'https://example.com/a',
      ]);
    });

    test('хвостовая скобка markdown-формы в URL не попадает', () {
      // Иначе сервер пошёл бы по адресу «…/a)» и превью не было бы никогда.
      final urls = extractPreviewUrls('[t](https://example.com/a)');
      expect(urls.single.endsWith(')'), isFalse);
    });

    test('точка в конце предложения в ссылку не попадает', () {
      expect(extractPreviewUrls('открой https://example.com/a.'), [
        'https://example.com/a',
      ]);
    });

    test('без ссылок — пусто (и ни одного запроса наружу)', () {
      expect(extractPreviewUrls('просто текст про example.com'), isEmpty);
    });
  });

  group('Given несколько ссылок', () {
    test('по умолчанию берём ТОЛЬКО первую', () {
      // Пять карточек под одним сообщением — стена, за которой не видно
      // самого сообщения.
      expect(
        extractPreviewUrls('https://a.com/1 и https://b.com/2 и https://c.com'),
        ['https://a.com/1'],
      );
    });

    test('max расширяет выборку, сохраняя порядок', () {
      expect(extractPreviewUrls('https://a.com/1 https://b.com/2', max: 2), [
        'https://a.com/1',
        'https://b.com/2',
      ]);
    });

    test('дубль одной ссылки — одна карточка', () {
      expect(
        extractPreviewUrls('https://a.com/1 повтор https://a.com/1', max: 5),
        ['https://a.com/1'],
      );
    });
  });

  group('Given ссылка внутри кода', () {
    test('inline-код пропускается', () {
      // URL в backtick-ах — пример, а не ссылка: он и кликабельным не
      // рисуется, значит карточка обещала бы переход, которого нет.
      expect(extractPreviewUrls('запрос к `https://example.com/api`'), isEmpty);
    });

    test('ограждённый блок пропускается', () {
      expect(
        extractPreviewUrls('вот код:\n```\ncurl https://example.com/a\n```'),
        isEmpty,
      );
    });

    test('ссылка ВНЕ блока рядом с блоком — находится', () {
      expect(
        extractPreviewUrls(
          'дока https://example.com/doc\n```\ncurl https://internal/x\n```',
        ),
        ['https://example.com/doc'],
      );
    });

    test('inline-код не склеивает соседей в несуществующий адрес', () {
      expect(extractPreviewUrls('`a`https://example.com/x'), [
        'https://example.com/x',
      ]);
    });
  });

  group('Given не-ссылки', () {
    test('нехттп-схемы игнорируются', () {
      // `file:`/`data:` — не «поделились ссылкой», а просьба сходить
      // куда-то у себя. Такое до сервера доходить не должно вовсе.
      expect(
        extractPreviewUrls('file:///etc/passwd и data:text/html,<b>x'),
        isEmpty,
      );
    });

    test('пустое тело — пусто', () {
      expect(extractPreviewUrls(''), isEmpty);
    });

    test('max=0 — пусто (вызывающий выключил превью)', () {
      expect(extractPreviewUrls('https://a.com/1', max: 0), isEmpty);
    });
  });
}
