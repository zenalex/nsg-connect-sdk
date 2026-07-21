import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/calls/call_media_diagnostics.dart';

/// Юнит-тесты чистых хелперов диагностики медиа-пути звонка
/// («соединились, звука нет»): сводка SDP + форматирование RTP-статов.
void main() {
  group('summarizeSdp', () {
    const audioSdp = 'v=0\r\n'
        'o=- 1 2 IN IP4 127.0.0.1\r\n'
        's=-\r\n'
        't=0 0\r\n'
        'm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'
        'a=rtpmap:111 opus/48000/2\r\n'
        'a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1\r\n'
        'a=sendrecv\r\n'
        'a=candidate:1 1 udp 2113 10.0.0.1 5000 typ host\r\n';

    test('извлекает направление, opus pt/fmtp и число кандидатов', () {
      final s = summarizeSdp(audioSdp);
      expect(s, contains('dir=sendrecv'));
      expect(s, contains('opus=111'));
      expect(s, contains('useinbandfec=1'));
      expect(s, contains('sdpCandidates=1'));
    });

    test('recvonly/inactive направление видно (диагностика one-way)', () {
      expect(
        summarizeSdp(audioSdp.replaceFirst('a=sendrecv', 'a=recvonly')),
        contains('dir=recvonly'),
      );
      expect(
        summarizeSdp(audioSdp.replaceFirst('a=sendrecv', 'a=inactive')),
        contains('dir=inactive'),
      );
    });

    test('нет аудио m-line → явный маркер ОТСУТСТВУЕТ', () {
      expect(summarizeSdp('v=0\r\ns=-\r\n'), contains('ОТСУТСТВУЕТ'));
    });

    test('opus отсутствует → маркер НЕТ (сигнал проблемы кодека)', () {
      const noOpus = 'm=audio 9 UDP/TLS/RTP/SAVPF 8\r\n'
          'a=rtpmap:8 PCMA/8000\r\n'
          'a=sendrecv\r\n';
      expect(summarizeSdp(noOpus), contains('opus=НЕТ'));
    });

    test('работает и с \\n-переводами (flutter_webrtc иногда без \\r)', () {
      final lf = audioSdp.replaceAll('\r\n', '\n');
      expect(summarizeSdp(lf), contains('dir=sendrecv'));
    });
  });

  group('CallStatsSnapshot.toLogLine', () {
    test('форматирует send/recv/pair; уровни с 3 знаками', () {
      const snap = CallStatsSnapshot(
        packetsSent: 100,
        bytesSent: 5000,
        micAudioLevel: 0.42,
        packetsReceived: 0,
        bytesReceived: 0,
        recvAudioLevel: 0,
        pairState: 'succeeded',
        localCandidateType: 'relay',
        remoteCandidateType: 'srflx',
      );
      final line = snap.toLogLine();
      // Диагностический кейс: шлём, но НЕ принимаем (pkt=0) при succeeded-паре.
      expect(line, contains('SEND(pkt=100'));
      expect(line, contains('mic=0.420'));
      expect(line, contains('RECV(pkt=0'));
      expect(line, contains('pair=succeeded'));
      expect(line, contains('cand=relay/srflx'));
    });

    test('null-поля рендерятся как прочерк (не падает)', () {
      const snap = CallStatsSnapshot();
      final line = snap.toLogLine();
      expect(line, contains('pkt=-'));
      expect(line, contains('mic=-'));
      expect(line, contains('cand=?/?'));
    });
  });

  group('CallMediaCollector — вердикт (что уйдёт в GlitchTip)', () {
    test('нет снимков → no_stats', () {
      expect(CallMediaCollector().verdict, 'no_stats');
    });

    test('не дошли до connected → never_connected, а НЕ no_rtp_received', () {
      // Звонок, который не соединился (сборка 62: сигналинг прошёл, потом 43 с
      // тишины и отбой). Пакетов нет не потому, что медиа сломано, а потому,
      // что канала нет — вердикты про RTP тут врали бы. Смотреть надо pair/cand.
      final c = CallMediaCollector()
        ..addStats(
          const CallStatsSnapshot(
            packetsSent: 0,
            packetsReceived: 0,
            pairState: 'checking',
            localCandidateType: 'relay',
          ),
        );
      expect(c.verdict, 'never_connected');
    });

    test('connected, но 0 принятых пакетов → no_rtp_received', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsSent: 500, packetsReceived: 0));
      expect(c.verdict, 'no_rtp_received');
    });

    test('пакеты идут, но уровень 0 → rtp_received_but_silent', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(
          const CallStatsSnapshot(packetsReceived: 300, recvAudioLevel: 0),
        );
      expect(c.verdict, 'rtp_received_but_silent');
    });

    test('пакеты + уровень есть → rtp_ok_playout_suspect '
        '(приём исправен, значит виновато проигрывание)', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(
          const CallStatsSnapshot(packetsReceived: 300, recvAudioLevel: 0.2),
        );
      expect(c.verdict, 'rtp_ok_playout_suspect');
    });

    test('вердикт берётся по ПОСЛЕДНЕМУ снимку (поток мог поехать позже)', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsReceived: 0))
        ..addStats(
          const CallStatsSnapshot(packetsReceived: 100, recvAudioLevel: 0.1),
        );
      expect(c.verdict, 'rtp_ok_playout_suspect');
    });
  });

  group('CallMediaCollector — теги и отчёт', () {
    test('recv_growth=yes когда приём растёт между снимками', () {
      final c = CallMediaCollector()
        ..addStats(const CallStatsSnapshot(packetsReceived: 10))
        ..addStats(const CallStatsSnapshot(packetsReceived: 90));
      expect(c.tags()['diag.recv_growth'], 'yes');
    });

    test('recv_growth=no когда приём замер (пакеты не идут)', () {
      final c = CallMediaCollector()
        ..addStats(const CallStatsSnapshot(packetsReceived: 10))
        ..addStats(const CallStatsSnapshot(packetsReceived: 10));
      expect(c.tags()['diag.recv_growth'], 'no');
    });

    test('jitter_ms из последнего снимка, секунды → мс', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsReceived: 10))
        ..addStats(
          const CallStatsSnapshot(packetsReceived: 90, jitterSeconds: 0.042),
        );
      expect(c.tags()['diag.jitter_ms'], '42.0');
    });

    test('loss_pct считается по ДЕЛЬТЕ окна, а не по абсолюту', () {
      // За окно: принято +90 (10→100), потеряно +10 (2→12). Доля = 10/100.
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsReceived: 10, packetsLost: 2))
        ..addStats(
          const CallStatsSnapshot(packetsReceived: 100, packetsLost: 12),
        );
      expect(c.tags()['diag.loss_pct'], '10.00');
    });

    test('loss_pct отсутствует, если счётчика потерь нет (старый WebRTC)', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsReceived: 10))
        ..addStats(const CallStatsSnapshot(packetsReceived: 90));
      expect(c.tags().containsKey('diag.loss_pct'), isFalse);
    });

    test('чистый звонок: потерь нет → loss_pct=0.00', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsReceived: 10, packetsLost: 0))
        ..addStats(
          const CallStatsSnapshot(packetsReceived: 500, packetsLost: 0),
        );
      expect(c.tags()['diag.loss_pct'], '0.00');
    });

    test('теги несут ключевые метрики + сводки SDP', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addSdp(
          'local_offer',
          'm=audio 9 RTP 111\r\na=rtpmap:111 opus/48000/2\r\na=sendrecv\r\n',
        )
        ..trackInfo = 'kind=audio streams=1 enabled=true'
        ..addStats(
          const CallStatsSnapshot(
            packetsSent: 500,
            packetsReceived: 0,
            micAudioLevel: 0.3,
            recvAudioLevel: 0,
            pairState: 'succeeded',
            localCandidateType: 'relay',
            remoteCandidateType: 'host',
          ),
        );
      final t = c.tags();
      expect(t['diag.verdict'], 'no_rtp_received');
      expect(t['diag.sent_pkt'], '500');
      expect(t['diag.recv_pkt'], '0');
      expect(t['diag.mic_level'], '0.300');
      expect(t['diag.cand'], 'relay/host');
      expect(t['diag.pair'], 'succeeded');
      expect(t['diag.track'], contains('kind=audio'));
      expect(t['diag.sdp.local_offer'], contains('dir=sendrecv'));
    });

    test('remote-трек не пришёл → тег NONE (сильный сигнал сам по себе)', () {
      final c = CallMediaCollector()
        ..addStats(const CallStatsSnapshot(packetsReceived: 0));
      expect(c.tags()['diag.track'], contains('NONE'));
    });

    test('длинный тег подрезается под лимит трекера (~200)', () {
      final c = CallMediaCollector()..trackInfo = 'x' * 500;
      final v = c.tags()['diag.track']!;
      expect(v.length, lessThanOrEqualTo(190));
      expect(v, endsWith('...'));
    });

    test('takeReport идемпотентен — отчёт уходит РОВНО один раз '
        '(flush и по таймеру, и на close)', () {
      final c = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsReceived: 0));
      final first = c.takeReport();
      expect(first, isNotNull);
      expect(first.toString(), 'CallMedia: no_rtp_received');
      expect(c.takeReport(), isNull, reason: 'второй раз не шлём');
    });

    test('toString отчёта СТАБИЛЕН (группировка issue по вердикту)', () {
      // Два разных звонка с одним вердиктом → одинаковый value → один issue.
      final a = CallMediaCollector()
        ..wasConnected = true
        ..addStats(const CallStatsSnapshot(packetsSent: 1, packetsReceived: 0));
      final b = CallMediaCollector()
        ..wasConnected = true
        ..addStats(
          const CallStatsSnapshot(packetsSent: 999, packetsReceived: 0),
        );
      expect(a.takeReport().toString(), b.takeReport().toString());
    });
  });
}
