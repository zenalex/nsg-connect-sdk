import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/nsg_messenger.dart'
    show MessengerSessionState, NsgMessenger;
import 'package:nsg_messenger/src/calls/call_controller.dart';
import 'package:nsg_messenger/src/calls/call_overlay_host.dart';
import 'package:nsg_messenger/src/calls/call_rpc.dart';
import 'package:nsg_messenger/src/calls/call_state.dart';
import 'package:nsg_messenger/src/calls/webrtc_adapter.dart';
import 'package:nsg_messenger/src/messenger_runtime.dart';

import '../test_helpers.dart';

/// **issue #47**: [CallOverlayHost] против жизненного цикла
/// [MessengerRuntime] (teardown/reinit при смене аккаунта).
///
/// Регресс: в окне смены аккаунта `isInitialized == true`, но `_calls`
/// уже (dispose) или ещё (init) null — билд хоста дёргал бросающий
/// геттер `MessengerRuntime.calls` и падал StateError-ом (красный
/// экран). Проверяем:
///
///   * билд без `init()` вообще — не бросает, оверлея нет;
///   * билд в «окне» (initDemo: isInitialized true, calls null) — не
///     бросает (точный сценарий креша из issue);
///   * рантайм ПОЯВИЛСЯ (init нового аккаунта завершился → session-state
///     событие) — оверлей сам цепляется к контроллеру, входящий звонок
///     показывается (без этого мультиаккаунт молча терял бы звонки);
///   * рантайм УШЁЛ (dispose) — оверлей отцепляется без утечки listener-а
///     и не бросает.
///
/// Runtime — singleton, поэтому в [tearDown] обязательно возвращаем его
/// в исходное состояние.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    // Сброс singleton-а между тестами: и подставленный контроллер, и
    // возможный demo-init.
    MessengerRuntime.instance.debugSetCallController(null);
    try {
      await NsgMessenger.dispose();
    } catch (_) {}
  });

  /// Хост БЕЗ явного контроллера — как в production (Chatista вставляет
  /// его в `MaterialApp.builder` и контроллер резолвится из runtime).
  Widget host() => wrapL10n(
    const CallOverlayHost(
      enableRingtone: false,
      child: Center(child: Text('APP BODY', key: Key('appBody'))),
    ),
  );

  testWidgets('билд без init(): не бросает, рисуется только app body', (
    tester,
  ) async {
    expect(MessengerRuntime.instance.isInitialized, isFalse);
    await tester.pumpWidget(host());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('appBody')), findsOneWidget);
    expect(find.byKey(const Key('callIncomingAcceptButton')), findsNothing);
  });

  testWidgets(
    'РЕГРЕСС issue #47: окно teardown/reinit (isInitialized == true, '
    'calls == null) — билд НЕ бросает StateError',
    (tester) async {
      // initDemo даёт ровно состояние «окна»: рантайм считается
      // инициализированным (rooms/eventBus есть), а CallController — нет.
      // До фикса _resolveController гейтился по isInitialized и дёргал
      // бросающий геттер calls → красный экран.
      await NsgMessenger.initDemo(rooms: const []);
      expect(MessengerRuntime.instance.isInitialized, isTrue);
      expect(MessengerRuntime.instance.callsOrNull, isNull);

      await tester.pumpWidget(host());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('appBody')), findsOneWidget);
    },
  );

  testWidgets(
    'reinit: рантайм появился ПОСЛЕ монтирования хоста → по session-state '
    'событию оверлей цепляется и показывает входящий звонок',
    (tester) async {
      // 1. Хост смонтирован, рантайма нет (окно смены аккаунта).
      await tester.pumpWidget(host());
      await tester.pump();
      expect(tester.takeException(), isNull);

      // 2. «init нового аккаунта завершился»: контроллер появился, session
      //    manager эмитит active (в production — из MessengerSessionManager,
      //    УЖЕ после создания CallController — см. порядок в init()).
      final controller = _FakeCallController();
      addTearDown(controller.dispose);
      MessengerRuntime.instance.debugSetCallController(controller);
      MessengerRuntime.instance.debugEmitSessionState(
        MessengerSessionState.active,
      );
      // Два pump-а: первый доставляет stream-событие (microtask →
      // setState), второй строит помеченный dirty виджет.
      await tester.pump();
      await tester.pump();

      // Хост пере-резолвил контроллер и подписался — БЕЗ rebuild-а сверху.
      expect(controller.debugHasListeners, isTrue);

      // 3. Входящий звонок нового аккаунта реально показывается.
      controller.emit(
        const CallIncomingRinging(
          callId: 'c1',
          roomId: 1,
          callerMatrixUserId: '@bob:home',
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);
    },
  );

  testWidgets(
    'teardown: рантайм ушёл → оверлей отцепляется (listener снят, звонок '
    'скрыт) и билд не бросает',
    (tester) async {
      final controller = _FakeCallController();
      addTearDown(controller.dispose);
      MessengerRuntime.instance.debugSetCallController(controller);

      await tester.pumpWidget(host());
      await tester.pump();
      expect(controller.debugHasListeners, isTrue);

      controller.emit(
        const CallIncomingRinging(
          callId: 'c1',
          roomId: 1,
          callerMatrixUserId: '@bob:home',
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);

      // «dispose() рантайма»: контроллер исчез, эмитится uninitialised
      // (production эмитит его первым делом в MessengerRuntime.dispose()).
      MessengerRuntime.instance.debugSetCallController(null);
      MessengerRuntime.instance.debugEmitSessionState(
        MessengerSessionState.uninitialised,
      );
      // Два pump-а: доставка stream-события + rebuild (см. тест выше).
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Отцепились без утечки listener-а: старый контроллер больше не
      // держит хост, оверлей ушёл в idle (пустой).
      expect(controller.debugHasListeners, isFalse);
      expect(find.byKey(const Key('callIncomingAcceptButton')), findsNothing);
      expect(find.byKey(const Key('appBody')), findsOneWidget);
    },
  );
}

/// Минимальный fake [CallController] (тот же паттерн, что в
/// call_overlay_host_test.dart): state задаётся вручную, webrtc/rpc —
/// no-op, чтобы не поднимать flutter_webrtc в widget-тестах.
class _FakeCallController extends CallController {
  _FakeCallController()
    : super(
        rpc: _NoopRpc(),
        webrtc: _NoopWebRtc(),
        events: const Stream<MessengerEvent>.empty(),
      );

  CallState _fakeState = const CallIdle();

  @override
  CallState get state => _fakeState;

  void emit(CallState s) {
    _fakeState = s;
    notifyListeners();
  }

  /// [ChangeNotifier.hasListeners] protected — открываем для проверки
  /// «оверлей подписался/отписался».
  bool get debugHasListeners => hasListeners;
}

class _NoopRpc implements CallRpc {
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
