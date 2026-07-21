import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/forward_source.dart';

/// **Issue #41** — координаты первоисточника пересланного сообщения.
///
/// Два чистых куска логики, тестируемых без виджетов и без сети:
///   * [ForwardSource.tryParse] — разбор сырого Matrix-content-а, где
///     значения могут быть любыми (content приходит из Matrix);
///   * [resolveForwardSource] — какие координаты записать при пересылке,
///     включая правило «первоисточник, а не промежуточное звено».
ChatMessage _msg({
  String? matrixEventId = 'e1',
  String? forwardedFromName,
  ForwardSource? forwardedSource,
}) => ChatMessage(
  clientTxnId: 'txn',
  matrixEventId: matrixEventId,
  senderMatrixUserId: '@a:t',
  senderMessengerUserId: 1,
  body: 'hi',
  msgType: 'm.text',
  serverTimestamp: DateTime.utc(2026, 1, 1),
  status: ChatMessageStatus.sent,
  forwardedFromName: forwardedFromName,
  forwardedSource: forwardedSource,
);

void main() {
  group('ForwardSource.tryParse', () {
    test('полная пара → координаты', () {
      final s = ForwardSource.tryParse({
        'nsg.forwarded_room_id': 10,
        'nsg.forwarded_event_id': r'$src',
      });
      expect(s, const ForwardSource(roomId: 10, eventId: r'$src'));
    });

    test('roomId строкой-числом → принимаем (JSON-мост отдаёт по-разному)', () {
      final s = ForwardSource.tryParse({
        'nsg.forwarded_room_id': '10',
        'nsg.forwarded_event_id': r'$src',
      });
      expect(s?.roomId, 10);
    });

    test('content == null → null', () {
      expect(ForwardSource.tryParse(null), isNull);
    });

    test('старое пересланное сообщение (полей нет) → null', () {
      // Самый частый случай на старте: всё, что переслали до issue #41.
      final s = ForwardSource.tryParse({
        'msgtype': 'm.text',
        'nsg.forwarded_from': 'Алиса',
      });
      expect(s, isNull);
    });

    test('полупара (только комната / только событие) → null', () {
      expect(ForwardSource.tryParse({'nsg.forwarded_room_id': 10}), isNull);
      expect(
        ForwardSource.tryParse({'nsg.forwarded_event_id': r'$src'}),
        isNull,
      );
    });

    test('кривой roomId (не-число, пусто, 0, отрицательный, дробь) → null', () {
      for (final bad in <Object?>[
        'abc',
        '',
        '   ',
        0,
        -5,
        '-5',
        3.7,
        true,
        <String>['10'],
        null,
      ]) {
        expect(
          ForwardSource.tryParse({
            'nsg.forwarded_room_id': bad,
            'nsg.forwarded_event_id': r'$src',
          }),
          isNull,
          reason: 'roomId=$bad должен отбраковываться',
        );
      }
    });

    test('целочисленный double (10.0) → принимаем', () {
      // jsonDecode вполне может отдать 10.0 вместо 10 — это тот же id.
      final s = ForwardSource.tryParse({
        'nsg.forwarded_room_id': 10.0,
        'nsg.forwarded_event_id': r'$src',
      });
      expect(s?.roomId, 10);
    });

    test('кривой eventId (пустая строка, не-строка) → null', () {
      for (final bad in <Object?>['', 42, true, null]) {
        expect(
          ForwardSource.tryParse({
            'nsg.forwarded_room_id': 10,
            'nsg.forwarded_event_id': bad,
          }),
          isNull,
          reason: 'eventId=$bad должен отбраковываться',
        );
      }
    });
  });

  group('resolveForwardSource', () {
    test('обычное сообщение → текущая комната + его eventId', () {
      final s = resolveForwardSource(
        message: _msg(matrixEventId: r'$orig'),
        currentRoomId: 10,
      );
      expect(s, const ForwardSource(roomId: 10, eventId: r'$orig'));
    });

    test('re-forward сохраняет ПЕРВОИСТОЧНИК, а не промежуточное звено', () {
      // Боб переслал сообщение Алисы из комнаты 10 в комнату 20; мы
      // пересылаем его дальше из комнаты 20 — координаты должны остаться
      // Алисиными, иначе шапка («Переслано от Алисы») и переход разъедутся.
      final s = resolveForwardSource(
        message: _msg(
          matrixEventId: r'$relay',
          forwardedFromName: 'Алиса',
          forwardedSource: const ForwardSource(roomId: 10, eventId: r'$orig'),
        ),
        currentRoomId: 20,
      );
      expect(s, const ForwardSource(roomId: 10, eventId: r'$orig'));
    });

    test(
      're-forward СТАРОГО пересланного (имя есть, координат нет) → null',
      () {
        // Указать на промежуточное звено нельзя: имя в шапке — первого автора,
        // и переход в чужой чат-пересыльщик был бы враньём.
        final s = resolveForwardSource(
          message: _msg(matrixEventId: r'$relay', forwardedFromName: 'Алиса'),
          currentRoomId: 20,
        );
        expect(s, isNull);
      },
    );

    test('pending без matrixEventId → null (ссылаться не на что)', () {
      expect(
        resolveForwardSource(
          message: _msg(matrixEventId: null),
          currentRoomId: 10,
        ),
        isNull,
      );
    });
  });
}
