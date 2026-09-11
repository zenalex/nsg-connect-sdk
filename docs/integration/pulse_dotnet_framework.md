# Connect Pulse from .NET Framework 4.7.2

Uptime monitoring for your backend service in CHATista: the service sends a
short HTTP signal every few minutes. While signals keep coming, the monitor is
green. When they stop for longer than *period + grace*, the monitor turns red
and an alert card lands in your chat room.

This guide is for services on **.NET Framework 4.7.2** — a Windows service or
a site in IIS. The ready-made class is
[`examples/server-csharp/PulseBeat.cs`](../../examples/server-csharp/PulseBeat.cs):
C# 7.3, no NuGet packages.

## How it works

```
POST https://hooks.chatista.me/beat
X-Pulse-Token: plt_<token>
```

- **Empty body** — "I'm alive".
- **JSON `{"status":"warn"|"error","text":"…"}`** — alive but degraded, or
  broken. `text` is shown on the dashboard and in the alert card.
- **JSON `{"values":{"queue_len":12}}`** — measurements; warn/error thresholds
  live on the monitor card, so you can change them without redeploying.
- **No signal for longer than period + grace** — the monitor goes `down`,
  an incident opens, and the alert escalates if nobody takes it.
- The next plain "I'm alive" closes the incident and posts a recovery card.

## 1. Before coding: what the monitor owner does

- **One monitor per service**, not one for everything — otherwise a healthy
  service hides a dead neighbour. In CHATista: **Monitoring → ＋ → Monitor**:
  name, folder, period, grace.
- **Period = how often your service will send.** Presets: 1, 5, 15, 30 min,
  1 h, 1 day. Grace is the allowance for jitter (default 120 s). Name, period
  and grace cannot be edited later — create a new monitor if you need others.
- **The token is shown once.** Hand it to the developer over a secure
  channel. If it leaks, press **Regenerate token** on the monitor card — the
  old one stops working immediately.
- **The monitor starts waiting right after creation.** Press **Pause** until
  the code is deployed, or it will turn red after period + grace.

## 2. Before coding: check the target server

One minute, no token needed. Run it in **Windows PowerShell 5.1** on the
machine where the service will run: it uses the same .NET Framework and
negotiates TLS exactly like your service will.

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
  Invoke-WebRequest -UseBasicParsing -Method Post -Uri 'https://hooks.chatista.me/beat' | Out-Null
  'unexpected: 200 without a token'
} catch {
  if ($_.Exception.Response) { "HTTP $([int]$_.Exception.Response.StatusCode)" }
  else { $_.Exception.Message }
}
```

| Result | Meaning |
|---|---|
| `HTTP 400` | All good: TLS negotiated, network is fine, the receiver answered "no token" (`missing_token`) — expected without one |
| `Could not create SSL/TLS secure channel` | Windows lacks the required cipher suites — see section 3. No code change will help |
| `…trust relationship…` / `…remote certificate is invalid…` | The machine does not trust `ISRG Root X1` — update Windows root certificates |
| timeout, `The remote name could not be resolved` | No internet access, DNS, or a proxy is required |

## 3. Compatibility: the Windows version decides

On .NET Framework, TLS is done by Windows (SChannel), not by the framework.
Over TLS 1.2 the receiver accepts only **ECDHE (P-256) + ECDSA + AES-GCM**;
TLS 1.3 works too (checked 2026-09-11):

- **Windows Server 2012 R2 / Windows 8.1 and newer** — connect.
- **Windows Server 2008 R2 / Windows 7** — cannot: they have no AES-GCM for
  ECDSA certificates, so the handshake fails regardless of code. Send the
  signals from a newer machine instead.
- Anything in between — the check in section 2 answers in a minute, more
  reliably than any table.

The certificate is issued by Let's Encrypt; the chain ends at `ISRG Root X1`.
Machines with automatic root updates have it; isolated ones may not.

## 4. The class

Add **References → Add Reference → Assemblies → `System.Net.Http` and
`System.Web.Extensions`**, then drop
[`PulseBeat.cs`](../../examples/server-csharp/PulseBeat.cs) into the project.
Replace `Trace` with your logger (NLog, log4net).

```csharp
await PulseBeat.AliveAsync(token);                                   // I'm alive
await PulseBeat.WarnAsync(token, "queue is growing");                // yellow
await PulseBeat.ErrorAsync(token, "database unreachable");           // red
await PulseBeat.ValuesAsync(token, new Dictionary<string, double>    // numbers
{
    { "queue_len", 42 },
});
```

Every call returns `false` instead of throwing: monitoring must never take
the service down. What the class takes care of:

- **TLS 1.2 is enabled explicitly.** An app built for an old
  `targetFramework` (e.g. `<httpRuntime targetFramework="4.5">` in
  `web.config`) offers only TLS 1.0 by default.
- **One `HttpClient` per process** — a new one per call exhausts sockets.
- **JSON via a serializer**, never by string concatenation: on a ru-RU server
  concatenation writes `31,5` instead of `31.5`, and quotes in the text break
  the body.
- **The token goes in the `X-Pulse-Token` header only.** In the URL it is
  rejected.

Keep the token in `app.config` / `web.config`, not in code:

```xml
<appSettings>
  <add key="PulseToken" value="plt_…" />
</appSettings>
```

Do not commit the real token — use config transforms or a file excluded from
version control.

## 5. Where to send from

### Windows service — a timer inside

```csharp
using System;
using System.Configuration;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;
using Nsg.Monitoring;

public partial class MyService : ServiceBase
{
    private readonly string _pulseToken = ConfigurationManager.AppSettings["PulseToken"];
    private Timer _pulseTimer;
    private int _busy; // guards against overlapping ticks

    protected override void OnStart(string[] args)
    {
        // Interval = the monitor's period (5 minutes here). The first signal
        // goes a minute after start, once the service is up.
        _pulseTimer = new Timer(PulseTick, null, TimeSpan.FromMinutes(1), TimeSpan.FromMinutes(5));
    }

    protected override void OnStop()
    {
        if (_pulseTimer != null) _pulseTimer.Dispose();
    }

    private void PulseTick(object state)
    {
        if (Interlocked.Exchange(ref _busy, 1) == 1) return; // previous tick still running
        try
        {
            string problem = CheckHealth(); // null means healthy
            if (problem == null)
                PulseBeat.AliveAsync(_pulseToken).GetAwaiter().GetResult();
            else
                PulseBeat.ErrorAsync(_pulseToken, problem).GetAwaiter().GetResult();
        }
        catch (Exception e)
        {
            // Required: an unhandled exception in a Timer callback kills the
            // whole process. And send nothing here — the check failed, not
            // the service; the monitor goes down on its own if this repeats.
            Trace.TraceError("Pulse tick: {0}", e);
        }
        finally
        {
            Interlocked.Exchange(ref _busy, 0);
        }
    }

    /// <summary>
    /// What the service is useless without: database, queue, external API.
    /// Catch expected failures here and return them as text — it ends up in
    /// the alert. Return null when healthy.
    /// </summary>
    private string CheckHealth()
    {
        // e.g. try { using (var c = new SqlConnection(cs)) c.Open(); }
        //      catch (SqlException e) { return "database unreachable: " + e.Message; }
        return null;
    }
}
```

### Site in IIS — better from outside

A timer inside an ASP.NET app does not run all the time: the application pool
recycles on a schedule and goes idle after 20 minutes without requests.
Signals stop, and the monitor turns red over a perfectly healthy site.

**Recommended: from outside.** Windows Task Scheduler runs a script every
5 minutes; it opens the site's health page and reports the result. This also
checks exactly what users see.

```powershell
# C:\pulse\pulse-beat.ps1
[Net.ServicePointManager]::SecurityProtocol =
  [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$token  = [Environment]::GetEnvironmentVariable('PULSE_TOKEN', 'Machine')
$health = 'https://your-site.example/health'
$beat   = 'https://hooks.chatista.me/beat'

try {
  Invoke-WebRequest -UseBasicParsing -Uri $health -TimeoutSec 15 | Out-Null
  Invoke-WebRequest -UseBasicParsing -Method Post -Uri $beat `
    -Headers @{ 'X-Pulse-Token' = $token } -TimeoutSec 10 | Out-Null
} catch {
  # Bytes, not a string: Windows PowerShell 5.1 does not reliably send a
  # string body as UTF-8.
  $json = @{ status = 'error'; text = "health page: $($_.Exception.Message)" } |
    ConvertTo-Json -Compress
  Invoke-WebRequest -UseBasicParsing -Method Post -Uri $beat `
    -Headers @{ 'X-Pulse-Token' = $token } -TimeoutSec 10 `
    -ContentType 'application/json; charset=utf-8' `
    -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null
}
```

```bat
setx PULSE_TOKEN "plt_…" /M
schtasks /Create /TN "Pulse beat - MySite" /SC MINUTE /MO 5 /RU SYSTEM ^
  /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\pulse\pulse-beat.ps1"
```

**From inside**, if there is no other way: application pool **Start Mode =
AlwaysRunning** and **Idle Time-out = 0**; site **Preload Enabled = True**
(requires the Application Initialization feature). And in page code only
`await` — never `.Result` / `.Wait()`, which deadlock under ASP.NET.

## 6. Common mistakes

- **Signal at the end of a successful iteration, not at the start.** A
  service stuck halfway stops signalling and goes down; a signal at the start
  would keep it green.
- **Do not report "could not measure" as "broken".** If a value can be
  missing, that is not a service failure. Test the sender on three inputs:
  success, a real failure, and a missing value.
- **A permanent yellow equals a disabled monitor.** People get used to a
  constant `warn` within a day and stop looking.
- **`text` lives for one signal.** The next signal without `text` clears it —
  that is how a monitor recovers. Need a permanent caption? Send it every time.
- **Numbers must be numbers** (`12`, not `"12"`), names in Latin letters,
  digits, `_ . -`, up to 40 chars, at most 20 values per signal.
- **No more than 120 signals per minute** per monitor, or you get `429`.
- **Pause the monitor for deployments**, or a restart gives a false `down`.
- **Exceptions still go to your error tracker.** Pulse answers "is the
  service alive", it does not collect stack traces.

## 7. Receiver responses

The body is always JSON.

| Code | Body | What to do |
|---|---|---|
| `200` | `{"ok":true,"status":"ok"}` | nothing; `status` is the status actually applied |
| `400` | `{"error":"missing_token"}` | the `X-Pulse-Token` header is missing or empty |
| `400` | `{"error":"invalid_status",…}` | typo in `status` — allowed: `ok`, `warn`, `error` |
| `401` | `{"error":"invalid_token"}` | wrong or regenerated token — get the current one from the monitor owner |
| `401` | `{"error":"token_in_path_not_accepted",…}` | the token was put in the URL — move it to the header |
| `403` | `{"error":"paused"}` | the monitor is paused — expected |
| `413` | `{"error":"payload_too_large"}` | body over 4 KB — shorten `text` |
| `429` | `{"error":"rate_limited","retryAfter":N}` | too frequent — send less often |
| `500` | `{"error":"beat_failed"}` | failure on our side — retry; report it if it persists |

Done when: create the monitor → call `AliveAsync` with the real token → the
monitor turns green in CHATista and the call returns `true`.
