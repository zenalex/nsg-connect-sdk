import '../i18n/generated/nsg_l10n.dart';

/// **TASK55 итер.1**: человекочитаемый last seen (Telegram-стиль):
/// «только что» (<1 мин) → «N мин назад» (<60 мин) → «сегодня в HH:MM» →
/// «вчера в HH:MM» → «DD.MM.YYYY». Род нейтрализован ключами l10n
/// («был(а) в сети…»). null → null (подпись не показывается).
///
/// [now] инжектится в тестах; продовые вызовы не передают.
String? humanLastSeen(DateTime? lastActiveAt, NsgL10n l, {DateTime? now}) {
  if (lastActiveAt == null) return null;
  final n = (now ?? DateTime.now()).toLocal();
  final t = lastActiveAt.toLocal();
  final diff = n.difference(t);
  if (diff.isNegative || diff.inMinutes < 1) return l.lastSeenJustNow;
  if (diff.inMinutes < 60) return l.lastSeenMinutes(diff.inMinutes);

  String two(int v) => v.toString().padLeft(2, '0');
  final hhmm = '${two(t.hour)}:${two(t.minute)}';
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  if (day == today) return l.lastSeenToday(hhmm);
  if (day == today.subtract(const Duration(days: 1))) {
    return l.lastSeenYesterday(hhmm);
  }
  return l.lastSeenDate('${two(t.day)}.${two(t.month)}.${t.year}');
}
