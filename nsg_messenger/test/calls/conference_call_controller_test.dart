import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
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

  // ═══════════════════════════════════════════════════════════════════
  // TASK80 итерация 1 — демонстрация экрана
  // ═══════════════════════════════════════════════════════════════════

  /// Конференция с Alice (1,'pa') и Bob (2,'pb'); обе наши пары
  /// установлены (пришли answer-ы) — с этой точки можно включать показ.
  Future<_Harness> activeWithTwoPeers() async {
    final harness = _Harness();
    harness.confRpc.members = [member(1, 'pa', 1), member(2, 'pb', 2)];
    await harness.controller.join(roomId: kRoomId);
    await pump();
    for (final entry in {1: 'pa', 2: 'pb'}.entries) {
      final callId = harness.callRpc.sent
          .firstWhere(
            (e) =>
                e.eventType == CallEventType.invite &&
                ConferencePairCallId.tryParse(
                      e.callId,
                    )!.inviteeMessengerUserId ==
                    entry.key,
          )
          .callId;
      harness.emit(
        harness.callEvent(
          MessengerEventType.callAnswer,
          roomId: kRoomId,
          callId: callId,
          partyId: entry.value,
          sdp: 'answer-remote-${entry.key}',
        ),
      );
    }
    await pump();
    return harness;
  }

  List<_SentEvent> negotiates(_Harness h) => h.callRpc.sent
      .where((e) => e.eventType == CallEventType.negotiate)
      .toList();

  /// Ответить negotiate-answer-ом на все висящие renegotiate-offer-ы —
  /// как сделал бы живой пир. Без этого пара остаётся «в перезаключении»
  /// до сторожевого таймера.
  Future<void> answerNegotiations(_Harness h) async {
    for (final offer in negotiates(h).where((e) => e.sdpType == 'offer')) {
      h.emit(
        h.callEvent(
          MessengerEventType.callNegotiate,
          roomId: kRoomId,
          callId: offer.callId,
          sdp: 'renegotiate-answer',
          sdpType: 'answer',
        ),
      );
    }
    await pump();
  }

  group('TASK80 — старт показа экрана', () {
    test('claim роли + захват + видео-трек с cap-ами в КАЖДУЮ пару + '
        'negotiate-offer каждой', () async {
      final h = await activeWithTwoPeers();
      // pc пар запоминаем ДО очистки журнала: `pcForInvitee` ищет по нему.
      final pairPcs = [h.pcForInvitee(1), h.pcForInvitee(2)];
      h.callRpc.sent.clear();

      final ok = await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      expect(ok, isTrue);
      // Роль докладчика — на сервере (арбитраж), с нашим partyId.
      expect(h.confRpc.startScreenShareCount, 1);
      expect(h.confRpc.lastScreenSharePartyId, h.controller.selfPartyId);
      // Захват — с выбранного источника.
      expect(h.webrtc.displayMediaSourceIds, ['screen:0']);
      expect(h.webrtc.displayStreams.length, 1);

      for (final pc in pairPcs) {
        expect(pc.addedVideoStreams.length, 1, reason: 'видео в каждой паре');
        expect(
          pc.videoSenders.single.appliedCaps,
          [kScreenShareCaps],
          reason: 'рамки качества применены до renegotiate',
        );
      }
      final negs = negotiates(h);
      expect(negs.length, 2, reason: 'переустановка каждой пары');
      expect(negs.every((e) => e.sdpType == 'offer'), isTrue);
      expect(negs.every((e) => e.partyId == h.controller.selfPartyId), isTrue);

      final s = h.controller.state as ConferenceActive;
      expect(s.selfPresenting, isTrue);
      expect(s.presenterMessengerUserId, kSelfUserId);
      expect(s.screenSharePending, isFalse);
      expect(
        s.participants.firstWhere((p) => p.isSelf).isPresenting,
        isTrue,
      );
      await h.dispose();
    });

    test('второй докладчик получает ЯВНЫЙ отказ «показывает X» и НЕ '
        'начинает захват', () async {
      final h = await activeWithTwoPeers();
      h.confRpc.screenShareBusyBy = 1; // показывает Alice.
      h.callRpc.sent.clear();

      final ok = await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      expect(ok, isFalse);
      expect(h.webrtc.displayStreams, isEmpty, reason: 'захват не начинали');
      expect(negotiates(h), isEmpty);
      final s = h.controller.state as ConferenceActive;
      expect(s.screenShareDeniedBy, 1);
      expect(s.selfPresenting, isFalse);
      expect(s.screenSharePending, isFalse);
      await h.dispose();
    });

    test('отказ/отмена системного диалога захвата → роль докладчика '
        'немедленно освобождается', () async {
      final h = await activeWithTwoPeers();
      h.webrtc.displayMediaDenied = true;

      final ok = await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      expect(ok, isFalse);
      expect(h.confRpc.startScreenShareCount, 1);
      expect(
        h.confRpc.stopScreenShareCount,
        1,
        reason: 'иначе все видели бы «показывает X» без картинки',
      );
      final s = h.controller.state as ConferenceActive;
      expect(s.selfPresenting, isFalse);
      expect(s.presenterMessengerUserId, isNull);
      await h.dispose();
    });

    test('платформа без захвата: кнопки нет (screenShareSupported=false), '
        'start — no-op без единого RPC', () async {
      final h = _Harness();
      h.webrtc.screenShareSupported = false;
      await h.controller.join(roomId: kRoomId);
      await pump();

      final ok = await h.controller.startScreenShare();
      await pump();

      expect(ok, isFalse);
      expect(h.confRpc.startScreenShareCount, 0);
      expect(h.webrtc.displayMediaSourceIds, isEmpty);
      expect(
        (h.controller.state as ConferenceActive).screenShareSupported,
        isFalse,
      );
      await h.dispose();
    });

    test('повторный старт во время показа игнорируется (один показ)',
        () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      final again = await h.controller.startScreenShare(sourceId: 'window:7');
      await pump();

      expect(again, isFalse);
      expect(h.confRpc.startScreenShareCount, 1);
      expect(h.webrtc.displayStreams.length, 1);
      await h.dispose();
    });
  });

  group('TASK80 — новый участник во время показа', () {
    test('пара, где инвайтер МЫ, рождается сразу с видео (без лишнего '
        'negotiate)', () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();
      h.callRpc.sent.clear();

      // Carol появилась в составе с joinedAt РАНЬШЕ нашего (+10с) →
      // по конвенции «зовёт поздний» инвайтер — мы.
      h.emit(
        h.confUpdated(
          roomId: kRoomId,
          members: [
            member(1, 'pa', 1),
            member(2, 'pb', 2),
            member(3, 'pc', 3),
            member(kSelfUserId, h.controller.selfPartyId, 10),
          ],
          screenSharingUserId: kSelfUserId,
          screenSharingPartyId: h.controller.selfPartyId,
        ),
      );
      await pump();

      final pcCarol = h.pcForInvitee(3);
      expect(
        pcCarol.addedVideoStreams.length,
        1,
        reason: 'вошедший во время показа сразу получает пару с видео',
      );
      final carolCallId = h.callRpc.sent
          .firstWhere((e) => e.eventType == CallEventType.invite)
          .callId;
      expect(
        negotiates(h).where((e) => e.callId == carolCallId),
        isEmpty,
        reason: 'видео уехало первым же offer-ом — renegotiate не нужен',
      );
      await h.dispose();
    });

    test('пара, где инвайтер ПИР, доносит видео отдельным negotiate после '
        'answer-а', () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();
      h.callRpc.sent.clear();

      final callId = ConferencePairCallId.build(
        confId: h.confRpc.confId,
        inviteeMessengerUserId: kSelfUserId,
        pairId: 'pair-carol',
      );
      h.emit(h.confInvite(roomId: kRoomId, callId: callId, partyId: 'pc'));
      await pump();
      await pump();

      expect(
        h.callRpc.sent.any(
          (e) => e.eventType == CallEventType.answer && e.callId == callId,
        ),
        isTrue,
      );
      final negs = negotiates(h).where((e) => e.callId == callId).toList();
      expect(negs.length, 1, reason: 'unified-plan: m-line в answer не добавить');
      expect(negs.single.sdpType, 'offer');
      await h.dispose();
    });
  });

  group('TASK80 — остановка показа', () {
    test('stopScreenShare: трек снят из всех пар + negotiate + захват '
        'остановлен + сервер уведомлён', () async {
      final h = await activeWithTwoPeers();
      final pairPcs = [h.pcForInvitee(1), h.pcForInvitee(2)];
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();
      await answerNegotiations(h);
      h.callRpc.sent.clear();

      await h.controller.stopScreenShare();
      await pump();
      await pump();

      for (final pc in pairPcs) {
        expect(pc.removedVideoSenders.length, 1);
      }
      expect(negotiates(h).length, 2);
      expect(h.webrtc.displayStreams.single.disposed, isTrue);
      expect(h.confRpc.stopScreenShareCount, 1);
      final s = h.controller.state as ConferenceActive;
      expect(s.selfPresenting, isFalse);
      expect(s.presenterMessengerUserId, isNull);
      await h.dispose();
    });

    test('СИСТЕМНАЯ кнопка «Прекратить показ» (onEnded трека) приводит '
        'состояние в порядок', () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      h.webrtc.displayStreams.single.videos.single.emitEnded();
      await pump();

      final s = h.controller.state as ConferenceActive;
      expect(s.selfPresenting, isFalse, reason: 'UI не врёт «показ идёт»');
      expect(h.confRpc.stopScreenShareCount, 1);
      expect(h.pcForInvitee(1).removedVideoSenders.length, 1);
      expect(h.webrtc.displayStreams.single.disposed, isTrue);
      await h.dispose();
    });

    test('выход из конференции ГАСИТ захват экрана', () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      await h.controller.leave();
      await pump();

      expect(
        h.webrtc.displayStreams.single.disposed,
        isTrue,
        reason: 'иначе останется работающий screen-capture без зрителей',
      );
      expect(h.controller.screenShareRenderer, isNull);
      await h.dispose();
    });

    test('смерть конференции (пустой ростер) гасит захват', () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      h.emit(h.confUpdated(roomId: kRoomId, members: const []));
      await pump();

      expect(h.webrtc.displayStreams.single.disposed, isTrue);
      expect(h.controller.state, isA<ConferenceCallEnded>());
      await h.dispose();
    });

    test('dispose контроллера (закрытие приложения) гасит захват', () async {
      final h = await activeWithTwoPeers();
      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();

      h.controller.dispose();
      await pump();

      expect(h.webrtc.displayStreams.single.disposed, isTrue);
      await h.eventCtrl.close();
    });

    test('аудио НЕ прерывается стартом и остановкой показа', () async {
      final h = await activeWithTwoPeers();
      final micStream = h.webrtc.streams.single;
      final pcAlice = h.pcForInvitee(1);
      final audioStreamsBefore = pcAlice.addedStreams.length;

      await h.controller.startScreenShare(sourceId: 'screen:0');
      await pump();
      await h.controller.stopScreenShare();
      await pump();

      expect(micStream.disposed, isFalse, reason: 'микрофон живёт');
      expect(pcAlice.closed, isFalse, reason: 'pc пары не пересоздавался');
      expect(pcAlice.addedStreams.length, audioStreamsBefore);
      expect(h.webrtc.pcs.length, 2, reason: 'новых pc не заводили');
      await h.dispose();
    });
  });

  group('TASK80 — приём чужого показа', () {
    test('ростер назначил докладчика + пришёл его видео-поток → рендерер '
        'привязан', () async {
      final h = await activeWithTwoPeers();
      h.emit(
        h.confUpdated(
          roomId: kRoomId,
          members: [
            member(1, 'pa', 1),
            member(2, 'pb', 2),
            member(kSelfUserId, h.controller.selfPartyId, 10),
          ],
          screenSharingUserId: 1,
          screenSharingPartyId: 'pa',
        ),
      );
      await pump();

      final s = h.controller.state as ConferenceActive;
      expect(s.presenterMessengerUserId, 1);
      expect(s.selfPresenting, isFalse);
      expect(
        s.participants.firstWhere((p) => p.messengerUserId == 1).isPresenting,
        isTrue,
      );

      final remote = _FakeStream(withVideo: true);
      h.pcForInvitee(1).emitRemoteVideo(remote);
      await pump();

      expect(h.controller.screenShareRenderer, isNotNull);
      expect(h.webrtc.renderers.single.bound, same(remote));
      await h.dispose();
    });

    test('negotiate-offer докладчика → отвечаем negotiate-answer', () async {
      final h = await activeWithTwoPeers();
      final callId = h.callRpc.sent
          .firstWhere(
            (e) =>
                e.eventType == CallEventType.invite &&
                ConferencePairCallId.tryParse(
                      e.callId,
                    )!.inviteeMessengerUserId ==
                    1,
          )
          .callId;
      final pcAlice = h.pcForInvitee(1);
      h.callRpc.sent.clear();

      h.emit(
        h.callEvent(
          MessengerEventType.callNegotiate,
          roomId: kRoomId,
          callId: callId,
          partyId: 'pa',
          sdp: 'screen-share-offer',
          sdpType: 'offer',
        ),
      );
      await pump();

      final sent = h.callRpc.sent.single;
      expect(sent.eventType, CallEventType.negotiate);
      expect(sent.sdpType, 'answer');
      expect(pcAlice.remoteDescriptions.last.sdp, 'screen-share-offer');
      await h.dispose();
    });

    test('показ докладчика окончен (ростер без screenSharing*) → рендерер '
        'отвязан', () async {
      final h = await activeWithTwoPeers();
      final members = [
        member(1, 'pa', 1),
        member(2, 'pb', 2),
        member(kSelfUserId, h.controller.selfPartyId, 10),
      ];
      h.emit(
        h.confUpdated(
          roomId: kRoomId,
          members: members,
          screenSharingUserId: 1,
          screenSharingPartyId: 'pa',
        ),
      );
      await pump();
      h.pcForInvitee(1).emitRemoteVideo(_FakeStream(withVideo: true));
      await pump();
      expect(h.webrtc.renderers.single.bound, isNotNull);

      h.emit(h.confUpdated(roomId: kRoomId, members: members));
      await pump();

      expect(h.webrtc.renderers.single.bound, isNull);
      expect(
        (h.controller.state as ConferenceActive).presenterMessengerUserId,
        isNull,
      );
      await h.dispose();
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
    int? screenSharingUserId,
    String? screenSharingPartyId,
  }) => MessengerEvent(
    eventType: MessengerEventType.conferenceUpdated,
    serverTimestamp: DateTime.utc(2026, 1, 1),
    roomId: roomId,
    conferenceConfId: confId ?? confRpc.confId,
    conferenceMembers: members,
    conferenceScreenSharingMessengerUserId: screenSharingUserId,
    conferenceScreenSharingPartyId: screenSharingPartyId,
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
    String? sdpType,
  }) => MessengerEvent(
    eventType: type,
    serverTimestamp: DateTime.utc(2026, 1, 1),
    roomId: roomId,
    matrixRoomId: '!room:test',
    callId: callId,
    callPartyId: partyId,
    callSdp: sdp,
    callCandidates: candidates,
    callSdpType: sdpType,
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

  /// **TASK80**: серверный арбитраж докладчика (в проде — unique-индекс).
  int? screenSharingUserId;
  String? screenSharingPartyId;

  /// Кто «уже показывает» — startScreenShare отвечает Busy.
  int? screenShareBusyBy;
  int startScreenShareCount = 0;
  int stopScreenShareCount = 0;
  String? lastScreenSharePartyId;

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
      screenSharingMessengerUserId: screenSharingUserId,
      screenSharingPartyId: screenSharingPartyId,
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

  @override
  Future<ConferenceState> startScreenShare({
    required int roomId,
    required String partyId,
  }) async {
    startScreenShareCount++;
    lastScreenSharePartyId = partyId;
    final busy = screenShareBusyBy;
    if (busy != null) {
      throw ScreenShareBusyException(presenterMessengerUserId: busy);
    }
    screenSharingUserId = selfUserId;
    screenSharingPartyId = partyId;
    final t0 = DateTime.utc(2026, 1, 1);
    return ConferenceState(
      confId: confId,
      roomId: roomId,
      members: const [],
      createdAt: t0,
      updatedAt: t0,
      screenSharingMessengerUserId: screenSharingUserId,
      screenSharingPartyId: screenSharingPartyId,
    );
  }

  @override
  Future<void> stopScreenShare({required int roomId}) async {
    stopScreenShareCount++;
    screenSharingUserId = null;
    screenSharingPartyId = null;
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
    this.sdpType,
  });
  final CallEventType eventType;
  final String callId;
  final String partyId;
  final String? sdp;
  final List<CallIceCandidate>? candidates;
  final String? hangupReason;

  /// **TASK80**: роль SDP в negotiate (`offer`/`answer`).
  final String? sdpType;
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
        sdpType: sdpType,
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

  /// **TASK80**: платформа умеет захват экрана (по умолчанию — да,
  /// «мы на десктопе»). false → контроллер обязан отказывать, а UI —
  /// не рисовать кнопку.
  bool screenShareSupported = true;
  bool needsSourcePicker = true;

  /// Пользователь отказал в захвате / закрыл системный диалог.
  bool displayMediaDenied = false;

  final List<_FakeStream> displayStreams = [];
  final List<String?> displayMediaSourceIds = [];
  List<ScreenShareSource> sources = const [
    ScreenShareSource(id: 'screen:0', name: 'Screen 1', isWindow: false),
    ScreenShareSource(id: 'window:7', name: 'Editor', isWindow: true),
  ];
  final List<_FakeRenderer> renderers = [];

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

  @override
  bool get supportsScreenShare => screenShareSupported;

  @override
  bool get screenShareNeedsSourcePicker => needsSourcePicker;

  @override
  Future<List<ScreenShareSource>> listScreenShareSources() async => sources;

  @override
  Future<RtcMediaStream> getDisplayMedia({
    required ScreenShareCaps caps,
    String? sourceId,
  }) async {
    displayMediaSourceIds.add(sourceId);
    if (displayMediaDenied) {
      throw const ScreenSharePermissionDeniedException();
    }
    final s = _FakeStream(withVideo: true);
    displayStreams.add(s);
    return s;
  }

  @override
  Future<RtcVideoRenderer> createVideoRenderer() async {
    final r = _FakeRenderer();
    renderers.add(r);
    return r;
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

  /// **TASK80**: видео-треки, добавленные в этот pc, и снятые отправители.
  final List<RtcMediaStream> addedVideoStreams = [];
  final List<_FakeVideoSender> videoSenders = [];
  final List<RtcVideoSender> removedVideoSenders = [];
  void Function(RtcMediaStream stream)? _onRemoteVideo;

  void emitLocalIce(RtcIce ice) => _onIce?.call(ice);
  void emitConnState(RtcConnState s) => _onConn?.call(s);
  // ignore: unused_element
  void emitRemoteTrack() => _onRemote?.call();
  void emitRemoteVideo(RtcMediaStream stream) => _onRemoteVideo?.call(stream);

  @override
  set onIceCandidate(void Function(RtcIce candidate)? cb) => _onIce = cb;
  @override
  set onConnectionState(void Function(RtcConnState state)? cb) => _onConn = cb;
  @override
  set onRemoteTrack(void Function()? cb) => _onRemote = cb;
  @override
  set onRemoteVideoStream(void Function(RtcMediaStream stream)? cb) =>
      _onRemoteVideo = cb;

  @override
  Future<void> addLocalStream(RtcMediaStream stream) async =>
      addedStreams.add(stream);

  @override
  Future<RtcVideoSender?> addVideoTrack(RtcMediaStream stream) async {
    if (stream.videoTracks.isEmpty) return null;
    addedVideoStreams.add(stream);
    final sender = _FakeVideoSender();
    videoSenders.add(sender);
    return sender;
  }

  @override
  Future<void> removeVideoSender(RtcVideoSender sender) async =>
      removedVideoSenders.add(sender);

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
  _FakeStream({bool withVideo = false})
    : videos = withVideo ? [_FakeVideoTrack()] : [];

  final List<_FakeTrack> tracks = [_FakeTrack()];
  final List<_FakeVideoTrack> videos;
  bool disposed = false;

  @override
  List<MediaAudioTrack> get audioTracks => tracks;

  @override
  List<MediaVideoTrack> get videoTracks => videos;

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeTrack implements MediaAudioTrack {
  @override
  bool enabled = true;
}

/// **TASK80**: видео-трек захвата. [emitEnded] изображает системную
/// кнопку «Прекратить показ» (остановка ВНЕ нашего UI).
class _FakeVideoTrack implements MediaVideoTrack {
  @override
  bool enabled = true;

  void Function()? _onEnded;

  @override
  set onEnded(void Function()? cb) => _onEnded = cb;

  void emitEnded() => _onEnded?.call();
}

class _FakeVideoSender implements RtcVideoSender {
  final List<ScreenShareCaps> appliedCaps = [];

  @override
  Future<void> applyScreenShareCaps(ScreenShareCaps caps) async =>
      appliedCaps.add(caps);
}

class _FakeRenderer implements RtcVideoRenderer {
  RtcMediaStream? bound;
  bool disposed = false;

  @override
  Future<void> initialize() async {}

  @override
  set srcObject(RtcMediaStream? stream) => bound = stream;

  @override
  Widget buildView({BoxFit fit = BoxFit.contain}) =>
      const SizedBox(key: Key('fakeVideoView'));

  @override
  Future<void> dispose() async => disposed = true;
}
