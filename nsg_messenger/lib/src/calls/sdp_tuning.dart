/// **TASK46 (SDK)** — тюнинг Opus в локальном SDP под плохую связь.
///
/// WebRTC по умолчанию не включает in-band FEC / DTX и может гнать
/// стерео на высоком битрейте — на мобильной сети / слабом Wi-Fi это
/// даёт заикания и потери. Дополняем `fmtp`-строку Opus-кодека
/// параметрами устойчивости к потерям и экономии полосы (моно, DTX,
/// FEC, потолок битрейта). Применяется к ЛОКАЛЬНОМУ описанию (offer и
/// answer) перед `setLocalDescription` — только наша сторона, remote SDP
/// не трогаем.
library;

/// Параметры Opus-fmtp, которыми мы перезаписываем/дополняем SDP.
/// Ключ → значение (значение как строка — так лежит в fmtp).
///
///   * `useinbandfec=1`      — in-band forward error correction (восстановление
///                             потерянных пакетов из последующих).
///   * `usedtx=1`            — discontinuous transmission (не шлём тишину →
///                             экономия полосы на паузах речи).
///   * `maxaveragebitrate`   — потолок среднего битрейта (24 кбит/с достаточно
///                             для разборчивого голоса, щадит слабый канал).
///   * `stereo=0`/`sprop-stereo=0` — моно (голос 1:1 не нуждается в стерео,
///                             половина полосы).
const Map<String, String> _opusTuning = {
  'useinbandfec': '1',
  'usedtx': '1',
  'maxaveragebitrate': '24000',
  'stereo': '0',
  'sprop-stereo': '0',
};

/// Дополнить `fmtp` Opus-кодека в [sdp] параметрами устойчивости
/// ([_opusTuning]). Чистая, идемпотентная функция:
///
///   * находит в аудио m-line `a=rtpmap:<pt> opus/...` → payload type Opus;
///   * дополняет существующую `a=fmtp:<pt> ...` нашими параметрами
///     (не-конфликтующие существующие, например `minptime`, сохраняются;
///     конфликтующие — перезаписываются нашими значениями);
///   * если `fmtp` для Opus нет — вставляет новую строку сразу после
///     `rtpmap` этого payload type;
///   * если Opus в SDP не найден — возвращает [sdp] без изменений.
///
/// Видео m-line и другие аудио-кодеки не затрагиваются. Повторный вызов
/// на уже оттюненном SDP не меняет результат (идемпотентность).
String tuneOpusSdp(String sdp) {
  // Разбиваем сохраняя стиль переводов строк (SDP канонично \r\n, но
  // flutter_webrtc иногда отдаёт \n). Определяем окончание строк по
  // первому вхождению, восстанавливаем при сборке.
  final usesCrlf = sdp.contains('\r\n');
  final eol = usesCrlf ? '\r\n' : '\n';
  final lines = sdp.split(RegExp(r'\r\n|\n'));

  // 1) Собираем payload types Opus по rtpmap (может быть несколько при
  // дублировании кодека — тюним каждый).
  final opusPayloadTypes = <String>{};
  final rtpmapRe = RegExp(r'^a=rtpmap:(\d+)\s+opus/', caseSensitive: false);
  for (final line in lines) {
    final m = rtpmapRe.firstMatch(line);
    if (m != null) opusPayloadTypes.add(m.group(1)!);
  }
  if (opusPayloadTypes.isEmpty) return sdp; // Opus нет — как есть.

  // 2) Проходим строки: дополняем существующие fmtp для Opus, помечаем
  // какие payload types уже покрыты (чтобы для остальных вставить новую).
  final covered = <String>{};
  final out = <String>[];
  final fmtpRe = RegExp(r'^a=fmtp:(\d+)\s+(.*)$');
  for (final line in lines) {
    final fm = fmtpRe.firstMatch(line);
    if (fm != null && opusPayloadTypes.contains(fm.group(1))) {
      final pt = fm.group(1)!;
      out.add('a=fmtp:$pt ${_mergeFmtpParams(fm.group(2)!)}');
      covered.add(pt);
      continue;
    }
    out.add(line);
  }

  // 3) Для Opus payload types без fmtp — вставляем новую строку сразу
  // после соответствующего rtpmap.
  final missing = opusPayloadTypes.difference(covered);
  if (missing.isNotEmpty) {
    final withInserted = <String>[];
    for (final line in out) {
      withInserted.add(line);
      final m = rtpmapRe.firstMatch(line);
      if (m != null && missing.contains(m.group(1))) {
        final pt = m.group(1)!;
        withInserted.add('a=fmtp:$pt ${_mergeFmtpParams('')}');
      }
    }
    return withInserted.join(eol);
  }

  return out.join(eol);
}

/// **TASK80 итерация 1** — потолок битрейта ВИДЕО в локальном SDP.
///
/// Зачем дублировать encoding parameters (`sender.setParameters`)
/// SDP-строкой: `setParameters` — путь через нативный плагин, и он
/// исторически «best-effort» (часть параметров платформа может молча
/// проигнорировать, а на свежедобавленном отправителе список encodings
/// иногда ещё пуст). `b=AS:`/`b=TIAS:` на видео-m-line — механизм
/// самого SDP (RFC 4566 / RFC 3890): его читает и та сторона, и наш
/// собственный кодировщик. В mesh-е промах по битрейту стоит дорого
/// (поток множится на число собеседников), поэтому держим оба ремня.
///
/// Чистая, идемпотентная функция: правит ТОЛЬКО секции `m=video`,
/// аудио и прочие m-line не трогает; если видео в SDP нет — no-op.
/// Строка `b=` вставляется сразу после `c=` (порядок полей в
/// media-секции по RFC 4566: `m=`, `i=`, `c=`, `b=`), существующая —
/// перезаписывается.
String capVideoBitrateSdp(String sdp, {required int maxKbps}) {
  if (maxKbps <= 0) return sdp;
  final usesCrlf = sdp.contains('\r\n');
  final eol = usesCrlf ? '\r\n' : '\n';
  final lines = sdp.split(RegExp(r'\r\n|\n'));
  if (!lines.any((l) => l.startsWith('m=video'))) return sdp;

  final out = <String>[];
  var inVideo = false;
  var bandwidthWritten = false;
  for (final line in lines) {
    if (line.startsWith('m=')) {
      // Новая media-секция. Если предыдущая была видео-секцией без
      // `c=` (редко, но валидно — connection-данные на уровне сессии),
      // строку `b=` всё равно надо было положить сразу после `m=`.
      inVideo = line.startsWith('m=video');
      out.add(line);
      bandwidthWritten = false;
      continue;
    }
    if (inVideo && (line.startsWith('b=AS:') || line.startsWith('b=TIAS:'))) {
      // Старый потолок выкидываем — свой поставим на месте `c=`
      // (идемпотентность: повторный вызов не плодит строк).
      continue;
    }
    out.add(line);
    if (inVideo && !bandwidthWritten && line.startsWith('c=')) {
      out.add('b=AS:$maxKbps');
      out.add('b=TIAS:${maxKbps * 1000}');
      bandwidthWritten = true;
    }
  }

  // Видео-секция без `c=` — дописываем потолок сразу после её `m=`.
  if (!out.any((l) => l.startsWith('b=AS:'))) {
    final patched = <String>[];
    for (final line in out) {
      patched.add(line);
      if (line.startsWith('m=video')) {
        patched.add('b=AS:$maxKbps');
        patched.add('b=TIAS:${maxKbps * 1000}');
      }
    }
    return patched.join(eol);
  }
  return out.join(eol);
}

/// Смержить существующую fmtp-параметр-строку [existing]
/// (`key=val;key2=val2`) с нашим тюнингом. Не-конфликтующие существующие
/// параметры сохраняются, конфликтующие перезаписываются нашими
/// значениями, наши отсутствующие — добавляются. Порядок: сначала
/// существующие (в исходном порядке, с обновлёнными значениями), затем
/// новые наши. Идемпотентно.
String _mergeFmtpParams(String existing) {
  // Разбираем существующие params в упорядоченную map (key → value).
  final params = <String, String>{};
  final order = <String>[];
  for (final raw in existing.split(';')) {
    final part = raw.trim();
    if (part.isEmpty) continue;
    final eq = part.indexOf('=');
    if (eq <= 0) {
      // Флаг без значения — сохраняем как есть (key без value).
      if (!params.containsKey(part)) order.add(part);
      params[part] = '';
      continue;
    }
    final key = part.substring(0, eq);
    final value = part.substring(eq + 1);
    if (!params.containsKey(key)) order.add(key);
    params[key] = value;
  }
  // Накладываем наш тюнинг (перезапись конфликтов + добавление новых).
  for (final entry in _opusTuning.entries) {
    if (!params.containsKey(entry.key)) order.add(entry.key);
    params[entry.key] = entry.value;
  }
  return order.map((k) => params[k]!.isEmpty ? k : '$k=${params[k]}').join(';');
}
