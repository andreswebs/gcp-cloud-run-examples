namespace DotnetApiEntra.Helpers;

public static class GcpOidcTokenHelper
{
    private static readonly HttpClient HttpClient = new HttpClient
    {
        Timeout = TimeSpan.FromSeconds(5),
    };

    /// <summary>
    /// Fetches a GCP OIDC identity token for the given audience from the metadata server.
    /// Returns null if not running in GCP or on failure.
    /// </summary>
    public static async Task<string?> GetIdentityTokenAsync(string? audience, ILogger? logger = null)
    {
        if (string.IsNullOrWhiteSpace(audience))
        {
            logger?.LogWarning("INTERNAL_OIDC_AUDIENCE not configured, skipping OIDC token fetch");
            return null;
        }

        try
        {
            var url = $"http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience={Uri.EscapeDataString(audience)}";

            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.Add("Metadata-Flavor", "Google");

            using var response = await HttpClient.SendAsync(request);

            if (response.IsSuccessStatusCode)
            {
                var token = await response.Content.ReadAsStringAsync();
                logger?.LogDebug("Successfully fetched OIDC identity token for audience {Audience}", audience);
                return token.Trim();
            }

            logger?.LogWarning("Metadata service returned {StatusCode} for identity token", response.StatusCode);
            return null;
        }
        catch (HttpRequestException ex)
        {
            logger?.LogDebug(ex, "Failed to fetch OIDC identity token (likely not running in GCP)");
            return null;
        }
        catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
        {
            logger?.LogDebug(ex, "Timeout fetching OIDC identity token");
            return null;
        }
        catch (Exception ex)
        {
            logger?.LogWarning(ex, "Unexpected error fetching OIDC identity token");
            return null;
        }
    }
}
