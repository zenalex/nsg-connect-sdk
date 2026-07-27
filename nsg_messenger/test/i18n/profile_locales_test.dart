// **TASK64**: список языков профиля — источник правды на КЛИЕНТЕ
// (TASK64.md §2: сервер валидирует формат кода, а не членство в списке).
// Список живёт в SDK, чтобы редактор имени (host-app) и редактор визитки
// (SDK) не разъезжались наборами.

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

void main() {
  test('содержит популярные локали из спеки', () {
    // §2 перечисляет их поимённо — набор не должен «усохнуть» при
    // рефакторинге.
    for (final code in ['ru', 'en', 'de', 'fr', 'es', 'it', 'pt', 'tr',
        'zh', 'ar', 'uk', 'kk']) {
      expect(kProfileLocaleNames, contains(code), reason: code);
    }
  });

  test('коды — короткие BCP-47, как ждёт серверная валидация', () {
    final re = RegExp(r'^[a-z]{2,3}$');
    for (final code in kProfileLocaleNames.keys) {
      expect(re.hasMatch(code), isTrue, reason: code);
    }
  });

  test('названия — самоназвания языков, а не перевод на русский', () {
    expect(kProfileLocaleNames['de'], 'Deutsch');
    expect(kProfileLocaleNames['zh'], '中文');
  });

  test('подпись для пикера: самоназвание + код', () {
    expect(profileLocaleLabel('de'), 'Deutsch (DE)');
  });

  test('незнакомый код не прячем — показываем как есть', () {
    // Профиль мог быть заполнен из другого клиента: скрыть язык было бы
    // хуже, чем показать голый код.
    expect(profileLocaleLabel('nl'), 'NL');
  });
}
