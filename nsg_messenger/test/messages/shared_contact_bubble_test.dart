/// **Поделиться контактом** (этап 1, `DESIGN_TEAMS_AND_CONTACT_SHARING`).
///
/// Что защищаем:
///   * карточка разбирается из custom-поля и рисуется в пузыре с кнопкой
///     «Добавить» — ради неё всё и затевалось;
///   * битая/чужая карточка не ломает ленту: сообщение показывается
///     обычным текстом (фолбэк-`body` для этого и шлётся);
///   * обычные сообщения карточку не отращивают.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/messages/shared_contact_data.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;

import '../test_helpers.dart';

void main() {
  setUpAll(registerTimeagoLocales);

  ChatMessage msg({
    SharedContactData? contact,
    String body = 'Контакт: Пётр',
  }) => ChatMessage(
    clientTxnId: 'txn',
    matrixEventId: 'e1',
    senderMatrixUserId: '@peer:test',
    senderMessengerUserId: 2,
    body: body,
    msgType: contact == null ? 'm.text' : SharedContactData.msgType,
    serverTimestamp: DateTime.utc(2026, 1, 1),
    status: ChatMessageStatus.sent,
    sharedContact: contact,
  );

  group('разбор карточки', () {
    test('целая карточка разбирается', () {
      final c = SharedContactData.tryParse({
        'nsg.contact_card': {
          'messengerUserId': 42,
          'displayName': 'Пётр',
          'avatarUrl': 'mxc://x/y',
        },
      });
      expect(c?.messengerUserId, 42);
      expect(c?.displayName, 'Пётр');
    });

    test('мусор вместо карточки — null, а не исключение', () {
      // Сообщение с битым полем обязано показаться текстом, а не уронить
      // ленту: тут проходит чужой и старый контент.
      expect(SharedContactData.tryParse(null), isNull);
      expect(
        SharedContactData.tryParse({'nsg.contact_card': 'строка'}),
        isNull,
      );
      expect(SharedContactData.tryParse({'nsg.contact_card': {}}), isNull);
      expect(
        SharedContactData.tryParse({
          'nsg.contact_card': {'messengerUserId': 'сорок два'},
        }),
        isNull,
      );
      expect(
        SharedContactData.tryParse({
          'nsg.contact_card': {'messengerUserId': 0},
        }),
        isNull,
        reason: 'нулевой id ведёт в никуда',
      );
    });

    test('пустое имя не выдаём за имя', () {
      final c = SharedContactData.tryParse({
        'nsg.contact_card': {'messengerUserId': 7, 'displayName': ''},
      });
      expect(c?.displayName, isNull);
    });
  });

  group('пузырь', () {
    Future<void> pump(WidgetTester tester, ChatMessage m) async {
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(message: m, isOwn: false, onRetry: (_) {}),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('карточка рисуется с именем и кнопкой «Добавить»', (
      tester,
    ) async {
      await pump(
        tester,
        msg(
          contact: const SharedContactData(
            messengerUserId: 42,
            displayName: 'Пётр Иванов',
          ),
        ),
      );
      expect(find.text('Пётр Иванов'), findsOneWidget);
      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('без имени показываем id, а не пустоту', (tester) async {
      await pump(
        tester,
        msg(contact: const SharedContactData(messengerUserId: 42)),
      );
      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('обычное сообщение карточки не отращивает', (tester) async {
      await pump(tester, msg(body: 'просто текст'));
      expect(find.text('Добавить'), findsNothing);
      expect(find.text('просто текст'), findsOneWidget);
    });

    testWidgets('карточка не распарсилась → виден фолбэк-текст', (
      tester,
    ) async {
      // Ровно то, ради чего сервер шлёт body «Контакт: Имя».
      await pump(tester, msg(body: 'Контакт: Пётр'));
      expect(find.textContaining('Контакт: Пётр'), findsOneWidget);
    });
  });

  group('список (поделиться меткой)', () {
    test('разбирается, битые карточки выпадают, остальные остаются', () {
      final list = SharedContactListData.tryParse({
        'nsg.contact_list': {
          'label': 'Проект',
          'contacts': [
            {'messengerUserId': 1, 'displayName': 'Аня'},
            {'messengerUserId': 'мусор'},
            {'messengerUserId': 2, 'displayName': 'Боря'},
          ],
        },
      });
      expect(list?.label, 'Проект');
      expect(list?.contacts.map((c) => c.messengerUserId), [1, 2]);
    });

    test('пустой или битый список — null, рисовать нечего', () {
      expect(SharedContactListData.tryParse(null), isNull);
      expect(
        SharedContactListData.tryParse({
          'nsg.contact_list': {'contacts': []},
        }),
        isNull,
      );
      expect(
        SharedContactListData.tryParse({'nsg.contact_list': 'строка'}),
        isNull,
      );
    });

    testWidgets('список рисуется с именами и «Добавить всех»', (tester) async {
      await tester.pumpWidget(
        wrapL10n(
          MessageBubble(
            message: ChatMessage(
              clientTxnId: 'txn',
              matrixEventId: 'e2',
              senderMatrixUserId: '@peer:test',
              senderMessengerUserId: 2,
              body: 'Контакты (Проект): 2',
              msgType: SharedContactListData.msgType,
              serverTimestamp: DateTime.utc(2026, 1, 1),
              status: ChatMessageStatus.sent,
              sharedContactList: const SharedContactListData(
                label: 'Проект',
                contacts: [
                  SharedContactData(messengerUserId: 1, displayName: 'Аня'),
                  SharedContactData(messengerUserId: 2, displayName: 'Боря'),
                ],
              ),
            ),
            isOwn: false,
            onRetry: (_) {},
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Аня'), findsOneWidget);
      expect(find.text('Боря'), findsOneWidget);
      expect(find.textContaining('Проект'), findsOneWidget);
      expect(find.text('Добавить всех'), findsOneWidget);
      // У каждого — своя кнопка: список часто нужен выборочно.
      expect(find.text('Добавить'), findsNWidgets(2));
    });
  });
}
