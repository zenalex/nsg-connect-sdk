using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FootballersDiary_Server.Controllers.Auth
{
    /// <summary>
    /// Итог отправки продуктового уведомления через nsg_connect.
    /// Числа — агрегаты ответа <c>ProductNotificationSendResult</c>.
    /// </summary>
    public sealed class ConnectNotificationOutcome
    {
        /// <summary>Вызов дошёл и принят (хотя бы частично). НЕ значит
        /// «пуш пришёл на устройство» — только «принят к доставке».</summary>
        public bool Ok { get; set; }

        /// <summary>Адресатов поставлено в очередь доставки.</summary>
        public int Accepted { get; set; }

        /// <summary>Схлопнуто дедупом (повтор idempotencyKey) — не ошибка.</summary>
        public int Deduped { get; set; }

        /// <summary>Адресатов без единого устройства с чат-приложением.</summary>
        public int NoDevices { get; set; }

        /// <summary>Причина отказа/сбоя (для лога; наружу не отдавать).</summary>
        public string Error { get; set; }

        public static ConnectNotificationOutcome Failure(string error)
        {
            return new ConnectNotificationOutcome { Ok = false, Error = error ?? "unknown" };
        }
    }

    /// <summary>Выданный nsg_connect одноразовый connect-токен (вариант C).</summary>
    public sealed class ConnectIssuedToken
    {
        public string Token { get; set; }

        public DateTime ExpiresAtUtc { get; set; }
    }

    /// <summary>
    /// S2S-клиент nsg_connect (Chatista) — эпик NSG-SOFT/futbolista-tasks#1212.
    ///
    /// <para><b>Один секрет тенанта на все исходящие вызовы</b>
    /// (<c>nsgconnect.tenantSecret</c>): им продукт авторизует и выдачу
    /// connect-токенов (<see cref="IssueTokenAsync"/>, мост авторизации,
    /// вариант C), и отправку уведомлений (<see cref="SendNotificationAsync"/>,
    /// TASK72). Секрет рождается в админке Chatista («Платформа» →
    /// «Включить и сгенерировать»), nsg_connect хранит только sha256;
    /// ротация — там же, с grace-окном, обе стороны не падают.</para>
    ///
    /// <para><b>Вариант C против моста #1203</b>: вместо «мы выдаём свой токен,
    /// nsg_connect звонит нам обратно в VerifyConnectToken» продукт просит токен
    /// У nsg_connect. Обратного вызова нет → на стороне nsg_connect не нужны
    /// env FUTBOLISTA_* (и их НЕЛЬЗЯ задавать: зарегистрированный адаптер
    /// перехватил бы аутентификацию, и выданные здесь токены перестали бы
    /// приниматься). Redis продукта в этой схеме тоже не нужен.</para>
    ///
    /// <para><b>Никогда не бросает</b>: сбой интеграции не должен ломать
    /// бизнес-операцию. Ошибки — в лог и null/Failure-результат.</para>
    /// </summary>
    internal static class NsgConnectApi
    {
        /// <summary>База API nsg_connect, например <c>https://api.chatista.me</c>.
        /// Не задана — интеграция выключена.</summary>
        private const string BaseUrlSettingKey = "nsgconnect.apiBaseUrl";

        /// <summary>Секрет тенанта (<c>cst_…</c> из админки Chatista). В
        /// app.config рядом с <c>auth.jwt.secret</c> — тот же класс данных.</summary>
        private const string TenantSecretSettingKey = "nsgconnect.tenantSecret";

        /// <summary>Сверено с <see cref="ConnectAuthController"/> (#1203) и
        /// строками tenant/product в БД nsg_connect.</summary>
        internal const string TenantExternalKey = "futbolista";
        internal const string ProductExternalKey = "futbolista";

        /// <summary>Один клиент на процесс (per-call экземпляры исчерпывают
        /// сокеты). Таймаут короткий: вызовы стоят в хвосте пользовательских
        /// операций, висеть на них нельзя.</summary>
        private static readonly HttpClient Http = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(10),
        };

        private static string BaseUrl =>
            System.Configuration.ConfigurationManager.AppSettings[BaseUrlSettingKey];

        private static string TenantSecret =>
            System.Configuration.ConfigurationManager.AppSettings[TenantSecretSettingKey];

        /// <summary>Интеграция сконфигурирована на этой ноде.</summary>
        public static bool IsConfigured =>
            !string.IsNullOrWhiteSpace(BaseUrl) && !string.IsNullOrWhiteSpace(TenantSecret);

        /// <summary>
        /// Выдать connect-токен пользователю (вариант C, TASK78): nsg_connect
        /// вернёт одноразовый токен, клиент откроет им messenger-сессию.
        /// <c>null</c> — отказ/сбой (подробности в логе).
        /// </summary>
        /// <param name="claims">Прикладные признаки для чата (например
        /// <c>futbolista_organizer=true</c>) — вернутся продукту в claims
        /// сессии. Имена — конвенция продукта, секретов не класть.</param>
        public static async Task<ConnectIssuedToken> IssueTokenAsync(
            Guid userId,
            string displayName,
            IDictionary<string, string> claims = null)
        {
            var request = new JObject
            {
                ["method"] = "issueToken",
                ["tenantExternalKey"] = TenantExternalKey,
                ["productExternalKey"] = ProductExternalKey,
                ["serviceSecret"] = TenantSecret,
                ["externalUserId"] = userId.ToString(),
                ["displayName"] = displayName ?? string.Empty,
            };
            if (claims != null && claims.Count > 0)
            {
                var map = new JObject();
                foreach (var pair in claims) map[pair.Key] = pair.Value;
                request["claims"] = map;
            }

            var parsed = await PostAsync("/connectToken", request, "issueToken")
                .ConfigureAwait(false);
            if (parsed == null) return null;

            var token = parsed.Value<string>("token");
            if (string.IsNullOrEmpty(token))
            {
                Program.Logger.LogWarning(
                    "[CONNECT] issueToken: ответ без token — контракт разъехался?");
                return null;
            }

            return new ConnectIssuedToken
            {
                Token = token,
                ExpiresAtUtc =
                    parsed.Value<DateTime?>("expiresAt")?.ToUniversalTime()
                    ?? DateTime.UtcNow.AddMinutes(5),
            };
        }

        /// <summary>
        /// Отправить push-уведомление пользователям (batch, TASK72).
        /// <paramref name="userIds"/> — наши GUID-ы <c>ПользователиСервисов</c>:
        /// ровно они уходят как <c>externalUserId</c> при входе в чат, по ним
        /// nsg_connect находит устройства. Идемпотентность на той стороне по
        /// <c>(product, idempotencyKey, адресат)</c> — retry безопасен.
        /// </summary>
        /// <param name="data">Deep-link полезная нагрузка: уйдёт в data пуша
        /// как есть. Секретов не класть.</param>
        public static async Task<ConnectNotificationOutcome> SendNotificationAsync(
            IReadOnlyCollection<Guid> userIds,
            string title,
            string body,
            string idempotencyKey,
            IDictionary<string, string> data = null)
        {
            if (userIds == null || userIds.Count == 0)
            {
                return ConnectNotificationOutcome.Failure("no_recipients");
            }

            var request = new JObject
            {
                ["method"] = "send",
                ["tenantExternalKey"] = TenantExternalKey,
                ["productExternalKey"] = ProductExternalKey,
                ["serviceSecret"] = TenantSecret,
                ["externalUserIds"] = new JArray(userIds.Select(id => id.ToString())),
                ["title"] = title ?? string.Empty,
                ["body"] = body ?? string.Empty,
                ["idempotencyKey"] = idempotencyKey ?? string.Empty,
            };
            if (data != null && data.Count > 0)
            {
                var map = new JObject();
                foreach (var pair in data) map[pair.Key] = pair.Value;
                request["data"] = map;
            }

            var parsed = await PostAsync("/productNotification", request,
                $"send idem={idempotencyKey}").ConfigureAwait(false);
            if (parsed == null)
            {
                return ConnectNotificationOutcome.Failure("call_failed");
            }

            var outcome = new ConnectNotificationOutcome
            {
                Ok = true,
                Accepted = parsed.Value<int?>("accepted") ?? 0,
                Deduped = parsed.Value<int?>("deduped") ?? 0,
                NoDevices = parsed.Value<int?>("noDevices") ?? 0,
            };
            Program.Logger.LogInformation(
                $"[CONNECT] send ok: accepted={outcome.Accepted} " +
                $"deduped={outcome.Deduped} noDevices={outcome.NoDevices} " +
                $"idem={idempotencyKey}");
            return outcome;
        }

        /// <summary>
        /// Wire-формат Serverpod: POST <c>/&lt;endpoint&gt;</c>, JSON-тело
        /// <c>{"method": имя, параметры}</c>; успех — HTTP 200 с
        /// <c>__className__</c>-объектом, отказ — 400 c
        /// <c>InvalidTokenException</c> без деталей (anti-enumeration, причина
        /// в логе nsg_connect). Сверено с дев-стендом. <c>null</c> — сбой.
        /// </summary>
        private static async Task<JObject> PostAsync(
            string path, JObject request, string logContext)
        {
            if (!IsConfigured)
            {
                Program.Logger.LogWarning(
                    $"[CONNECT] {logContext}: интеграция не сконфигурирована " +
                    $"({BaseUrlSettingKey}/{TenantSecretSettingKey}).");
                return null;
            }

            try
            {
                var url = BaseUrl.TrimEnd('/') + path;
                using (var content = new StringContent(
                    request.ToString(Formatting.None), Encoding.UTF8, "application/json"))
                using (var response = await Http.PostAsync(url, content).ConfigureAwait(false))
                {
                    var text = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    if (!response.IsSuccessStatusCode)
                    {
                        Program.Logger.LogWarning(
                            $"[CONNECT] {logContext}: HTTP {(int)response.StatusCode} " +
                            $"{Truncate(text, 200)}");
                        return null;
                    }

                    return JObject.Parse(text);
                }
            }
            catch (Exception ex)
            {
                Program.Logger.LogWarning(
                    $"[CONNECT] {logContext}: {ex.Message}");
                return null;
            }
        }

        private static string Truncate(string value, int max)
        {
            if (string.IsNullOrEmpty(value)) return string.Empty;
            return value.Length <= max ? value : value.Substring(0, max) + "…";
        }
    }
}
