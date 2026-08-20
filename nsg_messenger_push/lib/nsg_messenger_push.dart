/// Production push token provider для NSG Connect SDK через
/// `firebase_messaging` (TASK20-Phase2 Chunk 5 — variant (a)
/// FCM-iOS-wrapper).
///
/// **Использование**:
/// ```dart
/// import 'package:firebase_core/firebase_core.dart';
/// import 'package:firebase_messaging/firebase_messaging.dart';
/// import 'package:nsg_messenger/nsg_messenger.dart';
/// import 'package:nsg_messenger_push/nsg_messenger_push.dart';
///
/// void main() async {
///   await Firebase.initializeApp(); // host-app supplies options
///   FirebaseMessaging.onBackgroundMessage(nsgMessengerBackgroundHandler);
///   await NsgMessenger.init(
///     apiBaseUrl: '...',
///     authTokenProvider: ...,
///     pushTokenProvider: await FirebasePushTokenProvider.create(),
///     productExternalKey: 'chatista',
///   );
///   runApp(...);
/// }
/// ```
///
/// Отдельный pub package, чтобы pure-Dart `nsg_messenger` core не
/// тащил native plugin (`firebase_messaging`). Customer-app в
/// embed-mode без push не depend-ит от этого package.
library;

export 'src/call_push.dart' show CallPushData;
export 'src/call_push_presenter.dart' show CallPushPresenter;
export 'src/firebase_push_token_provider.dart'
    show FirebasePushTokenProvider, nsgMessengerBackgroundHandler;
// **Этап 3 TASK_TITAN_PRODUCT_PUSH01 §4.1**: каналы уведомлений Android.
// Заводятся при инициализации обоих провайдеров; наружу отданы, чтобы
// host-app мог переименовать категории под свой язык и провести
// отрицательное свидетельство §6.8.
export 'src/notification_channels.dart'
    show NsgNotificationChannels, requestAndroidNotificationsPermission;
// Разрешение на уведомления как наблюдаемое состояние — рядом с каналами
// намеренно: канал отвечает, КАК уведомление показано, разрешение —
// покажут ли его вообще. Без второго первое ничего не гарантирует:
// запрещённые уведомления не спасёт и самый громкий канал, а токен при
// этом выдан и регистрация на сервере валидна.
export 'src/notification_permission.dart'
    show
        NsgNotificationPermission,
        NsgNotificationPermissionStep,
        nextNotificationPermissionStep,
        readAndroidNotificationsPermission;
// TASK61: RuStore Push (Android без Google Play Services) + выбор
// провайдера на старте (GMS → fcm, иначе RuStore).
export 'src/push_provider_resolver.dart'
    show ResolvedPushService, resolvePushService;
// **Issue #86**: общий для провайдеров перевод «что удалось получить» в
// «почему уведомление не придёт».
export 'src/push_status_resolver.dart' show resolvePushTokenStatus;
// Issue #33 (TASK67 часть B): тихий read-sync-пуш — снятие уведомлений
// прочитанной комнаты на устройствах вне realtime-стрима.
export 'src/read_sync_push.dart' show ReadSyncPushData, readSyncPushType;
export 'src/rustore_push_token_provider.dart' show RuStorePushTokenProvider;
