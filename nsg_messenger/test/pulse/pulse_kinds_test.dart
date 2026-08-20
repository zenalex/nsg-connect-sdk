/// **Словари мониторинга: клиент и сервер обязаны совпадать** (TASK94).
///
/// Это одно поле в БД (`PulseMonitor.kind`, `PulseTlsProbe.validationMode`),
/// но константы к нему объявлены дважды — в серверном пакете и здесь. Иначе
/// клиенту пришлось бы тащить серверный пакет.
///
/// Цена копии: разъехавшись, две стороны дадут монитор, который сервер
/// считает пробой, а UI рисует как heartbeat — с кнопкой «пересоздать токен»
/// у монитора, у которого токена нет. Поэтому значения ЗАКРЕПЛЕНЫ здесь
/// литералами: правка на одной стороне без правки на другой роняет тест.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

void main() {
  group('PulseMonitorKinds', () {
    test('значения совпадают с серверными строками', () {
      expect(PulseMonitorKinds.heartbeat, 'heartbeat');
      expect(PulseMonitorKinds.tlsProbe, 'tlsProbe');
    });

    test('неизвестный род пробой не считается', () {
      // Тот же дефолт, что на сервере: ошибиться в сторону heartbeat
      // безопаснее — у пробы прячутся кнопки, а не появляются лишние.
      expect(PulseMonitorKinds.isProbe(null), isFalse);
      expect(PulseMonitorKinds.isProbe(''), isFalse);
      expect(PulseMonitorKinds.isProbe('нечто'), isFalse);
      expect(PulseMonitorKinds.isProbe('tlsprobe'), isFalse);
      expect(PulseMonitorKinds.isProbe(PulseMonitorKinds.tlsProbe), isTrue);
    });
  });

  group('PulseValidationModes', () {
    test('значения совпадают с серверными строками', () {
      expect(PulseValidationModes.publicPki, 'publicPki');
      expect(PulseValidationModes.pinnedSelfSigned, 'pinnedSelfSigned');
    });
  });
}
