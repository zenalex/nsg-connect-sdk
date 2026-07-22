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
void main() {
  setUpAll(registerTimeagoLocales);

  const kSelf = 42;

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
        role: RoomMemberRole.member,
        displayName: displayName,
      );

  RoomDetails details({required RoomType roomType}) => RoomDetails(
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
      participant(100, '@carol:t', displayName: 'Кэрол'),
    ],
    totalParticipants: 3,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  Future<_FakeConferenceController> pumpChat(
    WidgetTester tester, {
    required RoomDetails roomDetails,
    _FakeConferenceController? conference,
  }) async {
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
    final conf = conference ?? _FakeConferenceController();
    addTearDown(() async {
      conf.dispose();
      await controller.dispose();
      await eventCtrl.close();
    });
    await tester.pumpWidget(
      wrap(
        ChatScreen(
          roomId: 7,
          controllerOverride: controller,
          roomDetailsOverride: roomDetails,
          conferenceCallsOverride: conf,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return conf;
  }

  testWidgets('group → кнопка «Групповой звонок» видна', (tester) async {
    await pumpChat(tester, roomDetails: details(roomType: RoomType.group));
    expect(find.byKey(const Key('chatConferenceCallButton')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('direct → кнопки «Групповой звонок» НЕТ', (tester) async {
    await pumpChat(tester, roomDetails: details(roomType: RoomType.direct));
    expect(find.byKey(const Key('chatConferenceCallButton')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('productRoom → кнопки «Групповой звонок» НЕТ', (tester) async {
    await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.productRoom),
    );
    expect(find.byKey(const Key('chatConferenceCallButton')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('тап по кнопке → conferenceCalls.join(roomId=7)', (
    tester,
  ) async {
    final conf = await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.group),
    );
    await tester.tap(find.byKey(const Key('chatConferenceCallButton')));
    await tester.pump();
    expect(conf.joinCalls, [7]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('открытие экрана → refreshRoomConference(roomId=7) '
      '(конференция могла начаться до нашего подключения)', (tester) async {
    final conf = await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.group),
    );
    expect(conf.refreshCalls, [7]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('живая конференция в комнате → плашка с числом участников и '
      '«Присоединиться»; смерть конференции → плашка исчезает', (
    tester,
  ) async {
    final conf = await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.group),
    );
    expect(find.byKey(const Key('conferenceOngoingBanner')), findsNothing);

    conf.setLiveConference(
      7,
      const ConferenceRoomInfo(
        confId: 'conf_a',
        memberCount: 2,
        initiatorMessengerUserId: 99,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('conferenceOngoingBanner')), findsOneWidget);
    expect(find.text('Идёт групповой звонок'), findsOneWidget);
    expect(find.text('2 участника'), findsOneWidget);
    expect(find.byKey(const Key('conferenceJoinButton')), findsOneWidget);

    // Конференция умерла (пустой состав) → плашка исчезает.
    conf.setLiveConference(7, null);
    await tester.pump();
    expect(find.byKey(const Key('conferenceOngoingBanner')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('тап «Присоединиться» → conferenceCalls.join(roomId=7)', (
    tester,
  ) async {
    final conf = await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.group),
    );
    conf.setLiveConference(
      7,
      const ConferenceRoomInfo(confId: 'conf_a', memberCount: 3),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('conferenceJoinButton')));
    await tester.pump();
    expect(conf.joinCalls, [7]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('мы уже в этой конференции (Active) → плашки НЕТ', (
    tester,
  ) async {
    final conf = await pumpChat(
      tester,
      roomDetails: details(roomType: RoomType.group),
    );
    conf.setLiveConference(
      7,
      const ConferenceRoomInfo(confId: 'conf_a', memberCount: 3),
    );
    conf.emit(
      ConferenceActive(
        roomId: 7,
        confId: 'conf_a',
        startedAt: DateTime.now(),
        muted: false,
        participants: const [],
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('conferenceOngoingBanner')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Fake-контроллер конференций для widget-тестов ChatScreen: state и
/// карта живых конференций управляются вручную, команды записываются.
class _FakeConferenceController extends ConferenceCallController {
  _FakeConferenceController()
    : super(
        conferenceRpc: _NoopConferenceRpc(),
        callRpc: _NoopCallRpc(),
        webrtc: _NoopWebRtc(),
        events: const Stream<MessengerEvent>.empty(),
        selfMessengerUserId: () => 42,
      );

  ConferenceCallState _fakeState = const ConferenceCallIdle();
  final Map<int, ConferenceRoomInfo> _live = {};
  final List<int> joinCalls = [];
  final List<int> refreshCalls = [];

  void emit(ConferenceCallState s) {
    _fakeState = s;
    notifyListeners();
  }

  void setLiveConference(int roomId, ConferenceRoomInfo? info) {
    if (info == null) {
      _live.remove(roomId);
    } else {
      _live[roomId] = info;
    }
    notifyListeners();
  }

  @override
  ConferenceCallState get state => _fakeState;

  @override
  ConferenceRoomInfo? liveConferenceInRoom(int roomId) => _live[roomId];

  @override
  Future<void> join({required int roomId}) async {
    joinCalls.add(roomId);
  }

  @override
  Future<void> refreshRoomConference(int roomId) async {
    refreshCalls.add(roomId);
  }
}

class _NoopConferenceRpc implements ConferenceRpc {
  @override
  Future<ConferenceState> joinConference({
    required int roomId,
    required String partyId,
  }) async => ConferenceState(
    confId: 'conf_noop',
    roomId: roomId,
    members: const [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Future<void> leaveConference({required int roomId}) async {}

  @override
  Future<ConferenceState?> getConference({required int roomId}) async => null;
}

class _NoopCallRpc implements CallRpc {
  @override
  Future<void> sendCallEvent({
    required int roomId,
    required CallEventType eventType,
    required String callId,
    required String partyId,
    String? sdp,
    List<CallIceCandidate>? candidates,
    String? hangupReason,
    String? selectedPartyId,
    String? sdpType,
  }) async {}

  @override
  Future<TurnCredentials> getTurnCredentials() async => TurnCredentials(
    urls: const [],
    username: '',
    credential: '',
    ttlSeconds: 0,
  );
}

class _NoopWebRtc implements WebRtcAdapter {
  @override
  Future<RtcPeerConnection> createPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) => throw UnimplementedError();

  @override
  Future<RtcMediaStream> getUserMediaAudio() => throw UnimplementedError();

  @override
  Future<void> setSpeakerphone(bool enabled) async {}
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
