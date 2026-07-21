# nsg-connect SDK

Integration surface of the **nsg-connect / Chatista** messaging platform:
embed a full-featured chat (rooms, calls, attachments, push) into your
Flutter app, and drive server-side flows (auth bridge, product push
notifications) from your backend.

This repo is the public distribution, synced from the platform monorepo;
the platform core (server, admin, infra, secrets) is not part of it.
Read-only for consumers — changes land in the monorepo and get synced here.

## Layout

| Path | What it is |
|---|---|
| `nsg_messenger` | Flutter SDK: chat widgets, session, realtime, l10n |
| `nsg_messenger_push` | Optional FCM/APNs push provider for the SDK |
| `nsg_connect_client` | Generated Serverpod API client (SDK dependency) |
| `nsg_connect_flutter` | Flutter glue for the Serverpod client |
| `docs/integration` | Integrator docs — start here |
| `examples/server-csharp` | Reference S2S client for your backend |

## Quick start

Client (Flutter host app) — see
[`docs/integration/getting_started.md`](docs/integration/getting_started.md):

```yaml
dependencies:
  nsg_messenger:
    git:
      url: https://github.com/zenalex/nsg-connect-sdk.git
      path: nsg_messenger
```

Backend (any language) — two HTTP calls authorized by a tenant secret, see
[`docs/integration/server_side.md`](docs/integration/server_side.md).

To onboard (tenant/product keys, tenant secret) contact the platform
operator.

## As a git submodule

Host repos (e.g. the internship repo) may consume this repo as a submodule
instead of a git dependency:

```bash
git submodule add https://github.com/zenalex/nsg-connect-sdk.git sdk
```

```yaml
dependencies:
  nsg_messenger:
    path: ../../sdk/nsg_messenger   # relative to your pubspec.yaml
```

## Versioning

The default branch is the release channel; `nsg_messenger/lib/src/version.dart`
carries the build stamp (`<date>+<monorepo sha>`) — include it in bug
reports. Release tags for pinning: planned.
