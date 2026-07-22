import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/calls/call_rpc.dart';
import 'package:nsg_messenger/src/calls/conference_call_controller.dart';
import 'package:nsg_messenger/src/calls/conference_call_state.dart';
import 'package:nsg_messenger/src/calls/conference_rpc.dart';
import 'package:nsg_messenger/src/calls/webrtc_adapter.dart';

/// **TASK51 итерация 1 (SDK)**: unit-тесты state-machine
/// [ConferenceCallController] — по образцу тестов `CallController` (fake
/// rpc / fake webrtc / in-memory event stream).
///
/// Мир тестов: мы — userId 10, partyId генератора 'id-0'; участники
/// Alice (userId 1, party 'pa'), Bob (userId 2, party 'pb'), Carol
/// (userId 3, party 'pc'). Базовое время t0; joinedAt задаётся смещением.
void main() {
  const kRoomId = 500;
  const kSelfUserId = 10;
  final t0 = DateTime.utc(2026, 1, 1);

  ConferenceMember member(int userId, String partyId, int joinSec) =>
      ConferenceMember(
        messengerUserId: userId,
        partyId: partyId,
        joinedAt: t0.add(Duration(seconds: joinSec)),
      );

  group('ConferenceCallController — join (исходящая конференция)', () {
    test('joiner устанавливает пары со всеми из ответа join (адресный '
        'conf:-callId, наш partyId)', () async {
      final harness = _Harness();
      // В конференции уже Alice и Bob; мы joined последними.
      harness.confRpc.members = [
        member(1, 'pa', 1),
        member(2, 'pb', 2),
      ];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      expect(harness.controller.state, isA<ConferenceActive>());
      final invites = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.invite)
          .toList();
      expect(invites.length, 2, reason: 'по invite на каждого участника');
      final invitees = invites
          .map(
            (e) =>
                ConferencePairCallId.tryParse(e.callId)!.inviteeMessengerUserId,
          )
          .toSet();
      expect(invitees, {1, 2});
      for (final inv in invites) {
        final parsed = ConferencePairCallId.tryParse(inv.callId)!;
        expect(parsed.confId, harness.confRpc.confId);
        expect(inv.partyId, harness.controller.selfPartyId);
        expect(inv.sdp, contains('offer-sdp'));
      }
      // Состав в состоянии: мы + двое, все на месте, наша плитка isSelf.
      final s = harness.controller.state as ConferenceActive;
      expect(s.participants.length, 3);
      expect(s.participants.where((p) => p.isSelf).length, 1);
      await harness.dispose();
    });

    test('ConferenceFullException → типизированное состояние «конференция '
        'полна» с лимитом', () async {
      final harness = _Harness();
      harness.confRpc.joinThrows = ConferenceFullException(maxParticipants: 4);
      await harness.controller.join(roomId: kRoomId);
      await pump();

      expect(harness.controller.state, isA<ConferenceCallEnded>());
      final s = harness.controller.state as ConferenceCallEnded;
      expect(s.reason, ConferenceEndReason.conferenceFull);
      expect(s.maxParticipants, 4);
      // Ничего не подняли: ни pc, ни микрофона.
      expect(harness.webrtc.pcs, isEmpty);
      expect(harness.webrtc.streams, isEmpty);
      await harness.dispose();
    });

    test('микрофон запрещён → leaveConference + Ended(micDenied)', () async {
      final harness = _Harness();
      harness.webrtc.micDenied = true;
      await harness.controller.join(roomId: kRoomId);
      await pump();

      expect(harness.controller.state, isA<ConferenceCallEnded>());
      expect(
        (harness.controller.state as ConferenceCallEnded).reason,
        ConferenceEndReason.micDenied,
      );
      // Членство сняли — не висим призраком до TTL.
      expect(harness.confRpc.leaveCount, 1);
      await harness.dispose();
    });
  });

  group('ConferenceCallController — конвенция «кто зовёт»', () {
    test('участник joined ПОЗЖЕ нас (из события состава) → мы НЕ зовём, '
        'ждём его invite', () async {
      final harness = _Harness();
      harness.confRpc.members = []; // мы первые.
      await harness.controller.join(roomId: kRoomId);
      await pump();
      harness.callRpc.sent.clear();

      // Carol joined позже нас (наш joinedAt в ответе join = +10с).
      harness.emit(
        harness.confUpdated(
          roomId: kRoomId,
          members: [
            member(kSelfUserId, harness.controller.selfPartyId, 10),
            member(3, 'pc', 20),
          ],
        ),
      );
      await pump();

      expect(
        harness.callRpc.sent.where(
          (e) => e.eventType == CallEventType.invite,
        ),
        isEmpty,
        reason: 'зовёт поздний — то есть Carol, а не мы',
      );
      // Carol в составе видна (пара в connecting — ждём её invite).
      final s = harness.controller.state as ConferenceActive;
      expect(s.participants.length, 2, reason: 'мы + Carol');
      expect(
        s.participants.firstWhere((p) => p.messengerUserId == 3).phase,
        ConferencePairPhase.connecting,
      );
      await harness.dispose();
    });

    test('равный joinedAt: больший messengerUserId зовёт (мы больше → '
        'invite шлём мы)', () async {
      final harness = _Harness();
      // Alice(1) с ТЕМ ЖЕ joinedAt, что и мы (+10с задаёт fake join).
      harness.confRpc.members = [member(1, 'pa', 10)];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      final invites = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.invite)
          .toList();
      expect(invites.length, 1, reason: 'tie-break: 10 > 1 — зовём мы');
      await harness.dispose();
    });

    test('равный joinedAt: наш userId меньше → не зовём', () async {
      final harness = _Harness(selfUserId: 0);
      harness.confRpc.members = [member(1, 'pa', 10)];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      expect(
        harness.callRpc.sent.where(
          (e) => e.eventType == CallEventType.invite,
        ),
        isEmpty,
        reason: 'tie-break: 0 < 1 — зовёт Alice',
      );
      await harness.dispose();
    });

    test('встречный invite при нашем неотвеченном (рассинхрон ростера) → '
        'glare пары: меньший callId выигрывает', () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1)];
      await harness.controller.join(roomId: kRoomId);
      await pump();
      final ourInvite = harness.callRpc.sent
          .firstWhere((e) => e.eventType == CallEventType.invite);

      // Alice присылает встречный invite нам с callId, лексикографически
      // МЕНЬШИМ нашего ('conf:...:id-1' vs 'conf:...:  ~ zz...' — задаём
      // явно меньший «...:0000»).
      final aliceCallId = ConferencePairCallId.build(
        confId: harness.confRpc.confId,
        inviteeMessengerUserId: kSelfUserId,
        pairId: '0000',
      );
      expect(aliceCallId.compareTo(ourInvite.callId) < 0, isTrue);
      harness.emit(
        harness.confInvite(
          roomId: kRoomId,
          callId: aliceCallId,
          partyId: 'pa',
        ),
      );
      await pump();

      // Уступили: ответили answer-ом на её callId.
      final answers = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.answer)
          .toList();
      expect(answers.length, 1);
      expect(answers.single.callId, aliceCallId);
      await harness.dispose();
    });
  });

  group('ConferenceCallController — входящая конференция', () {
    test('звонит ОДИН раз при N pairwise-invite-ах', () async {
      final harness = _Harness();
      final states = <ConferenceCallState>[];
      harness.controller.addListener(
        () => states.add(harness.controller.state),
      );
      for (var i = 0; i < 3; i++) {
        harness.emit(
          harness.confInvite(
            roomId: kRoomId,
            callId: ConferencePairCallId.build(
              confId: 'conf_incoming',
              inviteeMessengerUserId: kSelfUserId,
              pairId: 'pair-$i',
            ),
            partyId: 'pa',
          ),
        );
        await pump();
      }
      expect(
        states.whereType<ConferenceIncomingRinging>().length,
        1,
        reason: 'повторные invite-ы той же конференции не звонят снова',
      );
      expect(harness.controller.state, isA<ConferenceIncomingRinging>());
      await harness.dispose();
    });

    test('conferenceUpdated с живым составом без нас → ринг; кто зовёт = '
        'самый ранний участник', () async {
      final harness = _Harness();
      harness.emit(
        harness.confUpdated(
          roomId: kRoomId,
          confId: 'conf_incoming',
          members: [member(1, 'pa', 1), member(2, 'pb', 5)],
        ),
      );
      await pump();

      expect(harness.controller.state, isA<ConferenceIncomingRinging>());
      final s = harness.controller.state as ConferenceIncomingRinging;
      expect(s.confId, 'conf_incoming');
      expect(s.callerMessengerUserId, 1);
      expect(s.memberCount, 2);
      await harness.dispose();
    });

    test('accept: отвечает на скопившиеся invite-ы и зовёт остальных',
        () async {
      final harness = _Harness();
      // Ринг стартует событием состава: Alice + Bob.
      harness.emit(
        harness.confUpdated(
          roomId: kRoomId,
          confId: harness.confRpc.confId,
          members: [member(1, 'pa', 1), member(2, 'pb', 5)],
        ),
      );
      await pump();
      // За время ринга Alice успела прислать pairwise-invite.
      final aliceCallId = ConferencePairCallId.build(
        confId: harness.confRpc.confId,
        inviteeMessengerUserId: kSelfUserId,
        pairId: 'pair-alice',
      );
      harness.emit(
        harness.confInvite(
          roomId: kRoomId,
          callId: aliceCallId,
          partyId: 'pa',
        ),
      );
      await pump();
      expect(harness.controller.state, isA<ConferenceIncomingRinging>());

      harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 5)];
      await harness.controller.accept();
      await pump();

      expect(harness.confRpc.joinCount, 1);
      expect(harness.controller.state, isA<ConferenceActive>());
      // Alice — answer на её callId; Bob — наш invite.
      final answers = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.answer)
          .toList();
      expect(answers.length, 1);
      expect(answers.single.callId, aliceCallId);
      final invites = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.invite)
          .toList();
      expect(invites.length, 1);
      expect(
        ConferencePairCallId.tryParse(invites.single.callId)!
            .inviteeMessengerUserId,
        2,
      );
      await harness.dispose();
    });

    test('decline: ничего не шлём, состояние сброшено, повторные invite-ы '
        'той же конференции больше не звонят', () async {
      final harness = _Harness();
      harness.emit(
        harness.confInvite(
          roomId: kRoomId,
          callId: ConferencePairCallId.build(
            confId: 'conf_incoming',
            inviteeMessengerUserId: kSelfUserId,
            pairId: 'pair-0',
          ),
          partyId: 'pa',
        ),
      );
      await pump();
      harness.controller.decline();
      await pump();

      expect(harness.controller.state, isA<ConferenceCallIdle>());
      expect(harness.callRpc.sent, isEmpty, reason: 'decline молчалив');
      expect(harness.confRpc.joinCount, 0);

      harness.emit(
        harness.confInvite(
          roomId: kRoomId,
          callId: ConferencePairCallId.build(
            confId: 'conf_incoming',
            inviteeMessengerUserId: kSelfUserId,
            pairId: 'pair-1',
          ),
          partyId: 'pa',
        ),
      );
      await pump();
      expect(
        harness.controller.state,
        isA<ConferenceCallIdle>(),
        reason: 'confId уже отклонён — не звонить повторно',
      );
      await harness.dispose();
    });

    test('invite, адресованный ДРУГОМУ участнику, не звонит (пара двух '
        'других)', () async {
      final harness = _Harness();
      harness.emit(
        harness.confInvite(
          roomId: kRoomId,
          callId: ConferencePairCallId.build(
            confId: 'conf_incoming',
            inviteeMessengerUserId: 77, // не мы.
            pairId: 'pair-0',
          ),
          partyId: 'pa',
        ),
      );
      await pump();
      expect(harness.controller.state, isA<ConferenceCallIdle>());
      await harness.dispose();
    });
  });

  group('ConferenceCallController — ростер как источник правды', () {
    test('участник исчез из состава → его пара закрыта и убрана из '
        'participants', () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 2)];
      await harness.controller.join(roomId: kRoomId);
      await pump();
      expect(harness.webrtc.pcs.length, 2);
      final bobPc = harness.pcForInvitee(2);

      // Bob ушёл.
      harness.emit(
        harness.confUpdated(
          roomId: kRoomId,
          members: [
            member(1, 'pa', 1),
            member(kSelfUserId, harness.controller.selfPartyId, 10),
          ],
        ),
      );
      await pump();

      expect(bobPc.closed, isTrue);
      final s = harness.controller.state as ConferenceActive;
      expect(s.participants.map((p) => p.messengerUserId).toSet(), {
        1,
        kSelfUserId,
      });
      await harness.dispose();
    });

    test('пустой состав → конференция умерла → полный teardown', () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1)];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      harness.emit(
        harness.confUpdated(roomId: kRoomId, members: const []),
      );
      await pump();

      expect(harness.controller.state, isA<ConferenceCallEnded>());
      expect(
        (harness.controller.state as ConferenceCallEnded).reason,
        ConferenceEndReason.conferenceDied,
      );
      expect(harness.webrtc.pcs.every((pc) => pc.closed), isTrue);
      expect(harness.webrtc.streams.single.disposed, isTrue);
      // Сервер и так снёс конференцию — leave не зовём.
      expect(harness.confRpc.leaveCount, 0);
      await harness.dispose();
    });

    test('новый участник joined позже → пары нет до его invite; его invite '
        'отвечается', () async {
      final harness = _Harness();
      harness.confRpc.members = [];
      await harness.controller.join(roomId: kRoomId);
      await pump();
      harness.callRpc.sent.clear();

      // Carol пришла (joined позже) → зовёт она.
      harness.emit(
        harness.confUpdated(
          roomId: kRoomId,
          members: [
            member(kSelfUserId, harness.controller.selfPartyId, 10),
            member(3, 'pc', 30),
          ],
        ),
      );
      await pump();
      final carolCallId = ConferencePairCallId.build(
        confId: harness.confRpc.confId,
        inviteeMessengerUserId: kSelfUserId,
        pairId: 'pair-carol',
      );
      harness.emit(
        harness.confInvite(
          roomId: kRoomId,
          callId: carolCallId,
          partyId: 'pc',
        ),
      );
      await pump();

      final answers = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.answer)
          .toList();
      expect(answers.length, 1);
      expect(answers.single.callId, carolCallId);
      await harness.dispose();
    });

    test('наш partyId в составе заменён (другое наше устройство) → '
        'Ended(displaced)', () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1)];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      harness.emit(
        harness.confUpdated(
          roomId: kRoomId,
          members: [
            member(1, 'pa', 1),
            member(kSelfUserId, 'other-device-party', 30),
          ],
        ),
      );
      await pump();

      expect(harness.controller.state, isA<ConferenceCallEnded>());
      expect(
        (harness.controller.state as ConferenceCallEnded).reason,
        ConferenceEndReason.displaced,
      );
      await harness.dispose();
    });
  });

  group('ConferenceCallController — leave', () {
    test('leave: hangup всем парам + leaveConference + Ended(localLeave)',
        () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 2)];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      await harness.controller.leave();
      await pump();

      expect(harness.controller.state, isA<ConferenceCallEnded>());
      expect(
        (harness.controller.state as ConferenceCallEnded).reason,
        ConferenceEndReason.localLeave,
      );
      final hangups = harness.callRpc.sent
          .where((e) => e.eventType == CallEventType.hangup)
          .toList();
      expect(hangups.length, 2, reason: 'по hangup на каждую пару');
      expect(harness.confRpc.leaveCount, 1);
      expect(harness.webrtc.pcs.every((pc) => pc.closed), isTrue);
      expect(harness.webrtc.streams.single.disposed, isTrue);
      await harness.dispose();
    });
  });

  group('ConferenceCallController — heartbeat', () {
    test('тикает каждые interval и останавливается на leave', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.confRpc.members = [member(1, 'pa', 1)];
        unawaited(harness.controller.join(roomId: kRoomId));
        async.flushMicrotasks();
        expect(harness.confRpc.joinCount, 1);

        async.elapse(const Duration(seconds: 45));
        async.flushMicrotasks();
        expect(harness.confRpc.joinCount, 2, reason: 'heartbeat-тик = re-join');
        async.elapse(const Duration(seconds: 45));
        async.flushMicrotasks();
        expect(harness.confRpc.joinCount, 3);

        unawaited(harness.controller.leave());
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(
          harness.confRpc.joinCount,
          3,
          reason: 'после leave heartbeat остановлен',
        );
        harness.controller.dispose();
      });
    });

    test('3 проваленных heartbeat-а подряд → Ended(failed): сервер нас '
        'гарантированно зачистил по TTL', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.confRpc.members = [member(1, 'pa', 1)];
        unawaited(harness.controller.join(roomId: kRoomId));
        async.flushMicrotasks();
        expect(harness.controller.state, isA<ConferenceActive>());

        harness.confRpc.joinThrows = StateError('network down (test)');
        async.elapse(const Duration(seconds: 45 * 3));
        async.flushMicrotasks();

        expect(harness.controller.state, isA<ConferenceCallEnded>());
        expect(
          (harness.controller.state as ConferenceCallEnded).reason,
          ConferenceEndReason.failed,
        );
        harness.controller.dispose();
      });
    });
  });

  group('ConferenceCallController — аудио', () {
    test('mute применяется к общему локальному стриму (един для всех пар) '
        'и виден в состоянии', () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 2)];
      await harness.controller.join(roomId: kRoomId);
      await pump();
      final stream = harness.webrtc.streams.single;
      // Один и тот же стрим добавлен во все pc — mute действует на всех.
      for (final pc in harness.webrtc.pcs) {
        expect(pc.addedStreams.single, same(stream));
      }
      expect(stream.tracks.single.enabled, isTrue);

      final muted = harness.controller.toggleMute();
      expect(muted, isTrue);
      expect(stream.tracks.single.enabled, isFalse);
      expect((harness.controller.state as ConferenceActive).muted, isTrue);

      harness.controller.toggleMute();
      expect(stream.tracks.single.enabled, isTrue);
      await harness.dispose();
    });

    test('toggleSpeaker: маршрут применяется, состояние обновляется',
        () async {
      final harness = _Harness();
      harness.confRpc.members = [];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      final on = harness.controller.toggleSpeaker();
      expect(on, isTrue);
      expect(harness.webrtc.speakerRoutes.last, isTrue);
      expect((harness.controller.state as ConferenceActive).speakerOn, isTrue);
      await harness.dispose();
    });
  });

  group('ConferenceCallController — graceful degrade пары', () {
    test('failed пары → один ретрай с бэкоффом (новый callId), второй сбой '
        '→ пара failed, конференция живёт', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 2)];
        unawaited(harness.controller.join(roomId: kRoomId));
        async.flushMicrotasks();
        final alicePc = harness.pcForInvitee(1);
        final firstInvites = harness.callRpc.sent
            .where((e) => e.eventType == CallEventType.invite)
            .toList();
        expect(firstInvites.length, 2);

        // Пара с Alice падает.
        alicePc.emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        // Ретрай уходит после бэкоффа (2с) — новый invite, новый callId.
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        final aliceInvites = harness.callRpc.sent
            .where(
              (e) =>
                  e.eventType == CallEventType.invite &&
                  ConferencePairCallId.tryParse(
                        e.callId,
                      )!.inviteeMessengerUserId ==
                      1,
            )
            .toList();
        expect(aliceInvites.length, 2, reason: 'первый + один ретрай');
        expect(
          aliceInvites[0].callId != aliceInvites[1].callId,
          isTrue,
          reason: 'ретрай — полная переустановка с новым callId',
        );

        // Ретрай тоже падает → пара окончательно failed, конференция жива.
        harness.pcForInvitee(1, nth: 1).emitConnState(RtcConnState.failed);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();
        expect(
          harness.callRpc.sent
              .where(
                (e) =>
                    e.eventType == CallEventType.invite &&
                    ConferencePairCallId.tryParse(
                          e.callId,
                        )!.inviteeMessengerUserId ==
                        1,
              )
              .length,
          2,
          reason: 'третьего invite нет — ретрай ровно один',
        );
        expect(harness.controller.state, isA<ConferenceActive>());
        final s = harness.controller.state as ConferenceActive;
        final alice = s.participants.firstWhere(
          (p) => p.messengerUserId == 1,
        );
        expect(alice.phase, ConferencePairPhase.failed);
        final bob = s.participants.firstWhere((p) => p.messengerUserId == 2);
        expect(
          bob.phase,
          isNot(ConferencePairPhase.failed),
          reason: 'сбой одной пары не трогает другие',
        );
        harness.controller.dispose();
      });
    });

    test('connected пары отражается в phase участника', () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1)];
      await harness.controller.join(roomId: kRoomId);
      await pump();

      harness.pcForInvitee(1).emitConnState(RtcConnState.connected);
      await pump();
      final s = harness.controller.state as ConferenceActive;
      expect(
        s.participants.firstWhere((p) => p.messengerUserId == 1).phase,
        ConferencePairPhase.connected,
      );
      await harness.dispose();
    });
  });

  group('ConferenceCallController — сигналинг пар', () {
    test('answer на наш invite применяется; кандидаты буферятся до answer',
        () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1)];
      await harness.controller.join(roomId: kRoomId);
      await pump();
      final invite = harness.callRpc.sent
          .firstWhere((e) => e.eventType == CallEventType.invite);
      final pc = harness.pcForInvitee(1);

      // Кандидаты ДО answer → буфер (WebRTC требует remote SDP сперва).
      harness.emit(
        harness.callEvent(
          MessengerEventType.callCandidates,
          roomId: kRoomId,
          callId: invite.callId,
          partyId: 'pa',
          candidates: [CallIceCandidate(candidate: 'cand-1')],
        ),
      );
      await pump();
      expect(pc.addedIce, isEmpty);

      harness.emit(
        harness.callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: invite.callId,
          partyId: 'pa',
          sdp: 'answer-remote',
        ),
      );
      await pump();
      expect(
        pc.remoteDescriptions.map((d) => d.sdp),
        contains('answer-remote'),
      );
      expect(pc.addedIce.length, 1, reason: 'буфер слит после answer');
      await harness.dispose();
    });

    test('hangup пары → пара закрыта и помечена failed, конференция живёт',
        () async {
      final harness = _Harness();
      harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 2)];
      await harness.controller.join(roomId: kRoomId);
      await pump();
      final invite = harness.callRpc.sent.firstWhere(
        (e) =>
            e.eventType == CallEventType.invite &&
            ConferencePairCallId.tryParse(e.callId)!.inviteeMessengerUserId ==
                1,
      );

      harness.emit(
        harness.callEvent(
          MessengerEventType.callHangup,
          roomId: kRoomId,
          callId: invite.callId,
          partyId: 'pa',
        ),
      );
      await pump();

      expect(harness.pcForInvitee(1).closed, isTrue);
      expect(harness.controller.state, isA<ConferenceActive>());
      final s = harness.controller.state as ConferenceActive;
      expect(
        s.participants.firstWhere((p) => p.messengerUserId == 1).phase,
        ConferencePairPhase.failed,
      );
      await harness.dispose();
    });
  });

  group('ConferenceCallController — карта живых конференций комнат '
      '(UI-плашка «идёт групповой звонок»)', () {
    test('conferenceUpdated наполняет карту (confId/размер/инициатор), '
        'слушатель уведомлён', () async {
      final harness = _Harness();
      var notified = 0;
      harness.controller.addListener(() => notified++);
      // Состав включает нас (userId 10) — ринга не будет (самому себе не
      // звоним), но карта комнат обязана обновиться.
      harness.emit(
        harness.confUpdated(
          roomId: 900,
          members: [member(1, 'pa', 1), member(10, 'px', 2)],
        ),
      );
      await pump();

      final info = harness.controller.liveConferenceInRoom(900);
      expect(info, isNotNull);
      expect(info!.confId, harness.confRpc.confId);
      expect(info.memberCount, 2);
      expect(info.initiatorMessengerUserId, 1, reason: 'самый ранний');
      expect(notified, greaterThan(0));
      expect(
        harness.controller.state,
        isA<ConferenceCallIdle>(),
        reason: 'мы в составе — ринга нет, только карта',
      );
      await harness.dispose();
    });

    test('пустой состав (смерть конференции) убирает комнату из карты', () async {
      final harness = _Harness();
      harness.emit(
        harness.confUpdated(roomId: 900, members: [member(10, 'px', 1)]),
      );
      await pump();
      expect(harness.controller.liveConferenceInRoom(900), isNotNull);

      harness.emit(harness.confUpdated(roomId: 900, members: []));
      await pump();
      expect(harness.controller.liveConferenceInRoom(900), isNull);
      await harness.dispose();
    });

    test('refreshRoomConference: getConference → карта наполняется; '
        'null-ответ → комната очищается', () async {
      final harness = _Harness();
      final t0 = DateTime.utc(2026, 1, 1);
      harness.confRpc.getConferenceResult = ConferenceState(
        confId: 'conf_live',
        roomId: 901,
        members: [member(1, 'pa', 1), member(2, 'pb', 2), member(3, 'pc', 3)],
        createdAt: t0,
        updatedAt: t0,
      );
      await harness.controller.refreshRoomConference(901);
      final info = harness.controller.liveConferenceInRoom(901);
      expect(info, isNotNull);
      expect(info!.confId, 'conf_live');
      expect(info.memberCount, 3);

      // Конференция умерла между запросами → null-ответ чистит карту.
      harness.confRpc.getConferenceResult = null;
      await harness.controller.refreshRoomConference(901);
      expect(harness.controller.liveConferenceInRoom(901), isNull);
      await harness.dispose();
    });

    test('refreshRoomConference глотает ошибки RPC (best-effort)', () async {
      final harness = _Harness();
      harness.confRpc.getConferenceThrows = Exception('offline');
      await harness.controller.refreshRoomConference(902);
      expect(harness.controller.liveConferenceInRoom(902), isNull);
      await harness.dispose();
    });
  });
}

/// Прогнать pending microtasks/timers-zero.
Future<void> pump() => Future<void>.delayed(Duration.zero);

// ─────────────────────────────────────────────────────────────────────
// Harness + fakes (по образцу call_controller_test)
// ─────────────────────────────────────────────────────────────────────

class _Harness {
  _Harness({
    int selfUserId = 10,
    Duration heartbeat = const Duration(seconds: 45),
    Duration retryBackoff = const Duration(seconds: 2),
  }) : confRpc = _FakeConferenceRpc()..selfUserId = selfUserId,
       callRpc = _FakeCallRpc(),
       webrtc = _FakeWebRtc() {
    var n = 0;
    controller = ConferenceCallController(
      conferenceRpc: confRpc,
      callRpc: callRpc,
      webrtc: webrtc,
      events: eventCtrl.stream,
      selfMessengerUserId: () => selfUserId,
      idGenerator: () => 'id-${n++}',
      heartbeatInterval: heartbeat,
      pairRetryBackoff: retryBackoff,
      // Фиксированные часы = timestamp событий (staleness-guard видит их
      // свежими, age 0).
      nowUtc: () => DateTime.utc(2026, 1, 1),
    );
  }

  final _FakeConferenceRpc confRpc;
  final _FakeCallRpc callRpc;
  final _FakeWebRtc webrtc;
  final StreamController<MessengerEvent> eventCtrl =
      StreamController<MessengerEvent>.broadcast();
  late final ConferenceCallController controller;

  void emit(MessengerEvent e) => eventCtrl.add(e);

  /// pc пары, чей invite адресован [inviteeUserId] (порядок создания pc
  /// совпадает с порядком установок пар; [nth] — какой по счёту pc этого
  /// адресата, для ретраев).
  _FakePc pcForInvitee(int inviteeUserId, {int nth = 0}) {
    final invites = callRpc.sent
        .where(
          (e) =>
              e.eventType == CallEventType.invite &&
              ConferencePairCallId.tryParse(e.callId)?.inviteeMessengerUserId ==
                  inviteeUserId,
        )
        .toList();
    final callId = invites[nth].callId;
    return webrtc.pcs[callRpc.pcOrderCallIds.indexOf(callId)];
  }

  MessengerEvent confUpdated({
    required int roomId,
    String? confId,
    required List<ConferenceMember> members,
  }) => MessengerEvent(
    eventType: MessengerEventType.conferenceUpdated,
    serverTimestamp: DateTime.utc(2026, 1, 1),
    roomId: roomId,
    conferenceConfId: confId ?? confRpc.confId,
    conferenceMembers: members,
  );

  MessengerEvent confInvite({
    required int roomId,
    required String callId,
    required String partyId,
  }) => callEvent(
    MessengerEventType.callInvite,
    roomId: roomId,
    callId: callId,
    partyId: partyId,
    sdp: 'offer-remote',
  );

  MessengerEvent callEvent(
    MessengerEventType type, {
    required int roomId,
    required String callId,
    String? partyId,
    String? sdp,
    List<CallIceCandidate>? candidates,
  }) => MessengerEvent(
    eventType: type,
    serverTimestamp: DateTime.utc(2026, 1, 1),
    roomId: roomId,
    matrixRoomId: '!room:test',
    callId: callId,
    callPartyId: partyId,
    callSdp: sdp,
    callCandidates: candidates,
  );

  Future<void> dispose() async {
    controller.dispose();
    await eventCtrl.close();
  }
}

class _FakeConferenceRpc implements ConferenceRpc {
  String confId = 'conf_test1';

  /// userId «нас» в возвращаемом ростере (harness проставляет свой).
  int selfUserId = 10;

  /// Состав ДО нас: ответ join вернёт `members + [мы (joinedAt +10с)]`.
  List<ConferenceMember> members = [];

  Object? joinThrows;
  int joinCount = 0;
  int leaveCount = 0;
  String? lastJoinPartyId;

  @override
  Future<ConferenceState> joinConference({
    required int roomId,
    required String partyId,
  }) async {
    final err = joinThrows;
    if (err != null) throw err;
    joinCount++;
    lastJoinPartyId = partyId;
    final t0 = DateTime.utc(2026, 1, 1);
    final all = [
      ...members,
      if (!members.any((m) => m.partyId == partyId))
        ConferenceMember(
          messengerUserId: selfUserId,
          partyId: partyId,
          joinedAt: t0.add(const Duration(seconds: 10)),
        ),
    ];
    return ConferenceState(
      confId: confId,
      roomId: roomId,
      members: all,
      createdAt: t0,
      updatedAt: t0,
    );
  }

  @override
  Future<void> leaveConference({required int roomId}) async {
    leaveCount++;
  }

  /// **UI-чанк**: ответ getConference для тестов refreshRoomConference.
  ConferenceState? getConferenceResult;
  Object? getConferenceThrows;

  @override
  Future<ConferenceState?> getConference({required int roomId}) async {
    final err = getConferenceThrows;
    if (err != null) throw err;
    return getConferenceResult;
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
  });
  final CallEventType eventType;
  final String callId;
  final String partyId;
  final String? sdp;
  final List<CallIceCandidate>? candidates;
  final String? hangupReason;
}

class _FakeCallRpc implements CallRpc {
  final List<_SentEvent> sent = [];

  /// callId в порядке отправки invite/answer — сопоставление «какой pc
  /// какой паре принадлежит» (pc создаётся до отправки сигнала пары, в
  /// том же порядке).
  final List<String> pcOrderCallIds = [];

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
    if (eventType == CallEventType.invite ||
        eventType == CallEventType.answer) {
      pcOrderCallIds.add(callId);
    }
    sent.add(
      _SentEvent(
        eventType: eventType,
        callId: callId,
        partyId: partyId,
        sdp: sdp,
        candidates: candidates,
        hangupReason: hangupReason,
      ),
    );
  }

  @override
  Future<TurnCredentials> getTurnCredentials() async => TurnCredentials(
    urls: const [],
    username: '',
    credential: '',
    ttlSeconds: 0,
  );
}

class _FakeWebRtc implements WebRtcAdapter {
  bool micDenied = false;
  final List<_FakePc> pcs = [];
  final List<_FakeStream> streams = [];
  final List<bool> speakerRoutes = [];

  @override
  Future<void> setSpeakerphone(bool enabled) async =>
      speakerRoutes.add(enabled);

  @override
  Future<RtcPeerConnection> createPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    final pc = _FakePc();
    pcs.add(pc);
    return pc;
  }

  @override
  Future<RtcMediaStream> getUserMediaAudio() async {
    if (micDenied) throw const MicPermissionDeniedException();
    final s = _FakeStream();
    streams.add(s);
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
  final List<RtcMediaStream> addedStreams = [];
  bool closed = false;
  var _offerCount = 0;
  var _answerCount = 0;

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
  Future<void> addLocalStream(RtcMediaStream stream) async =>
      addedStreams.add(stream);

  @override
  Future<RtcSdp> createOffer({bool iceRestart = false}) async =>
      RtcSdp(type: SdpType.offer, sdp: 'offer-sdp-${_offerCount++}');

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
