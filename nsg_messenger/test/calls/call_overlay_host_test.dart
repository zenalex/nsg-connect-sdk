import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/calls/call_controller.dart';
import 'package:nsg_messenger/src/calls/call_overlay_host.dart';
import 'package:nsg_messenger/src/calls/call_ringback_player.dart';
import 'package:nsg_messenger/src/calls/call_rpc.dart';
import 'package:nsg_messenger/src/calls/call_state.dart';
import 'package:nsg_messenger/src/calls/webrtc_adapter.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';

/// **TASK46 (UI)**: widget-тесты [CallOverlayHost].
///
/// Проверяют:
///   * по [CallState] рисуется правильный overlay (idle → нет overlay,
///     outgoing/incoming/connecting/connected/ended → соответствующий);
///   * кнопки overlay вызывают команды контроллера (accept/decline/
///     hangup/toggleMute);
///   * входящий overlay рисуется, даже если под ним посторонний экран
///     (глобальность — overlay в корне навигации).
///
/// Контроллер — [_FakeCallController] (подкласс `CallController` с
/// override state/команд), чтобы не поднимать flutter_webrtc.
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

  Future<_FakeCallController> pump(
    WidgetTester tester, {
    required CallState initial,
    String? Function(CallPeerRef ref)? peerNameResolver,
  }) async {
    final controller = _FakeCallController()..emit(initial);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        CallOverlayHost(
          controller: controller,
          peerNameResolver: peerNameResolver,
          enableRingtone: false,
          child: const Scaffold(
            body: Center(child: Text('APP BODY', key: Key('appBody'))),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('idle → overlay НЕ рисуется, виден только app body', (
    tester,
  ) async {
    await pump(tester, initial: const CallIdle());
    expect(find.byKey(const Key('appBody')), findsOneWidget);
    expect(find.byKey(const Key('callOutgoingHangupButton')), findsNothing);
    expect(find.byKey(const Key('callIncomingAcceptButton')), findsNothing);
    expect(find.byKey(const Key('callTimer')), findsNothing);
  });

  testWidgets('outgoingRinging → «Звоним {peer}…» + кнопка отмены', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const CallOutgoingRinging(
        callId: 'c1',
        roomId: 1,
        peerMessengerUserId: 42,
      ),
      peerNameResolver: (_) => 'Алиса',
    );
    expect(find.text('Звоним Алиса…'), findsOneWidget);
    expect(find.byKey(const Key('callOutgoingHangupButton')), findsOneWidget);
    // App body всё ещё в дереве (overlay поверх).
    expect(find.byKey(const Key('appBody')), findsOneWidget);
  });

  testWidgets(
    'РЕГРЕСС: incoming рендерится, когда хост стоит в MaterialApp.builder '
    '(над навигатором, БЕЗ Overlay-предка) — не падает «No Overlay found»',
    (tester) async {
      // Воспроизводим реальную интеграцию Chatista: CallOverlayHost
      // оборачивает навигатор через `builder`, поэтому его оверлей —
      // ВЫШЕ Overlay приложения. Кнопки НЕ должны требовать Overlay
      // (был баг: `Tooltip` → «No Overlay widget found»). Прежний харнесс
      // (`home: CallOverlayHost`) держал хост ПОД Overlay и баг не ловил.
      final controller = _FakeCallController()
        ..emit(
          const CallIncomingRinging(
            callId: 'c1',
            roomId: 1,
            callerMatrixUserId: '@bob:home',
          ),
        );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: const [
            NsgL10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: NsgL10n.supportedLocales,
          builder: (context, child) => CallOverlayHost(
            controller: controller,
            enableRingtone: false,
            child: child!,
          ),
          home: const Scaffold(
            body: Center(child: Text('APP BODY', key: Key('appBody'))),
          ),
        ),
      );
      await tester.pump();
      // Ключевое: рендер оверлея НЕ бросил исключение.
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);
      expect(
        find.byKey(const Key('callIncomingDeclineButton')),
        findsOneWidget,
      );
    },
  );

  testWidgets('outgoing без resolver → fallback «Собеседник»', (tester) async {
    await pump(
      tester,
      initial: const CallOutgoingRinging(
        callId: 'c1',
        roomId: 1,
        peerMessengerUserId: 42,
      ),
    );
    expect(find.text('Звоним Собеседник…'), findsOneWidget);
  });

  testWidgets('outgoing hangup-кнопка → controller.hangup()', (tester) async {
    final c = await pump(
      tester,
      initial: const CallOutgoingRinging(
        callId: 'c1',
        roomId: 1,
        peerMessengerUserId: 42,
      ),
    );
    await tester.tap(find.byKey(const Key('callOutgoingHangupButton')));
    await tester.pump();
    expect(c.hangupCalls, 1);
  });

  testWidgets('incomingRinging → «{caller} звонит» + accept/decline', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const CallIncomingRinging(
        callId: 'c1',
        roomId: 1,
        callerMatrixUserId: '@bob:home',
      ),
    );
    // resolver нет → fallback на localpart Matrix id.
    expect(find.text('bob звонит'), findsOneWidget);
    expect(find.text('Входящий звонок'), findsOneWidget);
    expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);
    expect(find.byKey(const Key('callIncomingDeclineButton')), findsOneWidget);
  });

  testWidgets('incoming accept/decline кнопки → команды контроллера', (
    tester,
  ) async {
    final c = await pump(
      tester,
      initial: const CallIncomingRinging(
        callId: 'c1',
        roomId: 1,
        callerMatrixUserId: '@bob:home',
      ),
    );
    await tester.tap(find.byKey(const Key('callIncomingAcceptButton')));
    await tester.pump();
    expect(c.acceptCalls, 1);
    expect(c.declineCalls, 0);

    await tester.tap(find.byKey(const Key('callIncomingDeclineButton')));
    await tester.pump();
    expect(c.declineCalls, 1);
  });

  testWidgets('incoming overlay рисуется поверх постороннего экрана '
      '(глобальность)', (tester) async {
    // app body — не chat-screen, а произвольный экран; overlay всё равно
    // поверх.
    await pump(
      tester,
      initial: const CallIncomingRinging(
        callId: 'c1',
        roomId: 1,
        callerMatrixUserId: '@bob:home',
      ),
    );
    expect(find.byKey(const Key('appBody')), findsOneWidget);
    expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);
  });

  testWidgets('connecting → «Соединение…»', (tester) async {
    await pump(tester, initial: const CallConnecting(callId: 'c1', roomId: 1));
    expect(find.text('Соединение…'), findsOneWidget);
  });

  testWidgets('connected → таймер + mute + hangup; тикает', (tester) async {
    final c = await pump(
      tester,
      initial: CallConnected(
        callId: 'c1',
        roomId: 1,
        startedAt: DateTime.now(),
        muted: false,
      ),
    );
    expect(find.byKey(const Key('callTimer')), findsOneWidget);
    expect(find.byKey(const Key('callMuteButton')), findsOneWidget);
    expect(find.byKey(const Key('callInCallHangupButton')), findsOneWidget);
    // Таймер стартует с 00:00.
    expect(find.text('00:00'), findsOneWidget);
    // Спустя ~1с — 00:01.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    // mute-кнопка → toggleMute.
    await tester.tap(find.byKey(const Key('callMuteButton')));
    await tester.pump();
    expect(c.toggleMuteCalls, 1);

    // hangup-кнопка → hangup.
    await tester.tap(find.byKey(const Key('callInCallHangupButton')));
    await tester.pump();
    expect(c.hangupCalls, 1);
  });

  // Без этой кнопки звук уходит в разговорный динамик и телефон на столе
  // звучит «никак» — то самое «соединились, звука нет».
  testWidgets('connected → есть кнопка громкой связи; тап → toggleSpeaker', (
    tester,
  ) async {
    final c = await pump(
      tester,
      initial: CallConnected(
        callId: 'c1',
        roomId: 1,
        startedAt: DateTime.now(),
        muted: false,
      ),
    );
    expect(find.byKey(const Key('callSpeakerButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('callSpeakerButton')));
    await tester.pump();
    expect(c.toggleSpeakerCalls, 1);
  });

  testWidgets('connected: иконка/подпись громкой связи отражают speakerOn', (
    tester,
  ) async {
    final controller = _FakeCallController()
      ..emit(
        CallConnected(
          callId: 'c1',
          roomId: 1,
          startedAt: DateTime.now(),
          muted: false,
          speakerOn: true,
        ),
      );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        CallOverlayHost(
          controller: controller,
          enableRingtone: false,
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
    // Тест про то, что иконка отражает флаг, — задаём его явно, а не
    // полагаемся на дефолт конструктора (он менялся: hands-free → «к уху»).
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.bySemanticsLabel('Выключить громкую связь'), findsOneWidget);

    controller.emit(
      CallConnected(
        callId: 'c1',
        roomId: 1,
        startedAt: DateTime.now(),
        muted: false,
        speakerOn: false,
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.hearing), findsOneWidget);
    expect(find.bySemanticsLabel('Включить громкую связь'), findsOneWidget);
  });

  testWidgets('ended(micDenied) → toast «Разрешите доступ к микрофону», '
      'скрывается после endedToastDuration', (tester) async {
    final controller = _FakeCallController()
      ..emit(const CallEnded(reason: CallEndReason.micDenied));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        CallOverlayHost(
          controller: controller,
          endedToastDuration: const Duration(seconds: 2),
          enableRingtone: false,
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Разрешите доступ к микрофону'), findsOneWidget);
    // По истечении — overlay скрывается.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Разрешите доступ к микрофону'), findsNothing);
  });

  testWidgets('ended(declined) → «Отклонён»', (tester) async {
    await pump(
      tester,
      initial: const CallEnded(reason: CallEndReason.declined),
    );
    expect(find.text('Отклонён'), findsOneWidget);
  });

  testWidgets('ended(remoteHangup) → «Звонок завершён»', (tester) async {
    await pump(
      tester,
      initial: const CallEnded(reason: CallEndReason.remoteHangup),
    );
    expect(find.text('Звонок завершён'), findsOneWidget);
  });

  testWidgets('enableRingtone=true на incoming → не падает '
      '(best-effort tone/вибро)', (tester) async {
    final controller = _FakeCallController()
      ..emit(
        const CallIncomingRinging(
          callId: 'c1',
          roomId: 1,
          callerMatrixUserId: '@bob:home',
        ),
      );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        CallOverlayHost(
          controller: controller,
          // enableRingtone по умолчанию true — проверяем, что дёрганье
          // SystemSound/HapticFeedback (no-op в тестах) не роняет overlay.
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);
    // Тик рингтона через 2с — тоже не падает.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('callIncomingAcceptButton')), findsOneWidget);
    // Уход из incoming глушит рингтон-таймер (без pending-таймеров при
    // teardown).
    controller.emit(const CallIdle());
    await tester.pump();
  });

  group('исходящий ringback (обратный сигнал)', () {
    Future<_FakeCallController> pumpWithRingback(
      WidgetTester tester,
      _FakeRingbackPlayer player, {
      required CallState initial,
    }) async {
      final controller = _FakeCallController()..emit(initial);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrap(
          CallOverlayHost(
            controller: controller,
            // enableRingtone=true, но плеер — fake (без платформенных каналов).
            enableRingtone: true,
            ringbackPlayer: player,
            child: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();
      return controller;
    }

    testWidgets('стадия 1 (reachedPeer=false) → play(connecting)', (
      tester,
    ) async {
      final player = _FakeRingbackPlayer();
      await pumpWithRingback(
        tester,
        player,
        initial: const CallOutgoingRinging(
          callId: 'c1',
          roomId: 1,
          peerMessengerUserId: 42,
        ),
      );
      expect(player.log, ['play:connecting']);
    });

    testWidgets(
      'стадия 1 → стадия 2 → connected: connecting → ringing → stop',
      (tester) async {
        final player = _FakeRingbackPlayer();
        final c = await pumpWithRingback(
          tester,
          player,
          initial: const CallOutgoingRinging(
            callId: 'c1',
            roomId: 1,
            peerMessengerUserId: 42,
          ),
        );
        expect(player.log, ['play:connecting']);

        // invite доставлен → стадия 2.
        c.emit(
          const CallOutgoingRinging(
            callId: 'c1',
            roomId: 1,
            peerMessengerUserId: 42,
            reachedPeer: true,
          ),
        );
        await tester.pump();
        expect(player.log, ['play:connecting', 'play:ringing']);

        // собеседник ответил → connecting → ringback глушится.
        c.emit(const CallConnecting(callId: 'c1', roomId: 1));
        await tester.pump();
        expect(player.log, ['play:connecting', 'play:ringing', 'stop']);
      },
    );

    testWidgets('глушится на CallEnded (например таймаут без ответа)', (
      tester,
    ) async {
      final player = _FakeRingbackPlayer();
      final c = await pumpWithRingback(
        tester,
        player,
        initial: const CallOutgoingRinging(
          callId: 'c1',
          roomId: 1,
          peerMessengerUserId: 42,
          reachedPeer: true,
        ),
      );
      expect(player.log, ['play:ringing']);
      c.emit(const CallEnded(reason: CallEndReason.timeout));
      await tester.pump();
      expect(player.log, ['play:ringing', 'stop']);
    });

    testWidgets('дедуп: повторный тот же тон не пере-дёргает плеер', (
      tester,
    ) async {
      final player = _FakeRingbackPlayer();
      final c = await pumpWithRingback(
        tester,
        player,
        initial: const CallOutgoingRinging(
          callId: 'c1',
          roomId: 1,
          peerMessengerUserId: 42,
        ),
      );
      // Повторный emit того же состояния (reachedPeer=false) — тон тот же.
      c.emit(
        const CallOutgoingRinging(
          callId: 'c1',
          roomId: 1,
          peerMessengerUserId: 42,
        ),
      );
      await tester.pump();
      expect(player.log, ['play:connecting'], reason: 'без повторного play');
    });

    testWidgets('входящий звонок НЕ трогает ringback-плеер (только исходящий)', (
      tester,
    ) async {
      final player = _FakeRingbackPlayer();
      final c = await pumpWithRingback(
        tester,
        player,
        initial: const CallIncomingRinging(
          callId: 'c1',
          roomId: 1,
          callerMatrixUserId: '@bob:home',
        ),
      );
      // Для входящего desired=null и плеер даже не создаётся из-за дедупа —
      // никаких play/stop.
      expect(player.log, isEmpty);
      // Гасим incoming-рингтон-таймер (SystemSound) перед концом теста, чтобы
      // не осталось pending-периодиков (enableRingtone=true).
      c.emit(const CallIdle());
      await tester.pump();
    });
  });

  testWidgets('смена состояния перерисовывает overlay '
      '(outgoing → connected)', (tester) async {
    final c = await pump(
      tester,
      initial: const CallOutgoingRinging(
        callId: 'c1',
        roomId: 1,
        peerMessengerUserId: 42,
      ),
    );
    expect(find.byKey(const Key('callOutgoingHangupButton')), findsOneWidget);
    c.emit(
      CallConnected(
        callId: 'c1',
        roomId: 1,
        startedAt: DateTime.now(),
        muted: false,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('callOutgoingHangupButton')), findsNothing);
    expect(find.byKey(const Key('callTimer')), findsOneWidget);
  });
}

/// Подкласс [CallController] для widget-тестов overlay: state
/// управляется вручную ([emit]), команды записываются (не трогают
/// flutter_webrtc). Super-конструктору отдаём no-op fake-и + пустой
/// event-stream (реальный event-reactor тут не нужен — состояние
/// задаётся напрямую).
class _FakeCallController extends CallController {
  _FakeCallController()
    : super(
        rpc: _NoopRpc(),
        webrtc: _NoopWebRtc(),
        events: const Stream<MessengerEvent>.empty(),
      );

  CallState _fakeState = const CallIdle();
  int acceptCalls = 0;
  int declineCalls = 0;
  int hangupCalls = 0;
  int toggleMuteCalls = 0;
  int toggleSpeakerCalls = 0;

  @override
  bool toggleSpeaker() {
    toggleSpeakerCalls++;
    return true;
  }

  void emit(CallState s) {
    _fakeState = s;
    notifyListeners();
  }

  @override
  CallState get state => _fakeState;

  @override
  Future<void> startCall({
    required int roomId,
    int? peerMessengerUserId,
    String? peerDisplayName,
  }) async {}

  @override
  Future<void> accept() async {
    acceptCalls++;
  }

  @override
  Future<void> decline() async {
    declineCalls++;
  }

  @override
  Future<void> hangup() async {
    hangupCalls++;
  }

  @override
  bool toggleMute() {
    toggleMuteCalls++;
    return false;
  }
}

/// Fake ringback-плеер: пишет последовательность вызовов в [log]
/// (`play:<tone>` / `stop` / `dispose`) — проверяем маппинг состояние→тон
/// без платформенных аудио-каналов.
class _FakeRingbackPlayer implements CallRingbackPlayer {
  final List<String> log = [];

  @override
  Future<void> play(CallRingbackTone tone) async {
    log.add('play:${tone.name}');
  }

  @override
  Future<void> stop() async {
    log.add('stop');
  }

  @override
  Future<void> dispose() async {
    log.add('dispose');
  }
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
