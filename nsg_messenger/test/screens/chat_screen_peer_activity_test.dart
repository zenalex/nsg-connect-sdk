/// **issue #73**: «Last seen собеседника не обновляется в реальном времени,
/// если тот отвечает в чате».
///
/// Подпись держалась только на presence, а тот внутри сеанса молчит:
/// сервер шлёт `presenceUpdated` лишь на переход offline→online, а
/// `lastActiveAt` в БД пишет один раз, в начале сеанса
/// (`PresenceService.heartbeat`). Пока собеседник отвечает, не меняется ни
/// то, ни другое — и пользователь видит «был(а) в сети N минут назад» от
/// человека, который пишет ему прямо сейчас.
///
/// Пришедшее сообщение — свидетельство сильнее presence: оно уже здесь.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

const kSelf = 42;
const kPeer = 99;

void main() {
  setUpAll(registerTimeagoLocales);

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: const [
      NsgL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: NsgL10n.supportedLocales,
    home: child,
  );

  RoomParticipant participant(int id, String mxid, {String? displayName}) =>
      RoomParticipant(
        messengerUserId: id,
        matrixUserId: mxid,
        displayName: displayName,
        role: RoomMemberRole.member,
        participantKind: ParticipantKind.user,
      );

  final directRoom = RoomDetails(
    id: 7,
    matrixRoomId: '!r:t',
    name: 'Пётр',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.direct,
    participants: [
      participant(kSelf, '@self:t'),
      participant(kPeer, '@peer:t', displayName: 'Пётр'),
    ],
    totalParticipants: 2,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  MessengerMessage msg({
    required int senderId,
    required String mxid,
    required DateTime at,
    String body = 'ответ',
  }) => MessengerMessage(
    matrixEventId: 'e-${at.microsecondsSinceEpoch}-$senderId',
    roomId: 7,
    matrixRoomId: '!r:t',
    senderMatrixUserId: mxid,
    senderMessengerUserId: senderId,
    body: body,
    msgType: 'm.text',
    serverTimestamp: at,
  );

  Future<void> pumpChat(
    WidgetTester tester,
    List<MessengerMessage> messages,
  ) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(MessengerMessageListPage(messages: messages));
    final eventCtrl = StreamController<MessengerEvent>.broadcast();
    final controller = MessagesController(
      roomId: 7,
      rpc: rpc,
      events: eventCtrl.stream,
      selfMessengerUserId: kSelf,
      selfMatrixUserId: '@self:t',
    );
    addTearDown(() async {
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: 7,
          controllerOverride: controller,
          roomDetailsOverride: directRoom,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('ответ собеседника обновляет подпись', (tester) async {
    await pumpChat(tester, [
      msg(senderId: kPeer, mxid: '@peer:t', at: DateTime.now().toUtc()),
    ]);
    expect(
      find.text('был(а) в сети только что'),
      findsOneWidget,
      reason: 'сообщение доказывает активность вернее любого presence',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('СВОЁ сообщение подпись не трогает', (tester) async {
    // Иначе подпись про собеседника рассказывала бы о нас самих.
    await pumpChat(tester, [
      msg(senderId: kSelf, mxid: '@self:t', at: DateTime.now().toUtc()),
    ]);
    expect(find.text('был(а) в сети только что'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('старое сообщение не омолаживает подпись', (tester) async {
    // В подпись идёт САМОЕ СВЕЖЕЕ сообщение собеседника, а не любое.
    final old = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    await pumpChat(tester, [msg(senderId: kPeer, mxid: '@peer:t', at: old)]);
    expect(find.text('был(а) в сети только что'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeRpc implements MessagesRpc {
  Future<MessengerMessageListPage> Function(int, String?, int)?
  listMessagesHandler;

  @override
  Future<MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    int limit = 50,
  }) {
    final h = listMessagesHandler;
    if (h == null) throw StateError('listMessagesHandler not set');
    return h(roomId, fromToken, limit);
  }

  @override
  Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
    String? threadRootEventId,
  }) async => true;

  @override
  Future<List<MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) async => const <MessengerEvent>[];

  @override
  Future<List<MessengerEvent>> listReadReceipts({required int roomId}) async =>
      const <MessengerEvent>[];

  @override
  Future<bool> isTaskIntegrationAvailable({required int roomId}) async => false;

  @override
  Future<void> sendTyping({required int roomId, required bool typing}) async {}

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_FakeRpc: only load-path RPCs mocked (${invocation.memberName})',
  );

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
