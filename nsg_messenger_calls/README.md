# nsg_messenger_calls

Optional audio/video calling, group conferences and screen sharing for
`nsg_messenger`. This package owns `flutter_webrtc`, call controllers, call
overlays and ringback audio. Text, attachments and recording/playback of voice
messages remain in `nsg_messenger` and do not require this package.

## Enable calling

Add `nsg_messenger_calls` alongside `nsg_messenger` in the host application's
dependencies. In the public Git distribution:

```yaml
dependencies:
  nsg_messenger_calls:
    git:
      url: https://github.com/zenalex/nsg-connect-sdk.git
      path: nsg_messenger_calls
```

Pin this package and core to the same SDK commit/tag with `ref:`. Relative
sibling dependencies resolve within that Git checkout. Explicitly install
the feature for each session:

```dart
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger_calls/nsg_messenger_calls.dart';

await NsgMessenger.init(
  apiBaseUrl: apiBaseUrl,
  authTokenProvider: authTokenProvider,
  callsFeature: NsgMessengerCalls.feature(),
);
```

Keep `CallOverlayHost` and `ConferenceOverlayHost` in the application's root
widget builder. The SDK chat screen shows call buttons and conference banners
only when the feature is installed. `NsgMessenger.dispose()` disposes it before
the session transport; create a fresh feature when switching accounts.

For a chat-only host, depend on `nsg_messenger` alone and omit `callsFeature`.
Neither WebRTC nor its native plugin is then part of the dependency graph.
Calling controls remain hidden, while voice-message recording uses `record`.

## Migration from calls bundled in core

- Import call controllers, states, adapters and overlays from this package.
- Use `NsgMessengerCalls.callController`, `.conferenceCalls`, `.startCall()`
  and `.fetchAndInjectCallInvite()` instead of the corresponding core methods.
- Nullable controller accessors support root overlays during teardown/reinit.
- `ClientCallRpc` and `ClientConferenceRpc` now receive the session-bound
  `MessengerCallsContext`; custom controllers can still use fake RPC/adapters.
- Call history and VoIP token registration remain lightweight core APIs.
- No server protocol change or database migration is required.

Chatista is an example of an explicitly enabled host. Public SDK distributions
include this package as a sibling of `nsg_messenger` and `nsg_connect_client`.
