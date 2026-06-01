# nsg_messenger_push

Production push-token provider для NSG Connect SDK (`nsg_messenger`)
через `firebase_messaging`.

**Status:** TASK20 Chunk 3 — skeleton. Full implementation in
TASK20-Phase2 (PushRoutingService + FCM/APNs adapters).

## Зачем отдельный пакет

`nsg_messenger` core — pure-Dart, без native plugin зависимостей.
Customer которые embed-ят SDK в:
- Web-only приложение → не нужны mobile push native plugins.
- Mobile customer-app со СВОЕЙ push-pipeline → не хочет
  `firebase_messaging` import duplicated.
- Чисто backend-driven чат (без mobile) — не нуждается в push токенах.

Этот package — **opt-in**: customer добавляет в `pubspec.yaml` только
если хочет use Firebase Cloud Messaging.

## Использование (когда impl будет готов)

```yaml
# pubspec.yaml
dependencies:
  nsg_messenger:
    path: path/to/nsg_messenger
  nsg_messenger_push:
    path: path/to/nsg_messenger_push
```

```dart
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger_push/nsg_messenger_push.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NsgMessenger.init(
    apiBaseUrl: 'https://api.example.com/',
    authTokenProvider: MyAuthProvider(),
    pushTokenProvider: await FirebasePushTokenProvider.create(),
    productExternalKey: 'chatista',
  );

  runApp(MyApp());
}
```

## Status of methods (TASK20 Chunk 3)

Все методы throw `UnimplementedError('TASK20-Phase2')`. Customer
которые хотят push сейчас (до TASK20-Phase2):

1. **InMemoryPushTokenProvider** из `nsg_messenger` core — для
   тестов / static token use case.
2. **Свой `PushTokenProvider` subclass** — wrap-нуть свой
   push pipeline (vendor-specific notifications, custom FCM-конфиг
   с другим Firebase project, и т.п.).

## Когда наполнится impl

TASK20-Phase2 (TBD priority после MVP):
- `create()` — wraps `WidgetsFlutterBinding.ensureInitialized()` +
  `FirebaseMessaging.instance.requestPermission()`.
- `getCurrentToken()` — `FirebaseMessaging.instance.getToken()`.
- `tokenStream()` — `FirebaseMessaging.instance.onTokenRefresh`.
- `getDeviceInfo()` — composite через `package_info_plus` +
  `device_info_plus` + `Platform.isIOS|Android` + `kIsWeb`.

См. [TASK20.md](../../docs/tasks/TASK20.md) Phase2 для full plan.
