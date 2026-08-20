/// **Строковые словари мониторинга** (TASK94) — клиентская сторона.
///
/// Значения совпадают с серверными (`PulseMonitorKind`,
/// `TlsValidationMode`): это одно поле в БД, и разъехавшись, две копии дадут
/// монитор, который сервер считает пробой, а UI рисует как heartbeat. Копия
/// здесь вынужденная — Serverpod отдаёт поле строкой, а тащить серверный
/// пакет в клиент нельзя.
///
/// Константы, а не литералы по коду: опечатка в `'tlsProbe'` не сломала бы
/// сборку, а тихо отнесла бы монитор не к тому роду.
library;

import 'dart:convert';

/// Род монитора (`PulseMonitor.kind`).
abstract final class PulseMonitorKinds {
  /// Сервис стучится сам — всё, что было до TASK94.
  static const String heartbeat = 'heartbeat';

  /// Сервер сам ходит на цель и проверяет сертификат.
  static const String tlsProbe = 'tlsProbe';

  /// Монитор-проба? Неизвестный род пробой НЕ считаем — так же, как на
  /// сервере: ошибиться в сторону heartbeat безопаснее.
  static bool isProbe(String? kind) => kind == tlsProbe;
}

/// Режим валидации сертификата (`PulseTlsProbe.validationMode`).
abstract final class PulseValidationModes {
  /// Системное доверие цепочке — публичные сертификаты.
  static const String publicPki = 'publicPki';

  /// Доверие по отпечатку — самоподписанные внутренние службы.
  static const String pinnedSelfSigned = 'pinnedSelfSigned';
}

/// **issue #116**: последние числа монитора из `lastValuesJson`.
///
/// Разбор на клиенте свой, а не общий с сервером: сервер и клиент — разные
/// пакеты, и тащить ради одной функции зависимость незачем. Правило то же —
/// только числа; строку в JSON молча превращать в число нельзя, иначе на
/// экране появится значение, которого порог не видит.
Map<String, num> decodeMonitorValues(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const {};
  try {
    final map = jsonDecode(raw);
    if (map is! Map) return const {};
    final out = <String, num>{};
    for (final e in map.entries) {
      final v = e.value;
      if (v is num) out[e.key.toString()] = v;
    }
    return out;
  } catch (_) {
    return const {};
  }
}
