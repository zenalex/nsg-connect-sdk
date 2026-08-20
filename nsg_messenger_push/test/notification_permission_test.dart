// Разрешение на уведомления — наблюдаемое состояние.
//
// Проверяется тут решение, а не платформа: «что предложить человеку» —
// чистая функция, и именно она врёт дороже всего. Совет не по адресу хуже
// молчания: отправить в системные настройки того, у кого уведомления
// разрешены, значит увести его от настоящей причины молчания; предложить
// диалог, который система не покажет, значит дать кнопку, не делающую
// ничего, — тот самый молчаливый отказ, ради которого файл и написан.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger_push/nsg_messenger_push.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('что делать дальше', () {
    test('разрешено → ничего не предлагаем', () {
      for (final asked in [true, false]) {
        expect(
          nextNotificationPermissionStep(
            permission: NsgNotificationPermission.granted,
            alreadyRequested: asked,
          ),
          NsgNotificationPermissionStep.none,
          reason: 'подтверждать исправность нечем и незачем',
        );
      }
    });

    test('вердикта нет → молчим, как при PushTokenStatus.pending', () {
      for (final asked in [true, false]) {
        expect(
          nextNotificationPermissionStep(
            permission: NsgNotificationPermission.unknown,
            alreadyRequested: asked,
          ),
          NsgNotificationPermissionStep.none,
          reason:
              'мы ничего не узнали о человеке; сказать ему «уведомления '
              'запрещены» — соврать, и чинить он пойдёт исправное',
        );
      }
    });

    test('запрещено, а диалога ещё не показывали → системный диалог', () {
      // Хост, отложивший запрос до своего шага онбординга: разрешения нет,
      // но одно касание его выдаст — вести в настройки рано.
      expect(
        nextNotificationPermissionStep(
          permission: NsgNotificationPermission.denied,
          alreadyRequested: false,
        ),
        NsgNotificationPermissionStep.requestSystemDialog,
      );
    });

    test('запрещено после показанного диалога → системные настройки', () {
      expect(
        nextNotificationPermissionStep(
          permission: NsgNotificationPermission.denied,
          alreadyRequested: true,
        ),
        NsgNotificationPermissionStep.openAppSettings,
        reason:
            'повторный запрос система может проглотить молча (окончательный '
            'отказ; Android ниже 13, где POST_NOTIFICATIONS нет вовсе), а '
            'различить это изнутри нечем — плагин отдаёт голый bool',
      );
    });

    test('ответ есть на каждое состояние — ни одно не остаётся без совета', () {
      // Появится четвёртое состояние — тест упадёт здесь, а не промолчит на
      // устройстве.
      for (final permission in NsgNotificationPermission.values) {
        for (final asked in [true, false]) {
          expect(
            () => nextNotificationPermissionStep(
              permission: permission,
              alreadyRequested: asked,
            ),
            returnsNormally,
          );
        }
      }
    });

    test('в настройки ведём только с отказом на руках', () {
      // Обратное — самая дорогая ошибка этой таблицы: человек уходит
      // включать включённое и перестаёт искать настоящую причину.
      final leadsToSettings = <NsgNotificationPermission>{
        for (final permission in NsgNotificationPermission.values)
          for (final asked in [true, false])
            if (nextNotificationPermissionStep(
                  permission: permission,
                  alreadyRequested: asked,
                ) ==
                NsgNotificationPermissionStep.openAppSettings)
              permission,
      };

      expect(leadsToSettings, {NsgNotificationPermission.denied});
    });
  });

  group('чтение состояния у платформы', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('iOS → вердикта нет: там разрешением ведает firebase_messaging', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(
        readAndroidNotificationsPermission(),
        completion(NsgNotificationPermission.unknown),
        reason: 'подменять ответ firebase_messaging значило бы двоевластие',
      );
    });

    test('десктоп → вердикта нет, а не отказ', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(
        readAndroidNotificationsPermission(),
        completion(NsgNotificationPermission.unknown),
      );
    });

    test('платформа молчит (плагина под тестом нет) → unknown, не denied', () {
      // Здесь `defaultTargetPlatform` — android (умолчание flutter_test), то
      // есть код доходит до плагина, а его под тестом нет. Ответ обязан
      // быть «не знаем»: приняв молчание платформы за отказ человека, UI
      // отправил бы в системные настройки того, у кого всё разрешено.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(
        readAndroidNotificationsPermission(),
        completion(NsgNotificationPermission.unknown),
      );
    });

    test('«не знаем» ничего не советует — сквозная проверка', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(
        nextNotificationPermissionStep(
          permission: await readAndroidNotificationsPermission(),
          alreadyRequested: true,
        ),
        NsgNotificationPermissionStep.none,
      );
    });
  });
}
