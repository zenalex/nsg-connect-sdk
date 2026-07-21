# Theming

Deep-dive on visual customization (`NsgMessengerTheme`) and behavior knobs (`NsgMessengerConfig`) for `nsg_messenger` SDK.

## Two axes: config (behavior) vs theme (visual)

The SDK splits customization into two independent objects, both passed to `NsgMessenger.init(...)`:

| What | Class | Storage | Pass via |
|---|---|---|---|
| Visual styling | `NsgMessengerTheme` | `MessengerThemeScope` overlay over host's `Theme.of(context)` | `init(theme: ...)` |
| Behavior knobs | `NsgMessengerConfig` | Singleton on `MessengerRuntime.instance.config` | `init(config: ...)` |

You may want default scroll behavior + custom theme, or vice versa — both are optional and independent.

## `NsgMessengerTheme` overview

`NsgMessengerTheme` has 4 fields, all optional:

```dart
@immutable
class NsgMessengerTheme {
  const NsgMessengerTheme({
    this.colorScheme,
    this.textTheme,
    this.bubbleTokens,
    this.roomTileTokens,
  });

  final ColorScheme? colorScheme;
  final TextTheme? textTheme;
  final NsgMessageBubbleTokens? bubbleTokens;
  final NsgRoomTileTokens? roomTileTokens;
}
```

**Inheritance contract:**
- Empty fields (`null`) fall through to the host's `Theme.of(context)` (your `MaterialApp.theme`).
- Non-null fields overlay on top: `colorScheme` is replaced, `textTheme` is **merged** (not replaced), `bubbleTokens` / `roomTileTokens` are stored as `ThemeData.extensions` so widgets read them via `Theme.of(context).extension<NsgMessageBubbleTokens>()`.

Use `NsgMessengerTheme.empty` (or just don't pass `theme:` to `init`) when you want to inherit the host's theme fully — the `MessengerThemeScope` short-circuits in that case for zero overhead.

## `ColorScheme` override example

The SDK uses Material 3 `ColorScheme` semantics throughout. Override with `ColorScheme.fromSeed(...)` for a quick brand recolor:

```dart
import 'package:flutter/material.dart';
import 'package:nsg_messenger/nsg_messenger.dart';

await NsgMessenger.init(
  apiBaseUrl: '...',
  authTokenProvider: MyAuthProvider(),
  theme: NsgMessengerTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6F00), // Chatista orange.
      brightness: Brightness.light,
    ),
  ),
);
```

For dark mode see § "Dark mode example" below.

Which `ColorScheme` slots the SDK uses:
- `primary` / `onPrimary` — own message bubble background + text, send-button.
- `surface` / `onSurface` — peer message bubble background + text, room tile background.
- `error` — failed-send icon, error banners.
- `surfaceVariant` / `secondaryContainer` — chips, badges, attachments.

(Refer to the actual widget sources under `sdk/nsg_messenger/lib/src/messages/` and `.../rooms/` for the exact slot usage if you need fine-grained control.)

## `TextTheme` merge semantics

`TextTheme` is **merged** with the host's text theme, not replaced. Override just the slots you care about; everything else falls through to the host:

```dart
NsgMessengerTheme(
  textTheme: const TextTheme(
    // Override only message body text. titleMedium / bodySmall / etc.
    // inherit from MaterialApp.theme.textTheme.
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      height: 1.4,
    ),
  ),
);
```

Implementation: `NsgMessengerTheme.applyTo(parent)` does `parent.textTheme.merge(override)`, where Flutter's merge keeps `parent`'s value for any field `override` left null.

SDK text slots in use:
- `titleMedium` — room tile primary text (name).
- `bodyMedium` — message bubble body, room tile subtitle.
- `bodySmall` — timestamps, "edited" badge, status hints.
- `labelMedium` — button labels, action sheet items.

## Domain tokens reference

### `NsgMessageBubbleTokens`

Lives in `ThemeData.extensions`. Read via `Theme.of(context).extension<NsgMessageBubbleTokens>() ?? NsgMessageBubbleTokens.fallback`.

| Field | Type | Default (`.fallback`) | Purpose |
|---|---|---|---|
| `radiusOwn` | `BorderRadius` | `topLeft/topRight/bottomLeft = 16, bottomRight = 4` | Own (sender) bubble border radius — tail at bottom-right. |
| `radiusPeer` | `BorderRadius` | `topLeft/topRight/bottomRight = 16, bottomLeft = 4` | Peer (recipient) bubble — mirror of `radiusOwn`, tail at bottom-left. |
| `padding` | `EdgeInsets` | `symmetric(horizontal: 12, vertical: 8)` | Inner padding around bubble content (text + status icon). |
| `maxWidthFraction` | `double` | `0.78` | Maximum bubble width as a fraction of available screen width (0.0–1.0). |
| `statusIconSize` | `double` | `14` | Pixel size of the status icon (pending spinner / sent checkmark / error icon). |
| `interBubbleSpacing` | `double` | `8.0` | **(Chunk 1)** Vertical gap between successive bubbles. Applied as outer padding (`top` + `bottom` = `interBubbleSpacing / 2`), so neighbouring bubbles add up to the full value. |
| `composerPadding` | `EdgeInsets` | `fromLTRB(8, 4, 8, 8)` | **(Chunk 1)** Outer padding of the `MessageComposer` row (attach button / text field / send button). |

Override example:

```dart
NsgMessengerTheme(
  bubbleTokens: NsgMessageBubbleTokens.fallback.copyWith(
    maxWidthFraction: 0.85,        // Wider bubbles on tablets.
    statusIconSize: 16,
    interBubbleSpacing: 12,        // More breathing room.
    composerPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
  ),
);
```

### `NsgRoomTileTokens`

Lives in `ThemeData.extensions`. Read via `Theme.of(context).extension<NsgRoomTileTokens>() ?? NsgRoomTileTokens.fallback`.

| Field | Type | Default (`.fallback`) | Purpose |
|---|---|---|---|
| `avatarSize` | `double` | `44` | Avatar diameter in `RoomSummaryTile`. |
| `unreadBadgeSize` | `double` | `20` | Diameter of the unread-count badge (round shape with counter inside). |
| `contentPadding` | `EdgeInsets` | `symmetric(horizontal: 16, vertical: 8)` | **(Chunk 1)** Padding applied as `ListTile.contentPadding`. |
| `titleSubtitleSpacing` | `double` | `4.0` | **(Chunk 1)** Vertical gap between title and subtitle (`SizedBox(height: ...)` or subtitle top padding). |

Override example:

```dart
NsgMessengerTheme(
  roomTileTokens: NsgRoomTileTokens.fallback.copyWith(
    avatarSize: 52,                     // Larger avatars.
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    titleSubtitleSpacing: 6,
  ),
);
```

Both token classes are `ThemeExtension` subclasses, so they participate in `ThemeData.lerp(...)` cross-fade transitions — useful if the host app animates between light / dark or between two brand themes.

## `MessengerThemeScope` usage

`MessengerThemeScope` is the widget that overlays `NsgMessengerTheme` on top of `Theme.of(context)`. You rarely instantiate it manually — `NsgMessenger.chatsListView()` and `NsgMessenger.openRoom(...)` wrap their roots in it automatically when `init(theme: ...)` was non-empty.

You **do** instantiate it manually when you embed SDK widgets in a sub-tree with different branding (e.g. one tab uses Chatista colors, another uses Futbolista):

```dart
MessengerThemeScope(
  theme: const NsgMessengerTheme(
    colorScheme: chatistaScheme,
    bubbleTokens: chatistaBubbles,
  ),
  child: SomeCustomChatScreen(),  // Uses MessagesController etc.
);
```

`MessengerThemeScope` is a `StatelessWidget` — placing it deeper in the tree just re-applies the overlay relative to whatever `Theme.of(context)` resolves at that point.

## `NsgMessengerConfig` + `NsgScrollThresholds`

```dart
@immutable
class NsgMessengerConfig {
  const NsgMessengerConfig({
    this.scrollThresholds = const NsgScrollThresholds(),
  });

  final NsgScrollThresholds scrollThresholds;

  static const NsgMessengerConfig fallback = NsgMessengerConfig();
}

@immutable
class NsgScrollThresholds {
  const NsgScrollThresholds({
    this.chatLoadMorePx = 200,
    this.chatsListLoadMorePx = 200,
  });

  final double chatLoadMorePx;
  final double chatsListLoadMorePx;
}
```

| Field | Default | Purpose |
|---|---|---|
| `chatLoadMorePx` | `200` | `ChatScreen` — distance from the bottom edge (DESC scroll, older messages) at which the SDK triggers fetch-next-page. |
| `chatsListLoadMorePx` | `200` | `ChatsListScreen` — distance from the bottom edge at which the SDK triggers fetch-more-rooms. |

**Tuning hints:**
- **Phone, portrait:** keep defaults (`200`). Anything larger triggers prefetch off-screen so often it's wasted.
- **Tablet / desktop / web** with a long viewport: bump to `400` – `600`. Prefetch starts earlier so the next page finishes loading before the user reaches the edge.
- **Slow network** (mobile data, EDGE, sat link): increase regardless of screen size — prefetch needs more lead time to mask latency.

```dart
await NsgMessenger.init(
  apiBaseUrl: '...',
  authTokenProvider: MyAuthProvider(),
  config: const NsgMessengerConfig(
    scrollThresholds: NsgScrollThresholds(
      chatLoadMorePx: 500,
      chatsListLoadMorePx: 500,
    ),
  ),
);
```

Config is **init-time-set, runtime read-only**: changing values dynamically after `init()` is not supported (would need a re-init of the runtime). For an MVP that's intentional — change is rare.

## Dark mode example

The SDK respects whatever `ThemeMode` your host app uses. Simplest pattern: pass a `ColorScheme` built with `Brightness.dark` and let `MaterialApp.themeMode` drive light/dark switching at the host level.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F00),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      home: HomePage(brightness: brightness),
    );
  }
}
```

If you also pass `theme:` to `NsgMessenger.init(...)`, that override layers on top of whichever ThemeData `MaterialApp` resolves (light or dark). A common pattern is to compute the SDK theme dynamically:

```dart
NsgMessengerTheme buildSdkTheme(Brightness b) => NsgMessengerTheme(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F00),
        brightness: b,
      ),
      bubbleTokens: NsgMessageBubbleTokens.fallback.copyWith(
        maxWidthFraction: 0.82,
      ),
    );
```

Then re-init or `dispose() + init()` when the brightness flips. (Live theme swap without re-init is on the wishlist; not in MVP.)

## Per-product branding (deferred)

Per-product theming (e.g. Chatista vs Futbolista with different brand books in the same multi-tenant deployment) is **deferred to TASK28** admin tooling — that's where the multi-runtime context model gets formalized. For the current MVP: **one `NsgMessengerTheme` per `NsgMessenger.init(...)` call**. If you embed SDK widgets in multiple tabs with different branding within a single app, wrap each subtree in its own `MessengerThemeScope` — see § "`MessengerThemeScope` usage".

<!-- verified against commit e25a73e -->
