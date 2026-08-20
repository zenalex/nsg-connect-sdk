/// **Заявка #138** — меню, которое открывает аватар отправителя.
///
/// Было: один пункт «Упомянуть». Оператор сообщил, что с аватара чаще
/// хотят понять, КТО это, и написать лично. Все три действия в коде уже
/// существовали, каждое со своего места; проверяется, что теперь они
/// собраны в одной точке входа и что бот ведёт в карточку бота, а не в
/// профиль контакта (метки и заметки про программу бессмысленны).
library;

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
import 'package:nsg_messenger/src/messages/message_bubble.dart';
import 'package:nsg_messenger/src/widgets/nsg_avatar_image.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(registerTimeagoLocales);

  const selfMxid = '@self:t';
  const peerMxid = '@peer:t';
  const botMxid = '@bot:t';

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

  RoomDetails details() {
    final list = [
      participant(id: 42, mxid: selfMxid, name: 'Self'),
      participant(id: 3, mxid: peerMxid, name: 'Мария'),
      participant(id: 2, mxid: botMxid, name: 'Помощник', kind: ParticipantKind.bot),
    ];
    return RoomDetails(
      id: 7,
      matrixRoomId: '!r:t',
      name: 'Команда',
      unreadCount: 0,
      archived: false,
      muted: false,
      roomType: RoomType.group,
      participants: list,
      totalParticipants: list.length,
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

  /// Лента DESC: сверху бот, под ним человек — у обоих свой аватар
  /// (нижнее сообщение серии), значит доступны оба меню.
  List<MessengerMessage> feed() => [
    msg(
      eventId: 'e2',
      senderMxid: botMxid,
      senderId: 2,
      body: 'Готово',
      tsOffset: 2,
    ),
    msg(
      eventId: 'e1',
      senderMxid: peerMxid,
      senderId: 3,
      body: 'Привет',
      tsOffset: 1,
    ),
  ];

  Future<void> pumpChat(WidgetTester tester) async {
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 7,
      rpc: _FakeRpc(feed()),
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
          roomDetailsOverride: details(),
          setPresenceOverride:
              ({int? currentRoomId, required bool foreground}) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Аватар рядом с сообщением [body]. Аватаров на экране несколько,
  /// поэтому ищем строго внутри того пузыря, где лежит нужный текст.
  Finder avatarNextTo(String body) => find.descendant(
    of: find.ancestor(of: find.text(body), matching: find.byType(MessageBubble)),
    matching: find.byType(NsgAvatarImage),
  );

  testWidgets('тап по аватару человека → три действия в одном меню', (
    tester,
  ) async {
    await pumpChat(tester);

    await tester.tap(avatarNextTo('Привет'));
    await tester.pumpAndSettle();

    // Имя в шапке — иначе непонятно, о ком меню; сообщений в ленте много,
    // а аватары мелкие и похожие.
    expect(find.text('Мария'), findsWidgets);
    expect(
      find.text('Contact profile'),
      findsOneWidget,
      reason: 'главное, чего просил оператор: «посмотреть, кто это»',
    );
    expect(find.text('Direct message'), findsOneWidget);
    expect(
      find.text('Mention'),
      findsOneWidget,
      reason: 'прежний единственный пункт никуда не делся',
    );
  });

  testWidgets('у бота — карточка бота, а не профиль контакта', (tester) async {
    await pumpChat(tester);

    await tester.tap(avatarNextTo('Готово'));
    await tester.pumpAndSettle();

    expect(find.text('Contact profile'), findsNothing);
    expect(
      find.text('Bot card'),
      findsOneWidget,
      reason: 'у программы нет ни визитки, ни заметок — им место в карточке '
          'бота, тот же выбор, что в списке участников и заголовке чата',
    );
  });

  testWidgets('меню закрывается без действия — черновик цел', (tester) async {
    // Свойство исходного мини-шита (TASK69 2C), которое нельзя потерять:
    // случайный тап по аватару ничего не делает молча.
    await pumpChat(tester);

    await tester.tap(avatarNextTo('Привет'));
    await tester.pumpAndSettle();
    expect(find.text('Mention'), findsOneWidget);

    Navigator.of(tester.element(find.text('Mention'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Mention'), findsNothing);
    expect(find.text('Привет'), findsOneWidget);
  });
}

/// Stub RPC: отдаёт фиксированную ленту, остальное — заглушки.
class _FakeRpc implements MessagesRpc {
  _FakeRpc(this.feed);

  final List<MessengerMessage> feed;

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
    String? threadId,
  }) => throw UnimplementedError();

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
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
