import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/auth_token_provider.dart' show ErrorReporter;
import 'package:nsg_messenger/src/calls/call_controller.dart';
import 'package:nsg_messenger/src/calls/call_rpc.dart';
import 'package:nsg_messenger/src/calls/call_state.dart';
import 'package:nsg_messenger/src/calls/webrtc_adapter.dart';

/// **TASK46 (SDK)**: unit-тесты state-machine [CallController].
///
/// flutter_webrtc абстрагирован за [WebRtcAdapter] → тесты подсовывают
/// [_FakeWebRtc] (in-memory pc/media без нативного плагина). RPC —
/// [_FakeCallRpc] (записывает отправленные call-события). Event bus —
/// обычный `StreamController<MessengerEvent>.broadcast()`.
void main() {
  const kRoomId = 101;

  group('CallController — исходящий звонок', () {
    test('startCall → invite отправлен с SDP offer, состояние '
        'outgoingRinging', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      final c = harness.controller;

      await c.startCall(roomId: kRoomId, peerMessengerUserId: 42);
      await pump();

      expect(c.state, isA<CallOutgoingRinging>());
      final s = c.state as CallOutgoingRinging;
      expect(s.callId, 'call-1');
      expect(s.roomId, kRoomId);
      expect(s.peerMessengerUserId, 42);

      // invite отправлен ровно один, с sdp offer.
      final invites = harness.rpc.sent
          .where((e) => e.eventType == CallEventType.invite)
          .toList();
      expect(invites.length, 1);
      expect(invites.single.callId, 'call-1');
      expect(invites.single.partyId, 'party-self');
      expect(invites.single.sdp, contains('offer-sdp'));
      await harness.dispose();
    });

    test('issue #5: сервер отклоняет invite (PeerUnavailable) → '
        'CallEnded(peerUnavailable), invite не «ушёл»', () async {
      // Гейт недоступного собеседника: server бросает PeerUnavailableException
      // на invite. Контроллер завершает звонок понятной причиной сразу, а не
      // висит в «идёт вызов».
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      harness.rpc.failInviteWithPeerUnavailable = true;
      final c = harness.controller;

      await c.startCall(roomId: kRoomId, peerMessengerUserId: 42);
      await pump();

      expect(c.state, isA<CallEnded>());
      expect((c.state as CallEnded).reason, CallEndReason.peerUnavailable);
      // invite не записан (бросок ДО отправки) и никакой hangup не ушёл
      // (notifyPeer:false — гасить на той стороне нечего).
      expect(harness.rpc.sent, isEmpty);
      await harness.dispose();
    });

    test('ringback-стадии: до отправки invite reachedPeer=false, после — '
        'true', () async {
      // Две различимые стадии обратного сигнала: пока идёт setup (TURN-fetch
      // держим гейтом) — «дозвон до сервера»; после доставки invite —
      // «звонит на устройстве».
      final harness = _Harness(idSeq: ['party-self', 'call-1'], blockTurn: true);
      final c = harness.controller;
      final startFuture = c.startCall(roomId: kRoomId, peerMessengerUserId: 42);
      await pump();

      // getTurn висит → invite ещё не ушёл → стадия 1.
      expect(c.state, isA<CallOutgoingRinging>());
      expect(
        (c.state as CallOutgoingRinging).reachedPeer,
        isFalse,
        reason: 'invite ещё не доставлен',
      );

      // Разблокируем setup → invite уходит → стадия 2.
      harness.rpc.releaseTurn();
      await startFuture;
      await pump();
      expect(c.state, isA<CallOutgoingRinging>());
      final s = c.state as CallOutgoingRinging;
      expect(s.reachedPeer, isTrue, reason: 'invite доставлен серверу');
      // Прочие поля сохранились при перевыставлении состояния.
      expect(s.callId, 'call-1');
      expect(s.peerMessengerUserId, 42);
      await harness.dispose();
    });

    test('ringback: answer до перевыставления reachedPeer НЕ откатывает в '
        'outgoingRinging', () async {
      // Если answer прилетит, пока invite ещё «в полёте», бамп reachedPeer
      // не должен вернуть нас из connecting обратно в outgoing.
      final harness = _Harness(idSeq: ['party-self', 'call-1'], blockTurn: true);
      final c = harness.controller;
      final startFuture = c.startCall(roomId: kRoomId);
      await pump();
      // invite ещё не ушёл; эмулируем ранний answer в буфер стрима.
      harness.rpc.releaseTurn();
      await startFuture;
      await pump();
      // Теперь answer.
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
          partyId: 'party-peer',
        ),
      );
      await pump();
      expect(c.state, isA<CallConnecting>());
      await harness.dispose();
    });

    test('getTurnCredentials попадает в iceServers (TURN + STUN)', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      harness.rpc.turn = TurnCredentials(
        urls: ['turns:turn.example:5349'],
        username: 'u',
        credential: 'p',
        ttlSeconds: 300,
      );
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      final servers = harness.webrtc.lastIceServers!;
      // STUN всегда + TURN добавлен.
      expect(servers.any((s) => '${s['urls']}'.contains('stun')), isTrue);
      expect(
        servers.any((s) => '${s['urls']}'.contains('turns:turn.example')),
        isTrue,
      );
      await harness.dispose();
    });

    test('getTurnCredentials упал → gracefully STUN-only, звонок '
        'продолжается', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      harness.rpc.turnThrows = true;
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      expect(harness.controller.state, isA<CallOutgoingRinging>());
      final servers = harness.webrtc.lastIceServers!;
      expect(servers.length, 1, reason: 'только STUN');
      await harness.dispose();
    });

    test('getTurnCredentials упал → потеря TURN УХОДИТ В ТРЕКЕР', () async {
      // Регрессия 2026-07-16: деградация на STUN-only была немой (debugPrint,
      // невидимый в release) → звонки не соединялись, а в логах устройства
      // «всё штатно». Без relay сотовая сеть не пробивается, поэтому факт
      // обязан быть виден в трекере.
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      harness.rpc.turnThrows = true;
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      expect(harness.reporter.reports, hasLength(1));
      final r = harness.reporter.reports.single;
      expect(r.error, isA<CallTurnUnavailableReport>());
      expect(
        r.error.toString(),
        'CallTurn: TURN-креды не получены — звонок пойдёт STUN-only',
        reason: 'стабильный toString → один issue в GlitchTip',
      );
      // Причина уходит тегом — по нему в трекере видно, ЧТО именно сломалось
      // (в проде это был MessengerNotAuthenticatedException).
      expect(r.tags?['turn.cause'], contains('turn unavailable'));
      await harness.dispose();
    });

    test('сервер отдал ПУСТОЙ список TURN-url → тоже репортим', () async {
      // TURN выключен на сервере (нет TURN_URLS/секрета) — RPC проходит, но
      // relay-серверов нет. Для звонка это тот же STUN-only, молчать нельзя.
      // `_FakeCallRpc.turn` по умолчанию как раз с пустыми urls.
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      expect(harness.reporter.reports, hasLength(1));
      expect(harness.reporter.reports.single.tags?['turn.cause'], 'empty_urls');
      await harness.dispose();
    });

    test('TURN получен → в трекер НИЧЕГО не шлём', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      harness.rpc.turn = TurnCredentials(
        urls: ['turns:turn.example:5349'],
        username: 'u',
        credential: 'p',
        ttlSeconds: 300,
      );
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      expect(harness.reporter.reports, isEmpty);
      await harness.dispose();
    });

    test('входящий answer → setRemoteDescription + connecting → '
        '(pc connected) → connected', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      final c = harness.controller;
      await c.startCall(roomId: kRoomId);
      await pump();

      // Отвечающая сторона прислала answer.
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
          partyId: 'party-peer',
        ),
      );
      await pump();

      // remote description применён к нашему pc.
      final pc = harness.webrtc.lastPc!;
      expect(
        pc.remoteDescriptions.any((d) => d.type == SdpType.answer),
        isTrue,
      );
      expect(c.state, isA<CallConnecting>());

      // pc сообщает connected.
      pc.emitConnState(RtcConnState.connected);
      await pump();
      expect(c.state, isA<CallConnected>());
      final s = c.state as CallConnected;
      expect(s.callId, 'call-1');
      expect(s.muted, isFalse);
      await harness.dispose();
    });

    test('микрофон запрещён → CallEnded(micDenied)', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      harness.webrtc.micDenied = true;
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      expect(harness.controller.state, isA<CallEnded>());
      expect(
        (harness.controller.state as CallEnded).reason,
        CallEndReason.micDenied,
      );
      // invite мог уйти или нет; главное — hangup peer-у НЕ шлём при
      // micDenied на исходящем (signalingSent=false).
      expect(
        harness.rpc.sent.any((e) => e.eventType == CallEventType.hangup),
        isFalse,
      );
      await harness.dispose();
    });
  });

  group('CallController — входящий звонок', () {
    test('callInvite из bus → incomingRinging(callId, caller)', () async {
      final harness = _Harness(idSeq: ['party-self']);
      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'call-in',
          sdp: 'offer-sdp-remote',
          senderMatrixUserId: '@bob:server',
        ),
      );
      await pump();

      expect(harness.controller.state, isA<CallIncomingRinging>());
      final s = harness.controller.state as CallIncomingRinging;
      expect(s.callId, 'call-in');
      expect(s.roomId, kRoomId);
      expect(s.callerMatrixUserId, '@bob:server');
      await harness.dispose();
    });

    test(
      '«звонок из прошлого» (invite старше lifetime) — игнор, без ринга',
      () async {
        // Replay Matrix-синхронизации при reconnect / бэклог пушей может
        // доставить давний m.call.invite. Ринговать его = фантомный входящий.
        final harness = _Harness(
          idSeq: ['party-self'],
          // «Сейчас» — на сутки позже timestamp-а invite-а → возраст ≫ lifetime.
          nowUtc: DateTime.utc(2026, 1, 2),
        );
        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-stale',
            sdp: 'offer-sdp-remote',
            senderMatrixUserId: '@bob:server',
            serverTimestamp: DateTime.utc(2026, 1, 1),
            lifetime: 60000,
          ),
        );
        await pump();

        // Не звонит…
        expect(harness.controller.state, isA<CallIdle>());
        // …и собеседнику НЕ шлём reject (звонящего давно нет).
        expect(harness.rpc.sent, isEmpty);
        await harness.dispose();
      },
    );

    test(
      'свежий invite в пределах lifetime+запас — рингует (fetch-побудка)',
      () async {
        // Push-побудка убитого app: сервер держит invite в кэше ~65с, клиент
        // дотягивает его чуть постаревшим — должен зазвонить.
        final harness = _Harness(
          idSeq: ['party-self'],
          nowUtc: DateTime.utc(2026, 1, 1, 0, 1, 5), // +65с
        );
        harness.controller.ingestFetchedInvite(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-fresh',
            sdp: 'offer-sdp-remote',
            senderMatrixUserId: '@bob:server',
            serverTimestamp: DateTime.utc(2026, 1, 1),
            lifetime: 60000,
          ),
        );
        await pump();
        expect(harness.controller.state, isA<CallIncomingRinging>());
        await harness.dispose();
      },
    );

    test(
      'дубликат callInvite (тот же callId) — идемпотентно, без reject',
      () async {
        // Push-побудка: invite может прийти дважды — live-стрим И
        // ingestFetchedInvite. Второй раз НЕ должен авто-reject-нуть свой же
        // входящий (иначе собеседник увидит «отклонён»).
        final harness = _Harness(idSeq: ['party-self']);
        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-dup',
            sdp: 'offer-sdp-remote',
            senderMatrixUserId: '@bob:server',
          ),
        );
        await pump();
        expect(harness.controller.state, isA<CallIncomingRinging>());

        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-dup',
            sdp: 'offer-sdp-remote',
            senderMatrixUserId: '@bob:server',
          ),
        );
        await pump();
        expect(harness.controller.state, isA<CallIncomingRinging>());
        expect(
          (harness.controller.state as CallIncomingRinging).callId,
          'call-dup',
        );
        expect(
          harness.rpc.sent.any((e) => e.eventType == CallEventType.reject),
          isFalse,
        );
        await harness.dispose();
      },
    );

    test(
      'ingestFetchedInvite → incomingRinging (push-побудка убитого app)',
      () async {
        final harness = _Harness(idSeq: ['party-self']);
        harness.controller.ingestFetchedInvite(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-fetch',
            sdp: 'offer-sdp-remote',
            senderMatrixUserId: '@bob:server',
          ),
        );
        await pump();
        expect(harness.controller.state, isA<CallIncomingRinging>());
        expect(
          (harness.controller.state as CallIncomingRinging).callId,
          'call-fetch',
        );
        await harness.dispose();
      },
    );

    test('accept → setRemoteDescription(offer) + answer отправлен', () async {
      final harness = _Harness(idSeq: ['party-self']);
      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'call-in',
          sdp: 'offer-sdp-remote',
        ),
      );
      await pump();

      await harness.controller.accept();
      await pump();

      final pc = harness.webrtc.lastPc!;
      expect(
        pc.remoteDescriptions.any(
          (d) => d.type == SdpType.offer && d.sdp == 'offer-sdp-remote',
        ),
        isTrue,
      );
      final answers = harness.rpc.sent
          .where((e) => e.eventType == CallEventType.answer)
          .toList();
      expect(answers.length, 1);
      expect(answers.single.callId, 'call-in');
      expect(answers.single.sdp, contains('answer-sdp'));
      expect(harness.controller.state, isA<CallConnecting>());
      await harness.dispose();
    });

    test('decline → reject отправлен + CallEnded(declined)', () async {
      final harness = _Harness(idSeq: ['party-self']);
      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'call-in',
          sdp: 'offer-sdp-remote',
        ),
      );
      await pump();

      await harness.controller.decline();
      await pump();

      expect(
        harness.rpc.sent.any((e) => e.eventType == CallEventType.reject),
        isTrue,
      );
      expect(harness.controller.state, isA<CallEnded>());
      expect(
        (harness.controller.state as CallEnded).reason,
        CallEndReason.declined,
      );
      await harness.dispose();
    });
  });

  group('CallController — ICE trickle', () {
    test(
      'локальные кандидаты после invite → sendCallEvent(candidates)',
      () async {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        await harness.controller.startCall(roomId: kRoomId);
        await pump();

        // pc эмитит локальный ICE-кандидат (уже после invite).
        harness.webrtc.lastPc!.emitLocalIce(
          const RtcIce(
            candidate: 'cand-local-1',
            sdpMid: '0',
            sdpMLineIndex: 0,
          ),
        );
        await pump();

        final iceEvents = harness.rpc.sent
            .where((e) => e.eventType == CallEventType.candidates)
            .toList();
        expect(iceEvents.length, 1);
        expect(iceEvents.single.candidates!.single.candidate, 'cand-local-1');
        await harness.dispose();
      },
    );

    test(
      'локальные кандидаты ДО invite буферятся, отправляются после',
      () async {
        final harness = _Harness(
          idSeq: ['party-self', 'call-1'],
          blockTurn:
              true, // задержим setup, чтобы ICE успел прийти раньше invite
        );
        final startFuture = harness.controller.startCall(roomId: kRoomId);
        await pump();

        // pc создан, но invite ещё не ушёл (getTurn висит). Эмитим ICE.
        final pc = harness.webrtc.lastPc;
        if (pc != null) {
          pc.emitLocalIce(const RtcIce(candidate: 'early-cand'));
        }
        // Разблокируем turn → setup завершится, invite уйдёт, буфер сольётся.
        harness.rpc.releaseTurn();
        await startFuture;
        await pump();

        final iceEvents = harness.rpc.sent
            .where((e) => e.eventType == CallEventType.candidates)
            .toList();
        // early-cand должен уйти после отправки invite.
        if (pc != null) {
          expect(
            iceEvents.any(
              (e) => e.candidates!.single.candidate == 'early-cand',
            ),
            isTrue,
          );
        }
        await harness.dispose();
      },
    );

    test(
      'входящие кандидаты (callee, после accept) → addIceCandidate на pc',
      () async {
        final harness = _Harness(idSeq: ['party-self']);
        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-in',
            sdp: 'offer-sdp-remote',
          ),
        );
        await pump();
        await harness.controller.accept();
        await pump();

        harness.emit(
          _callEvent(
            MessengerEventType.callCandidates,
            roomId: kRoomId,
            callId: 'call-in',
            candidates: [CallIceCandidate(candidate: 'cand-remote-1')],
          ),
        );
        await pump();

        final pc = harness.webrtc.lastPc!;
        expect(pc.addedIce.any((c) => c.candidate == 'cand-remote-1'), isTrue);
        await harness.dispose();
      },
    );

    test('входящие кандидаты ДО remoteDescription буферятся и применяются '
        'после answer (caller)', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      // remote answer ещё НЕ пришёл → входящие кандидаты буферятся.
      harness.emit(
        _callEvent(
          MessengerEventType.callCandidates,
          roomId: kRoomId,
          callId: 'call-1',
          candidates: [CallIceCandidate(candidate: 'buffered-remote')],
        ),
      );
      await pump();
      final pc = harness.webrtc.lastPc!;
      expect(pc.addedIce, isEmpty, reason: 'буферизуются до remote SDP');

      // answer приходит → remote SDP установлен → буфер сливается.
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
        ),
      );
      await pump();
      expect(pc.addedIce.any((c) => c.candidate == 'buffered-remote'), isTrue);
      await harness.dispose();
    });
  });

  group('CallController — hangup / teardown', () {
    test('hangup → hangup отправлен + pc закрыт + треки stop + '
        'CallEnded', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      final pc = harness.webrtc.lastPc!;
      final stream = harness.webrtc.lastStream!;

      await harness.controller.hangup();
      await pump();

      expect(
        harness.rpc.sent.any((e) => e.eventType == CallEventType.hangup),
        isTrue,
      );
      expect(pc.closed, isTrue);
      expect(stream.disposed, isTrue);
      expect(harness.controller.state, isA<CallEnded>());
      expect(
        (harness.controller.state as CallEnded).reason,
        CallEndReason.localHangup,
      );
      await harness.dispose();
    });

    test('входящий hangup из bus → CallEnded(remoteHangup), обратно hangup '
        'НЕ шлём', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      harness.rpc.sent.clear();

      harness.emit(
        _callEvent(
          MessengerEventType.callHangup,
          roomId: kRoomId,
          callId: 'call-1',
        ),
      );
      await pump();

      expect(harness.controller.state, isA<CallEnded>());
      expect(
        (harness.controller.state as CallEnded).reason,
        CallEndReason.remoteHangup,
      );
      expect(
        harness.rpc.sent.any((e) => e.eventType == CallEventType.hangup),
        isFalse,
        reason: 'на удалённый hangup обратно не отвечаем',
      );
      await harness.dispose();
    });

    test('pc connectionState=failed → CallEnded(failed)', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.failed);
      await pump();

      expect(harness.controller.state, isA<CallEnded>());
      expect(
        (harness.controller.state as CallEnded).reason,
        CallEndReason.failed,
      );
      await harness.dispose();
    });
  });

  group('CallController — mute', () {
    test('toggleMute в connected → track.enabled=false + muted=true', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();
      expect(harness.controller.state, isA<CallConnected>());

      final muted = harness.controller.toggleMute();
      expect(muted, isTrue);
      expect((harness.controller.state as CallConnected).muted, isTrue);
      expect(harness.webrtc.lastStream!.tracks.single.enabled, isFalse);

      // unmute.
      final unmuted = harness.controller.toggleMute();
      expect(unmuted, isFalse);
      expect(harness.webrtc.lastStream!.tracks.single.enabled, isTrue);
      await harness.dispose();
    });

    test('toggleMute вне connected → no-op false', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      // ещё outgoingRinging.
      expect(harness.controller.toggleMute(), isFalse);
      await harness.dispose();
    });
  });

  // Маршрут вывода задаётся ЯВНО (а не отдаётся умолчанию платформы) — это
  // и есть инвариант группы. Дефолт — «к уху»/наушники, как в любой
  // звонилке; громкая связь включается кнопкой. Раньше дефолтом был динамик,
  // но по отладочной причине (ловили «звука нет» — hands-free делал тракт
  // слышимым на лежащем телефоне); причину нашли, костыль снят.
  group('CallController — маршрут вывода', () {
    test('исходящий: маршрут применён сразу при захвате микрофона '
        '(до connected) и по умолчанию — «к уху»/наушники', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      // Звук маршрутизирован ещё на outgoingRinging: ждать connected
      // нельзя — сессия уже живёт, и умолчание платформы уже действует.
      expect(harness.controller.speakerOn, isFalse);
      expect(harness.webrtc.speakerRoutes, isNotEmpty);
      expect(harness.webrtc.speakerRoutes.first, isFalse);
      await harness.dispose();
    });

    test('входящий accept: маршрут применён (не только на исходящем)', () async {
      final harness = _Harness(idSeq: ['party-self']);
      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'call-in',
          sdp: 'offer-sdp',
        ),
      );
      await pump();
      await harness.controller.accept();
      await pump();

      expect(harness.webrtc.speakerRoutes, contains(false));
      await harness.dispose();
    });

    test('connected переприменяет маршрут (активация сессии сбрасывает '
        'его на умолчание платформы)', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      final beforeConnect = harness.webrtc.speakerRoutes.length;

      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();

      expect(harness.controller.state, isA<CallConnected>());
      expect(
        harness.webrtc.speakerRoutes.length,
        greaterThan(beforeConnect),
        reason: 'маршрут переприменён на connected',
      );
      expect(harness.webrtc.speakerRoutes.last, isFalse);
      await harness.dispose();
    });

    test('toggleSpeaker в connected → громкая связь + speakerOn=true, '
        'обратно → снова «к уху»', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();

      // Дефолт «к уху» → первый тап включает громкую связь.
      final on = harness.controller.toggleSpeaker();
      await pump();
      expect(on, isTrue);
      expect((harness.controller.state as CallConnected).speakerOn, isTrue);
      expect(harness.webrtc.speakerRoutes.last, isTrue);

      final off = harness.controller.toggleSpeaker();
      await pump();
      expect(off, isFalse);
      expect((harness.controller.state as CallConnected).speakerOn, isFalse);
      expect(harness.webrtc.speakerRoutes.last, isFalse);
      await harness.dispose();
    });

    test('toggleSpeaker вне connected → no-op, маршрут не трогаем', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();
      final routesAfterStart = harness.webrtc.speakerRoutes.length;

      // ещё outgoingRinging → no-op, значение не переворачивается
      // (остаётся дефолтное «к уху»).
      expect(harness.controller.toggleSpeaker(), isFalse);
      expect(harness.controller.speakerOn, isFalse);
      expect(harness.webrtc.speakerRoutes.length, routesAfterStart);
      await harness.dispose();
    });

    test('выбор пользователя переживает звонок: включил громкую связь → '
        'следующий звонок стартует на динамике', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1', 'call-2']);
      final c = harness.controller;
      await c.startCall(roomId: kRoomId);
      await pump();
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();
      c.toggleSpeaker(); // дефолт «к уху» → пользователь включил динамик
      await pump();
      await c.hangup();
      await pump();

      harness.webrtc.speakerRoutes.clear();
      await c.startCall(roomId: kRoomId);
      await pump();

      expect(c.speakerOn, isTrue);
      expect(harness.webrtc.speakerRoutes.first, isTrue);
      await harness.dispose();
    });
  });

  group('CallController — multi-device (второе устройство рядом)', () {
    // Сценарий постановщика: у собеседника открыты И телефон, И Windows.
    // Invite приходит на оба, звонят оба. Трубку берут на телефоне → caller
    // шлёт select_answer с partyId телефона. Windows обязан замолчать и
    // НЕ уметь оборвать уже идущий разговор.

    test('select_answer с ЧУЖИМ partyId → входящий гаснет '
        '(ответили на другом устройстве), peer-у ничего не шлём', () async {
      final harness = _Harness(idSeq: ['party-self']);
      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'call-in',
          sdp: 'offer-sdp-remote',
        ),
      );
      await pump();
      expect(harness.controller.state, isA<CallIncomingRinging>());
      harness.rpc.sent.clear();

      // Caller выбрал ДРУГОЕ наше устройство.
      harness.emit(
        _callEvent(
          MessengerEventType.callSelectAnswer,
          roomId: kRoomId,
          callId: 'call-in',
          selectedPartyId: 'party-phone',
        ),
      );
      await pump();

      expect(harness.controller.state, isA<CallEnded>());
      expect(
        (harness.controller.state as CallEnded).reason,
        CallEndReason.answeredElsewhere,
      );
      // Ключевое: НЕ шлём hangup/reject — разговор жив на другом устройстве.
      expect(
        harness.rpc.sent.any(
          (e) =>
              e.eventType == CallEventType.hangup ||
              e.eventType == CallEventType.reject,
        ),
        isFalse,
        reason: 'обрывать чужой живой разговор нельзя',
      );
      await harness.dispose();
    });

    test('select_answer с НАШИМ partyId → продолжаем звонить (выбрали нас)', () async {
      final harness = _Harness(idSeq: ['party-self']);
      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'call-in',
          sdp: 'offer-sdp-remote',
        ),
      );
      await pump();

      harness.emit(
        _callEvent(
          MessengerEventType.callSelectAnswer,
          roomId: kRoomId,
          callId: 'call-in',
          selectedPartyId: 'party-self',
        ),
      );
      await pump();
      expect(harness.controller.state, isA<CallIncomingRinging>());
      await harness.dispose();
    });

    test('РЕГРЕСС: reject от ДРУГОГО устройства собеседника НЕ обрывает '
        'живой разговор', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      final c = harness.controller;
      await c.startCall(roomId: kRoomId);
      await pump();
      // Ответило устройство party-phone → говорим с ним.
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
          partyId: 'party-phone',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();
      expect(c.state, isA<CallConnected>());

      // На втором устройстве (Windows) нажали «отклонить».
      harness.emit(
        _callEvent(
          MessengerEventType.callReject,
          roomId: kRoomId,
          callId: 'call-1',
          partyId: 'party-windows',
        ),
      );
      await pump();

      expect(
        c.state,
        isA<CallConnected>(),
        reason: 'reject от чужого устройства игнорируем — разговор жив',
      );
      await harness.dispose();
    });

    test('hangup от ТОГО устройства, с которым говорим → завершаем', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      final c = harness.controller;
      await c.startCall(roomId: kRoomId);
      await pump();
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
          partyId: 'party-phone',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();

      harness.emit(
        _callEvent(
          MessengerEventType.callHangup,
          roomId: kRoomId,
          callId: 'call-1',
          partyId: 'party-phone',
        ),
      );
      await pump();
      expect(c.state, isA<CallEnded>());
      expect(
        (c.state as CallEnded).reason,
        CallEndReason.remoteHangup,
      );
      await harness.dispose();
    });

    test('hangup БЕЗ partyId → завершаем как раньше (1:1 не ломаем)', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      final c = harness.controller;
      await c.startCall(roomId: kRoomId);
      await pump();
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
          partyId: 'party-phone',
        ),
      );
      await pump();
      harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
      await pump();

      harness.emit(
        _callEvent(
          MessengerEventType.callHangup,
          roomId: kRoomId,
          callId: 'call-1',
          // partyId отсутствует
        ),
      );
      await pump();
      expect(c.state, isA<CallEnded>());
      await harness.dispose();
    });
  });

  group('CallController — glare', () {
    test(
      'наш callId меньше → игнорируем входящий invite, держим свой',
      () async {
        // Наш callId 'aaa' < входящий 'zzz' → мы выигрываем.
        final harness = _Harness(idSeq: ['party-self', 'aaa']);
        await harness.controller.startCall(roomId: kRoomId);
        await pump();
        expect(harness.controller.state, isA<CallOutgoingRinging>());

        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'zzz',
            sdp: 'offer-remote',
          ),
        );
        await pump();

        // Остаёмся в своём исходящем звонке (не свалились в incoming).
        expect(harness.controller.state, isA<CallOutgoingRinging>());
        expect((harness.controller.state as CallOutgoingRinging).callId, 'aaa');
        await harness.dispose();
      },
    );

    test('входящий callId меньше → сворачиваем свой (glareLost) и '
        'принимаем входящий', () async {
      // Наш 'zzz' > входящий 'aaa' → уступаем.
      final harness = _Harness(idSeq: ['party-self', 'zzz']);
      final states = <CallState>[];
      harness.controller.addListener(
        () => states.add(harness.controller.state),
      );
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: kRoomId,
          callId: 'aaa',
          sdp: 'offer-remote',
        ),
      );
      await pump();

      // Свой звонок свёрнут (glareLost прошёл через ended), теперь входящий.
      expect(harness.controller.state, isA<CallIncomingRinging>());
      expect((harness.controller.state as CallIncomingRinging).callId, 'aaa');
      // Не упали — прошли через ended(glareLost).
      expect(
        states.whereType<CallEnded>().any(
          (e) => e.reason == CallEndReason.glareLost,
        ),
        isTrue,
      );
      await harness.dispose();
    });
  });

  group('CallController — фильтрация чужих событий', () {
    test('answer для другого callId игнорируется', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'DIFFERENT-CALL',
          sdp: 'answer-sdp',
        ),
      );
      await pump();

      // Остались в outgoingRinging (чужой answer не применился).
      expect(harness.controller.state, isA<CallOutgoingRinging>());
      await harness.dispose();
    });

    test('invite в другой комнате во время активного звонка → busy '
        'auto-reject, текущий не тронут', () async {
      final harness = _Harness(idSeq: ['party-self', 'call-1']);
      await harness.controller.startCall(roomId: kRoomId);
      await pump();

      harness.emit(
        _callEvent(
          MessengerEventType.callInvite,
          roomId: 999,
          callId: 'other-room-call',
          sdp: 'offer-remote',
        ),
      );
      await pump();

      // Текущий звонок держится; входящему ушёл reject.
      expect(harness.controller.state, isA<CallOutgoingRinging>());
      expect(
        harness.rpc.sent.any(
          (e) =>
              e.eventType == CallEventType.reject &&
              e.callId == 'other-room-call',
        ),
        isTrue,
      );
      await harness.dispose();
    });
  });

  group('CallController — invite lifetime timeout', () {
    test('никто не ответил за lifetime → CallEnded(timeout)', () {
      fakeAsync((async) {
        final harness = _Harness(
          idSeq: ['party-self', 'call-1'],
          inviteLifetime: const Duration(seconds: 5),
        );
        harness.controller.startCall(roomId: kRoomId);
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallOutgoingRinging>());

        async.elapse(const Duration(seconds: 6));
        expect(harness.controller.state, isA<CallEnded>());
        expect(
          (harness.controller.state as CallEnded).reason,
          CallEndReason.timeout,
        );
      });
    });
  });

  group('CallController — connect timeout', () {
    test('answer получен, но pc не connected за 45с → CallEnded(failed)', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        harness.controller.startCall(roomId: kRoomId);
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallOutgoingRinging>());

        harness.emit(
          _callEvent(
            MessengerEventType.callAnswer,
            roomId: kRoomId,
            callId: 'call-1',
            sdp: 'answer-sdp',
            partyId: 'party-peer',
          ),
        );
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallConnecting>());

        // pc так и не сообщил connected → «Соединение…» не висит вечно,
        // а завершается явным failed (индикация для пользователя).
        async.elapse(const Duration(seconds: 46));
        expect(harness.controller.state, isA<CallEnded>());
        expect(
          (harness.controller.state as CallEnded).reason,
          CallEndReason.failed,
        );
      });
    });

    test('pc connected до таймаута → остаётся Connected, таймаут снят', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        harness.controller.startCall(roomId: kRoomId);
        async.flushMicrotasks();

        harness.emit(
          _callEvent(
            MessengerEventType.callAnswer,
            roomId: kRoomId,
            callId: 'call-1',
            sdp: 'answer-sdp',
            partyId: 'party-peer',
          ),
        );
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallConnecting>());

        harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallConnected>());

        // Прошло сильно больше таймаута — не должно откатиться в failed.
        async.elapse(const Duration(seconds: 60));
        expect(harness.controller.state, isA<CallConnected>());
      });
    });
  });

  group('CallController — network resilience (ICE restart)', () {
    // Довести исходящий звонок (caller) до connected внутри fakeAsync.
    _FakePc connectOutgoing(_Harness harness, FakeAsync async) {
      harness.controller.startCall(roomId: kRoomId);
      async.flushMicrotasks();
      harness.emit(
        _callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: 'call-1',
          sdp: 'answer-sdp',
          partyId: 'party-peer',
        ),
      );
      async.flushMicrotasks();
      final pc = harness.webrtc.lastPc!;
      pc.emitConnState(RtcConnState.connected);
      async.flushMicrotasks();
      return pc;
    }

    test('failed после connected (caller) → ICE restart, negotiate-offer '
        'уходит', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);
        expect(harness.controller.state, isA<CallConnected>());
        harness.rpc.sent.clear();

        // Сеть сменилась → pc сообщает failed. Уже connected → рестарт.
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();

        expect(pc.iceRestartOffers, 1, reason: 'offer c iceRestart:true');
        final negotiates = harness.rpc.sent
            .where((e) => e.eventType == CallEventType.negotiate)
            .toList();
        expect(negotiates.length, 1);
        expect(negotiates.single.sdpType, 'offer');
        expect(negotiates.single.callId, 'call-1');
        // Не завершились — рестарт вместо CallEnded.
        expect(harness.controller.state, isA<CallConnected>());
      });
    });

    test('dispose во время in-flight рестарта → паразитный hangup НЕ уходит '
        '(fix#5b)', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);
        // Следующий restart-createOffer зависнет на гейте — рестарт in-flight.
        pc.offerGate = Completer<void>();
        harness.rpc.sent.clear();

        pc.emitConnState(RtcConnState.failed); // → старт ICE-restart
        async.flushMicrotasks();
        expect(
          pc.iceRestartOffers,
          1,
          reason: 'рестарт начат, createOffer ждёт',
        );

        // dispose ловит in-flight рестарт: закрывает pc и помечает ended.
        harness.controller.dispose();
        // Отпускаем гейт → createOffer падает на закрытом pc → catch в
        // _restartIce зовёт _endCall(notifyPeer:true). Флаг ended (fix#5b)
        // делает его no-op, иначе улетел бы m.call.hangup после dispose.
        pc.offerGate!.complete();
        async.flushMicrotasks();

        expect(
          harness.rpc.sent.any((e) => e.eventType == CallEventType.hangup),
          isFalse,
          reason: 'после dispose паразитный hangup в комнату не шлём',
        );
      });
    });

    test('disconnected <5с само восстановилось → рестарта нет', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);
        harness.rpc.sent.clear();

        pc.emitConnState(RtcConnState.disconnected);
        // Через 3с вернулось в connected — дебаунс должен сняться.
        async.elapse(const Duration(seconds: 3));
        pc.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        // Проходит остаток окна и запас — рестарт НЕ должен выстрелить.
        async.elapse(const Duration(seconds: 5));

        expect(pc.iceRestartOffers, 0);
        expect(
          harness.rpc.sent.any((e) => e.eventType == CallEventType.negotiate),
          isFalse,
        );
        expect(harness.controller.state, isA<CallConnected>());
      });
    });

    test('disconnected >5с не восстановилось → ICE restart', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);
        harness.rpc.sent.clear();

        pc.emitConnState(RtcConnState.disconnected);
        async.elapse(const Duration(seconds: 6));

        expect(pc.iceRestartOffers, 1);
        expect(
          harness.rpc.sent.any(
            (e) =>
                e.eventType == CallEventType.negotiate && e.sdpType == 'offer',
          ),
          isTrue,
        );
      });
    });

    test('2 неудачных рестарта → CallEnded(failed)', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);

        // 1-й failed → restart #1 (перевзводит connect-таймаут).
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        expect(pc.iceRestartOffers, 1);
        // Рестарт не поднял → снова failed → restart #2.
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        expect(pc.iceRestartOffers, 2);
        // Третий failed → лимит исчерпан → существующий путь CallEnded(failed).
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();

        expect(pc.iceRestartOffers, 2, reason: 'больше 2 не пробуем');
        expect(harness.controller.state, isA<CallEnded>());
        expect(
          (harness.controller.state as CallEnded).reason,
          CallEndReason.failed,
        );
      });
    });

    test('успешный рестарт (re-connected) обнуляет счётчик попыток', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);

        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        expect(pc.iceRestartOffers, 1);
        // Рестарт поднял соединение.
        pc.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        // Новый обрыв — счётчик сброшен, снова можем рестартить дважды.
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        expect(pc.iceRestartOffers, 3, reason: '1 + сброс + ещё 2');
        expect(harness.controller.state, isA<CallConnected>());
      });
    });

    test('callee отвечает answer-ом на negotiate-offer', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self']);
        // Входящий → accept → connected (callee).
        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-in',
            sdp: 'offer-sdp-remote',
          ),
        );
        async.flushMicrotasks();
        harness.controller.accept();
        async.flushMicrotasks();
        harness.webrtc.lastPc!.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallConnected>());
        harness.rpc.sent.clear();

        // Caller прислал negotiate-offer (ICE restart с той стороны).
        harness.emit(
          _callEvent(
            MessengerEventType.callNegotiate,
            roomId: kRoomId,
            callId: 'call-in',
            sdp: 'restart-offer',
            sdpType: 'offer',
          ),
        );
        async.flushMicrotasks();

        final pc = harness.webrtc.lastPc!;
        expect(
          pc.remoteDescriptions.any((d) => d.sdp == 'restart-offer'),
          isTrue,
        );
        final negotiates = harness.rpc.sent
            .where((e) => e.eventType == CallEventType.negotiate)
            .toList();
        expect(negotiates.length, 1);
        expect(negotiates.single.sdpType, 'answer');
      });
    });

    test(
      'glare-защита: callee (входящий звонок) сам рестарт НЕ инициирует',
      () {
        fakeAsync((async) {
          final harness = _Harness(idSeq: ['party-self']);
          harness.emit(
            _callEvent(
              MessengerEventType.callInvite,
              roomId: kRoomId,
              callId: 'call-in',
              sdp: 'offer-sdp-remote',
            ),
          );
          async.flushMicrotasks();
          harness.controller.accept();
          async.flushMicrotasks();
          final pc = harness.webrtc.lastPc!;
          pc.emitConnState(RtcConnState.connected);
          async.flushMicrotasks();
          harness.rpc.sent.clear();

          // Сеть сменилась у callee → failed. Callee НЕ инициирует negotiate
          // (только caller), чтобы не было встречных offer-ов. Но и НЕ убивает
          // звонок мгновенно (fix#2): взводит recovery-окно и ждёт caller-
          // restart. Пока окно живо — CallConnected.
          pc.emitConnState(RtcConnState.failed);
          async.flushMicrotasks();

          expect(pc.iceRestartOffers, 0);
          expect(
            harness.rpc.sent.any((e) => e.eventType == CallEventType.negotiate),
            isFalse,
          );
          // Мгновенного kill нет — держим звонок в течение recovery-окна.
          expect(harness.controller.state, isA<CallConnected>());

          // Caller-restart так и не пришёл за окно (20с) → только теперь фейл.
          async.elapse(const Duration(seconds: 21));
          expect(harness.controller.state, isA<CallEnded>());
          expect(
            (harness.controller.state as CallEnded).reason,
            CallEndReason.failed,
          );
        });
      },
    );

    test('fix#2: negotiate-offer у callee ОТМЕНЯЕТ/перевзводит kill-таймер '
        '(рестарт идёт — не убивать)', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self']);
        harness.emit(
          _callEvent(
            MessengerEventType.callInvite,
            roomId: kRoomId,
            callId: 'call-in',
            sdp: 'offer-sdp-remote',
          ),
        );
        async.flushMicrotasks();
        harness.controller.accept();
        async.flushMicrotasks();
        final pc = harness.webrtc.lastPc!;
        pc.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallConnected>());

        // Сеть сменилась → callee видит disconnected → взводит recovery-окно.
        pc.emitConnState(RtcConnState.disconnected);
        // Почти дожидаемся окна (19с из 20).
        async.elapse(const Duration(seconds: 19));
        expect(
          harness.controller.state,
          isA<CallConnected>(),
          reason: 'окно ещё не истекло',
        );

        // Прилетел caller-restart negotiate-offer → kill-таймер перевзводится,
        // звонок НЕ убивается на 20-й секунде исходного окна.
        harness.emit(
          _callEvent(
            MessengerEventType.callNegotiate,
            roomId: kRoomId,
            callId: 'call-in',
            sdp: 'restart-offer',
            sdpType: 'offer',
          ),
        );
        async.flushMicrotasks();
        // Проходим точку, где истёк бы ИСХОДНЫЙ таймер (20с) — звонок жив.
        async.elapse(const Duration(seconds: 5));
        expect(
          harness.controller.state,
          isA<CallConnected>(),
          reason: 'negotiate перевзвёл kill-таймер',
        );

        // Рестарт поднял соединение → recovery снят окончательно.
        pc.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 30));
        expect(harness.controller.state, isA<CallConnected>());
      });
    });

    test('fix#5: recovery-таймаут caller-restart-а САМ завершает звонок, '
        'если P2P не восстановился (без второго failed-события)', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);

        // Рестарт запускается из CallConnected. Раньше connect-таймаут был
        // мёртвым кодом (стреляет только в CallConnecting) → звонок мог висеть
        // навсегда. Теперь взводится recovery-таймаут, работающий независимо
        // от состояния.
        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        expect(pc.iceRestartOffers, 1);
        expect(harness.controller.state, isA<CallConnected>());

        // НИКАКИХ новых событий от pc. Только время. Recovery-таймаут (15с)
        // обязан гарантированно добить невосстановленный звонок.
        async.elapse(const Duration(seconds: 16));
        expect(harness.controller.state, isA<CallEnded>());
        expect(
          (harness.controller.state as CallEnded).reason,
          CallEndReason.failed,
        );
      });
    });

    test('fix#5: успешный re-connect в пределах recovery-окна → звонок жив, '
        'таймаут снят', () {
      fakeAsync((async) {
        final harness = _Harness(idSeq: ['party-self', 'call-1']);
        final pc = connectOutgoing(harness, async);

        pc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        expect(pc.iceRestartOffers, 1);

        // Рестарт поднял соединение до истечения recovery-окна.
        async.elapse(const Duration(seconds: 5));
        pc.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        expect(harness.controller.state, isA<CallConnected>());

        // Прошло сильно больше recovery-окна — снятый таймаут не срабатывает.
        async.elapse(const Duration(seconds: 30));
        expect(harness.controller.state, isA<CallConnected>());
      });
    });
  });

  group(
    'CallController — network resilience (RPC-ретраи negotiate, fix#4)',
    () {
      _FakePc connectOutgoing(_Harness harness, FakeAsync async) {
        harness.controller.startCall(roomId: kRoomId);
        async.flushMicrotasks();
        harness.emit(
          _callEvent(
            MessengerEventType.callAnswer,
            roomId: kRoomId,
            callId: 'call-1',
            sdp: 'answer-sdp',
            partyId: 'party-peer',
          ),
        );
        async.flushMicrotasks();
        final pc = harness.webrtc.lastPc!;
        pc.emitConnState(RtcConnState.connected);
        async.flushMicrotasks();
        return pc;
      }

      test('транзиентный сбой RPC на 1-й попытке → ретрай с бэкоффом → '
          'negotiate всё же уходит', () {
        fakeAsync((async) {
          final harness = _Harness(idSeq: ['party-self', 'call-1']);
          final pc = connectOutgoing(harness, async);
          harness.rpc.sent.clear();
          // Первая отправка negotiate падает, вторая — успешна.
          harness.rpc.failNegotiateTimes = 1;

          pc.emitConnState(RtcConnState.failed);
          async.flushMicrotasks();
          // Первая попытка упала — negotiate ещё НЕ записан.
          expect(
            harness.rpc.sent.any((e) => e.eventType == CallEventType.negotiate),
            isFalse,
            reason: 'первая попытка провалилась',
          );
          // Бэкофф 1с → вторая попытка успешна.
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();
          final negotiates = harness.rpc.sent
              .where((e) => e.eventType == CallEventType.negotiate)
              .toList();
          expect(negotiates.length, 1);
          expect(negotiates.single.sdpType, 'offer');
        });
      });

      test('все 3 попытки RPC провалились → рестарт не состоялся; при '
          'исчерпании лимита → CallEnded(failed)', () {
        fakeAsync((async) {
          final harness = _Harness(idSeq: ['party-self', 'call-1']);
          final pc = connectOutgoing(harness, async);
          harness.rpc.sent.clear();
          // Все попытки padают (лимит рестартов = 2; на 2-м рестарте после
          // исчерпания ретраев звонок завершается).
          harness.rpc.failNegotiateTimes = 999;

          // Рестарт #1 — 3 попытки с бэкоффом 1с/2с (после 3-й сдаёмся).
          pc.emitConnState(RtcConnState.failed);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 10)); // покрыть бэкоффы 1+2+4
          async.flushMicrotasks();
          expect(pc.iceRestartOffers, 1);
          expect(
            harness.rpc.sent.any((e) => e.eventType == CallEventType.negotiate),
            isFalse,
            reason: 'ни одна из 3 попыток не прошла',
          );

          // Рестарт #2 (последний по лимиту) — снова все попытки падают →
          // исчерпан и лимит рестартов, и ретраи → CallEnded(failed).
          pc.emitConnState(RtcConnState.failed);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 10));
          async.flushMicrotasks();
          expect(pc.iceRestartOffers, 2, reason: 'больше 2 рестартов нет');
          expect(harness.controller.state, isA<CallEnded>());
          expect(
            (harness.controller.state as CallEnded).reason,
            CallEndReason.failed,
          );
        });
      });
    },
  );
}

/// Прогнать pending microtasks/timers-zero.
Future<void> pump() => Future<void>.delayed(Duration.zero);

// ─────────────────────────────────────────────────────────────────────
// Harness + fakes
// ─────────────────────────────────────────────────────────────────────

class _Harness {
  _Harness({
    required List<String> idSeq,
    Duration inviteLifetime = const Duration(minutes: 5),
    bool blockTurn = false,
    DateTime? nowUtc,
  }) : rpc = _FakeCallRpc(),
       webrtc = _FakeWebRtc() {
    if (blockTurn) rpc.blockTurn();
    var i = 0;
    controller = CallController(
      rpc: rpc,
      webrtc: webrtc,
      events: eventCtrl.stream,
      idGenerator: () => idSeq[i++],
      inviteLifetime: inviteLifetime,
      reporter: reporter,
      // Фиксированные часы = timestamp дефолтных invite-ов (`_callEvent`),
      // чтобы staleness-guard видел их как свежие (age 0). Тесты про
      // «звонок из прошлого» задают явный nowUtc в будущем.
      nowUtc: () => nowUtc ?? DateTime.utc(2026, 1, 1),
    );
  }

  final _FakeCallRpc rpc;
  final _FakeWebRtc webrtc;
  final _RecordingReporter reporter = _RecordingReporter();
  final StreamController<MessengerEvent> eventCtrl =
      StreamController<MessengerEvent>.broadcast();
  late final CallController controller;

  void emit(MessengerEvent e) => eventCtrl.add(e);

  Future<void> dispose() async {
    controller.dispose();
    await eventCtrl.close();
  }
}

/// Записанное исходящее call-событие.
class _SentEvent {
  _SentEvent({
    required this.eventType,
    required this.callId,
    required this.partyId,
    this.sdp,
    this.candidates,
    this.hangupReason,
    this.selectedPartyId,
    this.sdpType,
  });
  final CallEventType eventType;
  final String callId;
  final String partyId;
  final String? sdp;
  final List<CallIceCandidate>? candidates;
  final String? hangupReason;
  final String? selectedPartyId;
  final String? sdpType;
}

/// Записывает отчёты вместо отправки в трекер.
class _RecordingReporter implements ErrorReporter {
  final List<({Object error, StackTrace? stack, Map<String, String>? tags})>
  reports = [];

  @override
  void reportError(Object error, StackTrace? stack, {Map<String, String>? tags}) {
    reports.add((error: error, stack: stack, tags: tags));
  }
}

class _FakeCallRpc implements CallRpc {
  final List<_SentEvent> sent = [];
  TurnCredentials turn = TurnCredentials(
    urls: const [],
    username: '',
    credential: '',
    ttlSeconds: 0,
  );
  bool turnThrows = false;
  Completer<void>? _turnGate;

  /// **fix#4**: сколько ближайших `negotiate`-отправок должны БРОСИТЬ
  /// (имитация транзиентного сетевого сбоя при смене сети). Декрементится
  /// на каждой упавшей попытке.
  int failNegotiateTimes = 0;

  /// **issue #5**: если true — `invite` бросает [PeerUnavailableException]
  /// (имитация серверного гейта недоступного собеседника). Бросок — ДО
  /// записи в [sent], чтобы тест мог убедиться, что invite не «ушёл».
  bool failInviteWithPeerUnavailable = false;

  void blockTurn() => _turnGate = Completer<void>();
  void releaseTurn() => _turnGate?.complete();

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
  }) async {
    if (eventType == CallEventType.invite && failInviteWithPeerUnavailable) {
      throw PeerUnavailableException();
    }
    if (eventType == CallEventType.negotiate && failNegotiateTimes > 0) {
      failNegotiateTimes--;
      throw StateError('transient negotiate RPC failure (test)');
    }
    sent.add(
      _SentEvent(
        eventType: eventType,
        callId: callId,
        partyId: partyId,
        sdp: sdp,
        candidates: candidates,
        hangupReason: hangupReason,
        selectedPartyId: selectedPartyId,
        sdpType: sdpType,
      ),
    );
  }

  @override
  Future<TurnCredentials> getTurnCredentials() async {
    if (_turnGate != null) await _turnGate!.future;
    if (turnThrows) throw StateError('turn unavailable');
    return turn;
  }
}

class _FakeWebRtc implements WebRtcAdapter {
  bool micDenied = false;
  List<Map<String, dynamic>>? lastIceServers;
  _FakePc? lastPc;
  _FakeStream? lastStream;

  /// Каждый применённый маршрут вывода (`true` — громкая связь), в
  /// порядке вызовов — тесты проверяют и факт, и порядок применения.
  final List<bool> speakerRoutes = [];

  @override
  Future<void> setSpeakerphone(bool enabled) async => speakerRoutes.add(enabled);

  @override
  Future<RtcPeerConnection> createPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    lastIceServers = iceServers;
    final pc = _FakePc();
    lastPc = pc;
    return pc;
  }

  @override
  Future<RtcMediaStream> getUserMediaAudio() async {
    if (micDenied) throw const MicPermissionDeniedException();
    final s = _FakeStream();
    lastStream = s;
    return s;
  }
}

class _FakePc implements RtcPeerConnection {
  void Function(RtcIce)? _onIce;
  void Function(RtcConnState)? _onConn;
  void Function()? _onRemote;

  final List<RtcSdp> remoteDescriptions = [];
  final List<RtcSdp> localDescriptions = [];
  final List<RtcIce> addedIce = [];
  bool closed = false;

  /// Сколько раз запрашивали offer с iceRestart:true (для проверок рестарта).
  int iceRestartOffers = 0;
  var _offerCount = 0;
  var _answerCount = 0;

  /// Гейт для теста «dispose во время in-flight рестарта»: если задан,
  /// createOffer(iceRestart) ждёт его завершения — можно вклинить dispose(),
  /// закрывающий pc, до резолва. После гейта на закрытом pc createOffer
  /// бросает (как реальный libwebrtc на закрытом соединении).
  Completer<void>? offerGate;

  void emitLocalIce(RtcIce ice) => _onIce?.call(ice);
  void emitConnState(RtcConnState s) => _onConn?.call(s);
  // ignore: unused_element
  void emitRemoteTrack() => _onRemote?.call();

  @override
  set onIceCandidate(void Function(RtcIce candidate)? cb) => _onIce = cb;
  @override
  set onConnectionState(void Function(RtcConnState state)? cb) => _onConn = cb;
  @override
  set onRemoteTrack(void Function()? cb) => _onRemote = cb;

  @override
  Future<void> addLocalStream(RtcMediaStream stream) async {}

  @override
  Future<RtcSdp> createOffer({bool iceRestart = false}) async {
    if (iceRestart) iceRestartOffers++;
    final gate = offerGate;
    if (gate != null) await gate.future;
    if (closed) throw StateError('createOffer on closed pc (test)');
    return RtcSdp(type: SdpType.offer, sdp: 'offer-sdp-${_offerCount++}');
  }

  @override
  Future<RtcSdp> createAnswer() async =>
      RtcSdp(type: SdpType.answer, sdp: 'answer-sdp-${_answerCount++}');

  @override
  Future<void> setLocalDescription(RtcSdp sdp) async =>
      localDescriptions.add(sdp);

  @override
  Future<void> setRemoteDescription(RtcSdp sdp) async =>
      remoteDescriptions.add(sdp);

  @override
  Future<void> addIceCandidate(RtcIce candidate) async =>
      addedIce.add(candidate);

  @override
  Future<void> close() async => closed = true;
}

class _FakeStream implements RtcMediaStream {
  final List<_FakeTrack> tracks = [_FakeTrack()];
  bool disposed = false;

  @override
  List<MediaAudioTrack> get audioTracks => tracks;

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeTrack implements MediaAudioTrack {
  @override
  bool enabled = true;
}

// ─────────────────────────────────────────────────────────────────────
// MessengerEvent builder для call-событий
// ─────────────────────────────────────────────────────────────────────

MessengerEvent _callEvent(
  MessengerEventType type, {
  required int roomId,
  required String callId,
  String? sdp,
  List<CallIceCandidate>? candidates,
  String? partyId,
  String? senderMatrixUserId,
  int? lifetime,
  DateTime? serverTimestamp,
  String? sdpType,
  String? selectedPartyId,
}) => MessengerEvent(
  eventType: type,
  serverTimestamp: serverTimestamp ?? DateTime.utc(2026, 1, 1),
  roomId: roomId,
  matrixRoomId: '!room:test',
  callId: callId,
  callPartyId: partyId,
  callSdp: sdp,
  callCandidates: candidates,
  callSenderMatrixUserId: senderMatrixUserId,
  callLifetime: lifetime,
  callSdpType: sdpType,
  callSelectedPartyId: selectedPartyId,
);
