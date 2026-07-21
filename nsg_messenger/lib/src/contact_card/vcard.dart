import 'dart:convert';
import 'dart:typed_data';

import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:share_plus/share_plus.dart';

/// **TASK52 итер.2**: экспорт визитки в vCard.
///
/// Формат — **vCard 3.0** (не 4.0): максимально совместим с адресными
/// книгами телефонов (iOS Contacts / Google Contacts стабильно импортируют
/// именно 3.0). Пустые поля опускаются; значения экранируются по RFC 6350
/// §3.4. Экспорт всегда работает с ПОЛНОЙ [ContactCardInfo] (из
/// `contactCards.get`), а не с preview-моделью редактора.
class ContactVCard {
  const ContactVCard._();

  /// Собрать vCard 3.0 из [card].
  static String build(ContactCardInfo card) {
    final fn = (card.displayName ?? '').trim();
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${_esc(fn.isEmpty ? 'Chatista' : fn)}',
    ];
    if (fn.isNotEmpty) lines.add('N:${_esc(fn)};;;;');
    _add(lines, 'TITLE', card.jobTitle);
    _add(lines, 'ORG', card.company);
    _add(lines, 'TEL;TYPE=CELL', card.phone);
    _add(lines, 'EMAIL;TYPE=INTERNET', card.email);
    _add(lines, 'URL', card.website);
    _add(lines, 'NOTE', card.about);
    lines.add('END:VCARD');
    return lines.join('\r\n');
  }

  static void _add(List<String> lines, String prop, String? value) {
    final v = value?.trim();
    if (v != null && v.isNotEmpty) lines.add('$prop:${_esc(v)}');
  }

  /// Экранирование значения vCard (RFC 6350 §3.4): `\ , ;` и переводы строк.
  static String _esc(String v) => v
      .replaceAll('\\', r'\\')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\n');

  /// Безопасное имя .vcf-файла из имени контакта. Убираем только
  /// файлово-небезопасные символы (`\ / : * ? " < > |` + пробелы),
  /// сохраняя кириллицу/юникод (allowlist `\w` вырезал бы её).
  static String fileName(ContactCardInfo card) {
    final base = (card.displayName ?? 'contact').trim();
    final safe = base.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    return '${safe.isEmpty ? 'contact' : safe}.vcf';
  }

  /// Поделиться [card] как `.vcf` через системный share sheet.
  static Future<void> share(ContactCardInfo card, {String? subject}) async {
    final bytes = Uint8List.fromList(utf8.encode(build(card)));
    final file = XFile.fromData(
      bytes,
      mimeType: 'text/vcard',
      name: fileName(card),
    );
    await SharePlus.instance.share(
      ShareParams(files: [file], subject: subject),
    );
  }
}
