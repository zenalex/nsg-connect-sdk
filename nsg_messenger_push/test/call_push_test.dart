import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger_push/src/call_push.dart';

void main() {
  group('CallPushData.tryParse', () {
    // Полный контракт из PushPayloadBuilder.buildCall (все значения строки).
    Map<String, dynamic> fullPayload() => <String, dynamic>{
      'type': 'call',
      'callId': 'call-abc-123',
      'roomId': '42',
      'matrixRoomId': '!room:matrix.example',
      'callerId': '7',
      'callerName': 'Иван Петров',
    };

    test('парсит валидный call-push', () {
      final data = CallPushData.tryParse(fullPayload());
      expect(data, isNotNull);
      expect(data!.callId, 'call-abc-123');
      expect(data.roomId, 42);
      expect(data.matrixRoomId, '!room:matrix.example');
      expect(data.callerId, 7);
      expect(data.callerName, 'Иван Петров');
    });

    test('возвращает null для не-call сообщения (type != call)', () {
      final msg = <String, dynamic>{
        'type': 'message',
        'roomId': '42',
        'callId': 'x',
      };
      expect(CallPushData.tryParse(msg), isNull);
    });

    test('возвращает null когда type отсутствует', () {
      final msg = <String, dynamic>{'roomId': '42', 'callId': 'x'};
      expect(CallPushData.tryParse(msg), isNull);
    });

    test('возвращает null для null-payload', () {
      expect(CallPushData.tryParse(null), isNull);
    });

    test('возвращает null без callId (нечего коррелировать с invite)', () {
      final msg = fullPayload()..remove('callId');
      expect(CallPushData.tryParse(msg), isNull);
    });

    test('возвращает null с пустым callId', () {
      final msg = fullPayload()..['callId'] = '   ';
      expect(CallPushData.tryParse(msg), isNull);
    });

    test('возвращает null с нечисловым roomId', () {
      final msg = fullPayload()..['roomId'] = 'not-a-number';
      expect(CallPushData.tryParse(msg), isNull);
    });

    test('возвращает null без roomId', () {
      final msg = fullPayload()..remove('roomId');
      expect(CallPushData.tryParse(msg), isNull);
    });

    test(
      'терпит отсутствие необязательных полей (matrixRoomId/callerId/name)',
      () {
        final msg = <String, dynamic>{
          'type': 'call',
          'callId': 'c1',
          'roomId': '5',
        };
        final data = CallPushData.tryParse(msg);
        expect(data, isNotNull);
        expect(data!.callId, 'c1');
        expect(data.roomId, 5);
        // Дефолты для необязательных полей.
        expect(data.matrixRoomId, '');
        expect(data.callerId, 0);
        expect(data.callerName, '');
      },
    );

    test('обрезает пробелы в строковых полях', () {
      final msg = fullPayload()
        ..['callId'] = '  c-trim  '
        ..['callerName'] = '  Имя  ';
      final data = CallPushData.tryParse(msg);
      expect(data!.callId, 'c-trim');
      expect(data.callerName, 'Имя');
    });

    test(
      'принимает int-значения roomId/callerId (на случай не-строкового FCM)',
      () {
        final msg = <String, dynamic>{
          'type': 'call',
          'callId': 'c2',
          'roomId': 99,
          'callerId': 3,
        };
        final data = CallPushData.tryParse(msg);
        expect(data!.roomId, 99);
        expect(data.callerId, 3);
      },
    );

    test('равенство/hashCode по значению', () {
      final a = CallPushData.tryParse(fullPayload());
      final b = CallPushData.tryParse(fullPayload());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
