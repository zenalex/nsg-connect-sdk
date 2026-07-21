// Issue #33 (TASK67 часть B) — разбор data-payload тихого «read-sync»-
// пуша. Чистая логика: без плагинов, isolate-состояния и сети.
//
// Контракт с сервером — `PushPayloadBuilder.buildReadSync`
// (`nsg_connect_server`): data-only сообщение со строковыми значениями
// `type` / `roomId` / `matrixRoomId` / `recipientId`.

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger_push/nsg_messenger_push.dart';

void main() {
  Map<String, dynamic> payload({
    String type = readSyncPushType,
    String? roomId = '42',
    String matrixRoomId = '!room:srv',
    String? recipientId = '7',
  }) => <String, dynamic>{
    'type': type,
    if (roomId != null) 'roomId': roomId,
    'matrixRoomId': matrixRoomId,
    if (recipientId != null) 'recipientId': recipientId,
  };

  group('ReadSyncPushData.tryParse', () {
    test('валидный read-sync → разобран, roomId в int', () {
      final d = ReadSyncPushData.tryParse(payload());
      expect(d, isNotNull);
      expect(d!.roomId, 42);
      expect(d.matrixRoomId, '!room:srv');
      expect(d.recipientId, 7);
    });

    // Чужие типы пушей не должны уводить обработку в ветку снятия:
    // message-пуш обязан остаться видимым, call — поднять звонок.
    test('type=message → null (обычная нотификация)', () {
      expect(ReadSyncPushData.tryParse(payload(type: 'message')), isNull);
    });

    test('type=call → null (пусть обрабатывает call-ветка)', () {
      expect(ReadSyncPushData.tryParse(payload(type: 'call')), isNull);
    });

    test('нет type → null', () {
      expect(
        ReadSyncPushData.tryParse(const <String, dynamic>{'roomId': '42'}),
        isNull,
      );
    });

    test('null data → null', () {
      expect(ReadSyncPushData.tryParse(null), isNull);
    });

    // roomId — единственное обязательное поле: без него снимать нечего.
    test('read-sync без roomId → null', () {
      expect(ReadSyncPushData.tryParse(payload(roomId: null)), isNull);
    });

    test('нечисловой roomId → null', () {
      expect(ReadSyncPushData.tryParse(payload(roomId: 'abc')), isNull);
    });

    // Провайдеры/каналы могут отдать числа не строкой — не падаем.
    test('roomId числом → разобран', () {
      final d = ReadSyncPushData.tryParse(const <String, dynamic>{
        'type': readSyncPushType,
        'roomId': 42,
      });
      expect(d?.roomId, 42);
    });

    test('без matrixRoomId/recipientId → пустая строка и null', () {
      final d = ReadSyncPushData.tryParse(const <String, dynamic>{
        'type': readSyncPushType,
        'roomId': '42',
      });
      expect(d, isNotNull);
      expect(d!.matrixRoomId, '');
      expect(d.recipientId, isNull);
    });

    test('константа типа совпадает с серверной строкой', () {
      expect(readSyncPushType, 'read_sync');
    });
  });
}
