# Getting started

Host-app integration walkthrough for `nsg_messenger`.

## Overview

`nsg_messenger` is a Flutter SDK that embeds a fully functional Matrix-based chat (Chatista platform) into a host product app. The SDK ships chat widgets (`chatsListView`, room screens, message composer, attachments, push, l10n) backed by a Serverpod API + Matrix Synapse homeserver — host apps drop these widgets into their own `Scaffold` instead of writing chat UI from scratch.

The SDK is **opt-in for visual customization**: by default it inherits `Theme.of(context)` from the host's `MaterialApp.theme` and uses domain-specific fallback tokens. Pass `NsgMessengerTheme` to override per-product branding without rebuilding widgets — see [theming.md](theming.md).

## Add the package

External integrators consume the SDK from the public distribution repo
[`nsg-connect-sdk`](https://github.com/zenalex/nsg-connect-sdk) as a git
dependency — no access to the platform monorepo required:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Required: SDK core.
  nsg_messenger:
    git:
      url: https://github.com/zenalex/nsg-connect-sdk.git
      path: nsg_messenger

  # Optional: Firebase push provider (only if you want FCM/APNs push).
  nsg_messenger_push:
    git:
      url: https://github.com/zenalex/nsg-connect-sdk.git
      path: nsg_messenger_push

  # Required transitively for l10n delegates (the SDK re-exports the
  # delegate via `NsgL10n.localizationsDelegates`).
  flutter_localizations:
    sdk: flutter
```

Pin a tag via `ref:` for reproducible builds once release tags exist;
until then the default branch is the release channel.

Inside the platform monorepo, host apps use path dependencies instead
(`path: ../nsg_messanger/sdk/nsg_messenger` relative to your pubspec).

## Initialize at startup

Call `NsgMessenger.init(...)` exactly once, before any SDK widget is rendered (typically in `main()`).

```dart
import 'package:flutter/material.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NsgMessenger.init(
    // Required.
    apiBaseUrl: 'https://nsg-connect.example.com',
    authTokenProvider: MyAuthProvider(),

    // Optional — visual override. Without it the SDK reads
    // Theme.of(context) from your MaterialApp.theme.
    theme: const NsgMessengerTheme(/* see theming.md */),

    // Optional — locale preference. Without it the system locale
    // resolves (falls back to ru). See i18n.md.
    locale: null,

    // Optional — embedded inside one product (default) vs standalone
    // Chatista-style app. See MessengerMode enum.
    mode: MessengerMode.embeddedProduct,

    // Optional — your Sentry / Crashlytics adapter. SDK proxies its
    // internal errors here. Without it errors go to debugPrint.
    errorReporter: null,

    // Optional — Firebase push provider. Without it push registration
    // is skipped (still works in foreground via WebSocket stream).
    pushTokenProvider: null,

    // Optional — externalKey of the product this app embeds (for
    // server-side product-scoping). Required when running in
    // embeddedProduct mode against a multi-product tenant.
    productExternalKey: 'futbolista',

    // Optional — behavior knobs (scroll thresholds etc). See theming.md.
    config: const NsgMessengerConfig(),
  );

  runApp(const MyApp());
}
```

Notes:
- `init()` is idempotent per-process — call once. To switch users / tenants after logout call `NsgMessenger.reauthenticate()` (re-asks your `AuthTokenProvider` for a fresh context) or `NsgMessenger.dispose()` + `init()` again.
- The SDK does NOT call `WidgetsFlutterBinding.ensureInitialized()` for you; your `main()` must do it.

## Implement `AuthTokenProvider`

The SDK never stores the customer access token. On every refresh it asks your provider for a fresh `MessengerAuthContext`. You're responsible for keeping the access token valid (refresh against your own auth backend) and producing the context.

Minimal in-memory example:

```dart
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

class MyAuthProvider implements AuthTokenProvider {
  MyAuthProvider({required this.session});

  final MyAppSession session;  // your app's auth state.

  @override
  Future<MessengerAuthContext> getAuthContext() async {
    // 1. Refresh the customer accessToken if it's about to expire.
    final accessToken = await session.getValidAccessToken();

    // 2. Build a MessengerAuthContext. tenantExternalKey +
    //    productExternalKey + identityProvider + externalUserId
    //    together identify the messenger user on the NSG backend.
    return MessengerAuthContext(
      tenantExternalKey: 'futbolista',  // your tenant key, issued by NSG.
      productExternalKey: 'futbolista',
      identityProvider: IdentityProvider.nsg,
      externalUserId: session.currentUserId,
      accessToken: accessToken,
    );
  }
}
```

Persisted variant (production) wraps `flutter_secure_storage` so the access token survives app restart:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAuthProvider implements AuthTokenProvider {
  SecureAuthProvider(this._storage, this._refresher);

  final FlutterSecureStorage _storage;
  final Future<String> Function() _refresher;

  @override
  Future<MessengerAuthContext> getAuthContext() async {
    var token = await _storage.read(key: 'access_token');
    if (token == null || _isExpired(token)) {
      token = await _refresher();   // your refresh call.
      await _storage.write(key: 'access_token', value: token);
    }
    return MessengerAuthContext(
      tenantExternalKey: 'futbolista',  // your tenant key, issued by NSG.
      productExternalKey: 'futbolista',
      identityProvider: IdentityProvider.nsg,
      externalUserId: await _storage.read(key: 'user_id') ?? '',
      accessToken: token,
    );
  }

  bool _isExpired(String token) {
    // decode JWT exp or check your own metadata.
    return false;
  }
}
```

The SDK itself stores its `sessionToken` (from `client.messenger.session(...)`) in `flutter_secure_storage` automatically, keyed by a SHA-256 fingerprint of the identity fields — see `sdk/nsg_messenger/README.md` § "Жизненный цикл сессии" for the cache / refresh flow.

## Embed widgets

The SDK exposes widgets via static factory methods on `NsgMessenger` (so they're automatically wrapped in `MessengerThemeScope` when a theme override is configured). Use them inside any `Scaffold`:

```dart
import 'package:flutter/material.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        // L10n delegates — required for the SDK to render localized strings.
        localizationsDelegates: NsgL10n.localizationsDelegates,
        supportedLocales: NsgL10n.supportedLocales,
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Futbolista')),
        // Chat list. Tap a tile → SDK pushes the room screen
        // via NsgMessenger.openRoom() automatically.
        body: NsgMessenger.chatsListView(),
      );
}
```

To open a specific room programmatically (e.g. from a deep link or product-context button):

```dart
ElevatedButton(
  onPressed: () => NsgMessenger.openRoom(context, roomId),
  child: const Text('Open chat'),
);
```

Available public widget / API surface (see `nsg_messenger.dart` for the full export list):
- `NsgMessenger.chatsListView({mode})` — rooms list widget.
- `NsgMessenger.openRoom(context, roomId)` — push the room screen.
- `NsgMessenger.openSupportChat(context, contextId: ...)` — support flow.
- `NsgMessenger.openProductRoom(...)` — get-or-create per-entity room (TASK13).
- `NsgMessenger.rooms` — programmatic rooms API (list/get/createDirect/createGroup).
- `NsgMessenger.messagesControllerFor(roomId)` — controller for a custom chat screen.
- `NsgMessenger.userEventStream` / `NsgMessenger.roomStream(roomId)` — realtime events.
- `NsgMessenger.sessionStateStream()` — session lifecycle for connection banners.

Lower-level screens (`ChatScreen`, `ChatsListScreen`) are NOT exported — host apps go through the static factory methods so theme injection works uniformly.

## Push notifications (optional)

If you want FCM/APNs push, add `nsg_messenger_push` (see pubspec snippet above) and pass a `FirebasePushTokenProvider` at init time:

```dart
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger_push/nsg_messenger_push.dart';

await NsgMessenger.init(
  apiBaseUrl: '...',
  authTokenProvider: MyAuthProvider(),
  pushTokenProvider: await FirebasePushTokenProvider.create(),
);
```

Notes:
- `nsg_messenger_push` is a separate package so customers without push (web, embed-only, custom pipelines) don't drag in `firebase_messaging` native plugin.
- For tests / static-token scenarios use `InMemoryPushTokenProvider` exported from `nsg_messenger` core.
- `firebase_core`/`firebase_messaging` version compatibility matrix: see `sdk/nsg_messenger_push/README.md` (the package declares wide ranges — your host app's Firebase pins win).
- Server-side push body localization is keyed off `DeviceRegistration.locale` — no extra host work needed.

## Theming (optional)

Pass `NsgMessengerTheme` to `init()` to override the SDK's `ColorScheme`, `TextTheme`, and domain tokens (bubble radius, room tile padding, etc). Without an override the SDK reads `Theme.of(context)` from your `MaterialApp.theme` and uses fallback constants for domain tokens. See [theming.md](theming.md) for the full token reference and dark-mode patterns.

## Localization (optional)

The SDK ships RU + EN locales. The host app must register `NsgL10n.localizationsDelegates` + `NsgL10n.supportedLocales` on its `MaterialApp` (see the embed snippet above). System locale resolves automatically; override at init via `locale:`. Adding a new locale or auditing the key surface: see [i18n.md](i18n.md).

## Runtime config (optional)

Pass `NsgMessengerConfig` to `init()` to tune scroll prefetch thresholds and other behavior knobs (separate from visual theme). Tuning hints (small screen vs tablet vs slow network) live in [theming.md](theming.md) § "NsgMessengerConfig".

## Demo / theming sandbox

For designer iteration (no backend required) there is a theming sandbox that boots the SDK widgets against in-memory fixtures via `NsgMessenger.initDemo(...)` — `apps/spike_ui/` in the platform monorepo (not part of the public SDK distribution). Useful for tweaking `NsgMessengerTheme` values without a running NSG backend.

<!-- verified against commit e25a73e -->

> **Verification convention:** the marker above pins each doc to a known-good commit. When the SDK's public API changes in a way that breaks examples here, the PR author should re-verify the snippets in this file and update the marker. CI does not auto-enforce this — it's a manual convention to catch documentation drift during review.
