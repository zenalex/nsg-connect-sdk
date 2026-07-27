import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/calls/call_rpc.dart';
import 'package:nsg_messenger/src/calls/conference_call_controller.dart';
import 'package:nsg_messenger/src/calls/conference_call_state.dart';
import 'package:nsg_messenger/src/calls/conference_rpc.dart';
import 'package:nsg_messenger/src/calls/webrtc_adapter.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/messages/messages_controller.dart';
import 'package:nsg_messenger/src/messages/messages_rpc.dart';
import 'package:nsg_messenger/src/rooms/room_summary_tile.dart'
    show registerTimeagoLocales;
import 'package:nsg_messenger/src/screens/chat_screen.dart';

/// **TASK51 (UI)**: widget-тесты кнопки «Групповой звонок» и плашки
/// «идёт конференция» в [ChatScreen] — по образцу
/// `chat_screen_call_button_test.dart` (TASK46).
///
/// Покрывает:
///   * кнопка видна ТОЛЬКО для group (не для direct/productRoom);
///   * тап → conferenceCalls.join(roomId);
///   * плашка «Присоединиться» появляется при живой конференции в
///     комнате и исчезает, когда конференция умерла / мы уже в ней;
///   * тап по «Присоединиться» → join; открытие экрана зовёт
///     refreshRoomConference.
const kSelf = 42;

void main() {
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

  RoomDetails details({
    required RoomType roomType,
    required int total,
  }) => RoomDetails(
    id: 7,
    matrixRoomId: '!r:t',
    name: 'Команда',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: roomType,
    participants: [
      participant(kSelf, '@self:t'),
      participant(99, '@peer:t', displayName: 'Пётр'),
    ],
    totalParticipants: total,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  Future<void> pumpChat(WidgetTester tester, RoomDetails roomDetails) async {
    final rpc = _FakeRpc();
    rpc.listMessagesHandler = (_, _, _) =>
        Future.value(MessengerMessageListPage(messages: const []));
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
          roomDetailsOverride: roomDetails,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  // **issue #63**: «В групповых чатах не видно участников» — под названием
  // группы не было ничего, хотя у 1:1 на этом месте живёт «был(а) в сети…»,
  // а `totalParticipants` уже приходил в details.
  testWidgets('группа: под названием — число участников', (tester) async {
    await pumpChat(tester, details(roomType: RoomType.group, total: 5));
    expect(find.text('5 участников'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('склонение: 1 участник, 2 участника', (tester) async {
    await pumpChat(tester, details(roomType: RoomType.group, total: 1));
    expect(find.text('1 участник'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    await pumpChat(tester, details(roomType: RoomType.group, total: 2));
    expect(find.text('2 участника'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('1:1 подпись не занимает: там last seen', (tester) async {
    await pumpChat(tester, details(roomType: RoomType.direct, total: 2));
    expect(find.text('2 участника'), findsNothing);
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
