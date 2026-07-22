import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

import '../test_helpers.dart';

/// **Issue #39** — подпись «кто написал» над peer-пузырями и
/// **issue #38** — индикатор «печатает…» плашкой, как сообщение.
///
/// #39 покрывает главное: раньше подпись включалась ТОЛЬКО по
/// `roomType == group`, поэтому support-чат (пользователь + бот +
/// оператор) читался как монолог. Теперь признак — «собеседник может быть
/// не один»: >2 участников ИЛИ есть бот. Проверяем support / группу
/// (видно, бот отмечен бейджем), direct (НЕ видно) и что в серии
/// сообщений одного отправителя имя не дублируется.
///
/// #38 проверяет, что footer «печатает…» появляется плашкой (Container с
/// BoxDecoration поверх голого Text) и исчезает при пустом Set печатающих.
void main() {
  setUpAll(registerTimeagoLocales);

  const selfMxid = '@self:t';
  const botMxid = '@bot:t';
  const operatorMxid = '@op:t';

  RoomParticipant participant({
    required int id,
    required String mxid,
    required String name,
    ParticipantKind? kind,
  }) => RoomParticipant(
    messengerUserId: id,
    matrixUserId: mxid,
    displayName: name,
    role: RoomMemberRole.member,
    participantKind: kind,
  );

  /// Комната по умолчанию — support с ботом и оператором (кейс из #39).
  RoomDetails details({
    RoomType roomType = RoomType.support,
    List<RoomParticipant>? participants,
    int? totalParticipants,
  }) {
    final list =
        participants ??
        [
          participant(id: 42, mxid: selfMxid, name: 'Self'),
          participant(
            id: 2,
            mxid: botMxid,
            name: 'Помощник',
            kind: ParticipantKind.bot,
          ),
          participant(id: 3, mxid: operatorMxid, name: 'Мария'),
        ];
    return RoomDetails(
      id: 7,
      matrixRoomId: '!r:t',
      name: 'Поддержка',
      unreadCount: 0,
      archived: false,
      muted: false,
      roomType: roomType,
      participants: list,
      totalParticipants: totalParticipants ?? list.length,
      viewerRole: RoomMemberRole.member,
      canEscalateSupport: false,
    );
  }

  MessengerMessage msg({
    required String eventId,
    required String senderMxid,
    required int senderId,
    required String body,
    required int tsOffset,
  }) => MessengerMessage(
    matrixEventId: eventId,
    roomId: 7,
    matrixRoomId: '!r:t',
    senderMessengerUserId: senderId,
    senderMatrixUserId: senderMxid,
    msgType: 'm.text',
    body: body,
    serverTimestamp: DateTime.utc(2026, 1, 1).add(Duration(minutes: tsOffset)),
  );

  /// Лента (DESC — новые первыми): оператор, потом два подряд от бота.
  /// Два подряд нужны, чтобы проверить «имя один раз на серию».
  List<MessengerMessage> defaultFeed() => [
    msg(
      eventId: 'e3',
      senderMxid: operatorMxid,
      senderId: 3,
      body: 'Уже смотрю',
      tsOffset: 3,
    ),
    msg(
      eventId: 'e2',
      senderMxid: botMxid,
      senderId: 2,
      body: 'Оператор скоро ответит',
      tsOffset: 2,
    ),
    msg(
      eventId: 'e1',
      senderMxid: botMxid,
      senderId: 2,
      body: 'Здравствуйте!',
      tsOffset: 1,
    ),
  ];

  Future<StreamController<MessengerEvent>> pumpChat(
    WidgetTester tester, {
    required RoomDetails roomDetails,
    List<MessengerMessage>? feed,
  }) async {
    final rpc = _FakeRpc(feed ?? defaultFeed());
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 7,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: 42,
      selfMatrixUserId: selfMxid,
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(
      wrapL10n(
        ChatScreen(
          roomId: 7,
          controllerOverride: controller,
          roomDetailsOverride: roomDetails,
          setPresenceOverride:
              ({int? currentRoomId, required bool foreground}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    return eventCtrl;
  }

  // ───────────────────────── issue #39 ─────────────────────────

  group('issue #39 — подпись отправителя', () {
    testWidgets('support-чат: видны имена и бота, и оператора', (tester) async {
      await pumpChat(tester, roomDetails: details());

      expect(
        find.text('Помощник'),
        findsOneWidget,
        reason: 'имя бота должно быть подписано над его пузырём',
      );
      expect(
        find.text('Мария'),
        findsOneWidget,
        reason: 'имя оператора должно быть подписано над его пузырём',
      );
    });

    testWidgets('support-чат: бот помечен бейджем «Бот», человек — нет', (
      tester,
    ) async {
      await pumpChat(tester, roomDetails: details());

      expect(find.text('Bot'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });

    testWidgets('серия подряд от одного отправителя — имя один раз', (
      tester,
    ) async {
      await pumpChat(tester, roomDetails: details());

      // В ленте ДВА сообщения бота подряд, но подпись — только над верхним.
      expect(find.text('Оператор скоро ответит'), findsOneWidget);
      expect(find.text('Здравствуйте!'), findsOneWidget);
      expect(
        find.text('Помощник'),
        findsOneWidget,
        reason: 'имя не должно дублироваться на каждом пузыре серии',
      );
    });

    testWidgets('групповой чат (>2 участников) — подпись видна', (
      tester,
    ) async {
      await pumpChat(
        tester,
        roomDetails: details(roomType: RoomType.group),
      );

      expect(find.text('Помощник'), findsOneWidget);
      expect(find.text('Мария'), findsOneWidget);
    });

    testWidgets('direct-чат — подписи НЕТ (был бы шум на каждом пузыре)', (
      tester,
    ) async {
      await pumpChat(
        tester,
        roomDetails: details(
          roomType: RoomType.direct,
          participants: [
            participant(id: 42, mxid: selfMxid, name: 'Self'),
            participant(id: 3, mxid: operatorMxid, name: 'Мария'),
          ],
        ),
        feed: [
          msg(
            eventId: 'e1',
            senderMxid: operatorMxid,
            senderId: 3,
            body: 'Привет',
            tsOffset: 1,
          ),
        ],
      );

      expect(find.text('Привет'), findsOneWidget);
      expect(
        find.text('Мария'),
        findsNothing,
        reason: 'в direct собеседник один — его имя уже в заголовке экрана',
      );
    });

    testWidgets('«Избранное» (saved) — подписи НЕТ', (tester) async {
      await pumpChat(
        tester,
        roomDetails: details(
          roomType: RoomType.saved,
          participants: [participant(id: 42, mxid: selfMxid, name: 'Self')],
        ),
        feed: [
          msg(
            eventId: 'e1',
            senderMxid: operatorMxid,
            senderId: 3,
            body: 'Заметка',
            tsOffset: 1,
          ),
        ],
      );

      expect(find.text('Заметка'), findsOneWidget);
      expect(find.text('Мария'), findsNothing);
    });

    testWidgets(
      'комната на двоих с ботом — подпись всё равно видна (бот ≠ человек)',
      (tester) async {
        await pumpChat(
          tester,
          roomDetails: details(
            participants: [
              participant(id: 42, mxid: selfMxid, name: 'Self'),
              participant(
                id: 2,
                mxid: botMxid,
                name: 'Помощник',
                kind: ParticipantKind.bot,
              ),
            ],
          ),
          feed: [
            msg(
              eventId: 'e1',
              senderMxid: botMxid,
              senderId: 2,
              body: 'Здравствуйте!',
              tsOffset: 1,
            ),
          ],
        );

        expect(
          find.text('Помощник'),
          findsOneWidget,
          reason: 'участников всего двое, но один из них бот — подписываем',
        );
        expect(find.text('Bot'), findsOneWidget);
      },
    );

    testWidgets('свои сообщения не подписываются', (tester) async {
      await pumpChat(
        tester,
        roomDetails: details(),
        feed: [
          msg(
            eventId: 'e1',
            senderMxid: selfMxid,
            senderId: 42,
            body: 'Мой вопрос',
            tsOffset: 1,
          ),
        ],
      );

      expect(find.text('Мой вопрос'), findsOneWidget);
      expect(find.text('Self'), findsNothing);
    });
  });

  // ───────────────────────── issue #38 ─────────────────────────

  group('issue #38 — «печатает…» плашкой', () {
    /// Плашка = Container с BoxDecoration, внутри которого лежит текст
    /// индикатора. Голый Text (как было) этому предикату не удовлетворяет.
    Finder typingPlate() => find.ancestor(
      of: find.textContaining('typing'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    );

    testWidgets('печатает → плашка появилась; перестал → исчезла', (
      tester,
    ) async {
      final events = await pumpChat(tester, roomDetails: details());

      expect(
        typingPlate(),
        findsNothing,
        reason: 'пустой Set печатающих — индикатор скрыт',
      );

      events.add(
        MessengerEvent(
          eventType: MessengerEventType.typingChanged,
          serverTimestamp: DateTime.utc(2026, 1, 1),
          roomId: 7,
          typingMatrixUserIds: const [operatorMxid],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Мария'),
        findsWidgets,
        reason: 'имя печатающего резолвится через участников комнаты',
      );
      expect(
        typingPlate(),
        findsOneWidget,
        reason: 'индикатор должен быть на плашке (Container + BoxDecoration)',
      );

      events.add(
        MessengerEvent(
          eventType: MessengerEventType.typingChanged,
          serverTimestamp: DateTime.utc(2026, 1, 1, 0, 1),
          roomId: 7,
          typingMatrixUserIds: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        typingPlate(),
        findsNothing,
        reason: 'Set опустел — индикатор снова скрыт',
      );
    });

    testWidgets('плашка использует те же токены, что и пузырь сообщения', (
      tester,
    ) async {
      final events = await pumpChat(tester, roomDetails: details());
      events.add(
        MessengerEvent(
          eventType: MessengerEventType.typingChanged,
          serverTimestamp: DateTime.utc(2026, 1, 1),
          roomId: 7,
          typingMatrixUserIds: const [operatorMxid],
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(typingPlate());
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        isNotNull,
        reason: 'скругления — как у peer-пузыря',
      );
      expect(
        decoration.color,
        isNotNull,
        reason: 'фон плашки и есть источник контраста (см. #38)',
      );
    });
  });
}

/// Stub RPC: отдаёт фиксированную ленту, остальное — заглушки.
class _FakeRpc implements MessagesRpc {
  _FakeRpc(this.feed);

  final List<MessengerMessage> feed;

  // **TASK82**: лента треда в этом сьюте не используется — фейку
  // достаточно удовлетворить интерфейс.
  @override
  Future<MessengerMessageListPage> listThreadMessages({
    required int roomId,
    required String threadRootEventId,
    String? fromToken,
    int limit = 50,
  }) => throw UnimplementedError();

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) async => MessengerMessageListPage(messages: feed);

  @override
  Future<TaskLink> createTaskFromMessage({
    required int roomId,
    required String matrixEventId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    required String clientTxnId,
    AttachmentRef? attachment,
    String? replyToMatrixEventId,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
    // TASK82: тред задачи — фейку достаточно принять параметр.
    String? threadId,
  }) => throw UnimplementedError();

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) async => true;

  @override
  Future<AttachmentRef> uploadAttachment({
    required ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => throw UnimplementedError();

  @override
  Future<AttachmentBytes> downloadAttachment({required String mxcUrl}) =>
      throw UnimplementedError();

  @override
  Future<MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => throw UnimplementedError();

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) async => 'reaction-event';

  @override
  Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) async {}

  @override
  Future<List<MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    int limit = 50,
  }) async => const <MessengerMessage>[];

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) async => const <String>[];

  @override
  Future<List<MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) async => const <MessengerMessage>[];
}
