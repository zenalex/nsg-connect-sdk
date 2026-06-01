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

export 'src/firebase_push_token_provider.dart'
    show FirebasePushTokenProvider, nsgMessengerBackgroundHandler;
