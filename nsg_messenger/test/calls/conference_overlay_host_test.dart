import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/calls/call_rpc.dart';
import 'package:nsg_messenger/src/calls/conference_call_controller.dart';
import 'package:nsg_messenger/src/calls/conference_call_state.dart';
import 'package:nsg_messenger/src/calls/conference_overlay_host.dart';
import 'package:nsg_messenger/src/calls/conference_rpc.dart';
import 'package:nsg_messenger/src/calls/webrtc_adapter.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';

/// **TASK51 (UI)**: widget-тесты [ConferenceOverlayHost] — по образцу
/// тестов 1:1-`CallOverlayHost` (fake-контроллер с ручным emit).
///
/// Проверяют:
///   * по [ConferenceCallState] рисуется правильный overlay;
///   * accept/decline/mute/speaker/leave зовут команды контроллера;
///   * Active рисует участников по фазам (спиннер / connected / failed);
///   * conferenceFull показывает причину с лимитом N; micDenied — как
///     1:1; остальные Ended-причины закрывают оверлей тихо.
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

  RoomDetails details() => RoomDetails(
    id: 7,
    matrixRoomId: '!r:t',
    name: 'Команда',
    unreadCount: 0,
    archived: false,
    muted: false,
    roomType: RoomType.group,
    participants: [
      _participant(10, '@self:t', displayName: 'Я Сам'),
      _participant(1, '@alice:t', displayName: 'Алиса'),
      _participant(2, '@bob:t', displayName: 'Боб'),
    ],
    totalParticipants: 3,
    viewerRole: RoomMemberRole.member,
    canEscalateSupport: false,
  );

  Future<_FakeConferenceController> pump(
    WidgetTester tester, {
    required ConferenceCallState initial,
    String? Function(int roomId)? roomNameResolver,
    RoomDetails? roomDetails,
    Duration endedToastDuration = const Duration(seconds: 3),
  }) async {
    final controller = _FakeConferenceController()..emit(initial);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        ConferenceOverlayHost(
          controller: controller,
          roomNameResolver: roomNameResolver,
          roomDetailsOverride: roomDetails,
          endedToastDuration: endedToastDuration,
          enableRingtone: false,
          child: const Scaffold(
            body: Center(child: Text('APP BODY', key: Key('appBody'))),
          ),
        ),
      ),
    );
    // Второй pump — post-frame префетч RoomDetails (override применяется
    // асинхронно относительно первого кадра).
    await tester.pump();
    await tester.pump();
    return controller;
  }

  testWidgets('idle → overlay НЕ рисуется, виден только app body', (
    tester,
  ) async {
    await pump(tester, initial: const ConferenceCallIdle());
    expect(find.byKey(const Key('appBody')), findsOneWidget);
    expect(
      find.byKey(const Key('conferenceIncomingAcceptButton')),
      findsNothing,
    );
    expect(find.byKey(const Key('conferenceTimer')), findsNothing);
  });

  testWidgets('incoming → «Групповой звонок в {комната}», кто зовёт, '
      'счётчик, accept/decline', (tester) async {
    await pump(
      tester,
      initial: const ConferenceIncomingRinging(
        roomId: 7,
        confId: 'conf_a',
        callerMessengerUserId: 1,
        memberCount: 2,
      ),
      roomNameResolver: (roomId) => roomId == 7 ? 'Команда' : null,
      roomDetails: details(),
    );
    expect(find.text('Групповой звонок в Команда'), findsOneWidget);
    // «Кто зовёт» + размер состава одной строкой.
    expect(find.text('Алиса приглашает вас · 2 участника'), findsOneWidget);
    expect(
      find.byKey(const Key('conferenceIncomingAcceptButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('conferenceIncomingDeclineButton')),
      findsOneWidget,
    );
    // App body всё ещё в дереве (overlay поверх).
    expect(find.byKey(const Key('appBody')), findsOneWidget);
  });

  testWidgets('incoming без имени комнаты/состава → генерик-заголовок', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const ConferenceIncomingRinging(roomId: 7, confId: 'conf_a'),
    );
    expect(find.text('Групповой звонок'), findsOneWidget);
    // Ни звонящего, ни счётчика — подпись как у 1:1-входящего.
    expect(find.text('Входящий звонок'), findsOneWidget);
  });

  testWidgets('incoming accept/decline → команды контроллера', (tester) async {
    final c = await pump(
      tester,
      initial: const ConferenceIncomingRinging(roomId: 7, confId: 'conf_a'),
    );
    await tester.tap(find.byKey(const Key('conferenceIncomingAcceptButton')));
    await tester.pump();
    expect(c.acceptCalls, 1);
    expect(c.declineCalls, 0);

    await tester.tap(find.byKey(const Key('conferenceIncomingDeclineButton')));
    await tester.pump();
    expect(c.declineCalls, 1);
  });

  testWidgets('joining → «Соединение…»', (tester) async {
    await pump(tester, initial: const ConferenceJoining(roomId: 7));
    expect(find.text('Соединение…'), findsOneWidget);
  });

  testWidgets('active → участники по фазам: connecting-спиннер, connected, '
      'failed «Нет связи»; своя плитка помечена «Вы»', (tester) async {
    final t0 = DateTime.utc(2026);
    await pump(
      tester,
      initial: ConferenceActive(
        roomId: 7,
        confId: 'conf_a',
        startedAt: DateTime.now(),
        muted: false,
        participants: [
          ConferenceParticipantView(
            messengerUserId: 10,
            partyId: 'p-self',
            joinedAt: t0,
            phase: ConferencePairPhase.connected,
            isSelf: true,
          ),
          ConferenceParticipantView(
            messengerUserId: 1,
            partyId: 'pa',
            joinedAt: t0,
            phase: ConferencePairPhase.connecting,
          ),
          ConferenceParticipantView(
            messengerUserId: 2,
            partyId: 'pb',
            joinedAt: t0,
            phase: ConferencePairPhase.failed,
          ),
        ],
      ),
      roomDetails: details(),
    );
    expect(find.byKey(const Key('conferenceParticipantTile_10')), findsOneWidget);
    expect(find.byKey(const Key('conferenceParticipantTile_1')), findsOneWidget);
    expect(find.byKey(const Key('conferenceParticipantTile_2')), findsOneWidget);
    // Имена из RoomDetails; своя плитка — с пометкой «Вы».
    expect(find.text('Я Сам (Вы)'), findsOneWidget);
    expect(find.text('Алиса'), findsOneWidget);
    expect(find.text('Боб'), findsOneWidget);
    // Фазы: connecting → спиннер в плитке Алисы; failed → «Нет связи».
    expect(
      find.descendant(
        of: find.byKey(const Key('conferenceParticipantTile_1')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('conferenceParticipantTile_2')),
        matching: find.text('Нет связи'),
      ),
      findsOneWidget,
    );
    // Таймер и кнопки управления на месте.
    expect(find.byKey(const Key('conferenceTimer')), findsOneWidget);
    expect(find.byKey(const Key('conferenceMuteButton')), findsOneWidget);
    expect(find.byKey(const Key('conferenceSpeakerButton')), findsOneWidget);
    expect(find.byKey(const Key('conferenceLeaveButton')), findsOneWidget);
  });

  testWidgets('active: mute/speaker/leave → команды контроллера; таймер '
      'тикает', (tester) async {
    final c = await pump(
      tester,
      initial: ConferenceActive(
        roomId: 7,
        confId: 'conf_a',
        startedAt: DateTime.now(),
        muted: false,
        participants: const [],
      ),
    );
    expect(find.text('00:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    await tester.tap(find.byKey(const Key('conferenceMuteButton')));
    await tester.pump();
    expect(c.toggleMuteCalls, 1);

    await tester.tap(find.byKey(const Key('conferenceSpeakerButton')));
    await tester.pump();
    expect(c.toggleSpeakerCalls, 1);

    await tester.tap(find.byKey(const Key('conferenceLeaveButton')));
    await tester.pump();
    expect(c.leaveCalls, 1);
  });

  testWidgets('ended(conferenceFull) → «Конференция заполнена (макс. N)», '
      'скрывается после endedToastDuration', (tester) async {
    await pump(
      tester,
      initial: const ConferenceCallEnded(
        reason: ConferenceEndReason.conferenceFull,
        roomId: 7,
        maxParticipants: 4,
      ),
      endedToastDuration: const Duration(seconds: 2),
    );
    expect(find.text('Конференция заполнена (макс. 4)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Конференция заполнена (макс. 4)'), findsNothing);
  });

  testWidgets('ended(micDenied) → как 1:1: «Разрешите доступ к микрофону»', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const ConferenceCallEnded(
        reason: ConferenceEndReason.micDenied,
        roomId: 7,
      ),
    );
    expect(find.text('Разрешите доступ к микрофону'), findsOneWidget);
  });

  testWidgets('ended(localLeave/conferenceDied/displaced/failed) → тихое '
      'закрытие, БЕЗ toast-а', (tester) async {
    for (final reason in [
      ConferenceEndReason.localLeave,
      ConferenceEndReason.conferenceDied,
      ConferenceEndReason.displaced,
      ConferenceEndReason.failed,
    ]) {
      final c = await pump(
        tester,
        initial: ConferenceCallEnded(reason: reason, roomId: 7),
      );
      expect(
        find.byKey(const Key('conferenceEndedText')),
        findsNothing,
        reason: 'причина $reason должна закрывать оверлей тихо',
      );
      expect(find.byKey(const Key('appBody')), findsOneWidget);
      c.emit(const ConferenceCallIdle());
      await tester.pump();
    }
  });

  // ═════════════════════════════════════════════════════════════════
  // TASK80 — демонстрация экрана в оверлее
  // ═════════════════════════════════════════════════════════════════

  ConferenceActive active({
    bool screenShareSupported = false,
    int? presenter,
    bool selfPresenting = false,
    bool pending = false,
    int? deniedBy,
  }) => ConferenceActive(
    roomId: 7,
    confId: 'conf_a',
    startedAt: DateTime.now(),
    muted: false,
    screenShareSupported: screenShareSupported,
    presenterMessengerUserId: presenter,
    selfPresenting: selfPresenting,
    screenSharePending: pending,
    screenShareDeniedBy: deniedBy,
    participants: [
      ConferenceParticipantView(
        messengerUserId: 10,
        partyId: 'p-self',
        joinedAt: DateTime.utc(2026),
        phase: ConferencePairPhase.connected,
        isSelf: true,
        isPresenting: selfPresenting,
      ),
      ConferenceParticipantView(
        messengerUserId: 1,
        partyId: 'pa',
        joinedAt: DateTime.utc(2026),
        phase: ConferencePairPhase.connected,
        isPresenting: presenter == 1,
      ),
    ],
  );

  testWidgets('платформа без захвата → кнопки «Показать экран» НЕТ '
      '(не «нажал и ничего»)', (tester) async {
    await pump(tester, initial: active(), roomDetails: details());
    expect(find.byKey(const Key('conferenceScreenShareButton')), findsNothing);
    // Остальные кнопки на месте.
    expect(find.byKey(const Key('conferenceMuteButton')), findsOneWidget);
  });

  testWidgets('платформа с захватом → кнопка есть; web-путь стартует показ '
      'без нашего пикера', (tester) async {
    final c = await pump(
      tester,
      initial: active(screenShareSupported: true),
      roomDetails: details(),
    );
    expect(
      find.byKey(const Key('conferenceScreenShareButton')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('conferenceScreenShareButton')));
    await tester.pump();
    expect(c.startScreenShareSourceIds, [null]);
    expect(find.byKey(const Key('conferenceSourcePicker')), findsNothing);
  });

  testWidgets('desktop-путь: свой список источников → выбор запускает показ',
      (tester) async {
    final c = await pump(
      tester,
      initial: active(screenShareSupported: true),
      roomDetails: details(),
    );
    c
      ..fakeNeedsSourcePicker = true
      ..fakeSources = const [
        ScreenShareSource(id: 'screen:0', name: 'Screen 1', isWindow: false),
        ScreenShareSource(id: 'window:7', name: 'Editor', isWindow: true),
      ]
      // Флаги читаются оверлеем на build — перестраиваем.
      ..emit(active(screenShareSupported: true));
    await tester.pump();
    await tester.tap(find.byKey(const Key('conferenceScreenShareButton')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('conferenceSourcePicker')), findsOneWidget);
    expect(c.startScreenShareSourceIds, isEmpty);
    await tester.tap(find.byKey(const Key('conferenceSource_window:7')));
    await tester.pump();
    expect(c.startScreenShareSourceIds, ['window:7']);
    expect(find.byKey(const Key('conferenceSourcePicker')), findsNothing);
  });

  testWidgets('свой показ: постоянный индикатор + кнопка становится '
      '«Остановить показ»', (tester) async {
    final c = await pump(
      tester,
      initial: active(
        screenShareSupported: true,
        presenter: 10,
        selfPresenting: true,
      ),
      roomDetails: details(),
    );
    expect(
      find.byKey(const Key('conferenceSelfPresentingBanner')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('conferenceScreenShareButton')));
    await tester.pump();
    expect(c.stopScreenShareCalls, 1);
    expect(c.startScreenShareSourceIds, isEmpty);
  });

  testWidgets('отказ второму докладчику показан словами «сейчас '
      'показывает X»', (tester) async {
    await pump(
      tester,
      initial: active(screenShareSupported: true, deniedBy: 1),
      roomDetails: details(),
    );
    expect(
      find.byKey(const Key('conferenceShareBusyBanner')),
      findsOneWidget,
    );
    expect(find.textContaining('Алиса'), findsWidgets);
  });

  testWidgets('чужой показ: экран докладчика + переключение на сетку '
      'участников и обратно', (tester) async {
    final c = await pump(tester, initial: active(), roomDetails: details());
    c.fakeRenderer = _FakeRenderer();
    c.emit(active(presenter: 1));
    await tester.pump();

    // По умолчанию — экран докладчика.
    expect(find.byKey(const Key('conferenceScreenSurface')), findsOneWidget);
    expect(find.byKey(const Key('fakeScreenView')), findsOneWidget);
    expect(find.byKey(const Key('conferencePresenterLabel')), findsOneWidget);
    expect(
      find.byKey(const Key('conferenceParticipantTile_1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('conferenceScreenToggleButton')));
    await tester.pump();
    expect(find.byKey(const Key('conferenceScreenSurface')), findsNothing);
    expect(
      find.byKey(const Key('conferenceParticipantTile_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('conferencePresentingLabel_1')),
      findsOneWidget,
      reason: 'на плитке видно, кто показывает',
    );

    await tester.tap(find.byKey(const Key('conferenceScreenToggleButton')));
    await tester.pump();
    expect(find.byKey(const Key('conferenceScreenSurface')), findsOneWidget);
  });

  testWidgets('показ кончился → кнопки переключения нет, вернулись к сетке',
      (tester) async {
    final c = await pump(
      tester,
      initial: active(presenter: 1),
      roomDetails: details(),
    );
    expect(
      find.byKey(const Key('conferenceScreenToggleButton')),
      findsOneWidget,
    );
    c.emit(active());
    await tester.pump();
    expect(
      find.byKey(const Key('conferenceScreenToggleButton')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('conferenceParticipantTile_1')),
      findsOneWidget,
    );
  });

  testWidgets('смена состояния перерисовывает overlay (incoming → active)', (
    tester,
  ) async {
    final c = await pump(
      tester,
      initial: const ConferenceIncomingRinging(roomId: 7, confId: 'conf_a'),
    );
    expect(
      find.byKey(const Key('conferenceIncomingAcceptButton')),
      findsOneWidget,
    );
    c.emit(
      ConferenceActive(
        roomId: 7,
        confId: 'conf_a',
        startedAt: DateTime.now(),
        muted: false,
        participants: const [],
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('conferenceIncomingAcceptButton')),
      findsNothing,
    );
    expect(find.byKey(const Key('conferenceTimer')), findsOneWidget);
  });
}

RoomParticipant _participant(int id, String mxid, {String? displayName}) =>
    RoomParticipant(
      messengerUserId: id,
      matrixUserId: mxid,
      role: RoomMemberRole.member,
      displayName: displayName,
    );

/// Подкласс [ConferenceCallController] для widget-тестов overlay: state
/// управляется вручную ([emit]), команды записываются (не трогают
/// flutter_webrtc/RPC) — паттерн `_FakeCallController` 1:1-тестов.
class _FakeConferenceController extends ConferenceCallController {
  _FakeConferenceController()
    : super(
        conferenceRpc: _NoopConferenceRpc(),
        callRpc: _NoopCallRpc(),
        webrtc: _NoopWebRtc(),
        events: const Stream<MessengerEvent>.empty(),
        selfMessengerUserId: () => 10,
      );

  ConferenceCallState _fakeState = const ConferenceCallIdle();
  int acceptCalls = 0;
  int declineCalls = 0;
  int leaveCalls = 0;
  int toggleMuteCalls = 0;
  int toggleSpeakerCalls = 0;

  // **TASK80**: команды демонстрации экрана.
  final List<String?> startScreenShareSourceIds = [];
  int stopScreenShareCalls = 0;
  bool fakeNeedsSourcePicker = false;
  List<ScreenShareSource> fakeSources = const [];
  RtcVideoRenderer? fakeRenderer;

  void emit(ConferenceCallState s) {
    _fakeState = s;
    notifyListeners();
  }

  @override
  ConferenceCallState get state => _fakeState;

  @override
  Future<void> accept() async {
    acceptCalls++;
  }

  @override
  void decline() {
    declineCalls++;
  }

  @override
  Future<void> leave() async {
    leaveCalls++;
  }

  @override
  bool toggleMute() {
    toggleMuteCalls++;
    return true;
  }

  @override
  bool toggleSpeaker() {
    toggleSpeakerCalls++;
    return true;
  }

  @override
  bool get screenShareNeedsSourcePicker => fakeNeedsSourcePicker;

  @override
  Future<List<ScreenShareSource>> listScreenShareSources() async =>
      fakeSources;

  @override
  RtcVideoRenderer? get screenShareRenderer => fakeRenderer;

  @override
  Future<bool> startScreenShare({String? sourceId}) async {
    startScreenShareSourceIds.add(sourceId);
    return true;
  }

  @override
  Future<void> stopScreenShare() async {
    stopScreenShareCalls++;
  }
}

/// Рендерер-заглушка: рисует маркерный виджет вместо нативного
/// `RTCVideoView` (плагина в widget-тестах нет).
class _FakeRenderer implements RtcVideoRenderer {
  RtcMediaStream? bound;

  @override
  Future<void> initialize() async {}

  @override
  set srcObject(RtcMediaStream? stream) => bound = stream;

  @override
  Widget buildView({BoxFit fit = BoxFit.contain}) =>
      const SizedBox(key: Key('fakeScreenView'));

  @override
  Future<void> dispose() async {}
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

  // **TASK80**: показ экрана в этих тестах не используется.
  @override
  Future<ConferenceState> startScreenShare({
    required int roomId,
    required String partyId,
  }) => throw UnimplementedError();

  @override
  Future<void> stopScreenShare({required int roomId}) async {}
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

  // **TASK80**: демонстрация экрана в этих тестах не участвует —
  // платформа «не умеет захват», кнопки нет.
  @override
  bool get supportsScreenShare => false;

  @override
  bool get screenShareNeedsSourcePicker => false;

  @override
  Future<List<ScreenShareSource>> listScreenShareSources() async => const [];

  @override
  Future<RtcMediaStream> getDisplayMedia({
    required ScreenShareCaps caps,
    String? sourceId,
  }) => throw UnimplementedError();

  @override
  Future<RtcVideoRenderer> createVideoRenderer() => throw UnimplementedError();
}
