import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/src/calls/sdp_tuning.dart';

/// **TASK46 (SDK)**: юнит-тесты чистой [tuneOpusSdp] — тюнинг Opus в
/// локальном SDP (FEC/DTX/моно/битрейт) под плохую связь.
void main() {
  // Минимальный аудио-SDP с Opus payload type 111.
  String sdp({String? opusFmtp, String eol = '\r\n'}) {
    final lines = <String>[
      'v=0',
      'o=- 0 0 IN IP4 127.0.0.1',
      's=-',
      't=0 0',
      'm=audio 9 UDP/TLS/RTP/SAVPF 111 0',
      'a=rtpmap:111 opus/48000/2',
      if (opusFmtp != null) 'a=fmtp:111 $opusFmtp',
      'a=rtpmap:0 PCMU/8000',
    ];
    return lines.join(eol);
  }

  /// Разобрать fmtp-строку Opus (pt=111) в map key→value для проверок.
  Map<String, String> opusFmtpParams(String tuned) {
    final line = tuned
        .split(RegExp(r'\r\n|\n'))
        .firstWhere((l) => l.startsWith('a=fmtp:111 '));
    final params = <String, String>{};
    for (final part in line.substring('a=fmtp:111 '.length).split(';')) {
      final eq = part.indexOf('=');
      if (eq <= 0) {
        params[part] = '';
      } else {
        params[part.substring(0, eq)] = part.substring(eq + 1);
      }
    }
    return params;
  }

  group('tuneOpusSdp', () {
    test('SDP без fmtp у Opus → вставляет fmtp с нашими параметрами', () {
      final tuned = tuneOpusSdp(sdp());
      expect(tuned, contains('a=fmtp:111 '));
      final p = opusFmtpParams(tuned);
      expect(p['useinbandfec'], '1');
      expect(p['usedtx'], '1');
      expect(p['maxaveragebitrate'], '24000');
      expect(p['stereo'], '0');
      expect(p['sprop-stereo'], '0');
    });

    test('fmtp вставляется сразу после rtpmap Opus', () {
      final lines = tuneOpusSdp(sdp()).split(RegExp(r'\r\n|\n'));
      final rtpmapIdx = lines.indexWhere((l) => l.startsWith('a=rtpmap:111 '));
      expect(lines[rtpmapIdx + 1], startsWith('a=fmtp:111 '));
    });

    test('существующий fmtp дополняется: minptime сохранён, конфликты '
        'перезаписаны', () {
      // minptime — не-конфликтующий (сохраняем); stereo=1 — конфликт
      // (перезаписываем в 0); useinbandfec=0 — конфликт (в 1).
      final tuned = tuneOpusSdp(
        sdp(opusFmtp: 'minptime=10;stereo=1;useinbandfec=0'),
      );
      final p = opusFmtpParams(tuned);
      expect(p['minptime'], '10', reason: 'не-конфликтующий сохраняется');
      expect(p['stereo'], '0', reason: 'конфликт перезаписан');
      expect(p['useinbandfec'], '1', reason: 'конфликт перезаписан');
      expect(p['usedtx'], '1');
      expect(p['maxaveragebitrate'], '24000');
      // Ровно одна fmtp-строка для Opus (не дублируем).
      final fmtpCount = tuned
          .split(RegExp(r'\r\n|\n'))
          .where((l) => l.startsWith('a=fmtp:111 '))
          .length;
      expect(fmtpCount, 1);
    });

    test('идемпотентность: повторный вызов не меняет результат', () {
      final once = tuneOpusSdp(sdp(opusFmtp: 'minptime=10'));
      final twice = tuneOpusSdp(once);
      expect(twice, once);
    });

    test('SDP без Opus → возвращается без изменений', () {
      const noOpus =
          'v=0\r\n'
          'm=audio 9 UDP/TLS/RTP/SAVPF 0\r\n'
          'a=rtpmap:0 PCMU/8000\r\n';
      expect(tuneOpusSdp(noOpus), noOpus);
    });

    test('чужой кодек (PCMU) не тронут', () {
      final tuned = tuneOpusSdp(sdp());
      // PCMU rtpmap на месте, никакой fmtp:0 не появился.
      expect(tuned, contains('a=rtpmap:0 PCMU/8000'));
      expect(tuned, isNot(contains('a=fmtp:0 ')));
    });

    test('видео m-line не затрагивается', () {
      const withVideo =
          'v=0\r\n'
          'm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'
          'a=rtpmap:111 opus/48000/2\r\n'
          'm=video 9 UDP/TLS/RTP/SAVPF 96\r\n'
          'a=rtpmap:96 VP8/90000\r\n'
          'a=fmtp:96 max-fr=30\r\n';
      final tuned = tuneOpusSdp(withVideo);
      // Видео fmtp не изменён.
      expect(tuned, contains('a=fmtp:96 max-fr=30'));
      // Opus получил тюнинг.
      expect(opusFmtpParams(tuned)['usedtx'], '1');
    });

    test('LF-переводы строк (без CR) сохраняются', () {
      final tuned = tuneOpusSdp(sdp(eol: '\n'));
      expect(tuned.contains('\r\n'), isFalse);
      expect(opusFmtpParams(tuned)['useinbandfec'], '1');
    });
  });
}
