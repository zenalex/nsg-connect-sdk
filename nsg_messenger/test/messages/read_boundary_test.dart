/// **Чат открывается там, где человек остановился.**
///
/// Жалоба владельца 09.08.2026: «открываю чат — он открывается на первых
/// сохранённых сообщениях, а потом сообщения догружаются и он проматывается
/// вниз. Надо чтобы он открывался на последнем прочитанном сообщении сразу,
/// иначе визуальные артефакты бесят».
///
/// Прыжок неизбежен, пока позицию выбирает то, что успело приехать: лента
/// наполняется дважды — сперва кэшем, потом сетью, — и низ reverse-списка
/// каждый раз означает «самое свежее из того, что сейчас есть». Позицию
/// должно задавать то, что известно СРАЗУ: граница прочитанного, посчитанная
/// по счётчику с диска.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/cache/messenger_cache_store.dart';
import 'package:nsg_messenger/src/messages/chat_message.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// Лента в порядке экрана: index 0 — самое свежее.
List<ChatMessage> feed(List<String> eventIds) => [
  for (final id in eventIds)
    ChatMessage.fromServer(
      MessengerMessage(
        matrixEventId: id,
        roomId: 1,
        matrixRoomId: '!1:l',
        senderMatrixUserId: '@u:l',
        msgType: 'm.text',
        body: id,
        serverTimestamp: DateTime.utc(2026, 8, 9),
      ),
    ),
];

void main() {
  group('readBoundaryOf', () {
    final messages = feed(['e5', 'e4', 'e3', 'e2', 'e1']); // e5 — новейшее

    test('три непрочитанных → встаём на самое старое из них', () {
      // Непрочитанные лежат сверху DESC-порядка: e5, e4, e3. Открыться надо
      // на e3 — тогда прочитанное осталось выше, новое читается вниз.
      expect(readBoundaryOf(messages: messages, unreadCount: 3), 'e3');
    });

    test('одно непрочитанное → оно и есть граница', () {
      expect(readBoundaryOf(messages: messages, unreadCount: 1), 'e5');
    });

    test('непрочитанного нет → позицию не навязываем', () {
      // Низ ленты и так правильное место: там самое свежее.
      expect(readBoundaryOf(messages: messages, unreadCount: 0), isNull);
    });

    test('счётчик неизвестен → позицию не навязываем', () {
      // «Не знаем» и «нечего читать» обязаны вести к разному: иначе первый
      // заход в чат без кэша уводил бы ленту вверх ни на чём.
      expect(readBoundaryOf(messages: messages, unreadCount: null), isNull);
    });

    test('непрочитанных больше, чем загружено → самое старое из ленты', () {
      // Граница за пределами страницы. Уводим к её краю — остальное
      // догрузит пагинация; выйти за список нельзя, это падение.
      expect(readBoundaryOf(messages: messages, unreadCount: 999), 'e1');
    });

    test('пустая лента не роняет', () {
      expect(readBoundaryOf(messages: const [], unreadCount: 5), isNull);
    });

    test('отрицательный счётчик не роняет', () {
      // С сервера такое не приходит, но арифметика счётчиков на клиенте
      // (вычли лишнее на markRead) в минус уже заезжала.
      expect(readBoundaryOf(messages: messages, unreadCount: -2), isNull);
    });
  });

  group('повторная подводка ленты (issue #112)', () {
    test('позиция ставится заново, когда лента долилась сетью', () {
      // Главный случай жалобы: по кэшу встали правильно, потом приехала
      // серверная страница и уронила прокрутку вниз. Раз содержимое
      // сменилось — подводим к тому же сообщению ещё раз.
      expect(
        shouldAnchorAtBoundary(
          target: 'e3',
          applied: 'e3',
          appliedOnSettledFeed: false,
        ),
        isTrue,
      );
    });

    test('на долитой ленте больше не дёргаем', () {
      // Иначе каждое новое сообщение утаскивало бы человека обратно к
      // границе прямо посреди чтения.
      expect(
        shouldAnchorAtBoundary(
          target: 'e3',
          applied: 'e3',
          appliedOnSettledFeed: true,
        ),
        isFalse,
      );
    });

    test('другая граница — подводим, даже если лента уже долита', () {
      expect(
        shouldAnchorAtBoundary(
          target: 'e2',
          applied: 'e3',
          appliedOnSettledFeed: true,
        ),
        isTrue,
      );
    });

    test('границы нет — позицию не навязываем', () {
      expect(
        shouldAnchorAtBoundary(
          target: null,
          applied: null,
          appliedOnSettledFeed: false,
        ),
        isFalse,
      );
    });
  });

  group('счётчик непрочитанного с диска', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('unread_cache'));
    tearDown(() {
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<MessengerCacheStore> open() async {
      final store = await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 7,
      );
      return store!;
    }

    RoomSummary room(int id, {required int unread}) => RoomSummary(
      id: id,
      name: 'Room $id',
      unreadCount: unread,
      archived: false,
      muted: false,
      roomType: RoomType.group,
    );

    test('читается без сети', () async {
      // Ради этого всё и затевалось: число известно ДО первого кадра.
      final store = await open();
      await store.putRooms([room(1, unread: 4), room(2, unread: 0)]);

      expect(await store.unreadCount(1), 4);
      expect(await store.unreadCount(2), 0);
      await store.close();
    });

    test('незнакомая комната — null, а не ноль', () async {
      // Ноль означал бы «всё прочитано» и открыл бы чат внизу, хотя на
      // деле мы просто ничего про него не знаем.
      final store = await open();
      expect(await store.unreadCount(42), isNull);
      await store.close();
    });

    test('битая строка не роняет открытие чата', () async {
      final store = await open();
      await store.debugInsertRawRoom(5, '{не json');

      expect(await store.unreadCount(5), isNull);
      await store.close();
    });

    test('счётчик виден только своему пользователю', () async {
      // Кэш общий на файл, разделение — по колонке userId. Чужой счётчик
      // открыл бы чат в случайном месте.
      final mine = await open();
      await mine.putRooms([room(1, unread: 9)]);
      await mine.close();

      final other = await MessengerCacheStore.openForUser(
        directory: tmp.path,
        namespace: 'test',
        userId: 8,
      );
      expect(await other!.unreadCount(1), isNull);
      await other.close();
    });
  });
}
