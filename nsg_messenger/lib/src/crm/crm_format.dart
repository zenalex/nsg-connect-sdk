import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../i18n/generated/nsg_l10n.dart';

/// Exact decimal arithmetic preserves all server digits before formatting.
class CrmDecimal {
  const CrmDecimal(this.value, this.scale);
  final BigInt value;
  final int scale;
  static CrmDecimal? parse(String text) {
    final m = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(text);
    if (m == null) return null;
    final fraction = m[3] ?? '';
    var value = BigInt.parse('${m[2]}$fraction');
    if (m[1] == '-') value = -value;
    return CrmDecimal(value, fraction.length);
  }

  CrmDecimal operator +(CrmDecimal other) {
    final digits = math.max(scale, other.scale);
    return CrmDecimal(
      value * BigInt.from(10).pow(digits - scale) +
          other.value * BigInt.from(10).pow(digits - other.scale),
      digits,
    );
  }
}

String crmMoney(BuildContext context, String? amount, String? currency) {
  final decimal = amount == null ? null : CrmDecimal.parse(amount);
  return decimal == null
      ? '—'
      : crmMoneyDecimal(context, decimal, currency ?? 'RUB');
}

String crmMoneyDecimal(
  BuildContext context,
  CrmDecimal decimal,
  String currency,
) {
  final locale = Localizations.localeOf(context).toString();
  final standard = NumberFormat.simpleCurrency(locale: locale, name: currency);
  var digits = decimal.scale;
  var value = decimal.value.abs();
  while (digits > (standard.decimalDigits ?? 2) &&
      value % BigInt.from(10) == BigInt.zero) {
    value ~/= BigInt.from(10);
    digits--;
  }
  digits = math.max(digits, standard.decimalDigits ?? 2);
  value *= BigInt.from(10).pow(digits - math.min(decimal.scale, digits));
  final formatter = NumberFormat.currency(
    locale: locale,
    name: currency,
    symbol: standard.currencySymbol,
    decimalDigits: digits,
  );
  // Intl supplies currency placement, signs and locale separators. Keep the
  // digits as text to avoid double precision loss for large server amounts.
  final raw = value.toString().padLeft(digits + 1, '0');
  final integer = raw.substring(0, raw.length - digits);
  final grouped = integer.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => formatter.symbols.GROUP_SEP,
  );
  final number = digits == 0
      ? grouped
      : '$grouped${formatter.symbols.DECIMAL_SEP}${raw.substring(raw.length - digits)}';
  final template = formatter.format(decimal.value.isNegative ? -1 : 0);
  return template.replaceFirst(
    RegExp(decimal.value.isNegative ? r'1(?:[.,]0+)?' : r'0(?:[.,]0+)?'),
    number,
  );
}

String crmDate(
  BuildContext context,
  DateTime date, {
  DateTime? now,
  bool due = false,
}) {
  final l = NsgL10n.of(context);
  final locale = Localizations.localeOf(context).toString();
  final local = date.toLocal(), clock = (now ?? DateTime.now()).toLocal();
  final days = DateTime.utc(
    clock.year,
    clock.month,
    clock.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  if (due && date.isBefore(clock)) return l.crmOverdueDays(math.max(1, days));
  final label = days == 0
      ? l.crmToday.toLowerCase()
      : days == 1
      ? l.crmYesterday
      : DateFormat('EEE, dd.MM', locale).format(local);
  return '$label, ${DateFormat.Hm(locale).format(local)}';
}
