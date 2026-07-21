import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/forward_source.dart';

/// Пересылка (forward): `ChatMessage` достаёт `nsg.forwarded_from[_uid]` из
/// сырого Matrix-content-а (server-side passthrough), copy-методы сохраняют.
ByteData _content(Map<String, dynamic> m) =>
    ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(m))));

MessengerMessage _msg({
  required String eventId,
  Map<String, dynamic> content = const {},
}) => MessengerMessage(
  matrixEventId: eventId,
  roomId: 1,
  matrixRoomId: '!r:t',
  senderMatrixUserId: '@a:t',
  senderMessengerUserId: 5,
  msgType: 'm.text',
  body: 'hi',
  serverTimestamp: DateTime.utc(2026, 1, 1),
  content: _content(content),
);

void main() {
  group('ChatMessage — forward', () {
    test('fromServer парсит nsg.forwarded_from (+ uid)', () {
      final m = ChatMessage.fromServer(
        _msg(
          eventId: 'e1',
          content: {
            'msgtype': 'm.text',
            'nsg.forwarded_from': 'Алиса',
            'nsg.forwarded_from_uid': 42,
          },
        ),
      );
      expect(m.forwardedFromName, 'Алиса');
      expect(m.forwardedFromMessengerUserId, 42);
      expect(m.isForwarded, isTrue);
    });

    test('name без uid — uid null, всё ещё isForwarded', () {
      final m = ChatMessage.fromServer(
        _msg(eventId: 'e2', content: {'nsg.forwarded_from': 'Bob'}),
      );
      expect(m.forwardedFromName, 'Bob');
      expect(m.forwardedFromMessengerUserId, isNull);
      expect(m.isForwarded, isTrue);
    });

    test('без forwarded-полей → не forwarded', () {
      final m = ChatMessage.fromServer(
        _msg(eventId: 'e3', content: {'msgtype': 'm.text'}),
      );
      expect(m.forwardedFromName, isNull);
      expect(m.isForwarded, isFalse);
    });

    test('пустая строка nsg.forwarded_from → null (не forwarded)', () {
      final m = ChatMessage.fromServer(
        _msg(eventId: 'e4', content: {'nsg.forwarded_from': ''}),
      );
      expect(m.forwardedFromName, isNull);
      expect(m.isForwarded, isFalse);
    });

    test('uid неверного типа игнорируется (name остаётся)', () {
      final m = ChatMessage.fromServer(
        _msg(
          eventId: 'e5',
          content: {'nsg.forwarded_from': 'Eve', 'nsg.forwarded_from_uid': 'x'},
        ),
      );
      expect(m.forwardedFromName, 'Eve');
      expect(m.forwardedFromMessengerUserId, isNull);
    });

    test('fromServer парсит координаты первоисточника (issue #41)', () {
      final m = ChatMessage.fromServer(
        _msg(
          eventId: 'e6',
          content: {
            'nsg.forwarded_from': 'Алиса',
            'nsg.forwarded_room_id': 77,
            'nsg.forwarded_event_id': r'$orig',
          },
        ),
      );
      expect(
        m.forwardedSource,
        const ForwardSource(roomId: 77, eventId: r'$orig'),
      );
    });

    test('старое пересланное (без координат) → forwardedSource null', () {
      final m = ChatMessage.fromServer(
        _msg(eventId: 'e7', content: {'nsg.forwarded_from': 'Алиса'}),
      );
      expect(m.isForwarded, isTrue);
      expect(m.forwardedSource, isNull, reason: 'шапка будет некликабельной');
    });

    test('кривые координаты не ломают разбор остальных полей', () {
      final m = ChatMessage.fromServer(
        _msg(
          eventId: 'e8',
          content: {
            'nsg.forwarded_from': 'Алиса',
            'nsg.forwarded_room_id': 'не число',
            'nsg.forwarded_event_id': '',
          },
        ),
      );
      expect(m.forwardedFromName, 'Алиса');
      expect(m.forwardedSource, isNull);
    });

    test('copy-методы сохраняют forwarded-поля', () {
      final o = ChatMessage.optimistic(
        clientTxnId: 't1',
        senderMatrixUserId: '@a:t',
        senderMessengerUserId: 1,
        body: 'x',
        forwardedFromName: 'Карл',
        forwardedFromMessengerUserId: 7,
        forwardedSource: const ForwardSource(roomId: 3, eventId: r'$o'),
      );
      expect(o.forwardedFromName, 'Карл');
      expect(o.failed(StateError('x')).forwardedFromName, 'Карл');
      expect(o.failed(StateError('x')).retrying().forwardedFromName, 'Карл');
      expect(
        o.failed(StateError('x')).retrying().forwardedFromMessengerUserId,
        7,
      );
      // Issue #41: координаты переживают тот же путь pending→failed→retry —
      // иначе после ретрая шапка теряла бы кликабельность.
      expect(
        o.failed(StateError('x')).retrying().forwardedSource,
        const ForwardSource(roomId: 3, eventId: r'$o'),
      );
    });
  });
}
