# nsg_messenger

Flutter SDK для встраивания мессенджера **Chatista** в продуктовые приложения, поверх платформы **NSG Connect** (Serverpod backend + Matrix homeserver).

> **Статус:** TASK11 skeleton. Публичный API зафиксирован, экраны — заглушки. Реальная имплементация — этап 2 (TASK14–TASK22).

## Host-app integration guides

Развёрнутые руководства для встраивания (host-app developer + designer):

- [Getting started](../../docs/integration/getting_started.md) — pubspec, `NsgMessenger.init`, embed widgets, `AuthTokenProvider`, опциональный push.
- [Theming](../../docs/integration/theming.md) — `NsgMessengerTheme`, `ColorScheme` / `TextTheme`, domain tokens (`NsgMessageBubbleTokens` / `NsgRoomTileTokens`), `NsgMessengerConfig`, dark mode.
- [Localization](../../docs/integration/i18n.md) — встроенные RU/EN, добавление новой локали, полный справочник ключей.

Краткая шпаргалка по подключению — ниже.

## Подключение

`pubspec.yaml`:

```yaml
dependencies:
  nsg_messenger:
    path: ../nsg-connect/sdk/nsg_messenger  # или git/version после публикации
```

## Минимальный пример

```dart
import 'package:flutter/material.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

class MyAuthProvider implements AuthTokenProvider {
  @override
  Future<MessengerAuthContext> getAuthContext() async {
    // 1. Здесь host-app убеждается, что customer accessToken актуален.
    final token = await myAuth.getValidAccessToken();
    // 2. Возвращает свежий MessengerAuthContext.
    return MessengerAuthContext(
      tenantExternalKey: 'nsg',
      productExternalKey: 'futbolista',
      identityProvider: IdentityProvider.nsg,
      externalUserId: myAuth.currentUserId,
      accessToken: token,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NsgMessenger.init(
    apiBaseUrl: 'https://nsg-connect.example.com',
    authTokenProvider: MyAuthProvider(),
    mode: MessengerMode.embeddedProduct,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('My product')),
          body: NsgMessenger.chatsListView(),
        ),
      );
}
```

## Публичный API

| Метод | Назначение |
|---|---|
| `NsgMessenger.init(...)` | Инициализация. Обязательный `AuthTokenProvider`. |
| `NsgMessenger.reauthenticate()` | После logout/login в host-app. |
| `NsgMessenger.dispose()` | Закрыть сессию. |
| `NsgMessenger.sessionStateStream()` | `MessengerSessionState`-переходы для UI. |
| `NsgMessenger.chatsListView({mode})` | Виджет списка чатов. |
| `NsgMessenger.openRoom(context, roomId)` | Открыть конкретный чат. |
| `NsgMessenger.openSupportChat(context, contextId: ...)` | Support flow. |
| `NsgMessenger.openProductRoom(context, productKey, entityType, entityId)` | TASK13. |

### `AuthTokenProvider`

SDK НЕ хранит customer accessToken. На init и при каждом refresh SDK дёргает provider, который обязан вернуть актуальный `MessengerAuthContext`. Это снимает противоречие "refresh без хранения токена" — refresh инициирует SDK, токен поставляет интегратор.

### Жизненный цикл сессии (TASK12 Chunk 3)

После `NsgMessenger.init(...)`:

1. **Cache lookup.** SDK хранит выданный backend-ом `sessionToken` в `flutter_secure_storage` (DPAPI/Keychain/Keystore) с привязкой к **fingerprint-у** identity-полей `MessengerAuthContext`-а (sha256 от `tenant|product|provider|externalUserId`, БЕЗ accessToken). Если в storage есть запись с таким же fingerprint и `expiresAt` ещё валиден (с запасом 5 мин) — переиспользуем сессию без сетевого вызова.
2. **Cache miss / mismatch / истёк.** SDK зовёт `provider.getAuthContext()` → `client.messenger.session(ctx)`. Если в storage была запись с другим fingerprint (logout/login в host-app), она сначала стирается.
3. **Proactive refresh.** За 5 мин до `expiresAt` SDK поднимает Timer, который делает `client.messenger.refresh(ctx)` (свежий ctx у provider-а). Новый токен ставится в `Client.authKeyProvider`, mirror-зеркало в storage обновляется, новый таймер ставится.
4. **Reactive refresh (401-retry).** Если backend ответит 401 на любой RPC, Serverpod-овский `MutexRefresherClientAuthKeyProvider` под капотом вызовет `refreshAuthKey(force: true)` — это тот же путь, что proactive refresh, только внеплановый. Mutex гарантирует, что параллельные RPC ждут одного refresh.
5. **Failure modes.** `InvalidTokenException` от backend-а или `MessengerNotAuthenticatedException` → `state.expired` (host-app должен показать login). Сетевые ошибки / 5xx → `state.error` без потери текущей сессии (host-app может вызвать `reauthenticate()` или просто подождать восстановления сети).

**Известное ограничение (TASK17 закрывает):** при refresh обновляется только токен в `authKeyProvider`. Уже-открытые WebSocket-стримы (`roomStream`, `userEventStream`) остаются на старом auth-handshake до тех пор, пока сервер их не закроет (Serverpod 3.4.7 не разрывает существующие подключения при смене auth-key). На TASK12 host-app сам зовёт `client.messenger.roomStream(...)` — если стрим отвалится, host-app переподписывается. На TASK17 SDK даст stream-обёртки с auto-reconnect on refresh.

### Тестирование

Для widget/integration-тестов host-app может подменить `flutter_secure_storage` на in-memory store без MethodChannel-моков:

```dart
await NsgMessenger.init(
  apiBaseUrl: 'http://localhost:5568',
  authTokenProvider: FakeAuthProvider(),
  // ignore: invalid_use_of_visible_for_testing_member
  tokenStoreOverride: InMemoryAuthTokenStore(),
);
```

### `ErrorReporter` (опционально)

```dart
await NsgMessenger.init(
  ...,
  errorReporter: SentryErrorReporter(dsn: '...'),
);
```

SDK проксирует свои внутренние ошибки в `errorReporter.reportError(...)`. Если не передать — ошибки уходят в `debugPrint`. Реализация `SentryErrorReporter` — на стороне host-app или в дочернем пакете `nsg_messenger_sentry` (не входит в TASK11).

## Архитектурные решения

- **`messengerUserId` скрыт от host-app.** Серверные RPC (Serverpod) пока требуют его явно как параметр; SDK подставляет внутри `MessengerRuntime`. На TASK12 server-side derive из аутентифицированной session уберёт нужность пробрасывать его, и публичный API SDK не изменится.
- **Singleton `MessengerRuntime`.** Один tenant в одном приложении одновременно. Multi-tenant — не входит в MVP.
- **Нет внешнего state-management в публичном API.** Внутри SDK можем использовать любой подход; host-app не обязан Riverpod / Bloc / Provider.
- **Без обязательного `MaterialApp` в SDK.** Темы наследуются от родительского `Theme.of(context)`; `NsgMessengerTheme` — точечные оверрайды.

## Что вынесено в отдельные TASK

| Возможность | TASK |
|---|---|
| Реальный список чатов | TASK14 |
| Экран чата (история, типы сообщений, threads UI) | TASK15 / TASK37 |
| Отправка / optimistic update / drafts | TASK16 |
| Realtime sync на стороне SDK | TASK17 |
| Unread / read receipts | TASK18 |
| Вложения (изображения, файлы) | TASK19 |
| Push-уведомления + deep link | TASK20 / TASK21 |
| i18n (RU/EN), темизация, white-label | TASK22 |
| Mute / archive / search / product filter | TASK42 |
| Server-side auth integration (без явного messengerUserId) | TASK12 |
| Полная спецификация AuthTokenProvider + refresh-цикл | TASK12 |

## Версии

- Flutter: 3.41.6 (см. `.fvmrc` корня)
- Dart: 3.11.4
- Serverpod: 3.4.7

## Лицензия

См. корневой [`LICENSE.md`](../../LICENSE.md). Сейчас TBD; стратегия распространения SDK — §22 ТЗ.
