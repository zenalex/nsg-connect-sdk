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

  /// Показать полноэкранный входящий звонок для данного [data].
  ///
  /// [callId] используется как id CallKit-сессии — тот же, что придёт в
  /// `m.call.invite`, поэтому host-app сможет закрыть UI (`endCall`) и
  /// сматчить accept с `CallController`. Idempotent на уровне плагина:
  /// повторный show с тем же id обновляет существующую сессию.
  static Future<void> showIncoming(CallPushData data) async {
    final params = CallKitParams(
      id: data.callId,
      nameCaller: data.callerName.isNotEmpty ? data.callerName : 'Входящий',
      appName: 'Chatista',
      handle: data.callerName,
      // 0 — аудио-звонок (голосовой 1:1, video пока нет).
      type: 0,
      textAccept: 'Ответить',
      textDecline: 'Отклонить',
      // Держим UI до 60с — совпадает с invite-lifetime CallController-а;
      // дальше система сама снимет нотификацию (missed).
      missedCallNotification: const NotificationParams(
        showNotification: true,
        subtitle: 'Пропущенный звонок',
      ),
      duration: 60000,
      // Прокидываем контекст в extra — host-app восстановит из
      // CallEvent.body при accept/decline (корреляция по callId).
      extra: <String, dynamic>{
        'callId': data.callId,
        'roomId': data.roomId.toString(),
        'matrixRoomId': data.matrixRoomId,
        'callerId': data.callerId.toString(),
        'callerName': data.callerName,
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

  /// Снять входящий/активный CallKit-UI по [callId]. Best-effort —
  /// вызывается когда звонок завершился/соединился (host-app хук на
  /// `CallController`) или при foreground-дедупликации.
  static Future<void> end(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      if (kDebugMode) debugPrint('[CallPushPresenter] endCall failed: $e');
    }
  }

  /// Снять все CallKit-сессии (teardown / logout).
  static Future<void> endAll() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      if (kDebugMode) debugPrint('[CallPushPresenter] endAllCalls failed: $e');
    }
  }
}
