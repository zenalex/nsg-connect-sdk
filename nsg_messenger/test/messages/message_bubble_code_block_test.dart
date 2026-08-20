/// **issue #80**: блок кода в пузыре — горизонтальная прокрутка.
///
/// Длинная строка кода раньше ПЕРЕНОСИЛАСЬ по ширине пузыря. Пузырь от
/// этого не распирало, но в коде отступы значат смысл, и перенос ломал
/// выравнивание — читать становилось нечего.
///
/// Что защищаем:
///   * блок кода рисуется отдельным виджетом с горизонтальным скроллом и
///     БЕЗ переноса (`softWrap: false`) — иначе прокручивать нечего;
///   * у блока есть кнопка «копировать» (тап по тексту теперь занят
///     прокруткой, и совмещать их значило бы копировать при каждом
///     движении);
///   * текст вокруг блока остаётся текстом;
///   * сообщение БЕЗ ограждений идёт прежним путём — 99% сообщений не
///     должны платить за перестройку рендера.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg(String body) => ChatMessage(
    clientTxnId: 'txn',
    matrixEventId: 'e1',
    senderMatrixUserId: '@peer:test',
    senderMessengerUserId: 2,
    body: body,
    msgType: 'm.text',
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
  );

  Future<void> pump(WidgetTester tester, String body) async {
    await tester.pumpWidget(
      wrapL10n(
        // Вертикальный скролл — как в ленте чата: развёрнутый длинный код
        // выше тестового вьюпорта, и без него падал бы RenderFlex, а не
        // проверялось поведение.
        SingleChildScrollView(
          child: MessageBubble(
            message: msg(body),
            isOwn: false,
            onRetry: (_) {},
          ),
        ),
        // Русская локаль — как у пользователя, на которого заведена
        // заявка; иначе ссылка сворачивания ищется по английской строке.
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Горизонтальный скролл внутри пузыря — тот, что оборачивает код.
  Finder codeScroller() => find.byWidgetPredicate(
    (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
  );

  const longLine =
      'final veryLongVariableName = someFunction(argumentOne, argumentTwo, '
      'argumentThree, argumentFour, argumentFive, argumentSix);';

  testWidgets('длинная строка кода прокручивается, а не переносится', (
    tester,
  ) async {
    await pump(tester, '```dart\n$longLine\n```');

    expect(codeScroller(), findsOneWidget);
    final codeText = tester.widget<Text>(
      find.descendant(of: codeScroller(), matching: find.byType(Text)),
    );
    expect(
      codeText.softWrap,
      isFalse,
      reason: 'с переносом прокручивать было бы нечего',
    );
    expect(codeText.data, contains('veryLongVariableName'));
  });

  testWidgets('у блока есть кнопка копирования', (tester) async {
    await pump(tester, '```\nprint(1);\n```');
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('текст вокруг блока остаётся текстом', (tester) async {
    await pump(tester, 'Смотри код:\n```\nprint(1);\n```\nи всё');

    expect(find.textContaining('Смотри код:'), findsOneWidget);
    expect(find.textContaining('и всё'), findsOneWidget);
    // Ограждения пользователю не показываем.
    expect(find.textContaining('```'), findsNothing);
  });

  testWidgets('сообщение без кода прежним путём: скролла и кнопки нет', (
    tester,
  ) async {
    await pump(tester, 'обычное сообщение без всякого кода');
    expect(codeScroller(), findsNothing);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });

  testWidgets('длинный код сворачивается и разворачивается по ссылке', (
    tester,
  ) async {
    // Без ограничения длинный код растянул бы ленту на весь экран — ровно
    // то, ради чего сворачивание и вводили.
    final code = List.generate(40, (i) => 'line $i;').join('\n');
    await pump(tester, '```\n$code\n```');

    final collapsed = tester.widget<Text>(
      find.descendant(of: codeScroller(), matching: find.byType(Text)),
    );
    expect(collapsed.maxLines, isNotNull);

    await tester.tap(find.text('Показать полностью'));
    await tester.pumpAndSettle();

    final expanded = tester.widget<Text>(
      find.descendant(of: codeScroller(), matching: find.byType(Text)),
    );
    expect(
      expanded.maxLines,
      isNull,
      reason: 'развёрнутый код показан целиком',
    );
  });
}
