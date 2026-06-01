import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Форматирует относительное время (Telegram-style: «только что», «5 минут
/// назад», «час назад»…).
///
/// Зачем обёртка вместо прямого `timeago.format`:
///
/// 1. Пакет `timeago` (≤ 3.7) в RU-локали возвращает «минуту» как для
///    `lessThanOneMinute`, так и для `aboutAMinute` — поэтому свежее
///    сообщение (1–44 сек назад) сразу показывает «минуту назад», что
///    выглядит как баг. Ожидаемое поведение Telegram/Slack — «только
///    что». Этот хелпер ловит окно «<45 сек» сам и возвращает локализо-
///    ванную строку без префикса/суффикса.
///
/// 2. Clock skew: серверный timestamp может быть слегка в будущем относи-
///    тельно клиента (NTP drift, batched send). Чистый timeago тогда
///    говорит «через 3 секунды» — некрасиво. Здесь clamp к `now`.
///
/// 3. Унифицирует поведение в MessageBubble (chat history) и
///    RoomSummaryTile (список чатов) — обе точки раньше дублировали
///    timeago-вызов с разными опциями.
///
/// [lang] — двухбуквенный код языка (`'ru'`, `'en'`, ...).
///
/// [shortEn] — формат для EN: `true` → `en_short` («now», «5m», «2h»;
/// компактно, для chat bubble), `false` → `en` («5 minutes ago»; полная
/// форма, для room list). RU использует одну (полную) форму в обоих
/// случаях — timeago RU не имеет short-варианта в пакете.
String formatRelativeTime(
  DateTime ts, {
  required String lang,
  bool shortEn = true,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  // Clamp future timestamps к now (clock skew client↔server).
  final clamped = ts.isAfter(clock) ? clock : ts;
  final diff = clock.difference(clamped);

  // «Только что» окно — < 45 сек. Совпадает с порогом, который сам
  // timeago использует для перехода на `aboutAMinute`, но мы выдаём
  // нашу локализованную строку, а не пакетную «минуту назад».
  if (diff.inSeconds < 45) {
    return _justNow(lang);
  }
  // Дальше делегируем timeago.
  final locale = lang == 'ru' ? 'ru' : (shortEn ? 'en_short' : 'en');
  return timeago.format(clamped, locale: locale, clock: clock);
}

String _justNow(String lang) {
  switch (lang) {
    case 'ru':
      return 'только что';
    default:
      return 'now';
  }
}

/// Текст с относительным временем, который **сам пересчитывается** раз
/// в [tick] (по умолчанию минута). Без него `Text(formatRelativeTime(…))`
/// замораживался бы до следующего setState от родителя (rebuilds списка
/// чата, переключение таба и т. п.) — пользователь видит «только что»
/// часами вместо ожидаемого перехода на «минуту назад» через ~45 сек.
///
/// Дёшев по ресурсам: один Timer на каждый bubble, но Timer.periodic в
/// Flutter — практически бесплатный (нет re-layout, только setState с
/// одной строки текста). Для очень больших историй (1000+ bubbles на
/// экране) можно перевести на shared ticker через `InheritedWidget`,
/// но на типичные 50-200 bubbles overhead незаметен.
class RelativeTimeText extends StatefulWidget {
  const RelativeTimeText({
    super.key,
    required this.timestamp,
    required this.lang,
    this.shortEn = true,
    this.style,
    this.tick = const Duration(minutes: 1),
  });

  final DateTime timestamp;
  final String lang;
  final bool shortEn;
  final TextStyle? style;

  /// Период пересчёта. Минута — достаточно для всех timeago-buckets
  /// (минуты/часы/дни). Меньше — оверкилл (тоже отрабатывает корректно).
  final Duration tick;

  @override
  State<RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<RelativeTimeText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(widget.tick, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant RelativeTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) {
      _ticker?.cancel();
      _ticker = Timer.periodic(widget.tick, (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = formatRelativeTime(
      widget.timestamp,
      lang: widget.lang,
      shortEn: widget.shortEn,
    );
    return Text(text, style: widget.style);
  }
}
