// Этап 3 TASK_TITAN_PRODUCT_PUSH01 §4.1 — каналы уведомлений Android.
//
// Проверяется тут ровно то, что иначе никак себя не проявит. Расхождение
// идентификатора канала с серверным — тихий отказ: Firebase на незнакомое
// имя молча подставляет канал из манифеста, тревога приходит обычным
// уведомлением, и ни лог, ни ответ ручки об этом не скажут. Поэтому
// главный тест здесь читает СЕРВЕРНЫЙ файл, а не повторяет строки за ним:
// повтор разошёлся бы вместе с оригиналом и промолчал бы точно так же.

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger_push/nsg_messenger_push.dart';

/// Серверная половина набора — единственный источник правды для строк.
const String _serverChannelFile =
    '../../server/nsg_connect/nsg_connect_server/lib/src/push/'
    'notification_channel.dart';

/// Вытащить значения `static const String <имя> = '<строка>';`.
Map<String, String> _parseServerConstants(String source) {
  final re = RegExp(
    r"static\s+const\s+String\s+(\w+)\s*=\s*'([^']*)'\s*;",
    multiLine: true,
  );
  return <String, String>{
    for (final m in re.allMatches(source)) m.group(1)!: m.group(2)!,
  };
}

void main() {
  group('идентификаторы совпадают с серверными дословно', () {
    late Map<String, String> serverConstants;

    setUpAll(() {
      final file = File(_serverChannelFile);
      // Не skip: пропущенная проверка тут неотличима от пройденной, а
      // цена ошибки — тихо онемевшая тревога.
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'не найден $_serverChannelFile — этот тест сверяет клиентские '
            'идентификаторы каналов с серверным закрытым набором; если файл '
            'переехал, поправьте путь, а не выкидывайте сверку',
      );
      serverConstants = _parseServerConstants(file.readAsStringSync());
    });

    test('канал тревог', () {
      expect(
        NsgNotificationChannels.alarms,
        serverConstants['alarms'],
        reason:
            'сервер кладёт этот идентификатор в '
            'android.notification.channel_id; расхождение в один символ = '
            'тревога приезжает обычным уведомлением, без единой ошибки',
      );
    });

    test('канал рядовых уведомлений', () {
      expect(NsgNotificationChannels.general, serverConstants['general']);
    });

    test('набор закрыт с обеих сторон — ни больше, ни меньше', () {
      expect(NsgNotificationChannels.known, {'nsg_alarms', 'nsg_general'});
      expect(
        NsgNotificationChannels.known,
        {serverConstants['alarms'], serverConstants['general']},
        reason:
            'появился третий канал на одной стороне — вторая о нём не знает',
      );
    });
  });

  group('свойства каналов', () {
    test('тревоги — IMPORTANCE_HIGH: всплытие поверх экрана и звук', () {
      final channel = NsgNotificationChannels.alarmsChannel();

      expect(channel.id, NsgNotificationChannels.alarms);
      expect(
        channel.importance,
        Importance.high,
        reason:
            'важность — свойство канала, и серверный priority=high её не '
            'заменяет: он про срочность доставки, а не про показ',
      );
      expect(channel.importance.value, 4, reason: 'IMPORTANCE_HIGH');
      expect(channel.playSound, isTrue);
      expect(channel.enableVibration, isTrue);
    });

    test('рядовые уведомления — обычная важность, БЕЗ всплытия', () {
      final channel = NsgNotificationChannels.generalChannel();

      expect(channel.id, NsgNotificationChannels.general);
      expect(
        channel.importance,
        Importance.defaultImportance,
        reason:
            'подними её до high — статусы объектов начнут перекрывать '
            'экран, человек выключит категорию, и разделение на два канала '
            'потеряет смысл',
      );
      expect(channel.importance.value, 3);
    });

    test('каналы различаются важностью, а не только именем', () {
      // Копипаста одного канала в другой — самая дешёвая ошибка здесь и
      // самая незаметная: имена разные, поведение одно.
      expect(
        NsgNotificationChannels.alarmsChannel().importance,
        isNot(NsgNotificationChannels.generalChannel().importance),
      );
    });

    test('обход «Не беспокоить» не выставляем — это решение пользователя', () {
      // §6.7 ТЗ: гарантировать обход серверными полями нельзя, и обещать
      // его Титану мы не будем. Выставленный тут флаг был бы таким
      // обещанием — молча не сработавшим без доступа к политике.
      expect(NsgNotificationChannels.alarmsChannel().bypassDnd, isFalse);
      expect(NsgNotificationChannels.generalChannel().bypassDnd, isFalse);
    });

    test('свой звук не задан — берётся системный', () {
      // Звук канала — ресурс res/raw/… у host-app. Указанный «на будущее»
      // несуществующий ресурс дал бы канал с битым URI, то есть навсегда
      // молчащий, и починить его было бы уже нельзя.
      expect(NsgNotificationChannels.alarmsChannel().sound, isNull);
    });

    test('подписи переопределяются host-приложением (смена языка)', () {
      final channel = NsgNotificationChannels.alarmsChannel(
        name: 'Alarms',
        description: 'Urgent notifications.',
      );

      expect(channel.name, 'Alarms');
      expect(channel.description, 'Urgent notifications.');
      expect(
        channel.id,
        NsgNotificationChannels.alarms,
        reason: 'id не трогаем',
      );
    });
  });

  group('вне Android', () {
    test('ensureCreated — no-op, а не исключение', () async {
      // Тесты идут на десктопе, плагина под ним нет. Пакет линкуется и в
      // web-хосты, где каналов не существует как понятия: падение здесь
      // уронило бы инициализацию пушей целиком.
      await expectLater(NsgNotificationChannels.ensureCreated(), completes);
    });

    test('запрос разрешения отвечает «ничего не мешает»', () async {
      expect(await requestAndroidNotificationsPermission(), isTrue);
    });
  });
}
