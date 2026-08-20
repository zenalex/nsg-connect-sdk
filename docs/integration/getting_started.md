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
// MessengerAuthContext / IdentityProvider / MessengerSession are re-exported
// by the nsg_messenger barrel — no direct nsg_connect_client dependency needed.

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

    // Firebase push provider. Without it push registration is skipped
    // silently — the app works, but only while it is open. See
    // "Push notifications" below before leaving this null.
    pushTokenProvider: null,

    // Optional — externalKey of the product this app embeds (for
    // server-side product-scoping). Required when running in
    // embeddedProduct mode against a multi-product tenant.
    productExternalKey: 'futbolista',

    // Optional — behavior knobs (scroll thresholds etc). See theming.md.
    config: const NsgMessengerConfig(),

    // Optional — offline cache (sqflite). Default true; set false to run
    // fully online. cacheDirectoryOverride is for tests / custom storage.
    enableOfflineCache: true,
    cacheDirectoryOverride: null,

    // Optional — base URL shown for incoming-webhook (autopost) links in
    // the Integrations screen. Derived from apiBaseUrl when omitted
    // (api.<domain> -> hooks.<domain>); set explicitly on non-standard
    // hosting.
    hooksBaseUrl: null,
  );

  runApp(const MyApp());
}
```

(There is one more named parameter, `tokenStoreOverride`, marked
`@visibleForTesting` — do not use it in production code.)

Notes:
- Call `init()` once at startup. Calling it again is allowed and is a **full
  restart** of the SDK: the runtime disposes the previous session manager and
  client and creates new ones (that's the supported way to swap
  `AuthTokenProvider` or theme). To switch users / tenants after logout prefer
  `NsgMessenger.reauthenticate()` (re-asks your `AuthTokenProvider` for a fresh
  context); `NsgMessenger.dispose()` + `init()` also works.
- The SDK does NOT call `WidgetsFlutterBinding.ensureInitialized()` for you; your `main()` must do it.
- **Never let two `init()` calls overlap.** Sequential re-init is supported (see
  above); *concurrent* re-init is not. The second call resets the runtime —
  `sessionState` drops to `uninitialised` and the event subscription is
  cancelled — while the first is still finishing, so the first caller's RPC
  fails. If you init lazily (e.g. on the first "Contact support" tap rather
  than in `main()`), memoize the `Future`:

  ```dart
  static Future<void>? _initFuture;
  static Future<void> _ensureInit() => _initFuture ??= NsgMessenger.init(...);
  ```

  A `bool _initialized` flag does **not** work here: it is only set after the
  `await`, so a second tap during init sails straight past it. Init takes about
  a second (issue token + create session), which is exactly long enough for a
  user to tap twice — show a progress indicator so they don't.

## Implement `AuthTokenProvider`

The SDK never stores the customer access token. On every refresh it asks your provider for a fresh `MessengerAuthContext`. You're responsible for keeping the access token valid (refresh against your own auth backend) and producing the context.

Minimal in-memory example:

```dart
import 'package:nsg_messenger/nsg_messenger.dart';
// MessengerAuthContext / IdentityProvider / MessengerSession are re-exported
// by the nsg_messenger barrel — no direct nsg_connect_client dependency needed.

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

`MessengerAuthContext` has one more optional field, `deviceId` — a stable
per-device identifier used for multi-device session handling. Leave it unset
unless you have a reason to supply your own.

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
        // Required: lets the SDK notice when another route (your profile /
        // settings screen) is pushed on top of an open chat — otherwise the
        // covered chat keeps suppressing push notifications and silently
        // marks incoming messages as read (issue #55).
        navigatorObservers: [NsgMessenger.routeObserver],
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

Most-used public surface (see `nsg_messenger.dart` for the full export list — it is much larger than this):
- `NsgMessenger.chatsListView({mode})` — rooms list widget.
- `NsgMessenger.openRoom(context, roomId)` — push the room screen.
- `NsgMessenger.rooms.openSupportChat(productExternalKey: ..., contextId: ...)` — support flow; returns `RoomDetails`, open it with `openRoom`. See [Support chat](#support-chat) for the full recipe.
- `NsgMessenger.rooms` — programmatic rooms API (list/get/createDirect/createGroup, and `getOrCreateProductRoom` for per-entity rooms).
- `NsgMessenger.messagesControllerFor(roomId)` — controller for a custom chat screen.
- `NsgMessenger.userEventStream` / `NsgMessenger.roomStream(roomId)` — realtime events.
- `NsgMessenger.sessionStateStream()` — session lifecycle for connection banners.
- `NsgMessenger.connectionStateStream` / `connectionState` / `forceReconnect()` — transport state.
- `NsgMessenger.updateTheme(theme)` — swap the SDK theme at runtime, without `dispose()` + `init()`.
- `showPendingAnnouncements(context, productExternalKey: ..., onOpenRoute: ...)` — in-app announcements shown on entry (planned maintenance, release notes, a nudge to open a screen). The server decides **what** to show — expiry, per-user "already seen", product targeting; do not re-implement those rules on your side. `onOpenRoute` receives a product-defined route and an opaque payload; omit it and route-kind announcements render as plain text instead of showing a button that goes nowhere. Errors are swallowed: failing to show an announcement is bad, breaking app start is worse. See [tasks/TASK91.md](../tasks/TASK91.md).
- `NsgMessenger.routeObserver` — add to `MaterialApp.navigatorObservers` (required, see the embed snippet above); for a nested `Navigator` that pushes screens over an embedded chat use `NsgMessenger.createNestedRouteObserver()` / `releaseNestedRouteObserver()`.

> `NsgMessenger.openProductRoom(...)` is **not implemented** — it throws
> `UnimplementedError`. Use `NsgMessenger.rooms.getOrCreateProductRoom(...)`
> instead.

> `NsgMessenger.openSupportChat(context, contextId: ...)` is **not implemented
> either**, and unlike `openProductRoom` it fails *silently*: it pushes
> `SupportChatScreen`, a placeholder rendering the literal text
> `SupportChatScreen — TASK39`. It does not throw, so nothing tells you the API
> is unfinished — the screen just looks broken. Use the
> [Support chat](#support-chat) recipe instead.

Beyond chat, the facade also exposes calls and conferences (`callController`,
`conferenceCalls`, `startCall`, `listCallHistory`, `registerVoipToken`),
contacts and cards (`contacts`, `contactCards`), presence
(`subscribePresence`, `getLastSeen`), profile (`uploadUserAvatar`,
`setDisplayName`, profile translations), share-in
(`handleSharedPayload` & friends), the offline cache (`clearOfflineCache`,
attachment-cache API), admin surfaces (`integrations`, `botsAdmin`, `myBots`,
`botCatalog`, `platformAdmin`), and screen openers (`openSupportTeam`,
`openPeople`, `openContactProfile`, `openContactRequests`, `openMyTickets`,
`openTasks`, `openObjectRoomsCatalog`).

The two core chat screens (`ChatScreen`, `ChatsListScreen`) are NOT exported —
host apps go through the static factory methods so theme injection works
uniformly. Standalone/admin screens **are** exported and can be pushed directly
(`IntegrationsScreen`, `BotsAdminScreen`, `MyBotsScreen`, `BotCatalogScreen`,
`BotCardScreen`, `PlatformAdminScreen`, `PulseScreen`,
`ContactCardEditorScreen`), as are overlay hosts `CallOverlayHost` /
`ConferenceOverlayHost` and widgets like `MessengerConnectionBanner`.

Note that several SDK surfaces are pushed into the **host** navigator without a
`MessengerThemeScope` wrapper, so they inherit the host `Theme` and, more
importantly, the host `Localizations` — see
[Scope gaps](theming.md#scope-gaps-pushed-routes-and-modals) for the list and
what it means for you in practice.

## Support chat

Embedding "Contact support" as a single button is the most common integration,
and the whole flow is three calls. Copy this service as-is — every guard in it
exists because its absence produced a real bug in a shipped app.

```dart
class SupportService {
  SupportService._();

  static const String productKey = 'my_product';

  // Memoize the FUTURE, not a bool "already initialized" flag. A flag is only
  // set AFTER the await, so a second tap during the ~1s init (issue token +
  // create session) enters init again — and a second NsgMessenger.init()
  // tears the first one down mid-flight (sessionState -> uninitialised, event
  // subscription cancelled), making the first caller's RPC fail.
  static Future<void>? _initFuture;
  static bool _opening = false;

  static Future<void> _ensureInit() => _initFuture ??= _init();

  static Future<void> _init() async {
    try {
      await NsgMessenger.init(
        apiBaseUrl: 'https://api.example.com',
        authTokenProvider: MyProductAuthTokenProvider(),
        mode: MessengerMode.embeddedProduct,
        productExternalKey: productKey,
        errorReporter: MyErrorReporter(),
      );
    } catch (_) {
      _initFuture = null; // let the next attempt retry instead of sticking
      rethrow;
    }
  }

  static Future<void> openChat(BuildContext context) async {
    if (_opening) return; // second tap would push a second copy of the screen
    _opening = true;
    try {
      // Opening takes about a second with no visible feedback — show a
      // progress indicator, otherwise users tap again and race you.
      final RoomDetails room;
      final progress = showMyProgressDialog();
      try {
        await _ensureInit();
        room = await NsgMessenger.rooms.openSupportChat(
          productExternalKey: productKey,
          contextId: 'general', // 'general' | 'bug' | 'idea' — scopes the room
        );
      } finally {
        // Hide BEFORE pushing: openRoom does not return until the chat is
        // closed, so hiding in the outer finally leaves the dialog on top of
        // the conversation.
        progress.hide();
      }
      if (!context.mounted) return;
      _opening = false;
      await NsgMessenger.openRoom(context, room.id);
    } catch (e, s) {
      myErrorReporter.capture(e, s);
      showSnack('Support is temporarily unavailable.');
    } finally {
      _opening = false;
    }
  }
}
```

Repeat calls with the same `contextId` reopen the same room. `NsgMessenger
.openMyTickets(context)` opens the "my requests" screen and needs the same
`_ensureInit()` in front of it.

Prerequisites, both easy to miss:
- `NsgL10n.delegate` must be registered on your `MaterialApp` — see
  [Localization](#localization-required). Without it the attachment picker
  inside the chat opens as a blank grey rectangle.
- Server side (issued-token flow) must be wired first — see
  [CONNECT_PRODUCT_QUICKSTART.md](../CONNECT_PRODUCT_QUICKSTART.md).

## Push notifications

**Optional to build, not optional to skip.** Without push your users only see
messages while the app is open — the SDK keeps a WebSocket while in
foreground and nothing wakes the device otherwise. On 11.08.2026 we found
that *every* integrated product except Chatista had **zero registered
devices**: our side was complete, the host apps simply never passed a
provider, and nobody noticed because missing notifications look like silence
(issue #120).

It takes two sides. Neither works alone:

| your side | our side |
|---|---|
| add `nsg_messenger_push`, wire Firebase into the app, pass `pushTokenProvider` at init | mount your Firebase service-account JSON and set `PUSH_FCM_<PRODUCT>` |
| pass `productExternalKey` so devices are scoped to your product | route wake-ups only to devices of that product |
| upload your APNs key to **your** Firebase console (iOS) | — we never see the `.p8` |
| RuStore build: send the RuStore project credentials | set `PUSH_RUSTORE_<PRODUCT>` |

**How to verify it landed.** Ask us to check the delivery-health screen: it
shows, per product, how many devices are registered, when a registration was
last refreshed and whether the sending keys are configured. Verdicts are
worded, not coloured — `no devices` is your side, `no keys` is ours.

Also worth knowing: a device registration is refreshed on every app start and
on token rotation, so a stale timestamp means nobody has opened the app —
not that push is broken.

To wire it up, add `nsg_messenger_push` (see pubspec snippet above) and pass a `FirebasePushTokenProvider` at init time:

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

## Localization (required)

The SDK ships RU + EN locales. The host app **must** register
`NsgL10n.localizationsDelegates` + `NsgL10n.supportedLocales` on its
`MaterialApp` (see the embed snippet above). System locale resolves
automatically; override at init via `locale:`. Adding a new locale or auditing
the key surface: see [i18n.md](i18n.md).

This is not a cosmetic step, and skipping it fails in a way that is genuinely
hard to diagnose. `NsgL10n.of(context)` is
`Localizations.of<NsgL10n>(context, NsgL10n)!` — with no delegate registered
the null-check throws, and in a **release** build Flutter replaces the widget
with a blank grey `ErrorWidget`: no message, no stack, nothing in the log. A
reported symptom of exactly this was "the attachment sheet opens empty".

`MessengerThemeScope` supplies the delegate inside SDK routes, so most of the
chat keeps working and the breakage looks random — only modals and pushed
routes are affected (see
[Scope gaps](theming.md#scope-gaps-pushed-routes-and-modals)). Registering the
delegate on the host `MaterialApp` is what makes those work.

## Runtime config (optional)

Pass `NsgMessengerConfig` to `init()` to tune scroll prefetch thresholds and other behavior knobs (separate from visual theme). Tuning hints (small screen vs tablet vs slow network) live in [theming.md](theming.md) § "NsgMessengerConfig".

## Demo / theming sandbox

For designer iteration (no backend required) there is a theming sandbox that boots the SDK widgets against in-memory fixtures via `NsgMessenger.initDemo(...)` — `apps/spike_ui/` in the platform monorepo (not part of the public SDK distribution). Useful for tweaking `NsgMessengerTheme` values without a running NSG backend.

<!-- verified against commit 8bc4d82 (2026-07-27) -->

> **Verification convention:** the marker above pins each doc to a known-good commit. When the SDK's public API changes in a way that breaks examples here, the PR author should re-verify the snippets in this file and update the marker. CI does not auto-enforce this — it's a manual convention to catch documentation drift during review.
>
> "Re-verify" means **run it**, not read it. Reading is what let this file
> recommend `NsgMessenger.openSupportChat(...)` for months while it pushed a
> `TASK39` placeholder: the call compiles, the signature is honest, and only
> executing it reveals the screen is a stub. Unimplemented surfaces that throw
> are caught by a compile-and-run pass; ones that silently render a placeholder
> are not. `apps/spike_ui/` boots the widgets against in-memory fixtures with no
> backend and is the cheapest place to do this.
