/// **TASK20 followup (a)**: transport health state, separate axis from
/// [MessengerSessionState] (auth/login state).
///
/// Three states:
///
///   * [healthy] — WebSocket connected, last successful frame recent.
///   * [reconnecting] — WS dropped, retry in flight. Fewer than
///     `disconnectedAfterFailures` consecutive failed reconnect
///     attempts.
///   * [disconnected] — `disconnectedAfterFailures`+ consecutive failed
///     reconnect attempts. Still retrying (SDK never gives up while
///     runtime is alive), but the user should be aware that the
///     network is having sustained problems.
///
/// Default failure threshold: 3 attempts → `disconnected`. With the
/// fast-then-slow backoff (0.5s, 1s, 2s, ±20% jitter) that's roughly
/// 3.5s before the indicator turns red — short enough to feel
/// responsive, long enough to avoid flicker on transient blips.
///
/// **NOT for auth invalidation.** See [MessengerSessionState] for that
/// axis. A `disconnected` connection state means "server unreachable"
/// — the token cache is preserved across transport blips. Auth
/// invalidation requires an explicit server response (401 / typed
/// exception) and lives in `MessengerSessionManager`.
enum MessengerConnectionState { healthy, reconnecting, disconnected }
