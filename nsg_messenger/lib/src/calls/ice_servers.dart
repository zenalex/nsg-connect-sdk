import 'package:flutter/foundation.dart';

import '../auth_token_provider.dart' show ErrorReporter;
import 'call_rpc.dart';

/// **Отчёт в трекер: звонок остался без TURN.** Отдельный тип (а не голый
/// `error`), чтобы в GlitchTip это был СВОЙ issue с говорящим заголовком, а
/// не сливалось с общим шумом причины (напр. с
/// `MessengerNotAuthenticatedException`, которого там и так десятки).
///
/// `toString` стабилен — все такие события группируются в один issue;
/// конкретная причина уходит тегом `turn.cause` (см. [resolveIceServers]).
///
/// Жил в `call_controller.dart` (TASK46); вынесен сюда вместе с
/// [resolveIceServers] при появлении конференций (TASK51) — путь получения
/// ICE-серверов у 1:1 и mesh-пар общий.
class CallTurnUnavailableReport implements Exception {
  const CallTurnUnavailableReport();

  @override
  String toString() =>
      'CallTurn: TURN-креды не получены — звонок пойдёт STUN-only';
}

/// Список ICE-серверов для pc: TURN-креды с сервера (если есть) плюс
/// публичные STUN как fallback. Если getTurnCredentials упал —
/// gracefully деградируем на один STUN.
///
/// **Деградация обязана быть ГРОМКОЙ.** Без relay звонок за симметричным
/// NAT / в сотовой сети просто не соединится, а раньше этот путь молчал:
/// ошибка глоталась, `debugPrint` в release не выводится, в трекер не
/// уходило ничего. Итог — звонки не соединялись, а в логах устройства
/// «всё штатно» (2026-07-16: `getTurnCredentials` падал с
/// `MessengerNotAuthenticatedException`, и это не было видно НИГДЕ).
/// Поэтому: STUN-only остаётся (лучше шанс на звонок, чем отказ), но
/// факт потери TURN всегда уходит в трекер через [reporter].
Future<List<Map<String, dynamic>>> resolveIceServers(
  CallRpc rpc,
  ErrorReporter? reporter,
) async {
  final servers = <Map<String, dynamic>>[
    {
      'urls': ['stun:stun.l.google.com:19302'],
    },
  ];
  try {
    final turn = await rpc.getTurnCredentials();
    if (turn.urls.isNotEmpty) {
      servers.add({
        'urls': turn.urls,
        'username': turn.username,
        'credential': turn.credential,
      });
      return servers;
    }
    // Сервер ответил, но список пуст — TURN на нём выключен (нет
    // TURN_URLS/секрета). Для звонка это тот же STUN-only, поэтому тоже
    // репортим: молча ходить без relay нельзя.
    _reportTurnUnavailable(reporter, 'empty_urls');
  } catch (e, st) {
    _reportTurnUnavailable(reporter, '${e.runtimeType}: $e', st);
  }
  return servers;
}

/// Сообщить в трекер, что звонок пойдёт без relay. Best-effort: сам
/// репорт не должен ронять звонок.
void _reportTurnUnavailable(
  ErrorReporter? reporter,
  String cause, [
  StackTrace? st,
]) {
  if (kDebugMode) {
    debugPrint('[CallController] TURN недоступен ($cause) → STUN-only');
  }
  try {
    reporter?.reportError(
      const CallTurnUnavailableReport(),
      st,
      tags: {
        // Обрезаем: GlitchTip режет теги ~200 символов.
        'turn.cause': cause.length <= 190 ? cause : cause.substring(0, 190),
      },
    );
  } catch (_) {
    // Трекер недоступен/упал — звонку это не повод падать.
  }
}
