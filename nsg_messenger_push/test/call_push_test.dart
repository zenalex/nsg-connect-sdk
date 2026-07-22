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

    // **TASK51 чанк 4**: 1:1-побудка старого сервера не должна
    // притвориться конференцией.
    test('1:1: isConference=false, callKitId = callId', () {
      final data = CallPushData.tryParse(fullPayload())!;
      expect(data.isConference, isFalse);
      expect(data.confId, isNull);
      expect(data.callKitId, 'call-abc-123');
      expect(data.roomName, '');
    });
  });

  // **TASK51 чанк 4 (CallKit-коллапс)**: побудка на mesh-конференцию.
  group('CallPushData.tryParse — конференция (TASK51 чанк 4)', () {
    const confId = 'conf_0123456789abcdef0123456789abcdef';

    Map<String, dynamic> conferencePayload() => <String, dynamic>{
      'type': 'call',
      'callKind': 'conference',
      'confId': confId,
      'callKitId': '01234567-89ab-cdef-0123-456789abcdef',
      'callId': 'conf:$confId:42:pair-1',
      'roomId': '7',
      'matrixRoomId': '!room:matrix.example',
      'callerId': '13',
      'callerName': 'Иван Петров',
      'roomName': 'Команда',
    };

    test('парсит конференц-поля', () {
      final data = CallPushData.tryParse(conferencePayload())!;
      expect(data.isConference, isTrue);
      expect(data.confId, confId);
      expect(data.roomName, 'Команда');
      // callId ПАРЫ сохраняется — по нему коррелируется pairwise-invite.
      expect(data.callId, 'conf:$confId:42:pair-1');
    });

    // Главное свойство чанка: разные пары одной конференции дают ОДИН
    // CallKit-id → повторные побудки схлопываются в один «входящий».
    test('callKitId одинаков для разных пар одной конференции', () {
      final a = CallPushData.tryParse(conferencePayload())!;
      final b = CallPushData.tryParse(
        conferencePayload()..['callId'] = 'conf:$confId:42:pair-2',
      )!;
      expect(a.callKitId, b.callKitId);
      expect(a.callKitId, '01234567-89ab-cdef-0123-456789abcdef');
    });

    test('без callKitId в payload — считаем сами из confId', () {
      final data = CallPushData.tryParse(
        conferencePayload()..remove('callKitId'),
      )!;
      expect(data.callKitId, '01234567-89ab-cdef-0123-456789abcdef');
    });

    test('callKind без confId → трактуем как 1:1 (битый payload)', () {
      // Без confId в конференцию не войти — нечего сопоставлять с
      // состоянием контроллера.
      final data = CallPushData.tryParse(
        conferencePayload()..remove('confId'),
      )!;
      expect(data.isConference, isFalse);
      expect(data.callKitId, data.callId);
    });

    test('confId без callKind → 1:1 (маркер семейства обязателен)', () {
      final data = CallPushData.tryParse(
        conferencePayload()..remove('callKind'),
      )!;
      expect(data.isConference, isFalse);
    });
  });

  // Дублируется на сервере (`PushPayloadBuilder.conferenceCallKitId`) —
  // значения обязаны совпадать, иначе «входящий», показанный из пуша, и
  // тот, что гасит клиент по событию шины, окажутся разными сессиями.
  group('CallPushData.conferenceCallKitId', () {
    test('conf_<32hex> → UUID 8-4-4-4-12', () {
      expect(
        CallPushData.conferenceCallKitId(
          'conf_0123456789abcdef0123456789abcdef',
        ),
        '01234567-89ab-cdef-0123-456789abcdef',
      );
    });

    test('детерминирован', () {
      const confId = 'conf_ffffffffffffffffffffffffffffffff';
      expect(
        CallPushData.conferenceCallKitId(confId),
        CallPushData.conferenceCallKitId(confId),
      );
      expect(
        CallPushData.conferenceCallKitId(confId),
        'ffffffff-ffff-ffff-ffff-ffffffffffff',
      );
    });

    test('не-каноничный confId возвращается как есть', () {
      expect(CallPushData.conferenceCallKitId('conf_short'), 'conf_short');
      expect(CallPushData.conferenceCallKitId('whatever'), 'whatever');
    });
  });
}
