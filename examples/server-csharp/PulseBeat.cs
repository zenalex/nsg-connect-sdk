// PulseBeat.cs — heartbeat signals to Connect Pulse (CHATista monitoring)
// from .NET Framework 4.7.2+. C# 7.3, no NuGet packages: references only
// framework assemblies System.Net.Http and System.Web.Extensions.
//
// Guide: docs/integration/pulse_dotnet_framework.md
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

namespace Nsg.Monitoring
{
    public static class PulseBeat
    {
        private const string BeatUrl = "https://hooks.chatista.me/beat";

        // One HttpClient per process. A new one per call leaks sockets on
        // .NET Framework: ports pile up in TIME_WAIT until they run out.
        private static readonly HttpClient Http;

        private static readonly JavaScriptSerializer Json = new JavaScriptSerializer();

        static PulseBeat()
        {
            // Enable TLS 1.2 explicitly. An app built for an old
            // targetFramework (typically <httpRuntime targetFramework="4.5">
            // in web.config) offers only TLS 1.0 by default, and the receiver
            // does not accept it. Use |=, not =, so nothing already allowed
            // gets switched off.
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;

            // A heartbeat must never hang the caller. 10 s is plenty.
            Http = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
        }

        /// <summary>"I'm alive" — empty body.</summary>
        public static Task<bool> AliveAsync(string token)
        {
            return SendAsync(token, null);
        }

        /// <summary>Alive but degraded — a yellow card in the chat.</summary>
        public static Task<bool> WarnAsync(string token, string text)
        {
            return SendAsync(token, new Dictionary<string, object>
            {
                { "status", "warn" },
                { "text", text },
            });
        }

        /// <summary>Broken — a red card in the chat.</summary>
        public static Task<bool> ErrorAsync(string token, string text)
        {
            return SendAsync(token, new Dictionary<string, object>
            {
                { "status", "error" },
                { "text", text },
            });
        }

        /// <summary>
        /// Measurements: queue length, free disk, age of the last sync.
        /// Warn/error thresholds are set on the monitor card, not here.
        /// Put the unit in the name: queue_len, disk_free_gb, sync_age_min.
        /// </summary>
        public static Task<bool> ValuesAsync(string token, IDictionary<string, double> values)
        {
            return SendAsync(token, new Dictionary<string, object> { { "values", values } });
        }

        private static async Task<bool> SendAsync(string token, object body)
        {
            try
            {
                using (var request = new HttpRequestMessage(HttpMethod.Post, BeatUrl))
                {
                    // The token goes in a header only. In the URL the receiver
                    // rejects it (401 token_in_path_not_accepted).
                    request.Headers.Add("X-Pulse-Token", token);

                    if (body != null)
                    {
                        // A serializer, not string concatenation: it escapes
                        // quotes in the text and writes numbers with a dot in
                        // any culture. Concatenation on a ru-RU server would
                        // produce 31,5 — JSON the receiver rejects.
                        request.Content = new StringContent(
                            Json.Serialize(body), Encoding.UTF8, "application/json");
                    }

                    using (var response = await Http.SendAsync(request).ConfigureAwait(false))
                    {
                        if (response.IsSuccessStatusCode) return true;

                        // 403 paused means the monitor is paused for
                        // maintenance — expected, not an error.
                        var answer = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                        Trace.TraceWarning("Pulse: HTTP {0} {1}", (int)response.StatusCode, answer);
                        return false;
                    }
                }
            }
            catch (Exception e)
            {
                // Monitoring must never take the service down. A heartbeat
                // that did not arrive shows up on its own: the monitor turns
                // red after period + grace. Never log the token.
                Trace.TraceWarning("Pulse: {0}", e.GetBaseException().Message);
                return false;
            }
        }
    }
}
