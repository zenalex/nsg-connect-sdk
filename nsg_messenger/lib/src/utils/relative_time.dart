import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../i18n/generated/nsg_l10n.dart';

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

// ─── TASK86: разделители дат в ленте чата ───────────────────────────────

/// **TASK86**: канонический ключ ЛОКАЛЬНОГО дня сообщения — полночь в TZ
/// пользователя. Именно по нему группируются сообщения в ленту-с-
/// разделителями и «липкая» дата.
///
/// Почему локальный, а не UTC: `ChatMessage.serverTimestamp` хранится в
/// UTC (bubble рисует его через `.toLocal()`), и сообщение, отправленное в
/// 01:00 по местному времени, для пользователя — «сегодня», а не «вчера».
/// Считать день по UTC означало бы рвать ленту не там, где пользователь
/// видит смену суток. `.toLocal()` идемпотентен для уже-локального
/// DateTime, поэтому функция безопасна и для UTC, и для local входа.
DateTime localDayKey(DateTime ts) {
  final local = ts.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// **TASK86**: тип метки разделителя — ЧИСТАЯ классификация без виджетов и
/// без локали (тестируется отдельно от текста). Локализация — в
/// [dateSeparatorLabel].
enum DateSeparatorKind {
  /// Сегодня (тот же локальный день, что `now`). Сюда же клампим будущее
  /// (clock skew client↔server — как в [formatRelativeTime]).
  today,

  /// Вчера (ровно один локальный день назад).
  yesterday,

  /// 2–6 дней назад — показываем день недели («Среда» / «Wednesday»).
  weekday,

  /// Старше недели, но тот же календарный год — «день месяц» («22 июля»).
  thisYear,

  /// Прошлые годы — «день месяц год» («22 июля 2026»).
  older,
}

/// **TASK86**: какой ТИП метки нужен для сообщения с датой [ts] на момент
/// [now]. Сравнение — по ЛОКАЛЬНОМУ дню (см. [localDayKey]).
///
/// Дельта дней считается через полночь-в-UTC (`DateTime.utc(y,m,d)`), а не
/// вычитанием local-DateTime: у local-полуночей на переходе летнего
/// времени сутки бывают 23/25 ч, и `Duration.inDays` округлил бы границу не
/// туда. UTC-сутки ровно 24 ч — дельта календарных дней получается точной,
/// при этом компоненты y/m/d берём именно локальные.
DateSeparatorKind dateSeparatorKind(DateTime ts, {DateTime? now}) {
  final tsLocal = ts.toLocal();
  final nowLocal = (now ?? DateTime.now()).toLocal();
  final tsDay = DateTime.utc(tsLocal.year, tsLocal.month, tsLocal.day);
  final nowDay = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
  final diffDays = nowDay.difference(tsDay).inDays;
  // diff <= 0 — сегодня или (clock skew) будущее: клампим к «Сегодня».
  if (diffDays <= 0) return DateSeparatorKind.today;
  if (diffDays == 1) return DateSeparatorKind.yesterday;
  if (diffDays <= 6) return DateSeparatorKind.weekday;
  if (tsLocal.year == nowLocal.year) return DateSeparatorKind.thisYear;
  return DateSeparatorKind.older;
}

/// **TASK86**: локализованная строка разделителя даты для [ts].
///
/// «Сегодня»/«Вчера» — из [l10n] (ключи `chatDateSeparatorToday`/
/// `...Yesterday`, есть в ru+en ARB). День недели/месяц/год — через
/// `DateFormat` с [locale] (intl уже инициализировал symbol-data для
/// активной локали внутри `GlobalMaterialLocalizations.load`).
///
/// Форматы (спека TASK86, ru-примеры авторитетны):
///   * день недели — полное имя, с заглавной («Среда» / «Wednesday»);
///   * этот год — `d MMMM` («22 июля» / «22 July»);
///   * старше — `d MMMM y` («22 июля 2026» / «22 July 2026»).
///
/// Почему явные паттерны `d MMMM`/`d MMMM y`, а не skeleton
/// `DateFormat.yMMMMd`: ru-skeleton добавляет суффикс « г.» («22 июля 2026
/// г.»), которого спека не хочет; явный паттерн даёт ровно ожидаемый вид и
/// держит ru/en визуально одинаковыми (день-месяц-[год]).
String dateSeparatorLabel(
  DateTime ts, {
  DateTime? now,
  required NsgL10n l10n,
  required Locale locale,
}) {
  final kind = dateSeparatorKind(ts, now: now);
  final tsLocal = ts.toLocal();
  final localeName = locale.toString();
  switch (kind) {
    case DateSeparatorKind.today:
      return l10n.chatDateSeparatorToday;
    case DateSeparatorKind.yesterday:
      return l10n.chatDateSeparatorYesterday;
    case DateSeparatorKind.weekday:
      return _capitalizeFirst(DateFormat.EEEE(localeName).format(tsLocal));
    case DateSeparatorKind.thisYear:
      return DateFormat('d MMMM', localeName).format(tsLocal);
    case DateSeparatorKind.older:
      return DateFormat('d MMMM y', localeName).format(tsLocal);
  }
}

/// Заглавная первая буква (день недели у intl.ru — строчный «среда», а
/// standalone-плашка читается лучше с заглавной «Среда»; en уже приходит
/// заглавным). Работает и для кириллицы (посимвольный `toUpperCase`).
String _capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
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
