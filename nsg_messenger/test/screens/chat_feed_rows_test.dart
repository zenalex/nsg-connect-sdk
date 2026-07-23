import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// **TASK86**: чистая модель строк ленты `buildFeedRows` — где именно
/// встают разделители дат в reverse-ленте (DESC: index 0 — свежее, низ).
///
/// Инвариант: разделитель дня стоит СРАЗУ ЗА самым старым сообщением дня
/// (в reverse-списке это «над группой»); внутри одного дня разделителей
/// нет; пустая лента — без разделителей.
ChatMessage _msg(DateTime tsLocal, {String id = 'e'}) => ChatMessage(
      clientTxnId: null,
      matrixEventId: id,
      senderMatrixUserId: '@peer:t',
      senderMessengerUserId: 2,
      body: 'hi',
      msgType: 'm.text',
      // Лента хранит UTC; локальный день считается через .toLocal().
      serverTimestamp: tsLocal.toUtc(),
      status: ChatMessageStatus.sent,
    );

void main() {
  test('пустая лента — ни строки', () {
    expect(buildFeedRows(const []), isEmpty);
  });

  test('один день — один разделитель (сверху), внутри дня разделителей нет', () {
    // DESC: два сообщения одного дня.
    final rows = buildFeedRows([
      _msg(DateTime(2026, 7, 23, 15), id: 'newer'),
      _msg(DateTime(2026, 7, 23, 9), id: 'older'),
    ]);
    expect(rows.length, 3, reason: '2 сообщения + 1 разделитель');
    expect(rows[0], isA<MessageFeedRow>());
    expect(rows[1], isA<MessageFeedRow>());
    expect(rows[2], isA<DateSeparatorFeedRow>());
    expect((rows[2] as DateSeparatorFeedRow).day, DateTime(2026, 7, 23));
  });

  test('два дня — разделитель между группами + разделитель на самом верху', () {
    // DESC: день2 (2 сообщения), затем день1 (1 сообщение).
    final rows = buildFeedRows([
      _msg(DateTime(2026, 7, 23, 15), id: 'd2-newer'),
      _msg(DateTime(2026, 7, 23, 9), id: 'd2-older'),
      _msg(DateTime(2026, 7, 22, 20), id: 'd1'),
    ]);
    expect(rows.length, 5);
    expect((rows[0] as MessageFeedRow).messageIndex, 0);
    expect((rows[1] as MessageFeedRow).messageIndex, 1);
    // Разделитель день2 стоит НАД группой день2 (между d2-older и d1).
    expect(rows[2], isA<DateSeparatorFeedRow>());
    expect((rows[2] as DateSeparatorFeedRow).day, DateTime(2026, 7, 23));
    expect((rows[3] as MessageFeedRow).messageIndex, 2);
    // Разделитель день1 — на самом верху.
    expect(rows[4], isA<DateSeparatorFeedRow>());
    expect((rows[4] as DateSeparatorFeedRow).day, DateTime(2026, 7, 22));
  });

  test('messageIndex сохраняет исходную нумерацию (разделители не сдвигают)', () {
    final rows = buildFeedRows([
      _msg(DateTime(2026, 7, 23, 12), id: 'a'),
      _msg(DateTime(2026, 7, 22, 12), id: 'b'),
      _msg(DateTime(2026, 7, 21, 12), id: 'c'),
    ]);
    final indices = rows
        .whereType<MessageFeedRow>()
        .map((r) => r.messageIndex)
        .toList();
    expect(indices, [0, 1, 2], reason: 'три дня → три сообщения, индексы 0..2');
    expect(rows.whereType<DateSeparatorFeedRow>().length, 3);
  });
}
