/// **Разрешение на уведомления — наблюдаемое состояние.**
///
/// Вторую половину вопроса «дойдёт ли тревога до этого человека» закрывает
/// `NsgNotificationChannels`: канал определяет, КАК уведомление показано.
/// Здесь — первая половина: покажут ли его вообще.
///
/// **Зачем это отдельное состояние.** Пока разрешения нет, система не
/// покажет ни одного уведомления — при том что FCM-токен выдан, а
/// регистрация устройства на сервере полностью валидна. Сервер в такой
/// связке честно рапортует «поставлено в очередь», на телефоне не
/// происходит ничего, и ни в логе, ни в ответе ручки об этом не сказано.
/// Это тот же класс молчаливого отказа, что описан в issue #86 и в §3
/// `platform/docs/TASK_TITAN_PRODUCT_PUSH01.md`, и для охранного
/// приложения он самый дорогой: «уведомление не пришло» здесь значит
/// «тревогу никто не увидел».
///
/// **Разрешение теряется двумя разными путями**, и оба сюда попадают:
///   * не выдан `POST_NOTIFICATIONS` — Android 13+, отказ в системном
///     диалоге при первом запуске;
///   * уведомления приложения выключены человеком в системных настройках —
///     это возможно на **любой** версии Android, диалога там не было
///     вовсе.
/// Для доставки они неразличимы (не придёт ничего), поэтому и состояние
/// одно — [NsgNotificationPermission.denied]. Различаются они только тем,
/// что делать дальше, и это решает [nextNotificationPermissionStep].
///
/// **Чего здесь сознательно нет.**
///   * **Своего запроса разрешения.** Его делают провайдеры токена, каждый
///     по-своему: FCM-путь — `FirebaseMessaging.requestPermission()`,
///     RuStore-путь — `requestAndroidNotificationsPermission()`. Позвать
///     отсюда третий раз значило бы показать человеку лишний системный
///     диалог.
///   * **Открытия системных настроек.** Это нативное действие, оно живёт в
///     host-app (у Chatista — `permission_handler`), как и у кнопки в
///     `PushStatusNotice`. Здесь только вердикт «туда и надо», а не переход.
///
/// **Платформа определяется через `defaultTargetPlatform`, а не
/// `Platform.isAndroid`** — в отличие от соседнего
/// `notification_channels.dart`, и это осознанная разница. Возражение,
/// записанное там («в тестах `defaultTargetPlatform` по умолчанию отвечает
/// android, и мы полезем в method channel, которого под тестом нет»), тут
/// не бьёт: отсутствующий канал даёт ровно [NsgNotificationPermission.
/// unknown] — «платформа не ответила», полноправное состояние этой модели,
/// тогда как `ensureCreated` возвращать было нечего. Взамен получаем
/// подмену платформы в тестах (`debugDefaultTargetPlatformOverride`),
/// которой `Platform.isAndroid` на Windows-хосте не даёт вовсе; тем же
/// `defaultTargetPlatform` пользуется и сам плагин в
/// `resolvePlatformSpecificImplementation`, так что проверка совпадает с
/// той, по которой он выбирает реализацию; а `dart:io` вдобавок бросает на
/// вебе.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Разрешено ли приложению показывать уведомления.
enum NsgNotificationPermission {
  /// Уведомления разрешены — со стороны разрешений доставке ничто не
  /// мешает. Это НЕ обещание, что уведомление придёт: токена может не
  /// быть (`PushTokenStatus.tokenUnavailable`), а канал — молчать.
  granted,

  /// Уведомления запрещены: не выдан `POST_NOTIFICATIONS` либо человек
  /// выключил их в системных настройках приложения. Система не покажет
  /// ничего, сколько бы валидных токенов ни было зарегистрировано.
  denied,

  /// **Вердикта нет.** Либо платформа не Android — на iOS разрешением
  /// ведает `firebase_messaging`, и его ответ уже уложен в
  /// `PushTokenStatus` провайдером, — либо платформа не ответила
  /// (плагина нет, вызов бросил).
  ///
  /// Обращаться с этим состоянием следует как с `PushTokenStatus.pending`:
  /// **UI молчит**. Показать «уведомления запрещены» тому, о ком мы просто
  /// ничего не узнали, — соврать; человек пойдёт чинить исправное, а
  /// настоящую причину молчания искать перестанет.
  ///
  /// **Ловушка при связке с `resolvePushTokenStatus`.** Тот принимает
  /// `bool permissionGranted`, и `unknown` обязан приезжать туда как
  /// `true` («ничего не мешает») — по той же договорённости, по которой
  /// `requestAndroidNotificationsPermission` отвечает `true` вне Android.
  /// Написав `permission == granted`, вы превратите «не знаем» в
  /// `PushTokenStatus.permissionDenied`, и каждому владельцу iPhone
  /// покажется карточка «приложению запрещено показывать уведомления» —
  /// при том что разрешение он выдал.
  unknown,
}

/// Что предложить человеку, чтобы уведомления заработали.
enum NsgNotificationPermissionStep {
  /// Ничего не предлагать. Либо всё в порядке, либо вердикта ещё нет.
  none,

  /// Показать системный диалог запроса разрешения — единственный путь,
  /// который человек проходит одним касанием, поэтому предпочтителен,
  /// пока доступен.
  requestSystemDialog,

  /// Отправить в системные настройки приложения — путь длиннее, но
  /// работает всегда.
  openAppSettings,
}

/// Что делать дальше — чистая функция от состояния.
///
/// Вся платформенная часть остаётся снаружи ([readAndroidNotificationsPermission]
/// и провайдеры токена), поэтому решение целиком проверяемо тестом.
///
/// [alreadyRequested] — показывали ли этому человеку системный диалог. Оба
/// провайдера запрашивают разрешение в `create()`, так что в обычном
/// сценарии он `true` к моменту, когда UI впервые о чём-то спрашивает;
/// `false` бывает у хоста, который отложил запрос до своего шага
/// онбординга (см. gating-by-onboarding-step в
/// `FirebasePushTokenProvider`).
///
/// **Почему после отказа мы ведём в настройки, а не показываем диалог
/// второй раз.** Повторный запрос система может проглотить молча: Android
/// перестаёт показывать диалог, когда разрешение отклонено окончательно, а
/// на версиях ниже 13 `POST_NOTIFICATIONS` не существует вовсе — там
/// запрос лишь сообщает текущее состояние, и никакого диалога не было с
/// самого начала. Различить эти случаи изнутри нечем: плагин отдаёт голый
/// `bool`. Кнопка, которая молча ничего не делает, — ровно тот отказ, ради
/// устранения которого написан этот файл, поэтому из [
/// NsgNotificationPermission.denied] с уже показанным диалогом ведём туда,
/// где результат гарантирован.
///
/// Обратная ошибка дешевле: если хост ещё не спрашивал, а система диалога
/// всё равно не покажет (Android ниже 13 с выключенными уведомлениями),
/// человек потратит одно касание впустую — и следующий же вызов, уже с
/// `alreadyRequested: true`, отправит его в настройки.
NsgNotificationPermissionStep nextNotificationPermissionStep({
  required NsgNotificationPermission permission,
  required bool alreadyRequested,
}) {
  switch (permission) {
    case NsgNotificationPermission.granted:
    // Молчим по той же причине, что при `PushTokenStatus.pending`:
    // предлагать починку, не зная, сломано ли, — хуже, чем не предлагать
    // ничего.
    case NsgNotificationPermission.unknown:
      return NsgNotificationPermissionStep.none;
    case NsgNotificationPermission.denied:
      return alreadyRequested
          ? NsgNotificationPermissionStep.openAppSettings
          : NsgNotificationPermissionStep.requestSystemDialog;
  }
}

/// Прочитать текущее состояние разрешения у платформы. Диалогов не
/// показывает — только спрашивает.
///
/// Отвечает на оба пути потери разрешения сразу: `areNotificationsEnabled`
/// возвращает `false` и при неотданном `POST_NOTIFICATIONS`, и при
/// выключенных в настройках уведомлениях, а второе возможно на любой
/// версии Android и никаким ответом на запрос разрешения не ловится.
///
/// **Зовите заново, а не кэшируйте.** Разрешение меняется вне приложения и
/// без его ведома: человек уходит в системные настройки и возвращается.
/// Естественная точка перечитывания — возврат приложения на передний план
/// (`AppLifecycleState.resumed`).
///
/// Вне Android — [NsgNotificationPermission.unknown]: на iOS разрешением
/// ведает `firebase_messaging`, и подменять его ответ этим было бы
/// двоевластием.
///
/// Неудача — тоже `unknown`, а не `denied`. Молчание платформы не отказ
/// человека: приняв одно за другое, мы отправили бы в системные настройки
/// того, у кого уведомления разрешены, а настоящую причину («токена нет»)
/// он бы искать перестал.
Future<NsgNotificationPermission> readAndroidNotificationsPermission() async {
  // `kIsWeb` проверяем отдельно: в браузере на Android-телефоне
  // `defaultTargetPlatform` отвечает `android`, но плагина там нет и
  // разрешения устроены иначе.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return NsgNotificationPermission.unknown;
  }
  try {
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await android?.areNotificationsEnabled();
    // `null` — плагин не ответил (реализации нет). Не `denied`: см. выше.
    if (enabled == null) return NsgNotificationPermission.unknown;
    return enabled
        ? NsgNotificationPermission.granted
        : NsgNotificationPermission.denied;
  } catch (e) {
    // Своего канала для ошибок у SDK нет; единственный потребитель этой
    // строки — тот, кто проверяет разрешения на подключённом устройстве.
    if (kDebugMode) {
      debugPrint('[NsgNotificationPermission] areNotificationsEnabled: $e');
    }
    return NsgNotificationPermission.unknown;
  }
}
