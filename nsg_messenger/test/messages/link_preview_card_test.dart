/// **issue #90**: карточка превью под сообщением.
///
/// Проверяем не «красиво ли», а обещания карточки: она появляется только
/// когда сервер что-то дал, ведёт на ТУ ЖЕ ссылку, что в тексте, и не
/// пытается ходить наружу сама.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

class _FakeRpc implements LinkPreviewRpc {
  _FakeRpc(this.known);

  final Map<String, LinkPreviewView> known;
  final List<List<String>> calls = [];

  @override
  Future<List<LinkPreviewView>> getLinkPreviews(List<String> urls) async {
    calls.add(List.of(urls));
    return [
      for (final u in urls)
        if (known[u] != null) known[u]!,
    ];
  }
}

void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg(String body) => ChatMessage(
    clientTxnId: 'txn-1',
    matrixEventId: 'event-1',
    senderMatrixUserId: '@someone:localhost',
    senderMessengerUserId: null,
    body: body,
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
  );

  group('Given сообщение со ссылкой', () {
    testWidgets('сервер дал превью → карточка под текстом', (tester) async {
      final rpc = _FakeRpc({
        'https://example.com/a': LinkPreviewView(
          url: 'https://example.com/a',
          title: 'Заголовок статьи',
          description: 'Короткое описание',
          siteName: 'Example',
        ),
      });
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: msg('смотри https://example.com/a'),
            isOwn: false,
            onRetry: (_) {},
            linkPreviews: LinkPreviewStore(rpc),
          ),
        ),
      );
      // Первый кадр — карточки ещё нет (ответ не пришёл), и это нормально:
      // текст сообщения показывается сразу, не дожидаясь украшения.
      expect(find.byKey(const Key('linkPreviewCard')), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('linkPreviewCard')), findsOneWidget);
      expect(find.text('Заголовок статьи'), findsOneWidget);
      expect(find.text('Короткое описание'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(rpc.calls, [
        ['https://example.com/a'],
      ]);
    });

    testWidgets('карточка ПОД текстом, а не над ним', (tester) async {
      // Человек написал текст, карточка к нему приложение: превью над
      // сообщением отодвигало бы вниз то, ради чего сообщение и открыли.
      final rpc = _FakeRpc({
        'https://example.com/a': LinkPreviewView(
          url: 'https://example.com/a',
          title: 'Заголовок статьи',
        ),
      });
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: msg('мой текст https://example.com/a'),
            isOwn: false,
            onRetry: (_) {},
            linkPreviews: LinkPreviewStore(rpc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textY = tester.getTopLeft(find.textContaining('мой текст')).dy;
      final cardY = tester
          .getTopLeft(find.byKey(const Key('linkPreviewCard')))
          .dy;
      expect(cardY, greaterThan(textY));
    });

    testWidgets('сервер превью не дал → карточки нет, текст на месте', (
      tester,
    ) async {
      final rpc = _FakeRpc(const {});
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: msg('смотри https://example.com/a'),
            isOwn: false,
            onRetry: (_) {},
            linkPreviews: LinkPreviewStore(rpc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('linkPreviewCard')), findsNothing);
      expect(find.textContaining('https://example.com/a'), findsWidgets);
    });

    testWidgets('стор не передан → наружу не ходим вовсе', (tester) async {
      // Хост без init-а и все прежние тесты: ссылка остаётся текстом, и
      // ни одного запроса.
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: msg('смотри https://example.com/a'),
            isOwn: false,
            onRetry: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('linkPreviewCard')), findsNothing);
    });

    testWidgets('ссылки нет → сервер не спрашивается', (tester) async {
      final rpc = _FakeRpc(const {});
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: msg('обычное сообщение без ссылок'),
            isOwn: false,
            onRetry: (_) {},
            linkPreviews: LinkPreviewStore(rpc),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(rpc.calls, isEmpty);
    });
  });

  group('Given карточка сама по себе', () {
    Widget card(LinkPreviewView view, {VoidCallback? onTap}) => wrapL10n(
      Center(
        child: SizedBox(
          width: 300,
          child: LinkPreviewCard(
            preview: view,
            textColor: Colors.black,
            accentColor: Colors.blue,
            onTap: onTap,
          ),
        ),
      ),
    );

    testWidgets('сайт не назвался → шапка по хосту, без www', (tester) async {
      await tester.pumpWidget(
        card(LinkPreviewView(url: 'https://www.example.com/a', title: 'Т')),
      );
      expect(find.text('example.com'), findsOneWidget);
    });

    testWidgets('тап ведёт на ссылку сообщения', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        card(
          LinkPreviewView(url: 'https://example.com/a', title: 'Т'),
          onTap: () => tapped++,
        ),
      );
      await tester.tap(find.byKey(const Key('linkPreviewCard')));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('нет описания и картинки → карточка всё равно рисуется', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(LinkPreviewView(url: 'https://example.com/a', title: 'Только он')),
      );
      expect(find.text('Только он'), findsOneWidget);
      expect(find.byKey(const Key('linkPreviewDescription')), findsNothing);
      expect(find.byKey(const Key('linkPreviewImage')), findsNothing);
    });
  });
}
