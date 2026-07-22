import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import 'call_push.dart';

/// **TASK46 (звонки в фоне)**: показ нативного полноэкранного входящего
/// звонка из call-push через `flutter_callkit_incoming`.
///
/// На Android плагин рисует full-screen-intent нотификацию + foreground-
/// service (звонит даже когда приложение убито). На iOS — CallKit (но там
/// нужен PushKit VoIP-push, не FCM — см. `docs/ios-voip-scaffold.md`).
///
/// **Self-contained** — не зависит от app-синглтонов (`NsgMessenger`,
/// `MessengerRuntime`): вызывается в том числе из FCM background isolate,
/// где app-состояния нет. Всё нужное берётся из [CallPushData] (callId,
/// имя звонящего), а корреляция с живым `m.call.invite` делается в
/// host-app при accept (по callId из `extra`).
class CallPushPresenter {
  const CallPushPresenter._();

  /// Notification-channel (Android 8+) для входящих звонков. Отдельный от
  /// message-канала — с высокой важностью и full-screen-intent.
  static const String androidChannelName = 'Входящие звонки';

  /// **TASK51 чанк 4**: заголовок входящего для группового звонка. Звонит
  /// не человек, а комната, поэтому имя одного из участников на экране
  /// вводило бы в заблуждение.
  static const String conferenceTitle = 'Групповой звонок';

  /// Окно защиты от повторного показа ОДНОГО И ТОГО ЖЕ CallKit-id.
  /// Совпадает с `duration` входящего (60с): пока «входящий» на экране,
  /// второй show — всегда дубль.
  static const Duration duplicateShowWindow = Duration(seconds: 60);

  /// Последний показанный CallKit-id и когда (см. [shouldSkipDuplicateShow]).
  static String? _lastShownId;
  static DateTime? _lastShownAt;

  /// **Гард от повторного «входящего»** — чистая логика (без плагина).
  ///
  /// Сервер уже дедуплицирует побудки конференции по (confId, получатель),
  /// но это ВТОРОЙ рубеж — на случай доставки в обход него (ретрай FCM,
  /// побудка от другого инстанса, окно дедупа истекло на границе). Плагин
  /// `flutter_callkit_incoming` идемпотентным по id НЕ является: на Android
  /// повторный `showCallkitIncoming` заново заводит рингтон и
  /// full-screen-intent, то есть звонит второй раз.
  ///
  /// Best-effort: состояние статическое, а показ происходит в FCM
  /// background isolate — при его пересоздании гард обнуляется. Главный
  /// механизм схлопывания — общий [CallPushData.callKitId], этот лишь
  /// гасит хвосты.
  @visibleForTesting
  static bool shouldSkipDuplicateShow({
    required String callKitId,
    required String? lastShownId,
    required DateTime? lastShownAt,
    required DateTime now,
    Duration window = duplicateShowWindow,
  }) {
    if (lastShownId == null || lastShownAt == null) return false;
    if (lastShownId != callKitId) return false;
    return now.difference(lastShownAt) < window;
  }

  /// **Tests only**: сбросить гард повторного показа.
  @visibleForTesting
  static void resetDuplicateShowGuard() {
    _lastShownId = null;
    _lastShownAt = null;
  }

  /// Показать полноэкранный входящий звонок для данного [data].
  ///
  /// Id CallKit-сессии — [CallPushData.callKitId]:
  ///   * 1:1 — сам callId (тот же, что придёт в `m.call.invite`), поэтому
  ///     host-app закрывает UI (`endCall`) и матчит accept с
  ///     `CallController`;
  ///   * **TASK51 чанк 4**: конференция — id, посчитанный из confId, ОДИН
  ///     на всю конференцию. Пачка pairwise-побудок схлопывается в один
  ///     «входящий» вместо N штук (на iOS каждая побудка ОБЯЗАНА
  ///     отрепортить звонок в CallKit — иначе система убьёт приложение, —
  ///     так что «просто не показывать лишние» там не вариант).
  static Future<void> showIncoming(CallPushData data) async {
    final callKitId = data.callKitId;
    final now = DateTime.now();
    if (shouldSkipDuplicateShow(
      callKitId: callKitId,
      lastShownId: _lastShownId,
      lastShownAt: _lastShownAt,
      now: now,
    )) {
      if (kDebugMode) {
        debugPrint('[CallPushPresenter] повторный show $callKitId — пропуск');
      }
      return;
    }
    _lastShownId = callKitId;
    _lastShownAt = now;

    final isConf = data.isConference;
    // Групповой: «Групповой звонок · Команда». Одной строкой, потому что
    // на Android при `isShowCallID: false` виден только nameCaller.
    final nameCaller = isConf
        ? (data.roomName.isNotEmpty
              ? '$conferenceTitle · ${data.roomName}'
              : conferenceTitle)
        : (data.callerName.isNotEmpty ? data.callerName : 'Входящий');
    final handle = isConf
        ? (data.roomName.isNotEmpty ? data.roomName : conferenceTitle)
        : data.callerName;

    final params = CallKitParams(
      id: callKitId,
      nameCaller: nameCaller,
      appName: 'Chatista',
      handle: handle,
      // 0 — аудио-звонок (голосовой 1:1, video пока нет).
      type: 0,
      textAccept: 'Ответить',
      textDecline: 'Отклонить',
      // Держим UI до 60с — совпадает с invite-lifetime CallController-а;
      // дальше система сама снимет нотификацию (missed).
      missedCallNotification: NotificationParams(
        showNotification: true,
        subtitle: isConf ? 'Пропущенный групповой звонок' : 'Пропущенный звонок',
      ),
      duration: 60000,
      // Прокидываем контекст в extra — host-app восстановит из
      // CallEvent.body при accept/decline (корреляция по callId, а для
      // конференции — по confId: callId у каждой пары свой).
      extra: <String, dynamic>{
        'callId': data.callId,
        'roomId': data.roomId.toString(),
        'matrixRoomId': data.matrixRoomId,
        'callerId': data.callerId.toString(),
        'callerName': data.callerName,
        if (data.roomName.isNotEmpty) 'roomName': data.roomName,
        if (isConf) ...<String, dynamic>{
          'callKind': 'conference',
          'confId': data.confId,
          'callKitId': callKitId,
        },
      },
      android: const AndroidParams(
        // false → стандартная call-нотификация с явными кнопками
        // «Ответить»/«Отклонить», которые СРАЗУ принимают/отклоняют звонок
        // (один тап). При isCustomNotification:true кастомный heads-up на
        // части устройств принимал только по кнопке, а тап по телу открывал
        // второй экран (жалоба «дважды поднять трубку»). См. плагин
        // CallkitNotificationManager: accept-action → getAcceptPendingIntent
        // (direct), а тело нотификации → getActivityPendingIntent (второй
        // экран). Стандартные action-кнопки виднее в heads-up.
        isCustomNotification: false,
        isShowLogo: false,
        // Высокий приоритет → heads-up поверх экрана; на локскрине —
        // полноэкранный входящий (full-screen-intent).
        isImportant: true,
        isShowCallID: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0E0B08',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: androidChannelName,
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: false,
        // audioSessionMode/Active/... остаются дефолтными — реальная
        // iOS-интеграция (PushKit) не завершена, см. docs-скаффолд.
      ),
    );
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallPushPresenter] showCallkitIncoming failed: $e');
      }
    }
  }

  /// Снять входящий/активный CallKit-UI по [callId] (для конференции —
  /// по её [CallPushData.callKitId]). Best-effort — вызывается когда
  /// звонок завершился/соединился (host-app хук на `CallController` /
  /// `ConferenceCallController`) или при foreground-дедупликации.
  static Future<void> end(String callId) async {
    // «Входящего» больше нет — снимаем и гард, иначе повторный звонок с тем
    // же id (перезаход в ту же конференцию) молча не показался бы.
    if (_lastShownId == callId) {
      _lastShownId = null;
      _lastShownAt = null;
    }
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      if (kDebugMode) debugPrint('[CallPushPresenter] endCall failed: $e');
    }
  }

  /// Снять все CallKit-сессии (teardown / logout).
  static Future<void> endAll() async {
    _lastShownId = null;
    _lastShownAt = null;
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      if (kDebugMode) debugPrint('[CallPushPresenter] endAllCalls failed: $e');
    }
  }
}
