import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/contact_card/vcard.dart';
import 'package:flutter_test/flutter_test.dart';

/// **TASK52 итер.2**: сборка vCard 3.0 из визитки.
ContactCardInfo card({
  String? name = 'Иван Петров',
  String? about,
  String? job,
  String? company,
  String? phone,
  String? email,
  String? website,
}) => ContactCardInfo(
  ownerMessengerUserId: 1,
  displayName: name,
  template: 'gradient',
  about: about,
  jobTitle: job,
  company: company,
  phone: phone,
  email: email,
  website: website,
  hasHiddenFields: false,
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('ContactVCard.build', () {
    test('минимальная визитка: BEGIN/VERSION/FN/END + N', () {
      final v = ContactVCard.build(card());
      expect(v, startsWith('BEGIN:VCARD\r\nVERSION:3.0\r\n'));
      expect(v, contains('FN:Иван Петров'));
      expect(v, contains('N:Иван Петров;;;;'));
      expect(v.trimRight(), endsWith('END:VCARD'));
    });

    test('все поля мапятся в правильные property', () {
      final v = ContactVCard.build(
        card(
          about: 'Сантехник',
          job: 'Мастер',
          company: 'ООО Ромашка',
          phone: '+79001234567',
          email: 'ivan@example.com',
          website: 'https://ivan.ru',
        ),
      );
      expect(v, contains('TITLE:Мастер'));
      expect(v, contains('ORG:ООО Ромашка'));
      expect(v, contains('TEL;TYPE=CELL:+79001234567'));
      expect(v, contains('EMAIL;TYPE=INTERNET:ivan@example.com'));
      expect(v, contains('URL:https://ivan.ru'));
      expect(v, contains('NOTE:Сантехник'));
    });

    test('пустые поля опускаются', () {
      final v = ContactVCard.build(card());
      expect(v, isNot(contains('TITLE:')));
      expect(v, isNot(contains('TEL')));
      expect(v, isNot(contains('EMAIL')));
      expect(v, isNot(contains('NOTE')));
    });

    test('экранирование спецсимволов (запятая/точка-с-запятой/перенос)', () {
      final v = ContactVCard.build(
        card(name: 'Ко, Инк; Ltd', about: 'строка1\nстрока2'),
      );
      expect(v, contains(r'FN:Ко\, Инк\; Ltd'));
      expect(v, contains(r'NOTE:строка1\nстрока2'));
    });

    test('пустое имя → FN fallback Chatista, N опускается', () {
      final v = ContactVCard.build(card(name: null));
      expect(v, contains('FN:Chatista'));
      expect(v, isNot(contains('\nN:')));
    });

    test('fileName безопасен', () {
      expect(ContactVCard.fileName(card(name: 'Иван Петров')), 'Иван_Петров.vcf');
      expect(ContactVCard.fileName(card(name: 'a/b:c*d')), 'a_b_c_d.vcf');
    });
  });
}
