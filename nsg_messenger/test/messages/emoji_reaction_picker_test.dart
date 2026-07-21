import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/emoji_reaction_picker.dart';

/// F2 ч.1: полный emoji-picker для реакций.
void main() {
  Widget host(void Function(String?) onResult) => MaterialApp(
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final picked = await showEmojiReactionPicker(context);
              onResult(picked);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('открывает пикер с категориями и возвращает выбранный emoji', (
    tester,
  ) async {
    String? result;
    var called = false;
    await tester.pumpWidget(
      host((r) {
        result = r;
        called = true;
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Заголовок + хотя бы одна категория видны.
    expect(find.text('Choose a reaction'), findsOneWidget);
    expect(find.text('Smileys & emotion'), findsOneWidget);
    // Первый emoji категории (виден в верхней части сетки).
    expect(find.text('😀'), findsOneWidget);

    // Тап по эмодзи → возврат его вызывающей стороне + закрытие шита.
    await tester.tap(find.text('😀'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(result, '😀');
    expect(find.text('Choose a reaction'), findsNothing);
  });

  testWidgets('закрытие без выбора → null', (tester) async {
    String? result = 'sentinel';
    var called = false;
    await tester.pumpWidget(
      host((r) {
        result = r;
        called = true;
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Тап по барьеру закрывает модальный лист.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(result, isNull);
  });
}
